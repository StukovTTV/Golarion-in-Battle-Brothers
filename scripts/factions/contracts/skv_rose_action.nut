this.skv_rose_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_rose_action";

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

		local C = ::Const.Skv.Rose;

		if (::Skv.Once.isLocked(C.OnceKey))
		{
			return;
		}

		if (::World.Assets.getBusinessReputation() < C.RenownGate)
		{
			return;
		}

		local moral = 100;
		try { moral = ::World.Assets.getMoralReputation(); }
		catch (e)
		{
			::logError("Skv.Rose: getMoralReputation threw in the offer gate; not offered this tick - " + e);
			return;
		}
		if (moral >= C.MoralMax)
		{
			return;
		}

		if (!_faction.isReadyForContract())
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_rose"))
		{
			return;
		}

		if (!this.canHost(_faction.getSettlements()[0]))
		{
			return;
		}

		if (::Math.rand(1, 100) > C.Rarity)
		{
			return;
		}

		this.m.Score = sc;
	}

	function canHost( _s )
	{
		return ::Skv.Rose.hostWhy(_s) == null;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim(::Const.Skv.Rose.OnceKey);
		local contract = this.new("scripts/contracts/contracts/skv_rose_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
