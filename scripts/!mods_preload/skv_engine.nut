// ============================================================================
//  ::Skv -- shared utilities for the Golarion hand-authored contracts.
//  Stands on MSU. First brick: ::Skv.Loot, extracted from the Choking Tower's
//  loot helpers. The roll *shape* stays per-contract (tiered for the Tower,
//  four-bundle for Metringer); THESE are the shared primitives every contract's
//  loot roller composes.  See claude/skv_engine_roadmap.md.
// ============================================================================
if (!("Skv" in ::getroottable()))
{
	::Skv <- {};
}

// Debug logging gate. OFF for live (release). Two ways to turn it on: the in-game MSU setting
// ("Debug logging (log.html)", ::Skv.Cfg.debugLogging()), or the console override ::Skv.Verbose = true.
// All Skv.* debug lines (check chances, budgets, the gambler swing) route through ::Skv.dbg().
::Skv.Verbose <- false;   // console override; the in-game setting is the normal way
::Skv.dbg <- function ( _s )
{
	local on = ::Skv.Verbose;
	if (!on) { try { on = ::Skv.Cfg.debugLogging(); } catch (e) {} }
	if (on) ::logInfo(_s);
};

::Skv.Loot <- {

	// Grant one item by script path into the company stash. Returns its display
	// name (for the loot line), or null on: null path / full stash / load failure.
	//
	// CRITICAL: instantiate with the ROOT-TABLE `::new`, NOT `_contract.new`. `new`
	// is a global installed on the root table by the mod loader (!!redirect.nut);
	// it is NOT a member of a contract instance, so `_contract.new(path)` throws
	// "the index 'new' does not exist" and aborts the whole getResult silently --
	// which read in-game as loot clicks that "did nothing" until a coin-only roll
	// happened to skip item creation. MSU itself uses `::new(...)` from utility code.
	// The `_contract` param is kept for call-site stability (and future context use).
	// Wrapped so a bad path can never throw out of a screen handler.
	function grantItem( _contract, _path )
	{
		if (_path == null) return null;
		if (!::World.Assets.getStash().hasEmptySlot()) return null;
		local item = null;
		try { item = ::new(_path); }
		catch (e) { ::logError("Skv.Loot.grantItem failed for '" + _path + "': " + e); return null; }
		if (item == null) return null;
		::World.Assets.getStash().add(item);
		return item.getName();
	}

	// Add coin to the purse. Returns "N crowns" for the loot line, or null if <= 0.
	function grantCoin( _amount )
	{
		if (_amount <= 0) return null;
		::World.Assets.addMoney(_amount);
		return _amount + " crowns";
	}

	// An MSU weighted pool from [[weight, path], ...] pairs. Call .roll() to draw.
	function pool( _pairs )
	{
		return ::MSU.Class.WeightedContainer(_pairs);
	}

	// Colour one loot name with the event-screen reward green. MSU's colorPositive
	// uses a different green (PositiveValue), so we call color() with the loot colour
	// directly to match the shipped look.
	function color( _name )
	{
		return ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _name);
	}

	// Join granted names into one coloured sentence, e.g.
	// "a silver bowl and 176 crowns". Nulls are skipped; empty haul reads cleanly.
	function lootLine( _found )
	{
		local parts = [];
		foreach (name in _found)
		{
			if (name != null) parts.push(this.color(name));
		}
		if (parts.len() == 0) return "nothing worth the carrying";
		local line = parts[0];
		for (local i = 1; i < parts.len(); i = i + 1)
		{
			line = line + (i == parts.len() - 1 ? " and " : ", ") + parts[i];
		}
		return line;
	}

	// -- ICONED HAUL (Legends-native presentation) ---------------------------------
	// Create item objects from script paths (skips null/bad; never throws). Does NOT
	// add to the stash -- hand the result to haul(), which grants + builds the rows.
	function make( _paths )
	{
		local items = [];
		foreach (p in _paths)
		{
			if (p == null) continue;
			local it = null;
			try { it = ::new(p); }
			catch (e) { ::logError("Skv.Loot.make failed for '" + p + "': " + e); }
			if (it != null) items.push(it);
		}
		return items;
	}

	// Grant a haul the way the game presents rewards, and return the ready-to-show
	// event-screen List rows. Items go to the stash (expanded if needed), are grouped
	// by ID, and drawn with their real item icon + quality frame. SUPPLIES/AMMO show
	// their stack amount as the game does -- a green "+20 Medical Supplies" -- via
	// isAmountShown()/getAmount(); Legends' own addItems prints only getName() and drops
	// that count, so we build the item rows ourselves and keep changeMoney (Legends')
	// for the coin row. Push these into a screen's `List`. Empty haul -> []. Default
	// prefix matches the game's wording ("You gain X"), consistent with the coin row.
	function haul( _items, _coin = 0, _prefix = "You gain " )
	{
		local rows = [];
		if (_items != null && _items.len() > 0)
		{
			local stash = ::World.Assets.getStash();
			stash.makeEmptySlots(_items.len());
			// Group identical items by ID so three antidotes read once as "3x", not thrice.
			local grouped = [];
			local index = {};
			foreach (it in _items)
			{
				stash.add(it);
				if (it.getID() in index) { grouped[index[it.getID()]].count = grouped[index[it.getID()]].count + 1; continue; }
				index[it.getID()] <- grouped.len();
				grouped.push({ item = it, count = 1 });
			}
			foreach (g in grouped)
			{
				local it = g.item;
				// A stack (Medical Supplies = 20, etc.) shows its amount as a green "+N", the
				// way the base food/supply events do; plain valuables (isAmountShown false)
				// fall back to a simple "Nx" only when several of the same dropped.
				local qty = "";
				if (it.isAmountShown())
					qty = ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, "+" + it.getAmount()) + " ";
				else if (g.count > 1)
					qty = g.count + "x ";
				rows.push({
					id = 1,
					icon = "ui/items/" + it.getIcon(),
					imageOverlayPath = it.getIconOverlay(),   // quality/named frame; "" for plain items (render hook skips it)
					text = _prefix + qty + it.getName()
				});
			}
		}
		if (_coin > 0) rows.push(::Legends.EventList.changeMoney(_coin));
		return rows;
	}

	// DISPLAY-ONLY rows for a screen that NAMES loot it will grant on confirm (so the
	// grant stays in the option handler, safe against a re-show/reload). Builds the same
	// icon + amount rows as haul() but adds nothing to the stash. Coin, when fixed, is a
	// plain "+N Crowns" row (we are not calling changeMoney -- that would add the money).
	function previewRows( _paths, _coin = 0, _prefix = "You gain " )
	{
		local rows = [];
		foreach (it in this.make(_paths))
		{
			local qty = "";
			if (it.isAmountShown())
				qty = ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, "+" + it.getAmount()) + " ";
			rows.push({
				id = 1,
				icon = "ui/items/" + it.getIcon(),
				imageOverlayPath = it.getIconOverlay(),
				text = _prefix + qty + it.getName()
			});
		}
		if (_coin > 0)
			rows.push({ id = 1, icon = "ui/icons/asset_money.png", text = _prefix + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _coin) + " Crowns" });
		return rows;
	}
};

