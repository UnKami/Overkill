param([string]$Payload = 'build/windows')
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$version = (Get-Content -Raw (Join-Path $projectRoot 'VERSION')).Trim()
$payloadRoot = (Resolve-Path -LiteralPath (Join-Path $projectRoot $Payload)).Path
$buildRoot = Join-Path $projectRoot 'build'
$installerRoot = Join-Path $projectRoot 'installer'
$zipPath = Join-Path $buildRoot "Overkill-$version-Windows.zip"
$installerPath = Join-Path $installerRoot "OverkillSetup-$version.exe"
$manifestPath = Join-Path $installerRoot "OverkillSetup-$version.sha256"
$expected = @('Overkill.exe', 'Overkill.pck', 'GODOT-LICENSE.txt', 'DELIVERY.md', 'Play Overkill.cmd')
foreach ($name in $expected) {
    if (!(Test-Path -LiteralPath (Join-Path $payloadRoot $name) -PathType Leaf)) { throw "Portable payload is missing $name" }
}
if (!(Test-Path -LiteralPath $installerPath -PathType Leaf)) { throw "Installer is missing: $installerPath" }
if (Test-Path -LiteralPath $zipPath) { throw "Portable ZIP already exists; move it aside before rebuilding: $zipPath" }
$files = $expected | ForEach-Object { Join-Path $payloadRoot $_ }
Compress-Archive -LiteralPath $files -DestinationPath $zipPath -CompressionLevel Optimal
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $actual = @($archive.Entries | ForEach-Object { $_.FullName } | Sort-Object)
    $wanted = @($expected | Sort-Object)
    if (Compare-Object $wanted $actual) { throw "Portable ZIP content differs from the five-file allowlist: $($actual -join ', ')" }
} finally { $archive.Dispose() }
$installerHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
@("$installerHash  $(Split-Path $installerPath -Leaf)", "$zipHash  $(Split-Path $zipPath -Leaf)") | Set-Content -LiteralPath $manifestPath -Encoding ascii
[pscustomobject]@{
    installer = $installerPath
    installer_bytes = (Get-Item -LiteralPath $installerPath).Length
    installer_sha256 = $installerHash
    portable_zip = $zipPath
    portable_bytes = (Get-Item -LiteralPath $zipPath).Length
    portable_sha256 = $zipHash
    zip_entries = ($actual -join ', ')
} | Format-List
