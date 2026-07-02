[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$GameRoot
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repositoryRoot "Distribution\DriveBeyondHorizons"
$gameRootPath = [System.IO.Path]::GetFullPath($GameRoot)
$shippingExecutable = Join-Path $gameRootPath "DriveBeyondHorizons\Binaries\Win64\DriveBeyondHorizons-Win64-Shipping.exe"

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
    throw "Missing prerequisite(s): $($missing -join ', ')"
}

if ($PSCmdlet.ShouldProcess($gameRootPath, "Install Assembly Not Included")) {
    Copy-Item -Path (Join-Path $source "*") -Destination $gameRootPath -Recurse -Force
    Write-Host "Assembly Not Included installed successfully."
}

