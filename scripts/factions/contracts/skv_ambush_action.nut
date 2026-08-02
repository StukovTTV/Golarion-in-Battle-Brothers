this.skv_ambush_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_ambush_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	function isDeliveryTarget( _s, _home )
	{

		if (_s == null) return false;
		if (_s.getID() == _home.getID()) return false;
		if (!_s.isDiscovered()) return false;
		if (_s.isMilitary()) return false;
		if (_s.isIsolated()) return false;
		return true;
	}

	function onUpdate( _faction )
	{

		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		if (::Skv.Once.isLocked("Ambush"))
		{
			return;
		}

		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_ambush_contract))
			{
				return;
			}
			if (_faction.hasContractExclusion("contract.skv_ambush"))
			{
				return;
			}
		}
		else if (!_faction.isReadyForContract())
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

		if (v.getSize() < 2)
		{
			return;
		}

		local hasTarget = false;
		try
		{
			foreach (s in ::World.EntityManager.getSettlements())
			{
				if (this.isDeliveryTarget(s, v)) { hasTarget = true; break; }
			}
		}
		catch (e)
		{
			return;
		}
		if (!hasTarget)
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

		::Skv.Once.claim("Ambush");

		local contract = this.new("scripts/contracts/contracts/skv_ambush_contract");
		contract.setFaction(_faction.getID());
		local home = _faction.getSettlements()[0];
		contract.setHome(home);
		contract.setEmployerID(_faction.getRandomCharacter().getID());

		contract.m.Name = "Ambush in " + home.getName();
		this.World.Contracts.addContract(contract);
	}

});
