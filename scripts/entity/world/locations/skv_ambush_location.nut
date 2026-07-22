// ============================================================================
//  AMBUSH IN <CITY> -- map marker (location entity)
//
//  A plain, non-attackable marker for the mouth of the undercity drains where a
//  goblin warren has nested. Reuses the vanilla cave brush (world_cave_01) so the
//  world map reads "a way down into the tunnels" -- not a garrisoned lair. The
//  CONTRACT owns it: setAttackable(false), and every fight is a scripted combat run
//  from the screen chain, so this location never fights (no defenders, no banner).
//  A custom class so we can never collide with a world-unique singleton.
//  (Brush catalog: world_location_sprites.md -- swap world_cave_01 in one line.)
// ============================================================================
this.skv_ambush_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_ambush_drains";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "The Undercity Drains";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("world_cave_01");
	}

});
