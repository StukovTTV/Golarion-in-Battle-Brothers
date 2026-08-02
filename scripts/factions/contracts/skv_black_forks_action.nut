this.skv_black_forks_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_black_forks_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	function onUpdate( _faction )
	{

		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		if (::Skv.Once.isLocked("BlackForks"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_black_forks_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		if (!this.isKindOf(v, "legends_village"))
		{
			return;
		}

		if (v.getSurroundingTilesOfType([
				this.Const.World.TerrainType.Forest,
				this.Const.World.TerrainType.LeaveForest,
				this.Const.World.TerrainType.AutumnForest
			], 3).len() == 0)
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_black_forks"))
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
		::Skv.Once.claim("BlackForks");
		local contract = this.new("scripts/contracts/contracts/skv_black_forks_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
