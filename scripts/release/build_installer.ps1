param(
    [string]$Godot = "$PSScriptRoot/../../.tools/Godot_v4.5.1-stable_win64_console.exe",
    [string]$Compiler = "$env:LOCALAPPDATA/Programs/Inno Setup 6/ISCC.exe"
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$version = (Get-Content -Raw "$projectRoot/VERSION").Trim()
$buildDir = Join-Path $projectRoot 'build/windows'
$installerDir = Join-Path $projectRoot 'installer'
$godotPath = (Resolve-Path $Godot).Path
$runtime = $godotPath.Replace('_console.exe', '.exe')
if (!(Test-Path -LiteralPath $Compiler)) { throw "Inno Setup compiler not found: $Compiler" }
New-Item -ItemType Directory -Force $buildDir | Out-Null
Push-Location $projectRoot
try {
    & $godotPath --headless --path $projectRoot --export-pack 'Windows Desktop' "$buildDir/Overkill.pck"
    if ($LASTEXITCODE -ne 0) { throw 'Godot resource export failed' }
    # Ship the same official runtime already used for local gameplay verification.
    Copy-Item -LiteralPath $runtime -Destination "$buildDir/Overkill.exe"
    Copy-Item -LiteralPath "$projectRoot/installer/GODOT-LICENSE.txt" -Destination "$buildDir/GODOT-LICENSE.txt"
    $delivery = Get-Content -Raw "$projectRoot/docs/presentation-014.md"
    Set-Content -LiteralPath "$buildDir/DELIVERY.md" -Value $delivery -Encoding utf8
    @'
@echo off
setlocal
set "APPDATA=%LOCALAPPDATA%\OverkillSentinel"
if not exist "%APPDATA%" mkdir "%APPDATA%"
set "LOCALAPPDATA=%APPDATA%"
cd /d "%~dp0"
start "" "%~dp0Overkill.exe" --scene res://scenes/sentinel_encounter.tscn
endlocal
'@ | Set-Content -LiteralPath "$buildDir/Play Sentinel.cmd" -Encoding ascii
    $compile = Start-Process -FilePath $Compiler -ArgumentList @("/DAppVersion=$version", "/O`"$installerDir`"", "`"$installerDir/overkill.iss`"") -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput "$buildDir/installer-compile.log" -RedirectStandardError "$buildDir/installer-compile-errors.log"
    if ($compile.ExitCode -ne 0) { throw "Installer compilation failed; see $buildDir/installer-compile-errors.log" }
    Get-Item -LiteralPath "$installerDir/OverkillSetup-$version.exe"
} finally { Pop-Location }
