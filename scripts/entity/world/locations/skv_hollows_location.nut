// ============================================================================
//  skv_hollows_location -- the Consortium Lumber Camp (Darkmoon Vale hub).
//
//  Pure decoration: the contract spawns it, sets it non-attackable, and runs its
//  own screens off it. Passive|Lair so it never joins a faction's settlement
//  bookkeeping. Same shape as skv_azari_location / skv_den_location, both of
//  which deserialize cleanly in this mod.
//
//  Brush: world_homestead_01 -- a working steading. (The lumber-camp art,
//  world_forest_needle_02, is NOT in the world_entity_0 atlas, so it is not
//  confirmed referenceable; homestead is, and reads correctly at map scale.)
// ============================================================================
this.skv_hollows_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_hollows";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "Consortium Lumber Camp";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("world_homestead_01");
	}

});
