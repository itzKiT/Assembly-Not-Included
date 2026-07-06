[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$EngineRoot,

    [string]$Version = "0.6.6"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repositoryRoot "Source\Unreal"
$projectFile = Join-Path $projectRoot "AssemblyNotIncluded.uproject"
$runUat = Join-Path $EngineRoot "Engine\Build\BatchFiles\RunUAT.bat"
$unrealPak = Join-Path $EngineRoot "Engine\Binaries\Win64\UnrealPak.exe"
$artifacts = Join-Path $repositoryRoot "artifacts"
$work = Join-Path $artifacts "work"
$releaseRoot = Join-Path $work "release"
$packageRoot = Join-Path $releaseRoot "DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded"
$runtimeSource = Join-Path $repositoryRoot "Runtime\AssemblyNotIncluded"
$runtimeTarget = Join-Path $releaseRoot "DriveBeyondHorizons\Binaries\Win64\ue4ss\Mods\AssemblyNotIncluded"
$distributionRoot = Join-Path $repositoryRoot "Distribution\DriveBeyondHorizons"
$distributionPackageRoot = Join-Path $distributionRoot "Content\Paks\LogicMods\AssemblyNotIncluded"
$distributionRuntimeRoot = Join-Path $distributionRoot "Binaries\Win64\ue4ss\Mods\AssemblyNotIncluded"

foreach ($required in @($projectFile, $runUat, $unrealPak)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required file not found: $required"
    }
}

