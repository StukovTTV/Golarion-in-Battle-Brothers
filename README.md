# Golarion Localization

*A Pathfinder / Golarion reflavor and contract pack for **Battle Brothers: Legends**.*

Golarion Localization turns each generated Battle Brothers world into a shard of the **Inner Sea** after a cataclysm — its towns, city-states, noble houses and gods renamed and re-storied into Paizo's **Golarion** setting — and adds a set of hand-authored contracts written to match. The geography is *evocative, not accurate*: every campaign is its own post-cataclysm Inner Sea, not a map of the canon one.

> Status: **in development / playtest (v0.90).** Playable and stable, still being tuned.

---

## What it does

**A world overlay.** The mod reflavors Legends' world generation into Golarion — settlement names, city-states (as fiend-ruled southern powers) and their titles, noble houses (as legacy claims on the Runelords of Thassilon), and the pantheon (Golarion's gods, expressed as the faction archetypes the houses serve). Nothing about the underlying mechanics changes; it is a naming-and-story layer on top of Legends.

**Six hand-authored contracts.** Original, multi-stage jobs themed to Golarion, each with its own art, branching screens, skill checks and consequences. The horror in them is human and institutional, never monstrous — every enemy is a person who made a choice.

**A small shared framework (`::Skv`).** The contracts are built on a reusable engine so future ones are quick to add: once-per-campaign offer gating, iconed loot rendered as Legends' own reward rows, roster skill-checks by background, MSU settings, and dev-console helpers.

---

## The contracts

Each is **once per campaign** — a genuine one-and-done per playthrough — and slightly favored to appear when eligible. Light teasers below; no endings spoiled.

- **The Madwoman of Metringer** — An escaped patient swears the sanitarium takes the sick "past helping" down below, and they never come up. The guards searched and found nothing; everyone calls her mad. She hires the company to find the truth. *(Investigation → a night ambush → an assault → a descent → a moral choice.)*
- **The Fires at Black Forks** — A forest village watches fires burn at the old monastery of Black Forks, where a cult has taken the ruin and driven off the druids who once kept it. *(A wait-for-dark approach, then a fight — go in wrong and it costs you.)*
- **The Choking Tower** — A frontier settlement lives under a column of smoke rising from a tower deep in the wood that no living person has entered. Someone finally pays to find out what is still burning up there. *(A room-by-room descent with skill checks, traps, and a technomancer's secrets.)*
- **The Wolves of the Green** — A noble posts a bounty on the great wolves that took a village whole. What sits in front of the granary is not the beast the bounty describes. *(A hunt that asks a question you did not expect.)*
- **Skull's Crossing** — A town gripped by drought blames the ancient Thassilonian dam upriver and will pay whoever sets it right. *(A world-reactive job that only appears when a settlement is genuinely in drought.)*
- **Shadows on the Frontier** — A highland village beneath a ruined watchtower, raiders coming down out of the peaks. *(The frontier defense beat, Golarion-flavored.)*

---

## Requirements

- **Battle Brothers** with all DLCs (required by Legends).
- **Battle Brothers: Legends** — this is a *submod*; Legends must be installed and working first.
- **Modding Standards & Utilities (MSU)** and **modern_hooks** — normally installed alongside Legends.

The **Dev Console** mod is optional but handy (see [Dev tools](#dev-tools)).

## Installation

1. Get Battle Brothers + Legends running first, following Legends' own setup (which pulls in MSU and modern_hooks).
2. Download the latest `mod_golarion_v*.zip` from Releases.
3. Drop the `.zip` into your `Battle Brothers/data/` folder — do not unzip it.
4. Launch. The mod declares Legends and MSU as dependencies, so it loads after them automatically.

Removing it is just deleting the `.zip`. The overlay and contracts are additive; no vanilla or Legends files are overwritten.

---

## Settings

Configured through **MSU → Mod Settings → Golarion Localization → Contracts**:

- **Contract frequency (weight)** — a single dial (0–10, default 2) shared by every Golarion contract. It sets the selection weight (`m.Score`) they carry when competing for a settlement's contract slot. **0 turns all of the mod's contracts off**; higher makes them appear more readily. Each contract keeps its own rarity and eligibility gates underneath — this only changes how heavily they weigh once eligible.

Takes effect live; no new campaign required.

## Dev tools

With the Dev Console mod installed, the mod adds a read-only console command (Squirrel):

- `::skvc()` — lists every settlement's offered contracts across the whole map, the mod's own marked with `*` and the accepted one flagged. `::skvc(true)` shows only this mod's contracts.

Useful for confirming where and whether the (once-per-campaign) contracts have posted, since you'd otherwise have to wander the map to find them.

---

## Design notes

- **Evocative, not accurate.** The overlay honors Golarion's flavor — its gods, its Runelords, its fiend-cities — without pretending the generated map is the canon Inner Sea. Absalom, Thassilon and the rest live in the text, not the coordinates.
- **The horror is human.** No monsters carry the moral weight of these contracts. Every blade you cross belongs to someone keeping a secret, and the hardest moments are choices, not fights.
- **Once and done.** Each contract appears at most once per campaign, and taking it retires it for good; declining or ignoring an offer lets it come back later.

## Credits & legal

An unofficial, **non-commercial fan project**. Not affiliated with, endorsed, or sponsored by Paizo Inc.

- **Pathfinder**, **Golarion**, the **Inner Sea**, and related names, places and deities are the intellectual property of **Paizo Inc.** Setting lore is drawn from published Pathfinder material and PathfinderWiki, used here in the spirit of fan work — please review Paizo's community-use / fan-content policy before redistributing.
- **Battle Brothers** © **Overhype Studios**.
- Built on **Battle Brothers: Legends** by the Legends team, and **Modding Standards & Utilities (MSU)** by the MSU team. Thanks to the Legends modding community.

License for the mod's own code: MIT (the setting content above remains Paizo's).
