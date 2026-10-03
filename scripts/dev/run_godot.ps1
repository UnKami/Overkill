param(
    [string]$Scene = '',
    [string]$Profile = 'development',
    [switch]$Headless,
    [int]$QuitAfter = 0,
    [string[]]$UserArguments = @()
)
# Run actual project scenes so autoloads and resources are initialized. Direct
# --script checks of gameplay classes are not valid game tests.
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
if ($Profile -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Profile must be a simple folder name' }
$engine = Join-Path $projectRoot '.tools/Godot_v4.5.1-stable_win64_console.exe'
if (!(Test-Path -LiteralPath $engine)) { throw "Godot runtime is missing: $engine" }
if ($Scene) {
    $relativeScene = $Scene.Replace('res://', '').Replace('\', '/')
    $resolvedScene = (Resolve-Path (Join-Path $projectRoot $relativeScene)).Path
    if (!$resolvedScene.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetExtension($resolvedScene) -ne '.tscn') {
        throw 'Choose a .tscn scene inside this project'
    }
    $Scene = "res://$relativeScene"
}
$profileRoot = Join-Path $projectRoot ".tools/042-audit-profile/$Profile"
$localProfile = Join-Path $profileRoot 'Local'
New-Item -ItemType Directory -Force $profileRoot, $localProfile | Out-Null
$previousAppData = $env:APPDATA
$previousLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $profileRoot
    $env:LOCALAPPDATA = $localProfile
    $arguments = @('--path', $projectRoot, '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--log-file', (Join-Path $profileRoot 'godot.log'))
    if ($Headless) { $arguments += '--headless' }
    else { $arguments += @('--windowed', '--resolution', '1280x720') }
    if ($QuitAfter -gt 0) { $arguments += @('--quit-after', "$QuitAfter") }
    if ($Scene) { $arguments += $Scene }
    if ($UserArguments.Count) { $arguments += '--'; $arguments += $UserArguments }
    & $engine @arguments
    $result = $LASTEXITCODE
    if ($result -ne 0) { throw "Godot exited with $result. Read $profileRoot/godot.log before another launch." }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalData
}
