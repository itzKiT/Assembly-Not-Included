[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$GameRoot
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repositoryRoot "Distribution\DriveBeyondHorizons"
$gameRootPath = [System.IO.Path]::GetFullPath($GameRoot)
$projectRoot = Join-Path $gameRootPath "DriveBeyondHorizons"
$shippingExecutable = Join-Path $projectRoot "Binaries\Win64\DriveBeyondHorizons-Win64-Shipping.exe"
$requiredUe4ssRelease = "https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest"

Write-Host "Required UE4SS build: zDEV archive from $requiredUe4ssRelease"
Write-Host "Stable and non-zDEV UE4SS builds are not supported."

if (-not (Test-Path -LiteralPath $shippingExecutable)) {
    throw "Drive Beyond Horizons was not found at: $gameRootPath"
}

$win64 = Split-Path -Parent $shippingExecutable
$ue4ssMods = Join-Path $win64 "ue4ss\Mods"
$missing = @()

if (-not (Test-Path -LiteralPath (Join-Path $ue4ssMods "BPModLoaderMod"))) {
    $missing += "BPModLoaderMod"
}
if (-not (Test-Path -LiteralPath (Join-Path $ue4ssMods "BPML_GenericFunctions"))) {
    $missing += "BPML_GenericFunctions"
}
if (-not (Get-ChildItem -LiteralPath $win64 -Recurse -File -Filter "*UTOC*Bypass*.asi" -ErrorAction SilentlyContinue)) {
    $missing += "Drive Beyond Horizons UTOC Signature Bypass"
}

if ($missing.Count -gt 0) {
    throw "Missing prerequisite(s): $($missing -join ', '). Install the zDEV UE4SS experimental-latest build from $requiredUe4ssRelease."
}

if ($PSCmdlet.ShouldProcess($projectRoot, "Install Assembly Not Included")) {
    Copy-Item -Path (Join-Path $source "*") -Destination $projectRoot -Recurse -Force
    Write-Host "Assembly Not Included installed successfully."
}
