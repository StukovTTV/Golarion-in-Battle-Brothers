this.legend_watchtower_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "legend_watchtower_action";
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
		if (::Skv.Once.isLocked("Watchtower"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.legend_watchtower_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (!this.canHost(v))
		{
			return;
		}

		// CANONICAL HOST -- Pezzack. If on the map AND able to host, ONLY Pezzack offers it.
		// Otherwise fall through: any settlement passing canHost() may offer instead
		// (the canHost() check on the canon town is what prevents a dead campaign).
		local canon = null;
		foreach (s in ::World.EntityManager.getSettlements())
		{
			if (s.getName() == "Pezzack")
			{
				canon = s;
				break;
			}
		}

		if (canon != null && this.canHost(canon) && v.getName() != "Pezzack")
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.legend_watchtower"))
		{
			return;
		}

		// Rarity dial (~17% of eligible ticks).
		if (::Math.rand(1, 100) > 17)
		{
			return;
		}

		// Selection weight (shared ::Skv.Cfg dial).
		this.m.Score = sc;
	}

	// Can this settlement host the watchtower? Used TWICE (ticked settlement + canon
	// host test) so the two paths can never drift apart.
	function canHost( _s )
	{
		if (_s.isIsolated())
		{
			return false;
		}

		// Any village. Forts inherit legends_fort (not legends_village), excluded.
		if (!this.isKindOf(_s, "legends_village"))
		{
			return false;
		}

		// Hills within 3 tiles -- also guarantees a spawnable tile for the ruined tower.
		if (_s.getSurroundingTilesOfType([::Const.World.TerrainType.Hills], 3).len() == 0)
		{
			return false;
		}

		return true;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		::Skv.Once.claim("Watchtower");
		local contract = this.new("scripts/contracts/contracts/legend_watchtower_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
