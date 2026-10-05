this.skv_rose_quarter_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_rose_quarter";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "The Drowned Quarter";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		local body = this.addSprite("body");
		body.setBrush("world_houses_03_01_ruins");

		body.Scale = ::Const.Skv.Rose.QuarterSpriteScale;
	}

	function onAfterInit()
	{
		this.location.onAfterInit();
		this.getSprite("selection").setBrush(::Const.Skv.Rose.LeadCoinBrush);
	}

});
