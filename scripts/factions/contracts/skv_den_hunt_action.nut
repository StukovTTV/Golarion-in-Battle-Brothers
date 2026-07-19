// ============================================================================
//  THE DEN HUNT -- ACTION (offer gate)
//
//  A bounty on the awakened dire wolves of the Den. Unlike every other contract
//  in this mod, it does NOT spawn its site: it finds the PERMANENT legendary
//  location skv_den_location and points you at it.
//
//  WHY THIS IS DIFFERENT, AND WHAT IT COSTS
//  Every other Golarion contract owns its target -- spawns it on accept, kills
//  it on clear, no save bloat. This one is a bounty on a world fixture that
//  exists whether or not the contract does, and that the player can attack
//  without ever taking the job. So:
//    - the action must PROVE the Den exists before offering (below);
//    - the contract must survive the Den dying by other means (onIsValid);
//    - completion is "the Den is dead", not "my spawned thing is dead".
//  No shipped contract targets a legendary location -- vanilla's candidate
//  filters explicitly EXCLUDE LocationType.Unique (stollwurms:485,
//  slave_uprising:464). The primitives are all shipped and proven; this exact
//  combination is not. Watch log.html.
//
//  WHY NOBLE HOUSES
//  Const.FactionTrait.Actions[FactionTrait.NobleHouse] IS the beast-hunt list --
//  build, upgrade, and ten monster hunts, nothing else (faction_traits.nut:14-27).
//  Legends already ships legend_hunting_white_direwolf_action there: a noble
//  paying for direwolves. This fills an existing slot rather than inventing one.
//
//  WHY *ALSO* SETTLEMENTS
//  Two reasons, one design and one practical.
//    Design: the Den's own leave screen already wrote the hook -- "They will
//    tell it in taverns. They will tell it the way men tell a thing they are
//    ashamed of, which is to say often, and badly." The story spreads through
//    villages first. A village hearing it is more honest than a noble hearing it.
//    Practical: noble houses MAY have a venue-level access gate (the "not worthy
//    of attention" tooltip) requiring renown before their board is readable at
//    all. NOT VERIFIED -- vanilla's isReadyForContract is stubbed in the
//    decompile and Legends does not hook it. If that gate is real, a noble-only
//    contract is untestable early BY CONSTRUCTION. Villages have no such gate.
//  legend_hunting_white_direwolf_action is registered on BOTH lists
//  (faction_traits.nut:17 and :32) and branches on getType() -- that is the
//  shipped precedent for this, copied below.
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

	// restore_location_action's idiom: the action stashes the target it found in
	// onUpdate so onExecute can hand it to the contract, and drops it on clear.
	function onClear()
	{
		this.m.Den = null;
	}

	// ONE predicate, used by nothing else yet, but factored out on the
	// watchtower's canHost() principle: if a second contract ever wants the Den,
	// the two must not drift.
	function findDen()
	{
		foreach( v in this.World.EntityManager.getLocations() )
		{
			if (v.getTypeID() != "location.skv_den")
			{
				continue;
			}

			// NOT isNull(). getLocations() hands back RAW entities, and isNull()
			// exists ONLY on WeakTableRef (weak_table_ref.nut:44) -- calling it on
			// an entity throws "the index 'isNull' does not exist".
			//
			// This action is on the Settlement list, so onUpdate runs for EVERY
			// village every tick. A throw here does not break this contract -- it
			// kills the whole faction action loop, and the village stops offering
			// ANY contracts at all. Silent, total, and it looks nothing like a
			// bug in the new file. Nothing in this function may throw.
			if (!v.isAlive())
			{
				continue;
			}

			// IsEventLocation is the shipped CLAIM-LOCK: stollwurms filters its
			// candidates on !getFlags().get("IsEventLocation") (:485) so two
			// contracts can never target one site. The contract sets it on accept
			// and clears it in onClear.
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
		// Shared frequency dial (::Skv.Cfg): 0 = all Golarion contracts off. This bounty
		// is repeatable (not once-per-campaign), but the master knob still gates it.
		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		// ===== TEST CONFIG =====================================================
		// Everything below marked RELEASE is commented out so the contract offers
		// from turn 1 at the nearest village. Restore all of them before you call
		// this done.
		//
		// NOTE: the contract's gates are NOT your bottleneck when testing -- the
		// DEN existing is. It is terrain-locked to Forest/AutumnForest, which is
		// common enough that it appears to spawn in every campaign (observed, and
		// it contradicts the "terrain lock is the frequency dial" claim in the
		// guide -- forest is not desert). If it ever fails to spawn, loosen
		// minDistToSettlements in the preload's build block, not this file.
		// =======================================================================

		// NO once-per-campaign flag, deliberately. It would be redundant AND wrong.
		// Redundant: findDen() returns null once the Den is dead, so the contract
		// can never offer again -- the existence gate already is the once-lock.
		// Wrong: the flag would ALSO fire if you took the job and abandoned it,
		// locking out a bounty that is still perfectly open. No shipped beast hunt
		// carries one either.

		// NOBLE-ONLY: registered on FactionTrait.NobleHouse only, so the no-argument
		// form is the right and only one. noble_faction.nut:94 --
		//     return m.Contracts.len() == 0
		//         && (m.LastContractTime == 0
		//             || Time.getVirtualTimeF() > m.LastContractTime + SecondsPerDay * 3.0);
		// i.e. ONE live contract per house at a time, plus a 3-day cooldown. Nobles
		// do NOT use the category-slot system at all; that is settlement_faction's.
		//
		// (If villages are ever re-enabled, this needs the getType()==Settlement
		// branch back AND a ContractCategoryMap entry in the preload -- see
		// legend_hunting_white_direwolf_action:22-31, which is on both lists.)
		if (!_faction.isReadyForContract())
		{
			return;
		}

		// The shipped noble ladder, read from the ten actions on
		// Const.FactionTrait.Actions[FactionTrait.NobleHouse]:
		//     demon alps 400 | rock unholds 700 | white direwolf 900 |
		//     skin ghouls 900 | bandit army 1200 | barbarian prisoner 1200 |
		//     stollwurms 1500 | schrats 1500 | coven leader 1500 |
		//     redback webknechts (none)
		//
		// THIS is the gate players actually feel as "the nobles won't talk to me".
		// There is no venue-level lock: noble_faction.isReadyForContract() is only
		// no-active-contract + a 3-day cooldown, and make_nobles_aware's onReward
		// sets no flag. The lock is emergent -- below ~400 renown NOTHING on the
		// list generates, the board comes up empty, and settlement.nut:393 fires
		// IsContractsLocked on a military settlement, which is the "not worthy of
		// attention" message. The ambition (1050 renown, "Professional") just
		// describes that effect honestly.
		//
		// 990 sits above the white wolf and below the bandit army.
		if (this.World.Assets.getBusinessReputation() < 990)
		{
			return;
		}

		local seat = _faction.getSettlements()[0];

		if (seat.isIsolated())
		{
			return;
		}

		// THE EXISTENCE GATE. This is the whole reason the action is unusual:
		// there may be no Den on this map at all, and if there isn't, there is no
		// contract -- not a broken one, none. Prove it before offering.
		local den = this.findDen();

		if (den == null)
		{
			return;
		}

		// ON, and not a nicety -- without it a Trade Master 101 TILES away posts a
		// bounty on a wood he has never seen and the camera flies across the map
		// to show him a place he cannot possibly know about. Observed in play.
		//
		// Calibration: legend_money_delivery_action:60-65 treats 12-100 as the band
		// for a delivery ACROSS THE MAP (`d <= 12 || d > 100` -> skip). So tile
		// units, and 100 is the longest journey Legends ships. 101 was off the end
		// of the scale for what is meant to be a local wolf problem.
		//
		// 40, not 30, because VENUE COUNT drives this, not plausibility.
		// The Den is placed 6-22 tiles from its NEAREST settlement -- but that
		// neighbour is whatever village happened to be closest, and it may not be
		// a venue that can offer this at all. A noble house posts at
		// getSettlements()[0], and there are only a handful of houses per map, so
		// the nearest QUALIFYING venue can sit far outside the Den's own 6-22
		// neighbourhood. 30 would starve the noble path; 40 keeps it fed while
		// still being local by the shipped scale.
		//
		// UNVERIFIED: whether getSettlements()[0] is a noble house's seat. faction.nut:266
		// just returns m.Settlements with no capital concept or documented order.
		// Note legend_hunting_white_direwolf_action gates on
		// `getSettlements()[0].getSize() > 2 -> return` (size 1-2 only) -- if [0]
		// WERE the capital, that noble hunt could never fire. So either [0] is not
		// the seat, or Legends ships a dead registration there. Unresolved.
		//
		// This is a further reason to keep the Settlement registration beyond
		// testing: a village IS its own faction, so [0] is unambiguous and the
		// venue question does not arise.
		if (seat.getTile().getDistanceTo(den.getTile()) > 40)
		{
			return;
		}

		this.m.Den = den;
		// Weight from the shared MSU dial (::Skv.Cfg). Was a literal 1; unified to the
		// shared default (2) with the other Golarion contracts.
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
