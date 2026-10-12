this.skv_lore_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_lore_action";
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

		if (::Skv.Once.isLocked(::Const.Skv.Lore.OnceKey))
		{
			return;
		}

		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_lore_contract))
			{
				return;
			}
		}
		else if (!_faction.isReadyForContract())
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_lore"))
		{
			return;
		}

		if (this.findHost(_faction) == null)
		{
			return;
		}

		if (::Math.rand(1, 100) > ::Skv.Lore.rarity(_faction))
		{
			return;
		}

		this.m.Score = sc;
	}

	function canHost( _s )
	{
		return ::Skv.Lore.hostWhy(_s) == null;
	}

	function findHost( _faction )
	{
		if (_faction.getType() != this.Const.FactionType.NobleHouse)
		{
			local s = _faction.getSettlements()[0];
			return this.canHost(s) ? s : null;
		}

		foreach (s in _faction.getSettlements())
		{
			if (s == null) continue;
			if (::Skv.Lore.kindOf(s) != "military") continue;
			if (this.canHost(s)) return s;
		}
		return null;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		local home = this.findHost(_faction);
		if (home == null)
		{

			::logError("Skv.Lore: onExecute found no host for faction " + _faction.getID() + " (it had one at onUpdate); not posting.");
			return;
		}

		::Skv.Once.claim(::Const.Skv.Lore.OnceKey);
		local contract = this.new("scripts/contracts/contracts/skv_lore_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(home);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
