# Cart Life on AGS 3.6.2.21

## Verified on 2026-10-21

- Installed editor: `C:\Program Files (x86)\Adventure Game Studio 3.6.2\AGSEditor.exe`, version 3.6.2.21.
- Project: `cartlife\Game.agf`. This checkout already contained the editor's format conversion before this work.
- Full build completed with exit code 0 and `AGS: Compilation successful!`.
- Windows executable launched and displayed the Cart Life character-selection screen.
- This is a build/startup smoke check, not a completed playthrough or certification that all bugs are fixed.

## Repairs made

1. Removed the extra closing brace inside Vinny's debug startup branch, which caused the compiler's unexpected `if` error. Preserved the restart-point addition and moved it to the end of `game_start`, after initialization.
2. Included a sauerkraut price of exactly $0.01 in both paid-topping branches. Previously neither the free nor paid branch covered that price.
3. Sauerkraut availability now requires positive stock and positive inventory quantity. The unavailable branch handles either missing inventory or depleted stock, including a negative stock counter.
4. Character selection handles individual left/right/Enter key events.
5. Andrus's standing cough animates and unlocks his view; withdrawal recalculates after nicotine replenishment and protagonist changes.
6. New manual saves search unused slots 4-100 and respect the 20-manual-save limit. Overwrite, load and delete use their own list's slot map, with valid-selection guards.
7. Register bills and coins reuse actual empty slots and reject additions when full, keeping visible money and recorded change consistent.
8. Declined hot-dog orders stop before preparation, and an accepted plain fallback retains its sale.
9. One-cent toppings are charged, everything orders count the base hot dog once, and ingredient availability checks both inventory and remaining portions.
10. Ordinary purchases no longer recheck affordability after taking payment. Exact cash purchases now deliver the purchased CDs, books, lighter and food.
11. Shopping spending is counted once, expenses/receipts use the actual paid price, and grade-S coffee costs no longer alter grade-A costs.
12. Eating an old sandwich removes the correct inventory item.
13. Cooking guards require the actual quantities consumed. Special-bagel restocking matches any existing flavor before allocating an empty slot; full flavor capacity preserves dough and releases the cooking overlay.
14. The pawn-shop stereo records its full $70 equipment cost, and purchases close the sold-out stereo and premium-espresso offers.
15. Register key/drawer callbacks wait for opening/payment animations and prevent duplicate checkout during closing.
16. Order confirmation never reads beyond the menu's item count. Short topping names and equal-height answer labels fit all regular bagel variants in every answer position.
17. Bagel topping orders preserve their accepted type, include the extra charge, receive a fresh typing phrase and credit the complete sale. Ingredients are consumed once per sale or wasted preparation; toasted bagels preserve cream cheese.
18. Melanie's $1200 stand purchase rejects insufficient funds before charging or entering the design step.
19. The pedestrian timer is re-armed on every roll. A roll of exactly 5 used to leave it unarmed, so no more customers came until the cart moved or the player travelled.
20. A customer can no longer order from an empty menu. George asks the time instead of buying, Nelly leaves Melanie as she leaves Andrus when there are no papers, and `Spin()`/`sellRandom()` no longer read `Menu.Items` with a stale index when the menu is empty.
21. The street rooms' edge check only sends characters in the current room to room 24. It used to move any character standing at x 0-2 or 748+ in any room, so characters vanished from other rooms.
22. Faith's dialog requests 123 and 478-480 exist. Turning down her test now records "no thanks" (state 2), which unlocks her existing "broken-hearted" re-offer, and the player's answer to "Was it hard?" is shown.
23. Ask-about answers are given once. The topic list is split over two if/else chains (AGS limits nesting), and every topic the first chain answered also fell into the second chain's "I guess I really don't know." and reopened the topic list.

Script edits retain the existing Windows-1252 encoding. Existing local conversion and source changes have been preserved.

## How to build and play

Open `cartlife\Game.agf` in AGS 3.6.2 and choose Build > Build EXE. Close any other editor instance using this same project before a command-line build.

Command-line build from PowerShell (wait for completion before reading the exit code):

