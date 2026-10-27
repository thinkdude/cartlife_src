# Community reports checked against this port

Research date: 2026-10-22. These reports concern the original AGS game. Their age and version differences make them investigation leads; the local results below come from this checkout and AGS 3.6.2.21.

## Sources

- [Combined bugs collected on Steam, source repository issue 2](https://github.com/gondur/cartlife_src/issues/2), opened 2016-04-26. This checkout's README directs bug reporting to that repository.
- [Cart Life FAQ/walkthrough by T Schenkhuizen, version 1.6](https://gamefaqs.gamespot.com/pc/696505-cart-life-2013/faqs/68657), updated 2024-05-28. Includes a bugs section based on the author's playthroughs.
- [Steam discussion with firsthand reports about extras, cookbooks and register cash](https://steamcommunity.com/app/233390/discussions/0/810919691033966496/), March 2013.
- [Steam resolution/startup discussion](https://steamcommunity.com/app/233390/discussions/0/810919057063592571/), March 2013, including a developer response.

## Comparison with local findings

| Reported symptom | Source | Result in this checkout |
| --- | --- | --- |
| Cream-cheese orders and PB+J confirmation problems | Repository issue; FAQ | Reproduced incorrect accepted order, missing topping charges, incomplete PB+J/lox checkout and overflowing answer text. Repairs tracked as CL-024 and CL-025. |
| Crash when preparing bagels with extras | Steam discussion; FAQ | Locally reproduced a specific crash: exactly four menu entries and a topped-bagel sale access nonexistent `Menu.Items[4]`. CL-023 repairs that case; this does not establish the cause of every historic crash. |
| Register key can mark a sale failed when clicked quickly | FAQ | Reproduced. CL-012 now uses drawer/animation state and allows checkout only once. |
| Stand purchase can put Melanie in debt | FAQ | Reproduced at $0 and $1199.99. CL-026 rejects insufficient funds and preserves the balance. Exact and excess payment remain valid. |
| Cash disappears from the register | Repository issue; Steam discussion | Earlier CL-007 repairs slot allocation, overflow and duplicate occupancy accounting. Cross-transaction cash retention is still a separate verification lead. |
| Cookbooks cannot be read | Steam discussion; FAQ | Not reproduced through the live interaction in this pass. A missing Cookbook look handler already appears in compiler diagnostics; its intended behavior still needs investigation. |
| Saturday school/custody inconsistencies | FAQ | Requires a longer Melanie playthrough; not reproduced here. |
| Greyed sales control still responds, or remains grey after conversation | FAQ | Not reproduced here. |
| `too_many_active_buttons` failure | FAQ | Not reproduced here. |
| Oversized pedestrians or disappearing characters | FAQ; repository issue | Not reproduced here. |
| Resolution/startup failure | Steam resolution discussion | This port previously launched successfully in its windowed setup. Other resolutions and hardware remain unverified. |

## Repairs and evidence

The community-led changes are in `GlobalScript.asc`, `CustomFunctions.asc`, `DialogRequesting.asc`, and the confirmation label in `Game.agf`. They also repair related defects found while tracing the reports: stale typing phrases, topping consumption at the wrong stage, missing bagel waste on failed preparation, unrelated cheese loss when toasting, and duplicate register checkout.

Before-repair script copies and GUI layout are preserved in `.checkpoints/2026-10-22-before-community/` with SHA-256 hashes. The original GUI copy restores the pre-repair answer-label height. Earlier independent repairs remain in both sides of the comparison.

Repeat the isolated checks from this repository:

```powershell
.\tests\Run-Regression.ps1 -Suite CommunityBagels -Original
.\tests\Run-Regression.ps1 -Suite CommunityBagels
.\tests\Run-Regression.ps1 -Suite OrderChoices -Original
.\tests\Run-Regression.ps1 -Suite OrderChoices
.\tests\Run-Regression.ps1 -Suite RegisterTiming -Original
.\tests\Run-Regression.ps1 -Suite RegisterTiming
.\tests\Run-Regression.ps1 -Suite StandPurchase -Original
.\tests\Run-Regression.ps1 -Suite StandPurchase
```

Original runs are expected to fail; OrderChoices reproduces a native engine error. All runs use disposable projects and separate saves. Dialogue reading delays are skipped for the bagel and stand suites. RegisterTiming counts checkout entry while exercising the real click handlers and failure logic. CommunityBagels uses the real negotiation, preparation, checkout and spill functions, but calls their callbacks directly. OrderChoices fixes the random answer position to cover all four positions and measures text with the engine's actual fonts. These checks do not replace a complete mouse/keyboard playthrough or establish that every historical report is resolved.

Detailed counts, evidence directories and the normal Windows build report are recorded in `TEST-RESULTS.md`.
