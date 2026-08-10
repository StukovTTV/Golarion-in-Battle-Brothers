this.skv_kobold_warren_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	function getDescription()
	{
		return "A crack in the rock with the spoil heaped outside it, too small for a man to enter upright. Something has been dragging things in.";
	}

	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_kobold_warren";
		this.m.LocationType = this.Const.World.LocationType.Lair;
		this.m.CombatLocation.Template[0] = "tactical.goblin_camp";
		this.m.CombatLocation.Fortification = this.Const.Tactical.FortificationType.None;
		this.m.CombatLocation.CutDownTrees = true;

		this.setDefenderSpawnList(::Const.World.Spawn.GolarionKoboldsCasters);

		this.m.RoamerSpawnList = ::Const.World.Spawn.GolarionKoboldRoamers;

		this.m.Resources = 90;
	}

	function onSpawned()
	{
		this.m.Name = this.World.EntityManager.getUniqueLocationName(::Const.Skv.WarrenNames);
		this.location.onSpawned();
	}

	function onDropLootForPlayer( _lootTable )
	{
		this.location.onDropLootForPlayer(_lootTable);
		this.dropMoney(this.Math.rand(0, 120), _lootTable);
		this.dropArmorParts(this.Math.rand(0, 10), _lootTable);
		this.dropAmmo(this.Math.rand(10, 30), _lootTable);
		this.dropMedicine(this.Math.rand(0, 3), _lootTable);
		this.dropFood(this.Math.rand(1, 2), [
			"strange_meat_item",
			"roots_and_berries_item",
			"pickled_mushrooms_item"
		], _lootTable);

		this.dropTreasure(this.Math.rand(1, 2), [
			"loot/goblin_carved_ivory_iconographs_item",
			"loot/goblin_minted_coins_item",
			"loot/goblin_rank_insignia_item",
			"loot/signet_ring_item",
			"trade/amber_shards_item",
			"trade/salt_item"
		], _lootTable);
	}

	function onInit()
	{
		this.location.onInit();
		local body = this.addSprite("body");
		body.setBrush("world_cave_01");
	}

});
