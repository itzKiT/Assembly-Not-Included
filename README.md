# Assembly Not Included

Assembly Not Included is an all-in-one utility suite for **Drive Beyond Horizons**. It combines vehicle and item spawning, vehicle maintenance tools, player utilities, world controls, a custom paint workflow, and a vehicle-only speedometer in a compact black-and-pink interface.

Press **F7** in game to open or close Assembly Not Included.

## Highlights

- Searchable eight-column item catalog
- Supplemental spawning coverage for vehicle parts omitted by the native catalog
- Full Petrol, Diesel, Oil, and Water barrel spawning
- Completed-vehicle spawner covering the current vehicle roster
- Custom spray-can color and finish selection
- Eight persistent, automatically saved paint-color slots
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
- **Required:** the **zDEV archive** from the [UE4SS experimental-latest release](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest), with `BPModLoaderMod` and `BPML_GenericFunctions` enabled. This release was tested with UE4SS Git SHA `c2ac2464`; verify the SHA on the second line of `UE4SS.log`. Stable, non-zDEV, and other experimental commits are not verified.
- [Drive Beyond Horizons UTOC Signature Bypass](https://www.nexusmods.com/drivebeyondhorizons/mods/8)

The release does not redistribute UE4SS, the signature bypass, or game files.

Tested game version: Drive Beyond Horizons Steam build `24071320`.

## Installation

1. Install and verify the prerequisites above.
2. Download `AssemblyNotIncluded-v0.6.6.zip` from the Releases page.
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

Back up important saves before installing any gameplay mod. Use this release in single-player environments and keep only one copy of the mod installed.

Object-heavy actions, particularly vehicle rust removal and polishing, may temporarily stall or crash on lower-performance systems. Save first, allow each action to finish, and do not click the action repeatedly.

Supplemental vehicle parts may display without an item image when the current game build does not expose a usable native thumbnail mapping. The parts remain searchable and spawnable; expanded thumbnail support is still in development.

## Licensing and approval status

Assembly Not Included is currently an independent, unofficial project being prepared for submission to the creators of Drive Beyond Horizons. It must not be represented as officially approved or endorsed unless written approval is received.

Original project material is provided under the [Assembly Not Included Evaluation License](LICENSE.md). This proprietary license permits creator review and limited personal, non-commercial use where separately authorized by the applicable game and platform terms. It does not license or claim ownership of third-party intellectual property.

See [Notices](NOTICE.md) for ownership, dependency, and trademark information.

## Version

Current release: **v0.6.6**
