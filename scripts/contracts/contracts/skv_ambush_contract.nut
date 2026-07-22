// ============================================================================
//  AMBUSH IN <CITY> -- CONTRACT (state machine)          [contract #8, v0.92]
//
//  Venture-Captain Ambrus Valsin of the Pathfinder Society lost a green agent in the
//  undercity drains, carrying a SEALED package for his contact -- the Sczarni fence
//  Guaril Karela -- in a NEIGHBOURING city. A goblin warren has nested in the tunnels
//  and trapped them ahead of a rival warband's parley. The company follows the agent's
//  trail down: a trapped passage (a skill check), a goblin PICKET (scripted fight), the
//  lost trail, then the warband CHIEF's escort (a scripted fight led by a real
//  makeMiniboss champion goblin_leader). Off the fallen escort they recover the agent's
//  kit and the sealed satchel, and carry it to Karela -- where the temptation to break
//  the seal decides the ending (the return_item fork: deliver sealed and be paid the
//  balance, or pry it open, be refused, and keep only the advance). The reveal at the
//  counter is the source's punchline: the parcel is a cookery book Karela ALREADY OWNS,
//  a coded line hidden in one recipe -- the lad died in the dark to carry a cookbook.
//
//  Adapted from the Pathfinder Society Quest "Ambush in Absalom" (Mark Moreland, 2012;
//  kobolds -> goblins). The Society framing is RESTORED as of v0.92.24: Venture-Captain
//  Ambrus Valsin hires the company, Guaril Karela receives the parcel, and the "already
//  owns the cookbook" reveal is put back. Built on the shared ::Skv engine, in the Azari
//  mould (fixed crawl, scripted combat from a screen).
//
//  Structure: Offer -> Running -> Deliver. The warren crawl runs in Running; once the parcel
//  is recovered the RecoverRoom option transitions to the Deliver state (the base return_item
//  pattern -- a real setState is what flips the objective UI; see the Deliver state's notes).
//  ART: event_NN images are safe placeholders -- an art pass (goblin/sewer contact
//  sheets) is a build-order TODO, see ambush_contracts.md.
// ============================================================================
this.skv_ambush_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Site        = null,   // the undercity-drains marker
		Destination = null,   // the neighbouring city the package is delivered to (WeakTableRef)
		DestName    = "",     // its name, cached for objective text + serialize
		HasPackage  = false,  // the sealed satchel recovered off the escort
		SiteCleared = false,  // warren done -> deliver leg is live
		Decided     = false,  // an ending was chosen -> show Outcome, not Delivery, on re-arrival
		Betrayed    = false,  // the seal was broken (flavor/consistency)
		OutcomeText = "",     // Outcome narrative (not serialized)
		OutcomeRows = null,   // Outcome iconed rows (not serialized)
		RoomRows    = null,   // a room/recover result's rows (not serialized)
		RoomText    = "",     // a room/recover result's narrative (not serialized)
		ActorName   = "",     // last brother to act on a check -> ::Skv.Check %actor% (transient)
		Deck        = null,   // the fixed room sequence, assembled on first arrival
		CrawlIndex  = 0,      // which card you are on
		FightWon    = false,  // a scripted fight was won -> update() advances (transient)
		FightFled   = false,  // retreated from a mandatory fight -> re-show it (transient)
	},

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_ambush";
		this.m.Name = "An Ambush";   // stub; the action composes "Ambush in <City>" once Home is set
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;   // two cities -> a longer board life
		this.m.Category = this.Const.Contracts.Categories.Battle;   // return-item + two mandatory fights
		this.m.DescriptionTemplates = [
			"A Pathfinder Society venture-captain is short an agent. The lad took a sealed parcel down into the city drains to save a few streets and never came up the other side -- and there is a contact in the next town still waiting on it. The venture-captain wants his agent found, the parcel recovered, and the thing carried the rest of the way, sealed. He is paying outside hands to do quietly what the Society cannot be seen to do.",
			"Word from the local lodge: a Pathfinder's agent lost in the undercity, a sealed package gone with him, and something down in the drains that folk have started crossing the street to avoid. The pay is fair for a fetch, better for a fight -- and there may be both.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		// 1 skull, ROLLED -- and the same DifficultyMult drives both fight budgets
		// (see startPatrolFight / startEscortFight). Kept below the 0.9 easy threshold
		// (base contract.nut:646) so the board always shows 1 skull, and both fight
		// budgets shrink with it (~19% off the old 2-skull midpoint).
		this.m.DifficultyMult = this.Math.rand(65, 80) * 0.01;   // 0.65-0.80 -> always 1 skull; a true starter job (the champion boss is the one spike)

		// Notable-delivery base: two fights + a two-city trek + the recovered kit.
		this.m.Payment.Pool = 900 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		// 33% up front (the betrayal floor -- kept however it ends), 67% on delivery.
		this.m.Payment.Completion = 0.67;
		this.m.Payment.Advance = 0.33;

		this.contract.start();
	}

	// The drains entrance -- a free land tile 1-3 from home (the delivery leg is the travel).
	function pickSiteTile()
	{
		local excluded = [
			this.Const.World.TerrainType.Ocean,
			this.Const.World.TerrainType.Shore,
			this.Const.World.TerrainType.Mountains
		];
		return this.getTileToSpawnLocation(this.m.Home.getTile(), 1, 2, excluded, false);
	}

	// Pick the NEAREST qualifying neighbour as the delivery city (same rule the action's
	// existence-check used; the action guaranteed at least one exists). Falls back to Home.
	// Pick the delivery city: PREFER the nearest road-connected town, but fall back to the nearest
	// eligible town regardless of roads (so a valid offer always resolves to a real destination).
	// The action only gates on "some eligible town exists"; the road/near preference lives here.
	function pickDestination()
	{
		local best = null;     local bestD = 99999;   // nearest road-connected
		local fallback = null; local fbD = 99999;      // nearest eligible, roads or not
		foreach (s in this.World.EntityManager.getSettlements())
		{
			if (s == null) continue;   // raw settlements have no isNull() -- see the action's isDeliveryTarget note
			if (s.getID() == this.m.Home.getID()) continue;
			if (!s.isDiscovered()) continue;
			if (s.isMilitary()) continue;
			if (s.isIsolated()) continue;
			local d = this.m.Home.getTile().getDistanceTo(s.getTile());
			if (d < fbD) { fbD = d; fallback = s; }
			if (this.m.Home.isConnectedToByRoads(s) && d < bestD) { bestD = d; best = s; }
		}
		return best != null ? best : fallback;
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				// Compose the dynamic title here too (belt-and-suspenders with the action).
				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
				{
					this.Contract.m.Name = "Ambush in " + this.Contract.m.Home.getName();
				}
				this.Contract.m.BulletpointsObjectives = [
					"Follow the courier's trail into the undercity drains"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				// Pick the delivery city (nearest qualifying neighbour).
				local dest = this.Contract.pickDestination();
				if (dest == null) dest = this.Contract.m.Home;   // safety net (action gated on existence)
				this.Contract.m.Destination = this.WeakTableRef(dest);
				this.Contract.m.DestName = dest.getName();

				// Spawn the drains marker near home.
				local tile = this.Contract.pickSiteTile();
				if (tile == null)
				{
					local excluded = [
						this.Const.World.TerrainType.Ocean,
						this.Const.World.TerrainType.Shore,
						this.Const.World.TerrainType.Mountains
					];
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 1, 5, excluded, false);
				}
				tile.clear();
				this.Contract.m.Site = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_ambush_location", tile.Coords));
				this.Contract.m.Site.onSpawned();
				this.Contract.m.Site.setName("The Undercity Drains");
				this.Contract.m.Site.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Goblins).getID());
				this.Contract.m.Site.setDiscovered(true);
				this.Contract.m.Site.setAttackable(false);   // a marker; every fight is a scripted combat from a screen
				this.World.uncoverFogOfWar(this.Contract.m.Site.getTile().Pos, 500.0);

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				// Objective + marker DERIVED from the current leg (the Choking Tower pattern), so a
				// reload or any state re-entry always lands on the right goal instead of a stale one.
				// Belt-and-suspenders with the immediate flip in recoverPackage / departForDelivery:
				// the objective can't get stuck once the parcel is in hand.
				if (this.Contract.m.SiteCleared || this.Contract.m.HasPackage)
				{
					this.Contract.m.BulletpointsObjectives = [
						"Deliver the sealed package to " + this.Contract.m.DestName
					];
					if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull())
					{
						this.Contract.m.Destination.getSprite("selection").Visible = true;
					}
				}
				else
				{
					this.Contract.m.BulletpointsObjectives = [
						"Follow the courier's trail into the undercity drains"
					];
					if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull())
					{
						this.Contract.m.Site.getSprite("selection").Visible = true;
					}
				}
			}

			function update()
			{
				// --- A scripted fight was WON: consume it, advance the crawl. If the escort
				// just fell, recover the kit + satchel and show the RecoverRoom. (Top of the
				// tick, before the arrival logic can re-fire -- the Azari crypt pattern.)
				if (this.Contract.m.FightWon)
				{
					this.Contract.m.FightWon = false;
					local justFought = this.Contract.m.Deck[this.Contract.m.CrawlIndex];
					this.Contract.m.CrawlIndex = this.Contract.m.CrawlIndex + 1;
					this.TempFlags.set("AtSite", true);
					if (justFought == "escort")
					{
						this.Contract.recoverPackage();
						this.Contract.setScreen("RecoverRoom");
					}
					else
					{
						this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
					}
					this.World.Contracts.showActiveContract();
					return;
				}

				// --- Retreated from a MANDATORY fight: re-show the same fight card (you must
				// win to pass; the index is NOT advanced). Leaving the site entirely aborts.
				if (this.Contract.m.FightFled)
				{
					this.Contract.m.FightFled = false;
					this.TempFlags.set("AtSite", true);
					this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
					this.World.Contracts.showActiveContract();
					return;
				}

				// --- DELIVERY LEG safety net: the normal path transitions to "Deliver" from inside
				// RecoverRoom's getResult (so dismissing that screen repaints the goal). By the time
				// this tick runs we are already in the Deliver state, so this branch does NOT fire in
				// the normal flow -- it only catches an old/partial save that restored into Running
				// with SiteCleared already set, and re-asserts the correct state.
				if (this.Contract.m.SiteCleared)
				{
					this.Contract.setState("Deliver");
					return;
				}

				// --- Arrival at the drains: start / resume the crawl -------------------------
				if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull() && this.Contract.isPlayerAt(this.Contract.m.Site))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						if (this.Contract.m.Deck == null)
						{
							this.Contract.m.Deck = this.Contract.assembleDeck();
							this.Contract.m.CrawlIndex = 0;
						}
						this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtSite", false);
				}
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == "AmbushFight")
				{
					this.Contract.m.FightWon = true;
				}
			}

			function onRetreatedFromCombat( _combatID )
			{
				if (_combatID == "AmbushFight")
				{
					this.Contract.m.FightFled = true;
				}
			}
		});

		// DELIVER: the second leg, entered from Running via setState once the parcel is in hand and
		// the company leaves the drains. Entering the state runs start(), which sets the "deliver"
		// objective + lights the destination -- and the STATE TRANSITION is what actually rebuilds
		// the objective UI (the base return_item pattern). On reload mid-trek the contract restores
		// straight into this state, so start() re-asserts the goal.
		this.m.States.push({
			ID = "Deliver",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Deliver the sealed package to " + this.Contract.m.DestName
				];
				// A state start() ONLY sets the goal -- it NEVER calls showActiveContract().
				// (Base return_item's Return.start() does exactly this and no more.) The repaint
				// comes for free from DISMISSING the RecoverRoom screen after the getResult that
				// transitioned us here -- the same way base repaints on dismissing its BattleDone.
				// Calling showActiveContract() here instead crashed ("the index 'Text' does not
				// exist", contract.nut getUIContent) because it re-renders the CURRENT contract
				// screen as an event popup, and that screen was just closed. That crash aborted the
				// whole transition, which is why the objective never flipped.
				if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull())
				{
					this.Contract.m.Destination.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				// Arrived at the neighbouring city -> the seal fork (Delivery screen) or, if already
				// decided, the Outcome recap.
				if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull() && this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (!this.TempFlags.get("AtDest"))
					{
						this.TempFlags.set("AtDest", true);
						this.Contract.setScreen(this.Contract.m.Decided ? "Outcome" : "Delivery");
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtDest", false);
				}
			}
		});
	}

	// ---- CRAWL ----------------------------------------------------------------
	function assembleDeck()
	{
		// Fixed, hand-authored sequence (not shuffled): trail -> trap -> picket fight ->
		// lost trail -> the chief's escort. Recovery + delivery follow the escort victory.
		return ["trail", "trap", "patrol", "rest", "track", "escort"];
	}

	function roomScreenFor( _key )
	{
		if (_key == "trail")  return "TrailRoom";
		if (_key == "trap")   return "TrapRoom";
		if (_key == "patrol") return "PatrolFight";
		if (_key == "rest")   return "RestRoom";
		if (_key == "track")  return "TrackRoom";
		if (_key == "escort") return "EscortFight";
		return "TrailRoom";
	}

	function advance()
	{
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return this.roomScreenFor(this.m.Deck[this.m.CrawlIndex]);
	}

	// Stash a result's rows + text, ADVANCE the index (so a card can't re-run on a
	// re-enter or reload), and route to the shared RoomResult screen.
	function resolveRoom( _rows, _text )
	{
		this.m.RoomRows = _rows;
		this.m.RoomText = _text;
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return "RoomResult";
	}


	// ---- FIGHTS ---------------------------------------------------------------
	// Shared combat scaffold: local combat on the player's tile, forced onto a ruined-stone
	// map (a sewer read, not the surface terrain), enemies on the goblin world-faction side.
	function newFightProperties()
	{
		local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
		p.CombatID = "AmbushFight";
		p.Tile = this.World.State.getPlayer().getTile();
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;
		p.TerrainTemplate = "tactical.plains";
		p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
		p.LocationTemplate.Template[0] = "tactical.ruins";
		p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.None;
		return p;
	}

	function goblinFactionID()
	{
		return this.World.FactionManager.getFactionOfType(this.Const.FactionType.Goblins).getID();
	}

	// The picket that killed the courier: a light goblin scout-party, budget-scaled off the
	// skull rating AND company strength (a 2-skull roll is a bigger picket).
	function startPatrolFight()
	{
		this.m.FightWon = false;
		this.m.FightFled = false;
		local p = this.newFightProperties();
		local fac = this.goblinFactionID();
		local budget = 50 * this.getDifficultyMult() * this.getScaledDifficultyMult();   // picket: a warm-up
		// Reusable GolarionKobolds (warriors only, MinR 15) -- so this small budget actually governs
		// the size, instead of the stock GoblinScouts (MinR 75) flooring it up to ~5. See mod_golarion.nut.
		this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn.GolarionKobolds, budget, fac);
		::logInfo("Skv.Ambush patrol budget=" + budget);
		this.World.Contracts.startScriptedCombat(p, false, true, true);
	}

	// The chief's escort: a heavier goblin honour-guard (GolarionKoboldsCasters, bigger BASE) led by a CHAMPION BOSS that
	// scales with company strength -- a THREE-TIER ladder of fighter units, ALL real champions:
	//   tier 0 (weakest) -> goblin_fighter_low   } championed via makeMiniboss, then any NAMED weapon
	//   tier 1 (mid)     -> goblin_fighter        } the promotion equipped is STRIPPED and re-rolled
	//   tier 2 (strong)  -> goblin_leader (keeps its named crossbow -- named loot gated to this tier)
	// makeMiniboss() is a BASE actor method (verified: base-game actor.nut:3714) -- works on ANY unit
	// (+1.5x XP, champion_racial stats, miniboss flag, custom name; touches no equipment). NAMED gear
	// comes only from a unit's own makeMiniboss OVERRIDE, so the lower tiers strip it after the fact
	// (see onCappedChampionPlaced) rather than relying on which unit does/doesn't carry an override.
	// The tier is decided HERE, OUTSIDE the callbacks (getScaledDifficultyMult isn't reachable inside).
	function escortBossTier()
	{
		local mult = this.getScaledDifficultyMult();
		if (mult < 1.3) return 0;
		if (mult < 2.5) return 1;
		return 2;
	}

	function startEscortFight()
	{
		this.m.FightWon = false;
		this.m.FightFled = false;
		local p = this.newFightProperties();
		local fac = this.goblinFactionID();
		local budget = 70 * this.getDifficultyMult() * this.getScaledDifficultyMult();   // boss set-piece
		// GolarionKoboldsCasters (warriors + a rare shaman/witch-doctor) -- the chief's warren can field
		// a dragon-priest. Larger BASE (70 vs 50) makes the escort the heavier fight, but the real spike is
		// the hand-pushed CHAMPION below (never budget-gated) -- the escort rank-and-file stays a starter's
		// handful so the boss is the one that matters.
		this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn.GolarionKoboldsCasters, budget, fac);

		// Three-tier boss ladder, all real champions (makeMiniboss). Named loot is controlled per tier
		// by the callback: lower tiers STRIP any named weapon and re-roll a plain one; the leader keeps
		// his named crossbow. (ID GoblinFighter covers goblin_fighter_low, which shares that EntityType.)
		local tier = this.escortBossTier();
		if (tier == 0)
		{
			// weakest company -> a goblin_fighter_low headman
			p.Entities.push({
				ID = this.Const.EntityType.GoblinFighter, Variant = 0, Row = 0,
				Script = "scripts/entity/tactical/enemies/goblin_fighter_low",
				Faction = fac, Callback = this.onCappedChampionPlaced.bindenv(this)
			});
		}
		else if (tier == 1)
		{
			// mid -> a full goblin_fighter
			p.Entities.push({
				ID = this.Const.EntityType.GoblinFighter, Variant = 0, Row = 0,
				Script = "scripts/entity/tactical/enemies/goblin_fighter",
				Faction = fac, Callback = this.onCappedChampionPlaced.bindenv(this)
			});
		}
		else
		{
			// strong -> the true chief, goblin_leader (keeps his named crossbow)
			p.Entities.push({
				ID = this.Const.EntityType.GoblinLeader, Variant = 0, Row = 0,
				Script = "scripts/entity/tactical/enemies/goblin_leader",
				Faction = fac, Callback = this.onChampionChiefPlaced.bindenv(this)
			});
		}
		::logInfo("Skv.Ambush escort budget=" + budget + " bossTier=" + tier);
		this.World.Contracts.startScriptedCombat(p, false, true, true);
	}

	// Lower-tier champion (goblin_fighter_low / goblin_fighter): full makeMiniboss, then STRIP any named
	// weapon the promotion equipped and re-roll a normal one via the unit's own (slot-guarded)
	// assignRandomEquipment -- a real champion with NO named loot. Robust to the whole override/
	// inheritance question: if no named item is present, isItemType returns false and the strip is a no-op.
	function onCappedChampionPlaced( _entity, _tag )
	{
		_entity.makeMiniboss();
		local items = _entity.getItems();
		local slots = [this.Const.ItemSlot.Mainhand, this.Const.ItemSlot.Offhand];
		foreach (slot in slots)
		{
			local it = items.getItemAtSlot(slot);
			if (it != null && it.isItemType(this.Const.Items.ItemType.Named))
			{
				items.unequip(it);
				items.removeFromBag(it);
			}
		}
		_entity.assignRandomEquipment();   // guarded: refills only the emptied slot(s) with plain gear
		local names = ["Grukk Blackfang", "Snagga the Chief", "Vharrok", "Old Skabb", "Gnashjaw", "Rukka Warlord"];
		_entity.setName(names[this.Math.rand(0, names.len() - 1)]);
	}

	// Final-tier champion (goblin_leader): full makeMiniboss and KEEP its named crossbow -- named loot
	// is gated to this tier only. No strip.
	function onChampionChiefPlaced( _entity, _tag )
	{
		_entity.makeMiniboss();
		local names = ["Grukk Blackfang", "Snagga the Chief", "Vharrok", "Old Skabb", "Gnashjaw", "Rukka Warlord"];
		_entity.setName(names[this.Math.rand(0, names.len() - 1)]);
	}

	// ---- RECOVER + DELIVERY ---------------------------------------------------
	// After the chief falls: recover the dead courier's kit (an iconed haul + coin) and the
	// SEALED satchel (a flag; no bespoke art). Builds the RecoverRoom rows/text.
	function recoverPackage()
	{
		this.m.HasPackage = true;
		local coin = this.Math.rand(90, 170);
		local paths = ["scripts/items/loot/signet_ring_item"];   // the courier's ring, off his body
		this.m.RoomRows = ::Skv.Loot.haul(::Skv.Loot.make(paths), coin);
		this.m.RoomText = "[img]gfx/ui/events/event_98.png[/img]{The chief's guard lie where they fell. Among their filched trophies is a Pathfinder's-worth of a poor lad's life: a battered ring, a few coins, and -- wrapped in oilcloth and still sealed with a wax stamp none of the goblins could read -- the parcel the courier died carrying. You take it up. It is light, and it is whole. The rest of the way is yours to walk.}";
		// Flip the objective the MOMENT the parcel is in hand -- not only on the "Out of the drains"
		// click below -- so the goal reads "deliver it" as soon as the boss falls. departForDelivery
		// still repeats this and does the physical leaving (kills the site, sets SiteCleared). The
		// caller (the escort-victory update() / the skip button) repaints right after this runs.
		this.m.BulletpointsObjectives = [
			"Deliver the sealed package to " + this.m.DestName
		];
		if (this.m.Destination != null && !this.m.Destination.isNull())
		{
			this.m.Destination.getSprite("selection").Visible = true;
		}
	}

	// Leave the drains and set out to deliver -- flips the leg on, removes the site, repoints the objective.
	function departForDelivery()
	{
		this.m.SiteCleared = true;
		if (!::MSU.isNull(this.m.Site)) this.m.Site.die();
		this.m.Site = null;
		this.m.BulletpointsObjectives = [
			"Deliver the sealed package to " + this.m.DestName
		];
		if (this.m.Destination != null && !this.m.Destination.isNull())
		{
			this.m.Destination.getSprite("selection").Visible = true;
		}
		// NO showActiveContract() here. This helper runs inside RecoverRoom's getResult, which then
		// does setState("Deliver") and returns 0 -- dismissing the screen is what repaints the map
		// with the new goal (the base return_item pattern). Calling showActiveContract() mid-getResult
		// re-pops the screen instead, and calling it from a state start() crashes on the closed screen.
	}

	// The recipient's faction (the neighbouring city), for the delivery relation. Guarded.
	function destFaction()
	{
		if (this.m.Destination == null || this.m.Destination.isNull()) return null;
		try { return this.World.FactionManager.getFaction(this.m.Destination.getFaction()); }
		catch (e) { return null; }
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		// --- TASK: Venture-Captain Valsin's hire.
		this.m.Screens.push({
			ID = "Task",
			Title = "The Missing Courier",
			Text = "[img]gfx/ui/events/event_76.png[/img]{%SKVNAME%Venture-Captain Ambrus Valsin%SKVNAME_OFF% of the Pathfinder Society catches you at the lodge, worry under the courtesy. %SPEECH_ON%I sent one of my agents two days past -- a green lad, all eagerness and no sense -- with a sealed parcel for a contact of mine in %SKVLOC%%destinationname%%SKVLOC_OFF%. He took the drains under the city to spare himself the streets, and he has not come up. There is something down in those tunnels now; folk have started going the long way round. This is Society business, and I would sooner not feed more of my own to it. Find him. If he lives, send him home with his ears ringing. If he does not -- bring the parcel up sealed, and carry it the rest of the way to my contact yourself. Part of your pay now, the rest when it is in his hands. And mind the seal: it is my contact's to break, not ours.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We will find your courier and see the parcel through.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{The drains, you say. What is down there?}",
						function getResult() { return "Lore"; }
					});
				}

				this.Options.push({
					Text = "{Find another company.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}
				});
			}
		});

		// --- LORE: two brothers on the undercity and its new tenants.
		this.m.Screens.push({
			ID = "Lore",
			Title = "The Undercity",
			Text = "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% has walked drains like these before. %SPEECH_ON%Every old city is built on its own gut -- sewers, cisterns, the tunnels nobody maps. Warm, dark, out of the rain. Good place to move unseen; good place for things that would rather not be seen.%SPEECH_OFF% %SKVNAME%%randombrother2%%SKVNAME_OFF% grunts. %SPEECH_ON%Goblins, most like. They den in the undercity and string the runs with tripwires and pits -- and they set MORE of them when they are expecting company. If the little wretches are fortifying, some bigger goblin is coming to call.%SPEECH_OFF% The first man nods. %SPEECH_ON%So we go in careful, and we do not go in blind. A lost boy is one thing. A trapped warren with a chief on the way is another.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. The terms again.}",
					function getResult() { return "Task"; }
				}
			],
			function start() {}
		});

		// --- TRAIL: down into the drains on the courier's tracks.
		this.m.Screens.push({
			ID = "TrailRoom",
			Title = "The Courier's Trail",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The drain mouth breathes cold, wet air. Just inside, in the silt along a trickle of runoff, a set of muddy bootprints leads in -- a young man's stride, hurried, careless. They wind deeper into the dark, following the water. So does the company.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On, then -- quiet and careful.}",
					function getResult() { return this.Contract.advance(); }
				}
			],
			function start() {}
		});

		// --- TRAP: a covered goblin pit, worked as a TWO-PART check.
		//  (1) PERCEPTION (::Skv.Check.perception) -- the sharpest-eyed brother tries to SPOT the
		//      false floor. Base scales with contract difficulty: clamp(100 - 50 * DifficultyMult, 5,
		//      95) -- a harder job hides the trap better.
		//  (2) ATHLETICS (::Skv.Check.agility) -- the nimblest brother CROSSES. Base 50 if the trap was
		//      spotted, 25 if it was missed (blind crossing). Fail -> a leg injury (Const.Injury.Mountains).
		//  The two are usually DIFFERENT brothers (the scout who saw it, the tumbler who led across).
		//  XP on a clean crossing goes to the crosser, and is SPLIT with the spotter only when BOTH
		//  checks succeeded (a blind-luck crossing credits the crosser alone).
		this.m.Screens.push({
			ID = "TrapRoom",
			Title = "A Trapped Passage",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The tunnel narrows to a low, muddy junction. The floor ahead may be wrong -- a stretch of packed muck that could be laid a shade too smooth, too level, or could be nothing at all. Goblins dig covered pits here, a full stride deep and floored with filed stakes, and lid them over so well the first you know is the drop. There is no wire to find, no catch to cut: someone has to read the ground with a sharp eye, and someone light-footed has to lead the company across it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Sharp eyes to find it, light feet to cross it.}",
						function getResult()
						{
							// (1) SPOT -- perception, base scaled by contract difficulty (anchor 50) via the
							// shared helper, which also honors the "scale checks" MSU toggle.
							local spot = ::Skv.Check.perception(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local spotter = spot.actor;
							local spotterName = (spotter != null) ? spotter.getName() : "the point man";
							// (2) CROSS -- agility, base 50 if spotted, 25 if blind. (Overwrites m.ActorName.)
							local cross = ::Skv.Check.agility(this.Contract, spot.ok ? 50 : 25);
							local crosserName = (cross.actor != null) ? cross.actor.getName() : this.Contract.m.ActorName;

							if (cross.ok)
							{
								// XP: crosser always; spotter shares only if he ALSO spotted it (grant dedupes).
								local actors = [];
								if (cross.actor != null) actors.push(cross.actor);
								if (spot.ok && spotter != null) actors.push(spotter);
								local rows = (actors.len() > 0 && ("XP" in ::Skv)) ? ::Skv.XP.grant(actors, 200) : [];
								local text = spot.ok
									? "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + spotterName + "%SKVNAME_OFF% catches the seam of the false floor before a boot ever finds it, and on his word %SKVNAME%" + crosserName + "%SKVNAME_OFF% threads the company past the covered pit one man at a time -- each boot set where his was. No sound, no fall. Whoever dug it will not know a soul crossed.}"
									: "[img]gfx/ui/events/event_89.png[/img]{No one marks the floor for what it is -- but %SKVNAME%" + crosserName + "%SKVNAME_OFF% feels it give a hair too easy underfoot, freezes the whole line with a hiss, and picks the way across the covered pit on instinct alone. Quick feet and quicker luck, and the company is over dry.}";
								return this.Contract.resolveRoom(rows, text);
							}
							return this.Contract.resolveRoom([this.Contract.trapFall(crosserName)], "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + crosserName + "%SKVNAME_OFF% leads off and gets it wrong. The lid gives under him and he drops a full stride into the pit, twisting as he falls to keep off the stakes -- and comes up on a leg that will not take his weight. The men haul him out. He can walk, after a fashion; the warren, no doubt, heard him land.}");
						}
					}
				];
			}
		});

		// --- PATROL FIGHT: the goblin picket that killed the courier.
		this.m.Screens.push({
			ID = "PatrolFight",
			Title = "The Picket",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The passage opens into a flooded junction -- and the dark is full of eyes. Goblins, a picket of them, crouched in the drain-mouths with slings and jagged spears, watching the very ground the trap defended. Between two of them, sprawled half in the water, is the boy: a courier's satchel-strap still crossing his chest, empty, and his throat a ruin. He found this picket the hard way. Now it has found you.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Blades. Put them down before they scatter and warn the rest.}",
						function getResult()
						{
							this.Contract.startPatrolFight();
							return 0;
						}
					}
				];
			}
		});

		// --- REST: a short breather after the picket. Roleplay beat + a light "bind the worst" patch
		// (the diegetic answer to "outfit after the first battle" -- no map-drop, no inventory UI).
		this.m.Screens.push({
			ID = "RestRoom",
			Title = "A Breather",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The picket is down and the water goes quiet again. Before pressing deeper the company takes what rest the dark allows -- a few minutes to bind the worst of it, cinch a loose strap, put an edge back on a notched blade, drink. %SKVNAME%%randombrother%%SKVNAME_OFF% works a whetstone down his blade and does not look up. %SPEECH_ON%Those were the doorkeepers. Whatever they were minding is deeper in, and it will be bigger. Set your gear right the once -- there'll be no asking for it down there.%SPEECH_OFF% Past the running water, somewhere ahead, a great many voices are on the move.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					// A "stay here" option: opens the character/loadout screen over this
					// breather and returns to it on close. Returns THIS screen's ID (never 0)
					// so processInput keeps the screen alive under the loadout overlay.
					// showLoadoutFromContract (the world_state hook in mod_golarion.nut) does
					// the hide/show + MenuStack restore; refillAmmo is charged on close.
					{
						Text = "{Set our gear right the once -- there'll be no asking down there. (open loadout)}",
						function getResult()
						{
							::World.State.showLoadoutFromContract();
							return "RestRoom";
						}
					},
					{
						Text = "{Buckled and ready. On, deeper.}",
						function getResult() { return this.Contract.advance(); }
					}
				];
			}
		});

		// --- TRACK: the trail is lost among goblin prints; find it and press on.
		this.m.Screens.push({
			ID = "TrackRoom",
			Title = "The Lost Trail",
			Text = "[img]gfx/ui/events/event_89.png[/img]{Past the picket the boy's tracks are gone -- churned away under a hundred small clawed feet coming and going. The satchel is not on his body; the goblins have carried it deeper. For a while the company casts about the muck in the dark, until someone picks out the freshest of the goblin runs -- broad, well-worn, heading toward a wider tunnel where the sound of a good many voices echoes up. The chief's road. The parcel went that way.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Follow it. Toward the voices.}",
					function getResult() { return this.Contract.advance(); }
				}
			],
			function start() {}
		});

		// --- ESCORT FIGHT: the chief and his honour-guard, met head-on.
		this.m.Screens.push({
			ID = "EscortFight",
			Title = "The Chief's Escort",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The tunnel widens into a vaulted trunk-drain, and there -- coming the other way, torches and tusked helms -- is the chief's own escort: the warband's best, spears and shields, and at their head a goblin bigger than any you have seen, hung with the trophies of a dozen fights and the satchel of a dead courier tied at his belt like one more. He was expecting an ambush on his road. He has decided you are it. There is no talking past this.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Then give him one. Take the chief.}",
						function getResult()
						{
							this.Contract.startEscortFight();
							return 0;
						}
					}
				];
			}
		});

		// --- RECOVER: after the chief falls -- the kit + the sealed satchel, then set out.
		this.m.Screens.push({
			ID = "RecoverRoom",
			Title = "Off the Chief's Guard",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Out of the drains -- we have a parcel to deliver.}",
					function getResult()
					{
						// The base return_item spine: flip the leg via a STATE TRANSITION from within
						// this getResult (base does exactly this in its CounterOffer -> setState("Return")
						// option), then return 0. Deliver.start() sets the "deliver" objective; dismissing
						// THIS screen (return 0) is what repaints the world-map goal. No showActiveContract
						// anywhere in this path -- that call is what crashed the old transition.
						this.Contract.departForDelivery();
						this.Contract.setState("Deliver");
						return 0;
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You take up the sealed parcel and turn for the surface.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		// --- ROOM RESULT: shows a trap/track result, then continues to the next card.
		this.m.Screens.push({
			ID = "RoomResult",
			Title = "The Drains",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On.}",
					// The room that led here ALREADY advanced the index; just show the current card.
					function getResult() { return this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]); }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You press on.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		// --- DELIVERY: the seal fork (the return_item spine).
		this.m.Screens.push({
			ID = "Delivery",
			Title = "The Sealed Parcel",
			Text = "[img]gfx/ui/events/event_15.png[/img]{In %SKVLOC%%destinationname%%SKVLOC_OFF% the contact keeps a counter in the back of a low tavern: %SKVNAME%Guaril Karela%SKVNAME_OFF%, a thin, mustachioed man who goes still at the sight of the wax seal, then eases when he sees it whole. %SPEECH_ON%Valsin's parcel -- and unopened. Good. You have no notion how rare that is in this trade.%SPEECH_OFF% He reaches for it across the counter. The thing is a hand-span of oilcloth and a lump of wax, and a green lad carried it down into the dark and never came out. Whatever is under that seal, Karela means to be the one to read it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [];

				// Deliver sealed -- the honest ending: full completion + renown + the town's regard.
				this.Options.push({
					Text = "{Hand it over. Sealed, as promised.}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeMoney(this.Contract.m.Payment.getOnCompletion()));
						rows.push(::Legends.EventList.changeRenown(20));
						local f = this.Contract.destFaction();
						if (f != null) f.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Delivered a sealed parcel, unopened");
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_15.png[/img]{Karela slits the wax with a thumbnail and folds back the oilcloth -- and what lies inside stops the whole company short. A cookery book. A fat, dog-eared book of Varisian recipes, the sort that sits on any tavern shelf. He thumbs to a recipe near the back, reads it through once with his lips moving, then closes it and holds it out to you. %SPEECH_ON%My thanks to the venture-captain -- tell him it is read. The book itself I have already; keep it, or leave it.%SPEECH_OFF% He counts out the balance all the same, and a little over for the seal kept whole. Somewhere between two recipes was a single line meant only for him -- and a green lad died in the dark, and good men bled in the warren, to carry a cookbook the man already owned. You take the coin. The book you leave on the counter.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});

				// Break the seal -- the betrayal: refused, keep only the advance, lose standing.
				this.Options.push({
					Text = "{A dead boy died for this. We should know what it is. (break the seal)}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeRenown(-15));
						local f = this.Contract.destFaction();
						if (f != null) f.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Pried open a sealed parcel entrusted to them");
						this.Contract.m.Betrayed = true;
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_15.png[/img]{Somewhere on the road the temptation wins, and you work the wax loose. Inside is -- a cookery book. A dog-eared book of Varisian recipes, and for a breath the whole company just stares at it: this is what the lad died carrying, this is what you bled in the warren for. Only later, turning the pages, does someone catch a recipe near the back that reads a shade wrong -- names where the measures should be, a road folded into the method. A Sczarni cipher, and by now the seal is broken and it is too late to matter. In %SKVLOC%%destinationname%%SKVLOC_OFF% %SKVNAME%Guaril Karela%SKVNAME_OFF% takes one look at the broken wax and will not touch it. %SPEECH_ON%You have opened what was not yours to open. Take your cookbook and go -- and pray Venture-Captain Valsin does not hear you were prying into his affairs.%SPEECH_OFF% You keep the advance, and nothing more, and word of a company that pries travels on ahead of you.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});
			}
		});

		// --- OUTCOME: narrative + the iconed reward list, then finishes.
		this.m.Screens.push({
			ID = "Outcome",
			Title = "The Seal",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{So it is done.}",
					function getResult()
					{
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.OutcomeText != "" ? this.Contract.m.OutcomeText : "{The parcel is delivered, one way or another, and the road goes on.}";
				this.List = this.Contract.m.OutcomeRows != null ? this.Contract.m.OutcomeRows : [];
			}
		});
	}

	// A pit-trap fall: a leg/blunt injury via addInjury (which ALSO deals rand(5,20) HP and
	// floors at 1 -- so NO stacked HP hit, per the guide). Returns the iconed outcome row.
	function trapFall( _name )
	{
		local injured = null;
		foreach (bro in this.World.getPlayerRoster().getAll())
		{
			if (bro.getName() == _name) { injured = bro; break; }
		}
		if (injured == null)
		{
			local roster = this.World.getPlayerRoster().getAll();
			if (roster.len() > 0) injured = roster[this.Math.rand(0, roster.len() - 1)];
		}
		if (injured == null)
		{
			return { id = 10, icon = "ui/icons/health.png", text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]Someone takes a bad fall[/color]" };
		}
		// Fall pool (Const.Injury.Mountains -- the game's own terrain-fall set, as the sled-crash
		// event uses): yields a LEG wound (sprained ankle / broken leg / twisted knee), matching
		// the fiction of a drop into the pit rather than the old PiercingBody torso wound. Name
		// the actual injury on the row when we get one back.
		local inj = injured.addInjury(this.Const.Injury.Mountains);
		local label = injured.getName() + (inj != null ? " -- " + inj.getNameOnly() : " takes a bad fall");
		return {
			id = 10,
			icon = (inj != null ? inj.getIcon() : "ui/icons/health.png"),
			text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + label + "[/color]"
		};
	}

	function onClear()
	{
		::Skv.Once.release("Ambush");   // always free the live-offer slot (any removal)
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Ambush");   // accepted then concluded -> retire for the campaign
			if (!::MSU.isNull(this.m.Site))
			{
				this.m.Site.getSprite("selection").Visible = false;
			}
			if (this.m.Destination != null && !this.m.Destination.isNull())
			{
				this.m.Destination.getSprite("selection").Visible = false;
			}
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onPrepareVariables( _vars )
	{
		local nameColor = "#9dbccb";
		_vars.push(["SKVNAME", "[color=" + nameColor + "]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);

		local locColor = "#b39dbc";
		_vars.push(["SKVLOC", "[color=" + locColor + "]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);

		// The delivery city, for the Task / Delivery text.
		_vars.push(["destinationname", this.m.DestName != "" ? this.m.DestName : "the next town"]);
	}

	function onSerialize( _out )
	{
		if (!::MSU.isNull(this.m.Site)) _out.writeU32(this.m.Site.getID());
		else _out.writeU32(0);

		if (this.m.Destination != null && !this.m.Destination.isNull()) _out.writeU32(this.m.Destination.getID());
		else _out.writeU32(0);
		_out.writeString(this.m.DestName);

		_out.writeU8(this.m.HasPackage ? 1 : 0);
		_out.writeU8(this.m.SiteCleared ? 1 : 0);
		_out.writeU8(this.m.Decided ? 1 : 0);
		_out.writeU8(this.m.Betrayed ? 1 : 0);

		if (this.m.Deck == null) _out.writeU8(0);
		else
		{
			_out.writeU8(this.m.Deck.len());
			foreach (k in this.m.Deck) _out.writeString(k);
		}
		_out.writeU8(this.m.CrawlIndex);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local site = _in.readU32();
		if (site != 0) this.m.Site = this.WeakTableRef(::World.getEntityByID(site));

		local dest = _in.readU32();
		if (dest != 0) this.m.Destination = this.WeakTableRef(::World.getEntityByID(dest));
		this.m.DestName = _in.readString();

		this.m.HasPackage  = _in.readU8() == 1;
		this.m.SiteCleared = _in.readU8() == 1;
		this.m.Decided     = _in.readU8() == 1;
		this.m.Betrayed    = _in.readU8() == 1;

		local dn = _in.readU8();
		if (dn > 0)
		{
			this.m.Deck = [];
			for (local i = 0; i < dn; i = i + 1) this.m.Deck.push(_in.readString());
		}
		this.m.CrawlIndex = _in.readU8();

		this.contract.onDeserialize(_in);
	}

});
