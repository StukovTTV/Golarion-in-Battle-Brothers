// ============================================================================
//  METRINGER SANITARIUM -- ACTION (offer gate)
//  Salindra Concilio hires the company to look into Metringer Sanitarium.
//  Once-per-campaign (::Skv.Once); rarity ~15%; gated to a town/city (getSize>=2).
//  The sanitarium spawns on any land tile near home -- no biome lock.
// ============================================================================
this.skv_metringer_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_metringer_action";
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
		if (::Skv.Once.isLocked("Metringer"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_metringer_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		// Any village (towns/cities inherit legends_village; forts do not).
		if (!this.isKindOf(v, "legends_village"))
		{
			return;
		}

		// Town or city (size >= 2), skip tier-1 hamlets. No biome gate.
		if (v.getSize() < 2)
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_metringer"))
		{
			return;
		}

		// Rarity dial (~15% of eligible ticks).
		if (::Math.rand(1, 100) > 15)
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
		::Skv.Once.claim("Metringer");
		local contract = this.new("scripts/contracts/contracts/skv_metringer_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
