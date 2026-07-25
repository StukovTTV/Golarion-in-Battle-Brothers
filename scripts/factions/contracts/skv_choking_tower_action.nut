// ============================================================================
//  THE CHOKING TOWER -- ACTION (offer gate)
//  Posts from a non-military frontier settlement in temperate, wooded country with
//  deep wood 6-12 tiles out. Registered on Settlement only (northern pool); the
//  south draws from OrientalCityState, so it never sees this contract.
//  Nothing here may throw -- a throw kills the whole faction-action loop.
// ============================================================================
this.skv_choking_tower_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_choking_tower_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	// Arctic exclusion: full snow/tundra class set (base + size variants).
	function isArctic( _v )
	{
		return ::MSU.isKindOf(_v, "legends_snow_village")   || ::MSU.isKindOf(_v, "small_snow_village")   || ::MSU.isKindOf(_v, "medium_snow_village")   || ::MSU.isKindOf(_v, "large_snow_village")
			|| ::MSU.isKindOf(_v, "legends_tundra_village") || ::MSU.isKindOf(_v, "small_tundra_village") || ::MSU.isKindOf(_v, "medium_tundra_village") || ::MSU.isKindOf(_v, "large_tundra_village");
	}

	// At least one free temperate-forest tile in the 6-12 ring (the tower's spawn
	// band). Gate ring == spawn ring, so passing guarantees pickSiteTile a home.
	function hasDeepWood( _v )
	{
		local ring = _v.getSurroundingTilesOfType([
			this.Const.World.TerrainType.Forest,
			this.Const.World.TerrainType.LeaveForest,
			this.Const.World.TerrainType.AutumnForest
		], 12);
		foreach( t in ring )
		{
			if (!t.IsOccupied && _v.getTile().getDistanceTo(t) >= 6)
			{
				return true;
			}
		}
		return false;
	}

	function onUpdate( _faction )
	{
		// Shared frequency dial (::Skv.Cfg): 0 = all Golarion contracts off.
		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		// Once per campaign (::Skv.Once).
		if (::Skv.Once.isLocked("ChokingTower"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_choking_tower_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		// Any NON-MILITARY settlement. Forts drop out here.
		if (v.isMilitary())
		{
			return;
		}

		// Temperate, not arctic (belt-and-suspenders on the forest gate below).
		if (this.isArctic(v))
		{
			return;
		}

		// Deep temperate wood 6-12 tiles out -- also guarantees a spawnable tile.
		if (!this.hasDeepWood(v))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_choking_tower"))
		{
			return;
		}

		// Rarity dial (~15% of eligible ticks).
		if (::Math.rand(1, 100) > 15)
		{
			return;
		}

		// Selection weight (shared ::Skv.Cfg dial).
		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		// Claim the one live-offer slot as this town posts it.
		::Skv.Once.claim("ChokingTower");

		local contract = this.new("scripts/contracts/contracts/skv_choking_tower_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
