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

		// Once per campaign -- it is THE Black Forks. Gate via ::Skv.Once (skv_engine):
		// one live offer at a time, only a passive expiry re-offers. Comment out to re-test.
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

		// Must have (green) forest within 3 tiles -- marks the woodland setting AND
		// guarantees a spawnable tile for the monastery. SnowyForest excluded on
		// purpose (Black Forks is a temperate southern wood, per the schrats hunt).
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

		// Rarity dial. `rand(1,100) > N` DECLINES above N, so it PASSES ~N% of eligible
		// ticks: 15 => ~15%. (Testing value was 99 = near-guaranteed.)
		if (::Math.rand(1, 100) > 15)
		{
			return;
		}

		// Score is a WEIGHT in the faction action loop's weighted pick, not a boolean --
		// the driver sums the eligible deck's scores and rolls against them. Native
		// contract actions almost all use 1; the shared dial defaults to 2 so a contract
		// already made rare by the roll above doesn't ALSO have to win a coin flip against
		// every build/upgrade action. Stamp the shared MSU weight (::Skv.Cfg).
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
