// ============================================================================
//  BLACK FORKS -- ACTION (offer gate)
//  An "investigate the fires" job posted by a forest village near the old
//  monastery of Black Forks. Cultists (the Tenders) have taken the ruin and
//  driven off the druids who once haunted its roof.
// ============================================================================
this.skv_black_forks_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_black_forks_action";
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
		if (::Skv.Once.isLocked("BlackForks"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_black_forks_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		// Any village (lumber villages inherit legends_village). Forts excluded.
		if (!this.isKindOf(v, "legends_village"))
		{
			return;
		}

		// Green forest within 3 tiles -- guarantees a spawnable tile for the monastery.
		// SnowyForest excluded on purpose (Black Forks is a temperate wood).
		if (v.getSurroundingTilesOfType([
				this.Const.World.TerrainType.Forest,
				this.Const.World.TerrainType.LeaveForest,
				this.Const.World.TerrainType.AutumnForest
			], 3).len() == 0)
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_black_forks"))
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
		::Skv.Once.claim("BlackForks");
		local contract = this.new("scripts/contracts/contracts/skv_black_forks_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
