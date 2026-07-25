// ============================================================================
//  ::Skv -- shared utilities for the Golarion hand-authored contracts.
// ============================================================================
if (!("Skv" in ::getroottable()))
{
	::Skv <- {};
}

// ::Skv.dbg gated logging. OFF for live. Enable via MSU setting (::Skv.Cfg.debugLogging()) or console ::Skv.Verbose = true.
::Skv.Verbose <- false;
::Skv.dbg <- function ( _s )
{
	local on = ::Skv.Verbose;
	if (!on) { try { on = ::Skv.Cfg.debugLogging(); } catch (e) {} }
	if (on) ::logInfo(_s);
};

::Skv.Loot <- {

	// Grant one item by script path into the stash. Returns its display name, or null on null path / full stash / load failure.
	// GOTCHA: use root-table `::new`, NOT `_contract.new` (not a contract member -- throws "index 'new' does not exist").
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

	// Colour one loot name with the event-screen reward green (PositiveEventValue).
	function color( _name )
	{
		return ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _name);
	}

	// Join granted names into one coloured sentence; nulls skipped, empty haul reads cleanly.
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
	// Create item objects from script paths (skips null/bad; never throws). Does NOT add to stash -- pass to haul().
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

	// Grant a haul (stash expanded as needed, grouped by ID, real icon + quality frame) and return event-screen List rows.
	// SUPPLIES/AMMO show stack amount via isAmountShown()/getAmount(); empty haul -> [].
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
				// Stacks show amount as green "+N" (isAmountShown); plain valuables fall back to "Nx" when several dropped.
				local qty = "";
				if (it.isAmountShown())
					qty = ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, "+" + it.getAmount()) + " ";
				else if (g.count > 1)
					qty = g.count + "x ";
				rows.push({
					id = 1,
					icon = "ui/items/" + it.getIcon(),
					imageOverlayPath = it.getIconOverlay(),   // quality/named frame ("" for plain items)
					text = _prefix + qty + it.getName()
				});
			}
		}
		if (_coin > 0) rows.push(::Legends.EventList.changeMoney(_coin));
		return rows;
	}

	// DISPLAY-ONLY rows (grant stays in the option handler). Same icon+amount rows as haul() but adds nothing to the stash.
	// Coin is a plain "+N Crowns" row (NOT changeMoney -- that would add the money).
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
//  ::Skv.Once -- "one-accept, once-per-campaign" gate. Two flags per key:
//   * <key>.active  -- one-live-offer slot; claimed on offer, released in onClear (fires on every removal).
//   * <key>.retired -- PERMANENT; set only when an ACCEPTED contract concludes (guard retire() with m.IsActive).
//  WIRING: onUpdate: if (isLocked(KEY)) return;  onExecute: claim(KEY);
//          onClear: release(KEY); if (m.IsActive) retire(KEY);
// ============================================================================
::Skv.Once <- {

	function activeFlag( _key )  { return "SkvOnce." + _key + ".active"; }
	function retiredFlag( _key ) { return "SkvOnce." + _key + ".retired"; }

	// onUpdate gate: true => do NOT offer (a copy is live, or resolved this campaign).
	function isLocked( _key )
	{
		return ::World.Flags.has(this.retiredFlag(_key)) || ::World.Flags.has(this.activeFlag(_key));
	}

	// ACTION onExecute: claim the single live-offer slot as the first town posts it.
	function claim( _key ) { ::World.Flags.set(this.activeFlag(_key), true); }

	// CONTRACT onClear (unconditional): free the live-offer slot on any removal.
	function release( _key ) { ::World.Flags.remove(this.activeFlag(_key)); }

	// onClear WHEN m.IsActive: accepted contract concluded -- retire permanently.
	function retire( _key ) { ::World.Flags.set(this.retiredFlag(_key), true); }

	// Query helper (rarely needed): has this been resolved this campaign?
	function isRetired( _key ) { return ::World.Flags.has(this.retiredFlag(_key)); }
};

