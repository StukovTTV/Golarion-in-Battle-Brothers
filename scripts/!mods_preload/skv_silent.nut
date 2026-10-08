if (!("Skv" in ::getroottable())) ::Skv <- {};

::Skv.RumourSites <- {

	Sites = [],

	function add( _site )
	{
		this.Sites.push(_site);
	}

	function offer( _tavern, _isPaidFor, _rumour )
	{
		foreach (site in this.Sites)
		{
			local text = null;

			try
			{
				text = site.tryRumour(_tavern, _isPaidFor, _rumour);
			}
			catch (e)
			{
				::logError("Skv.RumourSites: " + site.Name + " threw, so the tavern keeps its own rumour: " + e);
			}

			if (text != null) return text;
		}

		return null;
	}

	function retell( _tavern, _rumour, _line, _plain, _site )
	{
		local marker = "\n\n[color=#bcad8c]\"";
		local open = "[color=#bcad8c]\"";
		local close = "\"[/color]";
		local at = _rumour.find(marker);
		local intro = "";

		if (at != null)
		{
			intro = _rumour.slice(0, at);
		}
		else
		{
			::logError("Skv.RumourSites: the tavern's rumour had no quote marker, so ours goes out without its intro. Rumour was: " + _rumour);
		}

		local before = _tavern.m.Location;
		local text = null;

		try
		{
			_tavern.m.Location = ::WeakTableRef(_site);
			text = intro + "\n\n" + _tavern.buildText(open + _line + close) + "\n\n";
		}
		catch (e)
		{
			::logError("Skv.RumourSites: buildText threw, so the plain line goes out instead: " + e);
			text = intro + "\n\n" + open + _plain + close + "\n\n";
		}

		_tavern.m.Location = before;
		_tavern.m.LastRumor = text;
		return text;
	}
};

