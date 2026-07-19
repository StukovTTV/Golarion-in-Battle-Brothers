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

		// Once per campaign. Gate via ::Skv.Once (skv_engine): one live offer at a time,
		// and only a passive expiry re-offers -- accept or decline retires it. Comment
		// out this block while testing if you want the contract to keep re-appearing.
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

		// CANONICAL HOST — the tower's lore ties it to Pezzack. If Pezzack is on this map
		// AND can actually host it, then ONLY Pezzack offers it (correct settlement when
		// it exists). If Pezzack isn't drawn, or is drawn somewhere it can't host the
		// contract, fall through: any settlement passing canHost() may offer instead.
		// The canHost() check on the canon town is what prevents a dead campaign.
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

		// Rarity dial. `rand(1,100) > N` DECLINES above N, so it PASSES ~N% of eligible
		// ticks: 17 => ~17%. (Testing value was 99 = near-guaranteed.)
		if (::Math.rand(1, 100) > 17)
		{
			return;
		}

		// Weight from the shared MSU dial (::Skv.Cfg). Was a literal 1; the shared knob
		// defaults to 2, unifying it with the other Golarion contracts (negligible).
		this.m.Score = sc;
	}

	// Can this settlement host the watchtower at all? Used TWICE — for the settlement being
	// ticked, and to test whether the canonical host is live — so the two paths can never
	// drift apart. Terrain is part of it, which is what keeps the fallback tonally correct.
	function canHost( _s )
	{
		if (_s.isIsolated())
		{
			return false;
		}

		// Any village. Forts inherit from legends_fort (not legends_village), so they
		// are excluded automatically. A watchtower belongs to a vulnerable village,
		// not a fortress.
		if (!this.isKindOf(_s, "legends_village"))
		{
			return false;
		}

		// Must have Hills within 3 tiles. This does double duty: it marks the highland
		// frontier (the fiction is raiders coming down from the peaks), AND it guarantees
		// a walkable, spawnable tile for the ruined tower right next to the village.
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
