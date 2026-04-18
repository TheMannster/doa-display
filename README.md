# tm-streetside

Modular FiveM resource for parked cars - both the legit kind and the kind people steal.

- **Display vehicles** - locked, frozen showroom cars that spawn when a player gets close.
- **City cars** - ambient stealable cars rotated around random parking spots across the map.

> Made by **themannster**

## Requirements

- **OneSync** (or OneSync Infinity) - city cars are spawned server-side.

## Install

1. Drop `tm-streetside` into your `resources/` folder.
2. Add `ensure tm-streetside` to your `server.cfg`.
3. Edit `config.lua` and restart.

## Config

Everything is in [`config.lua`](./config.lua) - toggle modules, set vehicle lists, rotation timing, and parking spots.

## Stealing

City cars use no special lock handling - your existing lockpick / hotwire flow applies. Once a player sits in one (or drives it past `StolenDistance`), the car is released and left alone.

If you run a persistence resource like **kiminaze AdvancedParking**, set `Config.CityCars.PersistReleasedCars = true` and it'll take ownership of released cars. Otherwise leave it `false` and the script will clean up abandoned cars itself after `AbandonedCleanupMinutes`.
