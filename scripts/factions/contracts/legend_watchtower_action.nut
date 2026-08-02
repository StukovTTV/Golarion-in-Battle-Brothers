this.legend_watchtower_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "legend_watchtower_action";
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

		if (::Skv.Once.isLocked("Watchtower"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.legend_watchtower_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (!this.canHost(v))
		{
			return;
		}

		local canon = null;
		foreach (s in ::World.EntityManager.getSettlements())
		{
			if (s.getName() == "Pezzack")
			{
				canon = s;
				break;
			}
		}

		if (canon != null && this.canHost(canon) && v.getName() != "Pezzack")
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.legend_watchtower"))
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
		if (_s.isIsolated())
		{
			return false;
		}

		if (!this.isKindOf(_s, "legends_village"))
		{
			return false;
		}

		if (_s.getSurroundingTilesOfType([::Const.World.TerrainType.Hills], 3).len() == 0)
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
		::Skv.Once.claim("Watchtower");
		local contract = this.new("scripts/contracts/contracts/legend_watchtower_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
