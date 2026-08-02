this.skv_azari_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_azari_action";
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

		if (::Skv.Once.isLocked("Azari"))
		{
			return;
		}

		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_azari_contract))
			{
				return;
			}
			if (_faction.hasContractExclusion("contract.skv_azari"))
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

		if (!v.hasBuilding("building.temple"))
		{
			return;
		}

		if (::World.Assets.getMoralReputation() >= 80)
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

		::Skv.Once.claim("Azari");

		local contract = this.new("scripts/contracts/contracts/skv_azari_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
