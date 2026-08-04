this.skv_zoldos_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_zoldos_action";
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

		if (::Skv.Once.isLocked("Zoldos"))
		{
			return;
		}

		if (::World.Assets.getBusinessReputation() < 1300)
		{
			return;
		}

		local awareAmb = ::World.Ambitions.getAmbition("ambition.make_nobles_aware");
		if (awareAmb == null || !awareAmb.isDone())
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_zoldos_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (!this.canHost(v))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_zoldos"))
		{
			return;
		}

		if (::Math.rand(1, 100) > ::Skv.Cfg.rarity(_faction))
		{
			return;
		}

		this.m.Score = sc;
	}

	function canHost( _s )
	{
		if (_s == null)
		{
			return false;
		}

		if (_s.isIsolated())
		{
			return false;
		}

		if (!this.isKindOf(_s, "legends_village"))
		{
			return false;
		}

		if (_s.getSize() > 2)
		{
			return false;
		}

		if (_s.getSurroundingTilesOfType([::Const.World.TerrainType.Mountains], 3).len() == 0)
		{
			return false;
		}

		return true;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("Zoldos");
		local contract = this.new("scripts/contracts/contracts/skv_zoldos_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
