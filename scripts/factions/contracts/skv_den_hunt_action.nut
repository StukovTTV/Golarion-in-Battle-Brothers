// ============================================================================
//  THE DEN HUNT -- ACTION (offer gate)
//
//  Bounty on the permanent legendary location skv_den_location. Does NOT spawn
//  its site: it finds the existing Den and points you at it. Registered on
//  FactionTrait.NobleHouse (the beast-hunt list), like the shipped
//  legend_hunting_white_direwolf_action.
// ============================================================================
this.skv_den_hunt_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_den_hunt_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
		this.m.Den <- null;
	}

	// Action stashes the target found in onUpdate for onExecute; drops it on clear.
	function onClear()
	{
		this.m.Den = null;
	}

	function findDen()
	{
		foreach( v in this.World.EntityManager.getLocations() )
		{
			if (v.getTypeID() != "location.skv_den")
			{
				continue;
			}

			// NOT isNull(): getLocations() hands back RAW entities; isNull() exists
			// ONLY on WeakTableRef, so calling it on an entity throws. A throw here
			// kills the whole faction action loop (silent) -- nothing here may throw.
			if (!v.isAlive())
			{
				continue;
			}

			// IsEventLocation is the shipped claim-lock (stollwurms:485): contract
			// sets it on accept, clears in onClear, so two contracts can't share a site.
			if (v.getFlags().get("IsEventLocation"))
			{
				continue;
			}

			return v;
		}

		return null;
	}

	function onUpdate( _faction )
	{
		// Shared frequency dial (::Skv.Cfg): 0 = all Golarion contracts off.
		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		// NOBLE-ONLY: on FactionTrait.NobleHouse only, so isReadyForContract takes
		// the no-arg form. NobleHouse uses no-arg; Settlement passes the
		// ContractCategoryMap arg -- the wrong one throws and kills the faction loop.
		if (!_faction.isReadyForContract())
		{
			return;
		}

		// 990 renown sits above the white wolf and below the bandit army.
		if (this.World.Assets.getBusinessReputation() < 990)
		{
			return;
		}

		local seat = _faction.getSettlements()[0];

		if (seat.isIsolated())
		{
			return;
		}

		// The existence gate: there may be no Den on this map. Prove it before offering.
		local den = this.findDen();

		if (den == null)
		{
			return;
		}

		// Distance gate: without it a noble 100+ tiles away posts a bounty on a wood
		// he's never seen. 40 tiles, by legend_money_delivery_action's scale.
		// UNVERIFIED: whether getSettlements()[0] is a noble house's seat.
		if (seat.getTile().getDistanceTo(den.getTile()) > 40)
		{
			return;
		}

		this.m.Den = den;
		// Weight from the shared MSU dial (::Skv.Cfg).
		this.m.Score = sc;
	}

	function onExecute( _faction )
	{
		local contract = this.new("scripts/contracts/contracts/skv_den_hunt_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		contract.setDen(this.m.Den);
		this.World.Contracts.addContract(contract);
	}

});
