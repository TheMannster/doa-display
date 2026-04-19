# Changelog

## [1.2.1]
- Removed misleading `failed to delete` / `was deleted by something between spawn and state-tag` warnings - they were false positives from `DoesEntityExist` not stabilising in the same tick as `CreateVehicle` / `DeleteEntity`. Spawn and cleanup were already working correctly
- Shutdown log simplified to a single `deleted N` line

## [1.2.0]
- City cars now spawn locked and tagged with a `tm_streetside` state bag
- Added police gate: lockpicking a city car requires `MinPoliceOnline` cops with one of `PoliceJobs` (on-duty when `RequireOnDuty`)
- New ox_inventory exports `tm-streetside.uselockpick` and `tm-streetside.useaccesstool` (the latter wraps `r14-evidence.accesstool`)
- New helper exports `tm-streetside.CanSteal` and `tm-streetside.GetOnlineCops`
- Boot-time orphan sweep: leftover city cars from a crashed / failed shutdown are cleaned up on next start
- Spawn-clearance check: spots with a vehicle within 2.5m are skipped and logged
- More diagnostic rotation log: now reports despawned, released, and already-gone counts
- Added `ox_lib`, `ox_inventory`, `qbx_core` dependencies

## [1.1.0]
- Added `ModelsPerRotation` - random subset of models picked each rotation
- Added fresh-first picker for both models and locations (avoids back-to-back repeats)
- Added break-in detection - logs to console when a player enters a city car
- Added GitHub-based version check on boot
- Cleaned up config and README

## [1.0.0]
- Initial release
- Display module (showroom cars)
- CityCars module (rotating ambient stealable cars)
