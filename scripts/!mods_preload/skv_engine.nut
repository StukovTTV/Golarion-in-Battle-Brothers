if (!("Skv" in ::getroottable()))
{
	::Skv <- {};
}

::Skv.Verbose <- false;
::Skv.dbg <- function ( _s )
{
	local on = ::Skv.Verbose;
	if (!on) { try { on = ::Skv.Cfg.debugLogging(); } catch (e) {} }
	if (on) ::logInfo(_s);
};

::Skv.Loot <- {

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

	function grantCoin( _amount )
	{
		if (_amount <= 0) return null;
		::World.Assets.addMoney(_amount);
		return _amount + " crowns";
	}

	function pool( _pairs )
	{
		return ::MSU.Class.WeightedContainer(_pairs);
	}

	function color( _name )
	{
		return ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _name);
	}

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

	function haul( _items, _coin = 0, _prefix = "You gain " )
	{
		local rows = [];
		if (_items != null && _items.len() > 0)
		{
			local stash = ::World.Assets.getStash();
			stash.makeEmptySlots(_items.len());

			local grouped = [];
			local index = {};

			foreach (it in _items)
			{
				stash.add(it);
				local a = it.isAmountShown() ? it.getAmount() : 0;
				if (it.getID() in index)
				{
					local g = grouped[index[it.getID()]];
					g.count = g.count + 1;
					g.amount = g.amount + a;
					continue;
				}
				index[it.getID()] <- grouped.len();
				grouped.push({ item = it, count = 1, amount = a });
			}
			foreach (g in grouped)
			{
				local it = g.item;

				local qty = "";
				local amt = g.amount;
				if (amt > 0)
					qty = ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, "+" + amt) + " ";
				else if (g.count > 1)
					qty = g.count + "x ";
				rows.push({
					id = 1,
					icon = "ui/items/" + it.getIcon(),
					imageOverlayPath = it.getIconOverlay(),
					text = _prefix + qty + it.getName()
				});
			}
		}
		if (_coin > 0) rows.push(::Legends.EventList.changeMoney(_coin));
		return rows;
	}

	function previewRows( _paths, _coin = 0, _prefix = "You gain " )
	{
		local rows = [];
		foreach (it in this.make(_paths))
		{
			local qty = "";
			local amt2 = it.isAmountShown() ? it.getAmount() : 0;
			if (amt2 > 0)
				qty = ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, "+" + amt2) + " ";
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

::Skv.Once <- {

	function activeFlag( _key )  { return "SkvOnce." + _key + ".active"; }
	function retiredFlag( _key ) { return "SkvOnce." + _key + ".retired"; }

	function isLocked( _key )
	{
		return ::World.Flags.has(this.retiredFlag(_key)) || ::World.Flags.has(this.activeFlag(_key));
	}

	function claim( _key ) { ::World.Flags.set(this.activeFlag(_key), true); }

	function release( _key ) { ::World.Flags.remove(this.activeFlag(_key)); }

	function retire( _key ) { ::World.Flags.set(this.retiredFlag(_key), true); }

	function isRetired( _key ) { return ::World.Flags.has(this.retiredFlag(_key)); }
};

::Skv.Spawn <- {

	function fill( _into, _list, _budget, _fac, _label = "fight", _fallback = null, _minibossify = 0 )
	{
		local before = _into.len();
		::Const.World.Common.addUnitsToCombat(_into, _list, _budget, _fac, _minibossify);
		local got = _into.len() - before;

		if (got == 0)
		{
			if (_fallback != null)
			{
				::logError("Skv.Spawn: '" + _label + "' bought NOTHING at budget " + _budget
					+ " - falling back. EVERY ENTRY WAS FILTERED OUT: budget above every entry MaxR,"
					+ " or below every entry MinR before dateToSkip. NOT an affordability problem.");
				::Const.World.Common.addUnitsToCombat(_into, _fallback, _budget, _fac, _minibossify);
				got = _into.len() - before;
				if (got == 0)
					::logError("Skv.Spawn: '" + _label + "' FALLBACK ALSO BOUGHT NOTHING at budget "
						+ _budget + " - the player is about to walk onto an EMPTY BATTLEFIELD.");
			}
			else
			{
				::logError("Skv.Spawn: '" + _label + "' bought NOTHING at budget " + _budget
					+ " and no fallback was given - EMPTY BATTLEFIELD.");
			}
		}

		::Skv.dbg("Skv.Spawn: " + _label + " budget=" + _budget + " units=" + _into.len());
		return _into.len();
	}

	function check( _into, _label = "fight" )
	{
		if (_into.len() == 0)
		{
			::logError("Skv.Spawn: '" + _label + "' has NO units at combat start - EMPTY BATTLEFIELD.");
			return false;
		}
		::Skv.dbg("Skv.Spawn: " + _label + " starts with " + _into.len() + " unit(s).");
		return true;
	}
};

::Skv.Town <- {
	LastEnteredID = -1,

	function enter( _id )
	{
		this.LastEnteredID = _id;
		::Skv.dbg("Skv.Town: entered settlement id=" + _id);
	}

	function consume( _id )
	{
		if (this.LastEnteredID != _id)
		{
			return false;
		}
		this.LastEnteredID = -1;
		return true;
	}
};

::Skv.Econ <- {

	function wealth( _settlement, _lo, _hi )
	{
		if (_settlement == null)
		{
			::Skv.dbg("Skv.Econ.wealth: via=NONE (settlement is null) -> 1.0");
			return 1.0;
		}

		try
		{
			if (_settlement.isNull())
			{
				::Skv.dbg("Skv.Econ.wealth: via=NONE (settlement isNull) -> 1.0");
				return 1.0;
			}
		}
		catch (e) {}

		local w = null;
		local via = "legends";

		try { w = 0.01 * _settlement.getWealth(); }
		catch (e) { w = null; via = "fallback (getWealth threw: " + e + ")"; }

		if (w == null)
		{
			if (via == "legends") via = "fallback (getWealth gave null)";

			local baseline = 50.0;
			try { baseline += 50.0 * _settlement.getSize(); }
			catch (e)
			{
				::Skv.dbg("Skv.Econ.wealth: via=NONE (getSize threw: " + e + ") -> 1.0");
				return 1.0;
			}

			try { if (_settlement.isMilitary()) baseline += 50.0; } catch (e) {}
			try { if (::MSU.isKindOf(_settlement, "city_state")) baseline += 100.0; } catch (e) {}

			try { w = _settlement.getResources().tofloat() / baseline; }
			catch (e)
			{
				::Skv.dbg("Skv.Econ.wealth: via=NONE (getResources threw: " + e + ") -> 1.0");
				return 1.0;
			}

			via = via + " baseline=" + baseline;
		}

		if (w == null || w != w)
		{
			::Skv.dbg("Skv.Econ.wealth: via=NONE (result was not a number) -> 1.0");
			return 1.0;
		}

		local clamped = ::Math.maxf(_lo, ::Math.minf(_hi, w));
		::Skv.dbg("Skv.Econ.wealth: via=" + via + " raw=" + w + " clamped=" + clamped
			+ " [" + _lo + ".." + _hi + "]" + (clamped != w ? " CLAMPED" : ""));
		return clamped;
	}

	function pool( _contract, _base, _wealthLo = null, _wealthHi = null )
	{
		local w = 1.0;

		if (_wealthLo != null && _wealthHi != null)
		{
			local home = null;
			try { home = _contract.m.Home; } catch (e) { home = null; }
			w = this.wealth(home, _wealthLo, _wealthHi);
		}

		return _base * w
			* _contract.getPaymentMult()
			* ::Math.pow(_contract.getDifficultyMult(), ::Const.World.Assets.ContractRewardPOW)
			* _contract.getReputationToPaymentMult();
	}
};

::Skv.CheckVerbose <- false;

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
		::Skv.dbg("Skv.Check chance=" + chance + " roll=" + roll + (roll <= chance ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return { ok = roll <= chance, actor = actor, chance = chance, roll = roll };
	}

	function scoreBrother( _bro, _base, _traitMods, _bgMods, _perkMods, _injuries )
	{
		local sk = _bro.getSkills();
		local c = _base;
		foreach (id, d in _traitMods) if (sk.hasSkill(id)) c = c + d;
		local bg = _bro.getBackground();
		if (bg != null && (bg.getID() in _bgMods)) c = c + _bgMods[bg.getID()];
		foreach (id, d in _perkMods) if (sk.hasPerk(id)) c = c + d;
		foreach (inj in _injuries) if (sk.hasSkill(inj)) { c = c - 15; break; }
		return c;
	}

	function finalChance( _bro, _raw, _bgMods )
	{
		local c = _raw;
		if (_bro != null && ("background.gambler" in _bgMods))
		{
			local bg = _bro.getBackground();
			if (bg != null && bg.getID() == "background.gambler")
			{
				local swing = ::Math.rand(-5, 5);
				c = c + swing;
				::Skv.dbg("Skv.Check gambler's-gamble swing=" + swing + " actor=" + _bro.getName());
			}
		}
		return ::Math.max(5, ::Math.min(95, c));
	}

	function bestByComposition( _contract, _base, _traitMods, _bgMods, _perkMods, _injuries )
	{
		local best = null;
		local bestChance = -9999;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.isInReserves()) continue;
			local c = this.scoreBrother(bro, _base, _traitMods, _bgMods, _perkMods, _injuries);

			if (::Skv.CheckVerbose)
			{
				local bgd = bro.getBackground();
				::Skv.dbg("   " + bro.getName() + "  [" + (bgd != null ? bgd.getID() : "no-background") + "]  score=" + c);
			}
			if (c > bestChance) { bestChance = c; best = bro; }
		}
		if (best == null) bestChance = _base;
		local chance = this.finalChance(best, bestChance, _bgMods);
		local roll = ::Math.rand(1, 100);
		_contract.m.ActorName = (best != null ? best.getName() : "one of the company");
		return { ok = roll <= chance, actor = best, chance = chance, roll = roll };
	}

	function countByComposition( _contract, _base, _traitMods, _bgMods, _perkMods, _injuries, _needFraction = 0.5 )
	{
		local rows = [];
		local passed = 0;
		local total = 0;
		local sum = 0;
		local star = null;   local starChance = -9999;  local starRoll = 9999;
		local worst = null;  local worstChance = 9999;  local worstRoll = -9999;

		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.isInReserves()) continue;
			local raw = this.scoreBrother(bro, _base, _traitMods, _bgMods, _perkMods, _injuries);
			local chance = this.finalChance(bro, raw, _bgMods);
			local roll = ::Math.rand(1, 100);
			local ok = roll <= chance;
			local bg = bro.getBackground();

			total = total + 1;
			sum = sum + chance;
			if (ok) passed = passed + 1;

			if (ok && (star == null || chance > starChance || (chance == starChance && roll < starRoll)))
			{ starChance = chance;  starRoll = roll;  star = bro; }
			if (!ok && (worst == null || chance < worstChance || (chance == worstChance && roll > worstRoll)))
			{ worstChance = chance; worstRoll = roll; worst = bro; }

			rows.push({
				bro = bro,
				name = bro.getName(),
				bg = (bg != null ? bg.getID() : ""),
				chance = chance,
				roll = roll,
				ok = ok
			});

			if (::Skv.CheckVerbose)
				::Skv.dbg("   " + bro.getName() + "  [" + (bg != null ? bg.getID() : "no-background")
					+ "]  chance=" + chance + " roll=" + roll + (ok ? "  through" : "  CAUGHT"));
		}

		if (total == 0)
		{
			_contract.m.ActorName = "the company";

			return { ok = false, actor = null, star = null, worst = null, passed = 0, needed = 0, total = 0, avg = _base, rows = rows };
		}

		local want = total * _needFraction;
		local needed = want.tointeger();
		if (needed < want) needed = needed + 1;
		if (needed < 1) needed = 1;
		if (needed > total) needed = total;

		local ok = passed >= needed;

		local face = ok ? star : worst;
		_contract.m.ActorName = (face != null ? face.getName() : "the company");

		return {
			ok = ok, actor = face, star = star, worst = worst,
			passed = passed, needed = needed, total = total,
			avg = 1.0 * sum / total, rows = rows
		};
	}

	function agility( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 12, ["trait.sure_footing"] = 12, ["trait.lucky"] = 5, ["trait.legend_light"] = 5,
			  ["trait.clumsy"] = -12, ["trait.clubfooted"] = -12, ["trait.fat"] = -12, ["trait.old"] = -5 },
			{ ["background.belly_dancer"] = 7,
			  ["background.juggler"] = 3, ["background.assassin"] = 3, ["background.messenger"] = 3,
			  ["background.gambler"] = 0,
			  ["background.legend_blacksmith"] = -4, ["background.brawler"] = -4, ["background.butcher"] = -4,
			  ["background.farmhand"] = -4, ["background.milkmaid"] = -4, ["background.cripple"] = -12 },
			{ [::Legends.Perk.Dodge] = 15 },
			this.legInjuries());
		::Skv.dbg("Skv.Check.agility chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function perception( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.eagle_eyes"] = 12, ["trait.short_sighted"] = -12, ["trait.dumb"] = -8 },
			{ ["background.poacher"] = 12, ["background.hunter"] = 12,
			  ["background.ratcatcher"] = 10, ["background.thief"] = 8, ["background.witchhunter"] = 8 },
			{},
			this.eyeInjuries());
		::Skv.dbg("Skv.Check.perception chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function tracking( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.eagle_eyes"] = 12, ["trait.bright"] = 4, ["trait.old"] = 3,
			  ["trait.short_sighted"] = -12, ["trait.dumb"] = -8 },
			{ ["background.legend_ranger"] = 15, ["background.hunter"] = 12,
			  ["background.poacher"] = 9, ["background.beast_slayer"] = 9,
			  ["background.wildman"] = 6, ["background.legend_druid"] = 6,
			  ["background.manhunter"] = 6, ["background.legend_bounty_hunter"] = 6,
			  ["background.houndmaster"] = 6, ["background.shepherd"] = 3,
			  ["background.legend_berserker"] = -6, ["background.legend_berserker_commander"] = -6,
			  ["background.legend_commander_berserker"] = -6, ["background.barbarian"] = -6,
			  ["background.minstrel"] = -4, ["background.servant"] = -4 },
			{ [::Legends.Perk.Pathfinder] = 5 },
			this.eyeInjuries());
		::Skv.dbg("Skv.Check.tracking chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

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
		::Skv.dbg("Skv.Check.brawn chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

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
		::Skv.dbg("Skv.Check.handEye chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

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
		::Skv.dbg("Skv.Check.nerve chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function guile( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.bright"] = 12, ["trait.lucky"] = 5, ["trait.dumb"] = -8, ["trait.greedy"] = -2 },
			{ ["background.legend_diviner"] = 12, ["background.gambler"] = 0,
			  ["background.thief"] = 3, ["background.vagabond"] = 3 },
			{ [::Legends.Perk.Taunt] = 4, [::Legends.Perk.QuickHands] = 2 },
			[ "injury.crushed_finger", "injury.missing_finger", "injury.brain_damage" ]);
		::Skv.dbg("Skv.Check.guile chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function charm( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.bright"] = 6, ["trait.lucky"] = 5, ["trait.legend_seductive"] = 7, ["trait.legend_gift_of_people"] = 4 },
			{ ["background.legend_qiyan"] = 11, ["background.minstrel"] = 8, ["background.juggler"] = 8,
			  ["background.peddler"] = 4, ["background.servant"] = 2,
			  ["background.legend_berserker"] = -5, ["background.legend_berserker_commander"] = -5,
			  ["background.legend_commander_berserker"] = -5, ["background.brawler"] = -5,
			  ["background.legend_cannibal"] = -5, ["background.butcher"] = -5 },
			{},
			[ "injury.brain_damage" ]);
		::Skv.dbg("Skv.Check.charm chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function lockpick( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 16, ["trait.clumsy"] = -16 },
			{ ["background.thief"] = 26, ["background.graverobber"] = 14, ["background.killer_on_the_run"] = 14,
			  ["background.assassin"] = 16, ["background.assassin_southern"] = 16, ["background.vagabond"] = 8 },
			{ [::Legends.Perk.QuickHands] = 5 },
			this.handEyeInjuries());
		::Skv.dbg("Skv.Check.lockpick chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function disarm( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.dexterous"] = 8, ["trait.legend_steady_hands"] = 5, ["trait.lucky"] = 5,
			  ["trait.clumsy"] = -12, ["trait.hesitant"] = -4, ["trait.impatient"] = -4, ["trait.insecure"] = -4 },
			{ ["background.poacher"] = 15, ["background.hunter"] = 12, ["background.legend_inventor"] = 10,
			  ["background.thief"] = 9, ["background.ratcatcher"] = 7 },
			{ [::Legends.Perk.Nimble] = 2 },
			this.handEyeInjuries());
		::Skv.dbg("Skv.Check.disarm chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function secretDoor( _contract, _base )
	{
		local r = this.bestByComposition(_contract, _base,
			{ ["trait.eagle_eyes"] = 12, ["trait.bright"] = 8, ["trait.paranoid"] = 6,
			  ["trait.short_sighted"] = -12, ["trait.dumb"] = -8 },
			{ ["background.legend_diviner"] = 15, ["background.graverobber"] = 8,
			  ["background.historian"] = 7, ["background.mason"] = 7 },
			{},
			this.eyeInjuries());
		::Skv.dbg("Skv.Check.secretDoor chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

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
		::Skv.dbg("Skv.Check.wits chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
	}

	function reflex( _contract, _base, _need = null )
	{
		local traits =
			{ ["trait.dexterous"] = 12, ["trait.lucky"] = 5, ["trait.legend_light"] = 5,
			  ["trait.quick"] = 2, ["trait.swift"] = 2, ["trait.athletic"] = 2,
			  ["trait.clumsy"] = -12, ["trait.clubfooted"] = -12, ["trait.fat"] = -12, ["trait.old"] = -5 };
		local bgs =
			{ ["background.thief"] = 8, ["background.assassin"] = 8, ["background.assassin_southern"] = 8,
			  ["background.gladiator"] = 5, ["background.monk"] = 4,
			  ["background.belly_dancer"] = 3, ["background.juggler"] = 3,
			  ["background.brawler"] = -5, ["background.flagellant"] = -8, ["background.cripple"] = -15 };
		local perks = { [::Legends.Perk.Dodge] = 15, [::Legends.Perk.LegendEvasion] = 10,
			  [::Legends.Perk.Anticipation] = 5 };
		local inj = this.legInjuries();

		if (_need == null)
		{
			local rs = this.bestByComposition(_contract, _base, traits, bgs, perks, inj);
			::Skv.dbg("Skv.Check.reflex[one] chance=" + rs.chance + " roll=" + rs.roll + (rs.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
			return rs;
		}

		local rp = this.countByComposition(_contract, _base, traits, bgs, perks, inj, _need);
		::Skv.dbg("Skv.Check.reflex[party] " + rp.passed + "/" + rp.total + " clear, needed " + rp.needed
			+ ", avg=" + rp.avg + (rp.ok ? "  PASS" : "  FAIL -- " + _contract.m.ActorName + " was caught in the open"));
		return rp;
	}

	function stealth( _contract, _base, _need = null )
	{
		local traits =
			{ ["trait.legend_light"] = 12, ["trait.tiny"] = 10, ["trait.dexterous"] = 8,
			  ["trait.paranoid"] = 5, ["trait.quick"] = 2, ["trait.swift"] = 2,
			  ["trait.legend_heavy"] = -12, ["trait.fat"] = -12, ["trait.clumsy"] = -12,
			  ["trait.huge"] = -10, ["trait.asthmatic"] = -8, ["trait.clubfooted"] = -8,
			  ["trait.legend_prosthetic_leg"] = -8, ["trait.legend_prosthetic_foot"] = -8,
			  ["trait.drunkard"] = -5 };
		local bgs =
			{ ["background.poacher"] = 16,
			  ["background.thief"] = 14, ["background.thief_southern"] = 14,
			  ["background.assassin"] = 12, ["background.assassin_southern"] = 12,
			  ["background.ratcatcher"] = 8, ["background.hunter"] = 8,
			  ["background.killer_on_the_run"] = 8,
			  ["background.graverobber"] = 6, ["background.vagabond"] = 5,
			  ["background.cripple"] = -12, ["background.cripple_southern"] = -12,
			  ["background.hedge_knight"] = -8, ["background.flagellant"] = -5,
			  ["background.brawler"] = -4 };
		local perks = { [::Legends.Perk.LegendHidden] = 15, [::Legends.Perk.LegendLurker] = 8,
			  [::Legends.Perk.Nimble] = 3 };
		local inj = this.stealthInjuries();

		if (_need == null)
		{
			local rs = this.bestByComposition(_contract, _base, traits, bgs, perks, inj);
			::Skv.dbg("Skv.Check.stealth[scout] chance=" + rs.chance + " roll=" + rs.roll + (rs.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
			return rs;
		}

		local rp = this.countByComposition(_contract, _base, traits, bgs, perks, inj, _need);
		::Skv.dbg("Skv.Check.stealth[party] " + rp.passed + "/" + rp.total + " through, needed " + rp.needed
			+ ", avg=" + rp.avg + (rp.ok ? "  PASS" : "  FAIL -- " + _contract.m.ActorName + " gave you away"));
		return rp;
	}

	function scaledBase( _contract, _base, _slope = 50 )
	{
		local on = true;
		try { on = ::Skv.Cfg.scaleChecks(); } catch (e) { on = true; }
		if (!on) return ::Math.max(5, ::Math.min(95, _base));
		return ::Math.max(5, ::Math.min(95, _base + _slope * (1.0 - _contract.getDifficultyMult())));
	}

	function handInjuries() { return ["injury.smashed_hand", "injury.split_hand", "injury.pierced_hand", "injury.fractured_hand", "injury.burnt_hands", "injury.crushed_finger", "injury.missing_hand", "injury.missing_finger"]; }
	function eyeInjuries()  { return ["injury.grazed_eye_socket", "injury.missing_eye"]; }
	function handEyeInjuries() { local a = this.handInjuries(); a.extend(this.eyeInjuries()); return a; }

	function legInjuries()  { return ["injury.pierced_leg_muscles", "injury.injured_knee_cap", "injury.broken_leg", "injury.burnt_legs", "injury.cut_leg_muscles", "injury.bruised_leg", "injury.sprained_ankle", "injury.broken_knee", "injury.maimed_foot", "injury.cut_achilles_tendon"]; }

	function breathInjuries() { return ["injury.pierced_lung", "injury.collapsed_lung_part", "injury.crushed_windpipe", "injury.inhaled_flames", "injury.broken_ribs", "injury.fractured_ribs", "injury.exposed_ribs", "injury.cut_throat"]; }

	function stealthInjuries() { local a = this.legInjuries(); a.extend(this.breathInjuries()); return a; }
};

::Skv.Cfg <- {

	Mod = null,
	DefaultScore = 2,
	SettingID = "GolarionContractScore",

	ActorShareID = "GolarionCheckActorShare",
	DefaultActorShare = 35,

	CheckXPSoloID = "GolarionCheckXPSolo",
	DefaultCheckXPSolo = 75,
	CheckXPTeamID = "GolarionCheckXPTeam",
	DefaultCheckXPTeam = 50,

	MinOnlookerXP = 5,

	NorthRarity = 3,
	NobleRarity = 7,
	SouthRarity = 9,
	ScaleChecksID = "GolarionScaleChecks",
	DefaultScaleChecks = true,

	DebugLoggingID = "GolarionDebugLogging",
	DefaultDebugLogging = false,

	MovementMultID = "GolarionMovementMult",
	DefaultMovementMult = 50,

	VanillaGlobalMult = 0.75,

	FastForwardID = "GolarionFastForward",
	DefaultFastForward = 100,

	BaseFastMult     = null,
	BaseVeryFastMult = null,
	BaseEscortMult   = null,

	MarchDrainID          = "GolarionMarchDrain",
	DefaultMarchDrain     = 0.75,
	MarchRecoverID        = "GolarionMarchRecover",
	DefaultMarchRecover   = 3.0,
	MarchTownBonusID      = "GolarionMarchTownBonus",
	DefaultMarchTownBonus = 1.5,
	MarchCapID            = "GolarionMarchCap",
	DefaultMarchCap       = 75,
	MarchTavernID         = "GolarionMarchTavern",
	DefaultMarchTavern    = 1,

	function register( _id, _version, _name )
	{
		try
		{

			local ver = _version;
			try { local hm = ::Hooks.getMod(_id); if (hm != null) ver = hm.getVersionString(); } catch (e) {}
			this.Mod = ::MSU.Class.Mod(_id, ver, _name);
			local page = this.Mod.ModSettings.addPage("Contracts");
			page.addTitle("golarion_contracts_title", "Golarion Contracts");
			page.addRangeSetting(this.SettingID, this.DefaultScore, 0, 10, 1,
				"Contract frequency (weight)",
				"How often the mod's hand-authored contracts appear. This is the shared selection weight (m.Score) used by EVERY Golarion contract in the faction-action pick.\n\n[b]0[/b] = off (no Golarion contract is offered).\n[b]2[/b] = default.\nHigher = they win a settlement's contract slot more often.\n\nEach contract keeps its own rarity and eligibility gates; this only sets how heavily it weighs when it rolls.");
			page.addRangeSetting(this.ActorShareID, this.DefaultActorShare, 0, 100, 5,
				"Check XP: actor share (%)",
				"When a brother passes a skill check (a lockpick, a trapped passage, a reading), the contract awards a bit of experience.\n\nThis sets how much of it goes to the brother who actually did it; the rest is split evenly across the whole active company (everyone learns a little from watching).\n\n[b]35[/b] = default (about a third to the doer, the rest shared).\n[b]100[/b] = all to the doer.\n[b]0[/b] = split evenly across everyone.");
			page.addRangeSetting(this.CheckXPSoloID, this.DefaultCheckXPSolo, 0, 200, 5,
				"Check XP: one man's award",
				"Experience for a skill check that ONE brother makes on everyone's behalf, such as reading a ring, spotting a snare, picking a lock, creeping ahead to look.\n\nThis is the whole award for that check. How much of it goes to the brother who did it rather than to the company is the setting below.\n\n[b]75[/b] = default.\n[b]0[/b] = no experience from skill checks.");
			page.addRangeSetting(this.CheckXPTeamID, this.DefaultCheckXPTeam, 0, 200, 5,
				"Check XP: team effort, per brother",
				"Experience for a skill check EVERY brother has to make for himself, such as moving quietly past something asleep, crossing a market without being marked.\n\nThis is paid PER ACTIVE BROTHER and split evenly, so each man earns this much and the award does not get thinner as the company grows.\n\n[b]50[/b] = default. Deliberately lower than one man's award above: carrying a job for the whole company is worth more than doing your own share of one.");
			page.addBooleanSetting(this.ScaleChecksID, this.DefaultScaleChecks,
				"Scale skill checks with contract difficulty",
				"When ON, skill checks that scale (spotting a trap, reading a tome, picking a lock) get harder on higher-skull contracts and easier on low ones.\n\nWhen OFF, every such check sits at its own standard-difficulty value regardless of the contract's skull rating. Predictable mode.\n\nPhysical checks like crossing a pit are never affected either way.\n\n[b]On[/b] = default.");
			page.addBooleanSetting(this.DebugLoggingID, this.DefaultDebugLogging,
				"Debug logging (log.html)",
				"When ON, the mod writes diagnostics (skill-check chances and rolls, fight budgets, the gambler's-gamble swing) to log.html.\n\nLeave OFF for normal play. Turn it ON if you hit odd behaviour and want to report it, then send the log.\n\n[b]Off[/b] = default.");

			local world = this.Mod.ModSettings.addPage("World");
			world.addTitle("golarion_world_title", "Golarion World");
			local movement = world.addRangeSetting(this.MovementMultID, this.DefaultMovementMult, 10, 100, 5,
				"Travel speed (%)",
				"[b]100 = unchanged. LOWER IS SLOWER.[/b] This is a travel speed, not a world size, so turning it DOWN is what makes the world feel larger.\n\nIt sets how fast EVERY party crosses the world map -- yours and everyone else's, by the same factor. The map stays the same size and the towns stay where they are; only the time between them changes.\n\n[b]100[/b] = the game's normal speed, nothing altered.\n[b]50[/b] = default, half speed, a journey takes twice the days.\n[b]10[/b] = a tenth, for a very long campaign.\n\nEveryone slows together, so nothing outruns you that could not before, and no enemy becomes easier to escape.\n\n[b]Contract deadlines stretch automatically[/b] -- the game works out travel time using this same number, so a job is never made impossible by moving the slider.\n\n⚠ [b]What it does NOT slow is time.[/b] Wages and food are paid by the day, so at 50 percent a long journey costs roughly twice the crowns and twice the bread it used to. Distance having a price is the point, but it is a real cost. Fast-forward only skips the waiting, not the days.\n\n[b]Comparing two settings?[/b] Count the DAYS a journey takes, not how long it feels. Fast-forward, roads (x1.5), night (x0.75) and terrain all change the feel without changing what the slider did.\n\nTakes effect immediately and can be changed at any point in a campaign.");

			local wired = false;

			try { movement.addAfterChangeCallback(function ( _oldValue ) { ::Skv.Cfg.applyMovement(); }); wired = true; }
			catch (e) {}

			if (!wired)
			{
				try { movement.addCallback(function ( _newValue ) { ::Skv.Cfg.applyMovement(_newValue); }); wired = true; }
				catch (e) {}
			}

			if (!wired)
			{
				::logError("Skv.Cfg: no usable MSU change callback -- travel speed will only apply at load.");
			}

			local fastfwd = world.addRangeSetting(this.FastForwardID, this.DefaultFastForward, 100, 300, 25,
				"Fast-forward strength (%)",
				"[b]100 = unchanged.[/b] How much ground the fast-forward buttons cover per second of YOUR time. This is the tedium dial, and it is not the same thing as the travel speed above.\n\nTravel speed changes how many DAYS a journey costs your company. Fast-forward changes only how long you sit watching it. Raising this does not make anything cheaper: the same days pass, the same food is eaten, the same wages are paid, and everyone else on the map moves faster with you.\n\n[b]100[/b] = default, the speeds Legends set.\n[b]200[/b] = twice as brisk, which cancels a travel setting of 50.\n[b]300[/b] = three times.\n\nAffects the fast and very fast buttons and the forced speed during escort contracts. Camping is left alone, because that is a rest you chose rather than a wait you endured.\n\n⚠ At high values the game world advances in bigger jumps between checks, so it is possible to sweep past something you would rather have noticed. If you start missing encounters, come back down.");

			local wiredFF = false;

			try { fastfwd.addAfterChangeCallback(function ( _oldValue ) { ::Skv.Cfg.applyFastForward(); }); wiredFF = true; }
			catch (e) {}

			if (!wiredFF)
			{
				try { fastfwd.addCallback(function ( _newValue ) { ::Skv.Cfg.applyFastForward(_newValue); }); wiredFF = true; }
				catch (e) {}
			}

			if (!wiredFF)
			{
				::logError("Skv.Cfg: no usable MSU change callback -- fast-forward will only apply at load.");
			}

			world.addTitle("golarion_march_title", "March Fatigue");

			world.addRangeSetting(this.MarchDrainID, this.DefaultMarchDrain, 0.0, 2.0, 0.25,
				"Fatigue lost per hour on the road (%)",
				"Every hour the company spends travelling costs it this much of its MAXIMUM fatigue. Nobody becomes slower or less able; there is simply less strength left in them when the fighting starts.\n\n[b]0.75[/b] = default. A full day of marching costs 18 points, so one hard day is felt and two are a problem.\n[b]0[/b] = turn the drain off and keep the recovery, if you only want camping to be worth something.\n\nThe clock stops while you are inside a settlement, so shopping, haggling and hiring cost nothing at all.\n\n⚠ This is the pressure half of the system. The cure is below.");

			world.addRangeSetting(this.MarchRecoverID, this.DefaultMarchRecover, 0.0, 8.0, 0.5,
				"Fatigue regained per hour in camp (%)",
				"What making camp gives back, per hour. This is the only real cure, which is the entire point of the feature.\n\n[b]3.0[/b] = default. An ordinary eight hour night in camp returns 24 points and therefore pays for roughly thirty-two hours on the road, so a company that makes camp each night will hardly notice any of this.\n\nRaise it if you would rather camp briefly and often. Lower it if you want a forced march to be a decision you live with for days.");

			world.addRangeSetting(this.MarchTownBonusID, this.DefaultMarchTownBonus, 1.0, 3.0, 0.25,
				"Camping near a settlement, recovery bonus",
				"A multiplier on the recovery above when the camp is pitched within three tiles of a friendly settlement. Hot food, a fire somebody else built, a roof for any man who wants one, and a short walk to a bed for those who can pay for it.\n\n[b]1.5[/b] = default, so the standard 3.0 becomes 4.5 an hour.\n[b]1.0[/b] = no bonus, one camp is as good as another.\n\nThree tiles is the game's own reckoning of a town's reach: it is the same radius the base game uses to decide that the men enjoyed the visit. Any settlement that is not hostile to you counts, hamlet or fortress alike.");

			local marchCap = world.addRangeSetting(this.MarchCapID, this.DefaultMarchCap, 0, 90, 5,
				"Worst it can get (% of fatigue lost)",
				"The floor. However long the march, the company never loses more than this much of its maximum fatigue.\n\n⚠ [b]This is the amount LOST, not the amount left.[/b] 75 means a brother fights on a QUARTER of his usual fatigue: a man with 130 goes down to 32.\n\n[b]75[/b] = default. Reaching it takes about a hundred unbroken hours of marching, four days without once making camp, and climbing back out of it costs a full day in camp.\n[b]25[/b] = a steady tax that one night's camp erases.\n[b]0[/b] = switches the whole system off, and takes it off the company immediately.\n\nNothing else in the game is touched. Initiative, resolve, health and skill are all exactly what they were.");

			local wiredCap = false;

			try { marchCap.addAfterChangeCallback(function ( _oldValue ) { try { ::Skv.March.reconcile(); } catch (e) {} }); wiredCap = true; }
			catch (e) {}

			if (!wiredCap)
			{
				try { marchCap.addCallback(function ( _newValue ) { try { ::Skv.March.reconcile(); } catch (e) {} }); wiredCap = true; }
				catch (e) {}
			}

			if (!wiredCap)
			{
				::Skv.dbg("Skv.Cfg: march ceiling has no change callback -- it will apply on the next hourly tick instead of instantly.");
			}

			world.addRangeSetting(this.MarchTavernID, this.DefaultMarchTavern, 0, 10, 1,
				"A round of drinks at the tavern gives back (%)",
				"Buying the company a round in a tavern puts a little strength back into them. Once per day, however many taverns you visit.\n\n[b]1[/b] = default. Deliberately small: it is worth about eighty minutes of marching. A gesture rather than a plan, and no substitute for making camp.\n[b]0[/b] = drinking is for morale only, as it was.\n\nThe crowns, the drunkenness and the mood are all unchanged; this is added on top of what the round already did.");

			this.applyFastForward();

			this.applyMovement();

			::Skv.dbg("Skv.Cfg: settings registered (default score " + this.DefaultScore + ")");
		}
		catch (e)
		{
			::logError("Skv.Cfg.register failed (settings unavailable, using default score): " + e);
			this.Mod = null;
		}
	}

	function applyMovement( _pct = null )
	{
		try
		{

			local vanilla = this.VanillaGlobalMult;
			local pct     = this.DefaultMovementMult;

			if (_pct != null)
			{
				pct = _pct;
			}
			else if (this.Mod != null)
			{
				local st = this.Mod.ModSettings.getSetting(this.MovementMultID);
				if (st != null) pct = st.getValue();
			}

			::Const.World.MovementSettings.GlobalMult = vanilla * (pct / 100.0);
			::Skv.dbg("Skv.Cfg: travel speed " + pct + "% -> GlobalMult "
				+ ::Const.World.MovementSettings.GlobalMult + " (vanilla " + vanilla + ")");
		}
		catch (e)
		{
			::logError("Skv.Cfg.applyMovement failed (world speed left as-is): " + e);
		}
	}

	function applyFastForward( _pct = null )
	{
		try
		{
			local ss = ::Const.World.SpeedSettings;

			if (this.BaseFastMult == null)     this.BaseFastMult     = ss.FastMult;
			if (this.BaseVeryFastMult == null) this.BaseVeryFastMult = ss.VeryFastMult;
			if (this.BaseEscortMult == null)   this.BaseEscortMult   = ss.EscortMult;

			local pct = this.DefaultFastForward;

			if (_pct != null)
			{
				pct = _pct;
			}
			else if (this.Mod != null)
			{
				local st = this.Mod.ModSettings.getSetting(this.FastForwardID);
				if (st != null) pct = st.getValue();
			}

			local scale = pct / 100.0;
			ss.FastMult     = this.BaseFastMult * scale;
			ss.VeryFastMult = this.BaseVeryFastMult * scale;
			ss.EscortMult   = this.BaseEscortMult * scale;

			::Skv.dbg("Skv.Cfg: fast-forward " + pct + "% -> Fast " + ss.FastMult
				+ ", VeryFast " + ss.VeryFastMult + ", Escort " + ss.EscortMult
				+ " (base " + this.BaseFastMult + " / " + this.BaseVeryFastMult + " / " + this.BaseEscortMult + ")");
		}
		catch (e)
		{
			::logError("Skv.Cfg.applyFastForward failed (speed tiers left as-is): " + e);
		}
	}

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

	function checkXPSolo()
	{
		if (this.Mod == null) return this.DefaultCheckXPSolo;
		try
		{
			local s = this.Mod.ModSettings.getSetting(this.CheckXPSoloID);
			if (s == null) return this.DefaultCheckXPSolo;
			return s.getValue();
		}
		catch (e)
		{
			::logError("Skv.Cfg.checkXPSolo failed (using default): " + e);
			return this.DefaultCheckXPSolo;
		}
	}

	function checkXPTeam()
	{
		if (this.Mod == null) return this.DefaultCheckXPTeam;
		try
		{
			local s = this.Mod.ModSettings.getSetting(this.CheckXPTeamID);
			if (s == null) return this.DefaultCheckXPTeam;
			return s.getValue();
		}
		catch (e)
		{
			::logError("Skv.Cfg.checkXPTeam failed (using default): " + e);
			return this.DefaultCheckXPTeam;
		}
	}

	function rarity( _faction )
	{
		try
		{
			if (_faction != null)
			{
				local t = _faction.getType();
				if (t == ::Const.FactionType.OrientalCityState) return this.SouthRarity;
				if (t == ::Const.FactionType.NobleHouse)        return this.NobleRarity;
			}
		}
		catch (e)
		{
			::logError("Skv.Cfg.rarity failed (using the northern rate): " + e);
		}
		return this.NorthRarity;
	}

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

	function marchNumber( _id, _fallback )
	{
		if (this.Mod == null) return _fallback;
		try
		{
			local s = this.Mod.ModSettings.getSetting(_id);
			if (s == null) return _fallback;
			local v = s.getValue();
			if (v == null) return _fallback;
			return v;
		}
		catch (e)
		{
			return _fallback;
		}
	}

	function marchDrain()     { return this.marchNumber(this.MarchDrainID,     this.DefaultMarchDrain);     }
	function marchRecover()   { return this.marchNumber(this.MarchRecoverID,   this.DefaultMarchRecover);   }
	function marchTownBonus() { return this.marchNumber(this.MarchTownBonusID, this.DefaultMarchTownBonus); }
	function marchCap()       { return this.marchNumber(this.MarchCapID,       this.DefaultMarchCap);       }
	function marchTavern()    { return this.marchNumber(this.MarchTavernID,    this.DefaultMarchTavern);    }

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

::Skv.Debug <- {

	Types = [
		"contract.skv_azari", "contract.skv_ambush", "contract.skv_metringer", "contract.skv_black_forks",
		"contract.skv_choking_tower", "contract.skv_den_hunt", "contract.legend_watchtower", "contract.legend_skulls_crossing",
		"contract.skv_carthica", "contract.skv_hollows", "contract.skv_anvil", "contract.skv_threshold",
		"contract.skv_zoldos", "contract.skv_fortress", "contract.skv_torment"
	],

	function isMine( _type )
	{
		foreach (t in this.Types) if (_type == t) return true;
		return false;
	}

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

	thresholdSurvey = function ()
	{
		local out = [];
		local pt = null;
		try { pt = ::World.State.getPlayer().getTile(); } catch (e) { pt = null; }

		foreach (s in ::World.EntityManager.getSettlements())
		{
			local fac = null;
			try { fac = ::World.FactionManager.getFaction(s.getFaction()); } catch (e) { continue; }
			if (fac == null) continue;
			if (fac.getType() != ::Const.FactionType.OrientalCityState) continue;

			local why = null;
			try
			{

				if (!fac.isReadyForContract())            why = "not ready";
				else if (fac.hasContractExclusion("contract.skv_threshold")) why = "excluded";
				else if (s.isIsolated())                  why = "isolated";
				else if (s.getSize() < 2)                 why = "size < 2";
			}
			catch (e) { why = "ERR:" + e; }

			local d = -1;
			try { if (pt != null) d = pt.getDistanceTo(s.getTile()); } catch (e) { d = -1; }

			out.push({ S = s, D = d, Size = s.getSize(), Disc = s.isDiscovered(), Why = why });
		}
		return out;
	},

	thresholdLive = function ()
	{
		foreach (s in ::World.EntityManager.getSettlements())
		{
			foreach (c in s.getContracts())
			{
				if (c.getType() == "contract.skv_threshold") return { C = c, S = s };
			}
		}
		return null;
	},

	roam = function ( _budget = 105, _casters = true )
	{
		if (!("World" in ::getroottable()) || ::World == null)
		{
			::logError("Skv.Debug.roam: no world loaded - load a campaign first.");
			return;
		}

		local fac = null;
		try { fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Goblins); }
		catch (e) { fac = null; }
		if (fac == null)
		{
			::logError("Skv.Debug.roam: no greenskin faction in this world.");
			return;
		}

		local pt = ::World.State.getPlayer().getTile();
		local dest = ::Skv.Debug.freeTileNearPlayer();

		local list = _casters ? ::Const.World.Spawn.GolarionKoboldsCasters
		                      : ::Const.World.Spawn.GolarionKobolds;

		local party = null;
		try
		{
			party = fac.spawnEntity(dest, "Kobold Warband", false, list, _budget);
		}
		catch (e)
		{
			::logError("Skv.Debug.roam: spawnEntity threw - " + e);
			return;
		}

		::Skv.Debug.quietTestParty(party);

		try { party.setDescription("A test warband. It should not be here."); } catch (e) {}
		try { party.setDiscovered(true); } catch (e) {}

		::logInfo(">> Skv.Debug.roam: " + list.Name + " at budget " + _budget
			+ " spawned at " + dest.Coords.X + "," + dest.Coords.Y
			+ " (player at " + pt.Coords.X + "," + pt.Coords.Y + ")");
		::logInfo("   roster: " + ::Skv.Debug.rosterOf(party));
	},

	bog = function ( _budget = 105 )
	{
		if (!("World" in ::getroottable()) || ::World == null)
		{
			::logError("Skv.Debug.bog: no world loaded - load a campaign first.");
			return;
		}

		local fac = null;
		try { fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Beasts); }
		catch (e) { fac = null; }
		if (fac == null)
		{
			::logError("Skv.Debug.bog: no beast faction in this world.");
			return;
		}

		if (!("GolarionTroglodyteRoamers" in ::Const.World.Spawn))
		{
			::logError("Skv.Debug.bog: GolarionTroglodyteRoamers is not registered -- config/79_troglodytes.nut did not load.");
			return;
		}

		local pt = ::World.State.getPlayer().getTile();
		local dest = ::Skv.Debug.freeTileNearPlayer();
		local list = ::Const.World.Spawn.GolarionTroglodyteRoamers;

		local party = null;
		try
		{
			party = fac.spawnEntity(dest, "Troglodyte Test Band", false, list, _budget);
		}
		catch (e)
		{
			::logError("Skv.Debug.bog: spawnEntity threw - " + e);
			return;
		}

		::Skv.Debug.quietTestParty(party);

		try { party.setDescription("A test band out of the bog. It should not be here."); } catch (e) {}
		try { party.setDiscovered(true); } catch (e) {}

		::logInfo(">> Skv.Debug.bog: " + list.Name + " at budget " + _budget
			+ " spawned at " + dest.Coords.X + "," + dest.Coords.Y
			+ " (player at " + pt.Coords.X + "," + pt.Coords.Y + ")");
		::logInfo("   roster: " + ::Skv.Debug.rosterOf(party));
	},

	brushes = function ( _prefix = "bust_ghoul", _max = 12 )
	{
		if (_prefix == null || _prefix == "")
		{
			::logError("Skv.Debug.brushes: give it a prefix, e.g. ::skvbrush(\"bust_ghoul_04\").");
			return;
		}

		local probe = function ( _name )
		{
			try { return ::doesBrushExist(_name); } catch (e) { return false; }
		};

		local canary = false;
		try { canary = ::doesBrushExist("bust_ghoul_body_01"); } catch (e) { canary = false; }

		if (!canary)
		{
			::logError("Skv.Debug.brushes: ::doesBrushExist did not confirm a brush we KNOW exists (bust_ghoul_body_01). Every result below would be meaningless, so nothing was probed.");
			return;
		}

		local hits = [];

		if (probe(_prefix)) hits.push(_prefix);

		for( local i = 1; i <= _max; i = i + 1 )
		{
			local plain  = _prefix + "_" + i;
			local padded = _prefix + "_" + (i < 10 ? "0" : "") + i;

			if (probe(plain)) hits.push(plain);
			if (padded != plain && probe(padded)) hits.push(padded);
		}

		if (hits.len() == 0)
		{
			::logInfo(">> Skv.Debug.brushes: nothing registered under '" + _prefix + "' or its first " + _max + " numbered siblings.");
			return;
		}

		local out = "";
		foreach (h in hits) out = out + (out == "" ? "" : ", ") + h;
		::logInfo(">> Skv.Debug.brushes: " + hits.len() + " under '" + _prefix + "' -- " + out);
	},

	fxset = function ( _key = null, _value = null )
	{
		if (!("Skv" in ::Const) || !("FXStenchScale" in ::Const.Skv))
		{
			::logError("Skv.Debug.fxset: config/81_fx.nut did not load.");
			return;
		}

		if (_key == null)
		{
			::logInfo(">> Skv.Debug.fxset: the dials, all live and all writable.");

			foreach (k, v in ::Const.Skv)
			{
				if (k.len() > 2 && k.slice(0, 2) == "FX") ::logInfo("   " + k + " = " + (v == null ? "null" : v));
			}

			::logInfo("   ::skvfxset('Scale', 1.4) sets FXStenchScale and repaints.");
			return;
		}

		local key = "FXStench" + _key;
		if (!(key in ::Const.Skv)) key = _key;

		if (!(key in ::Const.Skv))
		{
			::logError("Skv.Debug.fxset: no dial called '" + _key + "' or 'FXStench" + _key + "'. ::skvfxset() lists them.");
			return;
		}

		local was = ::Const.Skv[key];
		::Const.Skv[key] = _value;

		::logInfo(">> Skv.Debug.fxset: " + key + " " + (was == null ? "null" : was) + " -> " + (_value == null ? "null" : _value));

		this.repaintAndReport();
	},

	repaintAndReport = function ()
	{
		if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null) return;
		if (!("StenchFX" in ::Skv)) return;

		::Skv.StenchFX.LastRound = -999;

		try { ::Skv.StenchFX.repaint(); }
		catch (e) { ::logError("Skv.Debug.fxset: repaint threw - " + e); return; }

		::logInfo("   " + ::Skv.StenchFX.LastSources + " source(s), "
			+ ::Skv.StenchFX.LastTiles + " visible aura tile(s), "
			+ ::Skv.FX.LastStainDecals + " decal(s) laid, "
			+ ::Skv.StenchFX.LastEmitters + " emitter(s) spawned.");

		if (::Skv.StenchFX.LastSources == 0)
			::logInfo("   no source: nothing on the field carries " + ::Skv.Stench.RacialID + ".");
		else if (::Skv.StenchFX.LastTiles == 0)
			::logInfo("   sources but no tiles: every neighbour failed IsVisibleForPlayer.");
		else
		{
			if (::Skv.FX.LastStainDecals == 0)
				::logInfo("   tiles but no decals: spawnDetail is refusing the flies brushes.");
			if (::Skv.StenchFX.LastEmitters == 0)
				::logInfo("   tiles but no emitters: the Miasma pool or its entry [0] is missing.");
		}
	},

	fx = function ( _name = null )
	{
		if (!("Tactical" in ::Const))
		{
			::logError("Skv.Debug.fx: ::Const.Tactical does not exist.");
			return;
		}

		local known = [
			"TerrainDropdown", "RaiseFromGround", "Dust", "GruesomeFeast", "Smoke",
			"Miasma", "Lich", "Fire", "Burn", "Acid", "HandgonneRight"
		];

		if (_name == null)
		{
			local present = "";
			local absent = "";

			foreach (n in known)
			{
				if ((n + "Particles") in ::Const.Tactical) present = present + (present == "" ? "" : ", ") + n;
				else absent = absent + (absent == "" ? "" : ", ") + n;
			}

			::logInfo(">> Skv.Debug.fx: pools present -- " + (present == "" ? "none" : present));
			if (absent != "") ::logInfo("   absent -- " + absent);

			try
			{
				if ("FliesDecals" in ::Const)
				{
					local d = "";
					foreach (b in ::Const.FliesDecals) d = d + (d == "" ? "" : ", ") + b;
					::logInfo("   Const.FliesDecals (" + ::Const.FliesDecals.len() + ") -- " + d);
				}
				else
				{
					::logError("   Const.FliesDecals is NOT registered -- the stench stain in hooks/66 will find nothing to paint.");
				}
			}
			catch (e)
			{
				::logError("   could not read Const.FliesDecals: " + e);
			}

			::logInfo("   ::skvfx(\"Miasma\") for one pool's contents.");
			return;
		}

		local key = _name + "Particles";

		if (!(key in ::Const.Tactical))
		{
			::logError("Skv.Debug.fx: no pool called " + key + ". ::skvfx() lists them.");
			return;
		}

		local pool = ::Const.Tactical[key];
		::logInfo(">> Skv.Debug.fx: " + key + " has " + pool.len() + " entr(y/ies).");

		foreach (i, entry in pool)
		{
			try
			{
				local brushes = "";
				if ("Brushes" in entry)
				{
					foreach (b in entry.Brushes) brushes = brushes + (brushes == "" ? "" : ", ") + b;
				}

				::logInfo("   [" + i + "] brushes = " + (brushes == "" ? "none" : brushes));

				local line = "        ";
				foreach (k, v in entry)
				{
					if (k == "Brushes" || k == "Stages") continue;
					line = line + k + "=" + v + "  ";
				}
				::logInfo(line);

				if (!("Stages" in entry) || entry.Stages == null)
				{
					::logInfo("        stages = none");
					continue;
				}

				::logInfo("        stages = " + entry.Stages.len());

				foreach (s, stage in entry.Stages)
				{

					local keys = "";
					foreach (k, v in stage) keys = keys + (keys == "" ? "" : ", ") + k;
					::logInfo("          stage " + s + ": " + keys);
				}
			}
			catch (e)
			{
				::logError("   [" + i + "] could not be read: " + e);
			}
		}
	},

	quietTestParty = function ( _party )
	{
		try
		{
			_party.getFlags().set("IsMercenaries", false);
		}
		catch (e)
		{
			::logError("Skv.Debug: could not quiet the test party, expect faction.nut errors on the world map - " + e);
		}
	},

	freeTileNearPlayer = function ()
	{
		local pt = ::World.State.getPlayer().getTile();

		for( local i = 0; i != 6; i = ++i )
		{
			if (!pt.hasNextTile(i)) continue;
			local t = pt.getNextTile(i);

			for( local step = 0; step != 2; step = ++step )
			{
				local ok = false;
				try
				{
					ok = !t.IsOccupied
						&& t.Type != ::Const.World.TerrainType.Impassable
						&& t.Type != ::Const.World.TerrainType.Ocean
						&& t.Type != ::Const.World.TerrainType.Mountains;
				}
				catch (e) { ok = false; }

				if (ok) return t;
				if (!t.hasNextTile(i)) break;
				t = t.getNextTile(i);
			}
		}

		return pt;
	},

	rosterOf = function ( _party )
	{
		local counts = {}, order = [];

		try
		{
			foreach (t in _party.getTroops())
			{
				local n = "?";
				try { n = ::Const.Strings.EntityName[t.ID]; } catch (e) { n = "id:" + t.ID; }
				if (!(n in counts)) { counts[n] <- 0; order.push(n); }
				counts[n] = counts[n] + 1;
			}
		}
		catch (e) { return "(could not read roster: " + e + ")"; }

		local line = "";
		foreach (n in order) line = line + (line == "" ? "" : ", ") + counts[n] + "x " + n;
		return line == "" ? "EMPTY" : line;
	},

	band = function ( _troop = "Bomber", _count = 4, _casters = true )
	{
		if (!("World" in ::getroottable()) || ::World == null)
		{
			::logError("Skv.Debug.band: no world loaded - load a campaign first.");
			return;
		}

		local key = _troop;
		if (!(key in ::Const.World.Spawn.Troops)) key = "SkvKobold" + _troop;

		if (!(key in ::Const.World.Spawn.Troops))
		{

			local known = "";
			foreach (k, v in ::Const.World.Spawn.Troops)
			{
				if (k.len() > 3 && k.slice(0, 3) == "Skv")
				{
					known = known + (known == "" ? "" : ", ") + k;
				}
			}
			::logError("Skv.Debug.band: no troop '" + _troop + "'. Known: " + known);
			return;
		}

		local def = ::Const.World.Spawn.Troops[key];

		local fac = null;
		try { fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Goblins); }
		catch (e) { fac = null; }
		if (fac == null)
		{
			::logError("Skv.Debug.band: no greenskin faction in this world.");
			return;
		}

		local pt   = ::World.State.getPlayer().getTile();
		local dest = ::Skv.Debug.freeTileNearPlayer();
		local list = _casters ? ::Const.World.Spawn.GolarionKoboldsCasters
		                      : ::Const.World.Spawn.GolarionKobolds;

		local party = null;
		try
		{
			party = fac.spawnEntity(dest, "Kobold Test Band", false, list, 1);
		}
		catch (e)
		{
			::logError("Skv.Debug.band: spawnEntity threw - " + e);
			return;
		}

		try { party.getTroops().clear(); }
		catch (e) { ::logError("Skv.Debug.band: could not clear the seeded roster, expect stray kobolds - " + e); }

		local added = 0;
		for( local i = 0; i != _count; i = ++i )
		{
			try
			{
				::Const.World.Common.addTroop(party, { Type = def }, false);
				added = added + 1;
			}
			catch (e)
			{
				::logError("Skv.Debug.band: addTroop threw - " + e);
				break;
			}
		}

		::Skv.Debug.quietTestParty(party);

		try { party.updateStrength(); } catch (e) {}
		try { party.setDescription("A test band. It should not be here."); } catch (e) {}
		try { party.setDiscovered(true); } catch (e) {}

		::logInfo(">> Skv.Debug.band: " + added + "x " + key
			+ " spawned at " + dest.Coords.X + "," + dest.Coords.Y
			+ " (player at " + pt.Coords.X + "," + pt.Coords.Y + ")");
		::logInfo("   roster: " + ::Skv.Debug.rosterOf(party));
	}
};

::skvc <- function ( _onlyMine = false ) { return ::Skv.Debug.contracts(_onlyMine); };
::skvazari <- function () { return ::Skv.Debug.azari(); };
::skvambush <- function () { return ::Skv.Debug.ambush(); };

::skvroam <- function ( _budget = 105, _casters = true ) { return ::Skv.Debug.roam(_budget, _casters); };

::skvbog <- function ( _budget = 105 ) { return ::Skv.Debug.bog(_budget); };

::skvbrush <- function ( _prefix = "bust_ghoul", _max = 12 ) { return ::Skv.Debug.brushes(_prefix, _max); };

::skvfx <- function ( _name = null ) { return ::Skv.Debug.fx(_name); };

::skvfxset <- function ( _key = null, _value = null ) { return ::Skv.Debug.fxset(_key, _value); };

::skvband <- function ( _troop = "Bomber", _count = 4, _casters = true ) { return ::Skv.Debug.band(_troop, _count, _casters); };

::skvcheck <- function ( _flavor = "stealth", _base = 45, _need = null )
{
	if (!("World" in ::getroottable()) || ::World == null)
	{
		::logInfo("Skv.check: not in a campaign.");
		return null;
	}
	if (!(_flavor in ::Skv.Check))
	{
		::logInfo("Skv.check: no flavor named '" + _flavor + "'. Try: stealth, perception, agility,"
			+ " brawn, handEye, nerve, guile, charm, lockpick, disarm, secretDoor, wits, reflex, tracking.");
		return null;
	}

	local fake = { m = { ActorName = "" } };

	local hadVerbose = ::Skv.Verbose;
	local hadDump    = ::Skv.CheckVerbose;
	::Skv.Verbose = true;
	::Skv.CheckVerbose = true;

	::logInfo("== Skv.Check." + _flavor + "  base=" + _base
		+ (_need == null ? "  [SCOUT -- best man acts]" : "  [PARTY -- need " + _need + " of the roster]")
		+ "  -- every ACTIVE brother, scored ==");

	local r = null;
	try
	{

		if (_need == null) r = ::Skv.Check[_flavor].call(::Skv.Check, fake, _base);
		else               r = ::Skv.Check[_flavor].call(::Skv.Check, fake, _base, _need);
	}
	catch (e)
	{
		::logError("Skv.check: " + _flavor + " threw - " + e
			+ (_need != null ? "   (does '" + _flavor + "' take a third argument? only stealth does)" : ""));
	}

	::Skv.Verbose = hadVerbose;
	::Skv.CheckVerbose = hadDump;

	if (r == null) return null;

	if (_need == null)
	{
		::logInfo("  SENT: " + fake.m.ActorName + "   chance=" + r.chance + "   roll=" + r.roll
			+ (r.ok ? "   PASS" : "   FAIL"));
		if (r.actor == null)
			::logInfo("  ⚠ NOBODY QUALIFIED -- chance fell back to the bare base. Empty or all-reserve roster?");
	}
	else
	{

		::logInfo("  " + r.passed + " of " + r.total + " got through; needed " + r.needed
			+ "   avg chance " + r.avg + (r.ok ? "   PASS" : "   FAIL"));
		::logInfo(r.ok
			? "  led by: " + fake.m.ActorName
			: "  gave you away: " + fake.m.ActorName);
		::logInfo("  ⚠ A count of many rolls is MUCH steadier than one roll. A big company will"
			+ " land near its average every time; a small band is where the swing lives.");
	}
	return r;
};

::skvthreshold <- function ( _force = false )
{
	if (!("World" in ::getroottable()) || ::World == null || ::World.Contracts == null)
	{
		::logInfo("Skv.threshold: not in a campaign.");
		return null;
	}

	if (_force)
	{
		::Skv.Once.release("Threshold");
		::World.Flags.remove("SkvOnce.Threshold.retired");
	}

	local sites = ::Skv.Debug.thresholdSurvey();
	local open = [];
	foreach (e in sites) if (e.Why == null) open.push(e);
	local existing = ::Skv.Debug.thresholdLive();

	::logInfo("== Skv.Threshold (contract #12) ==");
	::logInfo("  once.active=" + ::World.Flags.has("SkvOnce.Threshold.active")
		+ " once.retired=" + ::World.Flags.has("SkvOnce.Threshold.retired")
		+ (::Skv.Once.isLocked("Threshold") ? "  << BLOCKING" : ""));
	::logInfo("  score=" + ::Skv.Cfg.score() + (::Skv.Cfg.score() <= 0 ? "  << BLOCKING (dial is off)" : ""));
	::logInfo("  city-states found = " + sites.len() + " (expect 3), of which " + open.len() + " can host now");
	if (sites.len() == 0)
	{
		::logInfo("  ⚠ NO CITY-STATE FOUND. Either the world has none (check 50_city_states.nut loaded)"
			+ " or the faction type test is wrong - this contract cannot post at all.");
	}
	foreach (e in sites)
	{
		::logInfo("    " + (e.Why == null ? "OK  " : "--  ") + e.S.getName()
			+ "  " + (e.D < 0 ? "?" : e.D + "") + " tiles  size " + e.Size
			+ (e.Disc ? "  discovered" : "  UNDISCOVERED")
			+ (e.Why == null ? "" : "  [" + e.Why + "]"));
	}
	::logInfo("  live copy = " + (existing == null ? "none" : "at " + existing.S.getName()));

	if (existing != null)
	{
		try
		{
			local m = existing.C.m;
			::logInfo("  -- act " + m.Act + (m.Concluded ? "  CONCLUDED" : "") + (m.Aborted ? "  ABORTED" : ""));
			::logInfo("     ladder = " + existing.C.rungCount() + "/6  (bits " + m.Advantage + ")"
				+ "   KnowsRune=" + m.KnowsRune + "   bead=" + m.HasBracelet + "   scale=" + m.HasCharms);
			::logInfo("     act I: gift=" + m.GiftDone + " beetles=" + m.Beetles
				+ " mask=" + m.FoundMask + " notes=" + m.FoundNotes + " tracks=" + m.Footprints
				+ " chase=" + m.ChaseStep + " (" + m.ChaseWins + " won, pick " + m.ChasePick + ")"
				+ " door=" + m.DoorGate + "/4 tries=" + m.DoorTries + " hint=" + m.DoorHint
				+ " key=" + m.DoorKey + " rune=" + m.RuneLesson);
			::logInfo("     act II: gusa=" + m.Gusa + " kobolds=" + m.Kobolds + " swim=" + m.Swim
				+ " jubo=" + m.Jubo + " approach=" + m.Approach + " reads=" + m.Act2Reads
				+ " grotto=" + m.GrottoPick + " watched=" + m.Watched
				+ " ngajaDead=" + m.NgajaDead + " ot=" + m.OtFound + " students=" + m.Students
				+ " flipped=" + m.Flipped);
			::logInfo("     act III: clockDay=" + m.ClockDay + " spent=" + m.HoursSpent
				+ "h limit=" + m.HoursLimit + "h runes=" + m.RunesDone + " outcome=" + m.Outcome);
			::logInfo("     ⚠ act I states: 0 untried · 1 tried and MISSED · 2 found."
				+ " beetles 3 = looked and missed. chase 6 = resolved, either way.");
			::logInfo("     ⚠ act II states: gusa 1 talked down / 2 killed / 3 would not be talked round."
				+ " kobolds 3 = repulsed once (the retry is cheaper). jubo 1 snuck / 2 WOKE (it joins the"
				+ " grotto) / 3 driven off. grotto 3 = driven off the shelf, quiet way only.");

			::logInfo("     ⚠ reads= is a BITFIELD: 1 rubble read tried · 2 rubble read PASSED"
				+ " · 4 the act III hazard has fired · 8 Okulou's pack taken (the sickle).");
		}
		catch (e)
		{
			::logError("Skv.threshold: state dump failed (the gate report above is still good): " + e);
		}
	}
	::logInfo("  ⚠ NOT VISIBLE HERE: the 12% rarity roll and the action's 14-day cooldown."
		+ " Both are re-rolled per faction tick; neither leaves a flag. Use (true) to bypass them.");

	if (!_force)
	{
		return existing == null ? null : existing.C;
	}

	if (existing != null)
	{
		::logInfo("Skv.threshold: already posted at " + existing.S.getName() + " - not posting a second.");
		return existing.C;
	}
	if (open.len() == 0)
	{
		::logInfo("Skv.threshold: no city-state can take it. See the reasons above.");
		return null;
	}

	local s = open[0].S;
	local f = ::World.FactionManager.getFaction(s.getFaction());

	::Skv.Once.claim("Threshold");
	local c = ::new("scripts/contracts/contracts/skv_threshold_contract");
	c.setFaction(f.getID());
	c.setHome(s);
	c.setEmployerID(f.getRandomCharacter().getID());
	::World.Contracts.addContract(c);

	local posted = ::Skv.Debug.thresholdLive();
	if (posted == null)
	{
		::Skv.Once.release("Threshold");
		::logError("Skv.threshold: addContract accepted nothing at " + s.getName() + ".");
		return null;
	}

	::logInfo("Skv.threshold: posted at " + posted.S.getName() + ", " + open[0].D + " tiles away.");
	return posted.C;
};

::skvwinPending <- false;

::skvwin <- function ()
{
	if (!("Tactical" in getroottable()) || ::Tactical == null || ::Tactical.State == null)
	{
		::logInfo("Skv.win: not in a tactical fight.");
		return -1;
	}

	if (::skvwinPending)
	{
		::logInfo("Skv.win: already armed, waiting for projectiles to land.");
		return 0;
	}

	::skvwinPending = true;

	::Time.scheduleEvent(::TimeUnit.Real, 1200, function ( _data )
	{
		::skvwinPending = false;

		if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
		{
			::logInfo("Skv.win: fight ended before the kill fired.");
			return;
		}

		local factions = ::Tactical.Entities.m.Instances;
		local killed = 0;

		for ( local f = ::Const.Faction.Player + 1; f < factions.len(); f = f + 1 )
		{
			if (factions[f].len() == 0 || ::World.FactionManager.isAlliedWithPlayer(f))
			{
				continue;
			}

			foreach (e in clone factions[f])
			{
				if (e == null) continue;
				try { e.kill(); killed = killed + 1; }
				catch (err) { ::logError("Skv.win: " + err); }
			}
		}

		::logInfo("Skv.win: killed " + killed + " enemies.");
	}, null);

	::logInfo("Skv.win: armed, killing in 1200ms so anything in flight lands first.");
	return 0;
};

::skvhollows <- function ()
{
	if (!("World" in getroottable()) || ::World == null || ::World.Contracts == null)
	{
		::logInfo("Skv.hollows: not in a campaign.");
		return null;
	}

	local c = null;
	try { c = ::World.Contracts.getActiveContract(); } catch (err) { c = null; }
	if (c == null || c.getType() != "contract.skv_hollows")
	{
		c = null;
		foreach (s in ::World.EntityManager.getSettlements())
		{
			foreach (k in s.getContracts())
			{
				if (k.getType() == "contract.skv_hollows") { c = k; break; }
			}
			if (c != null) break;
		}
	}

	if (c != null)
	{
		local m = c.m;
		local d = -1;
		try
		{
			if (m.Home != null && !m.Home.isNull())
			{

				d = m.Home.getDistanceTo(::World.State.getPlayer());
			}
		}
		catch (e)
		{
			::logError("Skv.hollows: distance failed - " + e);
			d = -2;
		}

		::logInfo("== Skv.Hollows ==");
		::logInfo("  state=" + c.getState() + "  reported=" + m.Reported + "  failed=" + m.Failed);
		::logInfo("  moss=" + m.HasMoss + "  tail=" + m.HasTail + "  ironbloom=" + m.Mushrooms + "/7  haveAll=" + (m.HasMoss && m.HasTail && m.Mushrooms >= 7));
		::logInfo("  atSite='" + m.AtSite + "'  room='" + m.Room + "'  hoursSpent=" + m.HoursSpent + "  dead=" + m.Dead);
		::logInfo("  distance to employer = " + d + "  (isPlayerAt fires at <= 150)");
		::logInfo("  graypelt=" + m.GraypeltDead + "  bargain=" + m.Bargain + "  errands=" + m.Errands + "  ring=" + m.HasRing);
		return;
	}

	::logInfo("Skv.hollows: no Hollow's Last Hope contract is active.");
};

::skvhollowsreport <- function ()
{
	local c = ::skvhollows();
	if (c == null)
	{
		return false;
	}
	c.m.Reported = true;
	c.setScreen(c.m.Failed ? "ReportFailed" : "Report");
	::World.Contracts.setActiveContract(c);
	::World.Contracts.showActiveContract();
	::logInfo("Skv.hollows: forced the report screen.");
	return true;
};

::skvench <- function ( _path = "scripts/items/weapons/hand_axe", _tier = 1, _masterwork = false )
{
	if (!("GolarionEnchant" in ::getroottable()))
	{
		::logInfo("Skv.ench: the enhancement config is not loaded.");
		return null;
	}

	local item = null;
	try { item = ::new(_path); }
	catch (e) { ::logError("Skv.ench: cannot create '" + _path + "': " + e); return null; }
	if (item == null) return null;

	if (!::GolarionEnchant.isEligible(item))
	{
		::logInfo("Skv.ench: " + item.getName() + " cannot take an enhancement (weapons and ammo only).");
	}
	else if (_tier > 0)
	{
		::GolarionEnchant.apply(item, _tier);
	}
	else if (_masterwork)
	{
		::GolarionEnchant.setMasterwork(item, true);
	}

	local stash = ::World.Assets.getStash();
	stash.makeEmptySlots(1);
	stash.add(item);

	local mw = "n/a";
	try { mw = item.isMasterwork() ? "true" : "false"; } catch (e) { mw = "n/a"; }

	::logInfo("Skv.ench: " + item.getName() + "  value=" + item.getValue()
		+ "  enchant=" + ::GolarionEnchant.get(item)
		+ "  masterwork=" + mw);
	return item;
};

::skvenchset <- function ( _path = "scripts/items/weapons/hand_axe" )
{
	::skvench(_path, 0, false);
	::skvench(_path, 0, true);
	for ( local i = 1; i <= 5; i = i + 1 )
	{
		::skvench(_path, i, false);
	}
	::logInfo("Skv.ench: seven copies of " + _path + " are in the stash.");
	return true;
};

::Skv.Anvil <- {
	Key     = "MasterOfTheAnvil",
	Flag    = "SkvAnvil.NextDay",
	Type    = "contract.skv_anvil",
	Forges  = ["building.weaponsmith", "building.armorsmith",
	           "building.weaponsmith_oriental", "building.armorsmith_oriental"],

	function noblesAware()
	{
		try
		{
			local a = ::World.Ambitions.getAmbition("ambition.make_nobles_aware");
			return a != null && a.isDone();
		}
		catch (e) { ::logError("Skv.anvil: make_nobles_aware lookup threw - " + e); }
		return false;
	}

	function hasForge( _s )
	{
		foreach (b in this.Forges)
		{
			try { if (_s.hasBuilding(b)) return true; }
			catch (e) { ::logError("Skv.anvil: hasBuilding('" + b + "') threw - " + e); }
		}
		return false;
	}

	function survey()
	{
		local out = [];

		local p = ::World.State.getPlayer().getTile();

		foreach (s in ::World.EntityManager.getSettlements())
		{
			if (!this.hasForge(s)) continue;

			local d = s.getTile().getDistanceTo(p);

			local mil = false;
			try { mil = s.isMilitary(); }
			catch (e) { ::logError("Skv.anvil: isMilitary threw at " + s.getName() + " - " + e); }

			local why = null;
			if (s.isIsolated()) why = "isolated";
			else if (mil && !::Skv.Anvil.noblesAware())
				why = "military - waiting on the make_nobles_aware ambition";
			else
			{
				local f = ::World.FactionManager.getFaction(s.getFaction());

				local ready = false;
				try
				{
					ready = f.getType() == ::Const.FactionType.Settlement
						? f.isReadyForContract(::Const.Contracts.ContractCategoryMap.skv_anvil_contract)
						: f.isReadyForContract();
				}
				catch (e) { ::logError("Skv.anvil: isReadyForContract threw at " + s.getName() + " - " + e); }
				if (!ready) why = "no free Economy/Wildcard slot (or on contract cooldown)";
			}

			out.push({ S = s, D = d, Why = why, Mil = mil, Size = s.getSize() });
		}
		out.sort(@(x, y) x.D <=> y.D);
		return out;
	}

	function live()
	{
		foreach (s in ::World.EntityManager.getSettlements())
			foreach (k in s.getContracts())
				if (k.getType() == this.Type) return { C = k, S = s };
		return null;
	}
};

::skvanvil <- function ( _force = false )
{
	if (!("World" in ::getroottable()) || ::World == null || ::World.Contracts == null)
	{
		::logInfo("Skv.anvil: not in a campaign.");
		return null;
	}
	if (!("GolarionEnchant" in ::getroottable()))
	{
		::logInfo("Skv.anvil: the enhancement config is not loaded - the config chain died earlier.");
		return null;
	}

	local A = ::Skv.Anvil;

	if (_force)
	{

		if (::GolarionEnchant.findMostDamaged() == null)
		{
			local it = ::skvench("scripts/items/weapons/longsword", 2);
			if (it != null)
			{
				it.setCondition(::Math.floor(it.getConditionMax() * 0.35));
				::logInfo("Skv.anvil: seeded " + it.getName() + " at "
					+ it.getCondition() + "/" + it.getConditionMax() + " condition.");
			}
		}

		::World.Flags.remove(A.Flag);
		::Skv.Once.release(A.Key);
	}

	local day  = ::World.getTime().Days;
	local next = ::World.Flags.has(A.Flag) ? ::World.Flags.get(A.Flag) : null;
	local worst = ::GolarionEnchant.findMostDamaged();
	local sites = A.survey();
	local open  = [];
	foreach (e in sites) if (e.Why == null) open.push(e);
	local existing = A.live();

	::logInfo("== Skv.Anvil ==");
	::logInfo("  day=" + day + "  cooldown=" + (next == null ? "not set" : "until day " + next
		+ (day < next ? "  << BLOCKING (" + (next - day) + "d)" : "  (expired)")));
	::logInfo("  once-lock=" + (::Skv.Once.isLocked(A.Key) ? "LOCKED << BLOCKING" : "free")
		+ "  score=" + ::Skv.Cfg.score() + (::Skv.Cfg.score() <= 0 ? "  << BLOCKING (dial is off)" : ""));
	::logInfo("  worst enhanced item = " + (worst == null
		? "NONE << BLOCKING (nothing damaged and enhanced in roster or stash)"
		: worst.getName() + "  condition " + worst.getCondition() + "/" + worst.getConditionMax()
			+ "  fee " + ::Math.floor(worst.getValue() * 0.5)));
	local civ = 0;
	local civOpen = 0;
	foreach (e in sites)
	{
		if (!e.Mil) civ = civ + 1;
		if (!e.Mil && e.Why == null) civOpen = civOpen + 1;
	}

	::logInfo("  forge towns = " + sites.len() + " (" + civ + " civilian, " + (sites.len() - civ)
		+ " military), of which " + open.len() + " can take a contract now (" + civOpen + " civilian)");
	::logInfo("  make_nobles_aware = " + (A.noblesAware() ? "DONE (military boards open too)"
		: "not done (military boards closed to this contract)"));
	if (civ == 0)
		::logInfo("  ⚠ NO CIVILIAN FORGE TOWN EXISTS IN THIS WORLD - the contract cannot post at all.");
	else if (civOpen == 0)
		::logInfo("  ⚠ Every civilian forge town has a full board right now. Normal on a fresh world"
			+ " (civilian boards seed full, military ones do not); slots churn as contracts are taken.");
	foreach (e in sites)
		::logInfo("    " + (e.Why == null ? "OK  " : "--  ") + e.S.getName()
			+ "  " + e.D + " tiles  size " + e.Size + (e.Mil ? "  MILITARY" : "  civilian")
			+ (e.Why == null ? "" : "  [" + e.Why + "]"));
	::logInfo("  live copy = " + (existing == null ? "none" : "at " + existing.S.getName()));

	if (!_force)
	{
		return existing == null ? null : existing.C;
	}

	if (existing != null)
	{
		::logInfo("Skv.anvil: already posted at " + existing.S.getName() + " - not posting a second.");
		return existing.C;
	}
	if (open.len() == 0)
	{
		::logInfo("Skv.anvil: no town can take it. Clear a contract from a forge town's board and retry.");
		return null;
	}

	local s = open[0].S;
	local f = ::World.FactionManager.getFaction(s.getFaction());

	::Skv.Once.claim(A.Key);
	local c = ::new("scripts/contracts/contracts/skv_anvil_contract");
	c.setFaction(f.getID());
	c.setHome(s);
	c.setEmployerID(f.getRandomCharacter().getID());
	::World.Contracts.addContract(c);

	local posted = A.live();
	if (posted == null)
	{
		::Skv.Once.release(A.Key);
		::logError("Skv.anvil: addContract accepted nothing - Legends dropped it on the category slots.");
		return null;
	}

	::logInfo("Skv.anvil: posted at " + posted.S.getName() + ", " + open[0].D + " tiles away.");
	return posted.C;
};

::skvfortress <- function ( _force = false )
{
	if (!("World" in ::getroottable()) || ::World == null || ::World.Contracts == null)
	{
		::logInfo("Skv.fortress: not in a campaign.");
		return null;
	}

	if (_force)
	{
		::Skv.Once.release("Fortress");
		::World.Flags.remove("SkvOnce.Fortress.retired");
	}

	local act = null;
	try { act = ::new("scripts/factions/contracts/skv_fortress_action"); }
	catch (e) { ::logInfo("Skv.fortress: could not build the action (" + e + ")"); act = null; }

	local sc = ::Skv.Cfg.score();
	local locked = ::Skv.Once.isLocked("Fortress");

	local held = 0;
	if (act != null)
	{
		try { held = act.heldBack(); }
		catch (e) { held = 0; }
	}

	::logInfo("== Skv.Fortress (contract #14) ==");
	if (held == 0) ::logInfo("  RELEASED (0.99.28) -- posts on its own when the gates below pass.");

	if (held > 0)
	{
		::logInfo("  ⚠⚠ HELD BACK ON PURPOSE -- #14 is UNFINISHED and cannot post itself.");
		::logInfo("     effective score = " + sc + " - " + held + " = " + (sc - held)
			+ "   << BLOCKING, and nothing below it is ever reached.");
		::logInfo("     The rooms are one-line placeholders; the tower walks but nothing in it fights.");
		::logInfo("     ::skvfortress(true) STILL POSTS IT -- it bypasses onUpdate entirely.");
		::logInfo("     To release it: return 0 from heldBack() in skv_fortress_action.nut.");
	}

	::logInfo("  THE GATE STACK -- every one of these must pass, cheapest first:");
	::logInfo("    1 score dial      = " + sc + (sc <= 0 ? "        << BLOCKING (all Golarion contracts are off)" : "        ok")
		+ (held > 0 ? "   (moot -- held back above)" : ""));
	::logInfo("    2 once/campaign   active=" + ::World.Flags.has("SkvOnce.Fortress.active")
		+ " retired=" + ::World.Flags.has("SkvOnce.Fortress.retired")
		+ (locked ? "   << BLOCKING" : "   ok"));
	::logInfo("    3 readiness       per faction -- category slot in the north, vanilla's 2/3 cap + 4-day delay in the south");
	::logInfo("    4 canHost         size >= 2 and not isolated");
	::logInfo("    5 exclusion       per faction");
	::logInfo("    6 rarity roll     3% at a settlement, 9% at a city-state -- THE SLOW ONE, and it rolls every tick");
	::logInfo("  NOT gated on renown, terrain, a situation, or the day. That is deliberate:");
	::logInfo("  #14 is the board's entry-level delve. 'No renown gate' is NOT 'no gates'.");

	local open = [];
	local live = null;
	local total = 0;
	local shown = 0;

	try
	{
		local ac = ::World.Contracts.getActiveContract();
		if (ac != null && ac.getType() == "contract.skv_fortress")
		{
			local h = null;
			try { h = ac.m.Home; } catch (e) { h = null; }
			live = { S = h, C = ac, Active = true };
		}
	}
	catch (e) { }

	foreach (s in ::World.EntityManager.getSettlements())
	{
		foreach (c in s.getContracts())
		{
			if (c.getType() == "contract.skv_fortress" && live == null) live = { S = s, C = c, Active = false };
		}

		total = total + 1;

		local fac = null;
		try { fac = ::World.FactionManager.getFaction(s.getFaction()); } catch (e) { fac = null; }

		local ok = false;
		if (act != null)
		{
			try { ok = act.canHostFaction(fac) && act.canHost(s); }
			catch (e) { ::logInfo("Skv.fortress: canHost threw - " + e); act = null; }
		}
		if (act == null)
		{
			local t = -1;
			try { t = fac.getType(); } catch (e) { t = -1; }
			ok = (t == ::Const.FactionType.Settlement || t == ::Const.FactionType.OrientalCityState)
				&& !s.isIsolated() && s.getSize() >= 2;
		}

		if (!ok) continue;
		open.push(s);

		if (shown < 8)
		{
			shown = shown + 1;
			local f = fac;
			local ready = "?";
			try
			{
				if (f.getType() == ::Const.FactionType.Settlement)
					ready = f.isReadyForContract(::Const.Contracts.ContractCategoryMap.skv_fortress_contract) ? "yes" : "NO";
				else
					ready = f.isReadyForContract() ? "yes" : "NO";
			}
			catch (e) { ready = "threw"; }

			local excl = "?";
			try { excl = f.hasContractExclusion("contract.skv_fortress") ? "EXCLUDED" : "-"; }
			catch (e) { excl = "threw"; }

			::logInfo("    OK  " + s.getName() + "  size " + s.getSize()
				+ "  ready=" + ready + "  excl=" + excl
				+ "  rarity=" + ::Skv.Cfg.rarity(f) + "%");
		}
	}

	::logInfo("  " + open.len() + " of " + total + " settlements pass canHost."
		+ (act == null ? "   [verdict: LOCAL COPY -- the action would not build]" : "   [verdict: the action's own canHost]"));
	if (live != null)
	{
		local where = "somewhere";
		try { where = live.S != null && !live.S.isNull() ? live.S.getName() : "no home set"; }
		catch (e) { where = "no home set"; }
		::logInfo("  LIVE at " + where + " -- \"" + live.C.getName() + "\""
			+ (live.Active ? "   [ACCEPTED -- read from World.Contracts, not a board]" : "   [on the board]"));
	}
	else ::logInfo("  not posted anywhere yet. ::skvfortress(true) posts it directly.");

	if (live != null)
	{
		try
		{
			local c = live.C;

			::logInfo("  ---- the spine ----  state=" + c.getActiveState().ID
				+ "  Rooms=" + c.m.Rooms + " Found=" + c.m.Found + " Access=" + c.m.Access + " Alert=" + c.m.Alert + "%");
			::logInfo("    stair=" + (c.hasAccess(0x01) ? "OPEN (the Armoury is done)" : "blocked")
				+ "  secretDoor=" + (c.hasAccess(0x04) ? "found" : "not found")
				+ "  keys=" + (c.hasAccess(0x02) ? "held" : "not held")
				+ "  Balenar=" + c.m.Balenar);

			local nxt = c.nextRoom();
			foreach (r in c.rooms())
			{
				local mark;
				if (c.hasRoom(r.Bit))       mark = "done";
				else if (r.Bit == nxt)      mark = "NEXT";
				else if (!c.isSpine(r.Bit)) mark = (c.templeOpen() ? "OPEN" : "shut");
				else                        mark = "  . ";

				::logInfo("    " + mark + "  area " + (r.Area < 10 ? " " : "") + r.Area
					+ "  floor " + r.Floor + "  " + r.Title
					+ (c.isSpine(r.Bit) ? "" : "   << the one branch off the line"));
			}

			if (nxt == 0) ::logInfo("    the tower is walked out -- the hub offers the road home.");
		}
		catch (e)
		{
			::logInfo("  ---- the spine ----  could not be read (" + e + ")");
		}
	}

	if (!_force) return live == null ? null : live.C;

	if (live != null)
	{
		::logInfo("Skv.fortress: already posted at " + live.S.getName() + " - not posting a second.");
		return live.C;
	}
	if (open.len() == 0)
	{
		::logInfo("Skv.fortress: no settlement can host it.");
		return null;
	}

	local ready = [];
	foreach (h in open)
	{
		local hf = ::World.FactionManager.getFaction(h.getFaction());
		local r = false;
		try
		{
			if (hf.getType() == ::Const.FactionType.Settlement)
				r = hf.isReadyForContract(::Const.Contracts.ContractCategoryMap.skv_fortress_contract);
			else
				r = hf.isReadyForContract();
		}
		catch (e) { r = true; }
		if (r) ready.push(h);
	}

	local pool = ready.len() > 0 ? ready : open;
	if (ready.len() == 0)
	{
		::logInfo("Skv.fortress: NO host has a free Battle/Wildcard slot -- trying anyway, and it may be refused.");
	}

	local s = pool[::Math.rand(0, pool.len() - 1)];
	local f = ::World.FactionManager.getFaction(s.getFaction());

	::Skv.Once.claim("Fortress");
	local c = ::new("scripts/contracts/contracts/skv_fortress_contract");
	c.setFaction(f.getID());
	c.setHome(s);
	c.setEmployerID(f.getRandomCharacter().getID());
	::World.Contracts.addContract(c);
	::logInfo("Skv.fortress: posted at " + s.getName() + ".");
	return c;
};

::skvden <- function ( _rolls = 5 )
{
	if (!("World" in ::getroottable()) || ::World == null)
	{
		::logInfo("Skv.den: not in a campaign.");
		return;
	}

	local den = null;
	try
	{
		foreach (l in ::World.EntityManager.getLocations())
		{
			if (l.getTypeID() == "location.skv_den") { den = l; break; }
		}
	}
	catch (e)
	{
		::logInfo("Skv.den: could not walk the location list (" + e + ")");
	}

	local live = den != null;
	if (!live)
	{
		try { den = ::new("scripts/entity/world/locations/legendary/skv_den_location"); }
		catch (e)
		{
			::logInfo("Skv.den: could not build a Den at all (" + e + ")");
			return;
		}
	}

	local scale = 1.0;
	try { scale = den.m.LootScale; } catch (e) { scale = -1.0; }

	::logInfo("== Skv.Den loot ==  " + (live ? "the LIVE Den on this map" : "a THROWAWAY instance -- no Den on this map, LootScale is the 1.0 default")
		+ "   LootScale=" + scale);
	::logInfo("  Calling the real onDropLootForPlayer. Up to 0.99.4 this threw here, every time:");
	::logInfo("    \"the index '0' does not exist\"  --  dropTreasure with an EMPTY list.");

	local grand = 0;
	local items = 0;

	local tally = {};
	local lo = -1;
	local hi = -1;

	for( local r = 1; r <= _rolls; r = r + 1 )
	{
		local loot = [];

		try
		{
			den.onDropLootForPlayer(loot);
		}
		catch (e)
		{
			::logInfo("  roll " + r + ":  STILL THROWING -- " + e);
			if (!live) ::logInfo("    (on a throwaway instance -- re-run on a map that has the Den before believing this)");
			return;
		}

		local line = "";
		local worth = 0;

		foreach (it in loot)
		{
			local nm = it.getName();
			line = line + (line == "" ? "" : ", ") + nm;
			if (nm in tally) tally[nm] = tally[nm] + 1;
			else tally[nm] <- 1;
			try { worth = worth + it.getValue(); } catch (e) { }
		}

		items = items + loot.len();
		grand = grand + worth;
		if (lo < 0 || worth < lo) lo = worth;
		if (worth > hi) hi = worth;

		::logInfo("  roll " + r + ":  " + loot.len() + " item(s), base value " + worth
			+ "   " + (line == "" ? "(nothing)" : line));
	}

	::logInfo("  " + _rolls + " rolls, NO THROW. " + items + " items total, "
		+ (items > 0 ? (grand / _rolls) + " base value per roll on average." : "which is itself worth a look."));

	if (items > 0)
	{

		::logInfo("  worst haul " + lo + ", best " + hi
			+ (lo > 0 ? "  (" + (hi / lo) + "x spread)" : ""));

		local rows = [];
		foreach (k, v in tally) rows.push({ N = k, C = v });
		rows.sort(function ( a, b ) { return b.C <=> a.C; });

		::logInfo("  WHAT ACTUALLY CAME OUT -- " + rows.len() + " distinct items in " + items + " draws:");
		foreach (row in rows)
		{
			::logInfo("    " + row.C + "x   " + ::Math.floor(100.0 * row.C / items) + "%   " + row.N);
		}
		::logInfo("  ⚠ Compare those shares against the list. An entry listed twice should sit at");
		::logInfo("    double the others; anything far off after 20+ rolls is worth a second look.");
	}

	return null;
};

::skvzoldos <- function ( _force = false )
{
	if (!("World" in ::getroottable()) || ::World == null || ::World.Contracts == null)
	{
		::logInfo("Skv.zoldos: not in a campaign.");
		return null;
	}

	if (_force)
	{
		::Skv.Once.release("Zoldos");
		::World.Flags.remove("SkvOnce.Zoldos.retired");
	}

	local act = null;
	try { act = ::new("scripts/factions/contracts/skv_zoldos_action"); }
	catch (e) { ::logInfo("Skv.zoldos: could not build the action (" + e + ")"); act = null; }

	local renown = ::World.Assets.getBusinessReputation();

	::logInfo("== Skv.Zoldos (contract #13) ==");
	::logInfo("  once.active=" + ::World.Flags.has("SkvOnce.Zoldos.active")
		+ " once.retired=" + ::World.Flags.has("SkvOnce.Zoldos.retired")
		+ (::Skv.Once.isLocked("Zoldos") ? "  << BLOCKING" : ""));
	::logInfo("  score=" + ::Skv.Cfg.score() + (::Skv.Cfg.score() <= 0 ? "  << BLOCKING (dial is off)" : ""));
	::logInfo("  renown=" + renown + " / 1300" + (renown < 1300 ? "  << BLOCKING" : ""));

	local open = [];
	local live = null;
	local total = 0;

	foreach (s in ::World.EntityManager.getSettlements())
	{
		foreach (c in s.getContracts())
		{
			if (c.getType() == "contract.skv_zoldos") live = { S = s, C = c };
		}

		total = total + 1;

		local ok = false;
		local verdict = "canHost";
		if (act != null)
		{
			try { ok = act.canHost(s); }
			catch (e) { verdict = "local (canHost threw: " + e + ")"; act = null; }
		}
		if (act == null)
		{
			verdict = "local (no action)";
			ok = !s.isIsolated()
				&& ::MSU.isKindOf(s, "legends_village")
				&& s.getSize() <= 2
				&& s.getSurroundingTilesOfType([::Const.World.TerrainType.Mountains], 3).len() != 0;
		}

		local why = null;
		if (!ok)
		{
			if (s.isIsolated()) why = "isolated";
			else if (!::MSU.isKindOf(s, "legends_village")) why = "not a village";
			else if (s.getSize() > 2) why = "size " + s.getSize() + " (want <=2)";
			else if (s.getSurroundingTilesOfType([::Const.World.TerrainType.Mountains], 3).len() == 0) why = "no mountains within 3";
			else why = "canHost says no, and this dump cannot say why";
		}

		if (ok) open.push(s);

		if (ok || why == "no mountains within 3" || why.slice(0, 4) == "size")
		{
			::logInfo("    " + (ok ? "OK  " : "--  ") + s.getName()
				+ "  size " + s.getSize()
				+ "  mtn " + s.getSurroundingTilesOfType([::Const.World.TerrainType.Mountains], 3).len()
				+ (why == null ? "" : "   [" + why + "]"));
		}
	}

	::logInfo("  " + open.len() + " of " + total + " settlements can host now."
		+ (act == null ? "   [verdict: LOCAL COPY -- the action would not build]" : "   [verdict: the action's own canHost]"));
	if (live != null) ::logInfo("  LIVE at " + live.S.getName() + " -- \"" + live.C.getName() + "\"");

	if (!_force) return live == null ? null : live.C;

	if (live != null)
	{
		::logInfo("Skv.zoldos: already posted at " + live.S.getName() + " - not posting a second.");
		return live.C;
	}
	if (open.len() == 0)
	{
		::logInfo("Skv.zoldos: no settlement can host it. See the reasons above.");
		return null;
	}

	local ready = [];
	foreach (h in open)
	{
		local hf = ::World.FactionManager.getFaction(h.getFaction());
		local r = false;
		try { r = hf.isReadyForContract(::Const.Contracts.ContractCategoryMap.skv_zoldos_contract); }
		catch (e) { r = true; }
		if (r) ready.push(h);
	}

	local pool = ready.len() > 0 ? ready : open;
	if (ready.len() == 0)
	{
		::logInfo("Skv.zoldos: NO host has a free Hunt/Wildcard slot -- trying anyway, and it may be refused.");
	}

	local s = pool[::Math.rand(0, pool.len() - 1)];
	local f = ::World.FactionManager.getFaction(s.getFaction());

	::Skv.Once.claim("Zoldos");
	local c = ::new("scripts/contracts/contracts/skv_zoldos_contract");
	c.setFaction(f.getID());
	c.setHome(s);
	c.setEmployerID(f.getRandomCharacter().getID());
	::World.Contracts.addContract(c);

	local landed = false;
	foreach (x in s.getContracts())
	{
		if (x.getType() == "contract.skv_zoldos") landed = true;
	}

	if (landed)
	{
		::logInfo("Skv.zoldos: FORCED onto the board at " + s.getName() + " -- verified present.");
		return c;
	}

	::Skv.Once.release("Zoldos");
	local tier = s.getSize() - 1;
	local hunt = "?", wild = "?", hlim = "?", wlim = "?";
	try
	{
		hunt = f.m.ContractsByCategory["Hunt"].len() + "";
		wild = f.m.ContractsByCategory["Wildcard"].len() + "";
		hlim = ::Const.Contracts.CategoryLimits["Hunt"][tier] + "";
		wlim = ::Const.Contracts.CategoryLimits["Wildcard"][tier] + "";
	}
	catch (e) {}

	::logInfo("Skv.zoldos: ⚠ REFUSED at " + s.getName() + " (size " + s.getSize() + ").");
	::logInfo("  Legends' addContract drops a contract when its category AND Wildcard are both full,");
	::logInfo("  and only says so behind Debug.Flags.ContractCategories. Slots here:");
	::logInfo("    Hunt " + hunt + "/" + hlim + "   Wildcard " + wild + "/" + wlim);
	foreach (x in s.getContracts())
	{
		::logInfo("    holding: " + x.getName() + " [" + x.getType() + "]");
	}
	::logInfo("  Run it again to draw a different host, or clear a contract at this one.");
	return null;
};

::skvtorment <- function ( _force = false )
{
	if (!("World" in ::getroottable()) || ::World == null || ::World.Contracts == null)
	{
		::logInfo("Skv.torment: not in a campaign.");
		return null;
	}

	if (_force)
	{
		::Skv.Once.release("Torment");
		::World.Flags.remove("SkvOnce.Torment.retired");
	}

	local act = null;
	try { act = ::new("scripts/factions/contracts/skv_torment_action"); }
	catch (e) { ::logInfo("Skv.torment: could not build the action (" + e + ")"); act = null; }

	local day = ::World.getTime().Days;
	::logInfo("== Skv.Torment (contract #15) ==");
	::logInfo("  once.active=" + ::World.Flags.has("SkvOnce.Torment.active")
		+ " once.retired=" + ::World.Flags.has("SkvOnce.Torment.retired")
		+ (::Skv.Once.isLocked("Torment") ? "  << BLOCKING" : ""));
	::logInfo("  score=" + ::Skv.Cfg.score() + (::Skv.Cfg.score() <= 0 ? "  << BLOCKING (dial is off)" : ""));
	::logInfo("  day=" + day + " / 5" + (day < 5 ? "  << BLOCKING" : ""));
	::logInfo("  SkvHaanarFate=" + (::World.Flags.has("SkvHaanarFate") ? ::World.Flags.get("SkvHaanarFate") : "unset")
		+ "   (1 home · 2 dead after talking · 3 dead, straight to blades · 4 gone to his mother)");

	local hills = @(s) s.getSurroundingTilesOfType([::Const.World.TerrainType.Hills], 3).len();
	local open = [];
	local live = null;
	local total = 0;

	foreach (s in ::World.EntityManager.getSettlements())
	{
		foreach (c in s.getContracts())
		{
			if (c.getType() == "contract.skv_torment") live = { S = s, C = c };
		}
		total = total + 1;

		local ok = false;
		if (act != null)
		{
			try { ok = act.canHost(s); }
			catch (e) { ::logInfo("  canHost threw on " + s.getName() + ": " + e); ok = false; }
		}

		local why = null;
		if (!ok)
		{
			if (s.isIsolated()) why = "isolated";
			else if (!::MSU.isKindOf(s, "legends_village")) why = "not a village";
			else if (s.getSize() > 2) why = "size " + s.getSize() + " (want <=2)";
			else if (hills(s) == 0) why = "no hills within 3";
			else why = "canHost says no, and this dump cannot say why";
		}
		if (ok) open.push(s);
		if (ok || why == "no hills within 3" || why.slice(0, 4) == "size")
		{
			::logInfo("    " + (ok ? "OK  " : "--  ") + s.getName() + "  size " + s.getSize()
				+ "  hills " + hills(s) + (why == null ? "" : "   [" + why + "]"));
		}
	}
	::logInfo("  " + open.len() + " of " + total + " settlements can host now."
		+ (act == null ? "   [⚠ the action would not build -- no verdict]" : ""));

	if (live == null)
	{

		local a = ::World.Contracts.getActiveContract();
		if (a != null && a.getType() == "contract.skv_torment") live = { S = a.getHome(), C = a };
	}
	if (live != null)
	{
		local m = live.C.m;
		local acts = ["0 travelling", "1 trail read", "2 fight 1 won", "3 stones shown", "4 hill resolved", "5 concluded"];
		local apps = ["0 not tried", "1 caught at the fire", "2 the camp was up"];
		local outs = ["0 none", "1 talked down", "2 talked, then fought", "3 straight to blades", "4 Haanar gone"];
		local pick = function ( _arr, _i ) { return (_i >= 0 && _i < _arr.len()) ? _arr[_i] : (_i + " (UNKNOWN)"); };
		::logInfo("  LIVE at " + (live.S == null ? "?" : live.S.getName()) + " -- \"" + live.C.getName()
			+ "\"  active=" + m.IsActive);
		::logInfo("    Act=" + pick(acts, m.Act) + "  Approach=" + pick(apps, m.Approach)
			+ "  Outcome=" + pick(outs, m.Outcome));
		::logInfo("    Searched=" + m.Searched + "  Concluded=" + m.Concluded + "  Speaker=\"" + m.Speaker + "\"");
		::logInfo("    Marks=" + m.Marks + "  [" + ((m.Marks & ::Const.Skv.Torment.MarkFight1Lost) != 0 ? "1 fight-1-lost" : "no bits")
			+ "]   (1 fight 1 was lost: every re-attack is an ambush)");
		try
		{
			::logInfo("    hub -> " + live.C.hubScreen() + "   pay=" + live.C.finalPay()
				+ "   band budget=" + live.C.bandBudget() + "   wolf budget=" + live.C.wolfBudget()
				+ "   diff=" + live.C.getDifficultyMult());
			::logInfo("    ogre raw budget=" + live.C.ogreBudget() + "   champion=" + live.C.ogreIsChampion()
				+ " (gate " + ::Const.Skv.Torment.OgreChampionBudget + ")");
		}
		catch (e) { ::logInfo("    (hub/budget read threw: " + e + ")"); }
	}

	if (!_force) return live == null ? null : live.C;

	if (live != null)
	{
		::logInfo("Skv.torment: already posted - not posting a second.");
		return live.C;
	}
	if (open.len() == 0)
	{
		::logInfo("Skv.torment: no settlement can host it. See the reasons above.");
		return null;
	}

	local ready = [];
	foreach (h in open)
	{
		local hf = ::World.FactionManager.getFaction(h.getFaction());
		local r = false;
		try { r = hf.isReadyForContract(::Const.Contracts.ContractCategoryMap.skv_torment_contract); }
		catch (e) { r = true; }
		if (r) ready.push(h);
	}

	local shuffle = function ( _arr )
	{
		for (local i = _arr.len() - 1; i > 0; i = i - 1)
		{
			local j = ::Math.rand(0, i);
			local t = _arr[i]; _arr[i] = _arr[j]; _arr[j] = t;
		}
		return _arr;
	};
	local order = shuffle(ready);
	local rest = [];
	foreach (h in open)
	{
		local isReady = false;
		foreach (r in ready) if (r == h) isReady = true;
		if (!isReady) rest.push(h);
	}
	order.extend(shuffle(rest));
	if (ready.len() == 0) ::logInfo("Skv.torment: NO host has a free Hunt/Wildcard slot -- trying all " + order.len() + " anyway.");

	local join = function ( _arr )
	{
		local out = "";
		foreach (i, n in _arr) out = out + (i == 0 ? "" : ", ") + n;
		return out;
	};

	::Skv.Once.claim("Torment");
	local tried = [];
	foreach (s in order)
	{
		local f = ::World.FactionManager.getFaction(s.getFaction());
		local c = ::new("scripts/contracts/contracts/skv_torment_contract");
		c.setFaction(f.getID());
		c.setHome(s);
		c.setEmployerID(f.getRandomCharacter().getID());
		::World.Contracts.addContract(c);

		foreach (x in s.getContracts())
		{
			if (x.getType() == "contract.skv_torment")
			{
				::logInfo("Skv.torment: FORCED onto the board at " + s.getName() + " -- verified present"
					+ (tried.len() == 0 ? "." : " (refused first at: " + join(tried) + ")."));
				return c;
			}
		}
		tried.push(s.getName());
	}
	::Skv.Once.release("Torment");
	::logInfo("Skv.torment: ⚠ REFUSED at every host (" + join(tried)
		+ ") - Legends drops a contract when its category AND Wildcard are full. Wait a few days, or free a slot.");
	return null;
};

::skvitem <- function ( _path = null )
{
	local paths = _path != null ? [_path] : [
		"scripts/items/loot/skv_cut_ruby",
		"scripts/items/misc/skv_potion_of_cure_light_wounds",
		"scripts/items/accessory/skv_ring_of_torag",
		"scripts/items/misc/legend_masterwork_tools",
		"scripts/items/loot/gemstones_item",
		"scripts/items/loot/ancient_amber_item",
		"scripts/items/loot/white_pearls_item",
		"scripts/items/loot/glittering_rock_item"
	];

	local stash = ::World.Assets.getStash();
	stash.makeEmptySlots(paths.len());

	foreach ( p in paths )
	{
		local item = null;
		try { item = ::new(p); }
		catch (e) { ::logError("Skv.item: cannot create '" + p + "': " + e); continue; }
		if (item == null) continue;

		stash.add(item);
		::logInfo("Skv.item: " + item.getName() + "  icon=" + item.getIcon() + "  value=" + item.getValue());
	}
	return true;
};

::SkvAmbushDbg <- false;
::skvambushdbg <- function ( _on = true ) { ::SkvAmbushDbg = _on; ::Skv.dbg("SkvAmbushDbg = " + _on); return _on; };

::skvverbose <- function ( _on = null )
{
	local now = ::Const.AI.VerboseMode;
	::Const.AI.VerboseMode = _on == null ? !now : _on;
	::logInfo("Skv.verbose: AI score logging is now " + (::Const.AI.VerboseMode ? "ON" : "OFF") + ".");
	return ::Const.AI.VerboseMode;
};

::skvpickTargetTile <- function ( _actor, _skill )
{
	local own = _actor.getTile();

	local targeted = false;
	try { targeted = _skill.m.IsTargeted; } catch (e) { return own; }
	if (!targeted) return own;

	local minRange = 1;
	local maxRange = 1;
	try { minRange = _skill.m.MinRange; } catch (e) {}
	try { maxRange = _skill.getMaxRange(); } catch (e) {}
	if (maxRange < minRange) maxRange = minRange;

	local factions = ::Tactical.Entities.m.Instances;
	local best = null;
	local bestName = "";
	local bestDist = 9999;
	local bestFriendly = true;

	local nearestName = "";
	local nearestDist = 9999;
	local inWindowRefused = 0;

	for ( local f = 0; f < factions.len(); f = f + 1 )
	{
		foreach ( other in factions[f] )
		{
			if (other == null || !other.isAlive() || !other.isPlacedOnMap()) continue;
			if (other.getID() == _actor.getID()) continue;

			local tile = other.getTile();
			local d = own.getDistanceTo(tile);

			if (d < nearestDist)
			{
				nearestDist = d;
				nearestName = other.getName();
			}

			if (d < minRange || d > maxRange) continue;

			local usable = true;
			try { usable = _skill.isUsableOn(tile); } catch (e) {}

			if (!usable)
			{
				inWindowRefused = inWindowRefused + 1;
				continue;
			}

			local friendly = other.isAlliedWith(_actor);

			local take = false;
			if (best == null) take = true;
			else if (bestFriendly && !friendly) take = true;
			else if (bestFriendly == friendly && d < bestDist) take = true;

			if (!take) continue;

			best = tile;
			bestName = other.getName();
			bestDist = d;
			bestFriendly = friendly;
		}
	}

	if (best == null)
	{
		if (inWindowRefused > 0)
		{
			::logInfo("Skv.use: " + inWindowRefused + " actor(s) DO stand between range " + minRange
				+ " and " + maxRange + " and isUsableOn refused every one, so the SKILL is saying no rather than the positioning."
				+ " It will fire at its own tile and return FALSE.");
		}
		else if (nearestDist == 9999)
		{
			::logInfo("Skv.use: there is nobody else alive on the field to aim at."
				+ " It will fire at its own tile and return FALSE.");
		}
		else
		{
			::logInfo("Skv.use: nobody stands between range " + minRange + " and " + maxRange
				+ ". The nearest is " + nearestName + " at " + nearestDist + " tiles, so move somebody closer and try again."
				+ " It will fire at its own tile and return FALSE.");
		}

		return own;
	}

	::logInfo("Skv.use: aiming at " + bestName + " at " + bestDist + " tiles ("
		+ (bestFriendly ? "ally" : "hostile") + ", range window " + minRange + " to " + maxRange + ").");
	return best;
};

::skvusePending <- false;

::skvuse <- function ( _match = "warcry" )
{
	if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
	{
		::logInfo("Skv.use: not in a tactical fight.");
		return false;
	}

	if (::skvusePending)
	{
		::logInfo("Skv.use: already armed.");
		return false;
	}

	::skvusePending = true;

	::Time.scheduleEvent(::TimeUnit.Real, 900, function ( _data )
	{
		::skvusePending = false;

		if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
		{
			::logInfo("Skv.use: the fight ended before it fired.");
			return;
		}

		local factions = ::Tactical.Entities.m.Instances;

		for ( local f = 0; f < factions.len(); f = f + 1 )
		{
			foreach ( actor in factions[f] )
			{
				if (actor == null || !actor.isAlive() || !actor.isPlacedOnMap()) continue;
				if (actor.isPlayerControlled()) continue;

				foreach ( skill in actor.getSkills().m.Skills )
				{
					if (skill == null) continue;

					local id = "";
					try { id = skill.getID(); } catch (e) { continue; }
					if (id.find(_match) == null) continue;

					local ap = "?";
					local affordable = "?";
					try { ap = actor.getActionPoints() + "/" + actor.getActionPointsMax(); } catch (e) {}
					try { affordable = skill.isAffordable() ? "yes" : "no"; } catch (e) {}

					::logInfo("Skv.use: " + actor.getName() + " -> " + id
						+ " (usable " + (skill.isUsable() ? "yes" : "no")
						+ ", affordable " + affordable
						+ ", AP " + ap + ", cost " + skill.getActionPointCost() + ")");

					local lent = false;
					local savedAP = 0;
					local savedFatigue = 0;

					try
					{
						savedAP = actor.getActionPoints();
						savedFatigue = actor.getFatigue();
						actor.setActionPoints(actor.getActionPointsMax());
						actor.setFatigue(0);
						lent = true;
						::logInfo("Skv.use: lending " + actor.getName() + " a full turn ("
							+ actor.getActionPointsMax() + " AP, no fatigue) so isUsableOn will look at a target. Given back below.");
					}
					catch (e)
					{
						::logError("Skv.use: could not lend the caster a turn, so a spent creature will report no target: " + e);
					}

					try
					{

						local ok = skill.use(::skvpickTargetTile(actor, skill), true);
						::logInfo("Skv.use: use() returned " + (ok ? "TRUE -- onUse ran" : "FALSE -- onUse did NOT run, check range and target"));
					}
					catch (e)
					{
						::logError("Skv.use: " + id + " threw on use: " + e);
					}

					if (lent)
					{
						try
						{
							actor.setActionPoints(savedAP);
							actor.setFatigue(savedFatigue);
						}
						catch (e)
						{
							::logError("Skv.use: COULD NOT GIVE THE TURN BACK -- " + actor.getName()
								+ " is standing on borrowed action points. Reload before drawing any conclusion from this fight: " + e);
						}
					}

					return;
				}
			}
		}

		::logInfo("Skv.use: no living enemy on the field holds a skill matching '" + _match + "'.");
	}, null);

	::logInfo("Skv.use: armed for '" + _match + "', firing in 900ms so anything in flight lands first.");
	return true;
};

::skvmorale <- function ()
{
	if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
	{
		::logInfo("Skv.morale: not in a tactical fight.");
		return;
	}

	local names = {};
	try { foreach ( k, v in ::Const.MoraleState ) names[v] <- k; } catch (e) {}

	local factions = ::Tactical.Entities.m.Instances;

	for ( local f = 0; f < factions.len(); f = f + 1 )
	{
		foreach ( actor in factions[f] )
		{
			if (actor == null || !actor.isAlive() || !actor.isPlacedOnMap()) continue;

			local state = actor.getMoraleState();
			local label = (state in names) ? names[state] : ("" + state);

			::logInfo("Skv.morale: [f" + f + "] " + actor.getName()
				+ "  morale " + label
				+ "  fat " + actor.getFatigue() + "/" + actor.getFatigueMax()
				+ "  hp " + actor.getHitpoints() + "/" + actor.getHitpointsMax());
		}
	}
};

::skvgear <- function ()
{
	if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
	{
		::logInfo("Skv.gear: not in a tactical fight.");
		return;
	}

	local slots = [];
	try
	{
		slots = [
			["mainhand", ::Const.ItemSlot.Mainhand],
			["offhand",  ::Const.ItemSlot.Offhand],
			["head",     ::Const.ItemSlot.Head],
			["body",     ::Const.ItemSlot.Body]
		];
	}
	catch (e)
	{
		::logError("Skv.gear: could not read Const.ItemSlot - " + e);
		return;
	}

	local describe = function ( _item )
	{
		if (_item == null) return "-";

		local name = "?";
		try { name = _item.getName(); } catch (e) {}

		try { return name + " " + ::Math.round(_item.getCondition()) + "/" + ::Math.round(_item.getConditionMax()); }
		catch (e) { return name; }
	};

	local factions = ::Tactical.Entities.m.Instances;

	for ( local f = 0; f < factions.len(); f = f + 1 )
	{
		foreach ( actor in factions[f] )
		{
			if (actor == null || !actor.isAlive() || !actor.isPlacedOnMap()) continue;
			if (actor.isPlayerControlled()) continue;

			try
			{
				local items = actor.getItems();
				local line = "Skv.gear: " + actor.getName();

				foreach ( pair in slots )
				{
					line = line + "  [" + pair[0] + "] " + describe(items.getItemAtSlot(pair[1]));
				}

				local bag = "";
				try
				{
					foreach ( it in items.getAllItemsAtSlot(::Const.ItemSlot.Bag) )
					{
						bag = bag + (bag == "" ? "" : ", ") + describe(it);
					}
				}
				catch (e) {}

				line = line + "  [bag] " + (bag == "" ? "-" : bag);
				::logInfo(line);
			}
			catch (e)
			{
				::logError("Skv.gear: could not read " + actor.getName() + "'s items - " + e);
			}
		}
	}
};

::skvbreak <- function ( _state = "Wavering" )
{
	if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
	{
		::logInfo("Skv.break: not in a tactical fight.");
		return false;
	}

	local target = null;
	local known  = "";

	try
	{
		foreach ( k, v in ::Const.MoraleState )
		{
			known = known + (known == "" ? "" : ", ") + k;
			if (k.tolower() == _state.tolower()) target = v;
		}
	}
	catch (e)
	{
		::logError("Skv.break: could not read Const.MoraleState - " + e);
		return false;
	}

	if (target == null)
	{
		::logInfo("Skv.break: no morale state called '" + _state + "'. Known: " + known);
		return false;
	}

	local ignore = null;
	try { ignore = ::Const.MoraleState.Ignore; } catch (e) {}

	local factions = ::Tactical.Entities.m.Instances;
	local moved = 0;

	for ( local f = 0; f < factions.len(); f = f + 1 )
	{
		foreach ( actor in factions[f] )
		{
			if (actor == null || !actor.isAlive() || !actor.isPlacedOnMap()) continue;
			if (actor.isPlayerControlled()) continue;

			try
			{
				if (ignore != null && actor.getMoraleState() == ignore) continue;

				actor.setMoraleState(target);
				moved = moved + 1;
			}
			catch (e)
			{
				::logError("Skv.break: " + actor.getName() + " refused the change - " + e);
			}
		}
	}

	::logInfo("Skv.break: " + moved + " enemies set to " + _state
		+ ". End your turn, then watch Rally and Warcry in the next behaviour dump.");
	return true;
};
