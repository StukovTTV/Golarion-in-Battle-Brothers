// ============================================================================
//  AMBUSH IN <CITY> -- ACTION (offer gate)
//  Courier-package job. Hosts NORTH *and* SOUTH (Settlement + OrientalCityState).
//  Readiness split: settlements take isReadyForContract(CATEGORY); city-states take
//  the no-arg form -- wrong one throws and silently kills the faction loop.
//  Confirms a valid DELIVERY CITY exists before offering.
// ============================================================================
this.skv_ambush_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_ambush_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	// Offer-gate delivery target: just "some other reachable town exists." Road/distance
	// band is a PREFERENCE applied at pick time (contract.pickDestination), NOT a gate --
	// gating on them silently declined everywhere on a spread-out map.
	function isDeliveryTarget( _s, _home )
	{
		// _s is a RAW settlement -- no isNull() (WeakTableRef-only), guard with == null.
		if (_s == null) return false;
		if (_s.getID() == _home.getID()) return false;
		if (!_s.isDiscovered()) return false;
		if (_s.isMilitary()) return false;
		if (_s.isIsolated()) return false;
		return true;
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
		if (::Skv.Once.isLocked("Ambush"))
		{
			return;
		}

		// Readiness split -- settlement takes the category arg; city-state the no-arg form.
		if (_faction.getType() == this.Const.FactionType.Settlement)
		{
			if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_ambush_contract))
			{
				return;
			}
			if (_faction.hasContractExclusion("contract.skv_ambush"))
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

		// Any non-military town. Forts drop.
		if (v.isMilitary())
		{
			return;
		}

		// Size 2+ only (town or city) -- needs an undercity to lose a courier in.
		if (v.getSize() < 2)
		{
			return;
		}

		// Confirm at least one qualifying delivery neighbour exists.
		// Wrapped: a predicate throw just declines, never breaks the loop.
		local hasTarget = false;
		try
		{
			foreach (s in ::World.EntityManager.getSettlements())
			{
				if (this.isDeliveryTarget(s, v)) { hasTarget = true; break; }
			}
		}
		catch (e)
		{
			return;
		}
		if (!hasTarget)
		{
			return;
		}

		// Rarity dial (~12%); also once-per-campaign + 14d cooldown.
		if (::Math.rand(1, 100) > 12)
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
		// Claim the one live-offer slot as this town posts it.
		::Skv.Once.claim("Ambush");

		local contract = this.new("scripts/contracts/contracts/skv_ambush_contract");
		contract.setFaction(_faction.getID());
		local home = _faction.getSettlements()[0];
		contract.setHome(home);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		// Dynamic board title -- home is set and this runs BEFORE addContract.
		contract.m.Name = "Ambush in " + home.getName();
		this.World.Contracts.addContract(contract);
	}

});