// ============================================================================
//  ::Skv.Once -- the "one-accept, once-per-campaign" gate as a shared primitive,
//  extracted from the Choking Tower. Any hand-authored unique contract that should
//  appear at most once and never duplicate across towns adopts it with a stable
//  string _key (e.g. "ChokingTower", "BlackForks") and five call sites.
//
//  TWO FLAGS per key:
//   * <key>.active -- the "one live offer" slot. CLAIMed the instant a town
//     generates the offer; RELEASEd by the contract's onClear. onClear fires on
//     EVERY removal path -- accept-then-resolve, decline, AND an offer timing out
//     unseen (contract_manager.update -> c.clear() -> onClear, verified). So the
//     slot is never permanently leaked.
//   * <key>.retired -- PERMANENT. Set when an ACCEPTED contract CONCLUDES -- whether
//     completed or aborted after accept. Once set, the gate never opens again this
//     campaign. A pre-accept decline and a passive expiry do NOT set it.
//
//  RESULT -- a decline or a passive expiry brings the contract back; only taking it
//  and seeing it through (or giving up mid-way) retires it. The trick: onClear fires
//  on EVERY removal, but `m.IsActive` distinguishes them -- it is true only for a
//  contract that was accepted (setActiveContract), and BB keeps it true through
//  finishActiveContract's onClear (verified), while an offered contract that is
//  declined or times out never had it set. So retire() lives in onClear GUARDED by
//  m.IsActive; release() is unconditional. (An accepted contract cannot expire on its
//  own -- isTimedOut requires !IsActive -- so "IsActive at onClear" always means an
//  accept-then-conclude, never a stale offer.)
//
//  WIRING (see skv_choking_tower_* for the reference adoption):
//   action.onUpdate : if (::Skv.Once.isLocked(KEY)) return;         // at the very top
//   action.onExecute: ::Skv.Once.claim(KEY);                        // before addContract
//   contract.onClear: ::Skv.Once.release(KEY);                      // always, first line
//                     if (this.m.IsActive) ::Skv.Once.retire(KEY);  // accepted+concluded only
// ============================================================================
::Skv.Once <- {

	function activeFlag( _key )  { return "SkvOnce." + _key + ".active"; }
	function retiredFlag( _key ) { return "SkvOnce." + _key + ".retired"; }

	// ACTION onUpdate gate: true => do NOT offer (a copy is already live, or the
	// contract has been resolved for the campaign). The one call the gate needs.
	function isLocked( _key )
	{
		return ::World.Flags.has(this.retiredFlag(_key)) || ::World.Flags.has(this.activeFlag(_key));
	}

	// ACTION onExecute: claim the single live-offer slot as the first town posts it.
	function claim( _key ) { ::World.Flags.set(this.activeFlag(_key), true); }

	// CONTRACT onClear (unconditional): free the live-offer slot on any removal.
	function release( _key ) { ::World.Flags.remove(this.activeFlag(_key)); }

	// CONTRACT onClear WHEN m.IsActive: an accepted contract concluded (completed or
	// aborted) -- retire it permanently. Not called on a pre-accept decline or expiry.
	function retire( _key ) { ::World.Flags.set(this.retiredFlag(_key), true); }

	// Query helper (rarely needed): has this been resolved this campaign?
	function isRetired( _key ) { return ::World.Flags.has(this.retiredFlag(_key)); }
};