::Skv.Silent <- {

	Name   = "The Silent Nation",
	TypeID = "location.skv_silent",
	Script = "scripts/entity/world/locations/legendary/skv_silent_location",

	StateFlag    = "SkvSilent.State",

	HeardDayFlag = "SkvSilent.HeardDay",

	BattleFlag   = "SkvSilent.Battle",

	ThawFlag     = "SkvSilent.Thaw",

	SpentFlag    = "SkvSilent.ThawSpent",

	ThawDayFlag  = "SkvSilent.ThawDay",

	RetreatsFlag = "SkvSilent.Retreats",

	SeenFlag     = "SkvSilent.Seen",

	Pending = [],

	Held = {},

	LastBought = 0,

	Odds = 33,

	MaxDistToTown = 14,
	MinDistToSettlements = 6,
	MinDistToLocations = 4,

	MaxPathTries = 10,

	ThawPerDay  = 3.0,
	RetreatStep = 0.5,
	ThawCap     = 300.0,
	MaxUnits    = 50,

	Renown      = 50,
	Moral       = 5,

	FogRadius = 500.0,

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

	function isSnow( _tile )
	{
		return _tile.Type == ::Const.World.TerrainType.Snow || _tile.Type == ::Const.World.TerrainType.SnowyForest;
	}

	function isSiteTerrain( _tile )
	{
		return this.isSnow(_tile);
	}

	function candidateTiles( _near )
	{
		local out = [];
		local size = ::World.getMapSize();
		local R = this.MaxDistToTown;
		local cx = _near.SquareCoords.X;
		local cy = _near.SquareCoords.Y;
		local settlements = ::World.EntityManager.getSettlements();
		local locations = ::World.EntityManager.getLocations();
		local player = ::World.State.getPlayer();
		local playerTile = player != null ? player.getTile() : null;

		for (local x = ::Math.max(3, cx - R); x <= ::Math.min(size.X - 3, cx + R); x = ++x)
		{
			for (local y = ::Math.max(3, cy - R); y <= ::Math.min(size.Y - 4, cy + R); y = ++y)
			{
				if (!::World.isValidTileSquare(x, y)) continue;

				local t = ::World.getTileSquare(x, y);

				if (!this.isSiteTerrain(t)) continue;
				if (t.getDistanceTo(_near) > R) continue;
				if (t.IsOccupied || t.HasRoad || t.HasRiver) continue;
				if (playerTile != null && playerTile.getDistanceTo(t) < 6) continue;

				local bad = false;

				for (local i = 0; i != 6; i = ++i)
				{
					if (!t.hasNextTile(i)) continue;

					local n = t.getNextTile(i);

					if (n.HasRoad || n.Type == ::Const.World.TerrainType.Ocean || n.Type == ::Const.World.TerrainType.Shore)
					{
						bad = true;
						break;
					}
				}

				if (bad) continue;

				for (local i = x - 3; i < x + 3 && !bad; i = ++i)
				{
					for (local j = y - 3; j < y + 3; j = ++j)
					{
						if (::World.isValidTileSquare(i, j) && ::World.getTileSquare(i, j).HasRoad)
						{
							bad = true;
							break;
						}
					}
				}

				if (bad) continue;

				foreach (s in settlements)
				{
					if (s.getTile().getDistanceTo(t) < this.MinDistToSettlements)
					{
						bad = true;
						break;
					}
				}

				if (bad) continue;

				foreach (v in locations)
				{
					if (v.getTile().getDistanceTo(t) < this.MinDistToLocations)
					{
						bad = true;
						break;
					}
				}

				if (bad) continue;

				out.push(t);
			}
		}

		return out;
	}

	function pickTile( _settlement )
	{
		local tiles = this.candidateTiles(_settlement.getTile());
		local navSettings = ::World.getNavigator().createSettings();
		navSettings.ActionPointCosts = ::Const.World.TerrainTypeNavCost;
		navSettings.RoadMult = 1.0;
		local tries = 0;

		while (tiles.len() > 0 && tries < this.MaxPathTries)
		{
			++tries;
			local t = tiles.remove(::Math.rand(0, tiles.len() - 1));
			local path = ::World.getNavigator().findPath(t, _settlement.getTile(), navSettings, 0);

			if (!path.isEmpty()) return t;
		}

		if (tries > 0) ::Skv.dbg("Skv.RumourSites: " + this.Name + ": " + _settlement.getName() + ": no path from " + tries + " candidate tile(s) to the town.");
		return null;
	}

	Lines = [
		"Up past the snowline, %distance% %direction% of here, the old glacier has started giving up its dead. Hunters say you can see them standing in the ice, rank on rank, like an army waiting on an order. They call it the Silent Nation. Nobody goes up there now.",
		"My cousin keeps goats on the high ground %distance% %direction% of here. He says the glacier up there is thawing, and there are men in it. Hundreds of them, standing. Some nights he hears the ice crack from the inside. Folk call the place the Silent Nation. He has moved his goats."
	],
	Plain = [
		"Up past the snowline, the old glacier has started giving up its dead. Hunters say you can see them standing in the ice, rank on rank, like an army waiting on an order. They call it the Silent Nation. Nobody goes up there now.",
		"My cousin keeps goats on the high ground past the snowline. He says the glacier up there is thawing, and there are men in it. Hundreds of them, standing. Some nights he hears the ice crack from the inside. Folk call the place the Silent Nation. He has moved his goats."
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
			::logError("Skv.Silent: the tavern has no settlement, so no rumour of the Silent Nation here.");
			return null;
		}

		local site = this.spawnNear(town);

		if (site == null)
		{

			::Skv.dbg("Skv.Silent: " + town.getName() + " won the roll" + (forced ? " (forced)" : "") + " but has no snow site within " + this.MaxDistToTown + "; the tavern keeps its own rumour.");
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
			::logError("Skv.Silent: spawnLocation returned null at " + tile.SquareCoords.X + "," + tile.SquareCoords.Y + "; no site and no rumour.");
			return null;
		}

		tile.TacticalType = ::Const.World.TerrainTacticalType.Snow;
		site.onSpawned();
		site.setDiscovered(true);
		::World.uncoverFogOfWar(site.getTile().Pos, this.FogRadius);
		::World.Flags.set(this.StateFlag, 1);
		::World.Flags.set(this.HeardDayFlag, ::World.getTime().Days);
		::World.Flags.set(this.ThawDayFlag, ::World.getTime().Days);
		::World.Flags.set(this.ThawFlag, 0.0);
		::World.Flags.set(this.RetreatsFlag, 0);
		::World.Flags.set(this.BattleFlag, 1);
		this.fillHost(site, 1);
		::logInfo("Skv.Silent: The Silent Nation rose at " + tile.SquareCoords.X + "," + tile.SquareCoords.Y
			+ " terrain=" + tile.Type + " distance=" + tile.getDistanceTo(_settlement.getTile())
			+ ", heard in " + _settlement.getName() + " on day " + ::World.getTime().Days + ".");
		return site;
	}

	function battle()   { return ::World.Flags.has(this.BattleFlag) ? ::World.Flags.get(this.BattleFlag) : 0; }
	function retreats() { return ::World.Flags.has(this.RetreatsFlag) ? ::World.Flags.get(this.RetreatsFlag) : 0; }
	function thaw()     { return ::World.Flags.has(this.ThawFlag) ? ::World.Flags.get(this.ThawFlag) : 0.0; }
	function spent()    { return ::World.Flags.has(this.SpentFlag) ? ::World.Flags.get(this.SpentFlag) : 0.0; }

	function rate()
	{
		return this.ThawPerDay * (1.0 + this.RetreatStep * this.retreats());
	}

	function updateThaw()
	{
		local today = ::World.getTime().Days;
		local last = ::World.Flags.has(this.ThawDayFlag) ? ::World.Flags.get(this.ThawDayFlag)
			: (::World.Flags.has(this.HeardDayFlag) ? ::World.Flags.get(this.HeardDayFlag) : today);
		local days = ::Math.max(0, today - last);

		if (days > 0)
		{
			::World.Flags.set(this.ThawFlag, ::Math.minf(this.ThawCap, this.thaw() + days * this.rate()));
		}

		::World.Flags.set(this.ThawDayFlag, today);
	}

	function addUnit( _site, _type, _champion )
	{
		return ::Const.World.Common.addTroop(_site, { Type = _type }, false, _champion ? 200 : 0);
	}

	function fillHost( _site, _n )
	{
		foreach (e in ::Const.Skv.Silent.Hosts[_n - 1])
		{
			local champ = ("Champion" in e) && e.Champion;

			for (local i = 0; i < e.Num; i = ++i)
			{
				this.addUnit(_site, e.Type, champ);
			}
		}

		::World.Flags.set(this.SpentFlag, 0.0);
		this.topUp(_site, _n);
		_site.updateStrength();
		::logInfo("Skv.Silent: host " + _n + " stands: " + _site.getTroops().len() + " units, strength " + _site.getStrength()
			+ ", thaw " + this.thaw() + ".");
	}

	function topUp( _site, _n )
	{
		local pool = ::Const.Skv.Silent.Pools[_n - 1];
		local budget = this.thaw() - this.spent();
		local total = 0;
		local cheapest = 9999;

		foreach (e in pool)
		{
			total = total + e.Weight;
			cheapest = ::Math.min(cheapest, e.Type.Cost);
		}

		local bought = 0;
		local paid = 0.0;
		local guard = 0;
		this.LastBought = 0;

		while (budget >= cheapest && guard < 500)
		{

			if (_site.getTroops().len() >= this.MaxUnits)
			{
				paid = paid + budget;
				break;
			}

			++guard;
			local roll = ::Math.rand(1, total);
			local pick = null;

			foreach (e in pool)
			{
				roll = roll - e.Weight;

				if (roll <= 0)
				{
					pick = e;
					break;
				}
			}

			if (pick.Type.Cost > budget) continue;

			this.addUnit(_site, pick.Type, false);
			budget = budget - pick.Type.Cost;
			paid = paid + pick.Type.Cost;
			++bought;
		}

		if (paid > 0)
		{
			::World.Flags.set(this.SpentFlag, this.spent() + paid);
		}

		if (bought > 0)
		{
			this.LastBought = bought;
			_site.updateStrength();
			::Skv.dbg("Skv.Silent: the thaw freed " + bought + " more for host " + _n + " (" + paid + " of " + this.thaw() + " spent).");
		}
	}

	function advance( _site )
	{
		local n = ::Math.min(3, this.battle() + 1);
		::World.Flags.set(this.BattleFlag, n);
		this.fillHost(_site, n);
	}

	function endHost( _site )
	{
		local left = _site.getTroops().len();

		if (left > 0)
		{
			::logInfo("Skv.Silent: " + left + " troop(s) of beaten host " + this.battle() + " never took the field; cleared.");
			_site.clearTroops();
		}
	}

	function isBeaten( _site )
	{
		return this.battle() >= 3 && _site.getTroops().len() == 0;
	}

	function prepare( _site )
	{
		this.updateThaw();
		local n = this.battle();

		if (n == 0)
		{
			::World.Flags.set(this.BattleFlag, 1);
			this.fillHost(_site, 1);
		}
		else if (_site.getTroops().len() == 0)
		{
			if (n < 3)
			{
				::logInfo("Skv.Silent: host " + n + " was beaten but the company left without choosing; counted as a fall back.");
				this.advance(_site);
				this.recordRetreat();
			}
		}
		else
		{
			this.topUp(_site, n);
		}
	}

	function nextHost( _site )
	{
		this.endHost(_site);
		this.updateThaw();
		this.advance(_site);
	}

	function seen()     { return ::World.Flags.has(this.SeenFlag) && ::World.Flags.get(this.SeenFlag); }
	function markSeen() { ::World.Flags.set(this.SeenFlag, true); }

	function recordRetreat()
	{
		this.updateThaw();
		::World.Flags.set(this.RetreatsFlag, this.retreats() + 1);
		::logInfo("Skv.Silent: retreat " + this.retreats() + "; the thaw now runs at " + this.rate() + " a day (" + this.thaw() + " so far).");
	}

	function fight( _event, _site )
	{
		local n = this.battle();

		if (_site.getTroops().len() == 0)
		{
			::logError("Skv.Silent: battle " + n + " has no host; no fight started.");
			return false;
		}

		local p = ::Const.Tactical.CombatInfo.getClone();
		p.CombatID = "SkvSilent" + n;
		p.Tile = _site.getTile();
		p.TerrainTemplate = "tactical.snow";

		p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Center;
		p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Circle;
		try { p.Music = ::Const.Music.UndeadTracks; } catch (e) { ::logError("Skv.Silent: no UndeadTracks - " + e); }
		p.Entities = [];
		local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Undead).getID();
		this.Pending = [];
		this.Held = {};

		p.AfterDeploymentCallback = function ()
		{
			::Skv.Silent.holdGear(fac);
		};

		foreach (t in _site.getTroops())
		{
			t.Faction <- fac;
			t.Party <- ::WeakTableRef(_site);
			p.Entities.push(t);
		}

		::logInfo("Skv.Silent: battle " + n + " begins: " + p.Entities.len() + " units, strength " + _site.getStrength()
			+ ", thaw " + this.thaw() + ", retreats " + this.retreats() + ".");
		_event.registerToShowAfterCombat("Won" + n, "Fled");
		::World.State.startScriptedCombat(p, false, false, false);
		return true;
	}

	function isChampion( _a )
	{
		try { if (_a.m.IsMiniboss) return true; } catch (e) { ::logError("Skv.Silent: IsMiniboss unreadable: " + e); }

		try
		{
			local t = _a.getWorldTroop();
			if (t != null && ("Variant" in t) && t.Variant != 0) return true;
		}
		catch (e)
		{
			::logError("Skv.Silent: troop Variant unreadable: " + e);
		}

		return false;
	}

	function isNamedItem( _it )
	{
		if (_it.isItemType(::Const.Items.ItemType.Named)) return true;

		try { if (_it.isNamed()) return true; } catch (e) { ::Skv.dbg("Skv.Silent: " + _it.getName() + " has no isNamed: " + e); }
		return false;
	}

	function isOurs( _a, _siteID )
	{
		try
		{
			local t = _a.getWorldTroop();
			return t != null && ("Party" in t) && t.Party != null && !t.Party.isNull() && t.Party.getID() == _siteID;
		}
		catch (e)
		{
			::logError("Skv.Silent: an actor's troop table is unreadable: " + e);
		}

		return false;
	}

	function holdGear( _fac )
	{
		local held = 0;
		local seen = 0;
		local champs = 0;
		local inFac = 0;
		local site = this.findSite();

		if (site == null)
		{
			::logError("Skv.Silent: holdGear with no site on the map.");
			return;
		}

		local siteID = site.getID();

		try
		{
			try { inFac = ::Tactical.Entities.getInstancesOfFaction(_fac).len(); } catch (e) { ::logError("Skv.Silent: faction " + _fac + " has no instance list: " + e); }

			local all = [];

			foreach (list in ::Tactical.Entities.getAllInstances())
			{
				foreach (a in list) all.push(a);
			}

			foreach (a in all)
			{
				if (!this.isOurs(a, siteID)) continue;
				++seen;
				if (!this.isChampion(a)) continue;
				++champs;
				local hands = "";

				foreach (slot in [::Const.ItemSlot.Mainhand, ::Const.ItemSlot.Offhand])
				{
					local it = a.getItems().getItemAtSlot(slot);
					if (it == null) continue;
					local named = this.isNamedItem(it);
					hands = hands + " [" + it.getName() + (named ? ", named" : "") + "]";
					if (!named) continue;
					this.Held[it.getInstanceID()] <- true;
					this.Pending.push(it);
					++held;
				}

				::logInfo("Skv.Silent:   champion " + a.getName() + " (IsMiniboss " + a.m.IsMiniboss + ") holds" + (hands == "" ? " nothing" : hands));
			}
		}
		catch (e)
		{
			::logError("Skv.Silent: holding the champions' gear failed (it may drop in the battle instead): " + e);
		}

		::logInfo("Skv.Silent: battle " + this.battle() + ": " + seen + " of the host on the field (" + inFac + " in faction " + _fac + "), "
			+ champs + " champion(s), " + held + " named item(s) held back.");
	}

	function isHeld( _it )
	{
		if (this.Held.len() == 0) return false;

		try
		{
			return _it.getInstanceID() in this.Held;
		}
		catch (e)
		{
			::logError("Skv.Silent: an item without an instance ID reached the drop test: " + e);
		}

		return false;
	}

	function commitGear()
	{
		this.Held = {};
		local site = this.findSite();

		if (site == null)
		{
			if (this.Pending.len() > 0) ::logError("Skv.Silent: " + this.Pending.len() + " champion item(s) won with no site to keep them.");
			this.Pending = [];
			return;
		}

		local names = "";

		foreach (it in this.Pending)
		{
			site.getLoot().add(it);
			names = names + " [" + it.getName() + "]";
		}

		if (this.Pending.len() > 0) ::logInfo("Skv.Silent: " + this.Pending.len() + " champion item(s) won:" + names + "; " + this.gearItems().len() + " in all.");
		this.Pending = [];
	}

	function gearItems()
	{
		local out = [];
		local site = this.findSite();
		if (site == null) return out;

		foreach (it in site.getLoot().getItems())
		{
			if (it != null) out.push(it);
		}

		return out;
	}

	function claim()
	{
		if (this.state() == 2) return [];

		local rows = [];
		rows.push(::Legends.EventList.changeRenown(this.Renown));

		::World.Assets.addMoralReputation(this.Moral);
		rows.push({ id = 1, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]The dead of the glacier lie consecrated (+" + this.Moral + ")[/color]" });
		local paths = [];
		local T = ::Const.Skv.Silent.Treasure;

		for (local i = 0; i < ::Const.Skv.Silent.TreasureNum; i = ++i)
		{
			paths.push(T[::Math.rand(0, T.len() - 1)]);
		}

		local gear = this.gearItems();
		local site = this.findSite();
		if (site != null) site.getLoot().clear();
		rows.extend(::Skv.Loot.haul(::Skv.Loot.make(paths)));

		local stash = ::World.Assets.getStash();
		stash.makeEmptySlots(gear.len());
		local names = "";

		foreach (it in gear)
		{
			stash.add(it);
			names = names + " [" + it.getName() + "]";
			rows.push({
				id = 1,
				icon = "ui/items/" + it.getIcon(),
				imageOverlayPath = it.getIconOverlay(),
				text = "You gain " + it.getName()
			});
		}

		::World.Flags.set(this.StateFlag, 2);
		::logInfo("Skv.Silent: the cleric hands over " + gear.len() + " champion item(s):" + names + ".");
		if (site != null) site.die();
		::logInfo("Skv.Silent: The Silent Nation is laid to rest (" + this.retreats() + " retreats, thaw " + this.thaw() + ").");
		return rows;
	}
};

