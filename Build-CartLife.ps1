[CmdletBinding()]
param(
    [string]$EditorPath = 'C:\Program Files (x86)\Adventure Game Studio 3.6.2\AGSEditor.exe'
)

$ErrorActionPreference = 'Stop'
$projectPath = Join-Path $PSScriptRoot 'cartlife\Game.agf'
$reportDirectory = Join-Path $PSScriptRoot 'build-logs'
$lockPath = Join-Path $PSScriptRoot 'cartlife\_OpenInEditor.lock'
$executablePath = Join-Path $PSScriptRoot 'cartlife\Compiled\Windows\cartlife.exe'

if (-not (Test-Path -LiteralPath $EditorPath -PathType Leaf)) {
    throw "AGS editor not found: $EditorPath. Supply -EditorPath for another installation."
}
if (Test-Path -LiteralPath $lockPath) {
    try {
        $lockProbe = [IO.File]::Open($lockPath, 'Open', 'ReadWrite', 'None')
        $lockProbe.Dispose()
    }
    catch {
        throw 'The project is open in another AGS editor. Close that project before running this build.'
    }
}
if (Test-Path -LiteralPath $executablePath) {
    try {
        $executableProbe = [IO.File]::Open($executablePath, 'Open', 'ReadWrite', 'None')
        $executableProbe.Dispose()
    }
    catch {
        throw 'The Windows game executable is in use. Close the running Cart Life game before building.'
    }
}

New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
$runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$stdoutPath = Join-Path $reportDirectory "$runId.stdout.log"
$stderrPath = Join-Path $reportDirectory "$runId.stderr.log"
$started = [DateTimeOffset]::Now
$compilerGate = [Threading.Mutex]::new($false, 'Local\CartLifeAgsCompile')
if (-not $compilerGate.WaitOne(120000)) { $compilerGate.Dispose(); throw 'Timed out waiting for another AGS build.' }
try {
    $compiler = Start-Process -FilePath $EditorPath -ArgumentList ('"' + $projectPath + '" /compile') `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    # Windows PowerShell 5.1 only reports ExitCode for a redirected process if its handle was read.
    $null = $compiler.Handle
    if (-not $compiler.WaitForExit(120000)) {
        $compiler.Kill()
        throw "AGS compiler timed out. Inspect $stdoutPath and $stderrPath."
    }
}
finally { $compilerGate.ReleaseMutex(); $compilerGate.Dispose() }
$output = [IO.File]::ReadAllText($stdoutPath)
$errors = [IO.File]::ReadAllText($stderrPath)
# Some editor startup failures exit with zero. Require its explicit success message too.
$succeeded = $compiler.ExitCode -eq 0 -and $output.Contains('AGS: Compilation successful!')
$summary = [ordered]@{
    Started = $started.ToString('o')
    Completed = [DateTimeOffset]::Now.ToString('o')
    Editor = $EditorPath
    EditorVersion = (Get-Item -LiteralPath $EditorPath).VersionInfo.FileVersion
    Project = $projectPath
    ExitCode = $compiler.ExitCode
    Success = $succeeded
    Stdout = $stdoutPath
    Stderr = $stderrPath
    Diagnostics = @($output -split '\r?\n' | Where-Object { $_ -match '^AGS:' -and $_ -notmatch 'Compilation successful!' })
}
$summaryPath = Join-Path $reportDirectory "$runId.json"
$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
Copy-Item -LiteralPath $summaryPath -Destination (Join-Path $reportDirectory 'latest.json')
Write-Output $output
if ($errors) { Write-Warning $errors }
Write-Output "Build report: $summaryPath"
if (-not $succeeded) { throw "AGS build failed (exit $($compiler.ExitCode)). See $stdoutPath and $stderrPath." }
