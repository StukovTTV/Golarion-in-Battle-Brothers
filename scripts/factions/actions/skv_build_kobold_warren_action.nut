this.skv_build_kobold_warren_action <- this.inherit("scripts/factions/faction_action", {
	m = {},

	function create()
	{
		this.m.ID = "skv_build_kobold_warren_action";

		this.m.IsRunOnNewCampaign = true;
		this.faction_action.create();
	}

	function skvCountWarrens()
	{
		local n = 0;

		foreach( v in this.World.EntityManager.getLocations() )
		{
			if (v != null && v.getTypeID() == "location.skv_kobold_warren")
			{
				n = n + 1;
			}
		}

		return n;
	}

	function onUpdate( _faction )
	{

		if (_faction.getSettlements().len() == 0)
		{
			return;
		}

		if (this.skvCountWarrens() >= 2)
		{
			return;
		}

		this.m.Score = 2;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{

		if (this.skvCountWarrens() >= 2)
		{
			return;
		}

		local disallowedTerrain = [];

		for( local i = 0; i < this.Const.World.TerrainType.COUNT; i = i + 1 )
		{
			if (i == this.Const.World.TerrainType.Forest || i == this.Const.World.TerrainType.AutumnForest)
			{
				continue;
			}

			disallowedTerrain.push(i);
		}

		local tile = this.getTileToSpawnLocation(this.Const.Factions.BuildCampTries, disallowedTerrain, 10, 1000, 20, 7, 7, null, 0.0);

		if (tile == null)
		{
			return;
		}

		local warren = this.World.spawnLocation("scripts/entity/world/locations/skv_kobold_warren_location", tile.Coords);

		if (warren == null)
		{
			return;
		}

		local banner = this.getAppropriateBanner(warren, _faction.getSettlements(), 15, this.Const.GoblinBanners);
		warren.onSpawned();
		warren.setBanner(banner);
		_faction.addSettlement(warren, false);
	}

});