::Skv.RumourSites.add(::Skv.Silent);

::skvsilent <- function ( _cmd = null, _arg = null )
{
	local S = ::Skv.Silent;

	if (_cmd == "force")
	{
		S.Force = true;
		::logInfo("Skv.silent: forced. The next new rumour in an eligible tavern names the site (not saved).");
		return;
	}

	if (_cmd == "battle" || _cmd == "thaw")
	{
		local site = S.findSite();

		if (site == null)
		{
			::logInfo("Skv.silent: no site on the map. ::skvsilent(\"spawn\") in a northern town first.");
			return;
		}

		if (_cmd == "battle")
		{
			local n = (_arg == null) ? 1 : ::Math.max(1, ::Math.min(3, _arg.tointeger()));
			S.updateThaw();
			site.clearTroops();
			::World.Flags.set(S.BattleFlag, n);
			S.fillHost(site, n);
			::logInfo("Skv.silent: jumped to battle " + n + ". Walk onto the site to fight it.");
		}
		else
		{
			local d = (_arg == null) ? 10 : ::Math.max(0, _arg.tointeger());
			S.updateThaw();
			::World.Flags.set(S.ThawFlag, ::Math.minf(S.ThawCap, S.thaw() + d * S.rate()));
			if (site.getTroops().len() > 0) S.topUp(site, S.battle());
			::logInfo("Skv.silent: " + d + " days of thaw at " + S.rate() + " a day; thaw now " + S.thaw() + ".");
		}

		return;
	}

	if (_cmd == "spawn" || _cmd == "reset")
	{
		local old = S.findSite();

		if (_cmd == "reset" || old != null)
		{
			if (old != null) old.die();
			::World.Flags.set(S.StateFlag, 0);
			::World.Flags.set(S.HeardDayFlag, 0);
			::World.Flags.set(S.BattleFlag, 0);
			::World.Flags.set(S.ThawFlag, 0.0);
			::World.Flags.set(S.SpentFlag, 0.0);
			::World.Flags.set(S.ThawDayFlag, ::World.getTime().Days);
			::World.Flags.set(S.RetreatsFlag, 0);
			::World.Flags.set(S.SeenFlag, false);
			::logInfo("Skv.silent: reset" + (old != null ? " (the old site removed)." : " (there was no site)."));
		}

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

		if (town == null)
		{
			::logInfo("Skv.silent: no town found to spawn from.");
			return;
		}

		local site = S.spawnNear(town);

		if (site == null) ::logInfo("Skv.silent: " + town.getName() + " has no snow site within " + S.MaxDistToTown + ". Try a northern town.");
		return;
	}

	::logInfo(">> ::skvsilent() -- The Silent Nation");
	::logInfo("  state=" + S.state() + " (0 not heard, 1 spawned, 2 cleared)  heardDay="
		+ (::World.Flags.has(S.HeardDayFlag) ? ::World.Flags.get(S.HeardDayFlag) : "none")
		+ "  today=" + ::World.getTime().Days + "  force=" + S.Force + "  odds=1 in " + S.Odds);

	local site = S.findSite();

	if (site != null)
	{
		local t = site.getTile();
		::logInfo("  site at " + t.SquareCoords.X + "," + t.SquareCoords.Y + " terrain=" + t.Type
			+ " tacticalType=" + t.TacticalType + " (snow=" + ::Const.World.TerrainTacticalType.Snow + ")"
			+ " discovered=" + site.isDiscovered() + " faction=" + site.getFaction());

		local counts = {};
		local champs = 0;

		foreach (tr in site.getTroops())
		{
			local key = tr.Script.slice(tr.Script.find("enemies/") != null ? tr.Script.find("enemies/") + 8 : 0);
			if (!(key in counts)) counts[key] <- 0;
			counts[key] = counts[key] + 1;
			if (tr.Variant > 0) ++champs;
		}

		local host = "";

		foreach (k, v in counts)
		{
			host = host + (host == "" ? "" : ", ") + v + " " + k;
		}

		site.updateStrength();
		::logInfo("  battle=" + S.battle() + "  host " + site.getTroops().len() + " units (" + champs + " champion(s)), strength "
			+ site.getStrength() + ": " + (host == "" ? "none" : host));
		::logInfo("  thaw=" + S.thaw() + " (spent on this host " + S.spent() + ", cap " + S.ThawCap + ")  rate=" + S.rate()
			+ " a day  retreats=" + S.retreats() + "  champion items won=" + S.gearItems().len());
	}
	else
	{
		::logInfo("  no site on the map.");
	}

	local here = ::World.State.getCurrentTown();

	if (here != null)
	{
		::logInfo("  in " + here.getName() + ": " + S.candidateTiles(here.getTile()).len() + " candidate tile(s), reachable pick: "
			+ (S.pickTile(here) != null ? "yes" : "NO (this town cannot tell of it)"));
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

	::logInfo("  eligible towns " + eligible + " of " + all + ": " + (eligible > 0 ? names : "none"));
};
