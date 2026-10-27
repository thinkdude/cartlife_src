[CmdletBinding()]
param(
    [ValidatePattern('^[a-zA-Z0-9_-]+$')]
    [string]$Profile = 'manual',
    [switch]$Background,
    [ValidateRange(1, 998)]
    [int]$LoadSlot
)

$ErrorActionPreference = 'Stop'
$gameDirectory = Join-Path $PSScriptRoot 'cartlife\Compiled\Windows'
$gamePath = Join-Path $gameDirectory 'cartlife.exe'
if (-not (Test-Path -LiteralPath $gamePath)) { throw 'Build the game with Build-CartLife.ps1 first.' }
$profileDirectory = Join-Path $PSScriptRoot ".playtest\$Profile"
$saveDirectory = Join-Path $profileDirectory 'saves'
$sharedDirectory = Join-Path $profileDirectory 'shared'
New-Item -ItemType Directory -Path $saveDirectory,$sharedDirectory -Force | Out-Null
$configPath = Join-Path $profileDirectory 'acsetup.cfg'
if (-not (Test-Path -LiteralPath $configPath)) {
    @'
[graphics]
windowed=1
window=1280x800
game_scale_win=proportional
'@ | Set-Content -LiteralPath $configPath -Encoding ASCII
}
$runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$logPath = Join-Path $profileDirectory "$runId.engine.log"
$arguments = @('--windowed', '--conf', ('"' + $configPath + '"'),
    '--user-data-dir', ('"' + $saveDirectory + '"'),
    '--shared-data-dir', ('"' + $sharedDirectory + '"'),
    '--log-file=main:info,game:info,script:info', ('--log-file-path="' + $logPath + '"'))
if ($Background) { $arguments += '--background' }
if ($PSBoundParameters.ContainsKey('LoadSlot')) { $arguments += @('--loadsavedgame', $LoadSlot) }
$process = Start-Process -FilePath $gamePath -WorkingDirectory $gameDirectory `
    -ArgumentList ($arguments -join ' ') -WindowStyle Normal -PassThru `
    -RedirectStandardOutput (Join-Path $profileDirectory "$runId.stdout.log") `
    -RedirectStandardError (Join-Path $profileDirectory "$runId.stderr.log")
Write-Host "Playtest process $($process.Id); profile: $Profile; saves: $saveDirectory; log: $logPath"
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw "Playtest exited with code $($process.ExitCode). Inspect $logPath." }
