// ============================================================================
//  THE AZARI PALACE -- ACTION (offer gate)
//  Smuggler hires the company to lift a relic from the Azari Palace. Hosts NORTH
//  *and* SOUTH (registered on both Settlement and OrientalCityState). The "has a
//  temple" gate qualifies the host AND guarantees the "donate to a temple" ending.
//
//  ⚠ Readiness split per faction type: settlements take isReadyForContract(CATEGORY);
//  city-states take the no-arg form. Wrong one throws "wrong number of parameters"
//  and silently kills the whole faction-action loop.
// ============================================================================
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
		// Shared frequency dial (::Skv.Cfg): 0 = all Golarion contracts off.
		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		// Once per campaign (::Skv.Once).
		if (::Skv.Once.isLocked("Azari"))
		{
			return;
		}

		// Readiness split -- settlement takes the category arg; city-state the no-arg form.
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

		// Any NON-MILITARY settlement (!isMilitary, not isKindOf, so registered
		// city-states qualify). Forts drop out.
		if (v.isMilitary())
		{
			return;
		}

		// Must have a temple -- excludes temple-less hamlets AND guarantees the
		// "donate to a temple" ending a temple at home.
		if (!v.hasBuilding("building.temple"))
		{
			return;
		}

		// Not offered to a saintly company (>=80 moral = Chivalrous/Saintly).
		if (::World.Assets.getMoralReputation() >= 80)
		{
			return;
		}

		// Rarity dial (~13%); also once-per-campaign + 14d cooldown + temple + moral<80.
		if (::Math.rand(1, 100) > 13)
		{
			return;
		}

		// Selection weight (shared ::Skv.Cfg dial).
		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		// Claim the one live-offer slot as this town posts it.
		::Skv.Once.claim("Azari");

		local contract = this.new("scripts/contracts/contracts/skv_azari_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
