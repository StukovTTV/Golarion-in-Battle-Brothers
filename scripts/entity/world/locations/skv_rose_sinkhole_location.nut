this.skv_rose_sinkhole_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_rose_sinkhole";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "The Sinkhole";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("world_desert_ruins_01");
	}

});
