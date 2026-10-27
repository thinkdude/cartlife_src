# Port verification and bug ledger

## Confirmed repairs

### CL-001: Andrus remains in his cough pose

User report: Andrus (the older man with the cat) froze after a sneeze/cough, then appeared back at the hotel ground floor. The frozen pose and the room change are tracked separately until both can be reproduced together.

The original standing-withdrawal branches lock view 68 without unlocking it. The mild branch also omits the animation. Withdrawal severity is not reset when nicotine rises above 50, or when another protagonist is selected.

The repair runs and releases the standing cough animation, retains the seated return-to-idle sequence, and recalculates withdrawal for the current nicotine level and protagonist.

Engine regression results on 2026-10-21, AGS 3.6.2.21:

| Tested code | Pass | Fail |
| --- | ---: | ---: |
| Original withdrawal block from recovery checkpoint | 15 | 7 |
| Repaired withdrawal function | 22 | 0 |

Coverage: standing and seated at all three severity levels, animation completion and view restoration, unchanged room and coordinates, recovery after nicotine replenishment, and no withdrawal transfer to another protagonist. Both versions ran in disposable project copies with their own saves. No testing hooks are added to the normal build.

Repeat from the repository directory:

```powershell
.\tests\Run-Regression.ps1 -Original # Expected to fail, reproducing seven defects.
.\tests\Run-Regression.ps1           # Expected to pass all 22 checks.
```

Evidence:

- Original: `.playtest/regression-original-20261021-171520-304/saves/regression-results.txt`
- Repaired: `.playtest/regression-fixed-20261021-171623-362/saves/regression-results.txt`

### CL-002: Short arrow taps do not select a character

Title selection originally depends on polling key state from a region's Standing event. Selection now handles left/right/Enter in the room's `on_key_press` callback. Individual automated right-arrow presses cycled through Melanie, Vinny and Andrus in the rebuilt game, and Enter began Andrus's prologue.

### CL-004, CL-008, CL-009: Manual-save data loss and selection crash

The original save GUI allocates `ItemCount+1`, which can overwrite a manual save after a gap and can use character autosave slots 1-3. Save, load and delete also use the deprecated global `savegameindex[]`; filling the other list changes that map and can redirect the operation to the wrong file. Selection callbacks read `Items[-1]` when nothing is selected, causing a native engine error. The 20-save limit can be bypassed with no row selected.

Repairs search actual unused manual slots 4-100, enforce 20 manual saves, use each list's `SaveGameSlots[]`, validate selections, and clear stale names safely. Explicit overwrite uses the selected row, including when descriptions are duplicated. Existing save files are not migrated or renamed.

| Suite | Original result | Repaired result |
| --- | --- | --- |
| Saves | 2 pass, 11 fail | 13 pass, 0 fail |
| SaveSelection | Test entered; engine crashed on invalid list index | 3 pass, 0 fail |

The save suite calls the actual GUI callbacks, creates gaps, refreshes competing lists, checks capacity, and restores the requested slot to verify its money value. The selection suite reproduces the original native `ListBox.Items: invalid index specified` error. All files are confined to disposable test profiles.

```powershell
.\tests\Run-Regression.ps1 -Suite Saves -Original
.\tests\Run-Regression.ps1 -Suite Saves
.\tests\Run-Regression.ps1 -Suite SaveSelection -Original
.\tests\Run-Regression.ps1 -Suite SaveSelection
```

Evidence:

- Original save operations: `.playtest/regression-original-saves-20261021-174628-540`
- Final repaired save operations: `.playtest/regression-fixed-saves-20261021-175447-582`
- Original selection crash: `.playtest/regression-original-saveselection-20261021-174629-400/engine.log`
- Repaired selection: `.playtest/regression-fixed-saveselection-20261021-174731-629`

### CL-007: Register display and recorded change diverge

Original denomination handlers count occupied slots rather than finding an empty slot, omit the final slot from the count, and overwrite visible money when a gap exists or the area is full. Dimes, nickels and pennies also increment occupancy twice. This leaves `changeclimbing` inconsistent with the cash that can be removed from the screen.

The repair finds the first free bill or coin slot, refuses insertion when full, records one occupied slot, and updates the receipt from the resulting amount. Denominations, sprite ranges and existing removal handlers are preserved.

| Tested code | Pass | Fail |
| --- | ---: | ---: |
| Original register handlers | 0 | 11 |
| Repaired register handlers | 11 | 0 |

