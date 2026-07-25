// ---- Legendary locations ----
// Permanent, world-gen placed, discovered by map (not noticeboard).

// Location 1 - The Den (awakened dire wolves in an abandoned village).
// Location + event scripts need no registering (resolved by path / auto-discovered).
// This line is the Legends MAP-system registration -- its ONLY discovery channel
// (black-market map); rumours skip LocationType.Unique and can never name it.
::Legends.Map.SkvDen <- ::Legends.Maps.add("location.skv_den", "The Den");

// Worldgen placement (same shape as Legends' BuildMummySite/BuildTournamentSite).
// The terrain lock IS the frequency dial.
::mods_hookExactClass("factions/actions/build_unique_locations_action", function(o)
{
	o.m.SkvBuildDenSite <- true;

	local updateBuildings = o.updateBuildings;
	o.updateBuildings = function()
	{
		updateBuildings();

		// Idempotent: never build a second one (e.g. after a load).
		foreach( v in this.World.EntityManager.getLocations() )
		{
			if (v.getTypeID() == "location.skv_den")
			{
				this.m.SkvBuildDenSite = false;
			}
		}
	}

	local onExecute = o.onExecute;
	o.onExecute = function( _faction )
	{
		onExecute(_faction);

		if (!this.m.SkvBuildDenSite)
		{
			return;
		}

		// getTileToSpawnLocation takes a DISALLOWED list, so build "everything except forest".
		local disallowedTerrain = [];

		for( local i = 0; i < this.Const.World.TerrainType.COUNT; i = i )
		{
			if (i == this.Const.World.TerrainType.Forest || i == this.Const.World.TerrainType.AutumnForest)
			{
			}
			else
			{
				disallowedTerrain.push(i);
			}

			i = ++i;
		}

		// Verified signature (faction_action.nut:173): getTileToSpawnLocation(_maxTries,
		//   _notOnTerrain, _minDistToSettlements, _maxDistToSettlements, _maxDistanceToAllies,
		//   _minDistToEnemyLocations, _minDistToAlliedLocations, _nearTile, _minY, _maxY).
		// Ours: 6-22 from settlements.
		local tile = this.getTileToSpawnLocation(this.Const.Factions.BuildCampTries * 100, disallowedTerrain, 6, 22, 1001, 8, 8, null, 0.1);

		if (tile != null)
		{
			local camp = this.World.spawnLocation("scripts/entity/world/locations/legendary/skv_den_location", tile.Coords);

			if (camp != null)
			{
				camp.onSpawned();
				this.logInfo("Golarion: built The Den location");
			}
		}
	}
});
