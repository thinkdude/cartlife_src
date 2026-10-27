[CmdletBinding()]
param(
    [switch]$Original,
    [ValidateSet('Withdrawal','Startup','HotelStairs','Saves','CashRegister','SaveSelection','Hotdog','Shopping','Inventory','Equipment','Cooking','CommunityBagels','OrderChoices','RegisterTiming','StandPurchase')]
    [string]$Suite = 'Withdrawal',
    [ValidateSet('Andrus','Melanie','Vinny')]
    [string]$Character = 'Andrus',
    [string]$EditorPath = 'C:\Program Files (x86)\Adventure Game Studio 3.6.2\AGSEditor.exe'
)

$ErrorActionPreference='Stop'
$repository=Split-Path $PSScriptRoot
$source=Join-Path $repository 'cartlife'
$label=if ($Suite -in 'Saves','CashRegister','SaveSelection','Hotdog','Shopping','Inventory','Equipment','Cooking','CommunityBagels','OrderChoices','RegisterTiming','StandPurchase') { $(if ($Original) {'original-'} else {'fixed-'})+$Suite.ToLowerInvariant() } elseif ($Original -and $Suite -eq 'HotelStairs') { 'original-hotel-stairs' } elseif ($Original) { 'original' } elseif ($Suite -eq 'Startup') { 'startup-' + $Character.ToLowerInvariant() } elseif ($Suite -eq 'HotelStairs') { 'hotel-stairs' } else { 'fixed' }
if ($Original -and $Suite -eq 'Startup') { throw '-Original is not supported for the Startup suite.' }
$run=Join-Path $repository ('.playtest\regression-' + $label + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$project=Join-Path $run 'project'
$saves=Join-Path $run 'saves'
$shared=Join-Path $run 'shared'
New-Item -ItemType Directory -Path $project,$saves,$shared -Force | Out-Null

# Copies, never hard links: the editor is allowed to rewrite room/sprite files.
Get-ChildItem -LiteralPath $source -File | Where-Object {
    $_.Extension -in '.asc','.ash','.agf','.crm','.ttf','.spr','.dat','.ico','.pcx','.pal','.bmp'
} | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $project }
foreach ($assetDirectory in @('AudioCache','Speech','resources')) {
    Copy-Item -LiteralPath (Join-Path $source $assetDirectory) -Destination $project -Recurse
}
$encoding=[Text.Encoding]::GetEncoding(1252)
$globalPath=Join-Path $project 'GlobalScript.asc'
$globalText=[IO.File]::ReadAllText($globalPath,$encoding)
if ($Original) {
    $originalPath=Join-Path $repository '.checkpoints\2026-10-21-before-playtesting\working-files\cartlife\GlobalScript.asc'
    if ($Suite -in 'Equipment','Cooking','CommunityBagels','OrderChoices','RegisterTiming','StandPurchase') { $originalPath=Join-Path $repository '.checkpoints\2026-10-22-before-bughunt\GlobalScript.asc' }
    if ($Suite -in 'CommunityBagels','OrderChoices','RegisterTiming','StandPurchase') {
        $checkpoint=Join-Path $repository '.checkpoints\2026-10-22-before-community'
        $originalPath=Join-Path $checkpoint 'GlobalScript.asc'
        foreach ($script in @('CustomFunctions.asc','DialogRequesting.asc','Game.agf')) {
            Copy-Item -LiteralPath (Join-Path $checkpoint $script) -Destination (Join-Path $project $script)
        }
    }
    $originalText=[IO.File]::ReadAllText($originalPath,$encoding)
    if ($Suite -in 'Saves','CashRegister','SaveSelection','Hotdog','Shopping','Inventory','Equipment','Cooking','CommunityBagels','OrderChoices','RegisterTiming','StandPurchase') { $globalText=$originalText }
    else {
    $start=$originalText.IndexOf('////==================// nicotine withdrawel coughing')
    $end=$originalText.IndexOf('if (((IsKeyPressed(372)==1)||(IsKeyPressed(87)==1))', $start)
    if ($start -lt 0 -or $end -lt 0) { throw 'Original withdrawal code not found' }
    $originalHelper='function UpdateAndrusWithdrawal() {' + "`r`n" + $originalText.Substring($start,$end-$start) + "`r`n}`r`n"
    $helperStart=$globalText.IndexOf('function UpdateAndrusWithdrawal()')
    $helperEnd=$globalText.IndexOf('function repeatedly_execute() {',$helperStart)
    $globalText=$globalText.Substring(0,$helperStart)+$originalHelper+$globalText.Substring($helperEnd)
    }
}
$fixturePath=Join-Path $PSScriptRoot ($Suite+'Regression.asc')
$fixture=[IO.File]::ReadAllText($fixturePath,$encoding)
if ($Suite -in 'Startup','Saves','CashRegister','SaveSelection','Hotdog','Shopping','Inventory','Equipment','Cooking','CommunityBagels','OrderChoices','RegisterTiming','StandPurchase') {
    $globalText=$globalText.Replace('function repeatedly_execute() {','function repeatedly_execute() { return;')
}
if ($Suite -eq 'Cooking') {
    # Replace only the blocking rejection popup so invalid-recipe tests need no
    # human dismissal. Conditions, stock changes and cooking animations remain.
    $globalText=$globalText.Replace('DisplayTopBar(35, 8, 8, "", "Insufficient ingredients!");','TopUp("Insufficient ingredients", "Insufficient ingredients!");')
}
if ($Suite -eq 'Startup') {
    $characterId=@{Andrus='1'; Melanie='2'; Vinny='3'}[$Character]
    $fixture=$fixture.Replace('__CHARACTER__',$characterId)
    # Keep unrelated time, selling and story loops out of the isolated persistence test.
}
if ($Suite -ne 'Withdrawal') { $globalText+="`r`n"+$fixture }
else { $globalText=$globalText.Replace('function repeatedly_execute() {', $fixture+"`r`nfunction repeatedly_execute() {") }
if ($Suite -eq 'OrderChoices') {
    $globalText="int qaQuiz;`r`n"+$globalText.Replace('int quiz=Random(3);','int quiz=qaQuiz;')
}
if ($Suite -eq 'RegisterTiming') {
    # Count checkout entry while exercising real key logic and Botch behavior.
    $globalText="int qaCheckoutCalls;`r`n"+$globalText.Replace('function checkout(){','function checkout(){ qaCheckoutCalls++; return;')
}
if ($Suite -in 'CommunityBagels','StandPurchase') {
    $customPath=Join-Path $project 'CustomFunctions.asc'
    $custom=[IO.File]::ReadAllText($customPath,$encoding).Replace('function newblab(){','function newblab(){ return;')
    [IO.File]::WriteAllText($customPath,$custom,$encoding)
}
[IO.File]::WriteAllText($globalPath,$globalText,$encoding)
if ($Suite -in 'Shopping','Equipment') {
    $customPath=Join-Path $project 'CustomFunctions.asc'
    $custom=[IO.File]::ReadAllText($customPath,$encoding)
    # Skip dialogue reading delays, preserving the real purchase and receipt code.
    $custom=$custom.Replace('function newblab(){','function newblab(){ return;')
    $custom="String qaLastReceipt;`r`n"+$custom
    $custom=$custom.Replace('function TopItem(String desc, String cost, int itempic){','function TopItem(String desc, String cost, int itempic){ qaLastReceipt=cost;')
    $custom+="`r`nString QaLastReceipt() { return qaLastReceipt; }`r`n"
    [IO.File]::WriteAllText($customPath,$custom,$encoding)
    [IO.File]::AppendAllText((Join-Path $project 'CustomFunctions.ash'),"`r`nimport String QaLastReceipt();`r`n",$encoding)
}
if ($Suite -eq 'Hotdog') {
    $customPath=Join-Path $project 'CustomFunctions.asc'
    $custom=[IO.File]::ReadAllText($customPath,$encoding)
    if ($Original) {
        $custom=[IO.File]::ReadAllText((Join-Path $repository '.checkpoints\2026-10-21-before-playtesting\working-files\cartlife\CustomFunctions.asc'),$encoding)
    }
    # Keep real order negotiation and cancellation. Only make the random fallback
    # deterministic, skip dialogue waits, and count entry to the preparation UI.
    $custom="int qaHotdogChoice;`r`nint qaHotdogMakeCalls;`r`n"+$custom
    $custom=$custom.Replace('int switchhit=Random(1);//Calls a Fifty/Fifty on unmet preferences.','int switchhit=qaHotdogChoice;//Deterministic fallback in this disposable fixture.')
    $custom=$custom.Replace('function newblab(){','function newblab(){ return;')
    $custom=$custom.Replace('function Make(){','function Make(){ qaHotdogMakeCalls++; return;')
    $custom+="`r`nfunction QaHotdogReset(int choice) { qaHotdogChoice=choice; qaHotdogMakeCalls=0; }`r`nint QaHotdogMakeCount() { return qaHotdogMakeCalls; }`r`n"
    [IO.File]::WriteAllText($customPath,$custom,$encoding)
    [IO.File]::AppendAllText((Join-Path $project 'CustomFunctions.ash'),"`r`nimport function QaHotdogReset(int choice);`r`nimport int QaHotdogMakeCount();`r`n",$encoding)
}
$headerPath=Join-Path $project 'GlobalScript.ash'
[IO.File]::AppendAllText($headerPath,"`r`nimport function QaRun();`r`n",$encoding)
$roomPath=Join-Path $project 'room25.asc'
$roomText=[IO.File]::ReadAllText($roomPath,$encoding)
$roomText=[regex]::Replace($roomText,'function room_AfterFadeIn\(\)\s*\{[^}]*\}', 'function room_AfterFadeIn() { QaRun(); }')
[IO.File]::WriteAllText($roomPath,$roomText,$encoding)
if ($Suite -eq 'Saves') {
    [IO.File]::AppendAllText($headerPath,"`r`nimport function QaSaveTick();`r`n",$encoding)
    $roomText=[regex]::Replace($roomText,'function region1_Standing\(\)\s*\{','function region1_Standing() { return;')
    $roomText=[regex]::Replace($roomText,'function room_RepExec\(\)\s*\{','function room_RepExec() { QaSaveTick(); return;')
    [IO.File]::WriteAllText($roomPath,$roomText,$encoding)
}
if ($Suite -eq 'Startup') {
    [IO.File]::AppendAllText($headerPath,"`r`nimport function QaStartupTick();`r`nimport function QaSelectionTick();`r`n",$encoding)
    # newgame must run from character selection: switching player from another
    # room can immediately load that character's current room and end the caller.
    $roomText=[regex]::Replace($roomText,'function room_AfterFadeIn\(\)\s*\{[^}]*\}', 'function room_AfterFadeIn() { player.ChangeRoom(1, 165, 193); }')
    [IO.File]::WriteAllText($roomPath,$roomText,$encoding)
    $selectionPath=Join-Path $project 'room1.asc'
    $selection=[IO.File]::ReadAllText($selectionPath,$encoding)
    $selection=[regex]::Replace($selection,'function room_RepExec\(\)\s*\{','function room_RepExec() { QaSelectionTick(); return;')
    [IO.File]::WriteAllText($selectionPath,$selection,$encoding)
    $prologuePath=Join-Path $project 'room23.asc'
    $prologue=[IO.File]::ReadAllText($prologuePath,$encoding)
    $prologue=[regex]::Replace($prologue,'function room_RepExec\(\)\s*\{','function room_RepExec() { QaStartupTick(); return;')
    [IO.File]::WriteAllText($prologuePath,$prologue,$encoding)
}
if ($Suite -eq 'HotelStairs') {
    [IO.File]::AppendAllText($headerPath,@'

import bool QaForceStairs();
import bool QaHotelReady();
import function QaHotelPrepare(int carryingCat);
import function QaHotelLanding(int expectedX, int expectedY, int flight);
import function QaHotelSettle();
import function QaHotelTick();

'@,$encoding)
    $hotelPath=Join-Path $project 'room7.asc'
    $hotel=[IO.File]::ReadAllText($hotelPath,$encoding)
    # Force only the input conditions; execute the existing stair bodies unchanged.
    $hotel=$hotel.Replace('if ((IsKeyPressed(372)==1)||(IsKeyPressed(87)==1))','if (QaForceStairs())')
    $hotel=$hotel.Replace('if ((IsKeyPressed(380)==1)||(IsKeyPressed(83)==1))','if (QaForceStairs())')
    $hotel=$hotel.Replace('function room_RepExec(){','function QaOriginalRepExec(){')
    $hotel+=@'

function room_RepExec() {
  if (QaHotelReady()) {
    int cat=0;
    while (cat<=1) {
      QaHotelPrepare(cat);
      region3_Standing();
      QaHotelLanding(417, 139, 1);
      region15_Standing();
      QaHotelLanding(398, 75, 2);
      region14_Standing();
      QaHotelLanding(470, 139, 3);
      region2_Standing();
      QaHotelLanding(474, 193, 4);
      cat++;
    }
    QaHotelSettle();
  }
  else QaHotelTick();
}
'@
    [IO.File]::WriteAllText($hotelPath,$hotel,$encoding)
}

$projectPath=Join-Path $project 'Game.agf'
$compileLog=Join-Path $run 'compile.log'
# AGS writes a shared WindowConfig.json when it exits. Serialize our compilers
# even if multiple regression scripts are launched at once.
$compilerGate=[Threading.Mutex]::new($false, 'Local\CartLifeAgsCompile')
if (-not $compilerGate.WaitOne(120000)) { $compilerGate.Dispose(); throw 'Timed out waiting for another AGS build.' }
try {
    $compile=Start-Process -FilePath $EditorPath -ArgumentList ('"'+$projectPath+'" /compile') `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput $compileLog -RedirectStandardError (Join-Path $run 'compile-errors.log')
    # Windows PowerShell 5.1 only reports ExitCode for a redirected process if its handle was read.
    $null=$compile.Handle
    Write-Host "Regression compiler process $($compile.Id); evidence: $run"
    if (-not $compile.WaitForExit(120000)) {
        $compile.Kill()
        throw "Regression compiler timed out: $run"
    }
}
finally { $compilerGate.ReleaseMutex(); $compilerGate.Dispose() }
if ($compile.ExitCode -ne 0 -or -not ([IO.File]::ReadAllText($compileLog).Contains('AGS: Compilation successful!'))) {
    Get-Content -LiteralPath $compileLog
    throw "Regression fixture did not compile: $run"
}
$config=Join-Path $run 'acsetup.cfg'
"[graphics]`r`nwindowed=1`r`nwindow=640x400`r`n" | Set-Content -LiteralPath $config -Encoding ASCII
$gameDirectory=Join-Path $project 'Compiled\Windows'
$arguments='--windowed --background --audiodriver dummy --no-message-box --conf "'+$config+'" --user-data-dir "'+$saves+'" --shared-data-dir "'+$shared+'"'
$engine=Start-Process -FilePath (Join-Path $gameDirectory 'cartlife.exe') -WorkingDirectory $gameDirectory `
    -ArgumentList $arguments -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $run 'engine.log') -RedirectStandardError (Join-Path $run 'engine-errors.log')
$null=$engine.Handle
if (-not $engine.WaitForExit(60000)) {
    $engine.Kill()
    throw "Regression fixture timed out: $run"
}
if ($Suite -eq 'Startup' -and $engine.ExitCode -eq 0) {
    # Restore the same save in a new OS process as well as within the first run.
    Set-Content -LiteralPath (Join-Path $saves 'qa-fresh-process') -Value '1' -Encoding ASCII
    $fresh=Start-Process -FilePath (Join-Path $gameDirectory 'cartlife.exe') -WorkingDirectory $gameDirectory `
        -ArgumentList ($arguments+' --loadsavedgame 40') -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $run 'fresh-engine.log') -RedirectStandardError (Join-Path $run 'fresh-engine-errors.log')
    $null=$fresh.Handle
    if (-not $fresh.WaitForExit(60000)) { $fresh.Kill(); throw "Fresh-process restore timed out: $run" }
    if ($fresh.ExitCode -ne 0) { throw "Fresh-process restore failed (exit $($fresh.ExitCode)): $run" }
}
$resultPath=Join-Path $saves 'regression-results.txt'
if (-not (Test-Path -LiteralPath $resultPath)) { throw "Regression fixture produced no result (exit $($engine.ExitCode)): $run" }
$results=[IO.File]::ReadAllLines($resultPath)
$results
Write-Output "Regression evidence: $run"
if ($engine.ExitCode -ne 0 -or 'COMPLETE' -notin $results -or @($results | Where-Object { $_ -like 'FAIL *' }).Count -gt 0) {
    throw "Regression checks failed: $run"
}
