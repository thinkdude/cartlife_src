#!/usr/bin/env python3
"""Whitespace-only re-indenter for AGS scripts (.asc/.ash).

Only the leading and trailing blanks of each line change and the number of
lines stays the same, so every line maps 1:1 onto the original and the
compiler sees the same tokens on the same line numbers. The tool refuses to
write a file if that would not hold.

Indentation follows the statement structure the AGS compiler sees, not just
brace counting:
  * 2 spaces per level; block contents are one level in from their braces.
  * a brace-less body of `if`/`else`/`while` is one level in from its header;
    `else` binds to the nearest unmatched `if` (as in AGS and C), and
    `else if` chains stay flat.
  * continuation lines of a statement or condition get two extra levels.
  * a line is indented by the level of its first token, so a line starting
    with `}}` lines up with the inner of the two blocks it closes.
  * comment-only lines take the level of the next code line (one level in
    when that line starts with `}`).
  * preprocessor lines and the inside of multi-line /* */ comments keep their
    own indentation (" * " doc-comment lines align to their "/*").
  * trailing blanks are removed, blank lines become empty, and the file ends
    with a single newline.

Files are handled as bytes (decoded as latin-1, which is lossless), so
Windows-1252 text is preserved byte for byte. LF and CRLF files both work.

Usage: python tools/agsfmt.py [--check] [--report] FILE...
  --check   list files that would change and exit 1, without writing
  --report  list lines indented as a brace-less if/else/while body
"""
import glob
import re
import sys

INDENT = "  "
IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
NUM_RE = re.compile(r"[0-9][A-Za-z0-9_.]*")
CHAR_RE = re.compile(r"'(?:\\.|[^'\\])'")


class FormatError(Exception):
    pass


class Tok:
    __slots__ = ("val", "line", "level")

    def __init__(self, val, line):
        self.val, self.line, self.level = val, line, None

    def __repr__(self):
        return f"{self.val!r} on line {self.line + 1}"


def tokenize(lines):
    """Split the script into tokens and classify each line.

    Returns (tokens, kinds, comment_opener). kinds[i] is 'blank', 'pp'
    (preprocessor), 'comment' (comment only), 'code', 'incomment' (starts
    inside a /* */ comment) or 'incomment+code'. comment_opener maps each
    'incomment' line to the line where its comment opened.
    """
    toks, kinds, opener_of = [], [], {}
    in_block, opener = False, None
    for ln, raw in enumerate(lines):
        s = raw.strip(" \t")
        if in_block:
            kinds.append("incomment")
            opener_of[ln] = opener
        elif s == "":
            kinds.append("blank")
            continue
        elif s.startswith("#"):
            kinds.append("pp")
            continue
        else:
            kinds.append(None)
        i, n, had_code = 0, len(raw), False
        while i < n:
            c = raw[i]
            if in_block:
                j = raw.find("*/", i)
                if j < 0:
                    break
                in_block = False
                i = j + 2
            elif c in " \t":
                i += 1
            elif raw.startswith("//", i):
                break
            elif raw.startswith("/*", i):
                in_block, opener = True, ln
                i += 2
            else:
                had_code = True
                if c == '"':
                    j = i + 1
                    while j < n and raw[j] != '"':
                        j += 2 if raw[j] == "\\" else 1
                    if j >= n:
                        raise FormatError(f"line {ln + 1}: unterminated string")
                    end = j + 1
                elif c == "'":
                    m = CHAR_RE.match(raw, i)
                    if not m:
                        raise FormatError(f"line {ln + 1}: stray apostrophe")
                    end = m.end()
                else:
                    m = IDENT_RE.match(raw, i) or NUM_RE.match(raw, i)
                    end = m.end() if m else i + 1
                toks.append(Tok(raw[i:end], ln))
                i = end
        if kinds[ln] is None:
            kinds[ln] = "code" if had_code else "comment"
        elif had_code:
            kinds[ln] = "incomment+code"
    if in_block:
        raise FormatError("unterminated /* comment")
    return toks, kinds, opener_of


