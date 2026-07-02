# Troubleshooting

## The game reports a missing project descriptor

Verify the game through Steam. Do not delete the descriptor supplied by the game installation.

## F7 does nothing

Confirm:

- UE4SS loaded.
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
3. Reinstall the prerequisites.
4. Reinstall the current release.

Never overwrite the game's official package files with mod packages.

## Reporting a problem

Include:

- Game build number
- Exact action performed
- Whether the issue occurs on a new save
- The relevant end of `UE4SS.log`

Do not upload save files or full game packages.

