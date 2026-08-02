::Legends.Map.SkvDen <- ::Legends.Maps.add("location.skv_den", "The Den");

::mods_hookExactClass("factions/actions/build_unique_locations_action", function(o)
{
	o.m.SkvBuildDenSite <- true;

	local updateBuildings = o.updateBuildings;
	o.updateBuildings = function()
	{
		updateBuildings();

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
