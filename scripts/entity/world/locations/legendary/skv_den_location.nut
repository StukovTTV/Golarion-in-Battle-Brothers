// ============================================================================
//  skv_den_location  --  The Den (Golarion Localization).
//
//  Sevenarches, River Kingdoms. A pack of awakened dire wolves out of the
//  Wilewood took an abandoned village and the ground around it. They speak Fey
//  and attack anyone in their territory, even the Oakstewards. The humans left
//  and went north.  (Guide to the River Kingdoms, pg. 48)
//
//  MODEL: witch_hut_location, not abandoned_village_location. The two vanilla
//  legendary locations sit at opposite poles and the difference matters:
//    - witch_hut:         DefenderSpawnList = null, roster hardcoded in
//                         onSpawned via addTroop, IsAttackable = true. The enter
//                         event triggers the NORMAL location attack against that
//                         garrison via World.Events.showCombatDialog.
//    - abandoned_village: no garrison at all; its enter event builds its own
//                         combat properties in a local helper and calls
//                         startScriptedCombat, and every combat option first
//                         calls setVisited(false) so it never falls through to
//                         the normal attack path.
//  We are the first. Roster lives here; the event only decides whether it fires.
//
//  NO DefenderSpawnList ON PURPOSE. location.nut:250 gates the whole respawn
//  path on (IsSpawningDefenders && DefenderSpawnList != null && Resources != 0).
//  With the list null, createDefenders() NEVER runs: no budget, no day-scaling,
//  no 10-day regrowth. That is the point. The pack is twenty specific animals,
//  not a spawner -- a bandit camp is a supply, this is a cast. Kill them and
//  they are gone.
//
//  CONSEQUENCE, KNOWN AND ACCEPTED: a hardcoded roster does NOT get multiplied
//  by Const.Difficulty.EnemyMult[getCombatDifficulty()] the way createDefenders
//  would. It DOES still pick up Legends' per-difficulty perk grants (see below).
//  Tune on Legendary; it is a wall you come back to when strong enough, which is
//  what the mummy site and the witch hut already are.
// ============================================================================
this.skv_den_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	// The hover text. This is the ONLY warning before the warning -- the sole
	// thing standing between a curious player and a renown loss they did not see
	// coming. Deliberately vague: it does not name wolves and does not give the
	// count. The count is the brothers' to give, on the Lore screen, because a
	// number needs a mouth (canon says "about 20" -- that is a refugee's number,
	// and only a man can say "about").
	function getDescription()
	{
		return "A dozen houses standing open in the trees, and a stone granary at the end of the green. The people who lived here walked north and did not come back for their things.";
	}

	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_den";
		this.m.LocationType = this.Const.World.LocationType.Unique;

		// IsShowingDefenders = false is not imitation of the witch hut -- it is
		// load-bearing. The defender panel would report "13 Direwolf, 7 Frenzied
		// Direwolf", exact, mechanical, sourced from nowhere. The lore screen
		// reports "a score of them, near enough", sourced from a man who ran.
		// The engine's disclosure is WORSE than the fiction's, so switch it off.
		// Net effect: count disclosed (if you ask), composition hidden. You can
		// price the decision; you cannot solve it.
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;

		this.m.IsAttackable = true;
		this.m.VisibilityMult = 0.9;

		// Resources on a location with NO DefenderSpawnList is NOT a garrison
		// budget -- createDefenders never runs. It survives only as a loot scale
		// (setLootScaleBasedOnResources, location.nut:313) and a named-item
		// chance roll (location.nut:463). Set for loot, not out of habit.
		this.m.Resources = 350;

		this.m.OnEnter = "event.location.skv_den_enter";
	}

	function onSpawned()
	{
		this.m.Name = "The Den";
		this.location.onSpawned();

		// Canon: "About 20 dire wolves live in an empty stone granary in the Den."
		// 13 + 7 = 20. Cost 20/25 -> 435, against the Direwolves list's own
		// MaxR of 535: this is ~81% of the largest direwolf party the engine will
		// ever assemble, standing still. A roaming pack (send_beast_roamers_action)
		// is rand(80,120) -- four to six animals. This is four of those at once.
		//
		// The danger is not the stat block, it is tempo and snowball:
		//   Direwolf      -- Legends: AP 10, Initiative 135, MeleeDefense 5.
		//                    werewolf_bite, coup_de_grace, berserk, pathfinder.
		//                    IsAffectedByNight = false, IsImmuneToDisarm = true.
		//   DirewolfHIGH  -- the Frenzied Direwolf. DamageTotalMult 1.25,
		//                    + overwhelm, + relentless.
		// pathfinder means the forest taxes your line and not theirs.
		// Legends' coup_de_grace is effect-driven: +0.2 per high-tier effect
		// (Debilitated, LegendTackled), +0.1 per low-tier from a THIRTEEN-entry
		// list (Staggered, Stunned, Rooted, Dazed, Net, Web, Sleeping, ...).
		// Twenty bodies generate those states constantly and every wolf on the
		// field cashes in on them.
		//
		// The counterweight is MeleeDefense 5 -- they are trivially easy to hit.
		// So this is a FORMATION test, not a stat check: spearwall and polearms
		// behind a held line shred them; a broken line gets eaten. That is why 20
		// is survivable at all, and it is the fight worth having.
		//
		// TUNE ON LEGENDARY. That is where hooks/entity/tactical/enemies/direwolf
		// grants the 13 LegendStrengthInNumbers + Fearless (they NEVER rout -- no
		// morale-break escape hatch) + RacialLegendWerewolf, and direwolf_high
		// grants the 7 KillingFrenzy + Nimble. Nimble on a 5-defense wolf is a
		// real effective-HP jump on the thing you were counting on killing fast.
		// The difficulty gap is wider for this enemy than for most.
		//
		// NO ALPHA. Nothing in the source speaks of a leader, named or otherwise.
		// Every lair in this game has a thing at the top; a pack of twenty peers
		// that talks and has no leader is a fact about what awakening did to them.
		// Do not add one to fill the boss-shaped hole -- and note the engine agrees:
		// every direwolf Troops def is Variant = 0, so addTroop's miniboss block
		// (world_entity_common.nut:668, `if (troop.Variant > 0)`) never enters and
		// no direwolf can be championed as shipped. The championable set is
		// humanoids and named tiers without exception -- LegendGoblinDirewolfRider
		// is Variant 1, the wolf under him never is.
		for( local i = 0; i < 13; i = ++i )
		{
			this.Const.World.Common.addTroop(this, {
				Type = this.Const.World.Spawn.Troops.Direwolf
			}, false);
		}

		for( local i = 0; i < 7; i = ++i )
		{
			this.Const.World.Common.addTroop(this, {
				Type = this.Const.World.Spawn.Troops.DirewolfHIGH
			}, false);
		}

		this.updateStrength();
	}

	function onInit()
	{
		this.location.onInit();
		local body = this.addSprite("body");
		// Reuses the vanilla abandoned village brush (abandoned_village_location
		// uses the same one). It IS an abandoned village -- that is the whole
		// point of the site -- and no new art is needed to say so.
		body.setBrush("world_abandoned_village");
	}

	function onDropLootForPlayer( _lootTable )
	{
		this.location.onDropLootForPlayer(_lootTable);
		// Whatever the villagers left when they walked north, minus a few years
		// of weather and wolves. dropTreasure(count, extraList, _lootTable) --
		// the witch hut passes named upgrade materials here; we pass nothing
		// extra and let the generic treasure roll carry it. This is a granary,
		// not a hoard.
		this.dropTreasure(this.Math.rand(1, 2), [], _lootTable);
	}
});