// ============================================================================
//  ::Skv.Check -- roster skill-check by background LADDER. Best-qualified brother
//  attempts; traits (+/-12), perks (+15), injuries (-15) adjust, clamp 5..95, d100.
//  Sets _contract.m.ActorName (declare it). Returns { ok, actor, chance }.
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

	// COMPOSITION check: scores EVERY active brother, returns the BEST (highest net). No combat stats.
	// _traitMods/_bgMods are id->delta tables (FULL string ids, e.g. "trait.strong", "background.wildman");
	// _perkMods keyed by ::Legends.Perk DEFS (NOT "perk.x" strings -- hasPerk throws on a string).
	// _injuries is a string-id set, any of which costs -15. Returns { ok, actor, chance }, sets contract.m.ActorName.
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
		// GAMBLER'S GAMBLE: gambler scores 0 for selection; if the chosen actor IS a gambler, apply a
		// rand(-5..+5) swing here at resolution only (never during scoring). Lucky (the TRAIT) stays a flat +5.
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

	// AGILITY / DODGE -- nimblest active brother leads a physical feat (pit crossing, dodge).
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

	// PERCEPTION / SPOT -- sharpest-eyed active brother notices something. No perks.
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

	// BRAWN -- strongest active brother in a test of raw power.
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

	// HAND-EYE -- steadiest active brother in a test of aim (a thrown dagger).
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

	// NERVE -- steeliest active brother in a test of courage. No injury set.
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

	// GUILE -- coldest, sharpest card-player. gambler = 0 for selection (±5 gambler's-gamble swing); Lucky flat +5.
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

	// CHARM -- most magnetic active brother working a crowd. NOTE: Dumb is NOT a penalty here.
	function charm( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.bright"] = 6, ["trait.lucky"] = 5, ["trait.legend_seductive"] = 7, ["trait.legend_gift_of_people"] = 4 },   // gift_of_people = "Charming"
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

	// LOCKPICK -- deftest active brother springs a lock (Choking lockpick, Metringer descent, Azari crypt).
	function lockpick( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 16, ["trait.clumsy"] = -16 },
			{ ["background.thief"] = 26, ["background.graverobber"] = 14, ["background.killer_on_the_run"] = 14,
			  ["background.assassin"] = 16, ["background.assassin_southern"] = 16, ["background.vagabond"] = 8 },
			{ [::Legends.Perk.QuickHands] = 5 },
			this.handEyeInjuries());
		::Skv.dbg("Skv.Check.lockpick chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// DISARM -- steadiest active brother defuses a trap. Base is contract-set: scaledBase(50) if a prior
	// perception check spotted it, scaledBase(30) if the team went in blind.
	function disarm( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 8, ["trait.legend_steady_hands"] = 5, ["trait.lucky"] = 5,
			  ["trait.clumsy"] = -12, ["trait.hesitant"] = -4, ["trait.impatient"] = -4, ["trait.insecure"] = -4 },
			{ ["background.poacher"] = 15, ["background.hunter"] = 12, ["background.legend_inventor"] = 10,
			  ["background.thief"] = 9, ["background.ratcatcher"] = 7 },
			{ [::Legends.Perk.Nimble] = 2 },
			this.handEyeInjuries());
		::Skv.dbg("Skv.Check.disarm chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// SECRET DOOR -- who NOTICES hidden construction: lore/training-led (the diviner senses it, the
	// historian & mason know how it's built, the graverobber has opened sealed tombs), with a sharp or
	// suspicious eye helping on top.
	function secretDoor( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.eagle_eyes"] = 12, ["trait.bright"] = 8, ["trait.paranoid"] = 6,
			  ["trait.short_sighted"] = -12, ["trait.dumb"] = -8 },
			{ ["background.legend_diviner"] = 15, ["background.graverobber"] = 8,
			  ["background.historian"] = 7, ["background.mason"] = 7 },
			{},
			this.eyeInjuries());
		::Skv.dbg("Skv.Check.secretDoor chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// WITS -- cleverest scholar reads a text / mechanism. ONE shared table; _extraBg is an optional
	// {bgId = bonus} the caller passes so a specific gate leans on its own lead (star-chart -> astrologist,
	// golem -> inventor, reading -> historian). The bonus ADDS on top of the base weight.
	function wits( _contract, _base, _extraBg = null )
	{
		local bg = { ["background.historian"] = 16, ["background.legend_astrologist"] = 14,
			["background.legend_magister"] = 12, ["background.legend_philosopher"] = 12,
			["background.legend_inventor"] = 12, ["background.legend_diviner"] = 10 };
		if (_extraBg != null) foreach (id, d in _extraBg)
		{
			if (id in bg) bg[id] = bg[id] + d;
			else bg[id] <- d;
		}
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.bright"] = 12, ["trait.dumb"] = -10 },
			bg,
			{ [::Legends.Perk.LegendScholar] = 8 },
			[ "injury.brain_damage" ]);
		::Skv.dbg("Skv.Check.wits chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// REFLEX -- diving clear of a sudden hazard (a falling gantry). Where agility is innate balance, reflex
	// is TRAINED evasion: the dodge perks lead (Pathfinder-style -- Evasion is potent on a reflex save).
	function reflex( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 12, ["trait.lucky"] = 5, ["trait.legend_light"] = 5,
			  ["trait.quick"] = 2, ["trait.swift"] = 2, ["trait.athletic"] = 2,
			  ["trait.clumsy"] = -12, ["trait.clubfooted"] = -12, ["trait.fat"] = -12, ["trait.old"] = -5 },
			{ ["background.thief"] = 8, ["background.assassin"] = 8, ["background.assassin_southern"] = 8,
			  ["background.gladiator"] = 5, ["background.monk"] = 4,
			  ["background.belly_dancer"] = 3, ["background.juggler"] = 3,
			  ["background.brawler"] = -5, ["background.flagellant"] = -8, ["background.cripple"] = -15 },
			{ [::Legends.Perk.Dodge] = 15, [::Legends.Perk.LegendEvasion] = 10, [::Legends.Perk.Anticipation] = 5 },
			this.legInjuries());
		::Skv.dbg("Skv.Check.reflex chance=" + r.chance + " actor=" + _contract.m.ActorName);
		return r;
	}

	// Difficulty-scaled base: _base is the standard-difficulty anchor; swing is slope*(1 - DifficultyMult),
	// clamped 5-95. Honors the ::Skv.Cfg scaleChecks toggle -- OFF returns the anchor unchanged.
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
	function handEyeInjuries() { local a = this.handInjuries(); a.extend(this.eyeInjuries()); return a; }   // lockpick + disarm: a hurt hand OR eye costs the flat -15
	function legInjuries()  { return ["injury.pierced_leg_muscles", "injury.injured_knee_cap", "injury.broken_leg", "injury.burnt_legs", "injury.cut_leg_muscles", "injury.bruised_leg", "injury.sprained_ankle", "injury.broken_knee", "injury.maimed_foot"]; }
};

