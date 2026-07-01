# Assembly Not Included
All-in-one UE4SS mod suite for **Drive Beyond Horizons**.

**Version:** 0.1.0-Alpha  
**Status:** Active alpha build (feature-complete core toolkit, still evolving)

## What this mod includes
Assembly Not Included ships as a single drop-in package with:

- A custom **Garage Console** UI
- Native UI integrations (item catalog + paint studio)
- Vehicle spawning and tuning tools
- Player and world utility controls
- Weather/time controls
- Vehicle telemetry overlay (speedometer)

## In-game controls
| Control | Action |
| --- | --- |
| `F7` | Toggle the Assembly Not Included Garage Console |
| `assemblynotincluded` (console command) | Open the Garage Console |
| `F6` | Capture/compare polish probe snapshot (advanced diagnostic tool) |

## Feature overview
### Paint & inventory tools
- Open the native item catalog directly from the Garage Console.
- Open the native paint studio from the Garage Console.
- Choose **Standard** or **Infinite** behavior for the next custom paint can.
- Apply unlimited counts to loaded brushes, paint cans, or ammo.

### Vehicles
- Spawn complete vehicles from the built-in vehicle list.
- Live tire-grip tuning with a reset-to-stock action.
- Tire-grip tuning persistence saved per vehicle identity.
- Fill vehicle tanks or set them to unlimited.
- Recharge detected vehicle batteries.
- Toggle vehicle invulnerability.
- Vehicle surface actions: **polish**, **remove rust**, or **apply rust**.
- Vehicle inspection summary (parts/tanks/batteries/surface actors).
- "Super Subwoofer" range extension for supported car radios.
- Automatic on-vehicle speedometer overlay (KM/H).

### Player
- Toggle **Roadrunner speed**.
- Toggle **Moon jump**.
- Refill core player stats (health, hunger, thirst).
- Set bladder stat full or empty.
- Adjust money (`+5000` / `-5000`).

### World
- Spawn a zombie.
- Time presets: dawn, noon, dusk, night.
- Weather presets: clear, storm, rain, and blizzard-style snow mode.
- Destroy the currently looked-at target actor (when valid and unprotected).

## Installation
1. Install the latest experimental UE4SS dev build for Windows.
2. Place this mod package in your game folder at:
   - `...\common\Drive Beyond Horizons\`
3. Do not manually rearrange files; the included preset folder structure places content in the correct locations.
4. Launch the game and press `F7` to open the Garage Console.

## UE4SS requirement
Use a recent **UE4SS zDev** build (development branch). Older stable builds may not expose the hooks this mod uses.

Recommended source:
- https://github.com/UE4SS-RE/RE-UE4SS/releases (latest `zDev` build)

## Package note
This repository package already contains the required folder structure for direct copy/deploy into `Drive Beyond Horizons`.
