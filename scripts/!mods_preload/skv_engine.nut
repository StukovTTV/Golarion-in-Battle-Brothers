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
			return { ok = false, actor = null, worst = null, passed = 0, needed = 0, total = 0, avg = _base, rows = rows };
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
			ok = ok, actor = face, worst = worst,
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
		::Skv.dbg("Skv.Check.reflex chance=" + r.chance + " roll=" + r.roll + (r.ok ? " PASS" : " FAIL") + " actor=" + _contract.m.ActorName);
		return r;
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
				"Check XP — actor share (%)",
				"When a brother passes a skill check (a lockpick, a trapped passage, a reading), the contract awards a bit of experience.\n\nThis sets how much of it goes to the brother who actually did it; the rest is split evenly across the whole active company (everyone learns a little from watching).\n\n[b]35[/b] = default (about a third to the doer, the rest shared).\n[b]100[/b] = all to the doer.\n[b]0[/b] = split evenly across everyone.");
			page.addRangeSetting(this.CheckXPSoloID, this.DefaultCheckXPSolo, 0, 200, 5,
				"Check XP — one man's award",
				"Experience for a skill check that ONE brother makes on everyone's behalf — reading a ring, spotting a snare, picking a lock, creeping ahead to look.\n\nThis is the whole award for that check. How much of it goes to the brother who did it rather than to the company is the setting below.\n\n[b]75[/b] = default.\n[b]0[/b] = no experience from skill checks.");
			page.addRangeSetting(this.CheckXPTeamID, this.DefaultCheckXPTeam, 0, 200, 5,
				"Check XP — team effort, per brother",
				"Experience for a skill check EVERY brother has to make for himself — moving quietly past something asleep, crossing a market without being marked.\n\nThis is paid PER ACTIVE BROTHER and split evenly, so each man earns this much and the award does not get thinner as the company grows.\n\n[b]50[/b] = default. Deliberately lower than one man's award above: carrying a job for the whole company is worth more than doing your own share of one.");
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
		"contract.skv_carthica", "contract.skv_hollows", "contract.skv_anvil", "contract.skv_threshold"
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
	}
};

::skvc <- function ( _onlyMine = false ) { return ::Skv.Debug.contracts(_onlyMine); };
::skvazari <- function () { return ::Skv.Debug.azari(); };
::skvambush <- function () { return ::Skv.Debug.ambush(); };

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

::skvwin <- function ()
{
	if (!("Tactical" in getroottable()) || ::Tactical == null || ::Tactical.State == null)
	{
		::logInfo("Skv.win: not in a tactical fight.");
		return -1;
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
	return killed;
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
