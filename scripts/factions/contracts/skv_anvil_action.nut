this.skv_anvil_action <- this.inherit("scripts/factions/faction_action", {
	m = {},

	function create()
	{
		this.m.ID = "skv_anvil_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 7;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	function hasDamagedEnchanted()
	{
		if (!("GolarionEnchant" in ::getroottable()))
		{
			return false;
		}

		try
		{
			return ::GolarionEnchant.findMostDamaged() != null;
		}
		catch (e)
		{
			::logError("Skv.Anvil: findMostDamaged threw - " + e);
			return false;
		}
	}

	function onUpdate( _faction )
	{

		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		if (::Skv.Once.isLocked("MasterOfTheAnvil"))
		{
			return;
		}

		if (::World.Flags.has("SkvAnvil.NextDay")
			&& ::World.getTime().Days < ::World.Flags.get("SkvAnvil.NextDay"))
		{
			return;
		}

		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_anvil_contract))
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

		if (v.isMilitary())
		{
			local awareAmb = this.World.Ambitions.getAmbition("ambition.make_nobles_aware");
			if (awareAmb == null || !awareAmb.isDone())
			{
				return;
			}
		}

		local hasForge = false;
		foreach (b in ["building.weaponsmith", "building.armorsmith",
		               "building.weaponsmith_oriental", "building.armorsmith_oriental"])
		{
			try
			{
				if (v.hasBuilding(b))
				{
					hasForge = true;
					break;
				}
			}
			catch (e)
			{
				::Skv.dbg("Skv.Anvil: hasBuilding('" + b + "') threw at " + v.getName() + " - " + e);
			}
		}
		if (!hasForge)
		{
			return;
		}

		if (!this.hasDamagedEnchanted())
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_anvil"))
		{
			return;
		}

		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("MasterOfTheAnvil");
		local contract = this.new("scripts/contracts/contracts/skv_anvil_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