Coverage includes insertion into gaps, preservation of later bills and coins, removing visible money back to zero, rejecting extra money when full, and coin occupancy. The separate key-jangling report remains unverified.

```powershell
.\tests\Run-Regression.ps1 -Suite CashRegister -Original
.\tests\Run-Regression.ps1 -Suite CashRegister
```

Evidence:

- `.playtest/regression-original-cashregister-20261021-174355-726`
- `.playtest/regression-fixed-cashregister-20261021-174634-012`

### CL-006, CL-010, CL-011: Hot-dog refusal, pricing and ingredient availability

Confirmed in the engine: cancelled orders fall through into preparation and consume a preparation bonus; accepting a plain fallback after an expensive sauerkraut request cancels the sale; one-cent ketchup/mustard and chili prices fall between branches; everything orders add and budget-check the base hot-dog price twice; missing inventory or depleted counters can skip the proper unavailable-stock path.

The repair returns after cancellation, retains accepted plain fallback transactions, includes one cent in paid-topping branches, charges the everything total once, and consistently requires positive inventory and portions for available ingredients.

| Tested code | Pass | Fail |
| --- | ---: | ---: |
| Checkpoint order code | 6 | 22 |
| Repaired order code | 28 | 0 |

The fixture runs actual `Toppins`, dialogue state changes and cancellation. It makes the random plain/refusal choice deterministic, skips dialogue waits, and replaces the body of `Make` with an entry counter. It verifies whether preparation is invoked, rather than playing the preparation minigame or completing checkout. It covers all four priced refusal types, the accepted plain fallback, one-cent totals, exact customer budget, free/paid sauerkraut, missing inventory, zero portions and negative portions. The checkpoint already contained the first sauerkraut price/stock repairs, so those assertions also guard against regressions.

```powershell
.\tests\Run-Regression.ps1 -Suite Hotdog -Original
.\tests\Run-Regression.ps1 -Suite Hotdog
```

Evidence:

- `.playtest/regression-original-hotdog-20261021-175224-511`
- `.playtest/regression-fixed-hotdog-20261021-175311-308`

This bug-hunt pass added 55 passing engine assertions across saves, selection, register and orders. Assertion counts are not counts of distinct bugs. No fixture code is present in the normal game scripts.

### Broader sweep: shopping, expense records and food inventory

At the user's request, the hotel issue is set aside. The next sweep exercised purchases across CDs, books, sandwiches, a lighter, premium coffee and supplies, and inventory consumption with Melanie selected.

Confirmed repairs:

- CL-013: Twelve purchase branches recheck affordability after the common code has already deducted the price. With exact cash, or some change left, the game takes payment but does not give the item. Those redundant checks are removed; the original pre-payment affordability check remains.
- CL-014: Several food/book/lighter branches add local or superstore spending a second time, sometimes using a different hardcoded price. Spending is now recorded once by the common transaction code, and item expense/receipt values use the actual paid price.
- CL-015: Buying grade-S coffee increments `spent_coffeeA`. It now updates `spent_coffeeS`, preserving grade-A costs.
- CL-016: Twenty-four normal purchase receipts use `$.2f` rather than `$%.2f`, displaying a literal format string. These receipts now display the paid dollar amount.
- CL-017: Eating `Oldsand` removes `Dayold`. The consumption branch now removes the old sandwich and preserves the other inventory item.

| Suite | Original | Repaired |
| --- | --- | --- |
| Shopping | 45 pass, 33 fail | 78 pass, 0 fail |
| Inventory | 18 pass, 2 fail | 20 pass, 0 fail |

Shopping coverage: exact cash for 17 products, a CD purchase with change left over, insufficient funds, inventory delivery, single payment, local spending totals, miscellaneous expenses, grade-S versus grade-A coffee costs, purchased portions, and receipt formatting. It calls the real purchase callback; only dialogue-reading delays are skipped and the receipt argument is captured before the normal popup clears it. It does not test every store's stock list or every special-equipment branch.

Inventory coverage: actual description, food-confirmation, consumption and animation flow for old/day-old sandwiches, meat/veggie sandwiches, milk and cocoa. The normal eating/drinking animations run. The fixture suppresses unrelated global gameplay loops and selects Melanie's animation/state profile; it does not complete her story introduction.

```powershell
.\tests\Run-Regression.ps1 -Suite Shopping -Original
.\tests\Run-Regression.ps1 -Suite Shopping
.\tests\Run-Regression.ps1 -Suite Inventory -Original
.\tests\Run-Regression.ps1 -Suite Inventory
```

Evidence:

