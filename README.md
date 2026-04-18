# doa-display

A lightweight FiveM resource for **DOA Performance** that handles two things:

- **Display vehicles** — static showroom cars parked around the dealership, only spawned when a player is nearby.
- **City cars** — ambient "stealable" cars rotated around random parking spots across the map. Sit in one and it's yours; the slot refills next rotation.

> Made by **the mannster** 🛠️

---

## Requirements

- FiveM server with **OneSync** (or OneSync Infinity) enabled — city cars are spawned server-side so everyone sees them in the same spot.

## Install

1. Drop the `doa-display` folder into your `resources/` directory.
2. Add `ensure doa-display` to your `server.cfg`.
3. Tweak `config.lua` to taste, then restart the resource.

## Config

Everything lives in [`config.lua`](./config.lua). The highlights:

| Section | What it does |
|---|---|
| `Config.Modules` | Toggle `display` / `citycars` on or off independently. |
| `Config.Display` | List of showroom vehicles + spawn radius. |
| `Config.CityCars` | Models, per-model active counts, rotation interval, and parking locations. |

The server console prints a banner on boot showing which modules are active and a short summary of each.

## Plays nice with

- **kiminaze AdvancedParking** — once a player touches one of our city cars we release it and never delete it, so AdvancedParking can take ownership cleanly.

---

Made with care by **the mannster** for DOA Performance.
