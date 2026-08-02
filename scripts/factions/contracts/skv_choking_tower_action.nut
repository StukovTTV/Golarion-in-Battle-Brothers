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

	function isArctic( _v )
	{
		return ::MSU.isKindOf(_v, "legends_snow_village")   || ::MSU.isKindOf(_v, "small_snow_village")   || ::MSU.isKindOf(_v, "medium_snow_village")   || ::MSU.isKindOf(_v, "large_snow_village")
			|| ::MSU.isKindOf(_v, "legends_tundra_village") || ::MSU.isKindOf(_v, "small_tundra_village") || ::MSU.isKindOf(_v, "medium_tundra_village") || ::MSU.isKindOf(_v, "large_tundra_village");
	}

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

		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

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

		if (v.isMilitary())
		{
			return;
		}

		if (this.isArctic(v))
		{
			return;
		}

		if (!this.hasDeepWood(v))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_choking_tower"))
		{
			return;
		}

		if (::Math.rand(1, 100) > ::Skv.Cfg.rarity(_faction))
		{
			return;
		}

		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{

		::Skv.Once.claim("ChokingTower");

		local contract = this.new("scripts/contracts/contracts/skv_choking_tower_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
