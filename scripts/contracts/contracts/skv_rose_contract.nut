this.skv_rose_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Docks        = null,
		Drain        = null,
		Quarter      = null,
		Sinkhole     = null,
		DayAccepted  = 0,
		Act          = 0,
		Leads        = 0,
		Found        = 0,
		WordSent     = false,
		Rumours      = 0,
		RumoursPaid  = 0,
		Snips        = 0,
		Alley        = 0,
		Captive      = 0,
		Tunnel       = 0,
		Sewer        = 0,
		Ziraya       = 0,
		DonationPaid = 0,
		Climb        = 0,
		Attic        = 0,
		Descent      = 0,
		Door         = 0,
		TalkDown     = 0,
		Finale       = 0,
		Evidence     = 0,
		Granted      = 0,
		ActorName    = "",
		Rows         = null,
		Res16        = 0,
		Res32        = 0
	},

	function hasGrant( _bit ) { return (this.m.Granted & _bit) != 0; }
	function setGrant( _bit ) { this.m.Granted = this.m.Granted | _bit; }
	function hasFound( _bit ) { return (this.m.Found & _bit) != 0; }
	function leadClosed( _bit ) { return (this.m.Leads & _bit) != 0; }

	function foundCount()
	{
		local n = 0;
		foreach (b in [1, 2, 4]) if (this.hasFound(b)) n = n + 1;
		return n;
	}

	function factionOr( _id )
	{
		try { return ::World.FactionManager.getFaction(_id); }
		catch (e) { ::logError("Skv.Rose: faction " + _id + " did not resolve - " + e); }
		return null;
	}

	function townName()
	{
		return (this.m.Home != null && !this.m.Home.isNull()) ? this.m.Home.getName() : "the city";
	}

	function goodRow( _text ) { return { id = 1, icon = "ui/icons/special.png", text = _text }; }
	function badRow( _text )  { return { id = 1, icon = "ui/icons/regular_damage.png", text = _text }; }
	function relRow( _name, _better )
	{
		return { id = 1, icon = "ui/icons/relations.png",
			text = "Your relations with " + _name + (_better ? " improve" : " worsen") };
	}

	function finalPay()
	{
		local pay = this.m.Payment.getOnCompletion();
		if (this.m.Finale == 2) pay = ::Math.floor(pay * ::Const.Skv.Rose.PoorPayMult);
		return pay;
	}

	function payRenown()
	{
		local A = ::Const.World.Assets;
		return this.m.Finale == 2 ? A.ReputationOnContractPoor : A.ReputationOnContractSuccess;
	}

	function renownRow( _n )
	{
		try
		{
			local L = ::Legends.EventList;
			local a = ::Math.abs(_n);
			local band = a <= 50 ? 0 : (a <= 75 ? 1 : (a <= 100 ? 2 : 3));
			return { id = 10, icon = "ui/icons/special.png",
				text = _n > 0 ? ::format(L.RenownGain, ::Const.UI.Color.PositiveEventValue, L.Amount[band])
					: ::format(L.RenownLose, ::Const.UI.Color.NegativeEventValue, L.Amount[band]) };
		}
		catch (e) { ::logError("Skv.Rose: Legends' renown row strings did not resolve; a plain row stands in - " + e); }
		return { id = 10, icon = "ui/icons/special.png", text = _n > 0 ? "The company gains renown" : "The company loses renown" };
	}

	function img( _name ) { return "[img]gfx/ui/events/" + _name + ".png[/img]"; }

	function sb( _base ) { return ::Skv.Check.scaledBase(this, _base); }

	function actorName( _r, _mid = false )
	{
		if (_r != null && "actor" in _r && _r.actor != null) return _r.actor.getName();
		return _mid ? "one of the company" : "One of the company";
	}

	function knowsRemna() { return this.hasFound(1); }

	function moralRow( _delta, _text )
	{
		local col = _delta < 0 ? ::Const.UI.Color.NegativeEventValue : ::Const.UI.Color.PositiveEventValue;
		return { id = 1, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + col + "]" + _text + " (" + (_delta < 0 ? "" : "+") + _delta + ")[/color]" };
	}

	function moral( _delta, _text, _rows )
	{
		if (_delta == 0) return;
		::World.Assets.addMoralReputation(_delta);
		_rows.push(this.moralRow(_delta, _text));
	}

	function townRel( _delta, _why, _rows )
	{
		local f = this.factionOr(this.getFaction());
		if (f == null)
		{
			::logError("Skv.Rose: the city-state's faction did not resolve; a relation change of " + _delta + " is lost (" + _why + ").");
			return;
		}
		f.addPlayerRelation(_delta, _why);
		_rows.push(this.relRow(f.getName(), _delta > 0));
	}

	function feeShare( _mult )
	{
		local n = ::Math.floor(this.m.Payment.getOnCompletion() * _mult / 10.0 + 0.5) * 10;
		return n < 10 ? 10 : n;
	}

	function rumourCost() { return this.feeShare(::Const.Skv.Rose.RumourMult); }
	function wardCost()   { return this.feeShare(::Const.Skv.Rose.WardMult); }
	function bountyPay()  { return this.feeShare(::Const.Skv.Rose.BountyMult); }
	function pursePay()   { return this.feeShare(::Const.Skv.Rose.PurseMult); }
	function lawPay()     { return this.foundCount() == 0 ? 0 : this.feeShare(::Const.Skv.Rose.LawMult * this.foundCount()); }
	function brokerPay()
	{
		local C = ::Const.Skv.Rose;
		return this.feeShare(C.BrokerBase + C.BrokerPerT * this.foundCount());
	}
	function potionCount() { return ::Math.min(::Const.Skv.Rose.PotionsMax, 1 + ::Math.min(this.foundCount(), 2)); }

	function hurtThese( _checkRows, _min, _max )
	{
		local rows = [];
		if (_checkRows == null) return rows;
		foreach (cr in _checkRows)
		{
			if (cr.ok) continue;
			local bro = cr.bro;
			if (bro == null || !bro.isAlive()) continue;
			local dmg = this.Math.rand(_min, _max);
			local hp = bro.getHitpoints() - dmg;
			if (hp < 1) hp = 1;
			bro.setHitpoints(hp);
			rows.push({ id = 10, icon = "ui/icons/health.png", text = bro.getName() + " loses " + dmg + " health" });
		}
		return rows;
	}

	function hurtOne( _r, _min, _max )
	{
		if (_r == null || !("actor" in _r) || _r.actor == null || !_r.actor.isAlive())
		{
			::logInfo("Skv.Rose: hurtOne found no living actor on the check; nobody is hurt.");
			return [];
		}
		return this.hurtThese([ { ok = false, bro = _r.actor } ], _min, _max);
	}

	function canPay( _n ) { return ::World.Assets.getMoney() >= _n; }

	function alleyWarned() { return this.m.Rumours == 3 || this.m.Rumours == 5; }

	function alleyCircle() { return this.m.Snips == 2; }

	function fazgynJoins()
	{
		return ::Const.Skv.Rose.FazgynEnabled && (this.m.Tunnel == 1 || this.m.Tunnel == 3);
	}

	function remnaJoins() { return this.m.Door != 3; }

	function finaleCircle() { return this.m.Door == 4; }

	function alleyBudget()
	{
		local C = ::Const.Skv.Rose;
		return C.AlleyBase * this.getDifficultyMult() * this.getScaledDifficultyMult() + (this.alleyWarned() ? C.AlleyWarned : 0);
	}

	function sewerBudget( _fixed )
	{
		return ::Math.maxf(_fixed, ::Const.Skv.Rose.SewerBase * this.getDifficultyMult() * this.getScaledDifficultyMult());
	}

	function finaleBudget()
	{
		local C = ::Const.Skv.Rose;
		return ::Math.maxf(C.FinaleMin, C.FinaleBase * this.getDifficultyMult() * this.getScaledDifficultyMult());
	}

	function marker( _k )
	{
		if (_k == 0) return this.m.Docks;
		if (_k == 1) return this.m.Drain;
		if (_k == 2) return this.m.Quarter;
		return this.m.Sinkhole;
	}

	function setMarker( _k, _ref )
	{
		if (_k == 0) this.m.Docks = _ref;
		else if (_k == 1) this.m.Drain = _ref;
		else if (_k == 2) this.m.Quarter = _ref;
		else this.m.Sinkhole = _ref;
	}

	function markerLive( _k ) { return !::MSU.isNull(this.marker(_k)); }

	function killSite( _k )
	{
		local mk = this.marker(_k);
		if (!::MSU.isNull(mk))
		{
			mk.getSprite("selection").Visible = false;
			mk.die();
		}
		this.setMarker(_k, null);
	}

	function killLeads()
	{
		for (local k = 0; k < 3; k = k + 1) this.killSite(k);
	}

	function killAll()
	{
		for (local k = 0; k < 4; k = k + 1) this.killSite(k);
	}

	function liveTiles()
	{
		local out = [];
		for (local k = 0; k < 4; k = k + 1)
		{
			local mk = this.marker(k);
			if (!::MSU.isNull(mk)) out.push(mk.getTile());
		}
		return out;
	}

	function vanillaFilter( _pool )
	{
		local C = ::Const.Skv.Rose;
		local R = ::Skv.Rose;
		local townMin = ::Math.max(C.SiteMinDist, 4);
		local siteMin = C.SiteMinDist == 0 ? 0 : ::Math.min(4, C.SiteMinDist - 1);
		local towns = [];
		foreach (s in ::World.EntityManager.getSettlements()) towns.push(s.getTile());
		local sites = [];
		if (siteMin > 0)
		{
			foreach (v in ::World.EntityManager.getLocations()) sites.push(v.getTile());
		}
		local out = { Tiles = [], Town = 0, Site = 0 };
		foreach (t in _pool)
		{
			if (t.IsOccupied || !R.isSolidGround(t)) continue;
			local bad = false;
			foreach (st in towns)
			{
				if (st.getDistanceTo(t) < townMin) { bad = true; break; }
			}
			if (bad) { out.Town = out.Town + 1; continue; }
			foreach (lt in sites)
			{
				if (t.getDistanceTo(lt) < siteMin) { bad = true; break; }
			}
			if (bad) { out.Site = out.Site + 1; continue; }
			out.Tiles.push(t);
		}
		return out;
	}

	function pickSite( _home, _pool, _live, _gap, _maxSteps = null )
	{
		local C = ::Const.Skv.Rose;
		local R = ::Skv.Rose;
		local cap = _maxSteps == null ? C.SitePathMax : _maxSteps;
		local out = { Tile = null, Steps = 0, Tried = 0, Cut = 0, Far = 0, Close = 0 };
		while (_pool.len() > 0)
		{
			local k = ::Math.rand(0, _pool.len() - 1);
			local t = _pool[k];
			_pool.remove(k);
			if (t.IsOccupied || !R.isSolidGround(t)) continue;
			local near = false;
			foreach (lt in _live)
			{
				if (lt.getDistanceTo(t) < _gap) { near = true; break; }
			}
			if (near) { out.Close = out.Close + 1; continue; }
			out.Tried = out.Tried + 1;
			local n = R.landSteps(_home, t);
			if (n < 0) { out.Cut = out.Cut + 1; continue; }
			if (n > cap) { out.Far = out.Far + 1; continue; }
			out.Tile = t;
			out.Steps = n;
			break;
		}
		return out;
	}

	function spawnSite( _k )
	{
		if (this.markerLive(_k)) return null;
		local C = ::Const.Skv.Rose;
		local R = ::Skv.Rose;
		local home = this.m.Home.getTile();
		local raw = _k == C.KindSinkhole ? R.ringTiles(this.m.Home) : R.candidates(this.m.Home).Tiles;
		local vf = this.vanillaFilter(raw);
		local pool = vf.Tiles;
		local total = pool.len();
		local dropped = raw.len() + " candidates, " + vf.Town + " too near a settlement, " + vf.Site + " too near a location";
		local live = this.liveTiles();

		if (_k == C.KindSinkhole)
		{
			try { live.push(::World.State.getPlayer().getTile()); }
			catch (e) { ::logError("Skv.Rose: the party's tile could not be read for the sinkhole's spacing - " + e); }
		}

		local nearPool = [];
		foreach (t in pool)
		{
			if (t.getDistanceTo(home) <= C.NearRadius) nearPool.push(t);
		}
		local resN = this.pickSite(home, clone nearPool, live, C.SiteSpacing, C.NearPathMax);
		if (resN.Tile != null)
		{
			return this.placeAt(_k, resN.Tile, (_k == C.KindSinkhole ? "ring" : "coast") + " NEAR (" + dropped + "; " + nearPool.len()
				+ " within " + C.NearRadius + " tiles; tried " + resN.Tried + ": " + resN.Cut + " cut off, " + resN.Far + " over "
				+ C.NearPathMax + " steps, " + resN.Close + " too close) " + resN.Steps + " steps on foot, spaced " + C.SiteSpacing, false);
		}
		local res = this.pickSite(home, clone pool, live, C.SiteSpacing);
		local tile = res.Tile;
		local route = (_k == C.KindSinkhole ? "ring" : "coast") + " (" + dropped + "; tried " + res.Tried + ": "
			+ res.Cut + " cut off, " + res.Far + " over " + C.SitePathMax + " steps, " + res.Close + " too close) "
			+ res.Steps + " steps on foot, spaced " + C.SiteSpacing;
		local fallback = false;
		if (tile == null)
		{
			local res2 = this.pickSite(home, clone pool, live, 0);
			tile = res2.Tile;
			fallback = true;
			route = "RELAXED SPACING (none " + C.SiteSpacing + " apart was walkable: " + dropped + ", "
				+ res.Close + " too close; unspaced tried " + res2.Tried + ": " + res2.Cut + " cut off, " + res2.Far + " too far) "
				+ res2.Steps + " steps on foot";
		}
		if (tile == null)
		{
			local tries = 0;
			for (local i = 0; i < C.FallbackTries; i = i + 1)
			{
				tries = i + 1;
				tile = this.getTileToSpawnLocation(home, 3, 8);
				if (R.isSolidGround(tile)) break;
			}
			route = "FALLBACK getTileToSpawnLocation(home, 3, 8) unfiltered, " + tries + " ask(s) (" + dropped + "; " + total + " left, none walkable within "
				+ C.SitePathMax + ")" + (R.isSolidGround(tile) ? "" : "  << NOT SOLID GROUND after " + C.FallbackTries + " asks: taken anyway");
			fallback = true;
		}
		return this.placeAt(_k, tile, route, fallback);
	}

	function placeAt( _k, _tile, _route, _loud )
	{
		local site = ::Const.Skv.Rose.Sites[_k];
		local home = this.m.Home.getTile();
		_tile.clear();
		local ref = this.WeakTableRef(::World.spawnLocation(site.Script, _tile.Coords));
		ref.onSpawned();
		ref.setDiscovered(true);
		ref.setAttackable(false);
		ref.getSprite("selection").Visible = true;
		::World.uncoverFogOfWar(ref.getTile().Pos, 500.0);
		this.setMarker(_k, ref);
		local line = "Skv.Rose: " + site.Name + " at " + _tile.Coords.X + "," + _tile.Coords.Y + " terrain=" + _tile.Type
			+ (_tile.Type == ::Const.World.TerrainType.Shore ? " (SHORE)" : "")
			+ " " + _tile.getDistanceTo(home) + " tiles from " + this.m.Home.getName() + " route=" + _route;
		if (_loud || _tile.Type == ::Const.World.TerrainType.Shore) ::logInfo(line);
		else ::Skv.dbg(line);
		return line;
	}

	function spawnLeads()
	{
		local C = ::Const.Skv.Rose;
		local R = ::Skv.Rose;
		local fresh = true;
		for (local k = 0; k < 3; k = k + 1)
		{
			if (this.leadClosed(C.Sites[k].Bit) || this.markerLive(k)) fresh = false;
		}
		if (fresh)
		{
			try
			{
				local home = this.m.Home.getTile();
				local raw = R.candidates(this.m.Home).Tiles;
				local vf = this.vanillaFilter(raw);
				local walk = [];
				local cut = 0;
				local far = 0;
				local pool = clone vf.Tiles;
				while (pool.len() > 0)
				{
					local i = ::Math.rand(0, pool.len() - 1);
					local t = pool[i];
					pool.remove(i);
					local n = R.landSteps(home, t);
					if (n < 0) { cut = cut + 1; continue; }
					if (n > C.SitePathMax) { far = far + 1; continue; }
					walk.push({ T = t, N = n });
				}

				local nearTiles = [];
				foreach (w in walk)
				{
					if (w.N <= C.NearPathMax && w.T.getDistanceTo(home) <= C.NearRadius) nearTiles.push(w.T);
				}
				local pick = R.spacedPick(nearTiles, C.SiteCount, C.SiteSpacing);
				local range = "NEAR, " + nearTiles.len() + " within " + C.NearRadius + " tiles and " + C.NearPathMax + " steps";
				if (pick.len() < 3)
				{
					local tiles = [];
					foreach (w in walk) tiles.push(w.T);
					pick = R.spacedPick(tiles, C.SiteCount, C.SiteSpacing);
					range = "WIDE, only " + nearTiles.len() + " near";
				}
				local why = raw.len() + " candidates, " + vf.Town + " too near a settlement, " + vf.Site + " too near a location, "
					+ cut + " cut off, " + far + " over " + C.SitePathMax + " steps, " + walk.len() + " walkable; " + range;
				if (pick.len() >= 3)
				{
					for (local k = 0; k < 3; k = k + 1)
					{
						local steps = 0;
						foreach (w in walk) if (w.T.ID == pick[k].ID) steps = w.N;
						try { this.placeAt(k, pick[k], "spacedPick (" + why + ") " + steps + " steps on foot, spaced " + C.SiteSpacing, false); }
						catch (e) { ::logError("Skv.Rose: could not spawn " + C.Sites[k].Name + " - " + e); }
					}
				}
				else
				{
					::logInfo("Skv.Rose: spacedPick found only " + pick.len() + " of 3 walkable spaced lead sites (" + why
						+ "); each lead falls back to the greedy and relaxed path.");
				}
			}
			catch (e) { ::logError("Skv.Rose: the spacedPick placement threw; each lead falls back to the greedy path - " + e); }
		}
		for (local k = 0; k < 3; k = k + 1)
		{
			if (this.leadClosed(C.Sites[k].Bit) || this.markerLive(k)) continue;
			try { this.spawnSite(k); }
			catch (e) { ::logError("Skv.Rose: could not spawn " + C.Sites[k].Name + " - " + e); }
		}
	}

	function missingSites()
	{
		local out = [];
		if (this.m.Act != 0) return out;
		for (local k = 0; k < 3; k = k + 1)
		{
			if (!this.leadClosed(::Const.Skv.Rose.Sites[k].Bit) && !this.markerLive(k)) out.push(k);
		}
		if (this.m.WordSent && this.m.Finale == 0 && !this.markerLive(::Const.Skv.Rose.KindSinkhole)) out.push(::Const.Skv.Rose.KindSinkhole);
		return out;
	}

	function leadScreen( _k )
	{
		if (_k == 0)
		{
			if (this.m.Alley != 0 || this.leadClosed(1)) return null;
			if (this.m.Snips != 0) return "Alley";
			return this.m.Rumours != 0 ? "Barbershop" : "Docks";
		}
		if (_k == 1)
		{
			if (this.m.Sewer != 0 || this.leadClosed(2)) return null;
			return this.m.Tunnel != 0 ? "Sharks" : "Outfall";
		}
		if (_k == 2)
		{
			if (this.leadClosed(4)) return null;
			if (this.m.Climb != 0) return "Attic";
			return this.m.Ziraya != 0 ? "FrogsTongue" : "Quarter";
		}
		if (!this.m.WordSent || this.m.Finale != 0) return null;
		if (this.m.Door != 0) return "Wennel";
		return this.m.Descent != 0 ? "InnDoor" : "Sinkhole";
	}

	function edgeRows( _bit )
	{
		if (_bit == 1) return [ this.goodRow("You learned the killer's right side is hurt"),
			this.goodRow("You learned a broker's name from a hired blade") ];
		if (_bit == 2) return [ this.goodRow("You found the killer's journal and the names in it"),
			this.goodRow("You found a purse sealed with a broker's mark") ];
		return [ this.goodRow("You found a holy symbol torn from the killer"),
			this.goodRow("You found a bill of sale with a buyer's mark") ];
	}

	function wennelRows()
	{
		local rows = [];
		if (this.hasFound(1)) rows.push(this.goodRow("You know his right side is hurt"));
		if (this.hasFound(2)) rows.push(this.goodRow("The names in his journal will stop him for a moment"));
		if (this.hasFound(4)) rows.push(this.goodRow("His own symbol will cloud his mind"));
		return rows;
	}

	function evidenceOffered() { return this.m.Finale == 1 || this.foundCount() > 0; }

	function resolveRumours( _how )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Rumours != 0) return "Barbershop";
		local rows = [];
		if (_how == 1)
		{
			local n = ::Math.min(this.rumourCost(), ::World.Assets.getMoney());
			this.m.Rumours = 1;
			this.m.RumoursPaid = n;
			if (!this.hasGrant(C.GrantRumours))
			{
				this.setGrant(C.GrantRumours);
				if (n > 0) rows.push(::Legends.EventList.changeMoney(-n));
			}
			rows.push(this.goodRow("Nobody ran ahead of you to the Barbers"));
		}
		else
		{
			local charm = _how == 2;
			local r = charm ? ::Skv.Check.charm(this, this.sb(C.RumourCharmBase)) : ::Skv.Check.guile(this, this.sb(C.RumourGuileBase));
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Rumours = charm ? 2 : 4;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + (charm ? " got the net-menders talking" : " passed for a man with a blade to hire")));
				rows.push(this.goodRow("Nobody ran ahead of you to the Barbers"));
			}
			else
			{
				this.m.Rumours = charm ? 3 : 5;
				rows.push(this.badRow(who + (charm ? " asked too many questions" : " did not convince anyone")));
				rows.push(this.badRow("Word of you ran ahead to the Barbers"));
			}
		}
		::Skv.dbg("Skv.Rose: Docks resolved how=" + _how + " -> rumours=" + this.m.Rumours + " paid=" + this.m.RumoursPaid);
		this.m.Rows = rows;
		return "Barbershop";
	}

	function resolveSnips( _shake )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Snips != 0) return "Alley";
		local rows = [];
		if (_shake)
		{
			this.m.Snips = 3;
			if (!this.hasGrant(C.GrantMoralSnips))
			{
				this.setGrant(C.GrantMoralSnips);
				this.moral(C.MoralSnips, "You frightened a child into talking", rows);
			}
			rows.push(this.goodRow("The boy told you who was waiting where"));
		}
		else
		{
			local r = ::Skv.Check.agility(this, this.sb(C.SnipsBase));
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Snips = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + " caught the boy before he could whistle"));
				rows.push(this.goodRow("The boy told you who was waiting where"));
			}
			else
			{
				this.m.Snips = 2;
				rows.push(this.badRow("The boy twisted out of " + this.actorName(r, true) + "'s hands and whistled"));
			}
		}
		::Skv.dbg("Skv.Rose: Barbershop resolved shake=" + _shake + " -> snips=" + this.m.Snips);
		this.m.Rows = rows;
		return "Alley";
	}

	function resolveCaptive( _go )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Captive != 0) return "Captive";
		local rows = [];
		if (_go)
		{
			this.m.Captive = 1;
			rows.push(this.goodRow("The Barbers will remember this"));
		}
		else
		{
			this.m.Captive = 2;
			if (!this.hasGrant(C.GrantBounty))
			{
				this.setGrant(C.GrantBounty);
				rows.push(::Legends.EventList.changeMoney(this.bountyPay()));
				this.townRel(C.BountyRelation, "Handed a Barber to the watch", rows);
			}
		}
		::Skv.dbg("Skv.Rose: the captive " + (_go ? "LET GO" : "HANDED OVER") + " -> captive=" + this.m.Captive);
		this.m.Rows = rows;
		return "Captive";
	}

	function resolveTunnel( _pit )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Tunnel != 0) return "Sharks";
		local rows = [];
		if (!_pit)
		{
			local r = ::Skv.Check.disarm(this, this.sb(C.DisarmBase));
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Tunnel = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + " took the blade trap apart without a sound"));
			}
			else
			{
				this.m.Tunnel = 2;
				rows.push(this.badRow("The blade caught " + this.actorName(r, true) + ", and the Sharks heard it"));
				rows.extend(this.hurtOne(r, C.BladeHurtMin, C.BladeHurtMax));
			}
		}
		else
		{
			local r = ::Skv.Check.agility(this, this.sb(C.PitBase), C.PartyNeed);
			if (r.ok)
			{
				this.m.Tunnel = 3;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("The company got past the pit"));
			}
			else
			{
				this.m.Tunnel = 4;
				rows.push(this.badRow("Too many of the company slipped at the pit, and the Sharks heard it"));
				rows.extend(this.hurtThese(r.rows, C.HurtMin, C.HurtMax));
			}
		}
		if (this.fazgynJoins()) rows.push(this.goodRow("Fazgyn's squad got through to fight beside you"));
		else if (::Const.Skv.Rose.FazgynEnabled) rows.push(this.badRow("Fazgyn's squad was cut off"));
		::Skv.dbg("Skv.Rose: Fazgyn resolved pit=" + _pit + " -> tunnel=" + this.m.Tunnel + " fazgyn=" + this.fazgynJoins());
		this.m.Rows = rows;
		return "Sharks";
	}

	function resolveZiraya( _give )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Ziraya != 0) return "FrogsTongue";
		local rows = [];
		if (_give)
		{
			local n = ::Math.min(this.wardCost(), ::World.Assets.getMoney());
			this.m.Ziraya = 1;
			this.m.DonationPaid = n;
			if (!this.hasGrant(C.GrantWard))
			{
				this.setGrant(C.GrantWard);
				if (n > 0) rows.push(::Legends.EventList.changeMoney(-n));
			}
			if (!this.hasGrant(C.GrantMoralWard))
			{
				this.setGrant(C.GrantMoralWard);
				this.moral(C.MoralWard, "You gave to the drowned quarter's ward fund", rows);
			}
		}
		else
		{
			local r = ::Skv.Check.charm(this, this.sb(C.ZirayaBase));
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Ziraya = 2;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + " won Ziraya's trust"));
			}
			else
			{
				this.m.Ziraya = 3;
				rows.push(this.badRow("Ziraya did not warm to " + this.actorName(r, true)));
			}
		}
		::Skv.dbg("Skv.Rose: Quarter resolved give=" + _give + " -> ziraya=" + this.m.Ziraya + " paid=" + this.m.DonationPaid);
		this.m.Rows = rows;
		return "FrogsTongue";
	}

	function warned() { return this.m.Ziraya == 1 || this.m.Ziraya == 2; }

	function resolveClimb( _wall )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Climb != 0) return "Attic";
		local rows = [];
		local edge = this.warned() ? C.WarnedEdge : 0;
		if (!_wall)
		{
			local r = ::Skv.Check.agility(this, this.sb(C.StairsBase) + edge, C.PartyNeed);
			if (r.ok)
			{
				this.m.Climb = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("The company found the sound steps"));
			}
			else
			{
				this.m.Climb = 2;
				rows.push(this.badRow("The stairs gave way under the company"));
				rows.extend(this.hurtThese(r.rows, C.HurtMin, C.HurtMax));
			}
		}
		else
		{
			local r = ::Skv.Check.agility(this, this.sb(C.WallBase) + edge);
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Climb = 3;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + " climbed the wall and let down a rope"));
			}
			else
			{
				this.m.Climb = 4;
				rows.push(this.badRow(who + " fell from the wall, and the rest had to climb in without a rope"));
				rows.extend(this.hurtOne(r, C.BladeHurtMin, C.BladeHurtMax));
			}
		}
		::Skv.dbg("Skv.Rose: Manor resolved wall=" + _wall + " warned=" + this.warned() + " -> climb=" + this.m.Climb);
		this.m.Rows = rows;
		return "Attic";
	}

	function climbFailed() { return this.m.Climb == 2 || this.m.Climb == 4; }

	function resolveAttic( _still )
	{
		local C = ::Const.Skv.Rose;
		if (this.leadClosed(4)) return this.hasFound(4) ? "AtticAfter" : "QuarterFled";
		local rows = [];
		local ok = false;
		if (!_still)
		{
			local r = ::Skv.Check.nerve(this, this.sb(C.FireBase));
			local who = this.actorName(r);
			ok = r.ok;
			if (r.ok)
			{
				this.m.Attic = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + " drove the bats off with a burning rag"));
			}
			else
			{
				this.m.Attic = 2;
				rows.push(this.badRow("The swarm came down on " + this.actorName(r, true) + " before the rag caught fire"));
				rows.extend(this.hurtOne(r, C.BladeHurtMin, C.BladeHurtMax));
			}
		}
		else
		{
			local r = ::Skv.Check.stealth(this, this.sb(C.StillBase), C.PartyNeed);
			ok = r.ok;
			if (r.ok)
			{
				this.m.Attic = 3;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("The company kept still until the bats settled"));
			}
			else
			{
				this.m.Attic = 4;
				rows.push(this.badRow("Too many of the company flinched, and the bats came down"));
				rows.extend(this.hurtThese(r.rows, C.BiteHurtMin, C.BiteHurtMax));
			}
		}
		local found = ok || !this.climbFailed();
		this.m.Leads = this.m.Leads | 4;
		if (found) this.m.Found = this.m.Found | 4;
		this.killSite(C.KindQuarter);
		if (found) rows.extend(this.edgeRows(4));
		else rows.push(this.badRow("The freedman lead is lost"));
		::Skv.dbg("Skv.Rose: the freedman lead CLOSED " + (found ? "with its find" : "EMPTY (driven out)")
			+ ". climb=" + this.m.Climb + " attic=" + this.m.Attic + " leads=" + this.m.Leads + " found=" + this.m.Found);
		this.m.Rows = rows;
		this.updateObjectives();
		return found ? "AtticAfter" : "QuarterFled";
	}

	function resolveDescent()
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Descent != 0) return "InnDoor";
		local rows = [];
		local r = ::Skv.Check.agility(this, this.sb(C.DescentBase), C.PartyNeed);
		if (r.ok)
		{
			this.m.Descent = 1;
			rows.extend(::Skv.XP.check(r));
			rows.push(this.goodRow("The company reached the bottom of the pit in good order"));
		}
		else
		{
			this.m.Descent = 2;
			rows.push(this.badRow("The slope slid away under the company"));
			rows.extend(this.hurtThese(r.rows, C.HurtMin, C.HurtMax));
		}
		::Skv.dbg("Skv.Rose: Sinkhole resolved -> descent=" + this.m.Descent);
		this.m.Rows = rows;
		return "InnDoor";
	}

	function resolveDoor( _vines )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Door != 0) return "Wennel";
		local rows = [];
		if (!_vines)
		{
			local edge = this.m.Captive == 1 ? C.SideDoorEdge : 0;
			local r = ::Skv.Check.agility(this, this.sb(C.SideDoorBase) + edge, C.PartyNeed);
			if (edge > 0) rows.push(this.goodRow("The Barbers' word showed you the firm ground"));
			if (r.ok)
			{
				this.m.Door = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("The company crossed the mud to the side door"));
			}
			else
			{
				this.m.Door = 2;
				rows.push(this.badRow("The mud pulled at the company all the way to the door"));
				rows.extend(this.hurtThese(r.rows, C.HurtMin, C.HurtMax));
			}
			rows.push(this.badRow(this.knowsRemna() ? "Remna came up out of the mud" : "A dead woman with a barber's razor came up out of the mud"));
		}
		else
		{
			local r = ::Skv.Check.stealth(this, this.sb(C.VinesBase), C.PartyNeed);
			if (r.ok)
			{
				this.m.Door = 3;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("The company got inside unseen"));
				rows.push(this.goodRow(this.knowsRemna() ? "Remna stayed caught in the roots" : "A dead woman stayed caught in the roots"));
			}
			else
			{
				this.m.Door = 4;
				rows.push(this.badRow("The company was heard in the vines"));
				rows.push(this.badRow(this.knowsRemna() ? "The dead spread out to meet you, Remna with them" : "The dead spread out to meet you, a dead woman with a razor among them"));
			}
		}
		::Skv.dbg("Skv.Rose: InnDoor resolved vines=" + _vines + " captive=" + this.m.Captive + " -> door=" + this.m.Door
			+ " remna=" + this.remnaJoins() + " circle=" + this.finaleCircle());
		this.m.Rows = rows;
		return "Wennel";
	}

	function resolveEvidence( _to )
	{
		local C = ::Const.Skv.Rose;
		if (this.m.Evidence != 0) return "EvidenceAfter";
		this.m.Evidence = _to;
		local rows = [];
		if (_to == 1)
		{
			if (!this.hasGrant(C.GrantPotions))
			{
				this.setGrant(C.GrantPotions);
				local paths = [];
				for (local i = 0; i < this.potionCount(); i = i + 1) paths.push(C.ItemPotion);
				local got = ::Skv.Loot.haul(::Skv.Loot.make(paths));
				if (got.len() == 0) ::logError("Skv.Rose: the faithful's potions did not reach the stash.");
				rows.extend(got);
			}
			if (!this.hasGrant(C.GrantMoralProof))
			{
				this.setGrant(C.GrantMoralProof);
				this.moral(C.MoralFaithful, "You put the proof in the hands of those who free people", rows);
			}
		}
		else if (_to == 2)
		{
			if (!this.hasGrant(C.GrantEvidencePay))
			{
				this.setGrant(C.GrantEvidencePay);
				if (this.lawPay() > 0) rows.push(::Legends.EventList.changeMoney(this.lawPay()));
			}
			if (!this.hasGrant(C.GrantEvidenceRel))
			{
				this.setGrant(C.GrantEvidenceRel);
				this.townRel(C.LawRelation, "Brought proof against a slaver to the magistrates", rows);
			}
			if (!this.hasGrant(C.GrantMoralProof))
			{
				this.setGrant(C.GrantMoralProof);
				this.moral(C.MoralLaw, "You took the proof to the law", rows);
			}
		}
		else
		{
			if (!this.hasGrant(C.GrantEvidencePay))
			{
				this.setGrant(C.GrantEvidencePay);
				rows.push(::Legends.EventList.changeMoney(this.brokerPay()));
			}
			if (!this.hasGrant(C.GrantMoralProof))
			{
				this.setGrant(C.GrantMoralProof);
				this.moral(C.MoralBroker, "You sold the proof that freed people are being sold again", rows);
			}
		}
		::Skv.dbg("Skv.Rose: EVIDENCE to=" + _to + " T=" + this.foundCount() + " law=" + this.lawPay()
			+ " broker=" + this.brokerPay() + " potions=" + this.potionCount() + " granted=" + this.m.Granted);
		this.m.Act = 3;
		this.m.Rows = rows;
		return "EvidenceAfter";
	}

	function wordDue()
	{
		return this.m.Act == 0 && !this.m.WordSent && this.m.Found != 0;
	}

	function coldCase()
	{
		local C = ::Const.Skv.Rose;
		return this.m.Act == 0 && !this.m.WordSent && this.m.Found == 0 && (this.m.Leads & C.LeadBits) == C.LeadBits;
	}

	function afterLead()
	{
		if (this.coldCase()) return "Cold";
		if (this.wordDue()) return "Word";
		return 0;
	}

	function coldRenown()
	{
		return ::Const.World.Assets.ReputationOnContractFail;
	}

	function coldRelation()
	{
		return ::Const.World.Assets.RelationNobleContractFail;
	}

	function updateObjectives()
	{
		local C = ::Const.Skv.Rose;
		local b = [];
		if (this.m.Act == 0)
		{
			for (local k = 0; k < 3; k = k + 1)
			{
				if (!this.leadClosed(C.Sites[k].Bit) && this.markerLive(k)) b.push("Follow the lead at " + C.Sites[k].Name);
			}
			if (this.m.WordSent && this.m.Finale == 0) b.push("Go down into " + C.Sites[C.KindSinkhole].Name);
			if (b.len() == 0) b.push("Find the Rose Street Killer");
		}
		else
		{
			b.push("Return to " + this.townName());
		}
		this.m.BulletpointsObjectives = b;

		::World.Contracts.updateActiveContract();
	}

	function onWennelPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Rose: onWennelPlaced got a null entity - Wennel is a plain heavy skeleton (or missing).");
			return;
		}
		local C = ::Const.Skv.Rose;

		local weapon = "none";
		try
		{
			local items = _e.getItems();
			local old = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
			if (old != null)
			{
				::Skv.dbg("Skv.Rose: Wennel already held " + old.getID() + " at his callback; replaced.");
				items.unequip(old);
				items.removeFromBag(old);
			}
			items.equip(::new(C.WennelWeapon));
			local mh = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
			weapon = mh == null ? "NONE" : mh.getID();
		}
		catch (e) { ::logError("Skv.Rose: could not equip Wennel's morningstar (" + C.WennelWeapon + "): " + e); }
		if (weapon == "none" || weapon == "NONE") ::logError("Skv.Rose: Wennel holds no morningstar after his callback.");

		local champ = false;
		try
		{
			_e.m.XP = _e.m.XP * 1.5;
			_e.getSkills().add(::new("scripts/skills/racial/champion_racial"));
			_e.m.IsMiniboss = true;
			_e.m.IsGeneratingKillName = false;
			_e.getSprite("miniboss").setBrush("bust_miniboss");
			champ = _e.getSkills().hasSkill("racial.champion");
		}
		catch (e) { ::logError("Skv.Rose: could not make Wennel a champion by hand: " + e); }
		if (!champ) ::logError("Skv.Rose: Wennel should carry racial.champion and does not.");

		local edges = [];
		if (this.hasFound(1))
		{

			try
			{
				_e.getSkills().add(::new("scripts/skills/effects/disarmed_effect"));
				local b = _e.getBaseProperties();
				b.MeleeDefense = b.MeleeDefense - C.EdgeGuildDefense;
				edges.push("guild (disarmed=" + _e.getSkills().hasSkill("effects.disarmed") + ", melee defence -" + C.EdgeGuildDefense + ")");
			}
			catch (e) { ::logError("Skv.Rose: the guild edge did not apply to Wennel: " + e); }
		}
		if (this.hasFound(2))
		{

			try
			{
				_e.getSkills().add(::new("scripts/skills/effects/dazed_effect"));
				edges.push("kobold (dazed=" + _e.getSkills().hasSkill("effects.dazed") + ")");
			}
			catch (e) { ::logError("Skv.Rose: the kobold edge did not apply to Wennel: " + e); }
		}
		if (this.hasFound(4))
		{

			try
			{
				local b = _e.getBaseProperties();
				b.MeleeSkill = b.MeleeSkill - C.EdgeSymbolSkill;
				b.Bravery = b.Bravery - C.EdgeSymbolResolve;
				edges.push("freedman (melee skill -" + C.EdgeSymbolSkill + ", resolve -" + C.EdgeSymbolResolve + ")");
			}
			catch (e) { ::logError("Skv.Rose: the freedman edge did not apply to Wennel: " + e); }
		}
		try { _e.getSkills().update(); }
		catch (e) { ::logError("Skv.Rose: Wennel's skills did not update after his edges: " + e); }

		::Skv.dbg("Skv.Rose: WENNEL placed (in his callback, before his own loadout and Legends' scaling). found=" + this.m.Found
			+ " champion=" + champ + " mainhand=" + weapon + " edges=[" + this.joinList(edges, "; ") + "]");
		this.reportWennel(_e, "at his callback");

		try
		{
			::Time.scheduleEvent(::TimeUnit.Real, C.WennelReportMs, function ( _data )
			{
				if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
				{
					::logInfo("Skv.Rose: the delayed Wennel report found no fight running.");
					return;
				}
				if (::MSU.isNull(_data.Ref))
				{
					::logInfo("Skv.Rose: the delayed Wennel report found him gone.");
					return;
				}
				_data.Contract.reportWennel(_data.Ref.get(), "after setup");
			}, { Ref = this.WeakTableRef(_e), Contract = this });
		}
		catch (e) { ::logError("Skv.Rose: could not schedule the delayed Wennel report: " + e); }
	}

	function joinList( _a, _sep )
	{
		if (_a.len() == 0) return "none";
		local s = "";
		foreach (i, x in _a) s = s + (i == 0 ? "" : _sep) + x;
		return s;
	}

	function reportWennel( _e, _when )
	{
		try
		{
			local ids = [];
			foreach (s in _e.getSkills().query(::Const.SkillType.StatusEffect, true)) ids.push(s.getID());
			local items = _e.getItems();
			local mh = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
			local oh = items.getItemAtSlot(::Const.ItemSlot.Offhand);
			local b = _e.getBaseProperties();
			local cp = _e.getCurrentProperties();
			::Skv.dbg("Skv.Rose: Wennel " + _when + ": name=" + _e.getName() + " miniboss=" + _e.m.IsMiniboss
				+ " champion=" + _e.getSkills().hasSkill("racial.champion")
				+ " mainhand=" + (mh == null ? "NONE" : mh.getID()) + " offhand=" + (oh == null ? "none" : oh.getID())
				+ " effects=[" + this.joinList(ids, ", ") + "]"
				+ " base melee " + b.MeleeSkill + "/def " + b.MeleeDefense + "/resolve " + b.Bravery
				+ " current melee " + cp.MeleeSkill + "/def " + cp.MeleeDefense + "/resolve " + cp.Bravery
				+ " weaponSkills=" + cp.IsAbleToUseWeaponSkills
				+ " HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax() + " XP " + _e.m.XP);
		}
		catch (e) { ::logError("Skv.Rose: could not report Wennel (" + _when + "): " + e); }
	}

	function onRemnaPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Rose: onRemnaPlaced got a null entity - Remna is not in the fight.");
			return;
		}

		local weapon = "none";
		try
		{
			local items = _e.getItems();
			local old = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
			if (old != null)
			{
				::Skv.dbg("Skv.Rose: Remna already held " + old.getID() + " at her callback; replaced.");
				items.unequip(old);
				items.removeFromBag(old);
			}
			items.equip(::new(::Const.Skv.Rose.RemnaWeapon));
			local mh = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
			weapon = mh == null ? "NONE" : mh.getID();
		}
		catch (e) { ::logError("Skv.Rose: could not give Remna her razor (" + ::Const.Skv.Rose.RemnaWeapon + "): " + e); }
		if (weapon == "none" || weapon == "NONE") ::logError("Skv.Rose: Remna holds no razor after her callback.");
		::Skv.dbg("Skv.Rose: REMNA placed (a light skeleton, named on the descriptor) faction=" + _e.getFaction() + " mainhand=" + weapon);

		try
		{
			::Time.scheduleEvent(::TimeUnit.Real, ::Const.Skv.Rose.WennelReportMs, function ( _data )
			{
				if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null)
				{
					::logInfo("Skv.Rose: Remna's offhand step found no fight running.");
					return;
				}
				if (::MSU.isNull(_data.Ref))
				{
					::logInfo("Skv.Rose: Remna's offhand step found her gone.");
					return;
				}
				_data.Contract.stripRemnaOffhand(_data.Ref.get());
			}, { Ref = this.WeakTableRef(_e), Contract = this });
		}
		catch (e) { ::logError("Skv.Rose: could not schedule Remna's offhand step (she may hold a second weapon): " + e); }
	}

	function stripRemnaOffhand( _e )
	{
		try
		{
			local items = _e.getItems();
			local oh = items.getItemAtSlot(::Const.ItemSlot.Offhand);
			local mh = items.getItemAtSlot(::Const.ItemSlot.Mainhand);
			if (oh == null)
			{
				::Skv.dbg("Skv.Rose: REMNA after setup: offhand empty, mainhand=" + (mh == null ? "NONE" : mh.getID()));
				return;
			}
			local id = oh.getID();
			items.unequip(oh);
			items.removeFromBag(oh);
			local left = items.getItemAtSlot(::Const.ItemSlot.Offhand);
			if (left != null) ::logError("Skv.Rose: REMNA still holds " + left.getID() + " in her offhand after the strip.");
			else ::Skv.dbg("Skv.Rose: REMNA after setup: took " + id + " out of her offhand; mainhand=" + (mh == null ? "NONE" : mh.getID()));
		}
		catch (e) { ::logError("Skv.Rose: could not empty Remna's offhand: " + e); }
	}

	function onSharkPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Rose: onSharkPlaced got a null entity - the Sharks' sorcerer is missing.");
			return;
		}
		::Skv.dbg("Skv.Rose: the Sharks' sorcerer placed, type=" + _e.getType() + " faction=" + _e.getFaction());
	}

	function onFazgynPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Rose: onFazgynPlaced got a null entity - an ally is missing from the sewer.");
			return;
		}
		::Skv.dbg("Skv.Rose: ally placed, type=" + _e.getType() + " faction=" + _e.getFaction()
			+ " (PlayerAnimals=" + ::Const.Faction.PlayerAnimals + ")");
	}

	function troop( _t, _fac, _row = null, _name = null, _cb = null )
	{
		local d = {
			ID = _t.ID,
			Variant = 0,
			Row = _row == null ? _t.Row : _row,
			Script = _t.Script,
			Faction = _fac
		};
		if (_name != null) d.Name <- _name;
		if (_cb != null) d.Callback <- _cb;
		return d;
	}

	function indoorCombat( _id, _tile, _circle )
	{
		local p = ::Const.Tactical.CombatInfo.getClone();
		p.CombatID = _id;
		p.Tile = _tile;
		p.TerrainTemplate = "tactical.skv_ruin_floor";
		p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = _circle ? ::Const.Tactical.DeploymentType.Circle : ::Const.Tactical.DeploymentType.Line;
		p.IsWithoutAmbience = true;
		p.Entities = [];
		return p;
	}

	function siteTile( _k )
	{
		local mk = this.marker(_k);
		if (!::MSU.isNull(mk)) return mk.getTile();
		::logInfo("Skv.Rose: " + ::Const.Skv.Rose.Sites[_k].Name + " has no marker at its fight (a jump?); the fight runs on the party's tile.");
		return ::World.State.getPlayer().getTile();
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_rose";
		this.m.Name = "The Rose Street Revenge";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A man from the Pathfinder lodge wants outside hands for a hunt in the city's streets.",
			"Someone is killing freed people, and the lodge cannot spare its own agents to find out who."
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function onPrepareVariables( _vars )
	{
		_vars.push(["SKVTOWN", this.townName()]);
		_vars.push(["SKVNAME", "[color=#9dbccb]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);
	}

	function start()
	{
		local C = ::Const.Skv.Rose;
		this.m.DifficultyMult = this.Math.rand(C.DiffLo, C.DiffHi) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, C.PayBase);

		this.m.Payment.Advance = 0.0;
		this.m.Payment.Completion = 1.0;
		::Skv.dbg("Skv.Rose: created at " + this.m.Home.getName() + " diff=" + this.m.DifficultyMult
			+ " pool=" + this.m.Payment.Pool + " fee=" + this.finalPay());
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Follow three leads around " + this.Contract.townName(),
					"Find who is killing freed people"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				local c = this.Contract;

				local adv = c.m.Payment.getInAdvance();
				if (adv > 0)
				{
					::logError("Skv.Rose: an advance of " + adv + " was negotiated although #20 offers none; paid, so the player loses nothing.");
					this.World.Assets.addMoney(adv);
				}
				c.m.DayAccepted = ::World.getTime().Days;

				c.spawnLeads();
				c.updateObjectives();
				::Skv.dbg("Skv.Rose: ACCEPTED day=" + c.m.DayAccepted + " diff=" + c.getDifficultyMult() + " fee=" + c.finalPay());

				this.World.Contracts.setActiveContract(c);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				local c = this.Contract;
				c.updateObjectives();
				for (local k = 0; k < 4; k = k + 1)
				{
					local mk = c.marker(k);
					if (!::MSU.isNull(mk)) mk.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;

				local f = this.Flags.get("F20");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V20") == f;
					local ran = this.Flags.get("R20") == f;
					this.Flags.set("F20", "");
					this.Flags.set("V20", "");
					this.Flags.set("R20", "");

					if (!won && !ran)
					{
						::logInfo("Skv.Rose: " + f + " was launched but never resolved - no state change.");
					}
					else if (f == "Skv20Alley")
					{
						c.m.Alley = won ? 1 : 2;
						c.m.Leads = c.m.Leads | 1;
						if (won) c.m.Found = c.m.Found | 1;
						c.killSite(C.KindDocks);
						c.m.Rows = won ? c.edgeRows(1) : [ c.badRow("The guild lead is lost") ];
						::Skv.dbg("Skv.Rose: the alley " + (won ? "WON" : "FLED") + " -> leads=" + c.m.Leads + " found=" + c.m.Found);
						c.updateObjectives();
						c.setScreen(won ? "AlleyAfter" : "AlleyFled");
						this.World.Contracts.showActiveContract();
						return;
					}
					else if (f == "Skv20Sewer")
					{
						c.m.Sewer = won ? 1 : 2;
						c.m.Leads = c.m.Leads | 2;
						if (won) c.m.Found = c.m.Found | 2;
						c.killSite(C.KindDrain);
						c.m.Rows = won ? c.edgeRows(2) : [ c.badRow("The kobold lead is lost") ];
						::Skv.dbg("Skv.Rose: the sewer " + (won ? "WON" : "FLED") + " -> leads=" + c.m.Leads + " found=" + c.m.Found);
						c.updateObjectives();
						c.setScreen(won ? "Stash" : "SewerFled");
						this.World.Contracts.showActiveContract();
						return;
					}
					else if (f == "Skv20Finale")
					{

						local open = 0;
						for (local k = 0; k < 3; k = k + 1) if (c.markerLive(k)) open = open + 1;
						c.m.Finale = won ? 1 : 2;
						c.m.Act = 1;
						c.killAll();
						local rows = [];
						if (open > 0) rows.push(c.badRow("The leads you did not follow have gone cold"));
						c.m.Rows = rows;
						::Skv.dbg("Skv.Rose: the finale " + (won ? "WON" : "FLED") + " -> act 1, " + open + " open lead(s) gone cold, found=" + c.m.Found);
						c.setScreen(won ? "Nelfurhin" : "FinaleFled");
						this.World.Contracts.showActiveContract();
						return;
					}
				}

				if (c.m.Act != 0) return;

				local missing = c.missingSites();
				if (missing.len() > 0)
				{
					local tries = this.TempFlags.get("RoseRepairs");
					if (typeof tries != "integer") tries = 0;
					if (tries < C.RepairTries)
					{
						this.TempFlags.set("RoseRepairs", tries + 1);
						foreach (k in missing)
						{
							local line = null;
							try { line = c.spawnSite(k); }
							catch (e) { ::logError("Skv.Rose: REPAIR of " + C.Sites[k].Name + " threw (attempt " + (tries + 1) + " of " + C.RepairTries + ") - " + e); }
							if (c.markerLive(k)) ::logInfo("Skv.Rose: REPAIRED a missing marker (attempt " + (tries + 1) + "): " + line);
							else ::logError("Skv.Rose: REPAIR of " + C.Sites[k].Name + " left no marker (attempt " + (tries + 1) + " of " + C.RepairTries + ").");
						}
						c.updateObjectives();
					}
					else if (!this.TempFlags.get("RoseRepairGaveUp"))
					{
						this.TempFlags.set("RoseRepairGaveUp", true);
						::logError("Skv.Rose: " + missing.len() + " marker(s) still missing after " + C.RepairTries
							+ " repair attempts; giving up until the next load (::skvrosejump can place them by hand).");
					}
				}

				if (c.getActiveScreen() == null && (c.coldCase() || c.wordDue()))
				{
					local s = c.coldCase() ? "Cold" : "Word";
					::logInfo("Skv.Rose: " + s + " is due with no screen open (leads=" + c.m.Leads + " found=" + c.m.Found + ") -> opening it.");
					c.setScreen(s);
					this.World.Contracts.showActiveContract();
					return;
				}

				for (local k = 0; k < 4; k = k + 1)
				{
					local mk = c.marker(k);
					local latch = C.Sites[k].Latch;
					if (::MSU.isNull(mk)) continue;
					if (c.isPlayerAt(mk))
					{
						if (!this.TempFlags.get(latch))
						{
							this.TempFlags.set(latch, true);
							local s = c.leadScreen(k);
							if (s != null && c.getActiveScreen() == null)
							{

								c.m.Rows = [];
								::Skv.dbg("Skv.Rose: at " + C.Sites[k].Name + " -> " + s);
								c.setScreen(s);
								this.World.Contracts.showActiveContract();
								return;
							}
						}
					}
					else
					{
						this.TempFlags.set(latch, false);
					}
				}
			}

			function onCombatAlley()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.CombatID = "Skv20Alley";
				p.Tile = c.siteTile(C.KindDocks);
				p.TerrainTemplate = "tactical.plains";
				p.LocationTemplate = clone ::Const.Tactical.LocationTemplate;

				p.LocationTemplate.Template = clone ::Const.Tactical.LocationTemplate.Template;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = ::Const.Tactical.FortificationType.None;
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = c.alleyCircle() ? ::Const.Tactical.DeploymentType.Circle : ::Const.Tactical.DeploymentType.Line;
				try { p.Music = ::Const.Music.BanditTracks; } catch (e) { ::logError("Skv.Rose: no BanditTracks - " + e); }
				p.Entities = [];
				local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Bandits).getID();
				local budget = c.alleyBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.BanditRaiders, budget, fac, "Rose/Alley", ::Const.World.Spawn.BanditRaiders);
				::Skv.dbg("Skv.Rose: the alley. budget=" + budget + " (" + C.AlleyBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + (c.alleyWarned() ? " + warned " + C.AlleyWarned : "") + ") units=" + p.Entities.len()
					+ " deploy=" + (c.alleyCircle() ? "Circle" : "Line") + " (list MinR may raise a small budget)");
				this.Flags.set("F20", "Skv20Alley");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatSewer()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				local T = ::Const.World.Spawn.Troops;
				local p = c.indoorCombat("Skv20Sewer", c.siteTile(C.KindDrain), false);
				try { p.Music = ::Const.Music.GoblinsTracks; } catch (e) { ::logError("Skv.Rose: no GoblinsTracks - " + e); }
				local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Bandits).getID();
				local guile = c.getDifficultyMult() >= C.SewerCasterSplit;
				local lead = guile ? T.SkvKoboldGuilecaster : T.SkvKoboldScalecaster;
				p.Entities.push(c.troop(lead, fac, null, C.SharkName, c.onSharkPlaced.bindenv(c)));
				for (local i = 0; i < C.SewerBlades; i = i + 1) p.Entities.push(c.troop(T.SkvKoboldBlade, fac));
				local fixed = lead.Cost + C.SewerBlades * T.SkvKoboldBlade.Cost;
				local budget = c.sewerBudget(fixed);
				local extra = budget - fixed;
				if (extra >= C.SewerFillMin)
					::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionKobolds, extra, fac, "Rose/Sewer", ::Const.World.Spawn.GolarionKobolds);
				local allies = 0;
				if (c.fazgynJoins())
				{
					p.Entities.push(c.troop(T.SkvKoboldMasterTrapper, ::Const.Faction.PlayerAnimals, 1, C.FazgynName, c.onFazgynPlaced.bindenv(c)));
					for (local i = 0; i < C.FazgynKobolds; i = i + 1)
						p.Entities.push(c.troop(T.SkvKobold, ::Const.Faction.PlayerAnimals, 1, null, c.onFazgynPlaced.bindenv(c)));
					allies = 1 + C.FazgynKobolds;
				}
				::Skv.Spawn.check(p.Entities, "Rose/Sewer");
				::Skv.dbg("Skv.Rose: the sewer. leader=" + (guile ? "Guilecaster" : "Scalecaster") + " fixed=" + fixed
					+ " budget=" + budget + " (" + C.SewerBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ ") fill=" + (extra >= C.SewerFillMin ? extra : 0) + " units=" + p.Entities.len()
					+ " allies=" + allies + " (tunnel=" + c.m.Tunnel + ", FazgynEnabled=" + C.FazgynEnabled + ")");
				this.Flags.set("F20", "Skv20Sewer");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatFinale()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				local T = ::Const.World.Spawn.Troops;
				local p = c.indoorCombat("Skv20Finale", c.siteTile(C.KindSinkhole), c.finaleCircle());
				try { p.Music = ::Const.Music.UndeadTracks; } catch (e) { ::logError("Skv.Rose: no UndeadTracks - " + e); }
				local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Undead).getID();
				p.Entities.push(c.troop(T.SkeletonHeavy, fac, 0, C.WennelName, c.onWennelPlaced.bindenv(c)));
				for (local i = 0; i < C.FinaleZombies; i = i + 1) p.Entities.push(c.troop(T.Zombie, fac));
				if (c.remnaJoins()) p.Entities.push(c.troop(T.SkeletonLight, fac, 0, C.RemnaName, c.onRemnaPlaced.bindenv(c)));
				local budget = c.finaleBudget();
				local extra = budget - C.FinaleFixed;
				local bought = 0;
				local guard = 0;
				while (extra >= T.Zombie.Cost && guard < 40)
				{
					guard = guard + 1;
					local pick = (extra >= T.ZombieYeoman.Cost && ::Math.rand(1, 2) == 1) ? T.ZombieYeoman : T.Zombie;
					p.Entities.push(c.troop(pick, fac));
					extra = extra - pick.Cost;
					bought = bought + 1;
				}
				::Skv.Spawn.check(p.Entities, "Rose/Finale");
				::Skv.dbg("Skv.Rose: the finale. budget=" + budget + " (" + C.FinaleBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + ", floor " + C.FinaleMin + ", fixed charge " + C.FinaleFixed + ") extras=" + bought
					+ " units=" + p.Entities.len() + " remna=" + c.remnaJoins() + " door=" + c.m.Door
					+ " deploy=" + (c.finaleCircle() ? "Circle" : "Line") + " found=" + c.m.Found);
				this.Flags.set("F20", "Skv20Finale");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv20") return;
				this.Flags.set("V20", _combatID);
				::Skv.dbg("Skv.Rose: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F20");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R20", f);
				::Skv.dbg("Skv.Rose: retreated from " + f + " (id=" + _combatID + ")");
			}
		});

		this.m.States.push({
			ID = "Return",
			function start()
			{
				this.Contract.updateObjectives();
			}

			function update()
			{
				local c = this.Contract;
				if (c.m.Act != 1) return;
				if (c.m.Home == null || c.m.Home.isNull()) return;
				local arrived = c.isPlayerAt(c.m.Home);
				if (!arrived)
				{
					try
					{
						local t = ::World.State.getCurrentTown();
						if (t != null && t.getID() == c.m.Home.getID()) arrived = true;
					}
					catch (e) { ::Skv.dbg("Skv.Rose: getCurrentTown threw - " + e); }
				}
				if (!arrived) return;
				if (c.getActiveScreen() != null) return;
				c.setScreen("Pay");
				this.World.Contracts.showActiveContract();
			}
		});
	}

	function createScreens()
	{

		foreach (s in this.Const.Contracts.NegotiationDefault)
		{
			if (s.ID != "Negotiation")
			{
				this.m.Screens.push(s);
				continue;
			}
			local neg = clone s;
			local stockStart = s.start;
			neg.start <- function ()
			{
				stockStart();
				local kept = [];
				local dropped = 0;
				foreach (o in this.Options)
				{
					if (o.Text == "We need payment in advance." || o.Text == "We need more payment in advance.")
					{
						dropped++;
						continue;
					}
					kept.push(o);
				}
				this.Options = kept;
				if (dropped == 0)
					::logError("Skv.Rose: the negotiation's advance button was not found (Legends changed its text?); the player can haggle an advance #20 will not pay.");
			};
			this.m.Screens.push(neg);
		}

		local stock = this.Const.Contracts.Overview[0];
		local ov = clone stock;
		ov.Options = [];
		foreach (o in stock.Options)
		{
			if (o.Text == "I accept this contract.")
			{
				local inner = o.getResult;
				ov.Options.push({
					Text = o.Text,
					getResult = function ()
					{
						inner();
						return "Hunt";
					}
				});
			}
			else
			{
				ov.Options.push({ Text = o.Text, getResult = o.getResult });
			}
		}
		this.m.Screens.push(ov);

		this.m.Screens.push({
			ID = "Task",
			Title = "The Rose Street Revenge",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgLodge) + "{The man who receives you in the hall of the Pathfinder lodge is %SKVNAME%Valsin%SKVNAME_OFF%, and he has the look of a man who has not slept.%SPEECH_ON%Three nights ago one of my agents, Nelfurhin Zor, was taken off the street on her way home. People here call the one who took her the Rose Street Killer, and she is not the first. Every one taken was a freed slave, and every one was known to Milani's faithful, who buy men and women out of chains, or carry them out when buying is not possible.\n\nI have three leads and nobody to send. The streets blame the Bloody Barbers, a guild of cutthroats down at the docks. The Sewer Dragons, kobolds who live under the city and have been friends to this lodge, ask for help against newcomers in their tunnels. And a guard in the drowned quarter says a freed man is hiding there and will not come out.\n\nI need outside hands. There is no advance. I pay when you come back.%SPEECH_OFF%}";
				this.Options = [
					{
						Text = "{We'll take the hunt.}",
						function getResult() { return "Negotiation"; }
					}
				];
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{What do the men know of this?}",
						function getResult() { return "Lore"; }
					});
				}
				this.Options.push({
					Text = "{Find someone else.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "Lore",
			Title = "What the Men Know",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [
				{
					Text = "{Back to Valsin.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
				this.Text = this.Contract.img(::Const.Skv.Rose.ImgLodge) + "{%randombrother% has heard names like this one before, and he starts there.%SPEECH_ON%Every harbour has a corner where a woman sells roses to the sailors. The first of the victims went missing near the one here, so the street named the killer after it. A name like that means nothing more.%SPEECH_OFF%%randombrother2% knows of Milani's faithful only by rumour, and says so.%SPEECH_ON%They buy slaves free, and when the price is too high they steal them. Slavers hate them more than they hate the watch. If somebody is killing the people they freed, I would want to know who is paid for it.%SPEECH_OFF%One of the older men has a question of his own: whether a kobold that talks and trades can be trusted any more than one that bites. Nobody has an answer for him.}";
			}
		});

		this.m.Screens.push({
			ID = "Hunt",
			Title = "Three Leads",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				this.Text = c.img(C.ImgLodge) + "{Valsin marks three places for you: the shanty docks, where the Barbers keep their back ways; the drain outfall, where the Sewer Dragons keep watch; and the drowned quarter, where the freedman is hiding. Any of them may tell you who took Nelfurhin. Where you begin is your choice.}";
				local rows = [];
				for (local k = 0; k < 3; k = k + 1)
				{
					if (c.markerLive(k)) rows.push(c.goodRow("Marked on your map: " + C.Sites[k].Name));
				}
				this.List = rows;
				this.Options = [
					{
						Text = "{To the road.}",
						function getResult() { return 0; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Docks",
			Title = "The Shanty Docks",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local n = c.rumourCost();
				this.Text = c.img(::Const.Skv.Rose.ImgDocks) + "{The Bloody Barbers keep no sign and no door anyone will admit to. The shanty docks are all rope, tar and people who saw nothing. Someone here can point you to the guild, but asking the wrong person sends word ahead of you faster than you can walk.\n\n"
					+ (c.canPay(n) ? "You could ask the people mending nets, pass for men who want to hire a blade, or simply pay for drinks until someone talks.}" : "You could ask the people mending nets, or pass for men who want to hire a blade.}");
				this.List = [];
				this.Options = [
					{
						Text = "{Ask among the net-menders.}",
						function getResult() { return this.Contract.resolveRumours(2); }
					},
					{
						Text = "{Pose as men looking to hire a blade.}",
						function getResult() { return this.Contract.resolveRumours(3); }
					}
				];

				if (c.canPay(n))
				{
					this.Options.push({
						Text = "{Buy drinks for the right people. (" + n + " Crowns)}",
						function getResult() { return this.Contract.resolveRumours(1); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Barbershop",
			Title = "The Smiling Cut",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgDocks) + "{The trail ends at a barber's shop with a striped pole and a basin by the door. %SKVNAME%Valette%SKVNAME_OFF%, the barber, sharpens her razor and tells you nothing at all, very politely.\n\nHer sweep boy is another matter. %SKVNAME%Snips%SKVNAME_OFF% is perhaps twelve years old and wants his first shave from the guild more than anything in the world. He offers to show you the back way to the people you are looking for. His eyes keep going to the alley door, and his fingers keep going to his lips, as if to whistle.\n\nYou could grab him before he can whistle a warning, or frighten him until he tells you everything himself.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Grab the boy before he can whistle.}",
						function getResult() { return this.Contract.resolveSnips(false); }
					},
					{
						Text = "{Frighten the truth out of him.}",
						function getResult() { return this.Contract.resolveSnips(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Alley",
			Title = "The Back Alley",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local circle = c.alleyCircle();
				this.Text = c.img(::Const.Skv.Rose.ImgAlley) + (circle
					? "{The whistle is still in the air when the Barbers step out of the doorways on every side of the alley, razors and cudgels in hand. One of them calls out that they want one of you alive, to learn who is asking questions about the guild.}"
					: "{The Barbers are where the boy said they would be, and they step out into the alley in a line, razors and cudgels in hand. One of them calls out that they want one of you alive, to learn who is asking questions about the guild.}");

				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (rows.len() == 0)
				{
					if (circle) rows.push(c.badRow("The boy whistled a warning"));
					else rows.push(c.goodRow("The boy told you who was waiting where"));
				}
				if (c.alleyWarned()) rows.push(c.badRow("Word of you ran ahead, and more of them were waiting"));
				else rows.push(c.goodRow("No word of you ran ahead from the docks"));
				this.List = rows;
				this.Options = [
					{
						Text = "{Let them come.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Alley != 0) return 0;
							c.getActiveState().onCombatAlley();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AlleyAfter",
			Title = "A Barber Talks",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgAlley) + "{One Barber is left alive, and he talks quickly once he understands you are not the killer.%SPEECH_ON%You think we did it? We are hunting him too. %SKVNAME%Remna%SKVNAME_OFF% was one of ours, a freed woman and good with a razor, and she has been gone a week. People who saw him say he wears plate and moves as if his right side is hurt.%SPEECH_OFF%He hesitates, then decides that his life is worth more than a colleague's secret.%SPEECH_ON%There is something else. Last season one of ours took work outside the guild. A respectable man, a broker, paid him to kill a half-elf priest.%SPEECH_OFF%He gives you the broker's name, and asks only to walk away. You could let him go back to his guild, which may repay the favour, or hand him to the city watch, which pays for Barbers.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Let him go back to his guild.}",
						function getResult() { return this.Contract.resolveCaptive(true); }
					},
					{
						Text = "{Hand him to the watch.}",
						function getResult() { return this.Contract.resolveCaptive(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Captive",
			Title = "The Captive",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgAlley) + (c.m.Captive == 1
					? "{The Barber runs off into the docks without looking back. He will tell his guild that you could have handed him over and did not, and the Barbers keep a careful account of such things.}"
					: "{The watch takes the Barber away in irons, and its sergeant counts out the bounty with the face of a man who wishes he had caught him himself.}");
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the road.}",
						function getResult() { return this.Contract.afterLead(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AlleyFled",
			Title = "Driven Off",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgAlley) + "{The Barbers know these alleys and you do not. By the time the company has pulled back to the open quay, they have hidden themselves, and nobody on the docks will say the guild's name aloud now.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the road.}",
						function getResult() { return this.Contract.afterLead(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Outfall",
			Title = "The Drain Outfall",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgOutfall) + "{Where the city's great drain spills into the sea, a grey kobold sits on the stones with a begging bowl. He is not begging. His eyes go over every man in the company, and when you say Valsin's name he empties the bowl, stands up, and waves you into the tunnel after him.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Lead the way.}",
						function getResult() { return "Fazgyn"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Fazgyn",
			Title = "Fazgyn's Plan",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				this.Text = c.img(C.ImgFazgyn) + "{The Sewer Dragons' trapmaster, %SKVNAME%" + C.FazgynName + "%SKVNAME_OFF%, receives you in a dry chamber full of wire and sharpened scrap. He speaks your tongue carefully, like a merchant counting coins.%SPEECH_ON%The newcomers call themselves the Dragon Sharks. They crossed from the far side of the island this season, and they did not come for the fishing. Somebody in the city pays them to make bodies disappear in the drains. We want them gone. You want to know who pays them. Good.\n\nMy squad goes round by the old cistern, and you go straight at them. There are two ways. The short tunnel has a blade trap the Sharks set; if it goes off, they will hear it, and my squad will be cut off from you. The long way crosses a pit on a narrow ledge. It is quiet if you keep your feet, but if too many of you fall, they will hear that too, and my squad will be cut off all the same.%SPEECH_OFF%One man good with traps could take the short way for all of you. The ledge needs every man to be careful.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Disarm the blade trap.}",
						function getResult() { return this.Contract.resolveTunnel(false); }
					},
					{
						Text = "{Take the long way past the pit.}",
						function getResult() { return this.Contract.resolveTunnel(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Sharks",
			Title = "The Dragon Sharks",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				this.Text = c.img(C.ImgSharks) + "{The tunnel opens into a chamber where the Dragon Sharks have made their nest among rotten crates. Their leader is a winged kobold who calls himself %SKVNAME%" + C.SharkName + "%SKVNAME_OFF%, and sparks crawl over his claws. "
					+ (c.m.Tunnel == 2 || c.m.Tunnel == 4 ? "The noise has carried, and his blades are waiting for you.}" : "His blades are still finding their weapons when you come in.}");
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (rows.len() == 0)
				{
					if (c.fazgynJoins()) rows.push(c.goodRow("Fazgyn's squad got through to fight beside you"));
					else if (C.FazgynEnabled) rows.push(c.badRow("Fazgyn's squad was cut off"));
				}
				this.List = rows;
				this.Options = [
					{
						Text = "{At them.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Sewer != 0) return 0;
							c.getActiveState().onCombatSewer();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Stash",
			Title = "The Sharks' Hoard",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				this.Text = c.img(C.ImgStash) + "{Among the Sharks' junk lies a priest's journal, stained by water and written in a careful hand. Most of its pages are prayers. The last pages hold a list of names: Justerian, Remna, Aedo, Nelfurhin, Omoak. The ink of Nelfurhin's name is still fresh.\n\nBeside the journal lies a heavy purse sealed with wax, and the seal is a merchant's mark, not a guild's. When the fighting is done, %SKVNAME%" + C.FazgynName + "%SKVNAME_OFF% turns the purse over in his hands and gives it to you.%SPEECH_ON%Keep the coin. The man who paid it is worth more to us gone from our tunnels than his money is in our pockets.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantPurse)) this.List.extend(::Skv.Loot.previewRows([], c.pursePay()));
				this.Options = [
					{
						Text = "{Back to the light.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Rose;
							if (!c.hasGrant(C.GrantPurse))
							{
								c.setGrant(C.GrantPurse);
								::World.Assets.addMoney(c.pursePay());
								::Skv.dbg("Skv.Rose: the Sharks' purse granted: " + c.pursePay());
							}
							c.m.Rows = [];
							return c.afterLead();
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "SewerFled",
			Title = "Driven Off",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgSharks) + "{The Sharks hold the tunnel. The company comes out of the drain wet, bloodied and empty-handed, and the Sewer Dragons will have to deal with the newcomers on their own.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the road.}",
						function getResult() { return this.Contract.afterLead(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Quarter",
			Title = "The Drowned Quarter",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgQuarter) + "{The drowned quarter is the part of the city the sea took back. Houses stand in water up to their doorsteps, joined by plank walks that move underfoot. At the end of one stands %SKVNAME%Ziraya%SKVNAME_OFF%, who guards the ward because nobody is paid to, with a club in her belt and a dog the size of a calf at her side. She knows of the freedman: %SKVNAME%Justerian%SKVNAME_OFF%, who stopped coming to the tavern some days ago.\n\nThe ward has no money for lamps or for repairs. Ziraya would take you there herself if you gave something to the ward fund. Otherwise you will have to win her over and ask the way.}";
				this.List = [];
				this.Options = [];
				local n = c.wardCost();
				if (c.canPay(n))
				{
					this.Options.push({
						Text = "{Give to her ward fund. (" + n + " Crowns)}",
						function getResult() { return this.Contract.resolveZiraya(true); }
					});
				}
				this.Options.push({
					Text = "{Ask her the way.}",
					function getResult() { return this.Contract.resolveZiraya(false); }
				});
			}
		});

		this.m.Screens.push({
			ID = "FrogsTongue",
			Title = "The Frog's Tongue",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local z = c.m.Ziraya;
				local how = z == 1 ? "Ziraya walks you there herself, her dog splashing ahead."
					: (z == 2 ? "Ziraya's directions bring you straight there." : "Ziraya's directions were vague, and it takes a long time to find the place.");
				this.Text = c.img(::Const.Skv.Rose.ImgQuarter) + "{" + how + " The Frog's Tongue is a tavern built over the water. Its floor is a pond with planks laid across it, and there are frogs in the corners. The cook, %SKVNAME%Dahlia%SKVNAME_OFF%, was Justerian's friend. He was frightened for days, she says, then crossed to the old manor across the water to hide, and nobody has seen him since. "
					+ (c.warned() ? "She also tells you which of the manor's stairs are rotten, and where its floors will still hold a man.}" : "She will not say more than that to strangers.}");
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (c.warned()) rows.push(c.goodRow("Dahlia told you where the floors are rotten"));
				else rows.push(c.badRow("Dahlia did not trust you enough to say more"));
				this.List = rows;
				this.Options = [
					{
						Text = "{Go to the manor.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Manor";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Manor",
			Title = "The Rotten House",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgManor) + "{The manor was a fine house once. Now it leans, its lower floor stands in water, and its stairs hang from the wall at an angle. The attic window is dark.\n\nYou could take the stairs, all of you together, or send your best climber up the outside wall with a rope for the rest.}";
				this.List = c.warned() ? [ c.goodRow("Dahlia's warning helps either way") ] : [];
				this.Options = [
					{
						Text = "{Take the stairs.}",
						function getResult() { return this.Contract.resolveClimb(false); }
					},
					{
						Text = "{Climb the outside wall.}",
						function getResult() { return this.Contract.resolveClimb(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Attic",
			Title = "The Attic",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgAttic) + "{Justerian is in the attic. He has been dead for days, his club still in his hand, and something pale and wet is slowly working its way over his body. It is no danger to men with axes. The rafters above are another matter: they are black with bats, and the bats are beginning to stir.\n\nYou could drive them out with fire, or keep still and wait for them to settle.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Light a rag and drive them off.}",
						function getResult() { return this.Contract.resolveAttic(false); }
					},
					{
						Text = "{Keep still until the bats settle.}",
						function getResult() { return this.Contract.resolveAttic(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AtticAfter",
			Title = "Justerian's Last Fight",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgAttic) + "{With the bats gone and the pale thing hacked apart, you can look at what Justerian left behind. There is grey hair and grave dirt on his club, as if he struck something that had been buried. In his fist is a holy symbol of Milani on a broken chain, torn from whatever killed him. Pale moths crawl in the corners, and %randombrother% says he has only ever seen moths like that around plague pits.\n\nAmong Justerian's things is a bill of sale, half burned, for a man who should have had his freedom papers. The buyer marked it with a seal.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the road.}",
						function getResult() { return this.Contract.afterLead(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "QuarterFled",
			Title = "The Rotten House",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgHouseFled) + "{Between " + (c.m.Climb == 4 ? "the fall from the wall" : "the rotten stairs") + " and the bats, the company comes out of the manor with nothing but bites and bruises. Before anyone can go back in, the attic floor gives way into the water below, and Justerian and whatever he knew go with it.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the road.}",
						function getResult() { return this.Contract.afterLead(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Cold",
			Title = "The Trail Goes Cold",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgLodge) + "{Every lead has come to nothing. A runner from the lodge brings Valsin's word: with nothing left to follow, he has given up the hunt, and he will not pay for one that found no one.}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				rows.push(c.badRow("The contract is lost"));

				rows.push(c.renownRow(c.coldRenown()));
				local f = c.factionOr(c.getFaction());
				rows.push(c.relRow(f != null ? f.getName() : c.townName(), false));
				this.List = rows;
				this.Options = [
					{
						Text = "{So it ends.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Rose;
							if (!c.hasGrant(C.GrantRenown))
							{
								c.setGrant(C.GrantRenown);
								::World.Assets.addBusinessReputation(c.coldRenown());
							}
							if (!c.hasGrant(C.GrantRelation))
							{
								c.setGrant(C.GrantRelation);
								local f = c.factionOr(c.getFaction());
								if (f == null) ::logError("Skv.Rose: the city-state's faction did not resolve; the failure's relation loss is not applied.");
								else f.addPlayerRelation(c.coldRelation(), "Failed to find the Rose Street Killer");
							}
							c.killAll();
							c.m.Rows = [];
							::logInfo("Skv.Rose: COLD. All three leads closed with nothing found; the contract FAILS (renown "
								+ c.coldRenown() + ", city relation " + c.coldRelation() + ", no fee). leads=" + c.m.Leads
								+ " found=" + c.m.Found + " granted=" + c.m.Granted);
							this.World.Contracts.finishActiveContract(true);
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Word",
			Title = "Word from the Lodge",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgLodge) + "{A runner from the lodge finds you with a message from Valsin. He showed what you found to Milani's faithful, and it told them something they had not wanted to see: every one of the victims spent their first free nights in the same place, the cellar of the Sanguine Thorn. It was an inn until an old earthquake dropped it into a sinkhole, and the faithful kept using its cellar because nobody else goes down there.\n\nValsin asks you to go when you are ready. Once that is done, he adds, any lead you have not followed will no longer matter.}";
				this.List = [ c.goodRow("A new place is marked on your map") ];
				this.Options = [
					{
						Text = "{Then the sinkhole.}",
						function getResult()
						{
							local c = this.Contract;
							if (!c.m.WordSent)
							{

								c.m.WordSent = true;
								try { c.spawnSite(::Const.Skv.Rose.KindSinkhole); }
								catch (e) { ::logError("Skv.Rose: could not spawn the sinkhole (Running.update will repair it) - " + e); }
								if (!c.markerLive(::Const.Skv.Rose.KindSinkhole))
									::logError("Skv.Rose: the Word closed with no sinkhole marker; Running.update will repair it.");
								c.updateObjectives();
								::Skv.dbg("Skv.Rose: WORD sent; the sinkhole is marked. leads=" + c.m.Leads + " found=" + c.m.Found);
							}
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Sinkhole",
			Title = "The Sinkhole",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgSinkhole) + "{Fog lies in the sinkhole like water in a bowl. At the bottom, among broken walls and the roots of trees that grew there after the quake, you can make out the roof of the Sanguine Thorn. The only way down is a slope of loose earth and rubble.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Climb down.}",
						function getResult() { return this.Contract.resolveDescent(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "InnDoor",
			Title = "The Sanguine Thorn",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgInnDoor) + "{The inn has sunk to its upper windows. Its front door sits under a sagging roof that will not take much more. There are two other ways in: a side door, reached through deep mud, or the holes in a wall overgrown with vines. The mud is slow and loud, but there is no hiding that you came. The vines might take you in unseen, or might not."
					+ (c.m.Captive == 1 ? "\n\nOn the way down, a Barber's runner found you with a message from his guild: Remna's trail ended at the side door, and the firm ground runs along the old wall.}" : "}");
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{The side door, through the mud.}",
						function getResult() { return this.Contract.resolveDoor(false); }
					},
					{
						Text = "{Through the holes in the vine-grown wall.}",
						function getResult() { return this.Contract.resolveDoor(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Wennel",
			Title = "The Dead Priest",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgWennel) + "{In the inn's cellar a man in plate armour stands among broken tables, with two corpses swaying at his side. He was a priest once; a rose is worked into his breastplate. He is dead, and he does not seem to know it. He is reciting names under his breath, and when he sees you he stops.%SPEECH_ON%More of you. Murderers, all of you. I will settle every account.%SPEECH_OFF%}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (rows.len() == 0)
				{
					local who = c.knowsRemna() ? "Remna" : "A dead woman with a barber's razor";
					if (c.remnaJoins()) rows.push(c.badRow(c.finaleCircle() ? "The dead spread out to meet you" : who + " was waiting with him"));
					if (c.remnaJoins() && c.finaleCircle()) rows.push(c.badRow(who + " was among them"));
					if (!c.remnaJoins()) rows.push(c.goodRow(who + " stayed caught in the roots"));
				}
				rows.extend(c.wennelRows());
				this.List = rows;
				this.Options = [
					{
						Text = "{End it.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Finale != 0) return 0;
							c.getActiveState().onCombatFinale();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Nelfurhin",
			Title = "Below the Floor",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgRescue) + "{The dead priest falls apart inside his armour, and the cellar goes quiet. Below a rotten part of the floor you find %SKVNAME%Nelfurhin Zor%SKVNAME_OFF%, alive, with a broken leg and a voice gone hoarse from calling out.\n\nShe was taken from the street, she tells you, by a man in armour who called her one of his murderers. All the way here he kept saying the names of people she knew, freed people, as if he were reading out their sentence. Once he said his own name too: Wennel. Whatever was done to him, he blamed the wrong people for it.\n\nHer word against whoever began all this is worth something, and she knows it.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Get her out, and back to Valsin.}",
						function getResult()
						{
							local c = this.Contract;
							c.m.Rows = [];
							c.setState("Return");
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "FinaleFled",
			Title = "Out of the Pit",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Rose.ImgSinkhole) + "{The dead hold the cellar. The company climbs out of the sinkhole with its wounded, and Nelfurhin is still somewhere below. Valsin will have to be told.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to Valsin.}",
						function getResult()
						{
							local c = this.Contract;
							c.m.Rows = [];
							c.setState("Return");
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Pay",
			Title = "Valsin",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local fled = c.m.Finale == 2;
				this.Text = c.img(::Const.Skv.Rose.ImgLodge) + (fled
					? "{Valsin hears that the killer still holds the cellar and that Nelfurhin was not reached. He pays half of what was agreed, without complaint and without thanks.}"
					: "{Valsin listens to all of it, then sends Nelfurhin to the lodge's healer and pays what was agreed.%SPEECH_ON%Outside hands, as I said. You did what my own people could not.%SPEECH_OFF%}");
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				local C = ::Const.Skv.Rose;

				if (!c.hasGrant(C.GrantFee))
					rows.push({ id = 1, icon = "ui/icons/asset_money.png",
						text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.finalPay()) + " Crowns" });
				if (!c.hasGrant(C.GrantRenown)) rows.push(c.renownRow(c.payRenown()));
				if (!fled && !c.hasGrant(C.GrantRelation))
				{
					local f = c.factionOr(c.getFaction());
					rows.push(c.relRow(f != null ? f.getName() : c.townName(), true));
				}
				this.List = rows;
				this.Options = [
					{
						Text = c.evidenceOffered() ? "{Take the coin and step outside.}" : "{Then we're done here.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Rose;
							local A = ::Const.World.Assets;
							local fled = c.m.Finale == 2;
							if (!c.hasGrant(C.GrantFee))
							{
								c.setGrant(C.GrantFee);
								::World.Assets.addMoney(c.finalPay());
							}
							if (!c.hasGrant(C.GrantRenown))
							{
								c.setGrant(C.GrantRenown);

								::World.Assets.addBusinessReputation(c.payRenown());
							}
							if (!fled && !c.hasGrant(C.GrantRelation))
							{
								c.setGrant(C.GrantRelation);
								local f = c.factionOr(c.getFaction());
								if (f == null) ::logError("Skv.Rose: the city-state's faction did not resolve; its relation is lost.");
								else f.addPlayerRelation(A.RelationNobleContractSuccess, "Found the Rose Street Killer");
							}
							::Skv.dbg("Skv.Rose: PAID fee=" + c.finalPay() + " fled=" + fled + " found=" + c.m.Found
								+ " leads=" + c.m.Leads + " granted=" + c.m.Granted + " evidence offered=" + c.evidenceOffered());
							c.m.Act = 2;
							c.m.Rows = [];
							if (c.evidenceOffered()) return "Evidence";
							c.m.Evidence = 4;
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Evidence",
			Title = "What the Dead Man Knew",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local T = c.foundCount();
				this.Text = c.img(::Const.Skv.Rose.ImgEvidence) + (T > 0
					? "{Outside the lodge a soft-spoken man in good clothes is waiting for you. He does not give his name. He speaks for a gentleman, he says, who would pay well for any papers the company may have picked up, and who would be sorry to see them in the wrong hands. From what you found, you already know whose man he is.\n\nThe proof could go to Milani's faithful, who would use it to protect their people; to the city's magistrates, who might act on it; or to this man, who will burn it.}"
					: "{You found no papers along the way, but Nelfurhin's word is evidence of its own, and Valsin asks where it should go. Milani's faithful would like to hear it, to protect their people. So would the city's magistrates, who might act on it.}");
				this.List = [];
				this.Options = [
					{
						Text = "{Give it all to Milani's faithful.}",
						function getResult() { return this.Contract.resolveEvidence(1); }
					},
					{
						Text = "{Take it to the city's magistrates.}",
						function getResult() { return this.Contract.resolveEvidence(2); }
					}
				];
				if (T > 0)
				{
					this.Options.push({
						Text = "{Sell it to the broker's man.}",
						function getResult() { return this.Contract.resolveEvidence(3); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "EvidenceAfter",
			Title = "The Evidence",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Rose;
				local e = c.m.Evidence;
				if (e == 1)
					this.Text = c.img(C.ImgFaithful) + "{Milani's faithful take what you bring them without ceremony. By morning the people they freed have been moved to new hiding places, and the faithful will go after the broker in their own way, which is not the magistrates' way.}";
				else if (e == 2)
					this.Text = c.img(C.ImgLaw) + "{A magistrate reads what you brought, fines the broker heavily, and closes the matter. The men who did his work are not touched. It is the law, and the law is slow.}";
				else
					this.Text = c.img(C.ImgBroker) + "{The man counts out the coin without haste. Then he feeds the papers into a brazier on the corner, one sheet at a time, and thanks you for your discretion.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Farewell.}",
						function getResult()
						{
							local c = this.Contract;
							::Skv.dbg("Skv.Rose: CLOSED. evidence=" + c.m.Evidence + " found=" + c.m.Found + " granted=" + c.m.Granted);
							c.m.Rows = [];
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});
	}

	function onClear()
	{
		::Skv.Once.release(::Const.Skv.Rose.OnceKey);
		if (this.m.IsActive)
		{
			::Skv.Once.retire(::Const.Skv.Rose.OnceKey);

			this.killAll();
		}
	}

	function onIsValid()
	{
		return true;
	}

	function writeMarker( _out, _ref )
	{
		_out.writeU32(::MSU.isNull(_ref) ? 0 : _ref.getID());
	}

	function readMarker( _in )
	{
		local id = _in.readU32();
		if (id == 0) return null;
		local e = ::World.getEntityByID(id);
		if (e == null)
		{

			::logInfo("Skv.Rose: a saved marker id " + id + " resolved to nothing on load; the repair will respawn it if it is still needed.");
			return null;
		}
		return this.WeakTableRef(e);
	}

	function onSerialize( _out )
	{
		this.writeMarker(_out, this.m.Docks);
		this.writeMarker(_out, this.m.Drain);
		this.writeMarker(_out, this.m.Quarter);
		this.writeMarker(_out, this.m.Sinkhole);
		_out.writeU16(this.m.DayAccepted);
		_out.writeU8(this.m.Act);
		_out.writeU8(this.m.Leads);
		_out.writeU8(this.m.Found);
		_out.writeBool(this.m.WordSent);
		_out.writeU8(this.m.Rumours);
		_out.writeU16(this.m.RumoursPaid);
		_out.writeU8(this.m.Snips);
		_out.writeU8(this.m.Alley);
		_out.writeU8(this.m.Captive);
		_out.writeU8(this.m.Tunnel);
		_out.writeU8(this.m.Sewer);
		_out.writeU8(this.m.Ziraya);
		_out.writeU16(this.m.DonationPaid);
		_out.writeU8(this.m.Climb);
		_out.writeU8(this.m.Attic);
		_out.writeU8(this.m.Descent);
		_out.writeU8(this.m.Door);
		_out.writeU8(this.m.TalkDown);
		_out.writeU8(this.m.Finale);
		_out.writeU8(this.m.Evidence);
		_out.writeU16(this.m.Granted);
		_out.writeString(this.m.ActorName);
		local rows = this.m.Rows == null ? [] : this.m.Rows;
		local n = ::Math.min(255, rows.len());
		if (rows.len() > 255) ::logError("Skv.Rose: " + rows.len() + " rows on the open screen; only 255 are saved.");
		_out.writeU8(n);
		for (local i = 0; i < n; i++)
		{
			_out.writeString(rows[i].icon);
			_out.writeString(rows[i].text);
		}
		_out.writeU16(this.m.Res16);
		_out.writeU32(this.m.Res32);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.m.Docks = this.readMarker(_in);
		this.m.Drain = this.readMarker(_in);
		this.m.Quarter = this.readMarker(_in);
		this.m.Sinkhole = this.readMarker(_in);
		this.m.DayAccepted = _in.readU16();
		this.m.Act = _in.readU8();
		this.m.Leads = _in.readU8();
		this.m.Found = _in.readU8();
		this.m.WordSent = _in.readBool();
		this.m.Rumours = _in.readU8();
		this.m.RumoursPaid = _in.readU16();
		this.m.Snips = _in.readU8();
		this.m.Alley = _in.readU8();
		this.m.Captive = _in.readU8();
		this.m.Tunnel = _in.readU8();
		this.m.Sewer = _in.readU8();
		this.m.Ziraya = _in.readU8();
		this.m.DonationPaid = _in.readU16();
		this.m.Climb = _in.readU8();
		this.m.Attic = _in.readU8();
		this.m.Descent = _in.readU8();
		this.m.Door = _in.readU8();
		this.m.TalkDown = _in.readU8();
		this.m.Finale = _in.readU8();
		this.m.Evidence = _in.readU8();
		this.m.Granted = _in.readU16();
		this.m.ActorName = _in.readString();
		local n = _in.readU8();
		this.m.Rows = [];
		for (local i = 0; i < n; i++)
		{
			local icon = _in.readString();
			local text = _in.readString();
			this.m.Rows.push({ id = 1, icon = icon, text = text });
		}
		this.m.Res16 = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.contract.onDeserialize(_in);
	}
});
