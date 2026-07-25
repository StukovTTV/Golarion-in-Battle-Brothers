// ============================================================================
//  skv_den_location  --  The Den (Golarion Localization).
//
//  Awakened dire wolves hold an abandoned village. They speak Fey and attack
//  anyone in their territory. (Guide to the River Kingdoms, pg. 48)
//
//  MODEL: witch_hut_location (DefenderSpawnList = null, roster hardcoded in
//  onSpawned via addTroop, enter event fires the NORMAL location attack via
//  showCombatDialog), not abandoned_village_location.
//
//  NO DefenderSpawnList ON PURPOSE. location.nut:250 gates the respawn path on
//  (IsSpawningDefenders && DefenderSpawnList != null && Resources != 0); with the
//  list null, createDefenders() NEVER runs -- no regrowth. Kill them, they're gone.
//  Consequence: a hardcoded roster is NOT multiplied by EnemyMult, but DOES pick
//  up Legends' per-difficulty perk grants. Tune on Legendary.
// ============================================================================
this.skv_den_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	// Hover text: deliberately vague, does not name wolves or give the count.
	function getDescription()
	{
		return "A dozen houses standing open in the trees, and a stone granary at the end of the green. The people who lived here walked north and did not come back for their things.";
	}

	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_den";
		this.m.LocationType = this.Const.World.LocationType.Unique;

		// IsShowingDefenders = false: hide the exact "13 Direwolf, 7 Frenzied"
		// panel so composition stays hidden (the lore screen gives the count only).
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;

		this.m.IsAttackable = true;
		this.m.VisibilityMult = 0.9;

		// With no DefenderSpawnList, Resources is not a garrison budget -- it only
		// scales loot (location.nut:313) and the named-item chance roll (:463).
		this.m.Resources = 350;

		this.m.OnEnter = "event.location.skv_den_enter";
	}

	function onSpawned()
	{
		this.m.Name = "The Den";
		this.location.onSpawned();

		// Canon: about 20 wolves. 13 Direwolf + 7 DirewolfHIGH (Frenzied) = 20.
		// TUNE ON LEGENDARY -- that is where the Legends direwolf hooks grant
		// LegendStrengthInNumbers/Fearless/RacialLegendWerewolf and KillingFrenzy/
		// Nimble; the difficulty gap is wider for this enemy than for most.
		// No alpha: direwolf Troops defs are all Variant = 0, so addTroop's miniboss
		// block never enters and none can be championed as shipped.
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
		// Reuses the vanilla abandoned village brush.
		body.setBrush("world_abandoned_village");
	}

	function onDropLootForPlayer( _lootTable )
	{
		this.location.onDropLootForPlayer(_lootTable);
		// dropTreasure(count, extraList, _lootTable): no extra list, generic roll only.
		this.dropTreasure(this.Math.rand(1, 2), [], _lootTable);
	}
});
