# Changelog

All notable changes to **Golarion Localization** are recorded here. The format loosely follows
[Keep a Changelog](https://keepachangelog.com). The mod's own version is set in
`scripts/!mods_preload/mod_golarion.nut` and carried by each GitHub Release.

## [Unreleased]

- _Work in progress goes here; move it into a dated version block on release._

## [0.90] — playtest

First tracked release. The mod is playable and stable; ongoing work is tuning, not structure.

### World overlay
- Reflavors Legends' world generation into Golarion: settlement names, city-states (as fiend-ruled
  southern powers) with titles, noble houses (as legacy claims on the Runelords of Thassilon), and
  the pantheon (Golarion's gods expressed as the faction archetypes the houses serve). Naming-and-
  story layer only — no mechanical changes to Legends.

### Contracts (six, each once-per-campaign)
- **The Madwoman of Metringer** — investigation → night ambush → assault → descent → moral fork.
- **The Fires at Black Forks** — wait-for-dark approach on a cult-held monastery, then a fight.
- **The Choking Tower** — room-by-room descent with skill checks, traps, and a technomancer's tower.
- **The Wolves of the Green** — a noble bounty on great wolves that is not the hunt it looks like.
- **Skull's Crossing** — a world-reactive job that appears only when a town is in real drought.
- **Shadows on the Frontier** — a highland watchtower defense.

### Shared engine (`::Skv`)
- `::Skv.Once` — once-per-campaign offer gate (one live offer at a time; retires on accept-and-conclude).
- `::Skv.Loot` — iconed loot rendered as Legends' own reward rows (item icons, quality frames, "+N" stacks).
- `::Skv.Check` — roster skill-checks by background ladder.
- `::Skv.Cfg` — MSU settings integration.
- `::Skv.Debug` — dev-console helper (`::skvc()` lists where the mod's contracts have posted).

### Settings
- One shared **Contract frequency (weight)** dial in MSU (`m.Score`, 0 = off, default 2), applied to
  every Golarion contract; each contract keeps its own rarity/eligibility gates.

[Unreleased]: ../../compare/v0.90...HEAD
[0.90]: ../../releases/tag/v0.90
