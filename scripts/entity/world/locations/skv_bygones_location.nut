this.skv_bygones_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_bygones";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "Emberhold";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("skv_world_bygones");
	}

});
