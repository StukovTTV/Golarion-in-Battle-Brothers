this.skv_croak_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_croak_action";
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

		if (::Skv.Once.isLocked("Croak"))
		{
			return;
		}

		if (::World.Assets.getBusinessReputation() < ::Const.Skv.Croak.RenownGate)
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_croak_contract))
		{
			return;
		}

		if (!this.canHost(_faction.getSettlements()[0]))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_croak"))
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

		local has = false;
		try { has = _s.hasSituation(::Const.Skv.Croak.Situation); }
		catch (e)
		{
			::Skv.dbg("Skv.Croak: hasSituation threw on " + _s.getName() + " - " + e);
			return false;
		}
		if (!has)
		{
			return false;
		}

		if (_s.getSurroundingTilesOfType(::Const.Skv.Croak.swampTypes(), ::Const.Skv.Croak.SwampRadius).len() == 0)
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
		::Skv.Once.claim("Croak");
		local contract = this.new("scripts/contracts/contracts/skv_croak_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
