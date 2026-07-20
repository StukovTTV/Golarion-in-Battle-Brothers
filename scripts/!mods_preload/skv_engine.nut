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
		::logInfo("Skv.Check chance=" + chance + " roll=" + roll + " actor=" + _contract.m.ActorName);
		return { ok = roll <= chance, actor = actor, chance = chance };
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
			::logInfo("Skv.Cfg: settings registered (default score " + this.DefaultScore + ")");
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
		"contract.skv_azari", "contract.skv_metringer", "contract.skv_black_forks", "contract.skv_choking_tower",
		"contract.skv_den_hunt", "contract.legend_watchtower", "contract.legend_skulls_crossing"
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
};

// Short console aliases: ::skvc() = all contracts, ::skvc(true) = this mod's only.
::skvc <- function ( _onlyMine = false ) { return ::Skv.Debug.contracts(_onlyMine); };
::skvazari <- function () { return ::Skv.Debug.azari(); };
