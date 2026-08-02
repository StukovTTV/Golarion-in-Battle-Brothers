this.skv_threshold_action <- this.inherit("scripts/factions/faction_action", {
	m = {},

	function create()
	{
		this.m.ID = "skv_threshold_action";

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

		if (::Skv.Once.isLocked("Threshold"))
		{
			return;
		}

		if (!_faction.isReadyForContract())
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_threshold"))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		if (v.getSize() < 2)
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

		::Skv.Once.claim("Threshold");

		local contract = this.new("scripts/contracts/contracts/skv_threshold_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());

		this.World.Contracts.addContract(contract);
	}

});
