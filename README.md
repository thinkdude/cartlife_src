# Cart Life (AGS 3.6 port)

Source code to **Cart Life**, by Richard Hofmeier, ported to [Adventure Game Studio](https://www.adventuregamestudio.co.uk/) 3.6.2 with a set of long-standing gameplay bugs fixed.

This repository is a fork of [gondur/cartlife_src](https://github.com/gondur/cartlife_src), the "Open Sores" release of the original source. The goal is a version of Cart Life that builds cleanly in a current AGS, plays without the bugs players have reported since 2011, and is easier for the next person to read and change.

- [About the game](#about-the-game)
- [What this fork changes](#what-this-fork-changes)
- [Building](#building)
- [Running and testing](#running-and-testing)
- [Repository layout](#repository-layout)
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

**Engine upgrade.** The project was written in AGS 3.2.1 and later compiled in 3.4.0. It now opens, builds and runs in **AGS 3.6.2** (tested with editor 3.6.2.21). The upgrade needed a few small repairs: a stray unterminated string that 3.4 accepted, a brace the 3.6 editor's auto-inserted `SetRestartPoint()` split out of a comment, and Windows-1252 characters damaged by the editor's save.

**Bug fixes.** 18 gameplay bugs are fixed, most of them reported by players on Steam, the original repository's [issue #2](https://github.com/gondur/cartlife_src/issues/2) and community walkthroughs. Highlights:

- Andrus no longer freezes in his cough pose, and nicotine withdrawal recovers properly.
- Manual saves no longer overwrite each other or the character autosaves, and selecting nothing in the save menu no longer crashes.
- The cash register keeps the money you see and the change you record in step, and quick clicks on the register key no longer fail a sale or check out twice.
- Hot-dog and bagel orders charge the right toppings, use ingredients once, and no longer crash with a four-item menu.
- Purchases deliver what you paid for and record the right expense, and Melanie can no longer buy the $1200 stand into debt.
- Short arrow-key taps select a character on the title screen.

The full list, with what was wrong and how it was repaired, is in **[PORTING-NOTES.md](PORTING-NOTES.md)**. The evidence for each fix (before and after results) is in [TEST-RESULTS.md](TEST-RESULTS.md), and the player reports checked against this port are in [COMMUNITY-BUGS.md](COMMUNITY-BUGS.md).

**Regression tests.** `tests/` holds 15 engine-level regression suites (494 checks at the time of the 3.6 merge). Each one runs the game's real script code in a disposable copy of the project, so it does not touch your saves or add test hooks to the normal build.

**Not changed yet.** Resolution, widescreen, the save system and the overall code style are still as the original shipped them. See the [roadmap](#roadmap).

## Building

You need Windows and **[AGS 3.6.2](https://github.com/adventuregamestudio/ags/releases)** (the editor is Windows-only). Other 3.6.x releases will likely work but are untested. AGS 4.0 is not supported.

1. **Clone the repository.**

   ```
   git clone https://github.com/thinkdude/cartlife_src.git
   ```

2. **Extract the sprite file.** The sprite file is large, so it ships compressed as a two-part RAR archive. Extract `cartlife/acpsprset_DECOMPRESSME.part1.rar` (with `part2` beside it) into the `cartlife/` folder. You should end up with `cartlife/acsprset.spr`, which git ignores. Use [7-Zip](https://www.7-zip.org/) or WinRAR, or from a command prompt in `cartlife/`:

   ```
   unrar x acpsprset_DECOMPRESSME.part1.rar
   ```

   Without this file the editor opens the project with every sprite missing.

3. **Build.** Either:

   - open `cartlife/Game.agf` in the AGS 3.6.2 editor and choose **Build > Build EXE**, or
   - from PowerShell, run the build script, which writes dated compiler logs to `build-logs/` and fails if the project is open in an editor or the game is running:

     ```powershell
     .\Build-CartLife.ps1
     # Different install location:
     .\Build-CartLife.ps1 -EditorPath 'D:\AGS\AGSEditor.exe'
     ```

   The game is written to `cartlife/Compiled/Windows/cartlife.exe`. Keep it together with the data, audio and DLL files beside it.

### Things to know before editing

- **Script encoding.** The scripts and `Game.agf` use Windows-1252, not UTF-8. The 3.6 editor can turn characters such as `•`, `è` and `â` into `?` when it saves. Check `git diff` after saving in the editor, and keep your own editor in Windows-1252 when changing script files.
- **Project settings.** The game still uses the old audio API (`EnforceNewAudio` off), old-style global functions such as `SetGlobalInt` (`EnforceObjectBasedScript` off) and script compatibility level v321. Changing these will break the build until the scripts are updated.
- **Close the editor before a command-line build.** AGS locks the project while it is open.
- **Old saves.** AGS 3.6.2 can read saves from 3.2 and later, but saves made with the original game are not guaranteed to load in this build because the scripts changed.

## Running and testing

**Play a build** by running `cartlife/Compiled/Windows/cartlife.exe`, or use the playtest script, which starts the game windowed with its own save folder so it doesn't mix with your real saves:

```powershell
.\Start-Playtest.ps1 -Profile mytest          # saves and logs go to .playtest\mytest
.\Start-Playtest.ps1 -Profile mytest -LoadSlot 4
```

**Run a regression suite** with `tests/Run-Regression.ps1`. Add `-Original` to run the same checks against the code from before the fix, which is expected to fail and shows the bug the suite covers.

```powershell
.\tests\Run-Regression.ps1 -Suite Hotdog
.\tests\Run-Regression.ps1 -Suite Hotdog -Original
.\tests\Run-Regression.ps1 -Suite Startup -Character Melanie
```

Suites: `Withdrawal`, `Startup`, `HotelStairs`, `Saves`, `SaveSelection`, `CashRegister`, `RegisterTiming`, `Hotdog`, `Shopping`, `Inventory`, `Equipment`, `Cooking`, `CommunityBagels`, `OrderChoices`, `StandPurchase`.

The suites check game logic directly. They don't replace a full playthrough with mouse and keyboard, so please still play through anything you change.

## Repository layout

| Path | What it is |
| --- | --- |
| `cartlife/Game.agf` | The AGS project. Open this in the editor. |
| `cartlife/GlobalScript.asc` | Main game logic. |
| `cartlife/CustomFunctions.asc`, `DialogRequesting.asc`, `customertalk+listen.asc`, `AskOnly.asc` | Shared script modules: commerce, dialogue, customer conversations. |
| `cartlife/room*.asc`, `room*.crm` | Per-room scripts and room files. |
| `cartlife/acpsprset_DECOMPRESSME.part*.rar` | The sprite file, compressed (see [Building](#building)). |
| `cartlife/AudioCache/` | Music and sound effects. |
| `Build-CartLife.ps1`, `Start-Playtest.ps1` | Build and playtest helpers. |
| `tests/` | Regression suites and their runner. |
| `PORTING-NOTES.md`, `TEST-RESULTS.md`, `COMMUNITY-BUGS.md` | What changed in the port, the evidence, and the player reports behind it. |

Build logs (`build-logs/`), playtest profiles (`.playtest/`) and compiled output (`cartlife/Compiled/Windows`, `Linux`, `Data`) are local only and ignored by git.

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
- Check that your diff didn't damage Windows-1252 characters (see [Things to know before editing](#things-to-know-before-editing)).

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
- #####  "Open Sores" 0.1 - 2017-06-30
    - Now compiles successfully on AGS 3.4
    - Started reformatting / cleaning up code.
