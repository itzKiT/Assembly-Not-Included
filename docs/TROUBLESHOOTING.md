# Troubleshooting

## The game reports a missing project descriptor

Verify the game through Steam. Do not delete the descriptor supplied by the game installation.

## F7 does nothing

Confirm:

- The **zDEV archive** from the [UE4SS experimental-latest release](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) loaded. Release v0.6.7 was tested with Git SHA `c2ac2464`; stable, non-zDEV, and other experimental commits are not verified.
- `AssemblyNotIncluded\enabled.txt` exists.
- `AssemblyNotIncluded\Scripts\main.lua` exists.
- `BPModLoaderMod` and `BPML_GenericFunctions` are enabled.

Review `DriveBeyondHorizons\Binaries\Win64\ue4ss\UE4SS.log` for the `Assembly Not Included` load message.

## The menu loads but asset-backed controls do not

Confirm the `.pak`, `.ucas`, `.utoc`, and `config.lua` files are together under:

```text
DriveBeyondHorizons\Content\Paks\LogicMods\AssemblyNotIncluded
```

Also confirm that the UTOC signature bypass is installed.

## The game fails before reaching the menu

1. Remove the two Assembly Not Included folders listed in the uninstall instructions.
2. Verify the game through Steam.
3. Reinstall the prerequisites, including the zDEV archive from the UE4SS experimental-latest release.
4. Reinstall the current release.

Never overwrite the game's official package files with mod packages.

## Supplemental vehicle parts have no image

Enter at least three search characters to show supplemental vehicle parts. They are intentionally search-only to prevent repeated-open and multiplayer-host object pressure.

Broad vehicle-part searches are completed from indexed vehicle asset names. For example, searching a vehicle name should reveal matching parts that the native catalog may not show in its shorter result list.

Some vehicle parts omitted by the game's native catalog do not expose a usable native thumbnail mapping. Assembly Not Included still makes those parts searchable and spawnable, but their tile may use the game's missing-image presentation. Expanded thumbnail support remains under development.

This does not indicate a missing item class or failed spawn.

## Rust removal or polishing stalls or crashes

These actions inspect and update many attached vehicle components. On lower-performance systems, allow the current action to finish and do not click the button repeatedly.

If a crash occurs:

1. Do not restart the game before copying `UE4SS.log`.
2. Record the exact UE4SS Git SHA from the second log line.
3. Include the newest `Saved\Crashes` folder and current `DriveBeyondHorizons.log`.
4. Confirm the game build and whether the vehicle was freshly spawned.

## Reporting a problem

Include:

- Game build number
- Exact action performed
- Whether the issue occurs on a new save
- The relevant end of `UE4SS.log`

Do not upload save files or full game packages.
