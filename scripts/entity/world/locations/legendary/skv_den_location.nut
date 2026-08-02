this.skv_den_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	function getDescription()
	{
		return "A dozen houses standing open in the trees, and a stone granary at the end of the green. The people who lived here walked north and did not come back for their things.";
	}

	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_den";
		this.m.LocationType = this.Const.World.LocationType.Unique;

		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;

		this.m.IsAttackable = true;
		this.m.VisibilityMult = 0.9;

		this.m.Resources = 350;

		this.m.OnEnter = "event.location.skv_den_enter";
	}

	function onSpawned()
	{
		this.m.Name = "The Den";
		this.location.onSpawned();

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

		body.setBrush("world_abandoned_village");
	}

	function onDropLootForPlayer( _lootTable )
	{
		this.location.onDropLootForPlayer(_lootTable);

		this.dropTreasure(this.Math.rand(1, 2), [], _lootTable);
	}
});