class Parser:
    """Assigns an indent level to every token by parsing statements."""

    def __init__(self, toks):
        self.t, self.i = toks, 0
        self.flow = set()  # tokens inside a brace-less control body

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else None

    def at(self, val):
        tok = self.peek()
        return tok is not None and tok.val == val

    def take(self, level):
        tok = self.peek()
        if tok is None:
            raise FormatError("unexpected end of file")
        tok.level = level
        self.i += 1
        return tok

    def expect(self, val, level):
        if not self.at(val):
            raise FormatError(f"expected {val!r}, found {self.peek()!r}")
        return self.take(level)

    def toplevel(self):
        while self.peek() is not None:
            self.declaration()

    def declaration(self):
        """A top-level item: ends with ';' or a function/struct/enum body."""
        level, prev, depth = 0, None, 0
        while True:
            tok = self.peek()
            if tok is None:
                raise FormatError("unexpected end of file in a declaration")
            if depth == 0 and tok.val == "{":
                if prev is not None and prev.val == ")":
                    self.block(0)  # function body
                else:
                    self.member_list(0)  # struct or enum body
                    if self.at(";"):
                        self.take(2)
                return
            if tok.val == "}":
                raise FormatError(f"unbalanced {tok!r}")
            if tok.val in "([":
                depth += 1
            elif tok.val in ")]":
                depth -= 1
            prev = self.take(level)
            level = 2
            if depth == 0 and tok.val == ";":
                return

    def member_list(self, level):
        self.expect("{", level)
        while not self.at("}"):
            tok = self.take(level + 1)
            if tok.val == "{":
                raise FormatError(f"nested brace in struct/enum at {tok!r}")
        self.take(level)

    def block(self, level):
        self.expect("{", level)
        while not self.at("}"):
            self.statement(level + 1)
        self.take(level)

    def body(self, level):
        """Body of a control statement whose header is at `level`."""
        if self.at("{"):
            self.block(level)
        else:
            start = self.i
            self.statement(level + 1)
            self.flow.update(range(start, self.i))

    def condition(self, level):
        self.expect("(", level + 2)
        depth = 1
        while depth:
            tok = self.take(level + 2)
            if tok.val in "{};":
                raise FormatError(f"unexpected {tok!r} in a condition")
            depth += {"(": 1, ")": -1}.get(tok.val, 0)

    def statement(self, level):
        tok = self.peek()
        if tok is None:
            raise FormatError("unexpected end of file in a block")
        v = tok.val
        if v == "{":
            self.block(level)
        elif v == "if":
            self.take(level)
            self.condition(level)
            self.body(level)
            if self.at("else"):
                self.take(level)
                if self.at("if"):
                    self.statement(level)  # keep else-if chains flat
                else:
                    self.body(level)
        elif v == "while":
            self.take(level)
            self.condition(level)
            self.body(level)
        elif v in ("else", "}", "for", "do", "switch", "case", "default"):
            raise FormatError(f"unsupported or misplaced {tok!r}")
        else:
            self.simple(level)

    def simple(self, level):
        """Expression, declaration or return statement up to ';'."""
        depth = 0
        tok = self.take(level)
        while True:
            if tok.val in "{}":
                raise FormatError(f"unexpected {tok!r} in a statement")
            if tok.val in "([":
                depth += 1
            elif tok.val in ")]":
                depth -= 1
            if tok.val == ";" and depth == 0:
                return
            tok = self.take(level + 2)


def format_text(text, report=None):
    eol = "\n"
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    if lines and all(l.endswith("\r") for l in lines):
        eol = "\r\n"
        lines = [l[:-1] for l in lines]
    if any("\r" in l for l in lines):
        raise FormatError("mixed or bare CR line endings")

    toks, kinds, opener_of = tokenize(lines)
    parser = Parser(toks)
    parser.toplevel()

    first = {}
    for idx, tok in enumerate(toks):
        first.setdefault(tok.line, idx)

    level = [0] * len(lines)
    nxt = 0
    for ln in range(len(lines) - 1, -1, -1):
        if kinds[ln] == "code":
            tok = toks[first[ln]]
            level[ln] = tok.level
            nxt = tok.level + (1 if tok.val == "}" else 0)
        elif kinds[ln] == "comment":
            level[ln] = nxt
    if report is not None:
        report.extend(ln for ln in range(len(lines))
                      if kinds[ln] == "code" and first[ln] in parser.flow)

    out = []
    for ln, raw in enumerate(lines):
        kind, body = kinds[ln], raw.strip(" \t")
        if kind == "blank":
            out.append("")
        elif kind == "pp":
            out.append(raw.rstrip(" \t"))
        elif kind.startswith("incomment"):
            if body.startswith("*"):
                top = out[opener_of[ln]]
                out.append(" " * (len(top) - len(top.lstrip(" ")) + 1) + body)
            else:
                out.append(raw.rstrip(" \t"))
        else:
            out.append(INDENT * level[ln] + body)

    # Safety net: never change anything but leading/trailing blanks.
    if len(out) != len(lines) or any(
            a.strip(" \t") != b.strip(" \t") for a, b in zip(lines, out)):
        raise FormatError("internal error: non-whitespace change")
    return eol.join(out) + eol


def main(argv):
    check = "--check" in argv
    want_report = "--report" in argv
    files, rc = [], 0
    for arg in argv:
        if arg.startswith("--"):
            continue
        # Windows shells pass wildcards through unexpanded.
        wild = any(c in arg for c in "*?[")
        matches = sorted(glob.glob(arg)) if wild else [arg]
        if not matches:
            print(f"{arg}: no matching files", file=sys.stderr)
            rc = 2
        files.extend(matches)
    for name in files:
        with open(name, "rb") as fh:
            data = fh.read()
        report = [] if want_report else None
        try:
            new = format_text(data.decode("latin-1"), report).encode("latin-1")
        except FormatError as e:
            print(f"{name}: {e}", file=sys.stderr)
            rc = 2
            continue
        for ln in report or ():
            print(f"{name}:{ln + 1}: brace-less body")
        if new != data:
            if check:
                print(f"would reformat {name}")
                rc = max(rc, 1)
            else:
                with open(name, "wb") as fh:
                    fh.write(new)
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
