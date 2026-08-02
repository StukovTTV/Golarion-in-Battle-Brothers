# Changelog

All notable changes to **Golarion Localization** are recorded here. The format loosely follows
[Keep a Changelog](https://keepachangelog.com). The mod's own version is set in
`scripts/!mods_preload/mod_golarion.nut` and carried by each GitHub Release.

## [Unreleased]

- Org-flavored contract categories (Pathfinder, Sczarni, Church, Druid, …): the settlement-board icons
  are in place, but the categories themselves, and the contract-display cap that keeps the noticeboard
  within its slot limit, are not yet wired up.

## [0.96] - playtest

Adds the twelfth contract, a three-act job in the southern city-states that changes what it is about
halfway through, and rebuilds how every contract in the mod hands out experience.

### Contracts
- **Threshold of Knowledge** (contract #12, once-per-campaign, Hunt) adapted from Paizo's *Threshold of
  Knowledge*. A magic school's outpost has lost an instructor to the canals under the city, and the woman
  who runs it will pay quietly to have him found. Offered **only by southern city-states**, and only once
  in a campaign.

  **There is no marker on the map and nowhere to travel to.** The whole thing happens inside the city: go
  in, come back out, and the next scene is waiting for you.

  **The first act is a building and a chase.** A ransacked office with beetles in the spilled ichor, two
  different searches that answer two different questions, and a sixteen-year-old going out over the
  rooftops with five streets to run her down in. Behind a reshelving door that asks you to tell the time
  on a mirrored clock (a puzzle *you* solve, not one your roster rolls for) is a practice rune, and
  knowing how one comes apart is worth more later than anything else in the act.

  **The second act is the canal.** Something made of bark standing in the doorway that can simply be
  talked round, a collapsed vault with half a kobold warren behind it, forty feet of black water, a very
  large thing asleep on a beach, and a sea hag in a grotto with three prisoners. Every obstacle can be
  gone around rather than through. Two of your brothers argue about whether to take her at all, and the
  case for walking away is assembled line by line out of the advantages you actually earned on the way
  down, the only moment in the contract where that ledger is read out loud.

  **And then the job changes.** The man you came for tells you he was never the point. The last act is a
  race back to the archive against a rising canal: four rune rooms, a clock, and a company that paid
  attention in the first act working at twice the speed of one that did not. Whatever you left alive in
  the grotto comes up the stairs after you.

  **No renown, win or lose.** A house that cannot be seen hiring armed men cannot advertise a success,
  and cannot complain about a failure either. **300 crowns, all of it on completion and nothing up
  front**; miss the clock and you have done the whole job for nothing.

### Changed
- **Skill checks pay much less experience, and they pay it by a rule instead of a number somebody typed.**
  Every check in every contract now derives its award from what the check actually was: a scout check
  (one brother reading a ring, spotting a snare, creeping ahead to look) is worth **75** to the company,
  with about a third to the man who did it and the rest shared. A check every brother has to make for
  himself is worth **50 to each of them**, so it no longer gets thinner as your company grows. Nobody
  present ever earns less than 5.

  In practice a six-man company that finishes a long contract now comes out around **level 2 with part of
  level 3 banked**, where the old numbers took the same six to level 3 outright.
- **Two new settings** under Contracts in the MSU menu let you set both awards yourself, alongside the
  existing share-to-the-doer dial. Set them to 0 if you want no experience from skill checks at all.
- **Golarion's contracts appear far less often.** The chance of one turning up was between 12 and 17 %
  per opportunity depending on the contract; it is now **3 % at a northern settlement, 7 % at a noble
  house and 9 % at a southern city-state.** The south keeps the highest rate and will still be the rarest
  place to see one: there are only three city-states in a world and the game caps them at three
  contracts apiece.
- **The Choking Tower pays for the climb.** Eleven floors of smoke, traps and a thing on the stairs, and
  no fight at the end of it to earn anything from, so finishing it now grants **100 experience to every
  brother, or 200 if you shut the machine down by reading it rather than smashing the panel.** The panel
  always works; the careful route is now worth taking.
- Its ending also **shows the crowns it pays you**, which it never did.

### Fixed
- A stack of medical supplies found in a contract could **add twice what the screen said it did**, if two
  stacks of the same thing turned up together. The stash was right and the screen was wrong.
- **Paragraph breaks were printing as raw text** through the whole final act of Threshold of Knowledge,
  turning several screens into one unbroken wall with `\n` in the middle of it.
- The end of a contract could **hand you your pay without ever showing it as a reward**, because the
  figure was written as part of the prose instead of as a proper crowns line.
- Experience is no longer awarded for a **failed** skill check. This was fixed once before and came back
  in a second form; it is now structurally impossible rather than fixed case by case.

## [0.95] - playtest

Adds the mod's first repeatable contract, and with it the only answer in the world to a broken magic weapon.

### Contracts
- **Master of the Anvil** (contract #11, repeatable, Economy). An enhanced weapon cannot be taken to an
  ordinary armourer, so a masterwork blade that has been fought with is a blade on its way to being scrap.
  One smith is willing to try, and men have come to burn his forge down over it.

  The job only exists **while something of yours is actually damaged**, and only in a settlement that has a
  **weaponsmith or an armoursmith** (the southern forges count). Nothing on the board means nothing in your
  stash needs mending.

  A **one-skull fight** on the smith's doorstep, small enough to take with a young company and paid for up
  front: the town hands you **100 crowns** to help the man defend himself. Who turns up is rolled fresh each
  time, so the same contract is not the same fight twice, and the smith himself is only ever spoken of, never
  a body on the field for you to lose.

  Win, and you pay him **half the worth of the item** and he brings the worst-damaged enhanced piece in your
  company back to full, whether it was on a brother's belt or buried in the stash. Lose, and the contract is
  gone with no repair, and you have paid nothing but the butcher's bill.

  Repeatable, but not a living: **one item per contract**, a fee that scales with what you are asking him to
  save, and a **cooldown of thirty to forty-five days** before anyone will post it again. Only ever one copy
  on offer in the world at a time.

### Fixed
- Carrying an enhanced weapon no longer breaks the **camp repair list**. The hook that hides unrepairable
  magic from the repair building read the list in one shape and Legends hands it back in another.
- Master of the Anvil no longer throws an error in the **southern city-states**. The job is posted there as
  well as in the north, and the offer check was written for northern towns only, so any passing hour (camping
  most visibly) tripped over it.

## [0.94] - playtest

Adds the tenth contract: a plague village, a forest vale with three places to search, and an abandoned
dwarven monastery to work through room by room. Brings kobolds into the mod as a full family of enemies,
and adds masterwork and magical weapon enhancement that any contract can hand out.

### Contracts
- **Hollow's Last Hope** (contract #10, once-per-campaign, Hunt) adapted from Paizo's *GameMastery Module
  D0*. A village at the edge of the forest is dying of blackscour taint in its water. The herbalist has a
  cure written in a hand that is not her grandmother's and none of the three things it calls for, and she
  cannot pay you until the pot is standing. Offered only by small forest villages that are actually
  suffering sickness.

  Beyond the lumber camp that serves as your base lie three destinations: the oldest tree in the vale, the
  hollow of a witch everyone has a story about, and a dwarven monastery under the Crags. **The monastery is
  fifteen rooms across two wings**, explored one room at a time in whatever order you like, with a
  watchtower, a hidden prison behind a secret door, a desecrated shrine and a far chamber at the end of it.

  **Seven fights, and most can be declined.** Shut the tower door on the spider, walk past the wolf den,
  back out of the boss's chamber. Every refusal costs something: the pack you did not kill is standing
  beside their master when you meet him, and a floor crossed badly wakes the whole building.

  **Ten road encounters** shuffle into the journey and most are not fights. A rabbit dead in a snare that
  is no accident, a moorsnake that only matters after dark, drunk woodsmen who save you two hours, glowing
  mould worth carrying as a light, three hunters caught forty feet up a tree by something that hunts from
  above.

  **A worg the size of a pony who talks.** He offers a bargain, names errands he wants run, and is counting
  on you being tired when the talking stops. Take the deal, or watch his feet and work out that he is lying.

  **And a clock over all of it.** Searching and travelling cost hours, villagers are buried on a curve while
  you are away, and both the fee and your standing depend on how fast you come home. Return on the sixth day
  and it does not matter what you carried back.

### Enemies
- **Kobolds**, as a full family: fighters, trappers, warriors, a chief, a shaman and a dragon priest.
  Red-scaled and smaller than goblins, weaker one against one, and they come in numbers. They also replace
  the goblins in the **Ambush** contract, so the whole mod gets them.
- The vale itself holds a **nest of tatzlwyrms**, a spider nest thirty years undisturbed, **wolf packs**,
  dire wolves and the worg.
- Fights inside a building are now fought on a **stone floor** rather than on grass.

### Equipment
- **Weapon and ammunition enhancement.** Weapons and quivers can be **masterwork** or **enhanced from +1 to
  +5**. An enhancement adds damage and accuracy and raises the item's worth steeply, but an enhanced weapon
  **cannot be repaired** and wears out for good, and **enhanced ammunition never restocks** from your
  supplies. Masterwork stays repairable. Nothing rolls these at random: every enhanced item in the world is
  one somebody placed.
- The vale holds a masterwork shortsword, a masterwork light crossbow, masterwork tools, **+1
  armour-piercing bolts** and a **+1 hand axe** in a false-backed drawer.
- **Ring of Torag**, off the hand of a dwarf dead four hundred years, which turns aside fire.
- **A cut ruby**, worth a good deal of money or worth setting into an anvil, and you cannot do both.
- **Potion of Cure Light Wounds**, which can be drunk in the middle of a fight or poured into the man
  standing beside you.
- A shrine in the monastery that will heal the whole company, once, if you find both halves of what wakes it.

## [0.93] - playtest

Adds the ninth contract, a whole city-intrigue adventure that plays out in town, with no dungeon and one
fight, and rounds the shared skill-check engine out across all six character attributes plus a social axis.

### Contracts
- **Carthica's Pride** (contract #9, once-per-campaign, noble-house Hunt). Adapted from BlackStar Studios'
  *Carthica's Pride*. A spoiled young noble hires the company through his fixer **Natasha Corvina** to run
  down two **Sczarni** cutpurses, **Atharius & Jhaari**, who lifted his family signet, recover the ring,
  humiliate the pair in public, and keep his name out of it. An entirely **in-town** job that begins the
  moment you accept: barter with the information-broker **Lady Lilianna** (pay a fee, or give up a *true*
  secret; her charm reddens at a lie), catch the **Sczarni tail** shadowing you, wade a filthy back-alley
  (a sickness that follows you into the fight), the one scripted **ambush** by the retained executioner
  **Urie** (with the option to **betray the noble** for a ransom), then find the hidden thieves'-tavern
  door and a **five-contest tavern showdown**: arm-wrestle, rail-walk, dagger-toss, courage-hang, and
  cards, each with a crowd-working flourish, on a popularity meter. Win three games for the ring, win the
  room (7 points) to leave in triumph; lose the games or sell the man out and the job fails. Reports back
  to the noble for goal-scaled experience and a bonus for warning him of the Sczarni plot.

### Shared engine (`::Skv`)
- `::Skv.Check` gains four more **composition flavors**: **`brawn`** (raw strength), **`handEye`** (a
  steady hand and true eye), **`nerve`** (courage / Will), and **`guile`** vs **`charm`** (cold cunning at
  cards vs. warm social showmanship), so a check now exists for every character axis. The **gambler's
  gamble** turns the Gambler background into a wildcard: a random ±5 swing on the roll instead of a flat
  bonus, while the Lucky trait stays a dependable +5.
- New **in-town / no-travel crawl** pattern (a contract that plays as a chain of screens where you stand,
  with no world marker to walk to), and a **per-brother hazard** beat that applies a real injury which
  carries into the following battle.
- **Debug logging** is now gated behind an in-game setting (off by default). Turn on *Debug logging
  (log.html)* in the mod's MSU settings to capture diagnostics for a bug report.

## [0.92] - playtest

Adds the eighth contract, brings Golarion's organizations into the world by name, and grows the shared
engine with character-composition skill checks, experience for passing them, and a mid-contract loadout
screen.

### Contracts
- **Ambush in _<City>_** (contract #8, once-per-campaign). A courier-rescue-and-delivery job adapted
  from the Pathfinder Society Quest *Ambush in Absalom*. **Venture-Captain Ambrus Valsin** hires the
  company to find an agent lost in a city's undercity drains: follow the trail through a goblin warren
  (a covered pit-trap, a picket, and the chief's escort led by a champion boss), recover the sealed
  parcel, and carry it to the Sczarni fence **Guaril Karela** in a neighbouring city, where the
  temptation to break the seal decides the ending (deliver it sealed and be paid, or pry it open, find a
  cookery book the man already owns with a coded line hidden in one recipe, and be refused). A one-skull
  starter; hosted only at towns and cities; both fights mandatory. Offered north and south.

### Golarion organizations
- Reversed the earlier "generic hire" framing: **Golarion's organizations now appear by name.** The
  Ambush is a **Pathfinder Society** job with a **Sczarni** recipient, both written as recurring figures.
- New settlement-board **contract-type icons**: a redesigned Legendary plus **Pathfinder, Church,
  Druid, and Sczarni** (each with a greyscale variant), groundwork for org-flavored contract categories.

### Shared engine (`::Skv`)
- `::Skv.Check` gains **stat-free composition checks**: `agility` and `perception` pick the
  best-suited *active* brother by his traits, background, and perks (no combat stats), and `scaledBase`
  makes a check's difficulty track the contract's skull rating (with an in-game toggle). First use: the
  ambush's two-stage spot-then-cross pit-trap, which can split its reward between two brothers.
- **`::Skv.XP`**: a brother now earns **experience for passing a skill check**: a base award split
  between the one who did it and the watching company, difficulty-scaled, wired across every checking
  contract.
- **Reusable goblin rosters** (`GolarionKobolds` / `GolarionKoboldsCasters`) so small scripted-fight
  budgets buy an appropriately sized warband instead of being floored up to a crowd.
- **Loadout from a contract**: open your company's inventory and gear screen from inside a contract
  (a breather between fights, say) and return to the job afterwards, rather than being dropped back to
  the world map.

### Tuning & fixes
- Check-XP defaults retuned to a leaner spread (a smaller total, ~a third to the doer).
- A contract's on-screen objective now updates reliably through a proper state transition (matching the
  base game's return-item pattern), fixing an objective that could stick and a related crash.
- Packaging guardrails: every build ships its artwork and is archived for one-click rollback.

### Settings
- Two new dials on the Contracts page: **Check XP - actor share (%)** and **Scale skill checks with
  difficulty**.

## [0.91] - playtest

Adds the seventh contract and the scripted-combat tech behind it.

### Contracts
- **The Azari Palace** (contract #7, once-per-campaign). A retrieval-heist under cover of an honest
  admission fee. Pay the steward to walk a dead god's relic-halls; work a shuffled crawl of two-page
  **lore rooms** (a reading moves a brother's mood; the devout and brave shrug off the grim ones) and
  **moral-cost loot rooms** (rob a shrine for an iconed haul at a hit to your standing); breach an
  optional **Ancient Dead crypt**: pick the lock (a background-ladder check) or force it (louder, a
  bigger fight) → a **budget-scaled skeleton fight** with a ~15% chance of a **named champion** that
  drops a named weapon → a random honour-guard **trophy** (a bardiche or a plate cuirass), an optional
  blessed-water rite, and the steward's **2500 buy-back** of its counterpart on the way out. Learn at
  the door that your employer is the buyer the house already refused, then choose the Tome's fate at
  home (give it to the agent, donate it to a temple, fence it, or courier it back), each with iconed
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
  moral cost **1-6**, crypt fight budget **117 × company scaling** (force **×1.3**, champion **15%**).

## [0.90] - playtest

First tracked release. The mod is playable and stable; ongoing work is tuning, not structure.

### World overlay
- Reflavors Legends' world generation into Golarion: settlement names, city-states (as fiend-ruled
  southern powers) with titles, noble houses (as legacy claims on the Runelords of Thassilon), and
  the pantheon (Golarion's gods expressed as the faction archetypes the houses serve). Naming-and-
  story layer only; no mechanical changes to Legends.

### Contracts (six, each once-per-campaign)
- **The Madwoman of Metringer**: investigation → night ambush → assault → descent → moral fork.
- **The Fires at Black Forks**: wait-for-dark approach on a cult-held monastery, then a fight.
- **The Choking Tower**: room-by-room descent with skill checks, traps, and a technomancer's tower.
- **The Wolves of the Green**: a noble bounty on great wolves that is not the hunt it looks like.
- **Skull's Crossing**: a world-reactive job that appears only when a town is in real drought.
- **Shadows on the Frontier**: a highland watchtower defense.

### Shared engine (`::Skv`)
- `::Skv.Once`: once-per-campaign offer gate (one live offer at a time; retires on accept-and-conclude).
- `::Skv.Loot`: iconed loot rendered as Legends' own reward rows (item icons, quality frames, "+N" stacks).
- `::Skv.Check`: roster skill-checks by background ladder.
- `::Skv.Cfg`: MSU settings integration.
- `::Skv.Debug`: dev-console helper (`::skvc()` lists where the mod's contracts have posted).

### Settings
- One shared **Contract frequency (weight)** dial in MSU (`m.Score`, 0 = off, default 2), applied to
  every Golarion contract; each contract keeps its own rarity/eligibility gates.

[Unreleased]: ../../compare/v0.92...HEAD
[0.92]: ../../releases/tag/v0.92
[0.91]: ../../releases/tag/v0.91
[0.90]: ../../releases/tag/v0.90
