this.skv_trail_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_trail_action";
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

		if (::Skv.Once.isLocked(::Const.Skv.Trail.OnceKey))
		{
			return;
		}

		local awareAmb = ::World.Ambitions.getAmbition("ambition.make_nobles_aware");
		if (awareAmb == null || !awareAmb.isDone())
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_trail_contract))
		{
			return;
		}

		if (!this.canHost(_faction.getSettlements()[0]))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_trail"))
		{
			return;
		}

		this.m.Score = sc;
	}

	function canHost( _s )
	{
		return ::Skv.Trail.hostWhy(_s) == null;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim(::Const.Skv.Trail.OnceKey);
		local contract = this.new("scripts/contracts/contracts/skv_trail_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
