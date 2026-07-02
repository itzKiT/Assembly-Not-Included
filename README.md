# Assembly Not Included

Assembly Not Included is an all-in-one utility suite for **Drive Beyond Horizons**. It combines vehicle and item spawning, vehicle maintenance tools, player utilities, world controls, a custom paint workflow, and a vehicle-only speedometer in a compact black-and-pink interface.

Press **F7** in game to open or close the Garage Console.

## Highlights

- Searchable eight-column item catalog
- Completed-vehicle spawner covering the current vehicle roster
- Custom spray-can color and finish selection
- Standard and infinite paint-can modes
- Vehicle fluid refill, unlimited fluids, battery recharge, and invulnerability
- Persistent tire-grip adjustment with a stock reset
- Vehicle rust, rust removal, and polishing tools
- Vehicle-only speedometer
- Player health, hunger, thirst, bladder, speed, and jump utilities
- Dawn, noon, dusk, night, clear, storm, rain, and snow controls
- Infinite brush, paint, and ammunition utilities

## Requirements

- Drive Beyond Horizons on Steam
- **Required:** the **zDEV archive** from the [UE4SS experimental-latest release](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest), with `BPModLoaderMod` and `BPML_GenericFunctions` enabled. Stable and non-zDEV UE4SS builds are not supported.
- [Drive Beyond Horizons UTOC Signature Bypass](https://www.nexusmods.com/drivebeyondhorizons/mods/8)

The release does not redistribute UE4SS, the signature bypass, or game files.

## Installation

1. Install and verify the prerequisites above.
2. Download `AssemblyNotIncluded-v0.1.5.zip` from the Releases page.
3. Extract the archive.
4. Copy the included `DriveBeyondHorizons` folder into:

   ```text
   <Steam Library>\steamapps\common\Drive Beyond Horizons\
   ```

5. Merge folders when Windows asks. Do not replace the game's official base package.
6. Start the game and press **F7** after loading a save.

Detailed instructions and prerequisite checks are in [Installation](docs/INSTALLATION.md).

## Repository layout

```text
Distribution/   Tested deployable file tree
Runtime/        UE4SS Lua runtime source
Scripts/        Local install and release-build utilities
Source/Unreal/  Unreal Engine 5.2.1 project and asset-generator source
docs/           Installation, building, and troubleshooting guides
```

## Building

The Unreal assets target **Unreal Engine 5.2.1**. See [Building from source](docs/BUILDING.md) for the clean cook and minimal IoStore packaging process.

## Safety

Back up important saves before installing any gameplay mod. Use this project in single-player environments and keep only one copy of the mod installed.

## Licensing and approval status

Assembly Not Included is currently an independent, unofficial project being prepared for submission to the creators of Drive Beyond Horizons. It must not be represented as officially approved or endorsed unless written approval is received.

Original project material is provided under the [Assembly Not Included Evaluation License](LICENSE.md). This proprietary license permits creator review and limited personal, non-commercial use where separately authorized by the applicable game and platform terms. It does not license or claim ownership of third-party intellectual property.

See [Notices](NOTICE.md) for ownership, dependency, and trademark information.

## Version

Current release: **v0.1.5**