- Original shopping: `.playtest/regression-original-shopping-20261021-180106-573`
- Repaired shopping: `.playtest/regression-fixed-shopping-20261021-180312-880`
- Original inventory: `.playtest/regression-original-inventory-20261021-180416-177`
- Repaired inventory: `.playtest/regression-fixed-inventory-20261021-180539-602`

This broader pass adds 98 passing engine assertions. Test profiles have their own saves and never change the player's saves.

### 2026-10-22 sweep: equipment and cooking

This pass uses the source checkpoint `.checkpoints/2026-10-22-before-bughunt/GlobalScript.asc` for before/after comparisons. The checkpoint also preserves `CustomFunctions.asc` and SHA-256 hashes. Earlier repairs remain in both sides of these comparisons.

Confirmed repairs:

- CL-018: Cream cheese accepts one portion of buttermilk but consumes two, allowing negative stock. Its guard now requires two buttermilk, one salt and four milk. The plain-bagel recipe now requires positive sugar rather than accepting any nonzero value. Rejected recipes preserve their ingredients.
- CL-019: Special-bagel restocking compares every destination against flavor slot 1. Restocking flavors in slots 2-4 can consume dough without producing bagels, or create a duplicate flavor in an unused slot. Selection now searches all occupied slots for a matching flavor before choosing an empty slot.
- CL-020: Baking a new flavor when all four flavor slots are occupied leaves the cooking overlay visible after the room has faded out. The rejection now restores the display and normal overlay controls while retaining the dough and existing batches.
- CL-021: The pawn-shop stereo costs $70 but records only $60 in local spending and classifies it as miscellaneous. It now records $70 as equipment, matching the payment and the stereo's ordinary shop classification.
- CL-022: The stereo and premium espresso machine remain in an open purchase popup after their single seller-stock item has been removed. Successful purchases now close those popups.

| Suite | Before repairs | After repairs |
| --- | --- | --- |
| Cooking | 8 pass, 9 fail | 17 pass, 0 fail |
| Equipment | 16 pass, 4 fail | 20 pass, 0 fail |

Cooking coverage includes insufficient and exact recipe quantities, restocking all four existing flavors, preferring a matching flavor over an unused slot, successful dough consumption, and preserving dough/batches while releasing the overlay at full flavor capacity. The fixture uses the actual bake and recipe callbacks and normal cooking animations, at an increased game speed. It replaces only the blocking insufficient-ingredient popup with the game's ordinary notification so rejection tests require no human dismissal.

Equipment coverage includes exact and insufficient payment, inventory delivery, seller-stock removal, spending and expense categories, sold-out popups, Melanie's espresso-machine access, Andrus's drink-book requirement, and Vinny's drink-book/battery requirements. Dialogue reading waits are skipped; purchase logic is unchanged in the fixture. These are isolated interaction tests, not completed character story playthroughs.

```powershell
.\tests\Run-Regression.ps1 -Suite Cooking -Original
.\tests\Run-Regression.ps1 -Suite Cooking
.\tests\Run-Regression.ps1 -Suite Equipment -Original
.\tests\Run-Regression.ps1 -Suite Equipment
```

Evidence:

- Original cooking: `.playtest/regression-original-cooking-20261022-055616-697`
- Repaired cooking: `.playtest/regression-fixed-cooking-20261022-055932-479`
- Original equipment: `.playtest/regression-original-equipment-20261022-055617-046`
- Repaired equipment: `.playtest/regression-fixed-equipment-20261022-055933-284`

The first repair compilation caught an extra closing brace in the rewritten bagel function; it was corrected before the successful runs above. The normal Windows game then compiled successfully with AGS 3.6.2.21 at 06:00 on 2026-10-22 (America/Los_Angeles), report `build-logs/20261022-060036-806.json`. All 37 new assertions pass. Regression-runner PowerShell syntax and `git diff --check` pass. The normal scripts contain no test hooks.

### 2026-10-22 sweep: community reports and bagel/register transactions

