this.skv_fane_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_fane";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "The Fane in the Wood";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("world_ancient_temple");
	}

});