// ============================================================================
//  ::Skv.Cfg -- the mod's MSU settings. ONE frequency dial (faction-action m.Score,
//  0..10) shared by every Golarion contract; 0 = off. Reads are defensive (fall back
//  to DefaultScore, never throw out of an onUpdate tick).
//  WIRING (every Golarion *_action.nut onUpdate):
//     local sc = ::Skv.Cfg.score(); if (sc <= 0) return; ... gates ... this.m.Score = sc;
//  REGISTRATION: ::Skv.Cfg.register("mod_golarion", modVersion, modName); once.
// ============================================================================
::Skv.Cfg <- {

	Mod = null,          // ::MSU.Class.Mod handle, set by register()
	DefaultScore = 2,    // out-of-the-box weight AND the fallback when MSU is absent
	SettingID = "GolarionContractScore",

	// Check-XP actor share (0..100): % of awarded XP to the acting brother; rest split across active company.
	ActorShareID = "GolarionCheckActorShare",
	DefaultActorShare = 35,

	// Whether check bases scale with contract difficulty (::Skv.Check.scaledBase). Physical checks never scale.
	ScaleChecksID = "GolarionScaleChecks",
	DefaultScaleChecks = true,

	// Debug logging (via ::Skv.dbg): ON writes diagnostics to log.html. OFF for normal play.
	DebugLoggingID = "GolarionDebugLogging",
	DefaultDebugLogging = false,

	// Build the settings page. Called once from the mod's MSU queue; wrapped so it can't abort mod load.
	function register( _id, _version, _name )
	{
		try
		{
			// MSU's registry cross-checks the Mod version against the EXACT string mod_hooks recorded (throws
			// InvalidValue if they differ). Read the Hooks-recorded string when we can; fall back to _version.
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

	// Current shared weight, read fresh every tick; 0 => off. Falls back to DefaultScore, never throws.
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

	// Check-XP actor share (%), read fresh per check; same defensive shape as score(). Read by ::Skv.XP.grant.
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
//  ::Skv.Debug -- Dev-Console helpers (read-only inspection, safe any time).
//   ::Skv.Debug.contracts() / (true)  -- settlements' offered contracts (this mod's marked '*'); true = mod only.
//   ::skvc() / ::skvc(true)           -- short aliases.
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

	// Print every settlement's offered contracts, grouped by town; this mod's marked '*'. _onlyMine skips vanilla.
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

	// Azari gate diagnosis: once-flags + every temple-town and what's posted. Read-only. Run ::skvazari().
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

	// Ambush gate diagnosis: once-flags + every eligible hiring town and its readiness. Read-only. Run ::skvambush().
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

// When true, skv_ambush_action.onUpdate logs its decline reason per town. Toggle: ::skvambushdbg() / (false). Leave OFF.
::SkvAmbushDbg <- false;
::skvambushdbg <- function ( _on = true ) { ::SkvAmbushDbg = _on; ::Skv.dbg("SkvAmbushDbg = " + _on); return _on; };
