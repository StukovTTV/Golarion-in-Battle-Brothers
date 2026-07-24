// ============================================================================
//  Carthica's Pride in <City> -- ACTION (offer gate)
//
//  A spoiled minor noble hires the company (through his fixer) to run down the two
//  thieves who took his family signet, recover it, and humiliate them in public --
//  quietly. NOBLE-HOUSE contract: registered on Actions[NobleHouse] (ships noble-
//  only; also pushed onto Settlement during dev for testing -- see the preload).
//  NO renown gate: the noble lane's ~1050 "Professional" unlock is itself the gate
//  (verified against Legends 19.4.14 + the wiki). Design: carthicas_pride_contract.md.
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

	// First holding that can host the job: a real town (size 2+) WITH a tavern
	// (Act I meets there; the finale IS a tavern). Gate on ONLY those two things
	// (per design). A noble house owns several settlements and getSettlements()[0]
	// is not guaranteed to qualify, so SCAN rather than trust [0]. Raw settlements
	// have no isNull() -> guard with == null.
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
		// house takes the no-arg form (the SHIP path). Wrong one throws + silently
		// kills the faction loop (Azari's gotcha).
		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_carthica_contract)) return;
			if (_faction.hasContractExclusion("contract.skv_carthica")) return;
		}
		else if (!_faction.isReadyForContract())
		{
			return;
		}

		// No renown gate (decision #16). Just needs a size-2+ town w/ a tavern.
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
