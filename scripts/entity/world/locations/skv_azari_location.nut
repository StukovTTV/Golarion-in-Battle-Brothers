// ============================================================================
//  THE AZARI PALACE -- map marker (location entity)
//
//  A plain, non-attackable location that reuses the ancient-temple map sprite
//  (world_ancient_temple), so a dead god's temple reads as a grand old building on
//  the world map -- not the undead bone-pile the contract borrowed at first. The
//  CONTRACT owns it: it setAttackable(false)s the marker and runs its own screen
//  chain, so this location never actually fights (no defender list, no banner).
//  A custom class (rather than reusing the legendary ancient_temple_location) so we
//  cannot collide with that world-unique singleton.
// ============================================================================
this.skv_azari_location <- this.inherit("scripts/entity/world/location", {
	m = {},
	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_azari_palace";
		this.m.LocationType = this.Const.World.LocationType.Lair | this.Const.World.LocationType.Passive;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.Resources = 0;
	}

	function onSpawned()
	{
		this.m.Name = "Azari Palace";
		this.location.onSpawned();
	}

	function onInit()
	{
		this.location.onInit();
		this.addSprite("body").setBrush("world_ancient_temple");
	}

});
