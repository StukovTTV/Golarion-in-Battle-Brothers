// ============================================================================
//  THE CHOKING TOWER -- CONTRACT (Golarion Localization)
//
//  The mod's first fully NON-COMBAT contract. No startScriptedCombat anywhere.
//  A frontier local pays a pittance to have the company go up the soot-black
//  tower in the Smokewood of Numeria -- the sealed sanctum of the technomancer
//  Furkas Xoud of the Technic League, a maker of metal golems -- and find out
//  who is still working in there, because the chimneys have never once gone
//  quiet and the machines still grind. The setup reads as OCCUPIED. The horror,
//  proved only at the top, is that there is no one there at all: only the
//  machine, keeping a dead man's hours because nobody ever told it he was gone.
//
//  STRUCTURE. Offer -> Running. On arrival at the spawned marker the ascent
//  plays out as ONE continuous chain of event screens (Zork-in-a-mercenary-game):
//  each room-card's options return the ID of the next screen. The climb is
//  assembled from a randomized DECK (assembleDeck) of three guaranteed anchors
//  (Entry / NameWard / Top) plus a random middle drawn no-repeat from a pool of
//  path-obstacles and opportunities, so no two campaigns get the same tower.
//
//  RESOLUTION. Every meaningful choice is a ::Skv.Check.resolve against the roster:
//  it finds the best-qualified brother by background, applies HIS OWN traits,
//  perks and injuries, clamps 5-95, rolls d100. Traps draw from two pools
//  (floor/wall vs chest) and wound via addInjury damage-type POOLS + unfloored
//  HP. Smoke is a constant, minor, NEVER-lethal tick. Death is actualized once,
//  by an end-of-crawl SWEEP (proper hedge-knight death sequence) at the top or
//  on abort -- a trap can drive HP <= 0 mid-climb, the sweep is what makes it
//  real. Loot is the whole reward and is ALWAYS named to the player on-screen.
//
//  Every background / trait / injury / item / method path in this file was
//  verified against the Legends 19.4.10 tree and the vanilla decompile. See
//  claude/choking_tower_contracts.md for the full design and the tuning knobs.
// ============================================================================
this.skv_choking_tower_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Destination   = null,   // WeakTableRef to the tower marker
		Deck          = null,   // array of card-key strings, assembled on accept
		Floor         = 0,      // index of the card currently being faced
		KnowsName     = false,  // reading the offer Lore or the Star-Chart sets this; the Name-Ward reads it
		ClimbDone     = false,  // true once the contract has fully finished (report collected, or aborted)
		TowerDone     = false,  // true once the tower is silenced -- objective flips to "carry word back home"
		SmokedFloor   = -1,     // last Floor index that took a smoke tick (once-per-floor guard)
		DoomedCount   = 0,      // how many the sweep took, for the reveal text
		ShutdownClean = false,  // true if the machine was READ silent (chest + fate) vs smashed
		PendingTitle  = "",     // the generic Result screen reads these two
		PendingText   = "",
		LastLoot      = "",     // VESTIGIAL -- loot is now iconed rows (m.Rows via grantHaul); this and %loot% are unused, kept only so old saves deserialize (see onSerialize).
		ActorName     = "",     // whoever last acted -> %actor%
		CardTrap      = null,   // scratch: the trap drawn for the current card (not serialized)
		Rows          = null,   // scratch: outcome rows (damage/injury/death) for the next Result/Reveal screen
		SmokePending  = 0,      // scratch: smoke HP breathed since the last outcome screen, shown then reset
	},

	// ==========================================================================
	//  LOOT -- the tower pool. THIS is the payoff, and it is always NAMED.
	// ==========================================================================
	// entry: { W=weight, T=tier, Path="..." }  OR  { W, T, Gold=[min,max] }
	function towerLoot()
	{
		return [
			// general salvage (T1)
			{ W = 14, T = 1, Path = "scripts/items/shields/heater_shield" },        // metal shield (250)
			{ W = 10, T = 1, Path = "scripts/items/weapons/light_crossbow" },        // the "hand crossbow" (300)
			{ W = 25, T = 1, Gold = [50, 150] },
			// minor valuables (T1)
			{ W = 18, T = 1, Path = "scripts/items/loot/signet_ring_item" },         // his own ring (245)
			{ W = 15, T = 1, Path = "scripts/items/loot/bead_necklace_item" },       // 250
			{ W = 16, T = 1, Path = "scripts/items/loot/silverware_item" },          // 350
			{ W = 12, T = 1, Path = "scripts/items/loot/jade_broche_item" },         // 400
			{ W = 12, T = 1, Path = "scripts/items/loot/silver_bowl_item" },         // 490
			{ W = 12, T = 1, Path = "scripts/items/loot/ancient_amber_item" },       // 500
			{ W = 10, T = 1, Path = "scripts/items/loot/glittering_rock_item" },     // reflavour: raw noqual (500)
			// better finds (T2)
			{ W = 12, T = 2, Path = "scripts/items/misc/legend_masterwork_tools" },  // Masterwork Tools (750)
			{ W = 15, T = 2, Gold = [150, 400] },
			{ W = 10, T = 2, Path = "scripts/items/loot/ornate_tome_item" },         // his lesser writings (595)
			{ W = 8,  T = 2, Path = "scripts/items/loot/marble_bust_item" },         // 600
			{ W = 6,  T = 2, Path = "scripts/items/loot/golden_chalice_item" },      // 980
			// the prizes (T3)
			{ W = 8,  T = 3, Gold = [400, 900] },
			{ W = 8,  T = 3, Path = "scripts/items/loot/ancient_gold_coins_item" },  // 875
			{ W = 4,  T = 3, Path = "scripts/items/loot/gemstones_item" },           // 1120
			{ W = 2,  T = 3, Path = "scripts/items/loot/jeweled_crown_item" },       // 1260
		];
	}

	// His own alchemy, left on the bench -- pulled by the Gas-Store card.
	function towerAlchemicals()
	{
		return [
			"scripts/items/tools/acid_flask_item",   // 400
			"scripts/items/tools/smoke_bomb_item",   // 400
			"scripts/items/tools/daze_bomb_item",    // 500
			"scripts/items/tools/fire_bomb_item",    // 600 (weapon.fire_bomb)
		];
	}

	// Roll n entries (tier <= maxTier) + a guaranteed base of coin, and RETURN
	// { paths, coin } for grantHaul to grant + render as Legends' iconed reward rows.
	// No granting here -- the caller assembles any extra salvage/alchemical paths and
	// calls grantHaul once, so a mixed haul is one grant and one grouped icon list.
	function rollTowerLoot( _n, _maxTier )
	{
		local paths = [];
		local coin = 0;
		local table = this.towerLoot();
		for( local i = 0; i < _n; i = i + 1 )
		{
			local pool = [];
			local total = 0;
			foreach( e in table )
			{
				if (e.T <= _maxTier)
				{
					pool.push(e);
					total = total + e.W;
				}
			}
			if (total <= 0)
			{
				break;
			}
			local r = this.Math.rand(1, total);
			local pick = null;
			foreach( e in pool )
			{
				r = r - e.W;
				if (r <= 0)
				{
					pick = e;
					break;
				}
			}
			if (pick == null)
			{
				continue;
			}
			if ("Gold" in pick) coin = coin + this.Math.rand(pick.Gold[0], pick.Gold[1]);
			else paths.push(pick.Path);
		}
		// GUARANTEED base coin on every haul, scaled by how much and how deep it was --
		// the plunder IS the reward, so no loot event ever comes up empty of coin.
		for( local i = 0; i < _n; i = i + 1 ) coin = coin + this.Math.rand(15, 40) * _maxTier;
		return { paths = paths, coin = coin };
	}

	// Grant an assembled haul (item paths + coin) as iconed reward rows on the outcome
	// screen -- items to the stash with their icons + amounts, coin as its own row.
	function grantHaul( _paths, _coin )
	{
		this.pushRows(::Skv.Loot.haul(::Skv.Loot.make(_paths), _coin));
	}

	// Append pre-built List rows (e.g. from ::Skv.Loot.haul) to the pending outcome list.
	function pushRows( _rows )
	{
		if (this.m.Rows == null) this.m.Rows = [];
		foreach( r in _rows ) this.m.Rows.push(r);
	}

	// grantItem, color and lootLine now live in ::Skv.Loot (skv_engine.nut). One random
	// workshop alchemical PATH (the Tower's own pool) -- grantHaul grants + renders it.
	function pickAlchemical()
	{
		local paths = this.towerAlchemicals();
		return paths[this.Math.rand(0, paths.len() - 1)];
	}

	// (loot line + colour helpers moved to ::Skv.Loot -- see skv_engine.nut)

	// ==========================================================================
	//  TRAPS -- two pools, drawn by WHERE the trap sits. Both pools skew magical/
	//  tech, as a technomancer's sanctum should.
	//
	//  DAMAGE MODEL (see applyTrap): Pool != null -> the wound is the engine's own
	//  addInjury (injury + ~5-20 HP, floored at 1) -- survivable, so `Hp` here is
	//  IGNORED for those. Pool == null -> a direct `Hp` hit; `Floored` ones can
	//  never kill (gas/daze woosiness), un-floored ones (the electrical SHOCKS) are
	//  the rare lethal hazards that feed the end-of-crawl sweep.
	// ==========================================================================
	function floorTraps()
	{
		return [
			{ Name = "a battery of iron bolts",         Pool = this.Const.Injury.Archery,      Hp = [8, 16], Salvage = "scripts/items/ammo/quiver_of_bolts",       Alert = false },
			{ Name = "a spring-driven spear",           Pool = this.Const.Injury.PiercingBody, Hp = [10, 18], Salvage = null,                                     Alert = false },
			{ Name = "a wall-scythe on a cable",        Pool = this.Const.Injury.CuttingBody,  Hp = [10, 18], Salvage = null,                                     Alert = false },
			{ Name = "a counterweighted falling block", Pool = this.Const.Injury.BluntHead,    Hp = [8, 16], Salvage = null,                                      Alert = false },
			{ Name = "a floor plated in live skymetal", Pool = null,                           Hp = [6, 13], Salvage = "scripts/items/loot/glittering_rock_item", Alert = false }, // SHOCK: unfloored, lethal-capable
			{ Name = "a venting of pale gas",           Pool = null,                           Hp = [3, 7],  Salvage = "scripts/items/tools/daze_bomb_item",      Alert = false, Floored = true }, // gas: minor, never kills
		];
	}

	function chestTraps()
	{
		return [
			{ Name = "a poisoned needle",             Pool = this.Const.Injury.PiercingBody, Hp = [4, 9],  Salvage = null,                                       Alert = false },
			{ Name = "a spring-blade set in the lid", Pool = this.Const.Injury.CuttingBody,  Hp = [6, 12], Salvage = null,                                       Alert = false },
			{ Name = "a fire glyph",                  Pool = this.Const.Injury.Burning,      Hp = [8, 15], Salvage = "scripts/items/tools/fire_bomb_item",       Alert = false },
			{ Name = "a rigged phial of acid",        Pool = this.Const.Injury.Burning,      Hp = [8, 15], Salvage = "scripts/items/tools/acid_flask_item",      Alert = false },
			{ Name = "a puffer of grey dust",         Pool = null,                           Hp = [3, 7],  Salvage = "scripts/items/tools/daze_bomb_item",       Alert = false, Floored = true }, // daze: minor, never kills
			{ Name = "a shock-ward wired to a bell",  Pool = null,                           Hp = [6, 12], Salvage = "scripts/items/loot/glittering_rock_item",  Alert = true  }, // SHOCK: unfloored, lethal-capable
		];
	}

	function drawTrap( _isChest )
	{
		local pool = _isChest ? this.chestTraps() : this.floorTraps();
		return pool[this.Math.rand(0, pool.len() - 1)];
	}

	// Apply a trap to an actor (the disarmer/dodger/opener). If none qualified,
	// a random brother eats it.
	//
	// CRITICAL, LEARNED THE HARD WAY: player.addInjury (player.nut:2206) is NOT just an
	// injury -- it ALSO deals its own this.Math.rand(5, 20) HP loss and FLOORS the result
	// at 1. So a trap that inflicts an injury already carries a full ~5-20 HP wound. The
	// first build applied _trap.Hp ON TOP of that, double-counting (a fire glyph did ~35 HP,
	// not ~12, and nearly killed a fresh recruit in one hit). The model now:
	//   - Injury traps (Pool != null): addInjury IS the entire wound -- injury + ~5-20 HP,
	//     floored at 1 by the engine. Injuries MAIM but are survivable; they do not kill.
	//     A `before <= 0` guard stops an injury from REVIVING a brother a hazard already doomed.
	//   - HP-only hazards (Pool == null): a direct hit of _trap.Hp. If `Floored`, it can never
	//     kill (minor mishaps: a forced door, a fright, gas/daze woosiness). If NOT floored
	//     (the electrical shocks), it is UNFLOORED and can drive HP <= 0 -- the rare lethal
	//     backstop the end-of-crawl sweep turns into a death.
	function applyTrap( _actor, _trap )
	{
		local bro = _actor;
		if (bro == null)
		{
			local all = this.World.getPlayerRoster().getAll();
			if (all.len() > 0)
			{
				bro = all[this.Math.rand(0, all.len() - 1)];
			}
		}
		if (bro == null)
		{
			return;
		}
		this.m.ActorName = bro.getName();

		if (_trap.Pool != null)
		{
			local before = bro.getHitpoints();
			local injury = bro.addInjury(_trap.Pool);         // injury + engine's rand(5,20) HP, floored >= 1
			if (before <= 0)
			{
				bro.setHitpoints(before);                     // never let an injury revive an already-doomed brother
			}
			local lost = before - bro.getHitpoints();
			if (lost > 0)
			{
				this.pushRow("ui/icons/health.png", this.m.ActorName + " loses " + lost + " health");
			}
			if (injury != null)
			{
				this.pushRow(injury.getIcon(), this.m.ActorName + " suffers " + injury.getNameOnly());
			}
			this.logInfo("CT trap '" + _trap.Name + "' maimed " + this.m.ActorName + " (-" + lost + " HP)" + (_trap.Alert ? " (ALERT)" : ""));
		}
		else
		{
			local cur = bro.getHitpoints();
			local dmg = this.Math.rand(_trap.Hp[0], _trap.Hp[1]);
			local hp = cur - dmg;
			if (("Floored" in _trap) && _trap.Floored && cur > 0 && hp < 1)
			{
				hp = 1;                                       // minor mishaps never kill
			}
			bro.setHitpoints(hp);
			local lost = cur - hp;
			if (lost > 0)
			{
				this.pushRow("ui/icons/health.png", this.m.ActorName + " loses " + lost + " health");
			}
			this.logInfo("CT trap '" + _trap.Name + "' hit " + this.m.ActorName + " for " + dmg + (_trap.Alert ? " (ALERT)" : ""));
		}
	}

	// Outcome rows -- the icon+text list the Result / Reveal screens show below their
	// text, so trap damage, injuries and deaths are VISIBLE (contract screens render
	// m.ActiveScreen.List via getUIList, exactly as events do). pushRow appends a row;
	// showRows flushes the pending smoke + rows onto a screen and clears them.
	function pushRow( _icon, _text )
	{
		if (this.m.Rows == null)
		{
			this.m.Rows = [];
		}
		this.m.Rows.push({ id = 11, icon = _icon, text = _text });
	}

	// Put every outcome onto a screen's List so it is VISIBLE: the choking smoke breathed
	// since the last outcome screen (accumulated in SmokePending across any skipped rooms),
	// then the trap damage / injuries / deaths (m.Rows). Both are reset once shown. Called
	// by the Result and Reveal screens -- the two places the player pauses to read outcomes.
	function showRows( _screen )
	{
		if (this.m.SmokePending > 0)
		{
			_screen.List.push({ id = 10, icon = "ui/icons/health.png", text = "The choking smoke costs the company " + this.m.SmokePending + " health" });
			this.m.SmokePending = 0;
		}
		if (this.m.Rows != null)
		{
			foreach( r in this.m.Rows )
			{
				_screen.List.push(r);
			}
			this.m.Rows = [];
		}
	}

	// ==========================================================================
	//  SMOKE -- constant, minor, NEVER lethal. Once per floor. Flooring at 1
	//  means smoke cannot kill and, crucially, cannot heal a brother a trap has
	//  already driven to <= 0 (we skip the already-doomed).
	// ==========================================================================
	function tickSmoke()
	{
		if (this.m.Floor == this.m.SmokedFloor)
		{
			return;   // already smoked this floor (a resume) -- SmokePending keeps its running total
		}
		this.m.SmokedFloor = this.m.Floor;
		this.m.SmokePending = this.m.SmokePending + this.breatheSmoke(0);   // accrue until the next outcome screen shows it
	}

	// The extra lungful the "long way round" / gas rooms cost, bypassing the
	// once-per-floor guard. Folds into the same pending total.
	function tickSmokeExtra()
	{
		this.m.SmokePending = this.m.SmokePending + this.breatheSmoke(1);
	}

	function breatheSmoke( _bonus )
	{
		local total = 0;
		foreach( bro in this.World.getPlayerRoster().getAll() )
		{
			if (bro.getSkills().hasSkill("trait.iron_lungs"))
			{
				continue;
			}
			local cur = bro.getHitpoints();
			if (cur <= 0)
			{
				continue;                                     // already doomed by a trap; smoke neither hurts nor heals
			}
			local dmg = this.Math.rand(0, 2) + _bonus;
			if (bro.getSkills().hasSkill("trait.athletic") || bro.getSkills().hasSkill("trait.tough"))
			{
				dmg = this.Math.max(0, dmg - 1);
			}
			if (bro.getSkills().hasSkill("trait.asthmatic") || bro.getSkills().hasSkill("trait.ailing") || bro.getSkills().hasSkill("trait.fat"))
			{
				dmg = dmg + 1;
			}
			if (dmg <= 0)
			{
				continue;
			}
			local hp = cur - dmg;
			if (hp < 1)
			{
				hp = 1;                                       // smoke NEVER kills
			}
			bro.setHitpoints(hp);
			total = total + (cur - hp);
		}
		this.logInfo("CT smoke floor " + this.m.Floor + (_bonus > 0 ? " (heavy)" : "") + ": -" + total + " HP across the company");
		return total;
	}

	// ==========================================================================
	//  THE SKILL-CHECK ENGINE. Finds the best-qualified brother, applies HIS OWN
	//  traits/perks/injuries, clamps 5-95, rolls, logs. Stores the actor's name
	//  for %actor%.
	// ==========================================================================
	// resolveCheck + the injury sets now live in ::Skv.Check (skv_engine.nut) -- shared,
	// same behaviour (sets this.m.ActorName for %actor%). The named checks below keep the
	// tower's own background ladders and delegate to ::Skv.Check.resolve.

	// On a check SUCCESS, credit XP (::Skv.XP.grant, base 200) and push the "+N Experience"
	// rows onto the pending Result list -- so every Tower check awards XP uniformly, shown on
	// the same Result screen the loot uses. Guarded so a missing XP module can never break a check.
	function checkXP( _r )
	{
		if (_r.ok && _r.actor != null && ("XP" in ::Skv)) this.pushRows(::Skv.XP.grant(_r.actor, 200));
		return _r;
	}

	// The named checks (ladders per the design doc, all IDs verified). Each wraps its resolve in
	// checkXP so a pass awards experience (see checkXP).
	function checkLockpick()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[["background.thief", 80], ["background.legend_lurker", 55], ["background.vagabond", 30], ["background.gambler", 30]],
			["dexterous"], ["clumsy"], [], ::Skv.Check.handInjuries(), 15));
	}
	function checkDisarm()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[["background.poacher", 70], ["background.thief", 60], ["background.hunter", 55], ["background.legend_inventor", 50], ["background.ratcatcher", 40], ["background.assassin", 35]],
			["dexterous", "sure_footing"], ["clumsy"], [], ::Skv.Check.handInjuries(), 20));
	}
	function checkSecretDoors()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[["background.legend_diviner", 90], ["background.historian", 70], ["background.graverobber", 55], ["background.mason", 49], ["background.ratcatcher", 45], ["background.legend_lurker", 37]],
			["eagle_eyes", "bright", "paranoid"], ["short_sighted", "dumb"], [], ::Skv.Check.eyeInjuries(), 15));
	}
	function checkReading()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[["background.historian", 60], ["background.legend_astrologist", 55], ["background.legend_philosopher", 45], ["background.legend_magister", 40]],
			["bright"], ["dumb"], [::Legends.Perk.LegendScholar], [], 5));
	}
	function checkGolem()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[["background.legend_inventor", 65], ["background.historian", 50], ["background.legend_astrologist", 45], ["background.legend_magister", 45], ["background.legend_philosopher", 40]],
			["bright"], ["dumb"], [::Legends.Perk.LegendScholar], [], 20));
	}
	function checkStarChart()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[["background.legend_astrologist", 70], ["background.historian", 55], ["background.legend_diviner", 55], ["background.legend_philosopher", 45], ["background.legend_magister", 40]],
			["bright", "eagle_eyes"], ["dumb"], [::Legends.Perk.LegendScholar], [], 15));
	}
	function checkDodge()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[],
			["quick", "swift", "athletic", "dexterous", "sure_footing"], ["clumsy", "fat", "old", "clubfooted"], [], ::Skv.Check.legInjuries(), 40));
	}
	function checkForce()
	{
		return this.checkXP(::Skv.Check.resolve(this,
			[],
			["athletic", "tough"], ["old", "ailing"], [], [], 60));
	}

	// ==========================================================================
	//  THE DECK. Three guaranteed anchors + a random middle, no repeats. The
	//  ward drops at a random middle slot; if the Star-Chart is drawn it is kept
	//  BEFORE the ward, so it can still serve as the alternate key.
	// ==========================================================================
	function cardKeys()
	{
		// Stable order -- the index is the serialized card id. Append only.
		return ["Entry", "NameWard", "Top", "TrappedPassage", "BarredDoor", "BrokenGantry", "Strongbox", "HiddenVault", "GasStore", "GolemSlab", "StarChart", "EmptyLanding"];
	}
	function cardIndex( _key )
	{
		local keys = this.cardKeys();
		foreach( i, c in keys )
		{
			if (c == _key)
			{
				return i;
			}
		}
		return 0;
	}

	function assembleDeck()
	{
		local pool = ["TrappedPassage", "BarredDoor", "BrokenGantry", "Strongbox", "HiddenVault", "GasStore", "GolemSlab", "StarChart", "EmptyLanding"];
		// Fisher-Yates
		for( local i = pool.len() - 1; i > 0; i = i - 1 )
		{
			local j = this.Math.rand(0, i);
			local tmp = pool[i];
			pool[i] = pool[j];
			pool[j] = tmp;
		}
		local n = this.Math.rand(3, 5);          // middle floor count, INCLUDING the ward
		local take = n - 1;                        // non-ward middle cards
		if (take > pool.len())
		{
			take = pool.len();
		}
		local middle = [];
		for( local i = 0; i < take; i = i + 1 )
		{
			middle.push(pool[i]);
		}
		// keep the Star-Chart before the ward if it was drawn
		local scPos = -1;
		foreach( idx, c in middle )
		{
			if (c == "StarChart")
			{
				scPos = idx;
				break;
			}
		}
		local lo = (scPos >= 0 ? scPos + 1 : 0);
		local wardPos = this.Math.rand(lo, middle.len());
		middle.insert(wardPos, "NameWard");

		local deck = ["Entry"];
		foreach( c in middle )
		{
			deck.push(c);
		}
		deck.push("Top");

		this.m.Deck = deck;
		this.m.Floor = 0;
		this.m.SmokedFloor = -1;

		local s = "";
		foreach( c in deck )
		{
			s = s + c + " ";
		}
		this.logInfo("CT deck (" + deck.len() + " floors): " + s);
	}

	// The current card's screen ID. Ticks smoke once for this floor as a side
	// effect of arriving. Used to START the climb, to RESUME it (on return to the
	// tile), and by the Result screen's climb-on.
	function showFloor()
	{
		if (this.m.Deck == null || this.m.Floor >= this.m.Deck.len())
		{
			return "Top";
		}
		if (this.m.Floor < 0)
		{
			this.m.Floor = 0;
		}
		this.tickSmoke();
		return this.m.Deck[this.m.Floor];
	}

	// ==========================================================================
	//  RESOLUTIONS -- one method per card. Each does its effects, sets the
	//  Pending* text, advances the floor, and hands back the generic "Result"
	//  screen (which shows the text and offers the climb-on). Pass-through
	//  options (leave it / climb on) advance and jump straight to the next card.
	// ==========================================================================
	function resolveEntry( _pick )
	{
		local inClean = false;
		if (_pick)
		{
			inClean = this.checkLockpick().ok;
		}
		if (inClean)
		{
			local h = this.rollTowerLoot(1, 1);
			this.grantHaul(h.paths, h.coin);
			this.m.PendingTitle = "Inside";
			this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{%actor% works the damaged lock until it gives without a sound, and the iron hatch swings inward on a breath of dead, oil-thick air. Just inside, dropped by whoever sealed the place and never carried it out, lies the first of the tower's leavings.}";
		}
		else
		{
			local c = this.checkForce();
			if (!c.ok)
			{
				this.applyTrap(c.actor, { Name = "the hatch's recoil", Pool = null, Hp = [3, 8], Salvage = null, Alert = false, Floored = true });
				this.m.PendingTitle = "Forced";
				this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{Shoulders to the iron. The hatch fights, then gives all at once, and its sprung edge catches %actor% hard on the way through. You are inside -- but nothing was left worth stooping for at a door you had to break.}";
			}
			else
			{
				this.m.PendingTitle = "Forced";
				this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{Shoulders to the iron, and the damaged hatch tears off its last seal and folds inward. You are inside, and none the worse for it -- though the broken door kept nothing worth the stooping.}";
			}
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveWard( _correct )
	{
		if (_correct)
		{
			local h = this.rollTowerLoot(1, 3);
			this.grantHaul(h.paths, h.coin);
			this.m.PendingTitle = "The Ward Yields";
			this.m.PendingText = "[img]gfx/ui/events/legend_vala_inscribes_weapon.png[/img]{The mask hears the name and the blue fire dies in its throat. Somewhere behind the scorched wall a latch lets go, and a niche you had not seen until now gives up what it kept.}";
			this.logInfo("CT ward: correct");
		}
		else
		{
			this.applyTrap(null, { Name = "the ward's fire", Pool = this.Const.Injury.Burning, Hp = [8, 15], Salvage = null, Alert = false });
			this.m.PendingTitle = "Wrong";
			this.m.PendingText = "[img]gfx/ui/events/legend_vala_inscribes_weapon.png[/img]{The mask does not change. Then a lash of blue fire comes off it and takes %actor% across the face and hands before anyone can pull them clear. The wall keeps its secret, and adds a fresh scorch beside all the others.}";
			this.logInfo("CT ward: wrong");
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolvePassage( _disarm )
	{
		local trap = this.m.CardTrap;
		if (_disarm)
		{
			local c = this.checkDisarm();
			if (c.ok)
			{
				this.m.PendingTitle = "Disarmed";
				if (trap.Salvage != null)
				{
					this.grantHaul([trap.Salvage], 0);
					this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{%actor% reads the mechanism the way another man reads a sentence, and stills it. The passage is dead for everyone now -- and out of its works you draw something worth the prising.}";
				}
				else
				{
					this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{%actor% reads the mechanism the way another man reads a sentence, and stills it. The passage is dead for everyone now, and there is nothing in it worth prising loose.}";
				}
			}
			else
			{
				this.applyTrap(c.actor, trap);
				this.m.PendingTitle = "Sprung";
				this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{%actor%'s hands slip on the old works and the whole thing goes off at once. When the noise dies you go up over it fast, before it can be set again.}";
			}
		}
		else
		{
			local c = this.checkDodge();
			if (c.ok)
			{
				this.m.PendingTitle = "Through";
				this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{%actor% times the passage and takes it at a dead run, and it triggers into the empty air behind. You file through after, one at a time, holding your breath.}";
			}
			else
			{
				this.applyTrap(c.actor, trap);
				this.m.PendingTitle = "Caught";
				this.m.PendingText = "[img]gfx/ui/events/event_89.png[/img]{%actor% misjudges it by a heartbeat and the passage takes them square. You drag them up and through, cursing the tower, and go on.}";
			}
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveBarred( _method )
	{
		if (_method == "bypass")
		{
			local c = this.checkSecretDoors();
			if (c.ok)
			{
				local h = this.rollTowerLoot(1, 1);
				this.grantHaul(h.paths, h.coin);
				this.m.PendingTitle = "The Long Way";
				this.m.PendingText = "[img]gfx/ui/events/event_111.png[/img]{%actor% finds the false panel and the service-shaft behind it, and you come up above the barred door without ever touching it. In the shaft, forgotten by whoever built it, lies something left behind.}";
				this.m.Floor = this.m.Floor + 1;
				return "Result";
			}
			_method = "force";
		}
		if (_method == "pick")
		{
			if (this.checkLockpick().ok)
			{
				this.m.PendingTitle = "Opened";
				this.m.PendingText = "[img]gfx/ui/events/event_111.png[/img]{%actor% works the jammed lock until it turns, and the banded door swings wide, quiet as you please.}";
				this.m.Floor = this.m.Floor + 1;
				return "Result";
			}
			_method = "force";
		}
		local c = this.checkForce();
		if (!c.ok)
		{
			this.applyTrap(c.actor, { Name = "the door", Pool = null, Hp = [2, 6], Salvage = null, Alert = false, Floored = true });
		}
		this.m.PendingTitle = "Forced";
		this.m.PendingText = "[img]gfx/ui/events/event_111.png[/img]{The door gives at last with a crash that goes up the tower ahead of you -- and somewhere above, something heavy shifts its weight and begins, unhurried, to come down. You are through. Best not to be here when it arrives.}";
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveGantry( _edge )
	{
		if (_edge)
		{
			local c = this.checkDodge();
			if (c.ok)
			{
				this.m.PendingTitle = "Across";
				this.m.PendingText = "[img]gfx/ui/events/event_167.png[/img]{%actor% goes first, out along the iron spine over the black machine-pit, sure-footed where a slip means the gears. One by one you follow the line they pick, and make the far side.}";
			}
			else
			{
				this.applyTrap(c.actor, { Name = "the fall", Pool = this.Const.Injury.BluntBody, Hp = [6, 13], Salvage = null, Alert = false });
				this.m.PendingTitle = "The Drop";
				this.m.PendingText = "[img]gfx/ui/events/event_167.png[/img]{Halfway out the gantry shifts and %actor% goes down onto the machinery below with a sound you feel in your teeth. You get a rope to them and haul them up, white and shaking, and go on.}";
			}
		}
		else
		{
			this.tickSmokeExtra();
			this.m.PendingTitle = "The Long Way";
			this.m.PendingText = "[img]gfx/ui/events/event_167.png[/img]{You leave the gantry for the low galleries, the long way round, breathing the worst of the smoke where it pools thick and unmoving. It is slower, and it costs your lungs, but every man of you comes up on the far side whole.}";
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveStrongbox()
	{
		local trap = this.m.CardTrap;
		local c = this.checkDisarm();
		if (!c.ok)
		{
			this.applyTrap(c.actor, trap);
			this.m.PendingTitle = "Sprung";
			this.m.PendingText = "[img]gfx/ui/events/event_04.png[/img]{%actor% reaches into the box, and " + trap.Name + " does exactly what it was set to do. You leave the lid shut and your hands to yourselves after that.}";
			this.m.Floor = this.m.Floor + 1;
			return "Result";
		}
		if (trap.Salvage != null) this.grantHaul([trap.Salvage], 0);   // the drawn fangs, kept either way
		if (this.checkLockpick().ok)
		{
			local h = this.rollTowerLoot(1, 2);
			this.grantHaul(h.paths, h.coin);
			this.m.PendingTitle = "Opened";
			this.m.PendingText = "[img]gfx/ui/events/event_04.png[/img]{%actor% draws the box's fangs, then picks the lock beneath them. Packed in oiled cloth inside is what the technomancer thought worth a killing box.}";
		}
		else
		{
			this.m.PendingTitle = "Beaten by the Lock";
			this.m.PendingText = "[img]gfx/ui/events/event_04.png[/img]{%actor% draws the box's fangs -- but the lock beneath will not turn for anyone here, and there is no forcing it without ruining what it guards. You keep the trap's makings; the box keeps its own.}";
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveVault()
	{
		local c = this.checkSecretDoors();
		this.tickSmokeExtra();
		if (c.ok)
		{
			local h = this.rollTowerLoot(this.Math.rand(2, 3), 3);
			this.grantHaul(h.paths, h.coin);
			this.m.PendingTitle = "The Hidden Vault";
			this.m.PendingText = "[img]gfx/ui/events/event_55.png[/img]{%actor% finds the catch in the hollow wall and it grinds back on a technomancer's private store -- the things a man keeps when he trusts no one. You take all of it.}";
		}
		else
		{
			this.m.PendingTitle = "Solid Wall";
			this.m.PendingText = "[img]gfx/ui/events/event_55.png[/img]{The wall rings hollow under a knuckle, but it gives up no seam and no catch that anyone here can find. Whatever waits behind it goes on waiting.}";
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveGasStore()
	{
		local trap = this.m.CardTrap;
		this.tickSmokeExtra();
		local c = this.checkDisarm();
		if (!c.ok)
		{
			this.applyTrap(c.actor, trap);
			this.m.PendingTitle = "Fumes";
			this.m.PendingText = "[img]gfx/ui/events/event_98.png[/img]{The haze makes %actor% slow and clumsy, and the cabinet's " + trap.Name + " catches them before they can pull back. You retreat from the store with streaming eyes and nothing to show for it.}";
			this.m.Floor = this.m.Floor + 1;
			return "Result";
		}
		local h = this.rollTowerLoot(this.Math.rand(1, 2), 1);
		if (trap.Salvage != null) h.paths.push(trap.Salvage);
		h.paths.push(this.pickAlchemical());
		this.grantHaul(h.paths, h.coin);
		this.m.PendingTitle = "Salvage in the Haze";
		this.m.PendingText = "[img]gfx/ui/events/event_98.png[/img]{%actor% clears the cabinet's trap and you strip the store fast, working blind through the fumes, before the air drives you all back out the door. This is what you came away with.}";
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveGolem()
	{
		local c = this.checkGolem();
		if (c.ok)
		{
			this.grantHaul(["scripts/items/loot/glittering_rock_item"], 0);
			this.m.PendingTitle = "The Half-Made Man";
			this.m.PendingText = "[img]gfx/ui/events/event_116.png[/img]{%actor% reads the marks scored around the slab and the thing lying half-finished on it -- iron and brass and pale noqual, a man's height and a man's shape with no face cut yet, and prises loose a fitting of green skymetal. As the hand comes free the whole unfinished thing TWITCHES once on its cradle, and is still. You do not touch it again.}";
		}
		else
		{
			this.applyTrap(c.actor, { Name = "the fright", Pool = null, Hp = [2, 5], Salvage = null, Alert = false, Floored = true });
			this.m.PendingTitle = "It Moved";
			this.m.PendingText = "[img]gfx/ui/events/event_116.png[/img]{No one here can make sense of the marks around the slab. And when %actor% leans in close the half-made thing on it TWITCHES under their hands -- they go over backward hard, and you are all through the door before the echo dies.}";
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	function resolveStarChart()
	{
		local c = this.checkStarChart();
		if (c.ok)
		{
			this.m.KnowsName = true;
			local h = this.rollTowerLoot(1, 1);
			this.grantHaul(h.paths, h.coin);
			this.m.PendingTitle = "The Fall of Stars";
			this.m.PendingText = "[img]gfx/ui/events/legend_stollwurm_hole.png[/img]{%actor% reads the domed ceiling like a page. The charts track the skyfall over Numeria, year upon year -- where the burning green metal came down, and where a man went out to dig it from the crater and did not come back up the same. One mark is circled and circled again, and set under it in a proud hand, over and over, is a name. You will know it now, if the tower asks. Among the instruments you also turn up a thing or two worth the carrying.}";
		}
		else
		{
			this.m.PendingTitle = "Charts and Dust";
			this.m.PendingText = "[img]gfx/ui/events/event_45.png[/img]{The charts of the star-fall mean little to anyone here -- lines and dead reckonings and a language of numbers no one was taught. You leave the domed room no wiser than you came, the circled mark and its name blurring into all the rest.}";
		}
		this.m.Floor = this.m.Floor + 1;
		return "Result";
	}

	// The top. Reading it silences the machine CLEAN (compartment + the fate).
	// A SUCCESSFUL read goes straight to the reveal. A FAILED read does NOT silently
	// become a smash -- it routes through the "CannotRead" beat so the player sees
	// that the script defeated them and CHOOSES to put an axe to the panel. Smashing
	// (from the Top or from CannotRead) is crude, always works, no chest, no answer.
	function resolveTopRead()
	{
		if (this.checkReading().ok)
		{
			this.m.ShutdownClean = true;
			local h = this.rollTowerLoot(this.Math.rand(2, 3), 3);
			this.grantHaul(h.paths, h.coin);
			this.m.DoomedCount = this.deathSweep();
			return "Reveal";
		}
		return "CannotRead";
	}

	function resolveTopSmash()
	{
		this.m.ShutdownClean = false;
		this.m.DoomedCount = this.deathSweep();
		return "Reveal";
	}

	// ==========================================================================
	//  THE SWEEP. Everyone the tower drove to <= 0 dies here, properly -- the
	//  hedge-knight sequence (obituary, gear to stash, mourning), not a bare
	//  remove() that would only vanish them. Run at the top AND on abort.
	// ==========================================================================
	function deathSweep()
	{
		local doomed = [];
		foreach( bro in this.World.getPlayerRoster().getAll() )
		{
			if (bro.getHitpoints() <= 0)
			{
				doomed.push(bro);
			}
		}
		foreach( bro in doomed )
		{
			local fallen = {
				Name = bro.getName(),
				Time = this.World.getTime().Days,
				TimeWithCompany = this.Math.max(1, bro.getDaysWithCompany()),
				Kills = bro.getLifetimeStats().Kills,
				Battles = bro.getLifetimeStats().Battles,
				KilledBy = "Fell in the Choking Tower",
				Expendable = false
			};
			this.World.Statistics.addFallen(fallen);
			bro.getItems().transferToStash(this.World.Assets.getStash());
			bro.getSkills().onDeath(this.Const.FatalityType.None);
			this.World.getPlayerRoster().remove(bro);
			this.pushRow("ui/icons/kills.png", fallen.Name + " did not leave the tower");
			this.logInfo("CT sweep: " + fallen.Name + " fell in the tower");
		}
		return doomed.len();
	}

	function despawnSite()
	{
		if (this.m.Destination != null && !::MSU.isNull(this.m.Destination))
		{
			this.m.Destination.die();
			this.m.Destination = null;
		}
	}

	// ==========================================================================
	//  CONTRACT BOILERPLATE
	// ==========================================================================
	function create()
	{
		this.contract.create();
		this.m.Rows = [];   // init here, not as an m-table default, so instances never share one array
		this.m.Type = "contract.skv_choking_tower";
		this.m.Name = "The Choking Tower";
		// Long window: the tower is a genuine trek into the deep wood (6-12 tiles) AND
		// the word must be carried back, so the company makes that distance TWICE.
		// 35 days keeps a slow company from timing out on the return leg.
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 35.0;
		this.m.Category = this.Const.Contracts.Categories.Economy;
		this.m.DescriptionTemplates = [
			"A frontier local wants someone to go up to the old tower in the deep wood -- the soot-black one whose chimneys never stop smoking -- and find out who is still working in there. Small pay, for a look.",
			"There is a sealed tower out in the Smokewood, shut up years ago, and the machines inside it have never once fallen quiet. A villager will pay a little to have the company go and see who is still home.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		// 1 skull, capped. The 0.70-0.82 band shows a single skull and keeps the
		// fee small via DIFF^POW. The low rating is an honest read of the COMBAT
		// axis (there is none) and a deliberate undersell of the tower's real
		// danger, exactly as the poor employer undersells it.
		this.m.DifficultyMult = this.Math.rand(70, 82) * 0.01;

		local wealth = 1.0;
		if (this.m.Home != null && !this.m.Home.isNull())
		{
			local v = this.m.Home;
			local baseline = v.getSize() == 3 ? 200.0 : (v.getSize() == 2 ? 150.0 : 100.0);
			wealth = this.Math.maxf(0.6, this.Math.minf(1.1, v.getResources().tofloat() / baseline));
		}

		// Small base (250). The reward is the tower's plunder, not the purse.
		this.m.Payment.Pool = 250 * wealth * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		// A token retainer up front (paid in Offer.end); the rest on completion.
		// The floor that makes "turn back" fair is the BANKED LOOT, not the advance.
		this.m.Payment.Advance = 0.2;
		this.m.Payment.Completion = 0.8;

		this.contract.start();
	}

	// A free forest tile 6-12 tiles out -- Xoud sealed himself deep in the wood.
	function pickSiteTile()
	{
		local candidates = this.m.Home.getSurroundingTilesOfType([
			this.Const.World.TerrainType.Forest,
			this.Const.World.TerrainType.LeaveForest,
			this.Const.World.TerrainType.AutumnForest
		], 12);
		local valid = [];
		foreach( t in candidates )
		{
			if (!t.IsOccupied && this.m.Home.getTile().getDistanceTo(t) >= 6)
			{
				valid.push(t);
			}
		}
		if (valid.len() == 0)
		{
			return null;
		}
		return valid[this.Math.rand(0, valid.len() - 1)];
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Find the smoking tower in the wood near " + this.Contract.m.Home.getName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				// The token retainer. The live-offer slot was claimed at generation and is
				// freed in onClear; the PERMANENT retire happens only when an accepted
				// contract concludes -- handled in onClear via m.IsActive, not here.
				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());

				local tile = this.Contract.pickSiteTile();
				if (tile == null)
				{
					local excluded = this.Const.World.getAllTerrainTypesExcept([
						this.Const.World.TerrainType.Forest,
						this.Const.World.TerrainType.LeaveForest,
						this.Const.World.TerrainType.AutumnForest
					]);
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 6, 12, excluded, false);
				}

				tile.clear();
				// No combat: a marker we resolve entirely through the screen chain.
				// Reuse undead_ruins as the black_forks / skulls_crossing contracts do.
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/undead_ruins_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setName("The Choking Tower");
				this.Contract.m.Destination.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID());
				this.Contract.m.Destination.setBanner(this.World.FactionManager.getFaction(this.Const.FactionType.Bandits).getPartyBanner());
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);

				this.Contract.assembleDeck();

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				// Two legs: climb the tower, then carry the word back to the village.
				if (this.Contract.m.TowerDone)
				{
					this.Contract.m.BulletpointsObjectives = [
						"Carry word back to " + this.Contract.m.Home.getName()
					];
					if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
					{
						this.Contract.m.Home.getSprite("selection").Visible = true;
					}
				}
				else
				{
					this.Contract.m.BulletpointsObjectives = [
						"Climb the Choking Tower"
					];
					if (this.Contract.m.Destination != null && !::MSU.isNull(this.Contract.m.Destination))
					{
						this.Contract.m.Destination.getSprite("selection").Visible = true;
					}
				}
			}

			function update()
			{
				// LEG 2 -- the tower is silenced; carry the word home for pay. Checked
				// BEFORE the destination guard because the site is despawned by now.
				if (this.Contract.m.TowerDone)
				{
					if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
					{
						if (this.Contract.isPlayerAt(this.Contract.m.Home))
						{
							if (!this.TempFlags.get("AtHome"))
							{
								this.TempFlags.set("AtHome", true);
								this.Contract.setScreen("Report");
								this.World.Contracts.showActiveContract();
							}
						}
						else
						{
							this.TempFlags.set("AtHome", false);
						}
					}
					return;
				}

				// LEG 1 -- the climb. update() only STARTS it on arrival and RESUMES it
				// if the player wandered off the tile and came back.
				if (::MSU.isNull(this.Contract.m.Destination))
				{
					return;
				}
				if (this.Contract.m.ClimbDone)
				{
					return;
				}
				if (this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						this.Contract.setScreen(this.Contract.showFloor());
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtSite", false);
				}
			}
		});
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		// ---- OFFER: Task ------------------------------------------------------
		this.m.Screens.push({
			ID = "Task",
			Title = "The Choking Tower",
			Text = "[img]gfx/ui/events/event_20.png[/img]{%employer% keeps his voice down, the way a man does when he would rather not be overheard wanting a thing done. %SPEECH_ON%There is a tower out in the deep wood -- black as a burnt pot, and taller than anything has a right to be. A man shut himself up in it before my father's time and was never seen to come out. Folk hoped he had died in there.%SPEECH_OFF%He turns his cup and does not drink from it. %SPEECH_ON%But the chimneys smoke. Every day, all these years, the smoke goes up, and if you stand near enough of a still night you can hear it working in there -- grinding, always grinding. Somebody is home, or something is, and the smoke is drifting our way and folk are frightened. Go up and see who keeps those fires. I have not got much, but I will pay you to bring back word.%SPEECH_OFF%He leans in, lower still. %SPEECH_ON%And whatever you drag out of that place -- coin, curios, the dead man's leavings -- it is yours. Every crown of it. I want none of it in my house, and no one hereabouts will say a word against your keeping it. Just bring me the word, and stop that smoke if you can.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We will go and see who is home.}",
						function getResult()
						{
							return "Negotiation";
						}
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{A tower in the wood. Does anyone know this place?}",
						function getResult()
						{
							return "Lore";
						}
					});
				}

				this.Options.push({
					Text = "{We will leave your tower to itself.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);   // pre-accept decline -> NOT retired (can re-offer)
						return 0;
					}
				});
			}
		});

		// ---- OFFER: Lore -- accurate Numeria, and it NAMES him (sets KnowsName,
		// which the Name-Ward reads as the key). Two-brother conversation.
		this.m.Screens.push({
			ID = "Lore",
			Title = "The Choking Tower",
			Text = "[img]gfx/ui/events/event_23.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% answers slowly, like a man who would rather not. %SPEECH_ON%I know the country. That is %SKVLOC%Numeria%SKVLOC_OFF% -- where the stars fall. Great burning things come down out of the sky there and bury themselves in the ground, and the metal in them is like no metal a smith ever saw. Green stuff, they call noqual. There are men who spend their whole lives digging it out and learning what it wants to do.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% has stopped pretending not to listen. %SPEECH_ON%The %SKVLOC%Technic League%SKVLOC_OFF%. They keep it all for themselves and they answer to no lord. And the one who raised that tower was one of theirs -- a maker of golems, iron men that walk and work and have no soul in them. %SKVNAME%Furkas Xoud%SKVNAME_OFF%, his name was. They say he built one out of skyfall metal itself, and that after that he wanted no eyes on him, so he shut himself in the wood and sealed the door.%SPEECH_OFF%%SKVNAME%%randombrother%%SKVNAME_OFF% nods, once. %SPEECH_ON%Most reckon he is long dead in there. But nobody knows it. And an iron man does not need its master alive to keep working.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Let us hear the terms.}",
					function getResult()
					{
						return "Task";
					}
				}
			],
			function start()
			{
				// Reading the lore IS knowing the name. The ward becomes answerable.
				this.Contract.m.KnowsName = true;
			}
		});

		// ---- ANCHOR: Entry ----------------------------------------------------
		this.m.Screens.push({
			ID = "Entry",
			Title = "The Iron Hatch",
			Text = "[img]gfx/ui/events/event_108.png[/img]{The wood thins, and the tower is simply there -- sixty feet of soot-black stone streaked green where the skyfall metal has bled down it, windows no wider than arrow-slits, smoke standing straight up from its crown into the dead air. At its foot is a single iron hatch, damaged, sealed, with no handle and no hinge that shows. Behind it, felt more than heard, something turns over and over and does not stop. There is no other way in.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Pick the lock -- get in clean.}",
					function getResult()
					{
						return this.Contract.resolveEntry(true);
					}
				},
				{
					Text = "{Force it.}",
					function getResult()
					{
						return this.Contract.resolveEntry(false);
					}
				},
				{
					Text = "{Turn back -- leave the tower sealed.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- ANCHOR: Name-Ward ------------------------------------------------
		this.m.Screens.push({
			ID = "NameWard",
			Title = "Name Your Master",
			Text = "[img]gfx/ui/events/legend_vala_inscribes_weapon.png[/img]{The stair opens onto a landing barred by a mask of pale green noqual set into the wall, mouth open on a dark throat. Cut deep around it, in a script that somehow you can read, are the words NAME YOUR MASTER. The stone on either side is scorched black in long lashes, layer on layer -- the marks of everyone who answered wrong, and there were many.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local correctLabel = "{\"Furkas Xoud.\"}";
				if (this.Contract.m.KnowsName)
				{
					correctLabel = "{\"Furkas Xoud.\" (the name your company carried up)}";
				}
				this.Options = [
					{
						Text = correctLabel,
						function getResult()
						{
							return this.Contract.resolveWard(true);
						}
					},
					{
						Text = "{\"Zoresk Var.\"}",
						function getResult()
						{
							return this.Contract.resolveWard(false);
						}
					},
					{
						Text = "{\"Kazallin the Grey.\"}",
						function getResult()
						{
							return this.Contract.resolveWard(false);
						}
					},
					{
						Text = "{\"Marduzi Xelt.\"}",
						function getResult()
						{
							return this.Contract.resolveWard(false);
						}
					},
					{
						Text = "{Leave the ward be -- climb past it.}",
						function getResult()
						{
							this.Contract.m.Floor = this.Contract.m.Floor + 1;
							return this.Contract.showFloor();
						}
					},
					{
						Text = "{Turn back -- climb down.}",
						function getResult()
						{
							return "Aborted";
						}
					}
				];
			}
		});

		// ---- PATH: Trapped Passage (draws a floor/wall trap) ------------------
		this.m.Screens.push({
			ID = "TrappedPassage",
			Title = "A Trapped Passage",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Disarm it.}",
					function getResult()
					{
						return this.Contract.resolvePassage(true);
					}
				},
				{
					Text = "{Run it -- time it and go.}",
					function getResult()
					{
						return this.Contract.resolvePassage(false);
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start()
			{
				this.Contract.m.CardTrap = this.Contract.drawTrap(false);
				this.Text = "[img]gfx/ui/events/event_89.png[/img]{The stair narrows into a passage the tower has made unfriendly. Worked into the walls and floor is " + this.Contract.m.CardTrap.Name + ", cocked and patient and plainly meant for anyone who climbs. There is no other way up.}";
			}
		});

		// ---- PATH: Barred Door ------------------------------------------------
		this.m.Screens.push({
			ID = "BarredDoor",
			Title = "The Barred Door",
			Text = "[img]gfx/ui/events/event_111.png[/img]{The way up is shut by a door of banded iron, jammed hard from the inside -- barred, or rusted, or both. It does not give to a shoulder tried once, in passing. Getting past it will take doing.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Pick the lock.}",
					function getResult()
					{
						return this.Contract.resolveBarred("pick");
					}
				},
				{
					Text = "{Force it.}",
					function getResult()
					{
						return this.Contract.resolveBarred("force");
					}
				},
				{
					Text = "{Find another way around.}",
					function getResult()
					{
						return this.Contract.resolveBarred("bypass");
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- PATH: Broken Gantry ----------------------------------------------
		this.m.Screens.push({
			ID = "BrokenGantry",
			Title = "The Broken Gantry",
			Text = "[img]gfx/ui/events/event_167.png[/img]{The stair gives out over a pit of grinding machinery, and the only way across is a spine of iron gantry bridging the dark -- buckled in the middle, missing plates, groaning when the works below shudder. Or there is the long way, down through the low galleries where the smoke lies thickest, and up again on the far side.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Edge across the gantry.}",
					function getResult()
					{
						return this.Contract.resolveGantry(true);
					}
				},
				{
					Text = "{Take the long way round.}",
					function getResult()
					{
						return this.Contract.resolveGantry(false);
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- OPPORTUNITY: Trapped Strongbox (draws a chest trap) --------------
		this.m.Screens.push({
			ID = "Strongbox",
			Title = "The Trapped Strongbox",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Try it -- draw the trap, then the lock.}",
					function getResult()
					{
						return this.Contract.resolveStrongbox();
					}
				},
				{
					Text = "{Leave it alone.}",
					function getResult()
					{
						this.Contract.m.Floor = this.Contract.m.Floor + 1;
						return this.Contract.showFloor();
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start()
			{
				this.Contract.m.CardTrap = this.Contract.drawTrap(true);
				this.Text = "[img]gfx/ui/events/event_04.png[/img]{Set into an alcove off the stair is a strongbox of black iron, locked, and worked over with " + this.Contract.m.CardTrap.Name + " for the unwary. Whatever a man like that thought worth this much trouble is still inside it.}";
			}
		});

		// ---- OPPORTUNITY: Hidden Vault ----------------------------------------
		this.m.Screens.push({
			ID = "HiddenVault",
			Title = "The Hidden Vault",
			Text = "[img]gfx/ui/events/event_55.png[/img]{A stretch of wall here rings hollow under a knuckle -- there is a space behind it, and no honest reason for one. Finding the way in will mean reading the stone closely, in air that does not reward standing still.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Search for the way in.}",
					function getResult()
					{
						return this.Contract.resolveVault();
					}
				},
				{
					Text = "{Don't bother -- climb on.}",
					function getResult()
					{
						this.Contract.m.Floor = this.Contract.m.Floor + 1;
						return this.Contract.showFloor();
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- OPPORTUNITY: Gas-Flooded Store (draws a chest trap) --------------
		this.m.Screens.push({
			ID = "GasStore",
			Title = "The Gas-Flooded Store",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Brave the fumes and strip it.}",
					function getResult()
					{
						return this.Contract.resolveGasStore();
					}
				},
				{
					Text = "{Seal it off and climb on.}",
					function getResult()
					{
						this.Contract.m.Floor = this.Contract.m.Floor + 1;
						return this.Contract.showFloor();
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start()
			{
				this.Contract.m.CardTrap = this.Contract.drawTrap(true);
				this.Text = "[img]gfx/ui/events/event_98.png[/img]{A store-room off the stair, hazed to the knees in something heavier than the tower's smoke and sharp in the throat. Shelves of salvage stand ranked in the murk, and a cabinet at the back is fitted with " + this.Contract.m.CardTrap.Name + ". Anything taken here is taken fast, or not at all.}";
			}
		});

		// ---- OPPORTUNITY: The Golem on the Slab -------------------------------
		this.m.Screens.push({
			ID = "GolemSlab",
			Title = "The Golem on the Slab",
			Text = "[img]gfx/ui/events/event_116.png[/img]{A workshop, and on its central slab a golem half made -- iron and brass and pale green noqual, a man's height and a man's shape, its face not yet cut. Tools lie where a hand set them down mid-task, years ago. It is wired into the same pulse that beats through the whole tower, and now and then, very slightly, it seems to breathe.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Examine it.}",
					function getResult()
					{
						return this.Contract.resolveGolem();
					}
				},
				{
					Text = "{Leave it be.}",
					function getResult()
					{
						this.Contract.m.Floor = this.Contract.m.Floor + 1;
						return this.Contract.showFloor();
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- OPPORTUNITY: The Star-Chart --------------------------------------
		this.m.Screens.push({
			ID = "StarChart",
			Title = "The Star-Chart",
			Text = "[img]gfx/ui/events/event_45.png[/img]{A domed room, its ceiling one great chart of the sky and the falling of stars over Numeria, worked in silver and dark glass. Instruments stand about under a film of dust. One point on the dome is marked, and marked again, and circled until the metal is worn -- and there is writing under it, in a proud and careful hand.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Study the charts.}",
					function getResult()
					{
						return this.Contract.resolveStarChart();
					}
				},
				{
					Text = "{Leave it -- climb on.}",
					function getResult()
					{
						this.Contract.m.Floor = this.Contract.m.Floor + 1;
						return this.Contract.showFloor();
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- BREATHER: The Empty Landing --------------------------------------
		this.m.Screens.push({
			ID = "EmptyLanding",
			Title = "An Empty Landing",
			Text = "[img]gfx/ui/events/event_89.png[/img]{A bare landing. Nothing here -- no machine, no door of note, no reason for the room at all. Only the smoke, and the grinding going on above and below, and, on the stair beneath you, a slow dragging tread that was not there when you started up, and is nearer now than it was.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Climb on.}",
					function getResult()
					{
						this.Contract.m.Floor = this.Contract.m.Floor + 1;
						return this.Contract.showFloor();
					}
				},
				{
					Text = "{Turn back -- climb down.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- ANCHOR: The Top --------------------------------------------------
		this.m.Screens.push({
			ID = "Top",
			Title = "Xoud's Study",
			Text = "[img]gfx/ui/events/event_63.png[/img]{The stair ends in a round crown room, and you come into it braced for the master of the tower. A cot, long cold. A dead hearth. A desk buried in instruments and in pages of urgent notes, written in a script no one here was raised to read. And along one wall a panel of levers and lit glass, wired into all that grinding below. On the stair beneath you the dragging tread has stopped climbing. It is simply waiting, just out of sight, as if it too wants to see how this ends.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Read the notes -- shut it down properly.}",
					function getResult()
					{
						return this.Contract.resolveTopRead();
					}
				},
				{
					Text = "{Smash the panel.}",
					function getResult()
					{
						return this.Contract.resolveTopSmash();
					}
				},
				{
					Text = "{Turn back -- leave it running.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- The failed-read beat: the script defeats you, so you smash it. This
		// screen exists SO A FAILED READ IS NOT SILENT -- the player sees the notes
		// beat them and CHOOSES the crude way, instead of jumping straight to the
		// reveal with no acknowledgement (the bug this fixes).
		this.m.Screens.push({
			ID = "CannotRead",
			Title = "Beyond You",
			Text = "[img]gfx/ui/events/event_63.png[/img]{You bend over the desk, and the notes give up nothing. The hand is urgent, crabbed, certain -- and utterly closed, a script no one raised in these lands was ever taught to read. Whatever the man knew, whatever he meant to do and where he meant to do it, it stays his. There is no reading this. The grinding goes on under the floor, patient as ever, and there is only the one crude way left to make it stop.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Put an axe to the panel.}",
					function getResult()
					{
						return this.Contract.resolveTopSmash();
					}
				},
				{
					Text = "{Turn back -- leave it running.}",
					function getResult()
					{
						return "Aborted";
					}
				}
			],
			function start() {}
		});

		// ---- The generic RESULT screen (shows Pending*, offers the climb-on) --
		this.m.Screens.push({
			ID = "Result",
			Title = "The Tower",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Title = (this.Contract.m.PendingTitle != null && this.Contract.m.PendingTitle != "") ? this.Contract.m.PendingTitle : "The Tower";
				this.Text = this.Contract.m.PendingText; this.Contract.showRows(this);
				this.Options = [
					{
						Text = "{Climb on.}",
						function getResult()
						{
							return this.Contract.showFloor();
						}
					}
				];
			}
		});

		// ---- The REVEAL -- sweep has run; emptiness for all, fate for a reader -
		this.m.Screens.push({
			ID = "Reveal",
			Title = "No One Here",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local t = "[img]gfx/ui/events/event_57.png[/img]{The panel dies, the grinding stops, and on the stair below the tread stops too -- the half-made metal men gone still mid-climb, hands still lifted toward this room. And only now, in the silence, do you understand there is no one here to lift a hand back. No %SKVNAME%Xoud%SKVNAME_OFF%. No body. No bones. No grave. You climbed all this way to face whoever kept the fires lit, and there was never anyone at all -- only the machine, keeping a dead man's hours because no one ever came to tell it he was gone.";

				if (this.Contract.m.ShutdownClean)
				{
					t += "\n\nYou read enough of the desk before the lights went out to know the shape of it. He did not die here. He went somewhere -- the notes are certain of the place, if not the reason -- and sealed the tower to grind on behind him, as though he meant to come back, and never did. Where he went is a thing you will keep to yourselves for now.";
					t += "\n\nWhere the panel was, a compartment has come open, and what it held is yours.";
				}
				else
				{
					t += "\n\nWhatever the desk could have told you goes dark with the panel. You will not learn where he went, only that he is not here. Some questions the tower keeps.";
				}

				if (this.Contract.m.DoomedCount > 0)
				{
					t += "\n\nThe tower did not let all of you leave it. You carry down what the dead were owed, and their names, and the memory of a climb that bought them nothing.";
				}

				t += "}";
				this.Text = t; this.Contract.showRows(this);

				this.Options = [
					{
						Text = "{Climb down, and carry the word back.}",
						function getResult()
						{
							// The tower is silenced, but the job was to bring back WORD. Do NOT pay
							// here -- flip to the report leg and route the company home; pay + finish
							// happen at the Report screen in the village.
							this.Contract.m.TowerDone = true;
							this.Contract.despawnSite();
							this.Contract.m.BulletpointsObjectives = [
								"Carry word back to " + this.Contract.m.Home.getName()
							];
							if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
							{
								this.Contract.m.Home.getSprite("selection").Visible = true;
							}
							return 0;
						}
					}
				];
			}
		});

		// ---- REPORT -- carry the word back to the village for pay. The employer is
		// kept GENERIC ("the man who sent you out"): %employer% may not resolve to the
		// same NPC days later, so nothing here leans on it. Reflects whether the notes
		// were read (the kept seed) and whether anyone fell.
		this.m.Screens.push({
			ID = "Report",
			Title = "Word From the Wood",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local t = "[img]gfx/ui/events/event_20.png[/img]{You come down out of the wood days later, and the smoke does not come with you -- for the first time in longer than anyone in %SKVLOC%%townname%%SKVLOC_OFF% has been alive, the sky over the trees stands clean. That alone brings folk to their doors as you come up the road.\n\nThe man who sent you out meets you at the edge of the green, and he does not so much ask for the tower's tale as brace himself for it. So you give it to him plainly: there was no one up there. No master, no monster, no watchman -- only a dead man's machine grinding away at nothing, and it grinds no longer. %SPEECH_ON%%SKVNAME%%randombrother%%SKVNAME_OFF% cannot help himself. All that smoke, he says, all these years, and nobody home to make it. Your bogeyman was a broken clock.%SPEECH_OFF% The man takes it the way men take a fear they have carried so long they had half made a friend of it -- part relieved, part robbed of something.";
				if (this.Contract.m.ShutdownClean)
				{
					t += "\n\nWhat you do not tell him is the rest -- that the desk up there was certain the master had not died but GONE, and set down the place he went in a hand no soul in this village will ever read. It is not the sort of word that lets a man sleep. Better he keeps the broken clock.";
				}
				if (this.Contract.m.DoomedCount > 0)
				{
					t += "\n\nHe counts your number, too, and sees it comes back short of what went up. He does not say anything to that. There is nothing to say.";
				}
				t += "\n\nHe counts out what he promised, and a little he did not, and swears the well already tastes sweeter -- though it cannot possibly yet.}";
				this.Text = t;
				this.Options = [
					{
						Text = "{Take your pay.}",
						function getResult()
						{
							this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
							this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
							this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Silenced the Choking Tower");
							this.Contract.m.ClimbDone = true;
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		// ---- ABORT -- turn back on any floor. Keep advance + banked loot; the
		// sweep still runs (a brother a trap doomed does not walk out at <= 0 HP).
		this.m.Screens.push({
			ID = "Aborted",
			Title = "Down and Out",
			Text = "[img]gfx/ui/events/event_75.png[/img]{You have had enough of the tower. You go back the way you came -- down, always down, the smoke thinning as you descend, the dragging tread above falling silent behind you as though it had never been. You keep the little the employer paid to send you, and whatever you tore out of the tower's guts on the way up. Behind you the chimneys are still smoking. Someone else's worry now.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Leave the tower to itself.}",
					function getResult()
					{
						this.Contract.m.DoomedCount = this.Contract.deathSweep();
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Abandoned the Choking Tower");
						this.Contract.m.ClimbDone = true;
						this.Contract.despawnSite();
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}
				}
			],
			function start() {}
		});
	}

	function onClear()
	{
		// Always free the live-offer slot. If the contract was ACCEPTED (m.IsActive),
		// this onClear is an accept-then-conclude -- completed OR aborted mid-climb --
		// so retire the tower for good. A pre-accept decline or a passive expiry lands
		// here with IsActive false, leaving the tower re-offerable.
		::Skv.Once.release("ChokingTower");

		if (this.m.IsActive)
		{
			::Skv.Once.retire("ChokingTower");
			if (!::MSU.isNull(this.m.Destination))
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
		// Location highlighting -- see skv_black_forks_contract.nut for the full
		// reasoning. Names take blue-grey #9dbccb; places take violet-grey #b39dbc;
		// both are far points from BB's warm register and collide with nothing.
		local nameColor = "#9dbccb";
		_vars.push(["SKVNAME", "[color=" + nameColor + "]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);

		local locColor = "#b39dbc";
		_vars.push(["SKVLOC", "[color=" + locColor + "]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);

		// %actor% -- whoever last acted, pre-coloured as a person.
		local nm = (this.m.ActorName != null && this.m.ActorName != "") ? this.m.ActorName : "one of the company";
		_vars.push(["actor", "[color=" + nameColor + "]" + nm + "[/color]"]);
		// (no %loot% var any more -- loot is shown as iconed rows, not a text line.)
	}

	function onSerialize( _out )
	{
		if (!::MSU.isNull(this.m.Destination))
		{
			_out.writeU32(this.m.Destination.getID());
		}
		else
		{
			_out.writeU32(0);
		}

		_out.writeU8(this.m.KnowsName ? 1 : 0);
		_out.writeU8(this.m.ClimbDone ? 1 : 0);
		_out.writeU8(this.m.TowerDone ? 1 : 0);
		_out.writeU8(this.m.ShutdownClean ? 1 : 0);
		_out.writeU8(this.m.Floor);
		_out.writeU8(this.m.DoomedCount);

		if (this.m.Deck == null)
		{
			_out.writeU8(0);
		}
		else
		{
			_out.writeU8(this.m.Deck.len());
			foreach( c in this.m.Deck )
			{
				_out.writeU8(this.cardIndex(c));
			}
		}

		_out.writeString(this.m.PendingTitle);
		_out.writeString(this.m.PendingText);
		_out.writeString(this.m.LastLoot);   // vestigial (always "") -- kept so the save layout stays stable
		_out.writeString(this.m.ActorName);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local destination = _in.readU32();
		if (destination != 0)
		{
			this.m.Destination = this.WeakTableRef(::World.getEntityByID(destination));
		}

		this.m.KnowsName     = _in.readU8() == 1;
		this.m.ClimbDone     = _in.readU8() == 1;
		this.m.TowerDone     = _in.readU8() == 1;
		this.m.ShutdownClean = _in.readU8() == 1;
		this.m.Floor         = _in.readU8();
		this.m.DoomedCount   = _in.readU8();

		local len = _in.readU8();
		if (len == 0)
		{
			this.m.Deck = null;
		}
		else
		{
			local keys = this.cardKeys();
			this.m.Deck = [];
			for( local i = 0; i < len; i = i + 1 )
			{
				this.m.Deck.push(keys[_in.readU8()]);
			}
		}

		this.m.PendingTitle = _in.readString();
		this.m.PendingText  = _in.readString();
		this.m.LastLoot     = _in.readString();
		this.m.ActorName    = _in.readString();

		// The current floor is treated as already-smoked on load, so returning to
		// a save mid-climb does not sting the company a second time for one floor.
		this.m.SmokedFloor = this.m.Floor;
		this.m.CardTrap = null;
		this.m.Rows = [];        // transient outcome rows -- rebuilt as the player acts
		this.m.SmokePending = 0;

		this.contract.onDeserialize(_in);
	}

});
