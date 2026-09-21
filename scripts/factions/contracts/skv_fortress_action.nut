this.skv_fortress_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_fortress_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	function heldBack()
	{
		return 0;
	}

	function onUpdate( _faction )
	{

		local sc = ::Skv.Cfg.score() - this.heldBack();
		if (sc <= 0)
		{
			return;
		}

		if (::Skv.Once.isLocked("Fortress"))
		{
			return;
		}

		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_fortress_contract))
			{
				return;
			}
		}
		else if (!_faction.isReadyForContract())
		{
			return;
		}

		local s = _faction.getSettlements()[0];

		if (!this.canHost(s))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_fortress"))
		{
			return;
		}

		if (::Math.rand(1, 100) > ::Skv.Cfg.rarity(_faction))
		{
			return;
		}

		this.m.Score = sc;
	}

	function canHostFaction( _faction )
	{
		if (_faction == null)
		{
			return false;
		}

		local t = _faction.getType();
		return t == this.Const.FactionType.Settlement
			|| t == this.Const.FactionType.OrientalCityState;
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

		if (_s.getSize() < 2)
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
		::Skv.Once.claim("Fortress");
		local contract = this.new("scripts/contracts/contracts/skv_fortress_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
