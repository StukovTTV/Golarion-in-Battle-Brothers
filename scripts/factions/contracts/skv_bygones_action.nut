this.skv_bygones_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_bygones_action";
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

		if (::Skv.Once.isLocked(::Const.Skv.Bygones.OnceKey))
		{
			return;
		}

		if (::World.Assets.getBusinessReputation() < ::Const.Skv.Bygones.RenownGate)
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_bygones_contract))
		{
			return;
		}

		if (!this.canHost(_faction.getSettlements()[0]))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_bygones"))
		{
			return;
		}

		if (::Math.rand(1, 100) > ::Const.Skv.Bygones.Rarity)
		{
			return;
		}

		this.m.Score = sc;
	}

	function canHost( _s )
	{
		return ::Skv.Bygones.hostWhy(_s) == null;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim(::Const.Skv.Bygones.OnceKey);
		local contract = this.new("scripts/contracts/contracts/skv_bygones_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
