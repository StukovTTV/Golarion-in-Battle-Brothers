// ============================================================================
//  Carthica's Pride -- map marker (location entity)
//
//  A plain, non-attackable marker for the rundown quarter you go into to hunt the
//  two thieves: the info-broker's villa, the garbage alley, the sooty courtyard,
//  and the hidden tavern (The Urgent Messenger) all play out here as screens. The
//  CONTRACT owns it (setAttackable via Passive; every fight is a scripted combat
//  from the screen chain), so this marker never fights -- no defenders, no banner.
//  ⚠ BRUSH: world_cave_01 is a placeholder so it LOADS -- swap for an urban/ruin
//  brush from world_location_sprites.md (this is a city back-quarter, not a cave).
// ============================================================================
this.skv_carthica_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_carthica_quarter";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "The Backstreets";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("world_cave_01");
	}

});
