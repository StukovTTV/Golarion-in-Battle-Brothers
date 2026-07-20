# Changelog

All notable changes to **Golarion Localization** are recorded here. The format loosely follows
[Keep a Changelog](https://keepachangelog.com). The mod's own version is set in
`scripts/!mods_preload/mod_golarion.nut` and carried by each GitHub Release.

## [Unreleased]

- _Work in progress goes here; move it into a dated version block on release._

## [0.91] — playtest

Adds the seventh contract and the scripted-combat tech behind it.

### Contracts
- **The Azari Palace** (contract #7, once-per-campaign) — a retrieval-heist under cover of an honest
  admission fee. Pay the steward to walk a dead god's relic-halls; work a shuffled crawl of two-page
  **lore rooms** (a reading moves a brother's mood — the devout and brave shrug off the grim ones) and
  **moral-cost loot rooms** (rob a shrine for an iconed haul at a hit to your standing); breach an
  optional **Ancient Dead crypt** — pick the lock (a background-ladder check) or force it (louder, a
  bigger fight) → a **budget-scaled skeleton fight** with a ~15% chance of a **named champion** that
  drops a named weapon → a random honour-guard **trophy** (a bardiche or a plate cuirass), an optional
  blessed-water rite, and the steward's **2500 buy-back** of its counterpart on the way out. Learn at
  the door that your employer is the buyer the house already refused, then choose the Tome's fate at
  home — give it to the agent, donate it to a temple, fence it, or courier it back — each with iconed
  coin, renown, moral, and mood outcomes, and background-aware reactions (pious vs. criminal brothers).
  Offered in the north and the southern city-states.

### Shared engine (`::Skv`)
- Scripted tactical combat launched straight from a contract screen, spawned from a **contract-owned,
  pure-skeleton budget menu** (no vampire/hound leak from the stock undead list), with difficulty scaled
  to company strength and an optional champion via `makeMiniboss`.
- `::Skv.Loot.haul` now backs crawl loot, the crypt trophy, and the buy-back; `::Skv.Check` drives the
  crypt-door lockpick.

### Tuning
- Azari release values: offer rate **13%**, door fee **620**, base pay pool **1000**, per-room loot
  moral cost **1–6**, crypt fight budget **117 × company scaling** (force **×1.3**, champion **15%**).

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

[Unreleased]: ../../compare/v0.91...HEAD
[0.91]: ../../releases/tag/v0.91
[0.90]: ../../releases/tag/v0.90
