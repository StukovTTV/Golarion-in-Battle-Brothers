// ============================================================================
//  THE AZARI PALACE -- ACTION (offer gate)
//
//  A Kortos Consortium smuggler hires the company to lift a relic (a Tome of
//  Memory) from the forlorn Azari Palace -- a bankrupt noble house living in a
//  temple to the dead god Aroden. The contract spawns and owns its own site (see
//  the contract's Offer.end); this action only decides WHERE and WHETHER the job
//  appears.
//
//  HOSTS -- NORTH *AND* SOUTH. Registered on BOTH Const.FactionTrait.Actions[
//  Settlement] (northern civilian pool) AND [OrientalCityState] (the southern
//  city-states), because Absalom is the archetypal cosmopolitan city-state and a
//  smuggler works the southern ports too. The "has a temple" gate below decides
//  whether any given host actually qualifies -- and it also guarantees the
//  contract's "donate it to a temple" ending always has a temple to hand it to.
//
//  ⚠ CONTRACT-READINESS IS ASKED DIFFERENTLY PER FACTION TYPE. Settlements use the
//  category-slot system: isReadyForContract(CATEGORY) -- one argument. City-states
//  have their own simple 2-3 contract limit and take isReadyForContract() -- NO
//  argument. Calling the settlement form on a city-state throws "wrong number of
//  parameters", which kills the whole faction-action loop for that faction (the
//  contract then silently never offers). Legends' own dual-registered contracts
//  (deliver_item, escort_caravan) split on getType()==Settlement exactly this way.
//
//  NOTHING HERE MAY THROW. hasBuilding / isMilitary / getSettlements all work on a
//  city-state's settlement entity (hunting_mummies uses them), so only the
//  readiness call needs the split.
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

		// Once per campaign -- it is THE Azari Palace. ::Skv.Once handles the
		// one-live-offer slot and the permanent done-flag. Comment out to re-test.
		if (::Skv.Once.isLocked("Azari"))
		{
			return;
		}

		// Contract-readiness -- settlement (category slot, one arg) vs. city-state
		// (own limit, no arg). See the header. The contract-exclusion check is also
		// a settlement-slot concept, so it lives in the settlement branch.
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

		// Any NON-MILITARY settlement -- village, town, city, or southern
		// city-state. Forts are military and drop out. (Using !isMilitary rather
		// than isKindOf(legends_village) so the city-states we registered for can
		// actually qualify -- villages exclude that class.)
		if (v.isMilitary())
		{
			return;
		}

		// Must have a temple. Does double duty: excludes temple-less hamlets, AND
		// guarantees the "donate to a temple" ending always has a temple at home.
		if (!v.hasBuilding("building.temple"))
		{
			return;
		}

		// Not offered to a SAINTLY company: a smuggler does not bring a relic-theft
		// to the famously honourable. (>=80 on the 0-100 moral scale = the top
		// bands, Chivalrous/Saintly. Confirm the exact boundary in-game.)
		if (::World.Assets.getMoralReputation() >= 80)
		{
			return;
		}

		// Rarity dial. `rand(1,100) > N` DECLINES above N, so it PASSES ~N% of eligible
		// ticks. RELEASE VALUE = 13 (also gated once-per-campaign + 14d cooldown + temple + moral<80).
		if (::Math.rand(1, 100) > 13)
		{
			return;
		}

		// Selection WEIGHT in the faction-action pick (the shared dial's default 2).
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
