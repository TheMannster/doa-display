# tm-streetside

A modular FiveM resource for everything that lives parked at the curb — both the legit and the not-so-legit.

- **Display vehicles** — static showroom cars parked around your shop / dealership, only spawned when a player is nearby. Locked, frozen, indestructible, can't be entered.
- **City cars** — ambient stealable cars rotated around random parking spots across the map. Lockpick / hotwire them like any other AI car. The slot refills next rotation.

> Made by **the mannster** 🛠️

---

## Requirements

- FiveM server with **OneSync** (or OneSync Infinity) enabled — city cars are spawned server-side so everyone sees them in the same spot.

## Install

1. Drop the `tm-streetside` folder into your `resources/` directory.
2. Add `ensure tm-streetside` to your `server.cfg`.
3. Tweak `config.lua` to taste, then restart the resource.

## Config

Everything lives in [`config.lua`](./config.lua). The highlights:

| Section | What it does |
|---|---|
| `Config.Modules` | Toggle `display` / `citycars` on or off independently. |
| `Config.Display` | List of showroom vehicles + spawn radius. |
| `Config.CityCars` | Models, per-model active counts, rotation interval, and parking locations. |

The server console prints a banner on boot showing which modules are active and a short summary of each.

## How stealing works

City cars are spawned with no special lock/key handling — your server's existing lockpick / hotwire / no-keys flow applies just like it does to any random parked AI car. Once a player sits in one (or drives it past `StolenDistance`), `tm-streetside` releases the vehicle and stops tracking it, so it won't get yanked out from under the player on the next rotation.

## Plays nice with (optional)

- **kiminaze AdvancedParking** — *not required.* If you have it installed, set `Config.CityCars.PersistReleasedCars = true` and AdvancedParking will own released cars (survive restarts, stay parked where they were left).

  If you DON'T have it (or any similar persistence resource), leave `PersistReleasedCars = false`. The script will watch released cars itself and clean them up after `AbandonedCleanupMinutes` of nobody being nearby, so orphan vehicles don't pile up over long server uptimes.

---

Made with care by **the mannster**.