if (Test-Path -LiteralPath $artifacts) {
    $resolvedArtifacts = (Resolve-Path -LiteralPath $artifacts).Path
    $resolvedRepository = (Resolve-Path -LiteralPath $repositoryRoot).Path
    if (-not $resolvedArtifacts.StartsWith(($resolvedRepository + "\"), [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean an artifacts directory outside the repository."
    }
    Remove-Item -LiteralPath $resolvedArtifacts -Recurse -Force
}

New-Item -ItemType Directory -Path $work, $packageRoot, $runtimeTarget -Force | Out-Null

$uatLogFolder = Join-Path $work "uat-logs"
$buildLocalAppData = Join-Path $work "user-data\Local"
$buildAppData = Join-Path $work "user-data\Roaming"
New-Item -ItemType Directory -Path $uatLogFolder, $buildLocalAppData, $buildAppData -Force | Out-Null
$previousUatLogFolder = $env:uebp_LogFolder
$previousLocalAppData = $env:LOCALAPPDATA
$previousAppData = $env:APPDATA
$env:uebp_LogFolder = $uatLogFolder
$env:LOCALAPPDATA = $buildLocalAppData
$env:APPDATA = $buildAppData
try {
    & $runUat BuildCookRun `
        "-project=$projectFile" `
        -noP4 `
        -platform=Win64 `
        -clientconfig=Shipping `
        -clean `
        -cook `
        -pak `
        -iostore `
        -stage `
        -utf8output
    $uatExitCode = $LASTEXITCODE
}
finally {
    $env:uebp_LogFolder = $previousUatLogFolder
    $env:LOCALAPPDATA = $previousLocalAppData
    $env:APPDATA = $previousAppData
}

if ($uatExitCode -ne 0) {
    throw "Unreal cook failed with exit code $uatExitCode."
}

$cookedPlatformRoot = Join-Path $projectRoot "Saved\Cooked\Windows"
$cookedRoot = Join-Path $cookedPlatformRoot "AssemblyNotIncluded"
$metadata = Join-Path $cookedRoot "Metadata"
$responseFile = Join-Path $work "AssemblyNotIncluded.response.txt"
$commandsFile = Join-Path $work "AssemblyNotIncluded.commands.txt"
$emptyResponse = Join-Path $work "empty.response.txt"
$globalContainer = Join-Path $work "global.utoc"

$assets = @(
    "ModActor.uasset",
    "WBP_AssemblyNotIncluded.uasset",
    "WBP_AssemblyNotIncludedSpeedometer.uasset"
)

$responseLines = foreach ($asset in $assets) {
    $sourceFile = Join-Path $cookedRoot "Content\Mods\AssemblyNotIncluded\$asset"
    if (-not (Test-Path -LiteralPath $sourceFile)) {
        throw "Cooked asset not found: $sourceFile"
    }
    "`"$sourceFile`" `"../../../DriveBeyondHorizons/Content/Mods/AssemblyNotIncluded/$asset`" -compress"
}

Set-Content -LiteralPath $responseFile -Value $responseLines -Encoding ASCII
$containerPath = Join-Path $packageRoot "AssemblyNotIncluded.utoc"
Set-Content -LiteralPath $commandsFile -Value "-Output=`"$containerPath`" -ContainerName=AssemblyNotIncluded -ResponseFile=`"$responseFile`"" -Encoding ASCII
Set-Content -LiteralPath $emptyResponse -Value "" -Encoding ASCII

& $unrealPak `
    "-CreateGlobalContainer=$globalContainer" `
    "-CookedDirectory=$cookedPlatformRoot" `
    "-PackageStoreManifest=$(Join-Path $metadata 'packagestore.manifest')" `
    "-Commands=$commandsFile" `
    "-ScriptObjects=$(Join-Path $metadata 'scriptobjects.bin')" `
    -UTF8Output

if ($LASTEXITCODE -ne 0) {
    throw "IoStore packaging failed with exit code $LASTEXITCODE."
}

& $unrealPak (Join-Path $packageRoot "AssemblyNotIncluded.pak") "-Create=$emptyResponse"
if ($LASTEXITCODE -ne 0) {
    throw "PAK sidecar creation failed with exit code $LASTEXITCODE."
}

@'
Mods["AssemblyNotIncluded"] = {
    AssetName = "ModActor_C",
    AssetPath = "/Game/Mods/AssemblyNotIncluded/ModActor"
}
'@ | Set-Content -LiteralPath (Join-Path $packageRoot "config.lua") -Encoding ASCII

Copy-Item -Path (Join-Path $runtimeSource "*") -Destination $runtimeTarget -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repositoryRoot "docs\INSTALLATION.md") -Destination (Join-Path $releaseRoot "INSTALLATION.md")
foreach ($document in @("README.md", "LICENSE.md", "NOTICE.md")) {
    Copy-Item -LiteralPath (Join-Path $repositoryRoot $document) -Destination $releaseRoot
}

$expected = @(
    "AssemblyNotIncluded.pak",
    "AssemblyNotIncluded.ucas",
    "AssemblyNotIncluded.utoc",
    "config.lua"
)
$actual = Get-ChildItem -LiteralPath $packageRoot -File | Select-Object -ExpandProperty Name
if (Compare-Object -ReferenceObject $expected -DifferenceObject $actual) {
    throw "The generated logic-mod package contains unexpected or missing files."
}

$minimumPackageSizes = @{
    "AssemblyNotIncluded.pak" = 300
    "AssemblyNotIncluded.ucas" = 1024
    "AssemblyNotIncluded.utoc" = 256
}
foreach ($entry in $minimumPackageSizes.GetEnumerator()) {
    $packageFile = Join-Path $packageRoot $entry.Key
    if ((Get-Item -LiteralPath $packageFile).Length -lt $entry.Value) {
        throw "Generated package is unexpectedly empty or truncated: $($entry.Key)"
    }
}

# Keep the tested deployment tree identical to the package being archived.
New-Item -ItemType Directory -Path $distributionPackageRoot, $distributionRuntimeRoot -Force | Out-Null
foreach ($name in $expected) {
    Copy-Item -LiteralPath (Join-Path $packageRoot $name) -Destination (Join-Path $distributionPackageRoot $name) -Force
}
Copy-Item -Path (Join-Path $runtimeSource "*") -Destination $distributionRuntimeRoot -Recurse -Force

$zip = Join-Path $artifacts "AssemblyNotIncluded-v$Version.zip"
Compress-Archive -Path (Join-Path $releaseRoot "*") -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Release created: $zip"
