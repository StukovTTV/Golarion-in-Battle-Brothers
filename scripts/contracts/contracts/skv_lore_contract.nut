this.skv_lore_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Shop        = null,
		Temple      = null,
		Sage        = null,
		Envoy       = null,
		DayAccepted = 0,
		Act         = 0,
		Closed      = 0,
		Done        = 0,
		Karela      = 0,
		Entry       = 0,
		Rats        = 0,
		Crate       = 0,
		Dive        = 0,
		Goods       = 0,
		Gossip      = 0,
		Medicine    = 0,
		Secrets     = 0,
		Report      = 0,
		Moves       = 5,
		Vault       = 0,

		Blue        = 0,
		Imp         = 0,
		Case        = 0,
		Opener      = 0,
		Tails       = 0,
		Spotter     = "",
		Alley       = 0,
		Ledford     = 0,
		Revealed    = 0,
		Zarta       = 0,
		Band        = 0,
		Granted     = 0,
		ActorName   = "",
		Rows        = null,
		Gang        = 0,

		Res32       = 0
	},

	function hasGrant( _bit ) { return (this.m.Granted & _bit) != 0; }
	function isClosed( _bit ) { return (this.m.Closed & _bit) != 0; }
	function isDone( _bit ) { return (this.m.Done & _bit) != 0; }

	function countBits( _v )
	{
		local n = 0;
		foreach (b in [1, 2, 4, 8]) if ((_v & b) != 0) n = n + 1;
		return n;
	}
	function closedCount() { return this.countBits(this.m.Closed); }
	function doneCount() { return this.countBits(this.m.Done); }

	function factionOr( _id )
	{
		try { return ::World.FactionManager.getFaction(_id); }
		catch (e) { ::logError("Skv.Lore: faction " + _id + " did not resolve - " + e); }
		return null;
	}

	function townName()
	{
		return (this.m.Home != null && !this.m.Home.isNull()) ? this.m.Home.getName() : "the city";
	}

	function goodRow( _text ) { return { id = 1, icon = "ui/icons/special.png", text = _text }; }
	function badRow( _text )  { return { id = 1, icon = "ui/icons/regular_damage.png", text = _text }; }

	function img( _name ) { return "[img]gfx/ui/events/" + _name + ".png[/img]"; }

	function sb( _base ) { return ::Skv.Check.scaledBase(this, _base); }

	function actorName( _r, _mid = false )
	{
		if (_r != null && "actor" in _r && _r.actor != null) return _r.actor.getName();
		return _mid ? "one of the company" : "One of the company";
	}

	function joinList( _a, _sep )
	{
		if (_a.len() == 0) return "none";
		local s = "";
		foreach (i, x in _a) s = s + (i == 0 ? "" : _sep) + x;
		return s;
	}

	function fee() { return this.m.Payment.getOnCompletion(); }

	function setGrant( _bit ) { this.m.Granted = this.m.Granted | _bit; }

	function kindOK() { return this.m.Band != 2; }
	function ruthlessOK() { return this.m.Band != 1; }

	function relRow( _name, _better )
	{
		return { id = 1, icon = "ui/icons/relations.png",
			text = "Your relations with " + _name + (_better ? " improve" : " worsen") };
	}

	function moneyRow( _n )
	{
		return { id = 1, icon = "ui/icons/asset_money.png",
			text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _n) + " Crowns" };
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
		catch (e) { ::logError("Skv.Lore: Legends' renown row strings did not resolve; a plain row stands in - " + e); }
		return { id = 10, icon = "ui/icons/special.png", text = _n > 0 ? "The company gains renown" : "The company loses renown" };
	}

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

		local now = "?";
		try { now = ::World.Assets.getMoralReputation(); }
		catch (e) { ::logError("Skv.Lore: getMoralReputation threw after a moral change of " + _delta + " - " + e); }
		::logInfo("Skv.Lore: moral " + (_delta < 0 ? "" : "+") + _delta + " (" + _text + ") -> now " + now);
	}

	function spotterHere()
	{
		if (this.m.Spotter == "") return false;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.getName() == this.m.Spotter) return true;
		}
		return false;
	}

	function townRel( _delta, _why, _rows )
	{
		local f = this.factionOr(this.getFaction());
		if (f == null)
		{
			::logError("Skv.Lore: the host's faction did not resolve; a relation change of " + _delta + " is lost (" + _why + ").");
			return;
		}
		f.addPlayerRelation(_delta, _why);
		_rows.push(this.relRow(f.getName(), _delta > 0));
	}

	function feeShare( _mult )
	{
		local n = ::Math.floor(this.fee() * _mult / 10.0 + 0.5) * 10;
		return n < 10 ? 10 : n;
	}

	function karelaPay()  { return this.feeShare(::Const.Skv.Lore.KarelaMult); }
	function silencePay() { return this.feeShare(::Const.Skv.Lore.SilenceMult); }
	function pursePay()   { return this.feeShare(::Const.Skv.Lore.PurseMult); }
	function watchPay()   { return this.feeShare(::Const.Skv.Lore.WatchMult); }
	function cutPay()     { return this.feeShare(::Const.Skv.Lore.CutMult); }
	function visitPay()   { return this.feeShare(::Const.Skv.Lore.VisitMult); }

	function secretsFound()
	{
		local n = 0;
		foreach (b in [1, 2, 4]) if ((this.m.Secrets & b) != 0) n = n + 1;
		return n;
	}
	function drinkFound() { return (this.m.Secrets & 1) != 0; }

	function worseFound() { return (this.m.Secrets & 6) != 0; }

	function softTold() { return (this.drinkFound() && this.worseFound()) ? 1 : 0; }

	function reportPay( _how )
	{
		local C = ::Const.Skv.Lore;
		local told = _how == 1 ? this.secretsFound() : this.softTold();
		return this.feeShare(C.BaltwinBase + C.BaltwinPerSecret * told);
	}

	function mapDelivered() { return this.isDone(::Const.Skv.Lore.Sites[::Const.Skv.Lore.KindSage].Bit) && !this.alleyLost(); }
	function caseDelivered() { return this.isDone(::Const.Skv.Lore.Sites[::Const.Skv.Lore.KindEnvoy].Bit) && !this.alleyLost(); }
	function mapPay() { return this.mapDelivered() ? this.feeShare(::Const.Skv.Lore.MapMult) : 0; }
	function casePay()
	{
		local C = ::Const.Skv.Lore;
		if (!this.caseDelivered()) return 0;
		return this.feeShare(C.CaseMult * (this.m.Case == 3 ? C.CaseScratchMult : 1.0));
	}

	function finderPay()
	{
		local C = ::Const.Skv.Lore;
		if (!this.caseDelivered() || this.m.Case != 2) return 0;
		return this.feeShare(C.FinderMult);
	}

	function wagePay()
	{
		local C = ::Const.Skv.Lore;
		local t = this.tier();
		if (t == C.TierSuccess) return this.feeShare(C.WageMult);
		if (t == C.TierPoor) return this.feeShare(C.WageMult * C.PoorWageMult);
		return 0;
	}

	function payTotal() { return this.mapPay() + this.casePay() + this.finderPay() + this.wagePay(); }

	function addStores( _kind, _n, _rows )
	{
		local A = ::World.Assets;
		local before = _kind == 0 ? A.getAmmo() : (_kind == 1 ? A.getArmorParts() : A.getMedicine());
		if (_kind == 0) A.addAmmo(_n);
		else if (_kind == 1) A.addArmorParts(_n);
		else A.addMedicine(_n);
		local after = _kind == 0 ? A.getAmmo() : (_kind == 1 ? A.getArmorParts() : A.getMedicine());
		local got = ::Math.round(after - before);
		local icon = _kind == 0 ? "ui/icons/asset_ammo.png" : (_kind == 1 ? "ui/icons/asset_supplies.png" : "ui/icons/asset_medicine.png");
		local name = _kind == 0 ? "Ammunition" : (_kind == 1 ? "Tools and Supplies" : "Medical Supplies");
		_rows.push(got > 0
			? { id = 1, icon = icon, text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, got) + " " + name }
			: { id = 1, icon = icon, text = "Your stores of " + name + " were already full" });
		::logInfo("Skv.Lore: stores " + name + " asked +" + _n + ", added +" + got + " (" + before + " -> " + after + ")");
	}

	function hurtThese( _checkRows, _min, _max )
	{
		local rows = [];
		if (_checkRows == null) return rows;
		foreach (cr in _checkRows)
		{
			if (cr.ok) continue;
			local bro = cr.bro;
			if (bro == null || !bro.isAlive()) continue;
			local dmg = ::Math.rand(_min, _max);
			local hp = bro.getHitpoints() - dmg;
			if (hp < 1) hp = 1;
			bro.setHitpoints(hp);
			rows.push({ id = 10, icon = "ui/icons/health.png", text = bro.getName() + " loses " + dmg + " health" });
		}
		return rows;
	}

	function hurtBro( _bro, _min, _max )
	{
		if (_bro == null || !_bro.isAlive())
		{
			::logInfo("Skv.Lore: hurtBro found no living brother; nobody is hurt.");
			return [];
		}
		return this.hurtThese([ { ok = false, bro = _bro } ], _min, _max);
	}

	function hurtOne( _r, _min, _max )
	{
		return this.hurtBro((_r != null && "actor" in _r) ? _r.actor : null, _min, _max);
	}

	function anyBrother( _not = null )
	{
		local pool = [];
		foreach (b in ::World.getPlayerRoster().getAll())
		{
			if (b.isInReserves() || !b.isAlive()) continue;
			local skip = false;
			if (_not != null)
			{
				foreach (x in _not) if (x != null && x.getID() == b.getID()) { skip = true; break; }
			}
			if (!skip) pool.push(b);
		}
		if (pool.len() == 0) return null;
		return pool[::Math.rand(0, pool.len() - 1)];
	}

	function ratcatcherBro()
	{
		foreach (b in ::World.getPlayerRoster().getAll())
		{
			if (b.isInReserves()) continue;
			local bg = b.getBackground();
			if (bg != null && bg.getID() == ::Const.Skv.Lore.RatcatcherBg) return b;
		}
		return null;
	}

	function wandRows( _r, _rows )
	{
		if (_r == null || !("wandRow" in _r)) return;
		local s = _r.wandRow;
		if (s.len() > 0 && s.slice(s.len() - 1) == ".") s = s.slice(0, s.len() - 1);
		_rows.push(this.goodRow(s));
	}

	function itemRow( _it )
	{
		return { id = 1, icon = "ui/items/" + _it.getIcon(), text = "You gain " + _it.getName() };
	}

	function makeOpener()
	{
		local items = ::Skv.Loot.make([ ::Const.Skv.Lore.ItemOpener ]);
		if (items.len() == 0)
		{
			::logError("Skv.Lore: the letter-opener could not be made; nothing is granted for it.");
			return items;
		}
		if (!("GolarionEnchant" in ::getroottable()))
		{
			::logError("Skv.Lore: ::GolarionEnchant is missing; the letter-opener is a plain dagger.");
			return items;
		}
		local ok = false;
		try { ok = ::GolarionEnchant.setMasterwork(items[0], true); }
		catch (e) { ::logError("Skv.Lore: setMasterwork threw on the letter-opener - " + e); }
		if (!ok) ::logError("Skv.Lore: the letter-opener refused masterwork; it is a plain dagger.");
		return items;
	}

	function gearOption( _screenID )
	{
		return {
			Text = "{Set our gear right. (open loadout)}",
			function getResult()
			{
				if (!::World.State.showLoadoutFromContract())
					::logError("Skv.Lore: the loadout did not open from " + _screenID + " (the contract screen hidden or still animating?)");
				return _screenID;
			}
		};
	}

	function word( _n )
	{
		local w = [ "no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" ];
		return (_n >= 0 && _n < w.len()) ? w[_n] : ("" + _n);
	}

	function readBand()
	{
		local C = ::Const.Skv.Lore;
		local moral = null;
		try { moral = ::World.Assets.getMoralReputation(); }
		catch (e)
		{
			::logError("Skv.Lore: getMoralReputation threw at accept; the band falls back to NEUTRAL (every button shown) - " + e);
			return 0;
		}
		local band = moral >= C.LawfulMin ? 1 : (moral < C.LawlessMax ? 2 : 0);
		::logInfo("Skv.Lore: the band at accept is " + (band == 1 ? "LAWFUL" : (band == 2 ? "LAWLESS" : "NEUTRAL"))
			+ " (moral " + moral + "; lawful >= " + C.LawfulMin + ", lawless < " + C.LawlessMax + ")");
		return band;
	}

	function tailsRolled() { return this.m.Tails & 0x0F; }
	function tailsSpotted() { return (this.m.Tails >> 4) & 0x0F; }

	function tailDue()
	{
		return this.m.Act == 0 && this.tailsRolled() < ::Math.min(::Const.Skv.Lore.TailMax, this.closedCount());
	}

	function bluePenalty()
	{
		local C = ::Const.Skv.Lore;
		return ::Math.min(C.TailBlueMax, C.TailBluePenalty * this.m.Blue);
	}

	function ratsRoused() { return this.m.Entry == 2 || this.m.Entry == 4 || this.m.Entry == 6; }

	function ratcatcher() { return this.m.Entry == 7; }

	function alleyCircle() { return this.tailsRolled() > 0 && this.tailsSpotted() == 0; }
	function alleyTrim() { return this.tailsSpotted() >= 2; }
	function alleySlow() { return this.tailsSpotted() >= 3; }
	function alleyNamed() { return (this.m.Alley >> 4) & 0x0F; }
	function alleyLost() { return (this.m.Alley & 0x0F) == 2; }
	function alleyWon() { return (this.m.Alley & 0x0F) == 1; }

	function revealed() { return this.m.Revealed != 0; }

	function impCalmed() { return (this.m.Imp & 2) != 0; }
	function caseInHand() { return (this.m.Imp & 2) != 0 || (this.m.Imp & 8) != 0 || (this.m.Goods & 4) != 0; }

	function powderHeld() { return (this.m.Goods & 1) != 0 && (this.m.Goods & 4) == 0; }

	function impApproachLeft() { return (this.m.Imp & 1) == 0 || (this.m.Imp & 4) == 0 || this.powderHeld(); }

	function mapOut() { return (this.m.Vault & 32) != 0; }
	function studyPassed() { return (this.m.Vault & 128) != 0; }

	function decoyKnown( _jar )
	{
		if ((this.m.Vault & 1) == 0) return false;
		if (this.studyPassed()) return true;
		return ((this.m.Vault & 256) != 0) == _jar;
	}

	function ratBudget() { return ::Skv.Lore.ratBudget(this.getDifficultyMult(), this.getScaledDifficultyMult(), this.ratcatcher()); }
	function alleyBudget() { return ::Skv.Lore.alleyBudget(this.getDifficultyMult(), this.getScaledDifficultyMult(), this.alleyTrim()); }

	function tier()
	{
		local C = ::Const.Skv.Lore;
		local d = this.doneCount();
		if (d <= 1) return C.TierFailed;
		if (d == 2 || this.alleyLost()) return C.TierPoor;
		return C.TierSuccess;
	}

	function outcomeOf( _t )
	{
		local C = ::Const.Skv.Lore;
		if (_t == C.TierSuccess) return C.OutcomeSuccess;
		if (_t == C.TierPoor) return C.OutcomePoor;
		return C.OutcomeFailed;
	}

	function recordOutcome( _v )
	{
		local C = ::Const.Skv.Lore;
		::World.Flags.set(C.ArcFlagOutcome, _v);
		::logInfo("Skv.Lore: outcome recorded, " + C.ArcFlagOutcome + "=" + _v
			+ " (" + C.OutcomeSuccess + " success, " + C.OutcomePoor + " poor, " + C.OutcomeFailed + " failed, " + C.OutcomeAbandoned + " cancelled or abandoned)");
	}

	function tierName( _t )
	{
		local C = ::Const.Skv.Lore;
		if (_t == C.TierSuccess) return "SUCCESS";
		if (_t == C.TierPoor) return "POOR";
		return "FAILED";
	}

	function tierRenown( _t )
	{
		local C = ::Const.Skv.Lore;
		local A = ::Const.World.Assets;
		if (_t == C.TierSuccess) return A.ReputationOnContractSuccess;
		if (_t == C.TierPoor) return A.ReputationOnContractPoor;
		return A.ReputationOnContractFail;
	}

	function tierRelation( _t )
	{
		local C = ::Const.Skv.Lore;
		local A = ::Const.World.Assets;
		if (_t == C.TierSuccess) return A.RelationNobleContractSuccess;
		if (_t == C.TierPoor) return 0;
		return A.RelationNobleContractFail;
	}

	function marker( _k )
	{
		if (_k == 0) return this.m.Shop;
		if (_k == 1) return this.m.Temple;
		if (_k == 2) return this.m.Sage;
		return this.m.Envoy;
	}

	function setMarker( _k, _ref )
	{
		if (_k == 0) this.m.Shop = _ref;
		else if (_k == 1) this.m.Temple = _ref;
		else if (_k == 2) this.m.Sage = _ref;
		else this.m.Envoy = _ref;
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
		local C = ::Const.Skv.Lore;
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
		local C = ::Const.Skv.Lore;
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

	function placeAt( _k, _tile, _steps, _route )
	{
		local site = ::Const.Skv.Lore.Sites[_k];
		local home = this.m.Home.getTile();
		_tile.clear();
		local ref = this.WeakTableRef(::World.spawnLocation(site.Script, _tile.Coords));
		ref.onSpawned();
		ref.setDiscovered(true);
		ref.setAttackable(false);
		ref.getSprite("selection").Visible = true;
		::World.uncoverFogOfWar(ref.getTile().Pos, 500.0);
		this.setMarker(_k, ref);
		local line = "Skv.Lore: " + site.Name + " at " + _tile.Coords.X + "," + _tile.Coords.Y + " terrain=" + _tile.Type
			+ (_tile.Type == ::Const.World.TerrainType.Shore ? " (SHORE: must not happen)" : "")
			+ (::Skv.Lore.touchesShore(_tile) ? " shore-side" : "")
			+ " " + _tile.getDistanceTo(home) + " tiles and " + _steps + " steps from " + this.m.Home.getName() + " route=" + _route;
		::logInfo(line);
		return line;
	}

	function spawnErrands()
	{
		local C = ::Const.Skv.Lore;
		local R = ::Skv.Rose;
		local L = ::Skv.Lore;
		try
		{
			local home = this.m.Home.getTile();
			local raw = L.ringTiles(this.m.Home);
			local vf = this.vanillaFilter(raw);
			local walk = [];
			local cut = 0;
			local far = 0;
			foreach (t in L.shuffled(vf.Tiles))
			{
				local n = R.landSteps(home, t);
				if (n < 0) { cut = cut + 1; continue; }
				if (n > C.SitePathMax) { far = far + 1; continue; }
				walk.push({ T = t, N = n });
			}
			local nearTiles = [];
			local allTiles = [];
			foreach (w in walk)
			{
				allTiles.push(w.T);
				if (w.N <= C.NearPathMax && w.T.getDistanceTo(home) <= C.NearRadius) nearTiles.push(w.T);
			}
			local pick = R.spacedPick(L.shoreFirst(nearTiles), C.SiteCount, C.SiteSpacing);
			local range = "NEAR, " + nearTiles.len() + " within " + C.NearRadius + " tiles and " + C.NearPathMax + " steps";
			if (pick.len() < C.SiteCount)
			{
				pick = R.spacedPick(L.shoreFirst(allTiles), C.SiteCount, C.SiteSpacing);
				range = "WIDE, only " + nearTiles.len() + " near";
			}
			local why = raw.len() + " ring tiles, " + vf.Town + " too near a settlement, " + vf.Site + " too near a location, "
				+ cut + " cut off, " + far + " over " + C.SitePathMax + " steps, " + walk.len() + " walkable; " + range;
			if (pick.len() >= C.SiteCount)
			{

				local swapped = false;
				if (!L.touchesShore(pick[0]))
				{
					for (local j = 1; j < C.SiteCount; j = j + 1)
					{
						if (L.touchesShore(pick[j]))
						{
							local t0 = pick[0];
							pick[0] = pick[j];
							pick[j] = t0;
							swapped = true;
							break;
						}
					}
				}
				for (local k = 0; k < C.SiteCount; k = k + 1)
				{
					local steps = 0;
					foreach (w in walk) if (w.T.ID == pick[k].ID) steps = w.N;
					try { this.placeAt(k, pick[k], steps, "spacedPick (" + why + ")" + (k == 0 ? (L.touchesShore(pick[0]) ? ", Karela by the shore" + (swapped ? " (swapped in from the pick)" : "") : ", Karela NOT by the shore (the pick holds no shore tile)") : "")); }
					catch (e) { ::logError("Skv.Lore: could not spawn " + C.Sites[k].Name + " - " + e); }
				}
			}
			else
			{
				::logError("Skv.Lore: the accept found only " + pick.len() + " of " + C.SiteCount + " walkable spaced markers (" + why
					+ "); each missing marker falls back to the greedy and relaxed path.");
			}
		}
		catch (e) { ::logError("Skv.Lore: the spacedPick placement threw; each marker falls back to the greedy path - " + e); }
		for (local k = 0; k < C.SiteCount; k = k + 1)
		{
			if (this.isClosed(C.Sites[k].Bit) || this.markerLive(k)) continue;
			try { this.spawnOne(k); }
			catch (e) { ::logError("Skv.Lore: could not spawn " + C.Sites[k].Name + " - " + e); }
		}
	}

	function spawnOne( _k )
	{
		if (this.markerLive(_k)) return null;
		local C = ::Const.Skv.Lore;
		local R = ::Skv.Rose;
		local home = this.m.Home.getTile();
		local raw = ::Skv.Lore.ringTiles(this.m.Home);
		local vf = this.vanillaFilter(raw);
		local pool = vf.Tiles;
		local dropped = raw.len() + " ring tiles, " + vf.Town + " too near a settlement, " + vf.Site + " too near a location";
		local live = this.liveTiles();
		local nearPool = [];
		foreach (t in pool)
		{
			if (t.getDistanceTo(home) <= C.NearRadius) nearPool.push(t);
		}
		local resN = this.pickSite(home, clone nearPool, live, C.SiteSpacing, C.NearPathMax);
		if (resN.Tile != null)
		{
			return this.placeAt(_k, resN.Tile, resN.Steps, "greedy NEAR (" + dropped + "; " + nearPool.len() + " within " + C.NearRadius
				+ " tiles; tried " + resN.Tried + ": " + resN.Cut + " cut off, " + resN.Far + " over " + C.NearPathMax + " steps, "
				+ resN.Close + " too close), spaced " + C.SiteSpacing + ", no shore preference");
		}
		local res = this.pickSite(home, clone pool, live, C.SiteSpacing);
		local tile = res.Tile;
		local steps = res.Steps;
		local route = "greedy WIDE (" + dropped + "; tried " + res.Tried + ": " + res.Cut + " cut off, " + res.Far + " over "
			+ C.SitePathMax + " steps, " + res.Close + " too close), spaced " + C.SiteSpacing + ", no shore preference";
		if (tile == null)
		{
			local res2 = this.pickSite(home, clone pool, live, 0);
			tile = res2.Tile;
			steps = res2.Steps;
			route = "RELAXED SPACING (none " + C.SiteSpacing + " apart was walkable: " + dropped + ", " + res.Close
				+ " too close; unspaced tried " + res2.Tried + ": " + res2.Cut + " cut off, " + res2.Far + " too far)";
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
			steps = R.landSteps(home, tile);
			route = "FALLBACK getTileToSpawnLocation(home, 3, 8) unfiltered, " + tries + " ask(s) (" + dropped + "; none walkable within "
				+ C.SitePathMax + ")" + (R.isSolidGround(tile) ? "" : "  << NOT SOLID GROUND after " + C.FallbackTries + " asks: taken anyway");
		}
		return this.placeAt(_k, tile, steps, route);
	}

	function missingSites()
	{
		local out = [];
		if (this.m.Act != 0) return out;
		for (local k = 0; k < 4; k = k + 1)
		{
			if (!this.isClosed(::Const.Skv.Lore.Sites[k].Bit) && !this.markerLive(k)) out.push(k);
		}
		return out;
	}

	function errandScreen( _k )
	{
		local C = ::Const.Skv.Lore;
		local m = this.m;
		if (m.Act != 0 || this.isClosed(C.Sites[_k].Bit)) return null;
		if (_k == C.KindKarela)
		{
			if (m.Karela == 0) return "Shop";
			if (m.Entry == 0) return "Pier";

			if (m.Rats == 0) return "Rats";
			if (m.Crate == 0) return "Crate";
			if ((m.Crate == 2 || m.Crate == 4 || m.Crate == 6) && m.Dive == 0) return "CrateFalls";
			return "Delivered";
		}
		if (_k == C.KindBaltwin)
		{
			if (m.Gossip == 0) return "Temple";
			if (m.Medicine == 0) return "Arrive";
			if (m.Report == 3) return "Report";
			return "House";
		}
		if (_k == C.KindSage)
		{
			if (this.mapOut()) return "MapOut";
			if (m.Vault != 0 || m.Moves < C.VaultMoves) return "Vault";
			return "Sage";
		}
		if ((m.Imp & 16) == 0) return "Envoy";
		if (!this.caseInHand()) return "Bedroom";
		return m.Case == 0 ? "Case" : "Thanks";
	}

	function after( _k )
	{
		local s = this.errandScreen(_k);
		return s == null ? "Errands" : s;
	}

	function errandHere()
	{
		for (local k = 0; k < 4; k = k + 1)
		{
			local mk = this.marker(k);
			if (!::MSU.isNull(mk) && this.isPlayerAt(mk)) return k;
		}
		return null;
	}

	function atHome()
	{
		if (this.m.Home == null || this.m.Home.isNull()) return false;
		if (this.isPlayerAt(this.m.Home)) return true;
		try
		{
			local t = ::World.State.getCurrentTown();
			if (t != null && t.getID() == this.m.Home.getID()) return true;
		}
		catch (e) { ::Skv.dbg("Skv.Lore: getCurrentTown threw - " + e); }
		return false;
	}

	function closeErrand( _k, _done )
	{
		local C = ::Const.Skv.Lore;
		local bit = C.Sites[_k].Bit;
		this.m.Closed = this.m.Closed | bit;
		if (_done) this.m.Done = this.m.Done | bit;
		this.killSite(_k);
		this.updateObjectives();
		::logInfo("Skv.Lore: " + C.Sites[_k].Who + "'s errand " + (_done ? "DONE" : "LOST") + " -> closed=" + this.m.Closed
			+ " done=" + this.m.Done + " (" + this.doneCount() + " done of " + this.closedCount() + " closed)");
	}

	function resolveShop( _take )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Karela != 0) return this.after(C.KindKarela);
		local rows = [];
		if (_take)
		{
			this.m.Karela = 2;
			::logInfo("Skv.Lore: Shop -> the job TAKEN (band " + this.m.Band + ")");
			this.m.Rows = rows;
			return "Pier";
		}
		this.m.Karela = 1;
		if (!this.hasGrant(C.GrantShopRefuse))
		{
			this.setGrant(C.GrantShopRefuse);
			this.moral(C.MoralRefuse, "You would not rob the city's warehouse", rows);
		}
		rows.push(this.badRow("Karela's errand was refused, and it paid nothing"));
		this.closeErrand(C.KindKarela, false);
		::logInfo("Skv.Lore: Shop -> the job REFUSED (band " + this.m.Band + ") granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "Errands";
	}

	function resolveEntry( _how )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Entry != 0) return this.after(C.KindKarela);
		local rows = [];
		if (_how == 4)
		{
			local rc = this.ratcatcherBro();
			if (rc == null)
			{
				::logError("Skv.Lore: the Ratcatcher's button was pressed with no Ratcatcher in the active company; nothing happens.");
				return "Pier";
			}
			this.m.Entry = 7;
			this.m.ActorName = rc.getName();
			if (!this.hasGrant(C.GrantRatcatcher))
			{
				this.setGrant(C.GrantRatcatcher);
				rows.extend(::Skv.XP.grant(rc, C.RatcatcherXP));
			}
			rows.push(this.goodRow(rc.getName() + " smoked the nest, and some of the rats fled through the floor"));
		}
		else
		{
			local r = _how == 1 ? ::Skv.Check.lockpick(this, this.sb(C.PierPickBase))
				: (_how == 2 ? ::Skv.Check.perception(this, this.sb(C.PierKeyBase)) : ::Skv.Check.brawn(this, this.sb(C.PierForceBase)));
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Entry = _how * 2 - 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + (_how == 1 ? " opened the lock without a sound"
					: (_how == 2 ? " found the key the smugglers had hidden" : " lifted the door off its hinges in one push"))));
				rows.push(this.goodRow("The rats were still in their nest"));
			}
			else
			{
				this.m.Entry = _how * 2;
				rows.push(this.badRow(_how == 1 ? "The lock held against " + this.actorName(r, true) + ", and the door had to be kicked in"
					: (_how == 2 ? who + " found no key, and the door had to be kicked in" : "The door took " + this.actorName(r, true) + " a dozen loud blows")));
				rows.push(this.badRow("The noise roused the rats"));
			}
			this.wandRows(r, rows);
		}
		::logInfo("Skv.Lore: Pier how=" + _how + " -> entry=" + this.m.Entry + " roused=" + this.ratsRoused() + " ratcatcher=" + this.ratcatcher());
		this.m.Rows = rows;
		return this.after(C.KindKarela);
	}

	function resolveCrate( _how )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Crate != 0) return this.after(C.KindKarela);
		local rows = [];
		local r = _how == 1 ? ::Skv.Check.wits(this, this.sb(C.CraneBase))
			: (_how == 2 ? ::Skv.Check.brawn(this, this.sb(C.BraceBase), C.BraceNeed) : ::Skv.Check.agility(this, this.sb(C.SkiffBase)));
		local who = this.actorName(r);
		if (r.ok)
		{
			this.m.Crate = _how * 2 - 1;
			rows.extend(::Skv.XP.check(r));
			rows.push(this.goodRow(_how == 1 ? who + " worked out the crane, and it lifted the crate clear"
				: (_how == 2 ? "The braced floor held, and the company hauled the crate back" : who + " brought the skiff under the hole, and the crate came down into it")));
			if (!this.hasGrant(C.GrantCrate))
			{
				this.setGrant(C.GrantCrate);
				this.m.Goods = this.m.Goods | 1;
				this.addStores(0, C.SpareAmmo, rows);
				this.addStores(1, C.SpareTools, rows);
				rows.push(this.goodRow("You kept a bag of grey powder from the crate"));
			}
		}
		else
		{
			this.m.Crate = _how * 2;
			if (_how == 2)
			{
				rows.push(this.badRow("The timbers slipped, and the floor went out from under the crate"));
				rows.extend(this.hurtThese(r.rows, C.HurtMin, C.HurtMax));
			}
			else rows.push(this.badRow(_how == 1 ? "The crane's chain ran away from " + this.actorName(r, true) + ", and the crate dropped"
				: "The skiff was not under the hole when the boards gave way"));
			rows.push(this.badRow("The crate fell into the water"));
		}
		::logInfo("Skv.Lore: Crate how=" + _how + " -> crate=" + this.m.Crate + " goods=" + this.m.Goods + " granted=" + this.m.Granted);
		this.m.Rows = rows;
		return this.after(C.KindKarela);
	}

	function resolveDive( _go )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Dive != 0) return this.after(C.KindKarela);
		local rows = [];
		if (!_go)
		{
			this.m.Dive = 3;
			rows.push(this.badRow("The box of books sank with the crate"));
		}
		else
		{
			local r = ::Skv.Check.agility(this, this.sb(C.DiveBase));
			if (r.ok)
			{
				this.m.Dive = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " brought the box up, wet but readable"));
				rows.push(this.badRow("The rest of the crate was lost to the water"));
			}
			else
			{
				this.m.Dive = 2;
				rows.push(this.badRow(this.actorName(r) + " came up bleeding and without the box"));
				rows.extend(this.hurtOne(r, C.HardHurtMin, C.HardHurtMax));
			}
		}
		::logInfo("Skv.Lore: CrateFalls go=" + _go + " -> dive=" + this.m.Dive);
		if (this.m.Dive != 1)
		{
			rows.push(this.badRow("Karela's errand was lost"));
			this.closeErrand(C.KindKarela, false);
			this.m.Rows = rows;
			return "CrateLost";
		}
		this.m.Rows = rows;
		return "Delivered";
	}

	function resolveDelivered( _strip )
	{
		local C = ::Const.Skv.Lore;
		if (this.isClosed(C.Sites[C.KindKarela].Bit)) return "Errands";
		local rows = [ this.goodRow("Karela had his box of books") ];
		if (!this.hasGrant(C.GrantKarelaPay))
		{

			this.setGrant(C.GrantKarelaPay);
			::World.Assets.addMoney(this.karelaPay());
		}
		if (_strip && !this.hasGrant(C.GrantStrip))
		{
			this.setGrant(C.GrantStrip);
			this.m.Goods = this.m.Goods | 2;
			local paths = [];
			for (local i = 0; i < C.StripCount; i = i + 1) paths.push(C.StripGoods[::Math.rand(0, C.StripGoods.len() - 1)]);
			local got = ::Skv.Loot.haul(::Skv.Loot.make(paths));
			if (got.len() == 0) ::logError("Skv.Lore: the warehouse's goods did not reach the stash.");
			rows.extend(got);
			this.moral(C.MoralStrip, "You stripped a warehouse the city had seized", rows);
		}
		this.closeErrand(C.KindKarela, true);
		::logInfo("Skv.Lore: Delivered strip=" + _strip + " share=" + this.karelaPay() + " goods=" + this.m.Goods + " granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "Errands";
	}

	function resolveGossip( _ask )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Gossip != 0) return this.after(C.KindBaltwin);
		local rows = [];
		if (!_ask) this.m.Gossip = 3;
		else
		{
			local r = ::Skv.Check.charm(this, this.sb(C.GossipBase));
			if (r.ok)
			{
				this.m.Gossip = 1;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " got the neighbours talking"));
				rows.push(this.goodRow("You knew what to look for in the house"));
			}
			else
			{
				this.m.Gossip = 2;
				this.m.Secrets = this.m.Secrets | 64;
				rows.push(this.badRow("The neighbours told " + this.actorName(r, true) + " nothing"));
				rows.push(this.badRow("Word of your questions reached the house before you did"));
			}
		}
		::logInfo("Skv.Lore: Temple ask=" + _ask + " -> gossip=" + this.m.Gossip + " secrets=" + this.m.Secrets);
		this.m.Rows = rows;
		return "Arrive";
	}

	function resolveMedicine( _keep )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Medicine != 0) return this.after(C.KindBaltwin);
		local rows = [];
		if (!_keep)
		{
			this.m.Medicine = 1;
			rows.push(this.goodRow("The medicine was delivered"));
		}
		else
		{
			this.m.Medicine = 2;
			if (!this.hasGrant(C.GrantKept))
			{
				this.setGrant(C.GrantKept);
				this.addStores(2, C.KeptMedicine, rows);
				this.moral(C.MoralKept, "You kept medicine meant for sick children", rows);
			}
			rows.push(this.badRow("With no delivery there was no report to make: Ollysta's errand could not succeed"));
		}
		::logInfo("Skv.Lore: Arrive keep=" + _keep + " -> medicine=" + this.m.Medicine + " granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "House";
	}

	function houseBase( _base )
	{
		local C = ::Const.Skv.Lore;
		return this.sb(_base) + (this.m.Gossip == 1 ? C.GossipBonus : 0) - ((this.m.Secrets & 64) != 0 ? C.WaryPenalty : 0);
	}

	function resolveHouse( _what )
	{
		local C = ::Const.Skv.Lore;
		local found = _what == 1 ? 1 : (_what == 2 ? 2 : 4);
		local tried = found << 3;
		if ((this.m.Secrets & tried) != 0 || this.m.Medicine == 0 || this.m.Medicine == 3) return this.after(C.KindBaltwin);
		this.m.Secrets = this.m.Secrets | tried;
		local rows = [];
		local anchor = this.houseBase(_what == 1 ? C.TeaBase : (_what == 2 ? C.SearchBase : C.ChildrenBase));
		local r = _what == 1 ? ::Skv.Check.perception(this, anchor) : (_what == 2 ? ::Skv.Check.stealth(this, anchor) : ::Skv.Check.charm(this, anchor));
		local who = this.actorName(r);
		if (r.ok)
		{
			this.m.Secrets = this.m.Secrets | found;
			rows.extend(::Skv.XP.check(r));
			if (_what == 1)
			{
				rows.push(this.goodRow(who + " saw what she poured into her own cup"));
				rows.push(this.goodRow("She laughed and admitted the drinking at once"));
			}
			else if (_what == 2)
			{
				rows.push(this.goodRow(who + " found medicine from three charities hidden upstairs, unopened"));
				rows.push(this.goodRow("Beside it lay purses stamped with three crows"));
			}
			else
			{
				rows.push(this.goodRow(who + " heard it from two of the children"));
				rows.push(this.goodRow("She hired them out as servants and kept their wages"));
			}
		}
		else if (_what == 2)
		{
			this.m.Secrets = this.m.Secrets | 64;
			rows.push(this.badRow("She caught " + this.actorName(r, true) + " on the stairs"));
			rows.push(this.badRow("She watched the company closely after that"));
		}
		else rows.push(this.badRow(_what == 1 ? who + " saw nothing wrong with her tea" : "The children told " + this.actorName(r, true) + " only about her stories"));
		::logInfo("Skv.Lore: House what=" + _what + " base " + anchor + " " + (r.ok ? "PASS" : "FAIL") + " -> secrets=" + this.m.Secrets + " (found " + this.secretsFound() + ")");
		this.m.Rows = rows;
		return "House";
	}

	function resolveForce()
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Medicine == 3 || this.isClosed(C.Sites[C.KindBaltwin].Bit)) return "Errands";
		this.m.Medicine = 3;
		this.m.Secrets = this.m.Secrets | 7;
		local rows = [];
		if (!this.hasGrant(C.GrantForced))
		{
			this.setGrant(C.GrantForced);
			this.addStores(2, C.ForcedMedicine, rows);
			this.townRel(C.ForcedRelation, "Turned a house of sick children over", rows);
			this.moral(C.MoralForced, "You tore apart a house full of children", rows);
		}
		rows.push(this.badRow("Ollysta's errand was lost"));
		this.closeErrand(C.KindBaltwin, false);
		::logInfo("Skv.Lore: House FORCED -> medicine=3 secrets=" + this.m.Secrets + " granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "Forced";
	}

	function resolveSilence()
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Report != 0 || !this.worseFound() || this.isClosed(C.Sites[C.KindBaltwin].Bit)) return this.after(C.KindBaltwin);
		local rows = [];
		this.m.Report = this.m.Medicine == 1 ? 3 : 4;
		if (!this.hasGrant(C.GrantSilence))
		{
			this.setGrant(C.GrantSilence);
			rows.push(::Legends.EventList.changeMoney(this.silencePay()));
			this.moral(C.MoralSilence, "You sold your silence to a woman who cheats children", rows);
		}
		::logInfo("Skv.Lore: House SILENCE sold -> report=" + this.m.Report + " granted=" + this.m.Granted);
		if (this.m.Report == 4)
		{
			rows.push(this.badRow("Ollysta's errand was lost"));
			this.closeErrand(C.KindBaltwin, false);
			this.m.Rows = rows;
			return "Errands";
		}
		this.m.Rows = rows;
		return "Report";
	}

	function resolveLeave()
	{
		local C = ::Const.Skv.Lore;
		if (this.isClosed(C.Sites[C.KindBaltwin].Bit)) return "Errands";
		if (this.m.Medicine == 1)
		{
			this.m.Rows = [];
			return "Report";
		}
		this.closeErrand(C.KindBaltwin, false);
		this.m.Rows = [ this.badRow("Ollysta's errand was lost") ];
		return "Errands";
	}

	function resolveReport( _how )
	{
		local C = ::Const.Skv.Lore;
		if (this.isClosed(C.Sites[C.KindBaltwin].Bit)) return "Errands";
		local sold = this.m.Report == 3;
		if (sold) _how = 2;
		local rows = [];
		if (!this.hasGrant(C.GrantReport))
		{
			this.setGrant(C.GrantReport);
			rows.push(::Legends.EventList.changeMoney(this.reportPay(_how)));
			if (_how == 1)
			{
				if (this.secretsFound() > 0)
				{
					this.moral(C.MoralTruth, "You told the truth about Auntie Baltwin", rows);
					rows.push(this.goodRow("The temple sent one of its own to keep the house's purse"));
				}
				else rows.push(this.goodRow("You found nothing against Auntie Baltwin, and said so"));
			}
			else
			{
				this.moral(C.MoralSoft, "You kept the worst of it from the temple", rows);
				rows.push(this.goodRow("Baltwin sent a basket of her own remedies after you"));
				this.addStores(2, C.RemedyMedicine, rows);
			}
		}
		if (!sold) this.m.Report = _how;
		this.closeErrand(C.KindBaltwin, true);
		::logInfo("Skv.Lore: Report how=" + _how + (sold ? " (after the silence)" : "") + " found=" + this.secretsFound() + " share=" + this.reportPay(_how)
			+ " -> report=" + this.m.Report + " granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "Errands";
	}

	function resolveVault( _what )
	{
		local C = ::Const.Skv.Lore;
		local bit = 1 << _what;
		local V = this.m.Vault;
		if (this.mapOut() || this.m.Moves <= 0 || (V & bit) != 0) return this.after(C.KindSage);
		if ((_what == 4 && (V & 2) == 0) || (_what == 5 && (V & 16) == 0))
		{

			local rows = [ this.badRow(_what == 4 ? "The rune chest would not open without its key" : "The steel chest would not open without its key") ];
			this.m.Moves = ::Math.max(0, this.m.Moves - 1);
			::logInfo("Skv.Lore: Vault what=" + _what + " tried WITHOUT its key, cost 1 -> moves=" + this.m.Moves + " vault=" + this.m.Vault);
			if (this.m.Moves <= 0)
			{
				rows.push(this.badRow("The sand ran out"));
				rows.push(this.badRow("Amenopheus' errand was lost"));
				this.closeErrand(C.KindSage, false);
				this.m.Rows = rows;
				return "LetOut";
			}
			this.m.Rows = rows;
			return "Vault";
		}
		this.m.Vault = V | bit;
		local cost = 1;
		local rows = [];
		if (_what == 0)
		{
			local lead = {};
			lead["background.historian"] <- C.StudyLead;
			local r = ::Skv.Check.wits(this, this.sb(C.StudyBase), lead);
			if (r.ok)
			{
				this.m.Vault = this.m.Vault | 128;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " studied the room: the jar and the plain chest were decoys"));
				rows.push(this.goodRow("The steel chest's lid was made to punish a careless hand"));
			}
			else
			{
				local jar = ::Math.rand(0, 1) == 1;
				if (jar) this.m.Vault = this.m.Vault | 256;
				rows.push(this.badRow(this.actorName(r) + " was sure of one thing only"));
				rows.push(this.goodRow(jar ? "The jar was a decoy" : "The plain chest was a decoy"));
			}
		}
		else if (_what == 1)
		{
			local r = ::Skv.Check.reflex(this, this.sb(C.BasketBase));
			if (r.ok)
			{
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " tipped the basket over with a blade, and a small viper struck at nothing"));
			}
			else
			{
				rows.push(this.badRow("A small viper under the reeds bit " + this.actorName(r, true)));
				rows.extend(this.hurtOne(r, C.BiteHurtMin, C.BiteHurtMax));
			}
			rows.push(this.goodRow("Under the reeds lay an iron key"));
		}
		else if (_what == 2)
		{
			local bro = this.anyBrother();
			rows.push(this.badRow("The liquid in the jar burned " + (bro == null ? "the hand that reached in" : bro.getName() + "'s hand")));
			rows.extend(this.hurtBro(bro, C.HardHurtMin, C.HardHurtMax));
			rows.push(this.badRow("The key from the jar fitted no lock in the room"));
		}
		else if (_what == 3)
		{
			rows.push(this.badRow("The plain chest was empty"));
		}
		else if (_what == 4)
		{
			local r = ::Skv.Check.agility(this, this.sb(C.RuneBase));
			rows.push(this.goodRow("The iron key opened the rune chest: a gilt sceptre lay in it, and a golden key flew up out of it"));
			if (r.ok)
			{
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " caught the golden key before it rose out of reach"));
			}
			else
			{
				cost = 2;
				this.m.Vault = this.m.Vault | 64;
				rows.push(this.badRow("The golden key rose out of " + this.actorName(r, true) + "'s reach, and fetching it down cost time"));
			}
		}
		else
		{
			local anchor = this.sb(C.SteelBase) + (this.studyPassed() ? C.StudySteelBonus : 0);
			local r = ::Skv.Check.perception(this, anchor);
			if (r.ok)
			{
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " saw the trap in the lid and opened the chest from the side"));
			}
			else
			{
				local blue = [];
				if (r.actor != null) blue.push(r.actor);
				local extra = ::Math.rand(0, C.BlueExtraMax);
				for (local i = 0; i < extra; i = i + 1)
				{
					local b = this.anyBrother(blue);
					if (b == null) break;
					blue.push(b);
				}
				this.m.Blue = blue.len();
				rows.push(this.badRow("A cloud of blue dye burst out of the lid"));
				foreach (b in blue) rows.push(this.badRow(b.getName() + "'s skin turned blue"));
			}
			rows.push(this.goodRow("The map was in the steel chest"));
		}
		this.m.Moves = ::Math.max(0, this.m.Moves - cost);
		::logInfo("Skv.Lore: Vault what=" + _what + " cost " + cost + " -> moves=" + this.m.Moves + " vault=" + this.m.Vault + " blue=" + this.m.Blue);
		if (this.mapOut())
		{
			this.m.Rows = rows;
			return "MapOut";
		}
		if (this.m.Moves <= 0)
		{
			rows.push(this.badRow("The sand ran out"));
			rows.push(this.badRow("Amenopheus' errand was lost"));
			this.closeErrand(C.KindSage, false);
			this.m.Rows = rows;
			return "LetOut";
		}
		this.m.Rows = rows;
		return "Vault";
	}

	function resolveImp( _how )
	{
		local C = ::Const.Skv.Lore;
		if (this.caseInHand() || this.isClosed(C.Sites[C.KindEnvoy].Bit)) return this.after(C.KindEnvoy);
		local rows = [];
		if (_how == 3)
		{
			if (!this.powderHeld()) return "Bedroom";
			this.m.Goods = this.m.Goods | 4;
			rows.push(this.goodRow("The grey powder clung to him, and he could no longer hide"));
			rows.push(this.goodRow("He dropped the case and fled up the chimney"));
		}
		else
		{
			local tried = _how == 1 ? 1 : 4;
			if ((this.m.Imp & tried) != 0) return "Bedroom";
			this.m.Imp = this.m.Imp | tried;
			local r = _how == 1 ? ::Skv.Check.charm(this, this.sb(C.ImpTalkBase)) : ::Skv.Check.handEye(this, this.sb(C.ImpBladeBase));
			if (r.ok)
			{
				this.m.Imp = this.m.Imp | (tried << 1);
				rows.extend(::Skv.XP.check(r));
				if (_how == 1)
				{
					rows.push(this.goodRow(this.actorName(r) + " calmed him with words"));
					if (this.m.Revealed == 0) this.m.Revealed = 1;
					rows.push(this.goodRow("You learned who meant to rob you"));
				}
				else rows.push(this.goodRow(this.actorName(r) + " drove him off with the silver blade"));
			}
			else
			{
				rows.push(this.badRow("He vanished, laughing, and stung " + this.actorName(r, true)));
				rows.extend(this.hurtOne(r, C.BiteHurtMin, C.BiteHurtMax));
			}
		}
		::logInfo("Skv.Lore: Bedroom how=" + _how + " -> imp=" + this.m.Imp + " goods=" + this.m.Goods + " revealed=" + this.m.Revealed
			+ " case in hand=" + this.caseInHand() + " approach left=" + this.impApproachLeft());
		if (this.caseInHand())
		{
			this.m.Rows = rows;
			return "Case";
		}
		if (!this.impApproachLeft())
		{
			rows.push(this.badRow("Zarta's errand was lost"));
			this.closeErrand(C.KindEnvoy, false);
			this.m.Rows = rows;
			return "ImpLoose";
		}
		this.m.Rows = rows;
		return "Bedroom";
	}

	function resolveCase( _try )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Case != 0) return this.after(C.KindEnvoy);
		local rows = [];
		if (!_try) this.m.Case = 1;
		else
		{
			local r = ::Skv.Check.lockpick(this, this.sb(C.CaseLockBase));
			if (r.ok)
			{
				this.m.Case = 2;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(this.actorName(r) + " eased the lid a finger's width: brass tools inside, each cut with a sigil"));
				rows.push(this.goodRow("The locks closed again without a mark"));
			}
			else
			{
				this.m.Case = 3;
				rows.push(this.badRow("One of the seven locks bit " + this.actorName(r, true)));
				rows.extend(this.hurtOne(r, C.HardHurtMin, C.HardHurtMax));
				rows.push(this.badRow("The scratches on the case could not be hidden"));
			}
			this.wandRows(r, rows);
		}
		::logInfo("Skv.Lore: Case try=" + _try + " -> case=" + this.m.Case);
		this.m.Rows = rows;
		return "Thanks";
	}

	function resolveThanks( _keep )
	{
		local C = ::Const.Skv.Lore;
		if (this.isClosed(C.Sites[C.KindEnvoy].Bit)) return "Errands";
		local rows = [];
		if (!this.hasGrant(C.GrantThanks))
		{
			this.setGrant(C.GrantThanks);
			if (_keep)
			{
				this.m.Opener = 1;
				local got = ::Skv.Loot.haul(this.makeOpener());
				if (got.len() == 0) ::logError("Skv.Lore: the letter-opener did not reach the stash.");
				rows.extend(got);
				rows.push(this.goodRow("You promised the Paracountess a visit"));
			}
			else
			{
				this.m.Opener = 2;
				rows.push(::Legends.EventList.changeMoney(this.pursePay()));
			}
		}
		rows.push(this.goodRow("You left with the case for Valsin"));
		this.closeErrand(C.KindEnvoy, true);
		::logInfo("Skv.Lore: Thanks keep=" + _keep + " -> opener=" + this.m.Opener + " granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "Errands";
	}

	function resolveLedford( _how )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Ledford != 0) return "AlleyLeave";
		this.m.Ledford = _how;
		local rows = [];
		if (!this.hasGrant(C.GrantAlleyAfter))
		{
			this.setGrant(C.GrantAlleyAfter);
			if (_how == 1) rows.push(::Legends.EventList.changeMoney(this.cutPay()));
			else if (_how == 2)
			{
				rows.push(::Legends.EventList.changeMoney(this.watchPay()));
				this.townRel(C.WatchRelation, "Handed a robber to the watch", rows);
				this.moral(C.MoralWatch, "You handed a beaten man to the watch", rows);
			}
			else
			{
				local got = ::Skv.Loot.haul(::Skv.Loot.make([ C.LedfordKit[::Math.rand(0, C.LedfordKit.len() - 1)] ]));
				if (got.len() == 0) ::logError("Skv.Lore: Ledford's kit did not reach the stash.");
				rows.extend(got);
				this.moral(C.MoralFinish, "You killed a man who had begged for his life", rows);
			}
		}
		::logInfo("Skv.Lore: Ledford how=" + _how + " (1 spared, 2 watch, 3 finished) granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "AlleyLeave";
	}

	function resolveZarta( _how )
	{
		local C = ::Const.Skv.Lore;
		if (this.m.Zarta != 0) return "EnvoyAfter";
		this.m.Zarta = _how;
		local rows = [];
		if (!this.hasGrant(C.GrantEnvoy2))
		{
			this.setGrant(C.GrantEnvoy2);
			if (_how == 1)
			{
				this.moral(C.MoralTell, "You told the Lodge who paid the gang", rows);
				rows.push(this.goodRow("The Lodge resolved to lend her nothing more"));
			}
			else if (_how == 2)
			{
				rows.push(::Legends.EventList.changeMoney(this.visitPay()));
				this.moral(C.MoralVisit, "You sold your silence to the envoy", rows);
			}
		}
		this.m.Act = 4;
		::logInfo("Skv.Lore: Envoy2 how=" + _how + " (1 told, 2 the visit, 3 nothing) granted=" + this.m.Granted);
		this.m.Rows = rows;
		return "EnvoyAfter";
	}

	function finish()
	{
		local C = ::Const.Skv.Lore;
		local t = this.tier();
		::logInfo("Skv.Lore: CLOSED. tier=" + this.tierName(t) + " done=" + this.m.Done + " closed=" + this.m.Closed + " alley=" + this.m.Alley
			+ " ledford=" + this.m.Ledford + " revealed=" + this.m.Revealed + " zarta=" + this.m.Zarta + " band=" + this.m.Band + " granted=" + this.m.Granted);
		this.m.Rows = [];

		this.recordOutcome(this.outcomeOf(t));
		::World.Contracts.finishActiveContract(t == C.TierFailed);
		return 0;
	}

	function payRows()
	{
		local C = ::Const.Skv.Lore;
		local rows = [];
		local t = this.tier();
		local d = this.doneCount();
		local line = "Errands done: " + d + " of 4";
		rows.push(t == C.TierSuccess ? this.goodRow(line) : this.badRow(line));
		if (this.alleyLost()) rows.push(this.badRow("You lost the fight in the alley"));
		if (this.isDone(C.Sites[C.KindSage].Bit))
			rows.push(this.mapDelivered() ? this.goodRow("The map reached Valsin") : this.badRow("The gang took the map"));
		if (this.isDone(C.Sites[C.KindEnvoy].Bit))
		{
			rows.push(this.caseDelivered() ? this.goodRow("The case reached Valsin") : this.badRow("The gang took the case"));
			if (this.caseDelivered() && this.m.Case == 3) rows.push(this.badRow("Valsin saw the scratches on the case"));
			if (this.finderPay() > 0) rows.push(this.goodRow("Valsin paid for what you saw inside the case"));
		}
		if (t == C.TierPoor) rows.push(this.badRow("Valsin paid half a wage"));
		else if (t == C.TierFailed) rows.push(this.badRow("Valsin paid no wage"));
		if (this.payTotal() > 0) rows.push(this.moneyRow(this.payTotal()));
		rows.push(this.renownRow(this.tierRenown(t)));
		local rel = this.tierRelation(t);
		if (rel != 0)
		{
			local f = this.factionOr(this.getFaction());
			rows.push(this.relRow(f != null ? f.getName() : this.townName(), rel > 0));
		}
		return rows;
	}

	function resolveTail( _double )
	{
		local C = ::Const.Skv.Lore;

		local anchor = this.sb(_double ? C.TailDoubleBase : C.TailWatchBase) - this.bluePenalty();
		local r = _double ? ::Skv.Check.stealth(this, anchor, C.TailPartyNeed) : ::Skv.Check.perception(this, anchor);
		local rolled = this.tailsRolled() + 1;
		local spotted = this.tailsSpotted() + (r.ok ? 1 : 0);
		this.m.Tails = (rolled & 0x0F) | ((spotted & 0x0F) << 4);
		local name = this.actorName(r);
		if (r.ok && this.m.Spotter == "") this.m.Spotter = name;
		local rows = [];
		if (r.ok)
		{
			rows.extend(::Skv.XP.check(r));
			rows.push(this.goodRow(name + " marked a forgettable face that kept turning up"));
		}
		else rows.push(this.badRow("If anyone followed you, you did not see him"));
		if (this.m.Blue > 0) rows.push(this.badRow("Blue skin made the company easy to follow"));
		this.m.Rows = rows;
		::logInfo("Skv.Lore: TAIL " + (_double ? "double back (stealth, party)" : "keep watch (perception, best-of)") + " base " + anchor
			+ " (blue -" + this.bluePenalty() + ") " + (r.ok ? "PASS" : "FAIL") + " by " + name
			+ " -> tails rolled " + rolled + ", spotted " + spotted + ", spotter " + (this.m.Spotter == "" ? "none" : this.m.Spotter));
		local k = this.errandHere();
		if (k == null)
		{
			::logError("Skv.Lore: the tail resolved with the party at no errand marker; the screen closes (the latch re-opens the errand).");
			return 0;
		}
		local s = this.errandScreen(k);
		return s == null ? 0 : s;
	}

	function headBackNow()
	{
		local C = ::Const.Skv.Lore;
		local open = 0;
		for (local k = 0; k < 4; k = k + 1)
		{
			if (this.markerLive(k)) open = open + 1;
		}
		this.killAll();
		this.m.Act = 1;
		this.m.Rows = [];
		this.updateObjectives();
		::logInfo("Skv.Lore: HEADING BACK with " + open + " errand(s) undone -> act 1; closed=" + this.m.Closed + " done=" + this.m.Done);
		return "Street";
	}

	function wayBackScreen()
	{
		if (this.m.Act <= 1) return "Street";
		if (this.m.Act == 2) return (this.alleyWon() && this.m.Ledford == 0) ? "AlleyAfter" : "Pay";
		if (this.m.Act == 3 && this.revealed() && this.m.Zarta == 0) return "Envoy2";
		return "EnvoyAfter";
	}

	function updateObjectives()
	{
		local C = ::Const.Skv.Lore;
		local b = [];
		if (this.m.Act == 0)
		{
			for (local k = 0; k < 4; k = k + 1)
			{
				if (!this.isClosed(C.Sites[k].Bit) && this.markerLive(k)) b.push("Visit " + C.Sites[k].Name);
			}
			b.push("Return to Valsin in " + this.townName() + " when you are done");
		}
		else
		{
			b.push("Return to Valsin in " + this.townName());
		}
		this.m.BulletpointsObjectives = b;

		::World.Contracts.updateActiveContract();
	}

	function onNamedPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Lore: a named alley unit placed as null; it fights at its own speed.");
			return;
		}
		try
		{
			local b = _e.getBaseProperties();
			local i0 = b.Initiative;
			b.Initiative = i0 - ::Const.Skv.Lore.AlleySlowInit;
			_e.getSkills().update();
			::logInfo("Skv.Lore: " + _e.getName() + " placed, initiative " + i0 + " -> " + b.Initiative + " (three tails spotted)");
		}
		catch (e) { ::logError("Skv.Lore: could not slow a named alley unit (it fights at its own speed): " + e); }
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
		::logInfo("Skv.Lore: " + ::Const.Skv.Lore.Sites[_k].Name + " has no marker at its fight (a jump?); the fight runs on the party's tile.");
		return ::World.State.getPlayer().getTile();
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_lore";
		this.m.Name = "In Service to Lore";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A man from the Pathfinder lodge has four errands to run in the city, and nobody of his own to send.",
			"The Pathfinder lodge wants outside hands for a day of errands among its friends in the city."
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
		_vars.push(["SKVLOC", "[color=#b39dbc]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);
	}

	function start()
	{
		local C = ::Const.Skv.Lore;
		this.m.DifficultyMult = this.Math.rand(C.DiffLo, C.DiffHi) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, C.PayBase);

		this.m.Payment.Advance = 0.0;
		this.m.Payment.Completion = 1.0;
		::logInfo("Skv.Lore: created at " + this.m.Home.getName() + " diff=" + this.m.DifficultyMult
			+ " pool=" + this.m.Payment.Pool + " fee=" + this.fee() + " (design guess at DM 0.9: ~267)");
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Run four errands for friends of the lodge in " + this.Contract.townName(),
					"Return to Valsin when they are done"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;

				local adv = c.m.Payment.getInAdvance();
				if (adv > 0)
				{
					::logError("Skv.Lore: an advance of " + adv + " was negotiated although #21 offers none; paid, so the player loses nothing.");
					::World.Assets.addMoney(adv);
				}
				c.m.DayAccepted = ::World.getTime().Days;
				c.m.Band = c.readBand();
				c.m.Moves = C.VaultMoves;

				c.spawnErrands();
				c.updateObjectives();
				::logInfo("Skv.Lore: ACCEPTED day=" + c.m.DayAccepted + " diff=" + c.getDifficultyMult() + " fee=" + c.fee()
					+ " band=" + c.m.Band + " markers=" + c.liveTiles().len() + "/4");

				::World.Contracts.setActiveContract(c);
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
				local C = ::Const.Skv.Lore;

				if (::Skv.Screens.hold(c)) return;

				local f = this.Flags.get("F21");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V21") == f;
					local ran = this.Flags.get("R21") == f;
					this.Flags.set("F21", "");
					this.Flags.set("V21", "");
					this.Flags.set("R21", "");

					if (!won && !ran)
					{
						::logInfo("Skv.Lore: " + f + " was launched but never resolved - no state change.");

						if (f == "Skv21Rats")
						{
							this.TempFlags.set(C.Sites[C.KindKarela].Latch, false);
							::logInfo("Skv.Lore: the latch " + C.Sites[C.KindKarela].Latch + " was cleared; the errand's screen re-opens at the marker.");
						}
					}
					else if (f == "Skv21Rats")
					{
						if (won)
						{
							c.m.Rats = 1;
							c.m.Rows = [ c.goodRow("The rats were dead") ];
							::logInfo("Skv.Lore: the rats WON -> rats=1, Karela's errand goes on");

							c.setScreen(c.after(C.KindKarela));
						}
						else
						{

							c.m.Rats = 2;
							c.closeErrand(C.KindKarela, false);
							c.m.Rows = [ c.badRow("Karela's errand was lost") ];
							::logInfo("Skv.Lore: the rats FLED -> rats=2, Karela's errand lost");
							c.setScreen("RatsFled");
						}
						::World.Contracts.showActiveContract();
						return;
					}
					else if (f == "Skv21Alley")
					{
						c.m.Alley = (c.m.Alley & 0xF0) | (won ? 1 : 2);
						c.m.Act = 2;
						c.m.Rows = [];

						if (won && c.m.Revealed == 0 && (c.m.Imp & 16) != 0) c.m.Revealed = 2;

						if (!won && c.isDone(C.Sites[C.KindEnvoy].Bit)) c.m.Case = 4;
						c.updateObjectives();
						::logInfo("Skv.Lore: the alley " + (won ? "WON" : "FLED") + " -> act 2, alley=" + c.m.Alley + " (named " + c.alleyNamed()
							+ " of " + c.m.Gang + "), revealed=" + c.m.Revealed + " case=" + c.m.Case + ", tier now " + c.tierName(c.tier()));
						c.setScreen(won ? "AlleyAfter" : "AlleyLost");
						::World.Contracts.showActiveContract();
						return;
					}
				}

				if (c.m.Act >= 1)
				{
					if (c.getActiveScreen() != null || !c.atHome()) return;
					local s = c.wayBackScreen();
					::logInfo("Skv.Lore: act " + c.m.Act + " at the host with no screen open -> " + s);
					c.setScreen(s);
					::World.Contracts.showActiveContract();
					return;
				}

				local missing = c.missingSites();
				if (missing.len() > 0)
				{
					local tries = this.TempFlags.get("LoreRepairs");
					if (typeof tries != "integer") tries = 0;
					if (tries < C.RepairTries)
					{
						this.TempFlags.set("LoreRepairs", tries + 1);
						foreach (k in missing)
						{
							local line = null;
							try { line = c.spawnOne(k); }
							catch (e) { ::logError("Skv.Lore: REPAIR of " + C.Sites[k].Name + " threw (attempt " + (tries + 1) + " of " + C.RepairTries + ") - " + e); }
							if (c.markerLive(k)) ::logInfo("Skv.Lore: REPAIRED a missing marker (attempt " + (tries + 1) + "): " + line);
							else ::logError("Skv.Lore: REPAIR of " + C.Sites[k].Name + " left no marker (attempt " + (tries + 1) + " of " + C.RepairTries + ").");
						}
						c.updateObjectives();
					}
					else if (!this.TempFlags.get("LoreRepairGaveUp"))
					{
						this.TempFlags.set("LoreRepairGaveUp", true);
						::logError("Skv.Lore: " + missing.len() + " marker(s) still missing after " + C.RepairTries
							+ " repair attempts; giving up until the next load (::skvlorejump can place them by hand).");
					}
				}

				if (c.atHome())
				{
					if (!this.TempFlags.get("LoreAtHome") && c.getActiveScreen() == null && c.closedCount() > 0)
					{
						this.TempFlags.set("LoreAtHome", true);
						c.m.Rows = [];
						if (c.closedCount() >= 4)
						{
							c.m.Act = 1;
							c.killAll();
							c.updateObjectives();
							::logInfo("Skv.Lore: all four errands closed, at the host -> act 1, Street");
							c.setScreen("Street");
						}
						else
						{
							::logInfo("Skv.Lore: at the host with " + c.closedCount() + " of 4 closed -> HeadBack");
							c.setScreen("HeadBack");
						}
						::World.Contracts.showActiveContract();
						return;
					}
				}
				else
				{
					this.TempFlags.set("LoreAtHome", false);
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
							local s = c.errandScreen(k);
							if (s != null && c.getActiveScreen() == null)
							{
								c.m.Rows = [];
								if (c.tailDue()) s = "Tail";
								::logInfo("Skv.Lore: at " + C.Sites[k].Name + " -> " + s);
								c.setScreen(s);
								::World.Contracts.showActiveContract();
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

			function onCombatRats()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local p = c.indoorCombat("Skv21Rats", c.siteTile(C.KindKarela), c.ratsRoused());
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) { ::logError("Skv.Lore: no BeastsTracks - " + e); }
				local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Beasts).getID();
				local budget = c.ratBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionRats, budget, fac, "Lore/Rats", ::Const.World.Spawn.GolarionRats);
				::Skv.Spawn.check(p.Entities, "Lore/Rats");
				::logInfo("Skv.Lore: the rats. budget=" + budget + " (" + C.RatBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + (c.ratcatcher() ? " x Ratcatcher " + C.RatcatcherMult : "") + ") units=" + p.Entities.len()
					+ " deploy=" + (c.ratsRoused() ? "Circle" : "Line") + " entry=" + c.m.Entry);
				this.Flags.set("F21", "Skv21Rats");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatAlley()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.CombatID = "Skv21Alley";
				p.Tile = ::World.State.getPlayer().getTile();
				p.TerrainTemplate = "tactical.plains";
				p.LocationTemplate = clone ::Const.Tactical.LocationTemplate;

				p.LocationTemplate.Template = clone ::Const.Tactical.LocationTemplate.Template;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = ::Const.Tactical.FortificationType.None;
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = c.alleyCircle() ? ::Const.Tactical.DeploymentType.Circle : ::Const.Tactical.DeploymentType.Line;
				try { p.Music = ::Const.Music.BanditTracks; } catch (e) { ::logError("Skv.Lore: no BanditTracks - " + e); }
				p.Entities = [];
				local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Bandits).getID();
				local budget = c.alleyBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionAlleyGang, budget, fac, "Lore/Alley", ::Const.World.Spawn.GolarionAlleyGang);
				local n = ::Skv.Lore.nameGang(p.Entities, 0, c.alleySlow() ? c.onNamedPlaced.bindenv(c) : null);

				c.m.Alley = (c.m.Alley & 0x0F) | ((n & 0x0F) << 4);

				c.m.Gang = ::Math.min(65535, p.Entities.len());
				::Skv.Spawn.check(p.Entities, "Lore/Alley");
				local roster = [];
				foreach (u in p.Entities) roster.push(::Skv.Lore.scriptName(u) + " " + (("Cost" in u) ? u.Cost : 0) + (("Name" in u) && u.Name != "" ? " \"" + u.Name + "\"" : ""));
				::logInfo("Skv.Lore: the alley. budget=" + budget + " (" + C.AlleyBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + (c.alleyTrim() ? " x trim " + C.AlleyTrimMult : "") + ") units=" + p.Entities.len()
					+ " named=" + n + " deploy=" + (c.alleyCircle() ? "Circle" : "Line") + (c.alleySlow() ? ", named slowed by " + C.AlleySlowInit : "")
					+ " tails rolled=" + c.tailsRolled() + " spotted=" + c.tailsSpotted() + " :: " + c.joinList(roster, ", "));
				this.Flags.set("F21", "Skv21Alley");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv21") return;
				this.Flags.set("V21", _combatID);
				::Skv.dbg("Skv.Lore: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F21");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R21", f);
				::Skv.dbg("Skv.Lore: retreated from " + f + " (id=" + _combatID + ")");
			}
		});
	}

	function aliasScreen( _id, _k )
	{
		return {
			ID = _id,
			Kind = _k,
			Title = "",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local k = this.Kind;
				this.Title = C.Sites[k].Name;
				this.Text = c.img(C.ImgErrand) + "{You stand at the door of " + C.Sites[k].Name + ", with Valsin's letter in your hand.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Knock.}",
						function getResult()
						{
							local c = this.Contract;
							local s = c.errandScreen(k);
							::logInfo("Skv.Lore: a stage-1 stub screen was open for errand " + k + "; it goes on to " + (s == null ? "nothing (the errand is closed)" : s));
							c.m.Rows = [];
							return s == null ? 0 : s;
						}
					}
				];
			}
		};
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
					::logError("Skv.Lore: the negotiation's advance button was not found (Legends changed its text?); the player can haggle an advance #21 will not pay.");
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
						return "Errands";
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
			Title = "In Service to Lore",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgLodge) + "{%SKVNAME%Valsin%SKVNAME_OFF% of the Pathfinder lodge has four sealed letters on his table and nobody free to carry them.%SPEECH_ON%Four friends of this lodge each need a favour done, and I have promised all four. One letter is for %SKVNAME%Karela%SKVNAME_OFF%, who keeps a shop called the %SKVLOC%Pickled Imp%SKVLOC_OFF%. One is for %SKVNAME%Ollysta Zadrian%SKVNAME_OFF%, who serves the %SKVNAME%Dawnflower%SKVNAME_OFF% at the %SKVLOC%Shining Star%SKVLOC_OFF%. One is for %SKVNAME%Amenopheus%SKVNAME_OFF%, whom people call the %SKVNAME%Sapphire Sage%SKVNAME_OFF%. The last is for the Paracountess %SKVNAME%Zarta Dralneen%SKVNAME_OFF%, the envoy of %SKVLOC%Cheliax%SKVLOC_OFF%.\n\nEach of them will tell you what is needed when you arrive. Visit them in any order you like, do as they ask, and come back to me when you are finished. I need outside hands for this. There is no advance. I pay when you return.%SPEECH_OFF%}";
				this.Options = [
					{
						Text = "{We'll run your errands.}",
						function getResult() { return "Negotiation"; }
					}
				];
				if (::World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{What do the men know of these four?}",
						function getResult() { return "Lore"; }
					});
				}
				this.Options.push({
					Text = "{Find someone else.}",
					function getResult()
					{
						::World.Contracts.removeContract(this.Contract);
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
				this.Text = this.Contract.img(::Const.Skv.Lore.ImgLodge) + "{%SKVNAME%%randombrother%%SKVNAME_OFF% has heard one of the names before.%SPEECH_ON%%SKVNAME%Karela%SKVNAME_OFF%. If it is the same man, half the thieves and smugglers on the waterfront answer to him. He pays what he promises. He also never asks an honest man for a favour.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% knows the temple, though not the woman.%SPEECH_ON%The %SKVLOC%Shining Star%SKVLOC_OFF% belongs to the %SKVNAME%Dawnflower%SKVNAME_OFF%. Her people feed beggars and nurse the sick, and they expect everyone else to do the same.%SPEECH_OFF%Of the other two the company has only tavern talk. A sage out of %SKVLOC%Osirion%SKVLOC_OFF% will be old and patient, and slow to trust a stranger. As for %SKVLOC%Cheliax%SKVLOC_OFF%, people say that its nobles sign contracts with devils and call it good government.}";
			}
		});

		this.m.Screens.push({
			ID = "Errands",
			Title = "Four Errands",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local open = 0;
				for (local k = 0; k < 4; k = k + 1) if (c.markerLive(k)) open = open + 1;
				local text = "";
				if (c.closedCount() == 0)
					text = "{Valsin marks four houses on your map and gives you a sealed letter for each. What waits behind each door, he does not say. The order is yours to choose, and so is the moment you come back: an errand left open when you return to him stays undone.}";
				else if (open > 0)
					text = "{" + (open == 1 ? "One errand is" : (open == 2 ? "Two errands are" : (open == 3 ? "Three errands are" : "Four errands are"))) + " still open. You can go back to Valsin in %SKVTOWN% at any time, but the errands left open will then go undone.}";
				else
					text = "{Every errand has ended, done or not. Valsin is waiting at the lodge in %SKVTOWN%.}";
				this.Text = c.img(C.ImgLodge) + text;
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				for (local k = 0; k < 4; k = k + 1)
				{
					if (c.markerLive(k)) rows.push(c.goodRow("Marked on your map: " + C.Sites[k].Name));
				}
				this.List = rows;
				this.Options = [
					{
						Text = "{To the streets.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Tail",
			Title = "Familiar Faces",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgTail) + "{On the way here you saw a face in the crowd that you are sure you saw earlier, near another door. You could keep watch behind you as you walk, or double back through the crowd and see who turns with you.}";
				local rows = [];

				if (c.m.Blue > 0) rows.push(c.badRow("The company's blue skin was easy to follow"));
				this.List = rows;
				this.Options = [
					{
						Text = "{Keep watch behind you.}",
						function getResult() { return this.Contract.resolveTail(false); }
					},
					{
						Text = "{Double back through the crowd.}",
						function getResult() { return this.Contract.resolveTail(true); }
					}
				];
			}
		});

		this.m.Screens.push(this.aliasScreen("StubKarela", ::Const.Skv.Lore.KindKarela));
		this.m.Screens.push(this.aliasScreen("StubBaltwin", ::Const.Skv.Lore.KindBaltwin));
		this.m.Screens.push(this.aliasScreen("StubSage", ::Const.Skv.Lore.KindSage));
		this.m.Screens.push(this.aliasScreen("StubEnvoy", ::Const.Skv.Lore.KindEnvoy));

		this.m.Screens.push({
			ID = "Shop",
			Title = "The Pickled Imp",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local close = c.m.Band == 1
					? "Your company is known for keeping the law, and this is not work such a company can take."
					: (c.m.Band == 2
						? "It is the kind of work your company is known for."
						: "You could take the job. Or you could tell him that you do not rob warehouses the city has seized, and leave his errand undone.");
				this.Text = c.img(::Const.Skv.Lore.ImgShop) + "{The Pickled Imp sells jars. Things float in them that were never born right, and the largest jar holds something small with horns and a tail. Over the door hangs a sign of three crows. The owner, %SKVNAME%Karela%SKVNAME_OFF%, is thin and greasy, and he smiles as if each smile cost him money.%SPEECH_ON%A friend of mine left the city in a hurry, and the city took his warehouse at the end of the old pier. A crate of mine is still inside, marked with my crows. In it is a small box of books and papers. Bring me the box. The rest of the crate is yours, and so is anything else in that warehouse you care to carry. The city will only sell it.%SPEECH_OFF%When you ask whether the city would call that theft, he reminds you whose letter you carried in.\n\n" + close + "}";

				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Take the job.}",
						function getResult() { return this.Contract.resolveShop(true); }
					});
				}
				if (c.kindOK())
				{
					this.Options.push({
						Text = "{Refuse the job.}",
						function getResult() { return this.Contract.resolveShop(false); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Pier",
			Title = "The Old Pier",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local rc = c.ratcatcherBro();
				this.Text = c.img(::Const.Skv.Lore.ImgPier) + "{The warehouse stands at the far end of a pier, on piles over the water, and half of its neighbours have been left to rot. Somebody has drawn a small devil on the door in chalk, and the chalk is fresh. From inside comes a dry scratching that stops when you stand still.\n\nThe door has a good lock. One of the men could try to pick it, or search for the key that smugglers like to hide near such doors, or the company could break the door in. A quiet way in will not wake whatever is nesting inside."
					+ (rc != null ? "\n\n" + rc.getName() + " listens at the boards and says it is rats, large ones, and that a nest can be smoked out before anyone walks into it." : "") + "}";
				this.List = [];
				this.Options = [
					{
						Text = "{Pick the lock.}",
						function getResult() { return this.Contract.resolveEntry(1); }
					},
					{
						Text = "{Search for the hidden key.}",
						function getResult() { return this.Contract.resolveEntry(2); }
					},
					{
						Text = "{Break the door in.}",
						function getResult() { return this.Contract.resolveEntry(3); }
					}
				];
				if (rc != null)
				{
					this.Options.push({
						Text = "{Let " + rc.getName() + " smoke out the nest.}",
						function getResult() { return this.Contract.resolveEntry(4); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Rats",
			Title = "The Nest",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local hall = "Inside is one long hall of coffins, coiled rope, stacked timber and fishing nets. At the far end the floor has rotted through, and a crate hangs over the hole with dark water beneath it. ";
				local nest = c.ratcatcher()
					? "The smoke has done its work: a part of the nest has gone out through the hole and into the water. What is left has crowded into one corner, rats the size of dogs, and they will not leave."
					: (c.ratsRoused()
						? "The rats are already awake. They are the size of dogs, and they come along the walls and over the timber from every side."
						: "Between you and the crate, in a heap of chewed sailcloth, lie rats the size of dogs. They have not noticed you yet.");
				this.Text = c.img(::Const.Skv.Lore.ImgRats) + "{" + hall + nest + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Clear them out.}",
						function getResult()
						{
							local c = this.Contract;

							if (c.m.Rats != 0) return c.after(::Const.Skv.Lore.KindKarela);
							c.getActiveState().onCombatRats();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "RatsFled",
			Title = "Driven Out",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgRats) + "{The rats keep the warehouse. When you tell Karela, he shrugs and turns back to his jars: he pays for a box of books, not for the story of how you did not fetch it.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the streets.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Errands";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Crate",
			Title = "The Crate",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgCrate) + "{The crate with the three crows sits on the edge of the hole in the floor, on boards that bend when anyone comes near, and it is far too heavy to lift away by hand. Above it an old loading crane hangs from a rail. Below it, tied to a pile, is the skiff the smugglers used.\n\nSomeone clever could work out how the crane runs and lift the crate clear. The whole company could brace the floor with timber from the stacks and haul the crate back. Or one sure-footed man could bring the skiff under the hole, so that the crate comes down into the boat and not into the water.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Work the old crane.}",
						function getResult() { return this.Contract.resolveCrate(1); }
					},
					{
						Text = "{Brace the floor and haul.}",
						function getResult() { return this.Contract.resolveCrate(2); }
					},
					{
						Text = "{Bring the skiff under the hole.}",
						function getResult() { return this.Contract.resolveCrate(3); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CrateFalls",
			Title = "Through the Floor",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgPier) + "{The crate goes through the floor, hits the water and starts to sink, with the box of books inside it. Paper does not last long under water.\n\nOne man could go in after it at once, down among the piles and the broken timber, and may be hurt for nothing. Or you could let it go: then nobody bleeds, and Karela gets no box.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Send a man in after it.}",
						function getResult() { return this.Contract.resolveDive(true); }
					},
					{
						Text = "{Let it go.}",
						function getResult() { return this.Contract.resolveDive(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CrateLost",
			Title = "Lost to the Water",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgPier) + "{The crate lies in the mud under the pier, and the books in it are pulp by now. Karela hears it without a word and goes back to dusting his jars. He pays nothing for a box he does not have.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the streets.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Errands";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Delivered",
			Title = "Karela's Thanks",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local wet = c.m.Dive == 1;
				this.Text = c.img(C.ImgShop) + "{" + (wet
					? "Karela peels the wet pages apart with the point of a knife, reads a line here and there, and decides that enough of it has survived."
					: "Karela opens the box on his counter, runs a finger down a page of some trading house's cargo lists, and closes it again.")
					+ "%SPEECH_ON%A dozen merchant houses would sleep badly tonight if they knew who is reading their books. " + (wet ? "A pity about the rest of the crate." : "The rest of the crate is yours, as I said. Be careful with the grey powder: it clings to anything, even to things you cannot see.") + "%SPEECH_OFF%"
					+ (c.ruthlessOK()
						? "The warehouse still stands open behind you, full of stock the city has not counted yet. You could go back and strip it, as he suggested, or leave the rest to the city."
						: "The warehouse still stands open behind you. What is left in it belongs to the city.") + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantKarelaPay)) rows.push(c.moneyRow(c.karelaPay()));
				this.List = rows;
				this.Options = [];
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Strip the warehouse.}",
						function getResult() { return this.Contract.resolveDelivered(true); }
					});
				}
				this.Options.push({
					Text = "{Leave the rest to the city.}",
					function getResult() { return this.Contract.resolveDelivered(false); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Temple",
			Title = "The Shining Star",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgTemple) + "{The Shining Star is the Dawnflower's temple in this city. Its gates stand open to the sun, and %SKVNAME%Ollysta Zadrian%SKVNAME_OFF% receives you in its court. She is young, she wears her mail as if she slept in it, and she speaks plainly.%SPEECH_ON%This chest holds medicine for a house in the poor quarter, where a woman the children call Auntie Baltwin nurses the sick and the orphaned. The temple pays for much of what she does. Take the medicine to her. Then look at that house with open eyes, and tell me truthfully what you saw. I have heard things about it that I do not want to believe without cause.%SPEECH_OFF%You could ask around the quarter before you knock, and learn what to look for. But people talk, and your questions may reach the house before you do. Or you could go straight to her door and trust your own eyes.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Ask around the quarter first.}",
						function getResult() { return this.Contract.resolveGossip(true); }
					},
					{
						Text = "{Go straight to the house.}",
						function getResult() { return this.Contract.resolveGossip(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Arrive",
			Title = "Auntie Baltwin's House",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local close = c.m.Band == 1
					? "The medicine is hers by Ollysta's word, and your company keeps its word."
					: (c.m.Band == 2
						? "A company like yours does not carry good medicine across a city to give it away. Kept, it means there is no delivery to report, and the temple's errand cannot succeed. You can still go in and see what the house is worth."
						: "The medicine is hers by Ollysta's word. It would also serve a mercenary company well. If you keep it, there is no delivery to report and the temple's errand cannot succeed, though you can still go in and see what the house is worth.");
				this.Text = c.img(::Const.Skv.Lore.ImgHouse) + "{The house is clean and loud. There are cats on every sill and children on every stair, and somewhere upstairs a cough that does not stop. %SKVNAME%Auntie Baltwin%SKVNAME_OFF% is old and broad and walks with a cane, and she looks at the chest in your hands before she looks at you.\n\n" + close + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if (c.kindOK())
				{
					this.Options.push({
						Text = "{Hand over the medicine.}",
						function getResult() { return this.Contract.resolveMedicine(false); }
					});
				}
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Keep the medicine.}",
						function getResult() { return this.Contract.resolveMedicine(true); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "House",
			Title = "Auntie Baltwin's House",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local S = c.m.Secrets;
				local handed = c.m.Medicine == 1;
				local ways = [];
				if ((S & 8) == 0) ways.push("She offers tea, and one of you could sit with her and watch her hands.");
				if ((S & 16) == 0) ways.push("She says she must see to the soup, and someone could slip upstairs while she cooks.");
				if ((S & 32) == 0) ways.push("One of the men could talk with the children where she cannot hear.");
				local text = "Baltwin puts a kettle on and talks without a pause: about the price of coal, about the children, about how little the charities send. She watches you the whole time.";
				if (ways.len() > 0) text = text + "\n\n" + c.joinList(ways, " ");
				else text = text + "\n\nThere is nothing more to learn here by asking politely.";
				if (c.ruthlessOK())
				{
					text = text + " Or the company could stop being polite and search every room by force, whatever the neighbours and the watch make of it.";

					if (c.worseFound() && c.m.Report == 0) text = text + " What you already know also has a price, and she would pay it.";
				}
				text = text + (handed ? "\n\nWhen you have seen enough, Ollysta is waiting for her report." : "\n\nWhen you have seen enough, the door is behind you.");
				this.Text = c.img(::Const.Skv.Lore.ImgHouse) + "{" + text + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if ((S & 8) == 0)
				{
					this.Options.push({
						Text = "{Share a cup of her tea.}",
						function getResult() { return this.Contract.resolveHouse(1); }
					});
				}
				if ((S & 16) == 0)
				{
					this.Options.push({
						Text = "{Search upstairs while she cooks.}",
						function getResult() { return this.Contract.resolveHouse(2); }
					});
				}
				if ((S & 32) == 0)
				{
					this.Options.push({
						Text = "{Talk with the children out of her hearing.}",
						function getResult() { return this.Contract.resolveHouse(3); }
					});
				}
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Search the house by force.}",
						function getResult() { return this.Contract.resolveForce(); }
					});
					if (c.worseFound() && c.m.Report == 0)
					{
						this.Options.push({
							Text = "{Sell her your silence.}",
							function getResult() { return this.Contract.resolveSilence(); }
						});
					}
				}
				this.Options.push({
					Text = handed ? "{Go back to the temple.}" : "{Leave the house.}",
					function getResult() { return this.Contract.resolveLeave(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Forced",
			Title = "The Watch's Whistles",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgHouse) + "{The men go through the house room by room while the children wail and the cats run under the beds. It is all there: the bottles, the medicine of three charities stacked behind a false wall, and a little book of what each child earns her in other people's kitchens. Baltwin screams for the watch out of the window, and the watch is never far from a house like this. The company leaves by the back with what it can carry. The old woman will tell the story her own way.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the streets.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Errands";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "Ollysta's Question",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local sold = c.m.Report == 3;
				local found = c.secretsFound();
				local soft = sold || c.worseFound();
				local softDrink = c.softTold() == 1;
				local text = "Ollysta hears you in the temple court, standing, and asks what you saw in the house.\n\n";
				if (sold)
					text = text + "Baltwin's purse is in your pack, and it bought her a short report: " + (softDrink ? "the drink, which she admits to anyone, and not a word more." : "that nothing is wrong in the house.");
				else if (found == 0)
					text = text + "You found nothing against the old woman, and can only say so.";
				else
				{
					text = text + (c.kindOK() ? "You could tell her everything you found." : "");
					if (soft)
						text = text + (c.kindOK() ? " Or you" : "You") + (softDrink
							? " could tell her of the drink and leave out the rest. Then the house stays as it is, and the children keep their Auntie."
							: " could tell her that nothing is wrong. Then the house stays as it is, and the children keep their Auntie.");
				}
				this.Text = c.img(::Const.Skv.Lore.ImgTemple) + "{" + text + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if (!sold && c.kindOK())
				{
					this.Options.push({
						Text = found == 0 ? "{Tell her the house seems sound.}" : "{Tell her everything.}",
						function getResult() { return this.Contract.resolveReport(1); }
					});
				}
				if (soft)
				{
					this.Options.push({
						Text = softDrink ? "{Tell her only of the drink.}" : "{Tell her nothing is amiss.}",
						function getResult() { return this.Contract.resolveReport(2); }
					});
				}
				if (this.Options.len() == 0)
				{

					::logError("Skv.Lore: the Report screen had no button for band " + c.m.Band + " with secrets " + c.m.Secrets + "; the plain report is offered.");
					this.Options.push({
						Text = "{Tell her what you saw.}",
						function getResult() { return this.Contract.resolveReport(1); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Sage",
			Title = "The Sapphire Sage",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgSage) + "{The master of the house is away, and it is his adviser who receives you: %SKVNAME%Amenopheus%SKVNAME_OFF%, an old man in blue with a sapphire on his brow, who talks for a long time about Osirion. His country kept its doors shut to strangers for an age, he says, and ever since it opened them its tombs have been losing their treasures to every thief who owns a shovel.%SPEECH_ON%Valsin wants leave to dig in the vaults of the Salhar family, under Sothis. The family will give it. But the map of those vaults must cross this city in somebody's hands, and I have seen what careless hands do. The map lies in the vault beneath this house. Bring it up to me, and be careful how you do it. My servant will show you down.%SPEECH_OFF%The servant, who has not said a word, holds a door open and waits.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Follow the servant down.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Vault";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Vault",
			Title = "The Sage's Vault",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local V = c.m.Vault;
				local text = "The servant locks the door behind you and turns over a sandglass in a niche by the stair. The vault holds five things and nothing else: a reed basket, a clay jar with a wide mouth, a plain wooden chest, a chest carved with runes, and a chest of steel. The rune chest and the steel chest are locked. The map is in one of the five, and the sand is running.\n\nEverything you try costs time.";
				if ((V & 1) == 0) text = text + " A man with some learning could spend a part of that time studying the room before anyone touches it.";
				if ((V & 16) != 0) text = text + " You hold the golden key, and only the steel chest has a lock of that colour.";
				else if ((V & 2) != 0) text = text + " You hold an iron key from the basket, and the rune chest has an iron lock.";
				this.Text = c.img(::Const.Skv.Lore.ImgVault) + "{" + text + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				local n = c.m.Moves;
				rows.push(n > 1 ? c.goodRow("Sand left for " + c.word(n) + " more attempts") : c.badRow("Sand left for one more attempt"));
				this.List = rows;
				this.Options = [];
				if ((V & 1) == 0)
				{
					this.Options.push({
						Text = "{Study the room first.}",
						function getResult() { return this.Contract.resolveVault(0); }
					});
				}
				if ((V & 2) == 0)
				{
					this.Options.push({
						Text = "{Open the basket.}",
						function getResult() { return this.Contract.resolveVault(1); }
					});
				}
				if ((V & 4) == 0)
				{
					this.Options.push({
						Text = c.decoyKnown(true) ? "{Fish in the jar. (known for a decoy)}" : "{Fish in the jar.}",
						function getResult() { return this.Contract.resolveVault(2); }
					});
				}
				if ((V & 8) == 0)
				{
					this.Options.push({
						Text = c.decoyKnown(false) ? "{Open the plain chest. (known for a decoy)}" : "{Open the plain chest.}",
						function getResult() { return this.Contract.resolveVault(3); }
					});
				}

				if ((V & 16) == 0)
				{
					this.Options.push({
						Text = (V & 2) != 0 ? "{Open the rune chest with the iron key.}" : "{Try the rune chest. (missing key)}",
						function getResult() { return this.Contract.resolveVault(4); }
					});
				}
				if ((V & 32) == 0)
				{
					this.Options.push({
						Text = (V & 16) != 0 ? "{Open the steel chest with the golden key.}" : "{Try the steel chest. (missing key)}",
						function getResult() { return this.Contract.resolveVault(5); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "MapOut",
			Title = "The Map",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				this.Text = c.img(C.ImgSage) + "{In the steel chest lie a map on oiled hide, a letter of leave under the Salhar seal, and a short rod of dark wood banded in brass. The showy sceptre from the rune chest, all gilt and glass, turns out to be the key to the vault door. Amenopheus is waiting at the top of the stair."
					+ (c.m.Blue > 0
						? " He looks at the blue skin for a long moment.%SPEECH_ON%The dye fades, in time. Until it does, every thief in this city can find you in a crowd, and so can I. Still, the map is out, and I keep my word. Carry it to Valsin. The rod opens locks, and it is yours.%SPEECH_OFF%"
						: "%SPEECH_ON%Careful hands. That is rarer than courage. Carry the map to Valsin. The rod opens locks, and it is yours for the trouble.%SPEECH_OFF%") + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantMapOut))
				{
					local made = ::Skv.Loot.make([ C.ItemWand ]);
					if (made.len() > 0) rows.push(c.itemRow(made[0]));
				}
				this.List = rows;
				this.Options = [
					{
						Text = "{Back to the streets.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Lore;
							if (!c.hasGrant(C.GrantMapOut))
							{
								c.setGrant(C.GrantMapOut);
								local made = ::Skv.Loot.make([ C.ItemWand ]);
								if (made.len() == 0) ::logError("Skv.Lore: the wand could not be made; it is not granted.");
								else
								{
									local stash = ::World.Assets.getStash();
									stash.makeEmptySlots(1);
									stash.add(made[0]);
									::logInfo("Skv.Lore: the wand granted (" + made[0].getName() + ", " + made[0].getCharges() + " charges)");
								}
							}
							c.closeErrand(C.KindSage, true);
							c.m.Rows = [ c.goodRow("You left with the map for Valsin") ];
							return "Errands";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "LetOut",
			Title = "Out of Time",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgSage) + "{The last of the sand runs through, and the servant opens the door at once, as if he had been counting. Amenopheus does not ask what went wrong.%SPEECH_ON%Then the map stays with me until I find a courier of my own. Tell Valsin that the Salhar vaults have waited for an age. They can wait a little longer.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the streets.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Errands";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Envoy",
			Title = "The Envoy's House",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgEnvoy) + "{The house is hung in black and crimson from the door to the rafters. %SKVNAME%Zarta Dralneen%SKVNAME_OFF%, Paracountess and envoy of Cheliax, receives you lying on a couch, and looks the company over the way a buyer looks over horses.%SPEECH_ON%Valsin's messengers. He wants his iron case back, the one with the seven locks, and he shall have it. Whatever you have heard, in Cheliax we do not kneel to devils. We employ them, and everyone is happier when each knows his place. Which brings me to a servant of mine. He has shut himself in my bedroom with the case and forgotten his place entirely. Go and remind him of it.%SPEECH_OFF%Something heavy breaks behind the wall. She hands you a letter opener, a slim blade of silver, and mentions that he cannot bear the metal.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{See to the servant.}",
						function getResult()
						{
							local c = this.Contract;
							c.m.Imp = c.m.Imp | 16;
							c.m.Rows = [];
							::logInfo("Skv.Lore: Envoy -> the errand ATTEMPTED (imp=" + c.m.Imp + ")");
							return "Bedroom";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Bedroom",
			Title = "The Servant",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local I = c.m.Imp;
				local ways = [];
				if ((I & 1) == 0) ways.push("He is furious, not mad, and a calm voice might still reach him.");
				if ((I & 4) == 0) ways.push("The silver blade would drive him off, if anyone can hit something that small and that quick.");
				if (c.powderHeld()) ways.push("The grey powder from Karela's crate clings to whatever it touches, seen or unseen.");
				this.Text = c.img(::Const.Skv.Lore.ImgImp) + "{The bedroom has been torn apart: curtains in ribbons, a mirror in pieces, feathers still coming down. On the bedpost sits the servant. He is red, horned and winged, no bigger than a cat, and he is beating an iron case against the post with both arms and screaming at it. When he notices you he vanishes, and something laughs from the ceiling."
					+ (ways.len() > 0 ? "\n\n" + c.joinList(ways, " ") : "") + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if ((I & 1) == 0)
				{
					this.Options.push({
						Text = "{Calm him with words.}",
						function getResult() { return this.Contract.resolveImp(1); }
					});
				}
				if ((I & 4) == 0)
				{
					this.Options.push({
						Text = "{Attack him with the silver blade.}",
						function getResult() { return this.Contract.resolveImp(2); }
					});
				}
				if (c.powderHeld())
				{
					this.Options.push({
						Text = "{Throw the powder.}",
						function getResult() { return this.Contract.resolveImp(3); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Case",
			Title = "Seven Locks",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgCase) + "{" + (c.impCalmed()
					? "The imp sits down on the wrecked bed with his tail around his feet, and lets you take the case.%SPEECH_ON%It holds a kit for calling my kind out of Hell on a leash. Brass tools, every one with a name cut into it. I wanted it sunk where nobody would look. She wants it for herself. She could not open it, and she cannot keep what the lodge lent her. So she smiles and hands it back, and she has paid a pack of young thieves to take it from you before you reach your lodge. Devils in chalk across the street. She thinks that is funny.%SPEECH_OFF%Then he is gone up the chimney."
					: "The imp drops the case, shrieks something about his mistress, and is gone up the chimney.")
					+ "\n\nThe case is cold iron, shut with seven locks. You could carry it to Valsin as it is. Or one of the men could try the locks first: they look like the kind that bite, but somebody would surely pay to know what is inside.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Carry it as it is.}",
						function getResult() { return this.Contract.resolveCase(false); }
					},
					{
						Text = "{Try the locks.}",
						function getResult() { return this.Contract.resolveCase(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Thanks",
			Title = "The Paracountess",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgEnvoy) + "{Zarta walks through what is left of her bedroom without a glance at the damage, and seems delighted with you." + (c.m.Case == 3 ? " Her eyes rest on the scratched locks for a moment, and she says nothing about them." : "")
					+ "%SPEECH_ON%How capable. Take Valsin his box, with my compliments. As for my little blade: keep it, if you promise to come and see me again. I collect capable people. Or give it back and take a purse for your trouble, like any other tradesman.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Keep the blade and promise the visit.}",
						function getResult() { return this.Contract.resolveThanks(true); }
					},
					{
						Text = "{Give the blade back and take the purse.}",
						function getResult() { return this.Contract.resolveThanks(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "ImpLoose",
			Title = "Still Loose",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgImp) + "{Something is still laughing in the bedroom when Zarta shuts the door on it and takes her silver blade back.%SPEECH_ON%Then the case stays where it is until my house is in order. Tell Valsin that he may send somebody competent.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the streets.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Errands";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "HeadBack",
			Title = "Back in Town",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local open = 4 - c.closedCount();
				this.Text = c.img(::Const.Skv.Lore.ImgLodge) + "{You are back in %SKVTOWN%, and " + (open == 1 ? "one errand is" : (open == 2 ? "two errands are" : "three errands are"))
					+ " still open. If you go to Valsin now, the rest will go undone. If you still have work, the lodge can wait until you come back.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Go to the lodge now.}",
						function getResult() { return this.Contract.headBackNow(); }
					},
					{
						Text = "{We still have work.}",
						function getResult() { return 0; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Street",
			Title = "The Side Alley",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Lore.ImgStreet) + "{A crowd fills the street to the lodge. Somebody has drawn a whole hell across the cobbles in chalk, devils and flames from wall to wall, and the people stand around it and will not make way."
					+ (c.m.Revealed == 1 ? " Devils in chalk: the imp told you whose idea of fun this is, and what comes next." : "")
					+ " The only way through is a narrow side alley, and a mist is gathering in it on a dry day."
					+ (c.alleyCircle() ? " You are well into it before you see the shapes moving at both ends."
						: (c.tailsSpotted() > 0 ? " The company goes in with hands on hilts." : "")) + "}";
				local rows = [];
				if (c.tailsSpotted() > 0)
				{

					rows.push(c.goodRow((c.spotterHere() ? c.m.Spotter : "One of the company") + " knew the face at the alley mouth"));
					rows.push(c.goodRow("The company was not surrounded"));
					if (c.alleyTrim()) rows.push(c.goodRow("Seen twice, the gang had to hurry, and came with fewer men"));
					if (c.alleySlow()) rows.push(c.goodRow("Seen three times, their leaders were slow to react"));
				}
				else if (c.alleyCircle())
				{
					rows.push(c.badRow("Nobody had marked the followers"));
					rows.push(c.badRow("The gang closed in from every side"));
				}
				this.List = rows;
				this.Options = [
					{
						Text = "{Draw steel.}",
						function getResult()
						{
							local c = this.Contract;
							if ((c.m.Alley & 0x0F) != 0) return c.wayBackScreen();
							c.getActiveState().onCombatAlley();
							return 0;
						}
					},
					c.gearOption("Street")
				];
			}
		});

		this.m.Screens.push({
			ID = "AlleyAfter",
			Title = "After the Alley",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local n = c.alleyNamed();
				local purse = "On " + (n >= 1 ? "the red-haired woman who led them" : "the one who led them") + " you find a purse of black and crimson silk, already empty.";
				if (c.m.Revealed == 1) purse = purse + " The imp did not lie.";
				else if (c.m.Revealed == 2) purse = purse + " You have seen those colours before, on every wall of the envoy's house. "
					+ (c.isDone(C.Sites[C.KindEnvoy].Bit)
						? "Zarta handed the case over with a smile, and paid to have it taken from you on the way home."
						: "Whatever these people were sent to take from Valsin's messengers, Zarta paid for it.");
				else purse = purse + " It is far too fine a thing for a street thief, and its colours mean nothing to you.";
				local who = n >= 4 ? "One of them is still breathing: %SKVNAME%Ledford%SKVNAME_OFF%, a halfling with a waxed moustache and an axe as long as he is tall."
					: "One of them is still breathing: their lookout, caught at the alley mouth, a halfling with a waxed moustache and an axe as long as he is tall. He gives his name as %SKVNAME%Ledford%SKVNAME_OFF%.";

				local plea = "%SPEECH_ON%Enough. You have won. We were paid to rob you, and only the red one dealt with whoever paid. I was promised a house in Cheliax, with servants, and here I lie in a gutter. My cut of the advance is sewn into my coat. It is yours if I walk out of this alley.%SPEECH_OFF%";
				local ways = [];
				if (c.kindOK()) ways.push("You could hand him to the watch.");
				ways.push((c.kindOK() ? "You could also take" : "You could take") + " his coin and let him go.");
				if (c.ruthlessOK()) ways.push("Or you could finish him and take what he carries.");
				this.Text = c.img(C.ImgAlley) + "{The mist thins, and the alley is yours. " + purse + "\n\n" + who + " He is beaten, and he knows it." + plea + c.joinList(ways, " ") + "}";
				local rows = [];
				local names = [];
				for (local i = 0; i < n && i < 3 && i < C.GangNames.len(); i = i + 1) names.push(C.GangNames[i]);
				local rest = c.m.Gang - n;
				if (rest > 0) names.push(rest + (names.len() > 0 ? (rest == 1 ? " other" : " others") : (rest == 1 ? " robber" : " robbers")));
				if (names.len() > 0) rows.push(c.goodRow("Beaten in the alley: " + c.joinList(names, ", ")));
				this.List = rows;
				this.Options = [];
				if (c.kindOK())
				{
					this.Options.push({
						Text = "{Hand him to the watch.}",
						function getResult() { return this.Contract.resolveLedford(2); }
					});
				}
				this.Options.push({
					Text = "{Take his coin and let him go.}",
					function getResult() { return this.Contract.resolveLedford(1); }
				});
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Finish him.}",
						function getResult() { return this.Contract.resolveLedford(3); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "AlleyLeave",
			Title = "The Way Is Clear",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local L = c.m.Ledford;
				this.Text = c.img(::Const.Skv.Lore.ImgAlley) + (L == 2
					? "{The watch arrives when everything is over, as the watch does. It takes the halfling away in irons and asks few questions: it knows the faces of the others.}"
					: (L == 3
						? "{It is quick. His axe was better than his luck.}"
						: "{Ledford cuts a small purse out of the lining of his coat, drops it at your feet, and is gone before the mist is.}"));
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{On to the lodge.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Pay";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AlleyLost",
			Title = "Robbed",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local map = c.isDone(C.Sites[C.KindSage].Bit);
				local box = c.isDone(C.Sites[C.KindEnvoy].Bit);
				this.Text = c.img(C.ImgAlley) + "{You pull the company back out of the alley, and the gang does not follow. " + ((map || box)
					? "It has no need to: what it came for was dropped in the mist, and it is gone before you reach the street."
					: "It finds nothing on the ground worth chasing you for, and it is gone before you reach the street.") + " The lodge is two streets away by the long road.}";
				local rows = [ c.badRow("You lost the fight in the alley") ];
				if (map) rows.push(c.badRow("The gang took the map"));
				if (box) rows.push(c.badRow("The gang took the case"));
				this.List = rows;
				this.Options = [
					{
						Text = "{On to the lodge.}",
						function getResult()
						{
							this.Contract.m.Rows = [];
							return "Pay";
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
				local C = ::Const.Skv.Lore;
				local t = c.tier();
				local baltBit = C.Sites[C.KindBaltwin].Bit;
				local text = t == C.TierSuccess
					? "Valsin listens to your account of the day, from the first door to the alley, and does not interrupt.%SPEECH_ON%Outside hands. I should hire them more often.%SPEECH_OFF%"
					: (t == C.TierPoor
						? "Valsin listens to your account of the day and counts on his fingers what came of it.%SPEECH_ON%Not the day I hoped for. I pay for what lies on this table, and half a wage for your trouble.%SPEECH_OFF%"
						: "Valsin listens to your account of the day with his eyes closed.%SPEECH_ON%Four letters, and this is what comes back. I pay for what you have put on this table and for nothing else.%SPEECH_OFF%");
				local more = [];
				if (c.mapDelivered()) more.push("He unrolls the map and studies it for a long time. The Salhar vaults under Sothis, he says, are work for people he sends beyond the walls, once he has learned to trust them.");
				if (c.caseDelivered() && c.impCalmed()) more.push("When you repeat what the imp said about the case, he only nods: that is why the lodge sealed it.");
				if (c.finderPay() > 0) more.push("What was seen under the lid interests him, and he pays to hear it told twice.");
				if (c.caseDelivered() && c.m.Case == 3) more.push("He turns the case under the lamp, finds the scratches at once, and takes them out of its price.");
				if (c.isClosed(baltBit) && !c.isDone(baltBit)) more.push("No report has reached Ollysta, he adds, and she will ask him why.");
				if (c.alleyLost()) more.push("Of the alley he says only that the lodge will find those thieves in its own time.");
				if (more.len() > 0) text = text + c.joinList(more, " ");
				this.Text = c.img(C.ImgLodge) + "{" + text + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;

				if (!c.hasGrant(C.GrantPay)) rows.extend(c.payRows());
				this.List = rows;
				this.Options = [
					{
						Text = (c.revealed() && c.m.Zarta == 0)
							? ((!c.hasGrant(C.GrantPay) && c.payTotal() > 0) ? "{Take the coin. There is more to say.}" : "{There is more to say.}")
							: "{Farewell.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Lore;
							local t = c.tier();
							if (!c.hasGrant(C.GrantPay))
							{
								c.setGrant(C.GrantPay);
								local sum = c.payTotal();
								if (sum > 0) ::World.Assets.addMoney(sum);
								::World.Assets.addBusinessReputation(c.tierRenown(t));
								local rel = c.tierRelation(t);
								if (rel != 0)
								{
									local f = c.factionOr(c.getFaction());
									if (f == null) ::logError("Skv.Lore: the host's faction did not resolve; the tier's relation change of " + rel + " is lost.");
									else f.addPlayerRelation(rel, t == C.TierSuccess ? "Ran the lodge's errands" : "Failed the lodge's errands");
								}
								::logInfo("Skv.Lore: PAID. tier=" + c.tierName(t) + " done=" + c.m.Done + " (" + c.doneCount() + ") closed=" + c.m.Closed
									+ " alley=" + c.m.Alley + " fee=" + c.fee() + " sum=" + sum + " (map " + c.mapPay() + ", case " + c.casePay()
									+ ", finder " + c.finderPay() + ", wage " + c.wagePay() + ") renown=" + c.tierRenown(t) + " relation=" + rel
									+ " band=" + c.m.Band + " granted=" + c.m.Granted);
							}
							c.m.Act = 3;
							c.m.Rows = [];
							if (c.revealed() && c.m.Zarta == 0) return "Envoy2";
							return c.finish();
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Envoy2",
			Title = "The Envoy's Hand",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local ways = [];
				if (c.kindOK()) ways.push("You could tell him. Nobody can punish an envoy, but the lodge could stop lending her things.");
				ways.push((c.kindOK() ? "You could also say" : "You could say") + " nothing: it is the lodge's quarrel, not the company's.");
				if (c.ruthlessOK()) ways.push("Or you could say nothing here and pay Zarta " + (c.m.Opener == 1 ? "the visit you promised" : "a visit") + ", so that she learns what your silence is worth.");
				this.Text = c.img(::Const.Skv.Lore.ImgLodge) + "{Valsin is already reaching for his pen. He does not know who paid for the alley. You do: "
					+ (c.m.Revealed == 1 ? "her own servant told you." : "her colours were on the gang's purse.") + "\n\n" + c.joinList(ways, " ") + "}";
				this.List = [];
				this.Options = [];
				if (c.kindOK())
				{
					this.Options.push({
						Text = "{Tell Valsin.}",
						function getResult() { return this.Contract.resolveZarta(1); }
					});
				}
				this.Options.push({
					Text = "{Say nothing.}",
					function getResult() { return this.Contract.resolveZarta(3); }
				});
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Say nothing, and visit the envoy.}",
						function getResult() { return this.Contract.resolveZarta(2); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "EnvoyAfter",
			Title = "The Envoy's Hand",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Lore;
				local Z = c.m.Zarta;
				if (Z == 1)
					this.Text = c.img(C.ImgLodge) + "{Valsin listens, and his face does not change.%SPEECH_ON%An envoy. I cannot so much as raise my voice to her. But this lodge has lent the Paracountess its last book, its last key and its last favour.%SPEECH_OFF%}";
				else if (Z == 2)
					this.Text = c.img(C.ImgEnvoy) + "{Zarta receives you on the same couch, and is not at all surprised to see you. She counts out the coin herself, slowly, and says that she likes people who understand what a secret is for.}";
				else if (Z == 3)
					this.Text = c.img(C.ImgLodge) + "{You say nothing. Whatever Zarta wanted with that case is the lodge's business, and the lodge has not asked you.}";
				else
					this.Text = c.img(C.ImgLodge) + "{Valsin has nothing more for you today.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Farewell.}",
						function getResult() { return this.Contract.finish(); }
					}
				];
			}
		});
	}

	function onClear()
	{
		::Skv.Once.release(::Const.Skv.Lore.OnceKey);
		if (this.m.IsActive)
		{
			::Skv.Once.retire(::Const.Skv.Lore.OnceKey);

			if (!::World.Flags.has(::Const.Skv.Lore.ArcFlagOutcome))
				this.recordOutcome(::Const.Skv.Lore.OutcomeAbandoned);

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
			::logInfo("Skv.Lore: a saved marker id " + id + " resolved to nothing on load; the repair will respawn it if its errand is still open.");
			return null;
		}
		return this.WeakTableRef(e);
	}

	function onSerialize( _out )
	{
		this.writeMarker(_out, this.m.Shop);
		this.writeMarker(_out, this.m.Temple);
		this.writeMarker(_out, this.m.Sage);
		this.writeMarker(_out, this.m.Envoy);
		_out.writeU16(this.m.DayAccepted);
		_out.writeU8(this.m.Act);
		_out.writeU8(this.m.Closed);
		_out.writeU8(this.m.Done);
		_out.writeU8(this.m.Karela);
		_out.writeU8(this.m.Entry);
		_out.writeU8(this.m.Rats);
		_out.writeU8(this.m.Crate);
		_out.writeU8(this.m.Dive);
		_out.writeU8(this.m.Goods);
		_out.writeU8(this.m.Gossip);
		_out.writeU8(this.m.Medicine);
		_out.writeU8(this.m.Secrets);
		_out.writeU8(this.m.Report);
		_out.writeU8(this.m.Moves);
		_out.writeU16(this.m.Vault);
		_out.writeU8(this.m.Blue);
		_out.writeU8(this.m.Imp);
		_out.writeU8(this.m.Case);
		_out.writeU8(this.m.Opener);
		_out.writeU8(this.m.Tails);
		_out.writeString(this.m.Spotter);
		_out.writeU8(this.m.Alley);
		_out.writeU8(this.m.Ledford);
		_out.writeU8(this.m.Revealed);
		_out.writeU8(this.m.Zarta);
		_out.writeU8(this.m.Band);
		_out.writeU32(this.m.Granted);
		_out.writeString(this.m.ActorName);
		local rows = this.m.Rows == null ? [] : this.m.Rows;
		local n = ::Math.min(255, rows.len());
		if (rows.len() > 255) ::logError("Skv.Lore: " + rows.len() + " rows on the open screen; only 255 are saved.");
		_out.writeU8(n);
		for (local i = 0; i < n; i++)
		{
			_out.writeString(rows[i].icon);
			_out.writeString(rows[i].text);
		}
		_out.writeU16(this.m.Gang);
		_out.writeU32(this.m.Res32);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.m.Shop = this.readMarker(_in);
		this.m.Temple = this.readMarker(_in);
		this.m.Sage = this.readMarker(_in);
		this.m.Envoy = this.readMarker(_in);
		this.m.DayAccepted = _in.readU16();
		this.m.Act = _in.readU8();
		this.m.Closed = _in.readU8();
		this.m.Done = _in.readU8();
		this.m.Karela = _in.readU8();
		this.m.Entry = _in.readU8();
		this.m.Rats = _in.readU8();
		this.m.Crate = _in.readU8();
		this.m.Dive = _in.readU8();
		this.m.Goods = _in.readU8();
		this.m.Gossip = _in.readU8();
		this.m.Medicine = _in.readU8();
		this.m.Secrets = _in.readU8();
		this.m.Report = _in.readU8();
		this.m.Moves = _in.readU8();
		this.m.Vault = _in.readU16();
		this.m.Blue = _in.readU8();
		this.m.Imp = _in.readU8();
		this.m.Case = _in.readU8();
		this.m.Opener = _in.readU8();
		this.m.Tails = _in.readU8();
		this.m.Spotter = _in.readString();
		this.m.Alley = _in.readU8();
		this.m.Ledford = _in.readU8();
		this.m.Revealed = _in.readU8();
		this.m.Zarta = _in.readU8();
		this.m.Band = _in.readU8();
		this.m.Granted = _in.readU32();
		this.m.ActorName = _in.readString();
		local n = _in.readU8();
		this.m.Rows = [];
		for (local i = 0; i < n; i++)
		{
			local icon = _in.readString();
			local text = _in.readString();
			this.m.Rows.push({ id = 1, icon = icon, text = text });
		}
		this.m.Gang = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.contract.onDeserialize(_in);
	}
});
