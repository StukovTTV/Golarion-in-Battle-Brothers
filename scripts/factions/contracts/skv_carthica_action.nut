// ============================================================================
//  Carthica's Pride in <City> -- ACTION (offer gate)
//  NOBLE-HOUSE contract (registered on Actions[NobleHouse]; also pushed onto
//  Settlement during dev for testing). Gated on the make_nobles_aware ambition --
//  base noble readiness does NOT gate renown, so without this it offered on a fresh start.
// ============================================================================
this.skv_carthica_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_carthica_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	// First holding that can host: a town (size 2+) WITH a tavern. A noble house
	// owns several settlements, so SCAN rather than trust getSettlements()[0].
	// Raw settlements have no isNull() -> guard with == null.
	function findHost( _faction )
	{
		foreach (s in _faction.getSettlements())
		{
			if (s == null) continue;
			if (s.getSize() < 2) continue;
			if (!s.hasBuilding("building.tavern")) continue;
			return s;
		}
		return null;
	}

	function onUpdate( _faction )
	{
		local sc = ::Skv.Cfg.score();
		if (sc <= 0) return;

		if (::Skv.Once.isLocked("Carthica")) return;

		// Readiness split -- settlement takes the category arg (TEST path); a noble
		// house takes the no-arg form (SHIP path). Wrong one throws + silently kills the loop.
		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_carthica_contract)) return;
			if (_faction.hasContractExclusion("contract.skv_carthica")) return;
		}
		else
		{
			if (!_faction.isReadyForContract()) return;

			// Noble offer-gate: don't offer until make_nobles_aware is done. Fail closed if absent.
			local awareAmb = this.World.Ambitions.getAmbition("ambition.make_nobles_aware");
			if (awareAmb == null || !awareAmb.isDone()) return;
		}

		// Just needs a size-2+ town w/ a tavern to host the job.
		if (this.findHost(_faction) == null) return;

		// Rarity dial (~12%); also once-per-campaign + 14d cooldown.
		if (::Math.rand(1, 100) > 12) return;

		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("Carthica");

		local home = this.findHost(_faction);
		if (home == null) home = _faction.getSettlements()[0];   // onUpdate already proved one exists

		local contract = this.new("scripts/contracts/contracts/skv_carthica_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(home);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		contract.m.Name = "Carthica's Pride";   // no town suffix (per playtest feedback)
		this.World.Contracts.addContract(contract);
	}

});