Online research found historic reports in the [source repository's collected Steam bugs](https://github.com/gondur/cartlife_src/issues/2), the [version 1.6 FAQ](https://gamefaqs.gamespot.com/pc/696505-cart-life-2013/faqs/68657), and [firsthand Steam discussion](https://steamcommunity.com/app/233390/discussions/0/810919691033966496/). `COMMUNITY-BUGS.md` maps these reports to local repairs and remaining leads. Historic reports are not assumed to reproduce in this port.

Confirmed repairs:

- CL-012: Register key/drawer callbacks use the drawer's actual state, ignore input during opening/payment animations, and allow checkout only once during closing. The original key handler can fail the first click depending on its sprite frame, fail a rapid second click, and credit checkout more than once. The drawer path now follows the same state checks.
- CL-023: A topped bagel with exactly four menu entries can read `Menu.Items[4]`, causing `ListBox.Items: invalid index specified`. Choice construction now iterates within the actual item count, excludes duplicate/correct distractors, and supplies fallback answers for short menus.
- CL-024: Store-bought cream cheese can retain the plain order type; topping prices are missing from preparation/change calculation; PB+J and lox orders have no checkout credit or bagel consumption; homemade cheese is consumed twice; toasting consumes unrelated cheese; several variants reuse stale typing phrases. Accepted regular bagel variants now carry the complete price and order type through preparation and checkout. Ingredients are consumed on a successful sale or wasted preparation, with retry waste counted separately.
- CL-025: Full topping names wrap across answer rows, and the right-hand answer label is too short even for two ordinary lines. The label height now matches the left-hand label. Compact topping names fit all four answer positions without changing the actual sale item.
- CL-026: Melanie can commit the $1200 stand purchase without sufficient funds. The purchase now rejects balances below $1200 before dialogue, expenses or stand design; exact/excess payment proceeds normally.

| Suite | Before repairs | After repairs |
| --- | --- | --- |
| CommunityBagels | 21 pass, 28 fail | 49 pass, 0 fail |
| OrderChoices | Test entered; native invalid-index error before completing the first case | 136 pass, 0 fail |
| RegisterTiming | 3 pass, 8 fail | 11 pass, 0 fail |
| StandPurchase | 3 pass, 4 fail | 7 pass, 0 fail |

All 203 assertions pass. The first layout verification exposed the short right-hand label; expanded checks also caught cream-cheese/lox names still wrapping after the first abbreviation. Both were corrected before the final passing runs. The native font measurements are retained in `saves/label-metrics.txt` for OrderChoices.

Coverage and limits:

- CommunityBagels exercises actual customer negotiation, `Make`, checkout, failure animations, spill and retry accounting. It covers store-bought/homemade cream cheese, PB+J, lox/capers, toasted and plain fallback orders, change-calculation price, income and remaining ingredients. Dialogue reading waits are skipped. Callback entry is automated; a complete customer interaction through physical mouse/keyboard input remains unverified.
- OrderChoices fixes the random answer position in the disposable test copy. It covers menu sizes 0-6 for PB+J, all four positions for the other regular bagel variants, label bounds using the engine's fonts, and acceptance of the displayed correct answer.
- RegisterTiming calls real key/drawer handlers and real failure logic. Checkout entry is counted rather than executing a second full transaction in that suite; actual checkout is covered in CommunityBagels.
- StandPurchase checks $0, $1199.99, $1200 and $1500, expense entries and entry into stand design. It does not complete construction/delivery.

Before-repair scripts, the original GUI layout and SHA-256 hashes are in `.checkpoints/2026-10-22-before-community/`. `-Original` restores that source and layout in disposable projects, retaining earlier independent repairs. Original runs intentionally fail. Commands are listed in `COMMUNITY-BUGS.md`.

Evidence directories:

- Original bagels: `.playtest/regression-original-communitybagels-20261022-062714-574`
- Repaired bagels: `.playtest/regression-fixed-communitybagels-20261022-062924-067`
- Original order-menu crash: `.playtest/regression-original-orderchoices-20261022-061740-338/engine.log`
- Repaired order menus/layout: `.playtest/regression-fixed-orderchoices-20261022-063043-896`
- Original register timing: `.playtest/regression-original-registertiming-20261022-062715-409`
- Repaired register timing: `.playtest/regression-fixed-registertiming-20261022-062532-731`
- Original stand purchase: `.playtest/regression-original-standpurchase-20261022-061740-624`
- Repaired stand purchase: `.playtest/regression-fixed-standpurchase-20261022-062533-031`

The normal Windows game compiled successfully with AGS 3.6.2.21 at 06:32 on 2026-10-22 (America/Los_Angeles), report `build-logs/20261022-063153-069.json`. `cartlife/Compiled/Windows/cartlife.exe` includes these repairs. Existing event-handler warnings remain; compilation exits 0 and explicitly reports success. PowerShell syntax, `git diff --check` and the normal-source test-hook check pass.

## Startup and persistence checks

All three protagonists passed isolated checks of the actual `newgame` function, starting room, selected player, starting money and a character-specific inventory item. Each test saved to slot 40, deliberately changed money and removed that item, then restored and verified the original values. Each also loaded that save in a fresh OS process and verified restart to character selection while keeping the save on disk.

| Character | Starting money checked | Inventory item checked | Result |
| --- | ---: | --- | --- |
| Andrus | $2250.00 | Lighter | Pass |
| Melanie | $1560.00 | Cellphone | Pass |
| Vinny | $202.60 | Recipe book | Pass |

These startup tests exercise initialization and engine persistence; the separate Saves suite above exercises manual-save allocation. Complete introductions and story progression remain outside their coverage. Test builds contain isolated hooks, never added to the normal project.

```powershell
.\tests\Run-Regression.ps1 -Suite Startup -Character Andrus
.\tests\Run-Regression.ps1 -Suite Startup -Character Melanie
.\tests\Run-Regression.ps1 -Suite Startup -Character Vinny
```

Evidence directories (results under `saves/regression-results.txt`):

- `.playtest/regression-startup-andrus-20261021-173001-640`
- `.playtest/regression-startup-melanie-20261021-173124-140`
- `.playtest/regression-startup-vinny-20261021-173058-210`

## Hotel-stair regression

Following the user's clarification that the jump happened while climbing to Andrus's room, a disposable fixture exercised room 7's actual ascent/descent handler bodies. Only their keyboard trigger conditions were replaced for deterministic execution. Both flights were climbed and descended, with and without the cat, and a cough was triggered at each landing.

| Tested code | Pass | Fail |
| --- | ---: | ---: |
| Original withdrawal code on the hotel stairs | 17 | 8 |
| Repaired withdrawal code on the hotel stairs | 25 | 0 |

All eight original failures were unreleased cough views. Both versions reached the expected landings and preserved coordinates through each cough. The final check triggered a cough on the first landing, resumed the normal global gameplay loop, and verified that Andrus remained at room 7, x=417, y=139 for 40 frames. Neither version reproduced a return to the ground floor in this fixture. CL-003 remains open; this test does not reproduce every story state or held-key timing.

```powershell
.\tests\Run-Regression.ps1 -Suite HotelStairs -Original # Expected: eight failures.
.\tests\Run-Regression.ps1 -Suite HotelStairs           # Expected: 25 passes.
```

Evidence directories (results under `saves/regression-results.txt`):

- `.playtest/regression-original-hotel-stairs-20261021-173417-035`
- `.playtest/regression-hotel-stairs-20261021-173742-500`

The editor writes a shared `WindowConfig.json` when closing. Concurrent compiler processes caused a sharing violation during one test run. The build and regression scripts now share a compiler mutex and impose a two-minute compiler timeout; the successful stair recheck ran by itself. PowerShell syntax validation and `git diff --check` passed.

The latest main Windows build succeeded at 06:32 on 2026-10-22 (America/Los_Angeles), using AGS 3.6.2.21, including the equipment, cooking and community-led repairs above. Its report is `build-logs/20261022-063153-069.json`. The executable is `cartlife/Compiled/Windows/cartlife.exe`. PowerShell syntax validation, `git diff --check` and the normal-source test-hook check passed. Existing event-handler warnings remain in the compiler report.

The earlier 17:55 normal executable was launched in the separate `bugfix-pass` profile. Native-window screenshots confirmed startup at character selection and individual Right presses selecting Melanie, Vinny and Andrus. This checks that build's launch and keyboard selection; the engine regression results above come from disposable fixture builds.

## Open issues

| ID | Priority | Issue | Evidence / next check |
| --- | --- | --- | --- |
| CL-003 | Deferred | Reported return to ground floor | Set aside at the user's request. Do not prioritize further investigation unless requested. Prior evidence is retained above. |
| CL-005 | High | Missing or unlinked event handlers | Captured in build reports; investigate each event against intended behavior. The save/load buttons were checked in Game.agf and are correctly linked; similarly named decorative controls produce some warnings. |

## Remaining verification

- Finish introductions and check movement, story progression and room transitions for all three characters.
- Compare time/story state in longer playthrough saves and exercise the save GUI through native mouse/keyboard input.
- Complete real customer transactions through preparation, ingredient consumption and checkout.
- Check event-handler warnings and complete day-one playtests for each protagonist.

The local recovery checkpoint is a Git bundle plus exact changed-file copies and the Windows build, with SHA-256 hashes in `.checkpoints/2026-10-21-before-playtesting/manifest.json`. It is not a new Git commit.
