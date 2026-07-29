this.skv_hollows_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_hollows_action";
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

		if (::Skv.Once.isLocked("HollowsLastHope"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_hollows_contract))
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

		if (v.getSize() > 2)
		{
			return;
		}

		if (!v.hasSituation("situation.sickness"))
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

		if (_faction.hasContractExclusion("contract.skv_hollows"))
		{
			return;
		}

		this.m.Score = v.getName() == "Falcon's Hollow" ? sc * 3 : sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("HollowsLastHope");
		local contract = this.new("scripts/contracts/contracts/skv_hollows_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
