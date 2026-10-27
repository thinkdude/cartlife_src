# Cart Life (AGS 3.6 port)

Source code to **Cart Life**, by Richard Hofmeier, ported to [Adventure Game Studio](https://www.adventuregamestudio.co.uk/) 3.6.2 with a set of long-standing gameplay bugs fixed.

This repository is a fork of [gondur/cartlife_src](https://github.com/gondur/cartlife_src), the "Open Sores" release of the original source. The goal is a version of Cart Life that builds cleanly in a current AGS, plays without the bugs players have reported since 2011, and is easier for the next person to read and change.

- [About the game](#about-the-game)
- [What this fork changes](#what-this-fork-changes)
- [Building](#building)
- [Testing](#testing)
- [What's where](#whats-where)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Credits](#credits)
- [Changelog](#changelog)

## About the game

Cart Life is a simulation game developed by Richard Hofmeier in Adventure Game Studio for Microsoft Windows, released in May 2011. It was added to Steam in March 2013 and later removed when Hofmeier released the full source code for free. The game is drawn on a grayscale pixel grid with minimal detail, so the player reads the mood of each of the three vendor characters.

The player controls one of three street vendors (Andrus, Melanie or Vinny) and tries to run their business while looking after their health, interests and families.

Critics praised its relatable characters, though some criticised its technical issues. In 2013 Cart Life won the Independent Games Festival Seumas McNally Grand Prize, the Nuovo Award, and Excellence in Narrative.

More: [Cart Life on Wikipedia](https://en.wikipedia.org/wiki/Cart_Life)

## What this fork changes

**Engine upgrade.** The game was made in AGS 3.2.1 and later moved to 3.4. It now builds and runs in **AGS 3.6.2**, after a few small script repairs.

**Bug fixes.** 18 gameplay bugs are fixed, most of them reported by players on Steam, the original repository's [issue #2](https://github.com/gondur/cartlife_src/issues/2) and community walkthroughs. Highlights:

- Andrus no longer freezes in his cough pose, and nicotine withdrawal recovers properly.
- Manual saves no longer overwrite each other or the character autosaves, and selecting nothing in the save menu no longer crashes.
- The cash register keeps the money you see and the change you record in step, and quick clicks on the register key no longer fail a sale or check out twice.
- Hot-dog and bagel orders charge the right toppings, use ingredients once, and no longer crash with a four-item menu.
- Purchases deliver what you paid for and record the right expense, and Melanie can no longer buy the $1200 stand into debt.
- Short arrow-key taps select a character on the title screen.

The full list, with what was wrong and how it was repaired, is in **[PORTING-NOTES.md](PORTING-NOTES.md)**. The evidence for each fix (before and after results) is in [TEST-RESULTS.md](TEST-RESULTS.md), and the player reports checked against this port are in [COMMUNITY-BUGS.md](COMMUNITY-BUGS.md).

## Building

You need Windows and [AGS 3.6.2](https://github.com/adventuregamestudio/ags/releases).

1. Clone this repository.
2. Extract `cartlife/acpsprset_DECOMPRESSME.part1.rar` into the `cartlife/` folder with 7-Zip or WinRAR (part 2 is picked up automatically). This gives you the sprite file, `acsprset.spr`.
3. Open `cartlife/Game.agf` in AGS and choose **Build > Build EXE**.

The game ends up in `cartlife/Compiled/Windows/cartlife.exe`.

You can also build from PowerShell with `.\Build-CartLife.ps1`, which saves a log of each build in `build-logs/`.

### Before you edit

- The scripts are saved in Windows-1252, not UTF-8. The AGS editor sometimes turns special characters (like `è` or `•`) into `?` when it saves, so check your diff.
- The game still uses some older AGS settings, such as the old audio system. Leave them as they are unless you're ready to update the scripts too.

## Testing

To play a test build with its own saves, separate from your real ones:

```powershell
.\Start-Playtest.ps1 -Profile mytest
```
\

## Roadmap

The work happens in small steps, each in its own pull request, so every change can be reviewed and reverted on its own.

1. **Baseline on AGS 3.6.2** — done. Builds and runs, with the first 18 fixes and their regression suites.
2. **Ranked bug list** — next. Collect the remaining known bugs (open reports in [COMMUNITY-BUGS.md](COMMUNITY-BUGS.md), the missing event handlers the compiler warns about, the Cookbook that can't be read, Saturday custody issues, oversized or disappearing characters) and rank them by how much they hurt a playthrough.
3. **One pull request per bug**, each with a regression check where the bug can be reproduced.
4. **Code cleanup** that doesn't change behaviour: formatting, naming and removing dead code, kept separate from fixes so the diffs stay readable.
5. **Improvements**, each scoped on its own: higher and widescreen resolutions, a better save system, and other quality-of-life changes.

## Contributing

Bug reports and fixes are welcome. Please open an [issue](https://github.com/thinkdude/cartlife_src/issues) with what you did, what you expected, and which character and day it happened on. A save file helps a lot. Older reports are collected in the original repository's [issue #2](https://github.com/gondur/cartlife_src/issues/2) and in [COMMUNITY-BUGS.md](COMMUNITY-BUGS.md).

For pull requests:

- Keep each pull request to one bug or one change.
- Build with AGS 3.6.2 and run the regression suites that touch your change. If you fix a bug that can be reproduced in script, add a check for it.
- Keep fixes and reformatting in separate pull requests.
- Check that your diff didn't damage Windows-1252 characters (see [Before you edit](#before-you-edit)).

The code is quite messy and needs lots of refactoring, and even just formatting, to be readable. As RH notes in the code:
```
// It's clear that, at the time of making this game and writing all of this mind-cancer-inducing code, I was
// new to scripting and was only guessing at how to make things work. What takes cart life hundreds of thousands
// of lines of scripting could be done in a few dozen by a more astute author. But, despite the immeasurable shame
// I feel when I glance back over this shit, I remember that I only learned what I know through looking at the
// attempts made by other authors. If they hadn't granted me the chance to peek under the hoods of their creations,
// I could never have even started to forge my own. It's my dearest hope that any of this is of use to someone.
// BEST OF LUCK, PIONEER!
// -Richard
```

The original "Open Sores" cleanup followed something akin to the [PSR-2](https://www.php-fig.org/psr/psr-2/) standard as a style guide, as close as practicable in this language. New cleanup should follow it too.

The scripts are indented with 4 spaces per level, as PSR-2 asks. `python tools/agsfmt.py cartlife/*.asc cartlife/*.ash` re-indents them, and `--check` lists the files that need it. It only ever changes the blanks at the start and end of a line, so it can't change what the game does.

Please add a Signed-off-by line, in the following format, to the end of each of your commit messages to certify that you adhere to the requirements of the [Developer Certificate of Origin](https://julien.ponge.org/blog/developer-certificate-of-origin-versus-contributor-license-agreements/) below:
```
Signed-off-by: Vinny Bagelman <vinny.bagelman@example.com>
```
You must use your real name and email address in the Signed-off-by line. If you have correctly set your Git [user.name and user.email variables](https://git-scm.com/docs/git-config#Documentation/git-config.txt-username), you can then use the Git [commit command's -s option](https://git-scm.com/docs/git-commit#Documentation/git-commit.txt--s) to add the Signed-off-by line automatically.

### Developer Certificate of Origin

Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
1 Letterman Drive
Suite D4700
San Francisco, CA, 94129

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.

## License

CART LIFE'S FREE LICENSE: Copyright (c) 2014 • Richard Hofmeier Permission is hereby and enthusiastically granted, free of charge, to anyone obtaining a copy of this software and associated documentation files (the "Software"), to deal in the software without restriction, including without limitation the rights to use, copy, modify, pervert, corrupt, manipulate, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This doesn't include most of the music, of course, since it was composed and performed by people who aren't me. Please contact them for permission: MAT64: http://www.cervellomeccanico.com/ POCKETMASTER: http://www.pocketmaster.ch/ STU: http://stu.atari.org/ LO-BAT: http://www.lo-bat.be/

ALSO: This game uses the font "HOOGE" by Nicholay Dubina and Craig Kroeger, which I can't give you permission to use, probably. Best to ask Craig, instead. http://miniml.com/fonts/

## Credits

- **Richard Hofmeier**: Cart Life, and the release of its source.
- **[gondur/cartlife_src](https://github.com/gondur/cartlife_src)** and its contributors: the "Open Sores" release, which got the source compiling in AGS 3.4 and started the cleanup. Binaries and a clone of that repository are on [SourceForge](https://sourceforge.net/projects/cartlife/).
- **Music** by MAT64, POCKETMASTER, STU and LO-BAT, and the **HOOGE** font by Nicholay Dubina and Craig Kroeger (see the license above).

## Changelog

- ##### AGS 3.6 port - 2026-10-27
    - Builds and runs in AGS 3.6.2.
    - Fixes 18 gameplay bugs. See [PORTING-NOTES.md](PORTING-NOTES.md).
    - Adds engine regression suites, build and playtest scripts.
    - Re-indents every script consistently (whitespace only) and adds `tools/agsfmt.py`.
- #####  "Open Sores" 0.1 - 2017-06-30
    - Now compiles successfully on AGS 3.4
    - Started reformatting / cleaning up code.