// ============================================================================
//  ::Skv.Check -- the roster skill-check by background LADDER, extracted from the
//  Choking Tower's resolveCheck. The best-qualified brother (highest ladder base for
//  his background) attempts it; his traits (+/-12), perks (+15) and matching injuries
//  (-15) adjust the chance, clamped 5..95, then a d100. Ladder + modifier lists are
//  DATA. Sets _contract.m.ActorName (declare it) for the %actor% text var. Returns
//  { ok, actor, chance }. (Tower still runs its own copy; retrofit is a follow-up.)
// ============================================================================
::Skv.Check <- {

	function resolve( _contract, _ladder, _plusTraits, _minusTraits, _plusPerks, _injuries, _floorBase )
	{
		local actor = null;
		local chance = 0;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			foreach (e in _ladder)
			{
				if (e[0] == bro.getBackground().getID() && e[1] > chance) { chance = e[1]; actor = bro; }
			}
		}
		if (actor == null) chance = _floorBase;
		else
		{
			foreach (t in _plusTraits)  if (actor.getSkills().hasSkill("trait." + t)) chance = chance + 12;
			foreach (t in _minusTraits) if (actor.getSkills().hasSkill("trait." + t)) chance = chance - 12;
			foreach (p in _plusPerks)   if (actor.getSkills().hasPerk(p))             chance = chance + 15;
			foreach (inj in _injuries)  if (actor.getSkills().hasSkill(inj))          chance = chance - 15;
		}
		chance = ::Math.max(5, ::Math.min(95, chance));
		local roll = ::Math.rand(1, 100);
		_contract.m.ActorName = (actor != null ? actor.getName() : "one of the company");
		::Skv.dbg("Skv.Check chance=" + chance + " roll=" + roll + " actor=" + _contract.m.ActorName);
		return { ok = roll <= chance, actor = actor, chance = chance };
	}

	// COMPOSITION checks -- deliberately use NO combat stats (Initiative etc.), staying on the same
	// character axis as resolve(). A flat _base is moved by curated trait/background/perk modifiers
	// minus an injury penalty, and -- unlike resolve() (best BACKGROUND, then that one brother) --
	// bestByComposition() scores EVERY active brother and returns the BEST one (highest net). So
	// your sharpest/nimblest man leads, and the negatives only bite a company with no good one left.
	// _traitMods / _bgMods are id->delta tables; _perkMods is keyed by ::Legends.Perk DEFS (NOT raw
	// "perk.x" strings -- Legends' hasPerk throws on a string); _injuries is a string-id set, any of
	// which costs -15. Returns { ok, actor, chance } and sets contract.m.ActorName (for %actor%).
	function bestByComposition( _contract, _base, _traitMods, _bgMods, _perkMods, _injuries )
	{
		local best = null;
		local bestChance = -9999;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.isInReserves()) continue;   // active company only -- matches the ::Skv.XP pool
			local sk = bro.getSkills();
			local c = _base;
			foreach (id, d in _traitMods) if (sk.hasSkill(id)) c = c + d;
			local bg = bro.getBackground();
			if (bg != null && (bg.getID() in _bgMods)) c = c + _bgMods[bg.getID()];
			foreach (id, d in _perkMods) if (sk.hasPerk(id)) c = c + d;
			foreach (inj in _injuries) if (sk.hasSkill(inj)) { c = c - 15; break; }   // one penalty, not per-injury
			if (c > bestChance) { bestChance = c; best = bro; }
		}
		if (best == null) bestChance = _base;   // empty / all-reserve roster safety
		// GAMBLER'S GAMBLE (catalog §6): a flavor that LISTS background.gambler scores it at 0 (neutral
		// for SELECTION -- see agility/guile), then, if the chosen brother IS a gambler, his luck is
		// itself a gamble: a rand(-5..+5) swing on the final chance, net-neutral on average. Rolled here,
		// at resolution, for the chosen actor only -- never during scoring (which would destabilize WHO
		// is picked). Lucky (the TRAIT) is unaffected; it stays a flat +5 in the flavor tables.
		if (best != null && ("background.gambler" in _bgMods))
		{
			local bg2 = best.getBackground();
			if (bg2 != null && bg2.getID() == "background.gambler")
			{
				local swing = ::Math.rand(-5, 5);
				bestChance = bestChance + swing;
				::Skv.dbg("Skv.Check gambler's-gamble swing=" + swing + " actor=" + best.getName());
			}
		}
		local chance = ::Math.max(5, ::Math.min(95, bestChance));
		local roll = ::Math.rand(1, 100);
		_contract.m.ActorName = (best != null ? best.getName() : "one of the company");
		return { ok = roll <= chance, actor = best, chance = chance };
	}

	// AGILITY / DODGE -- the nimblest active brother leads a physical feat (a pit crossing, a dodge).
	// Footwork signals +-12, luck-flavored ones +-5, Dodge +15, a standing leg injury -15.
	function agility( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 12, ["trait.sure_footing"] = 12, ["trait.lucky"] = 5, ["trait.legend_light"] = 5,
			  ["trait.clumsy"] = -12, ["trait.clubfooted"] = -12, ["trait.fat"] = -12, ["trait.old"] = -5 },
			{ ["background.belly_dancer"] = 7,
			  ["background.juggler"] = 3, ["background.assassin"] = 3, ["background.messenger"] = 3,
			  ["background.gambler"] = 0,   // 0 for selection; the ±5 gambler's-gamble swing is rolled in bestByComposition
			  ["background.legend_blacksmith"] = -4, ["background.brawler"] = -4, ["background.butcher"] = -4,
			  ["background.farmhand"] = -4, ["background.milkmaid"] = -4, ["background.cripple"] = -12 },
			{ [::Legends.Perk.Dodge] = 15 },
			this.legInjuries());
		::Skv.dbg("Skv.Check.agility chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// PERCEPTION / SPOT -- the sharpest-eyed active brother notices something (a trap seam, a
	// tell). Keen eyes and woodcraft help; short sight / dullness / a missing eye hurt. No perks.
	function perception( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.eagle_eyes"] = 12, ["trait.short_sighted"] = -12, ["trait.dumb"] = -8 },
			{ ["background.poacher"] = 12, ["background.brigand_poacher"] = 12, ["background.hunter"] = 12,
			  ["background.ratcatcher"] = 10, ["background.thief"] = 8, ["background.witchhunter"] = 8 },
			{},
			this.eyeInjuries());
		::Skv.dbg("Skv.Check.perception chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// BRAWN -- strongest active brother in a test of raw power (arm-wrestle, lift, force a door).
	// Big frames help; soft/old sap it; a hand wound kills the grip. (Carthica's arm-wrestle.)
	function brawn( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.strong"] = 12, ["trait.huge"] = 10, ["trait.brute"] = 12,
			  ["trait.fat"] = -8, ["trait.old"] = -5 },
			{ ["background.wildman"] = 12, ["background.legend_berserker"] = 12,
			  ["background.legend_berserker_commander"] = 12, ["background.legend_commander_berserker"] = 12,
			  ["background.barbarian"] = 8, ["background.brawler"] = 6,
			  ["background.farmhand"] = 2, ["background.lumberjack"] = 2,
			  ["background.minstrel"] = -5, ["background.historian"] = -5, ["background.messenger"] = -5 },
			{ [::Legends.Perk.Colossus] = 5 },
			this.handInjuries());
		::Skv.dbg("Skv.Check.brawn chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// HAND-EYE -- steadiest active brother in a test of aim (a thrown dagger). Fine motor + keen
	// eyes help; clumsy/short-sighted hurt; a hand wound spoils the throw. (Carthica's dagger-toss.)
	function handEye( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 8, ["trait.eagle_eyes"] = 8,
			  ["trait.clumsy"] = -12, ["trait.short_sighted"] = -8 },
			{ ["background.juggler"] = 12, ["background.hunter"] = 10, ["background.poacher"] = 10,
			  ["background.bowyer"] = 6, ["background.fletcher"] = 6, ["background.fisherman"] = 3,
			  ["background.legend_berserker"] = -3, ["background.legend_berserker_commander"] = -3,
			  ["background.legend_commander_berserker"] = -3, ["background.brawler"] = -3,
			  ["background.cripple"] = -3 },
			{},
			this.handInjuries());
		::Skv.dbg("Skv.Check.handEye chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// NERVE -- steeliest active brother in a test of courage (hung upside-down over spikes). Brave/
	// determined hold; faint hearts and cowards fold. No injury set. (Carthica's courage hang.)
	function nerve( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.fearless"] = 12, ["trait.brave"] = 12, ["trait.mad"] = 10, ["trait.determined"] = 6, ["trait.cocky"] = 3,
			  ["trait.fainthearted"] = -12, ["trait.paranoid"] = -10, ["trait.dastard"] = -7, ["trait.insecure"] = -6 },
			{ ["background.legend_battle_sister"] = 6, ["background.monk"] = 8, ["background.gladiator"] = 6,
			  ["background.legend_berserker"] = 6, ["background.legend_berserker_commander"] = 6,
			  ["background.legend_commander_berserker"] = 6, ["background.assassin"] = 4,
			  ["background.deserter"] = -10 },
			{},
			[]);
		::Skv.dbg("Skv.Check.nerve chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// GUILE -- the coldest, sharpest card-player: bluff, odds, sleight (Carthica's CARDS contest only;
	// the crowd-work flourish is CHARM now). A Diviner "knows" the cards; Quick Hands palms them; Taunt
	// rattles the mark; a KNOWN Thief is watched from the first hand, so his edge is small (+3). Greedy
	// overbets. gambler = 0 for SELECTION with the ±5 gambler's-gamble swing; Lucky stays flat +5.
	// Finger/brain wounds (crushed/missing finger, brain damage) sap the hands AND the counting.
	function guile( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.bright"] = 12, ["trait.lucky"] = 5, ["trait.dumb"] = -8, ["trait.greedy"] = -2 },
			{ ["background.legend_diviner"] = 12, ["background.gambler"] = 0,   // gambler = 0 for selection; ±5 swing in bestByComposition
			  ["background.thief"] = 3, ["background.vagabond"] = 3 },
			{ [::Legends.Perk.Taunt] = 4, [::Legends.Perk.QuickHands] = 2 },
			[ "injury.crushed_finger", "injury.missing_finger", "injury.brain_damage" ]);
		::Skv.dbg("Skv.Check.guile chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// CHARM -- the most magnetic active brother WORKING A CROWD (a joke, a swagger, stage presence).
	// The social twin of guile: cards is cold cunning; this is warmth and showmanship, usually a
	// DIFFERENT man. Entertainers lead (Qiyan, Minstrel, Juggler); the brutish/off-putting drag it
	// (Berserker, Brawler, Cannibal, Butcher). NOTE: Dumb is NOT a penalty here -- a fool can land a
	// joke. Brain damage still saps it. (Carthica's flourish; reusable for future persuade/rally beats.)
	function charm( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.bright"] = 6, ["trait.lucky"] = 5 },
			{ ["background.legend_qiyan"] = 11, ["background.minstrel"] = 8, ["background.juggler"] = 8,
			  ["background.peddler"] = 4, ["background.servant"] = 2,   // servant covers female "Housemaid" too (same id)
			  ["background.legend_berserker"] = -5, ["background.legend_berserker_commander"] = -5,
			  ["background.legend_commander_berserker"] = -5, ["background.brawler"] = -5,
			  ["background.legend_cannibal"] = -5, ["background.butcher"] = -5 },
			{},
			[ "injury.brain_damage" ]);
		::Skv.dbg("Skv.Check.charm chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// A difficulty-scaled base for a check that SHOULD stiffen on a harder contract (spotting a trap,
	// reading a tome, picking a lock). _base is the check's STANDARD-difficulty anchor; the swing is
	// slope*(1 - DifficultyMult), so an easy contract raises the anchor and a hard one lowers it
	// (e.g. base 50, slope 50: DiffMult 0.72 -> 64, 1.2 -> 40). Clamped 5-95. Honors the ::Skv.Cfg
	// "scale checks with difficulty" toggle -- OFF returns the anchor unchanged (predictable mode).
	// Physical checks (athletics) that don't care about contract difficulty just pass a flat number
	// and never call this. Usage: perception(contract, ::Skv.Check.scaledBase(contract, 50)).
	function scaledBase( _contract, _base, _slope = 50 )
	{
		local on = true;
		try { on = ::Skv.Cfg.scaleChecks(); } catch (e) { on = true; }
		if (!on) return ::Math.max(5, ::Math.min(95, _base));
		return ::Math.max(5, ::Math.min(95, _base + _slope * (1.0 - _contract.getDifficultyMult())));
	}

	// Injury sets that read as a penalty when the acting brother already carries one.
	function handInjuries() { return ["injury.smashed_hand", "injury.split_hand", "injury.pierced_hand", "injury.fractured_hand", "injury.burnt_hands", "injury.crushed_finger", "injury.missing_hand", "injury.missing_finger"]; }
	function eyeInjuries()  { return ["injury.grazed_eye_socket", "injury.missing_eye"]; }
	function legInjuries()  { return ["injury.pierced_leg_muscles", "injury.injured_knee_cap", "injury.broken_leg", "injury.burnt_legs", "injury.cut_leg_muscles", "injury.bruised_leg", "injury.sprained_ankle", "injury.broken_knee", "injury.maimed_foot"]; }
};

// ============================================================================
//  ::Skv.Cfg -- the mod's MSU settings. ONE general frequency dial shared by
//  EVERY Golarion hand-authored contract (not one per contract). It is the
//  literal faction-action m.Score, 0..10:
//     0  = off  -- no Golarion contract is offered at all
//     1..10     = the selection WEIGHT every Golarion action stamps on itself
//                 (the faction-action loop sums the eligible deck's scores and
//                 rolls against them; a higher weight wins the settlement's slot
//                 more often). Default 2, the value four of the six contracts
//                 already used (watchtower + den_hunt were 1; a single shared
//                 knob unifies them -- a negligible weighting change).
//
//  Each contract keeps its OWN rarity / eligibility gates (the ~15% roll, the
//  draught situation, the renown floor, once-per-campaign via ::Skv.Once); this
//  only sets how heavily it weighs when it does roll -- and 0 short-circuits the
//  action before it offers.
//
//  WIRING (every Golarion *_action.nut onUpdate):
//     local sc = ::Skv.Cfg.score();
//     if (sc <= 0) return;          // first line -- Golarion contracts disabled
//     ... the action's own gates ...
//     this.m.Score = sc;            // replaces the old literal `this.m.Score = N`
//
//  REGISTRATION: mod_golarion.nut's mods_queue (after mod_msu) calls
//     ::Skv.Cfg.register("mod_golarion", modVersion, modName);
//  once. Reads are defensive -- if MSU/the setting is ever absent, score() falls
//  back to DefaultScore and never throws out of an onUpdate tick.
// ============================================================================
::Skv.Cfg <- {

	Mod = null,          // ::MSU.Class.Mod handle, set by register()
	DefaultScore = 2,    // out-of-the-box weight AND the fallback when MSU is absent
	SettingID = "GolarionContractScore",

	// Check-XP actor share: on a successful skill check, what % of the awarded XP goes to the
	// acting brother; the rest is split across the active company (::Skv.XP.grant). 0..100.
	ActorShareID = "GolarionCheckActorShare",
	DefaultActorShare = 35,

	// Whether skill-check bases scale with contract difficulty (::Skv.Check.scaledBase). ON =
	// harder contracts hide traps / stiffen checks; OFF = every scaling check sits at its
	// standard-difficulty anchor regardless of skull rating. Physical checks (athletics) never scale.
	ScaleChecksID = "GolarionScaleChecks",
	DefaultScaleChecks = true,

	// Debug logging: when ON, the mod writes its skill-check chances, fight budgets, and other
	// diagnostics to log.html (via ::Skv.dbg). OFF for normal play. Handy when reporting a bug.
	DebugLoggingID = "GolarionDebugLogging",
	DefaultDebugLogging = false,

	// Build the settings page + the single shared dial. Called once from the mod's
	// MSU queue. Wrapped so a settings-system hiccup can never abort mod load.
	function register( _id, _version, _name )
	{
		try
		{
			// MSU's registry cross-checks the ::MSU.Class.Mod version against the EXACT
			// version string mod_hooks recorded for this id and throws InvalidValue if
			// they differ (registry_system.nut) -- which is why a float modVersion (0.90)
			// failed. Read the Hooks-recorded string directly when we can, so the two can
			// never disagree; fall back to the passed version otherwise. The mod registers
			// with a STRING semver (X.Y.Z), so either value is valid for ::MSU.SemVer.
			local ver = _version;
			try { local hm = ::Hooks.getMod(_id); if (hm != null) ver = hm.getVersionString(); } catch (e) {}
			this.Mod = ::MSU.Class.Mod(_id, ver, _name);
			local page = this.Mod.ModSettings.addPage("Contracts");
			page.addTitle("golarion_contracts_title", "Golarion Contracts");
			page.addRangeSetting(this.SettingID, this.DefaultScore, 0, 10, 1,
				"Contract frequency (weight)",
				"How often the mod's hand-authored contracts appear. This is the shared selection weight (m.Score) used by EVERY Golarion contract in the faction-action pick.\n\n[b]0[/b] = off (no Golarion contract is offered).\n[b]2[/b] = default.\nHigher = they win a settlement's contract slot more often.\n\nEach contract keeps its own rarity and eligibility gates; this only sets how heavily it weighs when it rolls.");
			page.addRangeSetting(this.ActorShareID, this.DefaultActorShare, 0, 100, 5,
				"Check XP — actor share (%)",
				"When a brother passes a skill check (a lockpick, a trapped passage, a reading), the contract awards a bit of experience.\n\nThis sets how much of it goes to the brother who actually did it; the rest is split evenly across the whole active company (everyone learns a little from watching).\n\n[b]35[/b] = default (about a third to the doer, the rest shared).\n[b]100[/b] = all to the doer.\n[b]0[/b] = split evenly across everyone.");
			page.addBooleanSetting(this.ScaleChecksID, this.DefaultScaleChecks,
				"Scale skill checks with contract difficulty",
				"When ON, skill checks that scale (spotting a trap, reading a tome, picking a lock) get harder on higher-skull contracts and easier on low ones.\n\nWhen OFF, every such check sits at its own standard-difficulty value regardless of the contract's skull rating — predictable mode.\n\nPhysical checks like crossing a pit are never affected either way.\n\n[b]On[/b] = default.");
			page.addBooleanSetting(this.DebugLoggingID, this.DefaultDebugLogging,
				"Debug logging (log.html)",
				"When ON, the mod writes diagnostics — skill-check chances and rolls, fight budgets, the gambler's-gamble swing — to log.html.\n\nLeave OFF for normal play. Turn it ON if you hit odd behaviour and want to report it, then send the log.\n\n[b]Off[/b] = default.");
			::Skv.dbg("Skv.Cfg: settings registered (default score " + this.DefaultScore + ")");
		}
		catch (e)
		{
			::logError("Skv.Cfg.register failed (settings unavailable, using default score): " + e);
			this.Mod = null;
		}
	}

	// The current shared weight, read fresh every tick. 0 => actions treat it as off.
	// Falls back to DefaultScore if MSU/the setting is somehow unavailable; never throws.
	function score()
	{
		if (this.Mod == null) return this.DefaultScore;
		try
		{
			local s = this.Mod.ModSettings.getSetting(this.SettingID);
			if (s == null) return this.DefaultScore;
			return s.getValue();
		}
		catch (e)
		{
			::logError("Skv.Cfg.score failed (using default): " + e);
			return this.DefaultScore;
		}
	}

	// The check-XP actor share (%), read fresh on each successful check. Mirrors score()'s
	// exact shape (same Mod handle, same defensive fallback); ::Skv.XP.grant reads it.
	function actorShare()
	{
		if (this.Mod == null) return this.DefaultActorShare;
		try
		{
			local s = this.Mod.ModSettings.getSetting(this.ActorShareID);
			if (s == null) return this.DefaultActorShare;
			return s.getValue();
		}
		catch (e)
		{
			::logError("Skv.Cfg.actorShare failed (using default): " + e);
			return this.DefaultActorShare;
		}
	}

	// Whether difficulty-scaled check bases actually scale. Read by ::Skv.Check.scaledBase.
	function scaleChecks()
	{
		if (this.Mod == null) return this.DefaultScaleChecks;
		try
		{
			local s = this.Mod.ModSettings.getSetting(this.ScaleChecksID);
			if (s == null) return this.DefaultScaleChecks;
			return s.getValue();
		}
		catch (e)
		{
			::logError("Skv.Cfg.scaleChecks failed (using default): " + e);
			return this.DefaultScaleChecks;
		}
	}

	// Whether the mod writes debug diagnostics to log.html. Read by ::Skv.dbg on every log call.
	function debugLogging()
	{
		if (this.Mod == null) return this.DefaultDebugLogging;
		try
		{
			local s = this.Mod.ModSettings.getSetting(this.DebugLoggingID);
			if (s == null) return this.DefaultDebugLogging;
			return s.getValue();
		}
		catch (e) { return this.DefaultDebugLogging; }
	}
};

// ============================================================================
//  ::Skv.Debug -- Dev-Console helpers (TaroEld's mod_dev_console, Squirrel env).
//  Read-only inspection commands, safe to run any time. Nothing here is wired into
//  gameplay -- it exists only to be typed into the console.
//
//  ::Skv.Debug.contracts()      -- every settlement's offered contracts, this mod's
//                                  marked with '*', the accepted one flagged (ACTIVE).
//  ::Skv.Debug.contracts(true)  -- only this mod's contracts (skip vanilla/Legends).
//  ::skvc() / ::skvc(true)      -- short aliases for the two above.
//
//  Reads the SAME source the town screen uses (settlement.getContracts(), filtered to
//  contracts whose home is that town), so it shows where a contract actually posted --
//  including towns you have not visited (contracts generate over time as settlements
//  tick). A fresh campaign may list none of yours yet; run it again after a few days.
// ============================================================================
::Skv.Debug <- {

	// This mod's contract types (exact match -- so we don't flag Legends' own legend_* jobs).
	Types = [
		"contract.skv_azari", "contract.skv_ambush", "contract.skv_metringer", "contract.skv_black_forks",
		"contract.skv_choking_tower", "contract.skv_den_hunt", "contract.legend_watchtower", "contract.legend_skulls_crossing",
		"contract.skv_carthica"
	],

	function isMine( _type )
	{
		foreach (t in this.Types) if (_type == t) return true;
		return false;
	}

	// Print every settlement's offered contracts, grouped by town; this mod's marked '*',
	// the accepted one flagged (ACTIVE). _onlyMine skips vanilla/Legends jobs.
	function contracts( _onlyMine = false )
	{
		local total = 0, mineN = 0, towns = 0;
		foreach (s in ::World.EntityManager.getSettlements())
		{
			local cs = s.getContracts();
			if (cs.len() == 0) continue;
			local shown = false;
			foreach (c in cs)
			{
				local t = c.getType();
				local hit = this.isMine(t);
				if (_onlyMine && !hit) continue;
				if (!shown) { ::logInfo(">> " + s.getName()); shown = true; towns = towns + 1; }
				total = total + 1;
				if (hit) mineN = mineN + 1;
				::logInfo((hit ? " * " : " - ") + c.getName() + " [" + t + "]" + (c.isActive() ? " (ACTIVE)" : ""));
			}
		}
		::logInfo("== " + total + " contract(s) at " + towns + " town(s), " + mineN + " from this mod" + (_onlyMine ? " (mod only)" : "") + " ==");
	}

	// Azari gate diagnosis: the once-flags + every temple-town on the map (and what
	// is posted there), so we can see why The Azari Commission is or is not offering.
	// Read-only. Run ::skvazari().
	function azari()
	{
		::logInfo(">> Azari gate: once.active=" + ::World.Flags.has("SkvOnce.Azari.active") + " once.retired=" + ::World.Flags.has("SkvOnce.Azari.retired"));
		local temples = 0, total = 0;
		foreach (s in ::World.EntityManager.getSettlements())
		{
			total = total + 1;
			local hasT = false;
			try { hasT = s.hasBuilding("building.temple"); } catch (e) {}
			if (!hasT) continue;
			temples = temples + 1;
			local types = "";
			foreach (c in s.getContracts()) types = types + (types == "" ? "" : ",") + c.getType();
			::logInfo(" temple: " + s.getName() + " south=" + s.isSouthern() + " mil=" + s.isMilitary() + " iso=" + s.isIsolated() + " size=" + s.getSize() + " contracts=[" + types + "]");
		}
		::logInfo("== " + temples + " temple-town(s) of " + total + " settlements ==");
	}

	// Ambush gate diagnosis: the once-flags + every eligible hiring town, with how many DELIVERY
	// candidates it has (any / road-connected) and the distance range -- so we can see why
	// "Ambush in <city>" is or is not offering, and tune the destination pick. Read-only. Run ::skvambush().
	function ambush()
	{
		::logInfo(">> Ambush gate: once.active=" + ::World.Flags.has("SkvOnce.Ambush.active") + " once.retired=" + ::World.Flags.has("SkvOnce.Ambush.retired"));
		local towns = 0, readyN = 0;
		foreach (s in ::World.EntityManager.getSettlements())
		{
			local mil = true, iso = true, disc = false;
			try { mil = s.isMilitary(); iso = s.isIsolated(); disc = s.isDiscovered(); } catch (e) { continue; }
			if (mil || iso || !disc) continue;
			towns = towns + 1;
			// Resolve the owning faction and the EXACT readiness the offer gate would see.
			local tname = "?", ready = false, excl = false;
			try
			{
				local fac = ::World.FactionManager.getFaction(s.getFaction());
				if (fac.getType() == ::Const.FactionType.Settlement)
				{
					tname = "SET";
					ready = fac.isReadyForContract(::Const.Contracts.ContractCategoryMap.skv_ambush_contract);
					excl = fac.hasContractExclusion("contract.skv_ambush");
				}
				else
				{
					tname = "CS";
					ready = fac.isReadyForContract();
				}
			}
			catch (e) { tname = "ERR:" + e; }
			if (ready && !excl) readyN = readyN + 1;
			local n = s.getContracts().len();
			::logInfo(" town: " + s.getName() + " type=" + tname + " READY=" + ready + " excl=" + excl + " nContracts=" + n);
		}
		::logInfo("== " + towns + " eligible town(s); " + readyN + " would PASS the Ambush readiness gate ==");
	}
};

// Short console aliases: ::skvc() = all contracts, ::skvc(true) = this mod's only.
::skvc <- function ( _onlyMine = false ) { return ::Skv.Debug.contracts(_onlyMine); };
::skvazari <- function () { return ::Skv.Debug.azari(); };
::skvambush <- function () { return ::Skv.Debug.ambush(); };

// When true, skv_ambush_action.onUpdate logs its EXACT decline reason per town to log.html.
// Toggle from the console: ::skvambushdbg()  (on) / ::skvambushdbg(false)  (off). Then let a moment
// of game time pass and read log.html. Leave OFF normally (it is chatty).
::SkvAmbushDbg <- false;
::skvambushdbg <- function ( _on = true ) { ::SkvAmbushDbg = _on; ::Skv.dbg("SkvAmbushDbg = " + _on); return _on; };
