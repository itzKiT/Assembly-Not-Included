# Changelog

## v0.6.6

Complete vehicle-parts catalog and input-stability update.

- Added omitted vehicle and engine parts from the current game build to the item spawner.
- Added coverage for Escada, P-51/French Utility, Loft/German Compact, Kage/Japanese Sporty, Tomahawk/Muscle Car, Peak, Speedle, and isolated missing parts from other vehicle families.
- Preserved the fast native item catalog and indexed only concrete vehicle-item classes that the native catalog omitted.
- Excluded master, template, projectile, debug, and non-item Blueprint classes from supplemental spawning.
- Kept the compact eight-column catalog layout.
- Made supplemental vehicle parts search-only with a three-character minimum and a 64-result safety cap.
- Added zero supplemental widgets during normal catalog opening, preventing repeated-open object accumulation.
- Removed generic `/CarsV2/` path text from supplemental matching so broad terms cannot create hundreds of unrelated tiles.
- Re-resolved item classes for each result instead of retaining stale UE4SS userdata.
- Released supplemental widget references when searches change or the catalog closes.
- Fixed repeated item-spawner crashes, including the higher object pressure observed while hosting multiplayer.
- Strengthened guarded game-input restoration after item spawning so control returns without an extra F7 cycle.
- Removed experimental thumbnail mutation after testing showed it could destabilize catalog rebuilding.
- Known limitation: supplemental vehicle parts may display without an item image when the game does not provide a usable native thumbnail mapping. Thumbnail support remains under development.
- Validated the release against Drive Beyond Horizons Steam build `24071320`.
- Validated the release with UE4SS zDEV Git SHA `c2ac2464`.

## v0.6.5

Compatibility, performance, and spawning update.

- Added a Full Barrels section with directly spawnable full containers:
  - Petrol: 100 L
  - Diesel: 100 L
  - Oil: 20 L
  - Water: 100 L
- Replaced the vehicle `ReceiveTick` and player-controller transition hooks with one throttled speedometer monitor.
- Reduced speedometer work to two updates per second while driving and one lightweight vehicle check every 1.5 seconds while on foot.
- Cached the speedometer value widget and stopped repeated widget ownership, child lookup, and visibility work.
- Preserved tire-grip changes when closing the menu without continuously reapplying them every frame.
- Removed diagnostic barrel probes and temporary vehicle-entry hooks from the production runtime.
- Retained the compact eight-column item catalog and existing paint, vehicle, player, and world tools.
- Validated the release against Drive Beyond Horizons Steam build `24063845`.
- Validated the release with UE4SS zDEV Git SHA `c2ac2464`.
- Added a lower-performance-system warning: object-heavy actions such as rust removal and polishing may stall or crash on some systems. Save first and avoid repeated clicks while an action is running.
- Multiplayer authority support is not included in this release; use the current release in single-player environments.

## v1.6.0

First broadly tested public release and stability overhaul of Assembly Not Included.

- Added the compact black-and-pink Assembly Not Included interface opened with F7.
- Added the searchable eight-column item catalog.
- Added completed spawning for the current vehicle roster.
- Added custom paint color, finish, standard-capacity, and infinite-capacity modes.
- Added eight persistent, automatically saved paint-color slots.
- Changed saved swatches to spawn configured paint cans directly, avoiding unsafe native color-picker mutation.
- Added vehicle speedometer, grip tuning, fluid, battery, and protection controls.
- Added vehicle rust, rust-removal, and polish actions.
- Added player, time-of-day, weather, precipitation, and utility controls.
- Corrected input restoration after menu and item-spawner actions.
- Isolated vehicle surface actions to the occupied vehicle and its attached components.
- Restored normal brush durability when infinite brushes are disabled.
- Added post-load and menu-open brush normalization for saves containing stale unlimited durability.
- Restricted surface updates to deduplicated, explicit per-part material controllers to prevent UE4SS access violations.
- Removed obsolete catalog filtering, reflection probes, and recurring global scans.
- Restored the event-driven vehicle tick hook and removed recurring Lua callback churn.
- Packaged the project under the single `AssemblyNotIncluded` identifier.
- Added the project evaluation license, creator-review grant, and third-party notices.
- Documented the zDEV UE4SS experimental-latest build as the required and supported UE4SS version.

## v0.1.5

Initial supported development release of Assembly Not Included.
