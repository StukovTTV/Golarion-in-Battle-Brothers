# Changelog

All notable changes to **Golarion Localization** are recorded here. The format loosely follows
[Keep a Changelog](https://keepachangelog.com). The mod's own version is set in
`scripts/!mods_preload/mod_golarion.nut` and carried by each GitHub Release.

## [Unreleased]

- Org-flavored contract categories (Pathfinder, Sczarni, Church, Druid, …): the settlement-board icons
  are in place, but the categories themselves — and the contract-display cap that keeps the noticeboard
  within its slot limit — are not yet wired up.

## [0.92] — playtest

Adds the eighth contract, brings Golarion's organizations into the world by name, and grows the shared
engine with character-composition skill checks, experience for passing them, and a mid-contract loadout
screen.

### Contracts
- **Ambush in _<City>_** (contract #8, once-per-campaign) — a courier-rescue-and-delivery job adapted
  from the Pathfinder Society Quest *Ambush in Absalom*. **Venture-Captain Ambrus Valsin** hires the
  company to find an agent lost in a city's undercity drains: follow the trail through a goblin warren —
  a covered pit-trap, a picket, and the chief's escort led by a champion boss — recover the sealed
  parcel, and carry it to the Sczarni fence **Guaril Karela** in a neighbouring city, where the
  temptation to break the seal decides the ending (deliver it sealed and be paid, or pry it open, find a
  cookery book the man already owns with a coded line hidden in one recipe, and be refused). A one-skull
  starter; hosted only at towns and cities; both fights mandatory. Offered north and south.

### Golarion organizations
- Reversed the earlier "generic hire" framing — **Golarion's organizations now appear by name.** The
  Ambush is a **Pathfinder Society** job with a **Sczarni** recipient, both written as recurring figures.
- New settlement-board **contract-type icons**: a redesigned Legendary plus **Pathfinder, Church,
  Druid, and Sczarni** (each with a greyscale variant), groundwork for org-flavored contract categories.

### Shared engine (`::Skv`)
- `::Skv.Check` gains **stat-free composition checks** — `agility` and `perception` pick the
  best-suited *active* brother by his traits, background, and perks (no combat stats), and `scaledBase`
  makes a check's difficulty track the contract's skull rating (with an in-game toggle). First use: the
  ambush's two-stage spot-then-cross pit-trap, which can split its reward between two brothers.
- **`::Skv.XP`** — a brother now earns **experience for passing a skill check**: a base award split
  between the one who did it and the watching company, difficulty-scaled, wired across every checking
  contract.
- **Reusable goblin rosters** (`GolarionKobolds` / `GolarionKoboldsCasters`) so small scripted-fight
  budgets buy an appropriately sized warband instead of being floored up to a crowd.
- **Loadout from a contract** — open your company's inventory and gear screen from inside a contract
  (a breather between fights, say) and return to the job afterwards, rather than being dropped back to
  the world map.

### Tuning & fixes
- Check-XP defaults retuned to a leaner spread (a smaller total, ~a third to the doer).
- A contract's on-screen objective now updates reliably through a proper state transition (matching the
  base game's return-item pattern), fixing an objective that could stick and a related crash.
- Packaging guardrails: every build ships its artwork and is archived for one-click rollback.

### Settings
- Two new dials on the Contracts page: **Check XP — actor share (%)** and **Scale skill checks with
  difficulty**.

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

[Unreleased]: ../../compare/v0.92...HEAD
[0.92]: ../../releases/tag/v0.92
[0.91]: ../../releases/tag/v0.91
[0.90]: ../../releases/tag/v0.90
