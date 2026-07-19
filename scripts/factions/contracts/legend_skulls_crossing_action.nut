// =============================================================================
// SKULL'S CROSSING - ACTION (offer gate)
// Economy mechanism-gamble. Appears at a town in real draught with shallow water
// somewhere in a wide ring (the remote Thassilonian dam spawns there).
// =============================================================================

this.legend_skulls_crossing_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "legend_skulls_crossing_action";
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

		// Once per campaign (specific site). Gate via ::Skv.Once (skv_engine): one live
		// offer at a time, only a passive expiry re-offers. Comment out to re-test.
		if (::Skv.Once.isLocked("SkullsCrossing"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.legend_skulls_crossing_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		// --- WORLD-REACTIVE GATE: only a town in real draught. This IS the rarity limiter
		//     (rare + ~7-day window), so there is NO random roll. Checked at OFFER only.
		if (!v.hasSituation("situation.draught"))
		{
			return;
		}

		// --- PLACEMENT GATE: shallow (inland) water somewhere in a WIDE ring; the dam spawns there.
		if (v.getSurroundingTilesOfType([this.Const.World.TerrainType.Shore], 12).len() == 0)
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.legend_skulls_crossing"))
		{
			return;
		}

		// NO random roll — the draught situation is the rarity gate (when enabled).
		// Weight from the shared MSU dial (::Skv.Cfg).
		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("SkullsCrossing");
		local contract = this.new("scripts/contracts/contracts/legend_skulls_crossing_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
