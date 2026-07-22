// ============================================================================
//  AMBUSH IN <CITY> -- ACTION (offer gate)
//
//  A city trader hired a green courier to run a sealed package to a business
//  associate in a NEIGHBOURING city. The courier vanished in the undercity drains,
//  where a goblin warren has nested and trapped its tunnels ahead of a rival
//  warband's parley. The company is hired to find him, recover the package off the
//  warren, and carry it to the associate -- sealed. The contract spawns and owns
//  its own site (see the contract's Offer.end); this action only decides WHERE and
//  WHETHER the job appears, and confirms a valid DELIVERY CITY exists first.
//
//  HOSTS -- NORTH *AND* SOUTH (Settlement + OrientalCityState pools). A courier job
//  fits any trading town, north or south. See the faction-type readiness split below
//  (Azari's gotcha: settlements take isReadyForContract(CATEGORY); city-states take
//  the no-arg form -- the wrong one throws and silently kills the faction loop).
//
//  EXISTENCE-CHECK (deliver_money pattern): the reward is delivered ELSEWHERE, so the
//  action confirms at least one road-connected, discovered, non-military town exists
//  in a sane distance band before offering. Decline if none -- nothing is stored; the
//  contract re-picks the actual destination at accept. All wrapped so a predicate can
//  never throw out of the faction-action tick.
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

	// Is _s a valid DELIVERY target for a hirer at _home? Discovered, civilian, not
	// isolated, road-connected, and a "neighbouring" distance (not the far side of the
	// map). Static-shaped so the contract can re-use the same rule at accept.
	// A valid delivery target for the OFFER GATE: just "some other reachable town exists." Road
	// connection and a tight distance band are a PREFERENCE applied at pick time (contract.pickDestination),
	// NOT an offer gate -- gating on them silently declined everywhere on a spread-out map (v0.92.5 bug:
	// my 6-60 + road check found nothing; the real deliver_money uses 15-100).
	function isDeliveryTarget( _s, _home )
	{
		// NOTE: _s is a RAW settlement from getSettlements() -- it has NO isNull() (that is a
		// WeakTableRef method only). Calling _s.isNull() here threw every tick and the onUpdate
		// try/catch swallowed it into a silent decline -- the v0.92.x "never offers" bug.
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

		// Once per campaign. ::Skv.Once handles the one-live-offer slot + done-flag.
		if (::Skv.Once.isLocked("Ambush"))
		{
			return;
		}

		// Contract-readiness -- settlement (category slot, one arg) vs. city-state
		// (own limit, no arg). The exclusion check is a settlement-slot concept.
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

		// Any non-military town -- town, city, or southern city-state. Forts drop.
		if (v.isMilitary())
		{
			return;
		}

		// Size 2+ only (a town or city). A drains-and-undercity job needs a settlement large
		// enough to HAVE an undercity -- a size-1 hamlet has no sewers to lose a courier in.
		// getSize(): 1 = village/hamlet, 2 = town, 3 = city.
		if (v.getSize() < 2)
		{
			return;
		}

		// A courier job needs somewhere to deliver TO. Confirm at least one qualifying
		// neighbour exists (existence, not a count) -- else this town cannot host it.
		// Wrapped: a predicate throw just declines the offer, never breaks the loop.
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

		// Rarity dial. `rand(1,100) > N` DECLINES above N -> passes ~N% of eligible ticks.
		// RELEASE VALUE = 12 (~12% of eligible ticks; also once-per-campaign + 14d cooldown,
		// so in practice it appears once, early, at a size-2+ town).
		if (::Math.rand(1, 100) > 12)
		{
			return;
		}

		// Selection WEIGHT in the faction-action pick -- the shared ::Skv.Cfg frequency dial (sc),
		// same as every other Golarion contract. ::Skv.Once still locks it to a single town, so a
		// high dial can never flood the board with ambushes.
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
		// Compose the dynamic board title here -- home is set, and this runs BEFORE
		// addContract, so the noticeboard list shows "Ambush in <City>" not the create() stub.
		contract.m.Name = "Ambush in " + home.getName();
		this.World.Contracts.addContract(contract);
	}

});
