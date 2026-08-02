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

		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_carthica_contract)) return;
			if (_faction.hasContractExclusion("contract.skv_carthica")) return;
		}
		else
		{
			if (!_faction.isReadyForContract()) return;

			local awareAmb = this.World.Ambitions.getAmbition("ambition.make_nobles_aware");
			if (awareAmb == null || !awareAmb.isDone()) return;
		}

		if (this.findHost(_faction) == null) return;

		if (::Math.rand(1, 100) > ::Skv.Cfg.rarity(_faction)) return;

		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("Carthica");

		local home = this.findHost(_faction);
		if (home == null) home = _faction.getSettlements()[0];

		local contract = this.new("scripts/contracts/contracts/skv_carthica_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(home);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		contract.m.Name = "Carthica's Pride";
		this.World.Contracts.addContract(contract);
	}

});
