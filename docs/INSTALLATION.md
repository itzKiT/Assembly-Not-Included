# Installation

## 1. Prepare the game

Install Drive Beyond Horizons through Steam and launch it once without mods.

The game folder normally ends with:

```text
steamapps\common\Drive Beyond Horizons\
```

## 2. Install prerequisites

Install:

1. [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases)
2. UE4SS `BPModLoaderMod`
3. UE4SS `BPML_GenericFunctions`
4. [Drive Beyond Horizons UTOC Signature Bypass](https://www.nexusmods.com/drivebeyondhorizons/mods/8)

Confirm the UE4SS proxy DLL is beside the game executable and that both required UE4SS mods are enabled.

## 3. Install Assembly Not Included

Extract the release ZIP. Copy its `DriveBeyondHorizons` folder into:

```text
<Steam Library>\steamapps\common\Drive Beyond Horizons\
```

The final files should include:

```text
DriveBeyondHorizons\Binaries\Win64\ue4ss\Mods\AssemblyNotIncluded\enabled.txt
DriveBeyondHorizons\Binaries\Win64\ue4ss\Mods\AssemblyNotIncluded\Scripts\main.lua
DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded\AssemblyNotIncluded.pak
DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded\AssemblyNotIncluded.ucas
DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded\AssemblyNotIncluded.utoc
DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded\config.lua
```

Do not place the mod package beside or over the official base package.

## 4. Start the mod

Load a save and press **F7**. Press F7 again or use Close to return control to the game.

## Updating

Close the game, then copy the newer release over the existing `AssemblyNotIncluded` folders.

## Uninstalling

Close the game and remove only these two folders:

```text
DriveBeyondHorizons\Binaries\Win64\ue4ss\Mods\AssemblyNotIncluded
DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded
```

Leave UE4SS and the signature bypass installed if other mods require them.

