if (!("Skv" in ::getroottable())) ::Skv <- {};

::Skv.Mbotuu <- {

	Name   = "M'botuu",
	TypeID = "location.skv_mbotuu",
	Script = "scripts/entity/world/locations/legendary/skv_mbotuu_location",

	StateFlag    = "SkvMbotuu.State",
	HeardDayFlag = "SkvMbotuu.HeardDay",

	Odds = 33,
	MaxDistToTown = 14,
	MinDistToSettlements = 6,
	MinDistToLocations = 4,
	MaxPathTries = 10,
	FogRadius = 500.0,

	ChampionEvery = 40,
	Seers = 3,
	Warriors = 6,
	Scouts = 9,
	ChiefName = "Sepoko",
	ChiefScript = "scripts/entity/tactical/enemies/skv_boggard_sepoko",

	ChampionNames = ["Gulmok", "Brakka", "Tsorrug", "Ommuk", "Glorb", "Kerrup", "Mudgar", "Phlegg",
		"Rakkat", "Wumbol", "Slubbik", "Gorrok", "Hurnak", "Blatha", "Okkreg", "Vuggal"],

	LastRows = [],

	Moral = -10,

	Treasure = [
		"scripts/items/loot/white_pearls_item",
		"scripts/items/loot/white_pearls_item",
		"scripts/items/loot/bone_figurines_item",
		"scripts/items/loot/jade_broche_item",
		"scripts/items/loot/ancient_gold_coins_item"
	],
	TreasureMin = 2,
	TreasureMax = 3,

	Force = false,

	function state()
	{
		return ::World.Flags.has(this.StateFlag) ? ::World.Flags.get(this.StateFlag) : 0;
	}

	function findSite()
	{
		foreach (v in ::World.EntityManager.getLocations())
		{
			if (v.getTypeID() == this.TypeID) return v;
		}

		return null;
	}

	function isSiteTerrain( _tile )
	{
		return ::Const.Skv.Croak.swampTypes().find(_tile.Type) != null;
	}

	function candidateTiles( _near )
	{
		return ::Skv.Silent.candidateTiles.call(this, _near);
	}

	function pickTile( _settlement )
	{
		return ::Skv.Silent.pickTile.call(this, _settlement);
	}

	Lines = [
		"There are frog-folk in the marsh %distance% %direction% of here. Not a raiding band, a proper village: huts hung from the dead trees, smoke, young ones in the reeds. M'botuu, they call it. Their chief is an old boggard named Sepoko who talks to the swamp, and folk say the swamp talks back.",
		"A trapper came through last week with half his traps gone and two fingers with them. He says the boggards %distance% %direction% of here have built themselves a whole village, M'botuu, with a chief to match, one Sepoko. They trouble no one who does not trouble them, he says. He troubled them."
	],
	Plain = [
		"There are frog-folk out in the marsh. Not a raiding band, a proper village: huts hung from the dead trees, smoke, young ones in the reeds. M'botuu, they call it. Their chief is an old boggard named Sepoko who talks to the swamp, and folk say the swamp talks back.",
		"A trapper came through last week with half his traps gone and two fingers with them. He says the boggards in the marsh have built themselves a whole village, M'botuu, with a chief to match, one Sepoko. They trouble no one who does not trouble them, he says. He troubled them."
	],

	function tryRumour( _tavern, _isPaidFor, _rumour )
	{
		if (this.state() != 0) return null;
		if (this.findSite() != null) return null;

		local forced = this.Force;
		if (!forced && ::Math.rand(1, this.Odds) != 1) return null;

		local town = _tavern.m.Settlement;

		if (town == null)
		{
			::logError("Skv.Mbotuu: the tavern has no settlement, so no rumour of M'botuu here.");
			return null;
		}

		local site = this.spawnNear(town);

		if (site == null)
		{
			::Skv.dbg("Skv.Mbotuu: " + town.getName() + " won the roll" + (forced ? " (forced)" : "") + " but has no swamp site within " + this.MaxDistToTown + "; the tavern keeps its own rumour.");
			return null;
		}

		this.Force = false;
		local i = ::Math.rand(0, this.Lines.len() - 1);
		return ::Skv.RumourSites.retell(_tavern, _rumour, this.Lines[i], this.Plain[i], site);
	}

	function spawnNear( _settlement )
	{
		local tile = this.pickTile(_settlement);
		if (tile == null) return null;

		local site = ::World.spawnLocation(this.Script, tile.Coords);

		if (site == null)
		{
			::logError("Skv.Mbotuu: spawnLocation returned null at " + tile.SquareCoords.X + "," + tile.SquareCoords.Y + "; no village and no rumour.");
			return null;
		}

		site.onSpawned();

		site.setFaction(::World.FactionManager.getFactionOfType(::Const.FactionType.Beasts).getID());
		this.fillGarrison(site);
		site.setDiscovered(true);
		::World.uncoverFogOfWar(site.getTile().Pos, this.FogRadius);
		::World.Flags.set(this.StateFlag, 1);
		::World.Flags.set(this.HeardDayFlag, ::World.getTime().Days);
		::logInfo("Skv.Mbotuu: M'botuu rose at " + tile.SquareCoords.X + "," + tile.SquareCoords.Y
			+ " terrain=" + tile.Type + " distance=" + tile.getDistanceTo(_settlement.getTile())
			+ ", heard in " + _settlement.getName() + " on day " + ::World.getTime().Days + ".");
		return site;
	}

	function championWarriors()
	{
		local n = 1 + ::World.getTime().Days / this.ChampionEvery;
		return ::Math.max(1, ::Math.min(n, ::World.getPlayerRoster().getSize()));
	}

	function addChampion( _site, _type, _name )
	{
		local t = ::Const.World.Common.addTroop(_site, { Type = _type }, false);
		t.Variant = ::Math.rand(1, 255);
		t.Strength = ::Math.round(t.Strength * 1.35);
		if (_name != null) t.Name = _name;
		return t;
	}

	function namedItem()
	{
		local item = null;
		local kind = ::Math.rand(1, 4);

		try
		{
			if (kind == 1)
				item = ::new("scripts/items/" + ::Const.Items.NamedWeapons[::Math.rand(0, ::Const.Items.NamedWeapons.len() - 1)]);
			else if (kind == 2)
				item = ::new("scripts/items/" + ::Const.Items.NamedShields[::Math.rand(0, ::Const.Items.NamedShields.len() - 1)]);
			else if (kind == 3)
				item = ::Const.World.Common.pickHelmet(::Const.World.Common.convNameToList(::Const.Items.NamedHelmets));
			else
				item = ::Const.World.Common.pickArmor(::Const.World.Common.convNameToList(::Const.Items.NamedArmors));
		}
		catch (e)
		{
			::logError("Skv.Mbotuu: the named item (kind " + kind + ") threw: " + e);
		}

		if (item == null)
		{
			::logError("Skv.Mbotuu: no named item of kind " + kind + "; a named weapon instead.");
			item = ::new("scripts/items/" + ::Const.Items.NamedWeapons[::Math.rand(0, ::Const.Items.NamedWeapons.len() - 1)]);
		}

		return item;
	}

	function fillGarrison( _site )
	{
		local T = ::Const.World.Spawn.Troops;
		local champs = this.championWarriors();

		local chief = this.addChampion(_site, T.SkvBoggardSwampseer, this.ChiefName);
		chief.Script = this.ChiefScript;
		local names = clone this.ChampionNames;

		for (local i = 0; i < champs; i = ++i)
		{
			if (names.len() == 0) names = clone this.ChampionNames;
			this.addChampion(_site, T.SkvBoggardWarrior, names.remove(::Math.rand(0, names.len() - 1)));
		}

		for (local i = 0; i < this.Seers; i = ++i) ::Const.World.Common.addTroop(_site, { Type = T.SkvBoggardSwampseer }, false);
		for (local i = 0; i < this.Warriors; i = ++i) ::Const.World.Common.addTroop(_site, { Type = T.SkvBoggardWarrior }, false);
		for (local i = 0; i < this.Scouts; i = ++i) ::Const.World.Common.addTroop(_site, { Type = T.SkvBoggardScout }, false);

		_site.updateStrength();
		::logInfo("Skv.Mbotuu: the garrison: Sepoko, " + champs + " champion warrior(s), " + this.Seers + " seers, "
			+ this.Warriors + " warriors, " + this.Scouts + " scouts: " + _site.getTroops().len() + " units, strength " + _site.getStrength() + ".");
	}

	function claim()
	{
		if (this.state() == 2) return [];

		local rows = [];
		::World.Assets.addMoralReputation(this.Moral);
		rows.push({ id = 1, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]A village put to the sword (" + this.Moral + ")[/color]" });

		local P = ::Legends.Perk.LegendTumble;
		local pool = [];
		local fought = [];

		foreach (b in ::World.getPlayerRoster().getAll())
		{
			local has = true;
			try { has = ::Legends.Perks.has(b, P); } catch (e) { ::logError("Skv.Mbotuu: Perks.has threw - " + e); }
			if (has) continue;
			pool.push(b);

			local reserve = false;
			try { reserve = b.isInReserves(); } catch (e) { ::logError("Skv.Mbotuu: isInReserves threw - " + e); }
			if (!reserve) fought.push(b);
		}

		if (fought.len() > 0) pool = fought;

		if (pool.len() == 0)
		{
			::logInfo("Skv.Mbotuu: every brother already tumbles; no perk to give.");
		}
		else
		{
			local bro = pool[::Math.rand(0, pool.len() - 1)];
			local res = { Added = null };

			try
			{
				::Legends.Perks.grant(bro, P, function ( _perk )
				{
					res.Added = this.getBackground().addPerk(P, 0, false);
					if (!res.Added) this.getBackground().m.PerkTreeMap[_perk.getID()].IsRefundable = false;
				}.bindenv(bro));

				rows.push({ id = 1, icon = "ui/perks/tumble_circle.png", text = bro.getName() + " gains the Tumble perk" });
				local now = false;
				try { now = ::Legends.Perks.has(bro, P); } catch (e) { ::logError("Skv.Mbotuu: the perk's read-back threw - " + e); }
				::logInfo("Skv.Mbotuu: Tumble to " + bro.getName() + ", added to his tree: " + res.Added + ", has it: " + now + ".");
			}
			catch (e)
			{
				::logError("Skv.Mbotuu: Perks.grant threw on " + bro.getName() + " - " + e);
			}
		}

		try
		{
			local paths = [];
			local n = ::Math.rand(this.TreasureMin, this.TreasureMax);
			for (local i = 0; i < n; i = ++i) paths.push(this.Treasure[::Math.rand(0, this.Treasure.len() - 1)]);
			rows.extend(::Skv.Loot.haul(::Skv.Loot.make(paths)));

			local famed = this.namedItem();
			local stash = ::World.Assets.getStash();
			stash.makeEmptySlots(1);
			stash.add(famed);
			rows.push({ id = 1, icon = "ui/items/" + famed.getIcon(), imageOverlayPath = famed.getIconOverlay(), text = "You gain " + famed.getName() });
			::logInfo("Skv.Mbotuu: the hoard: " + n + " valuables and " + famed.getName() + ".");
		}
		catch (e)
		{
			::logError("Skv.Mbotuu: the hoard threw (moral and Tumble still stand): " + e);
		}

		::World.Flags.set(this.StateFlag, 2);
		::logInfo("Skv.Mbotuu: M'botuu is gone.");
		this.LastRows = rows;
		return rows;
	}
};

::skvmbotuu <- function ( _cmd = null )
{
	local S = ::Skv.Mbotuu;

	if (_cmd == "force")
	{
		S.Force = true;
		::logInfo("Skv.mbotuu: forced. The next new rumour in an eligible tavern names M'botuu (not saved).");
		return;
	}

	if (_cmd == "spawn" || _cmd == "reset")
	{
		local old = S.findSite();
		if (old != null) old.die();
		::World.Flags.set(S.StateFlag, 0);
		::World.Flags.set(S.HeardDayFlag, 0);
		::logInfo("Skv.mbotuu: reset" + (old != null ? " (the old village removed)." : " (there was no village)."));
		if (_cmd == "reset") return;

		local town = ::World.State.getCurrentTown();

		if (town == null)
		{
			local best = 9999;
			local here = ::World.State.getPlayer().getTile();

			foreach (s in ::World.EntityManager.getSettlements())
			{
				local d = s.getTile().getDistanceTo(here);
				if (d < best) { best = d; town = s; }
			}
		}

		if (town == null) { ::logInfo("Skv.mbotuu: no town found to spawn from."); return; }
		if (S.spawnNear(town) == null) ::logInfo("Skv.mbotuu: " + town.getName() + " has no swamp site within " + S.MaxDistToTown + ". Try a town by the marshes.");
		return;
	}

	::logInfo(">> ::skvmbotuu() -- M'botuu");
	::logInfo("  state=" + S.state() + " (0 not heard, 1 standing, 2 destroyed)  heardDay="
		+ (::World.Flags.has(S.HeardDayFlag) ? ::World.Flags.get(S.HeardDayFlag) : "none")
		+ "  today=" + ::World.getTime().Days + "  force=" + S.Force + "  odds=1 in " + S.Odds
		+ "  champion warriors if it rose today=" + S.championWarriors());

	local site = S.findSite();

	if (site != null)
	{
		local t = site.getTile();
		local champs = 0;
		local counts = {};

		foreach (tr in site.getTroops())
		{
			local key = tr.Script.slice(tr.Script.find("enemies/") != null ? tr.Script.find("enemies/") + 8 : 0);
			if (!(key in counts)) counts[key] <- 0;
			counts[key] = counts[key] + 1;
			if (tr.Variant > 0) ++champs;
		}

		local host = "";
		foreach (k, v in counts) host = host + (host == "" ? "" : ", ") + v + " " + k;
		site.updateStrength();
		::logInfo("  village at " + t.SquareCoords.X + "," + t.SquareCoords.Y + " terrain=" + t.Type + " faction=" + site.getFaction()
			+ " attackable=" + site.isAttackable() + " discovered=" + site.isDiscovered());
		::logInfo("  garrison " + site.getTroops().len() + " units (" + champs + " champion(s)), strength " + site.getStrength() + ": " + (host == "" ? "none" : host));
	}
	else
	{
		::logInfo("  no village on the map.");
	}

	local eligible = 0;
	local all = 0;
	local names = "";

	foreach (s in ::World.EntityManager.getSettlements())
	{
		++all;
		local n = S.candidateTiles(s.getTile()).len();

		if (n > 0)
		{
			names = names + (eligible > 0 ? ", " : "") + s.getName() + " (" + n + ")";
			++eligible;
		}
	}

	::logInfo("  eligible towns " + eligible + " of " + all + " (candidates before the path test): " + (eligible > 0 ? names : "none"));
};