```powershell
$editor = 'C:\Program Files (x86)\Adventure Game Studio 3.6.2\AGSEditor.exe'
$project = Join-Path $PSScriptRoot 'cartlife\Game.agf'
# In an interactive shell, replace $PSScriptRoot with this repository's path.
$build = Start-Process $editor -ArgumentList ('"' + $project + '" /compile') -WindowStyle Hidden -PassThru -Wait
$build.ExitCode
```

Run `cartlife\Compiled\Windows\cartlife.exe`; retain all neighboring game data, audio and DLL files.

## Remaining issues and regression checks

The compiler reports missing handlers for several GUI clicks, soy-milk interactions, Cookbook look, cEgo interactions, and room 35 region 3 WalksOff. It also reports existing handlers that are not linked, including room 28's first-load and leave handlers. These need investigation against the intended interactions; adding empty functions or attaching handlers indiscriminately would hide warnings without demonstrating a repair.

The hot-dog refusal, pricing and stock paths and register money allocation have reproduced failures and verified repairs. The community-led pass also reproduces and repairs register key/drawer timing, duplicate checkout, a four-item-menu crash, bagel transaction handling and an unaffordable stand purchase. See `COMMUNITY-BUGS.md` for the source reports and remaining leads.

Playtest next:

- Start each of Andrus, Melanie and Vinny; verify intro, movement and room transitions.
- Save, quit, restore and restart; verify inventory, money, story and time persist appropriately.
- With Vinny, order sauerkraut at $0.00, $0.01 and a higher price, including customer acceptance/refusal.
- Test sauerkraut with both stock indicators positive, each independently empty, both empty, and a negative remaining-stock counter. Unavailable stock must not be offered as available.
- Verify plain-hot-dog fallback, rejected orders, preparation and cash-register change.
- Exercise room 28 visits and room 35 region transitions before changing their event links.

The latest full build completed successfully at 06:32 on 2026-10-22 (America/Los_Angeles), including the community-led repairs. Its dated report is `build-logs/20261022-063153-069.json`; compiler output is in the corresponding `.stdout.log` and `.stderr.log` files.

## Ongoing verification

Use `Build-CartLife.ps1` for dated compiler logs and `build-logs/latest.json`. It rejects an open editor project or running Windows game before attempting a build. `Start-Playtest.ps1 -Profile <name>` launches a visible game with separate saves and shared data under `.playtest/<name>`.

See `TEST-RESULTS.md` for the bug ledger and verified repairs. The Andrus withdrawal regression reproduces seven failures in the original block and passes all 22 checks with the repair; repeat it with `tests/Run-Regression.ps1`.

All three protagonists now pass isolated startup, save/restore, fresh-process reload and restart checks. The prior stair/withdrawal evidence is retained in the bug ledger; further investigation of the reported room jump is deferred at the user's request.

The independent bug-hunt pass adds 55 passing engine assertions: Saves (13), SaveSelection (3), CashRegister (11), and Hotdog (28). The order fixture counts preparation entry instead of playing the minigame. These checks do not replace complete playthroughs, mouse/keyboard save-menu checks, or end-to-end checkout testing. See `TEST-RESULTS.md` for original/fixed comparisons, evidence paths and exact coverage limits.

The broader shopping/inventory pass adds another 98 passing assertions: Shopping (78) and Inventory (20). These cover purchase delivery, spending, receipts, coffee costs, and six food/drink consumption flows including normal animations. The original code fails 33 shopping checks and two inventory checks. All tests run in disposable projects with separate saves.

The 2026-10-22 equipment/cooking pass adds 37 passing assertions: Equipment (20) and Cooking (17). The source before these repairs fails four equipment checks and nine cooking checks. This pass verifies quantities, flavored-bagel restocking/capacity, seller stock, expense records and the three protagonists' tested machine prerequisites. See the ledger for fixture limits and evidence directories.

The community-led pass adds 203 passing assertions: CommunityBagels (49), OrderChoices (136), RegisterTiming (11), and StandPurchase (7). Before-repair comparisons fail 28 bagel checks, eight register checks and four stand checks, and reproduce a native menu-index crash. Longer story playthroughs and the unresolved online reports remain outside this coverage.
