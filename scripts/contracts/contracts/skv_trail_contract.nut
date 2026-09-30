this.skv_trail_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Marker        = null,
		DestinationID = 0,
		RivalID       = 0,
		HouseID       = 0,
		DP            = 0,
		Gin           = 0,
		Nobles        = 0,
		NobleTalks    = 0,
		Ravens        = 0,
		Lore          = 0,
		OrcLoreName   = "",
		SnowLoreName  = "",
		Travel        = 0,
		GiftPaid      = 0,
		ClimbMode     = 0,
		Slides        = 0,
		Bark          = 0,
		BarkPaid      = 0,
		Goats         = 0,
		StreamTasks   = 0,
		VantageTasks  = 0,
		Odvar         = 0,
		Orcs          = 0,
		Cave          = 0,
		CampPrep      = 0,
		Stop          = 0,
		Concluded     = 0,
		BoonGranted   = false,
		BoonName      = "",
		ActorName     = "",
		Rows          = null,

		LairGuards    = 0,
		Res16         = 0,
		Res32         = 0,

		DestNoted     = false
	},

	function isDone( _field, _i )   { return (_field & (1 << _i)) != 0; }
	function isPassed( _field, _i ) { return (_field & (1 << (_i + 8))) != 0; }
	function mark( _field, _i, _ok )
	{
		local v = _field | (1 << _i);
		if (_ok) v = v | (1 << (_i + 8));
		return v;
	}
	function countPassed( _field, _n )
	{
		local k = 0;
		for (local i = 0; i < _n; i++) if (this.isPassed(_field, i)) k++;
		return k;
	}

	function travelAt( _i ) { return (this.m.Travel >> (2 * _i)) & 3; }
	function setTravel( _i, _v )
	{
		this.m.Travel = (this.m.Travel & ~(3 << (2 * _i))) | ((_v & 3) << (2 * _i));
	}

	function sb( _base ) { return ::Skv.Check.scaledBase(this, _base); }

	function actorName( _r )
	{
		return (_r != null && _r.actor != null) ? _r.actor.getName() : "One of the company";
	}

	function gearOption( _screenID )
	{
		return {
			Text = "{Set our gear right. (open loadout)}",
			function getResult()
			{
				if (!::World.State.showLoadoutFromContract())
					::logError("Skv.Trail: the loadout did not open from " + _screenID + " (the contract screen hidden or still animating?)");
				return _screenID;
			}
		};
	}

	function goodRow( _text ) { return { id = 1, icon = "ui/icons/special.png", text = _text }; }
	function badRow( _text )  { return { id = 1, icon = "ui/icons/regular_damage.png", text = _text }; }

	function pointsText( _n )
	{
		local a = _n < 0 ? -_n : _n;
		return a + (a == 1 ? " point" : " points");
	}

	function pointsRow( _delta )
	{
		if (_delta > 0) return this.goodRow("The survey gains " + this.pointsText(_delta));
		if (_delta < 0) return this.badRow("The survey loses " + this.pointsText(_delta));
		return this.badRow("The survey gains nothing here");
	}

	function standsRow()
	{
		local n = this.m.DP;
		return this.goodRow("The survey stands at " + n + (n == 1 ? " point" : " points"));
	}

	function moralRow( _delta, _text )
	{
		local col = _delta < 0 ? ::Const.UI.Color.NegativeEventValue : ::Const.UI.Color.PositiveEventValue;
		return { id = 1, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + col + "]" + _text + " (" + (_delta < 0 ? "" : "+") + _delta + ")[/color]" };
	}

	function addDP( _n, _why )
	{
		local before = this.m.DP;
		this.m.DP += _n;
		if (this.m.DP < 0) this.m.DP = 0;
		local got = this.m.DP - before;
		::Skv.dbg("Skv.Trail: survey " + (_n >= 0 ? "+" : "") + _n + (got != _n ? " (floored: " + got + ")" : "")
			+ " (" + _why + ") -> " + this.m.DP);
		return got;
	}

	function lossRows( _n, _logWhy, _why = null )
	{
		local got = this.addDP(-_n, _logWhy);
		if (got >= 0) return [];
		if (_why == null) return [this.pointsRow(got)];
		return [this.badRow("The survey loses " + this.pointsText(got) + ": " + _why)];
	}

	function isXPRow( _r ) { return _r.icon == "ui/icons/xp_received.png"; }
	function rowsKept()
	{
		local out = [];
		if (this.m.Rows != null) foreach (r in this.m.Rows) if (!this.isXPRow(r)) out.push(r);
		return out;
	}
	function rowsXP()
	{
		local out = [];
		if (this.m.Rows != null) foreach (r in this.m.Rows) if (this.isXPRow(r)) out.push(r);
		return out;
	}
	function setRows( _rows, _xp )
	{
		this.m.Rows = [];
		this.m.Rows.extend(_rows);
		this.m.Rows.extend(_xp);
	}

	function addAction( _rows, _xp )
	{
		local kept = this.rowsKept();
		kept.extend(_rows);
		this.setRows(kept, _xp);
	}
	function clearRows() { this.m.Rows = []; }

	function listWith( _derived )
	{
		local out = this.rowsKept();
		out.extend(_derived);
		out.extend(this.rowsXP());
		return out;
	}

	function factionOr( _id )
	{
		if (_id == 0) return null;
		try { return ::World.FactionManager.getFaction(_id); }
		catch (e) { ::logError("Skv.Trail: faction " + _id + " did not resolve - " + e); }
		return null;
	}

	function houseName()
	{
		local f = this.factionOr(this.m.HouseID);
		return f != null ? f.getName() : "The house";
	}

	function rivalName()
	{
		local f = this.factionOr(this.m.RivalID);
		return f != null ? f.getName() : "a rival house";
	}

	function destination()
	{
		if (this.m.DestinationID == 0) return null;
		local d = null;
		try { d = ::World.getEntityByID(this.m.DestinationID); }
		catch (e) { ::logError("Skv.Trail: the far town's id threw - " + e); }
		if (d == null || ::MSU.isNull(d))
		{
			if (!this.m.DestNoted)
			{
				this.m.DestNoted = true;
				::logError("Skv.Trail: the far town (id " + this.m.DestinationID + ") no longer resolves; the survey falls back to "
					+ (this.m.Home != null ? this.m.Home.getName() : "the employer") + ".");
			}
			return null;
		}
		return d;
	}

	function pickRival( _house )
	{
		local home = this.m.Home.getTile();
		local best = null;
		local bestD = 9999;
		local houses = [];
		try { houses = ::World.FactionManager.getFactionsOfType(::Const.FactionType.NobleHouse); }
		catch (e)
		{
			::logError("Skv.Trail: getFactionsOfType(NobleHouse) threw - " + e);
			return 0;
		}
		foreach (f in houses)
		{
			if (f == null || (_house != null && f.getID() == _house.getID())) continue;
			foreach (s in f.getSettlements())
			{
				if (s == null) continue;
				local d = s.getTile().getDistanceTo(home);
				if (d < bestD || (d == bestD && best != null && f.getID() < best.getID()))
				{
					best = f;
					bestD = d;
				}
			}
		}
		return best == null ? 0 : best.getID();
	}

	function fixRoute()
	{
		local T = ::Skv.Trail;
		local home = this.m.Home;
		local pl = T.plan(home);
		this.m.DestinationID = pl.Far == null ? 0 : pl.Far.getID();
		local h = T.house(home);
		this.m.HouseID = h == null ? 0 : h.getID();
		this.m.RivalID = this.pickRival(h);
		this.m.Payment.Pool = T.fullPay(this, pl.Steps);
		local over = "";
		foreach (i, r in pl.Rejected) over = over + (i == 0 ? "" : "; ") + r;

		::Skv.dbg("Skv.Trail: ROUTE from " + home.getName() + " -> "
			+ (pl.Far != null ? "the far town " + pl.Far.getName() : "FALLBACK (into the mountains and back to " + home.getName() + ")")
			+ ", walk " + pl.Steps + " steps, full pay " + this.m.Payment.Pool
			+ " (diff " + this.getDifficultyMult() + "), house " + this.houseName() + ", rival " + this.rivalName()
			+ (over == "" ? "" : "; passed over: " + over));
		if (h == null) ::logError("Skv.Trail: " + home.getName() + " has no owning noble house; the text will say \"The house\".");
	}

	function killMarker()
	{
		if (!::MSU.isNull(this.m.Marker))
		{
			this.m.Marker.getSprite("selection").Visible = false;
			this.m.Marker.die();
		}
		this.m.Marker = null;
	}

	function dressMarker()
	{
		if (::MSU.isNull(this.m.Marker)) return;
		local C = ::Const.Skv.Trail;
		local k = this.m.Stop;
		if (k < 1 || k >= C.StopBrushes.len()) return;
		try
		{
			this.m.Marker.getSprite("body").setBrush(C.StopBrushes[k]);
			this.m.Marker.setName(C.StopNames[k]);
			this.m.Marker.getSprite("selection").Visible = true;
		}
		catch (e) { ::logError("Skv.Trail: could not dress the stop " + k + " marker - " + e); }
	}

	function spawnStop( _k )
	{
		local T = ::Skv.Trail;
		this.killMarker();
		local far = this.destination();
		local stops = T.stopsFor(this.m.Home, far);
		local tile = stops[_k - 1];
		local via = "the route";

		if (tile == null && far != null)
		{
			tile = T.stopsAlong(this.m.Home.getTile(), far.getTile(), false)[_k - 1];
			via = "the route, off its terrain (its tiles are taken now)";
			::logError("Skv.Trail: stop " + _k + " found no free " + T.stopTerrainText(_k) + " tile any more; placed on the route regardless.");
		}
		if (tile == null)
		{
			tile = this.getTileToSpawnLocation(::World.State.getPlayer().getTile(), 3, 6);
			via = "LAST RESORT near the company (nothing standable on the route)";
			::logError("Skv.Trail: stop " + _k + " had no standable tile on the route; placed near the company.");
		}
		tile.clear();
		this.m.Marker = this.WeakTableRef(::World.spawnLocation("scripts/entity/world/locations/skv_trail_location", tile.Coords));
		this.m.Marker.onSpawned();
		this.m.Marker.setDiscovered(true);
		this.m.Marker.setAttackable(false);
		this.m.Stop = _k;
		this.dressMarker();
		::World.uncoverFogOfWar(this.m.Marker.getTile().Pos, 500.0);
		::Skv.dbg("Skv.Trail: stop " + _k + " at " + tile.SquareCoords.X + "," + tile.SquareCoords.Y
			+ " (" + T.terrainName(tile.Type) + ", via " + via + ")");
	}

	function stopScreen()
	{
		if (this.m.Stop == 1) return "NoblesCamp";
		if (this.m.Stop == 2) return this.stop2Screen();
		if (this.m.Stop == 3) return this.stop3Screen();
		if (this.m.Stop == 4) return this.caveHas(::Const.Skv.Trail.CaveOgreDead) ? "OgreAfter" : "CaveMouth";

		::logError("Skv.Trail: a marker was reached at stop " + this.m.Stop + ", which has none; no screen.");
		return null;
	}

	function updateObjectives()
	{
		local d = this.destination();
		local deliver = d != null
			? "Deliver the house's ledger to its agent in " + d.getName()
			: "Bring the house's ledger back to " + this.m.Home.getName();
		local now = "Survey a caravan road over the mountains";
		if (this.m.Stop == 1) now = "Head up into the foothills";
		else if (this.m.Stop == 2) now = "Climb to the snow line";
		else if (this.m.Stop == 3) now = "Make for the treeline";
		else if (this.m.Stop == 4) now = "Find the cave";
		this.m.BulletpointsObjectives = this.m.Stop >= 5 ? [deliver] : [now, deliver];
	}

	function resolveSetOut()
	{
		local C = ::Const.Skv.Trail;
		if ((this.m.Lore & C.LoreRolled) != 0) return;
		this.m.Lore = this.m.Lore | C.LoreRolled;

		local before = ::World.Assets.getMedicine();
		::World.Assets.addMedicine(C.KarlaMedicine);
		local got = ::World.Assets.getMedicine() - before;
		local rows = [];
		rows.push(got > 0
			? { id = 1, icon = "ui/icons/asset_medicine.png",
				text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, got) + " Medical Supplies" }
			: { id = 1, icon = "ui/icons/asset_medicine.png", text = "Your medical stores are already full" });

		local orc = ::Skv.Check.wits(this, this.sb(C.LoreBase), C.OrcLoreLeads);
		if (orc.ok)
		{
			this.m.Lore = this.m.Lore | C.LoreOrc;
			this.m.OrcLoreName = this.actorName(orc);
		}
		local snow = ::Skv.Check.wits(this, this.sb(C.LoreBase), C.MountainLeads);
		if (snow.ok)
		{
			this.m.Lore = this.m.Lore | C.LoreSnow;
			this.m.SnowLoreName = this.actorName(snow);
		}
		this.setRows(rows, ::Skv.XP.checks([orc, snow]));
		::Skv.dbg("Skv.Trail: SETTING OUT medicine +" + got + ", orc lore " + (orc.ok ? "PASSED (" + this.m.OrcLoreName + ")" : "failed")
			+ " chance " + orc.chance + ", snow lore " + (snow.ok ? "PASSED (" + this.m.SnowLoreName + ")" : "failed")
			+ " chance " + snow.chance);
	}

	function setOutList()
	{
		local C = ::Const.Skv.Trail;
		local rows = this.rowsKept();
		rows.push(this.goodRow("You carry a bottle of Urglin gin"));
		rows.push(this.goodRow("You carry the house's ledger: the survey stands at " + this.pointsText(this.m.DP)));
		rows.push((this.m.Lore & C.LoreOrc) != 0
			? this.goodRow(this.m.OrcLoreName + " has fought orcs out of those peaks: the Shattered Fang, who keep an oath sworn on their dead")
			: this.badRow("Nobody in the company knows much about the orcs up there"));
		rows.push((this.m.Lore & C.LoreSnow) != 0
			? this.goodRow(this.m.SnowLoreName + " has seen snow like that let go: an edge at the snow line")
			: this.badRow("Nobody in the company has climbed in snow like that"));
		rows.extend(this.rowsXP());
		return rows;
	}

	function rollTalk( _i, _rows )
	{
		local C = ::Const.Skv.Trail;

		local anchor = this.sb(C.TalkBase);
		local r;
		local pass;
		local fail;
		if (_i == C.TalkJasper)
		{
			r = ::Skv.Check.tracking(this, anchor);
			pass = "shows Jasper what his book leaves out, and Jasper writes it in the margin";
			fail = "shows Jasper what his book leaves out; Jasper nods along and takes none of it in";
		}
		else if (_i == C.TalkSarevi)
		{
			r = ::Skv.Check.agility(this, anchor);
			pass = "reties Sarevi's knots with her until she reties every one herself, twice";
			fail = "reties Sarevi's knots with her, and they are still wrong when you give up";
		}
		else if (_i == C.TalkAmyas)
		{
			r = ::Skv.Check.wits(this, anchor, C.SoldierLeads);
			pass = "tells Amyas how high ground kills men, and Amyas stops talking about hunting";
			fail = "tells Amyas how high ground kills men; Amyas has heard all this before, he says";
		}
		else if (_i == C.TalkLeonie)
		{
			r = ::Skv.Check.wits(this, anchor, C.MountainLeads);
			pass = "walks Leonie along the rock and shows her which faces fall, and she comes round, grudgingly";
			fail = "walks Leonie along the rock and shows her which faces fall; she hears it all and believes none of it";
		}
		else
		{
			r = ::Skv.Check.tracking(this, anchor);
			pass = "takes Dacian out to hunt in earnest, and Dacian comes back quieter than he went out";
			fail = "takes Dacian out to hunt in earnest; Dacian comes back with a hare and a worse opinion of you";
		}
		this.m.NobleTalks = this.mark(this.m.NobleTalks, _i, r.ok);
		local who = this.actorName(r) + " ";
		_rows.push(r.ok ? this.goodRow(who + pass) : this.badRow(who + fail));
		::Skv.dbg("Skv.Trail: talk " + _i + " by " + this.actorName(r) + " chance " + r.chance + (r.ok ? " WON" : " not won"));
		return r;
	}

	function resolveTalks()
	{
		local C = ::Const.Skv.Trail;
		local rows = [];
		local results = [];
		foreach (i in [C.TalkJasper, C.TalkSarevi, C.TalkAmyas, C.TalkLeonie, C.TalkDacian])
		{
			if (!this.isDone(this.m.NobleTalks, i)) results.push(this.rollTalk(i, rows));
		}
		if (results.len() == 0) return "NoblesTalk";
		local kept = this.rowsKept();
		kept.extend(rows);
		this.setRows(kept, ::Skv.XP.checks(results));
		::Skv.dbg("Skv.Trail: TALKS rolled " + results.len() + ", won over " + this.talksWon() + " of " + C.TalksNeeded
			+ (this.canGift() ? " (the gift would decide it)" : ""));
		return "NoblesTalk";
	}

	function talksWon() { return this.countPassed(this.m.NobleTalks, 6); }

	function canGift()
	{
		local C = ::Const.Skv.Trail;
		return !this.isDone(this.m.NobleTalks, C.TalkGift)
			&& this.talksWon() == C.TalksNeeded - 1
			&& this.giftSupply() != C.GiftNone;
	}

	function giftRows()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.GiftPaid == C.GiftNone) return [];
		local lose = this.m.GiftPaid == C.GiftTools
			? { id = 1, icon = "ui/icons/asset_supplies.png",
				text = "You lose " + ::MSU.Text.color(::Const.UI.Color.NegativeEventValue, C.GiftAmount) + " Tools and Supplies" }
			: { id = 1, icon = "ui/icons/asset_medicine.png",
				text = "You lose " + ::MSU.Text.color(::Const.UI.Color.NegativeEventValue, C.GiftAmount) + " Medical Supplies" };
		return [lose, this.goodRow("They take the gear, and the point")];
	}

	function giftSupply()
	{
		local n = ::Const.Skv.Trail.GiftAmount;
		if (::World.Assets.getArmorParts() >= n) return ::Const.Skv.Trail.GiftTools;
		if (::World.Assets.getMedicine() >= n) return ::Const.Skv.Trail.GiftMedicine;
		return ::Const.Skv.Trail.GiftNone;
	}

	function resolveGift()
	{
		local C = ::Const.Skv.Trail;
		if (!this.canGift())
		{
			::logError("Skv.Trail: the gift was chosen when it could not be given (done, not one short, or too few supplies); nothing taken.");
			return "NoblesTalk";
		}
		local kind = this.giftSupply();
		if (kind == C.GiftTools) ::World.Assets.addArmorParts(-C.GiftAmount);
		else ::World.Assets.addMedicine(-C.GiftAmount);
		this.m.GiftPaid = kind;
		this.m.NobleTalks = this.mark(this.m.NobleTalks, C.TalkGift, true);
		::Skv.dbg("Skv.Trail: gift paid in " + (kind == C.GiftTools ? "tools" : "medicine") + "; won over " + this.talksWon());
		return this.resolveNobles();
	}

	function resolveNobles()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Nobles != C.NoblesNone) return "NoblesResult";
		if (this.talksWon() >= C.TalksNeeded)
		{
			this.m.Nobles = C.NoblesTurnedBack;
			this.addDP(C.TurnBackPoints, "the nobles turned back, and gave up their maps");
		}
		else
		{
			this.m.Nobles = C.NoblesPressing;
		}
		::Skv.dbg("Skv.Trail: NOBLES " + (this.m.Nobles == C.NoblesTurnedBack ? "TURNED BACK" : "press on")
			+ " (won over " + this.talksWon() + " of " + C.TalksNeeded + ")");
		this.clearRows();
		return "NoblesResult";
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
			local dmg = this.Math.rand(_min, _max);
			local hp = bro.getHitpoints() - dmg;
			if (hp < 1) hp = 1;
			bro.setHitpoints(hp);
			rows.push({ id = 10, icon = "ui/icons/health.png", text = bro.getName() + " loses " + dmg + " health" });
		}
		return rows;
	}

	function animalPerks()
	{
		local C = ::Const.Skv.Trail;
		local p = {};
		p[::Legends.Perk.LegendSummonFalcon] <- C.AnimalPerkFalcon;
		p[::Legends.Perk.LegendDogWhisperer] <- C.AnimalPerkDogWhisperer;
		p[::Legends.Perk.LegendDogHandling] <- C.AnimalPerkDog;
		p[::Legends.Perk.LegendDogMaster] <- C.AnimalPerkDog;
		p[::Legends.Perk.LegendPackleader] <- C.AnimalPerkDog;
		return p;
	}

	function resolveRavens( _mode )
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Ravens != C.RavensNone) return "RavensAfter";
		local rows = [];
		local xp = [];
		if (_mode == 1 && this.m.Gin == C.GinCarried)
		{
			this.m.Gin = C.GinBurned;
			this.m.Ravens = C.RavensGin;
			rows.push(this.badRow("You no longer carry the Urglin gin"));
			::Skv.dbg("Skv.Trail: RAVENS burned off with the gin");
		}
		else if (_mode == 2)
		{

			local r = ::Skv.Check.reflex(this, this.sb(C.TaskBase), 0.5);
			if (r.ok)
			{
				this.m.Ravens = C.RavensFightPass;
				rows.extend(::Skv.Loot.haul(::Skv.Loot.make([C.GemShards])));
				if (rows.len() == 0) ::logError("Skv.Trail: the Gem Shards did not reach the stash - check the path in 87_trail.nut.");
				xp = ::Skv.XP.check(r);
			}
			else
			{
				this.m.Ravens = C.RavensFightFail;
				rows.extend(this.hurtThese(r.rows, C.RavenHurtMin, C.RavenHurtMax));
				rows.extend(this.lossRows(1, "the ravens: a day lost to the flock"));
			}
			::Skv.dbg("Skv.Trail: RAVENS fought through, " + r.passed + "/" + r.total + " kept their eyes, needed " + r.needed
				+ (r.ok ? " PASS" : " FAIL"));
		}
		else if (_mode == 3)
		{

			local r = ::Skv.Check.wits(this, this.sb(C.CalmBase), C.AnimalLeads, this.animalPerks());
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Ravens = C.RavensCalmPass;
				rows.push(this.goodRow(who + " quiets the flock without a bird killed"));
				rows.push(this.goodRow(who + " reads the ground: something heavy raided the nests, from up the mountain"));
				xp = ::Skv.XP.check(r);
			}
			else
			{
				this.m.Ravens = C.RavensCalmFail;
				rows.push(this.badRow(who + " tries to quiet the flock, and it turns on the company"));
				local rf = ::Skv.Check.reflex(this, this.sb(C.TaskBase), 0.5);
				rows.extend(this.hurtThese(rf.rows, C.RavenHurtMin, C.RavenHurtMax));
				rows.extend(this.lossRows(1, "the ravens: the flock turned"));

				this.m.ActorName = who;
			}
			::Skv.dbg("Skv.Trail: RAVENS quieting by " + who + " chance " + r.chance + (r.ok ? " PASS (spared)" : " FAIL (the flock turned, not spared)"));
		}
		else
		{

			::logError("Skv.Trail: resolveRavens(" + _mode + ") with gin=" + this.m.Gin + "; nothing resolved.");
			return "Ravens";
		}
		this.setRows(rows, xp);
		return "RavensAfter";
	}

	function streamTask( _rows, _results, _i, _r, _pass, _fail )
	{
		this.m.StreamTasks = this.mark(this.m.StreamTasks, _i, _r.ok);
		_rows.push(_r.ok ? this.goodRow(_pass) : this.badRow(_fail));
		_results.push(_r);
		::Skv.dbg("Skv.Trail: stream task " + _i + " by " + this.actorName(_r) + " chance " + _r.chance + (_r.ok ? " PASS" : " FAIL"));
		return _r.ok ? 1 : 0;
	}

	function resolveStream()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.StreamTasks != 0) return "StreamSurvey";
		local anchor = this.sb(C.TaskBase);
		local rows = [];
		local results = [];
		local gained = 0;

		local r = ::Skv.Check.tracking(this, anchor);
		gained += this.streamTask(rows, results, C.TaskWildlife, r,
			this.actorName(r) + " notes what comes down to drink, and what hunts what does",
			this.actorName(r) + " watches the water all morning and learns nothing");
		r = ::Skv.Check.wits(this, anchor, C.HerbLeads);
		gained += this.streamTask(rows, results, C.TaskPlants, r,
			this.actorName(r) + " finds the poison growing along the bank before a mule does",
			this.actorName(r) + " can't tell the grazing from the poison");
		r = ::Skv.Check.wits(this, anchor);
		gained += this.streamTask(rows, results, C.TaskChart, r,
			this.actorName(r) + " draws the clearing, the stream and the slopes above it",
			this.actorName(r) + "'s map of the clearing is no use to anyone");
		r = ::Skv.Check.wits(this, anchor, C.WaterLeads);
		gained += this.streamTask(rows, results, C.TaskFord, r,
			this.actorName(r) + " finds where the stream can be waded",
			this.actorName(r) + " finds nowhere to wade that wouldn't drown a mule");

		if (this.isPassed(this.m.StreamTasks, C.TaskFord))
		{
			r = ::Skv.Check.brawn(this, anchor);
			gained += this.streamTask(rows, results, C.TaskFirm, r,
				this.actorName(r) + " and the strong backs roll stones in to firm the ford",
				"The stones will not bed down in that current");
		}
		r = ::Skv.Check.wits(this, anchor, C.BuildLeads);
		gained += this.streamTask(rows, results, C.TaskSite, r,
			this.actorName(r) + " finds where a bridge would stand",
			this.actorName(r) + " finds nowhere a bridge would stand");

		if (gained > 0) this.addDP(gained, "the stream survey");
		this.setRows(rows, ::Skv.XP.checks(results));
		::Skv.dbg("Skv.Trail: STREAM " + gained + " task(s) passed, survey now " + this.m.DP);
		return "StreamSurvey";
	}

	function streamPoints() { return this.countPassed(this.m.StreamTasks, 7); }

	function canBuildBridge()
	{
		local C = ::Const.Skv.Trail;
		return this.isPassed(this.m.StreamTasks, C.TaskSite)
			&& !this.isDone(this.m.StreamTasks, C.TaskBridge)
			&& ::World.Assets.getArmorParts() >= C.BridgeTools;
	}

	function resolveBridge()
	{
		local C = ::Const.Skv.Trail;
		if (!this.canBuildBridge())
		{
			::Skv.dbg("Skv.Trail: the bridge was asked for and cannot be built (site, done, or tools); nothing taken.");
			return "StreamSurvey";
		}
		::World.Assets.addArmorParts(-C.BridgeTools);
		local r = ::Skv.Check.brawn(this, this.sb(C.TaskBase));
		this.m.StreamTasks = this.mark(this.m.StreamTasks, C.TaskBridge, r.ok);
		if (r.ok) this.addDP(1, "the bridge holds");
		local rows = [
			{ id = 1, icon = "ui/icons/asset_supplies.png",
				text = "You lose " + ::MSU.Text.color(::Const.UI.Color.NegativeEventValue, C.BridgeTools) + " Tools and Supplies" },
			r.ok ? this.goodRow("The bridge holds a man's weight, and will hold a mule's")
				: this.badRow("The bridge goes down the stream with the first man on it")
		];
		this.addAction(rows, ::Skv.XP.check(r));
		::Skv.dbg("Skv.Trail: BRIDGE by " + this.actorName(r) + " chance " + r.chance + (r.ok ? " HOLDS" : " washed away"));
		return "StreamSurvey";
	}

	function rollTravel( _i )
	{
		local C = ::Const.Skv.Trail;
		if (this.travelAt(_i) != C.TravelNotRolled) return [];
		local r = ::Skv.Check.brawn(this, this.sb(C.TravelBase), 0.5);
		local rate = r.total > 0 ? r.passed * 1.0 / r.total : 0.0;
		local v = C.TravelFair;
		if (rate >= C.TravelGood) v = C.TravelGoodTime;
		else if (rate < C.TravelBad) v = C.TravelLost;
		this.setTravel(_i, v);
		local texts = [
			["The company makes good time up through the pines", "The company keeps a fair pace through the pines",
				"The company loses its way twice in the pines"],
			["The company finds a quick way down off the crag", "The company picks its way down off the crag",
				"The company takes a wrong gully down off the crag and has to climb back out"],
			["The company makes good time along the valley floor", "The company keeps a steady pace along the valley floor",
				"The company blunders into a bog in the valley and loses half a day"]
		][_i];
		local rows = [];
		if (v == C.TravelGoodTime)
		{
			rows.push(this.goodRow(texts[0]));
			rows.push(this.pointsRow(this.addDP(1, "travel ladder " + _i + ": good time")));
		}
		else if (v == C.TravelLost)
		{
			rows.push(this.badRow(texts[2]));
			rows.extend(this.lossRows(1, "travel ladder " + _i + ": lost time"));
		}
		else rows.push(this.goodRow(texts[1]));
		::Skv.dbg("Skv.Trail: TRAVEL " + _i + " " + r.passed + "/" + r.total + " (rate " + rate + ", rungs "
			+ C.TravelBad + "/" + C.TravelGood + ") -> " + (v == C.TravelGoodTime ? "GOOD (+1)" : (v == C.TravelLost ? "LOST (-1)" : "fair (0)")));
		return rows;
	}

	function leaveStop1()
	{
		this.clearRows();
		this.setRows(this.rollTravel(0), []);
		this.spawnStop(2);
		this.updateObjectives();
		::World.Contracts.updateActiveContract();
		return 0;
	}

	function stop2Screen()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.ClimbMode == 0) return "Scree";
		if (this.fiveOnTheMountain()) return "Buried";
		local met = this.m.Bark & C.BarkMetMask;
		if (met == 0) return "Wilbert";
		return "Cabin";
	}

	function fiveOnTheMountain()
	{
		local C = ::Const.Skv.Trail;
		return this.m.Nobles == C.NoblesPressing || this.m.Nobles == C.NoblesSabotaged;
	}

	function travel1Rows()
	{
		local kept = this.rowsKept();
		if (kept.len() > 0) return kept;
		local C = ::Const.Skv.Trail;
		local v = this.travelAt(0);
		::logInfo("Skv.Trail: the snow line's travel rows were not kept (a pre-1.3.11 save); derived from the ladder.");
		if (v == C.TravelGoodTime) return [this.goodRow("The company makes good time up through the pines"), this.pointsRow(1)];
		if (v == C.TravelLost) return [this.badRow("The company loses its way twice in the pines"), this.pointsRow(-1)];
		if (v == C.TravelFair) return [this.goodRow("The company keeps a fair pace through the pines")];
		::logError("Skv.Trail: travel ladder 1 was never rolled, and the snow line has no travel rows.");
		return [];
	}

	function namesText( _names )
	{
		local out = "";
		foreach (i, n in _names)
		{
			if (i > 0) out = out + (i == _names.len() - 1 ? " and " : ", ");
			out = out + n;
		}
		return out;
	}

	function hurtAll( _bros, _dmg )
	{
		local names = [];
		foreach (bro in _bros)
		{
			if (bro == null || !bro.isAlive()) continue;
			local hp = bro.getHitpoints() - _dmg;
			if (hp < 1) hp = 1;
			bro.setHitpoints(hp);
			names.push(bro.getName());
		}
		return names;
	}

	function resolveClimb( _mode )
	{
		local C = ::Const.Skv.Trail;
		if (this.m.ClimbMode != 0) return "Avalanche";
		this.m.ClimbMode = _mode;
		local roped = _mode == C.ClimbRoped;
		local anchor = this.sb(C.ClimbBase) + ((this.m.Lore & C.LoreSnow) != 0 ? C.SnowEdge : 0);
		local rows = [];
		local held = null;
		local slides = 0;
		while (true)
		{
			local r = ::Skv.Check.agility(this, anchor, C.ClimbNeed);
			if (r.ok)
			{
				rows.push(this.goodRow("The slope holds"));
				held = r;
				break;
			}
			slides++;
			rows.push(this.badRow("The snow goes, and takes " + (roped ? "the whole company" : "the men on the slope") + " with it"));
			local hit = [];
			if (r.rows != null)
			{
				foreach (cr in r.rows)
				{
					if (roped || !cr.ok) hit.push(cr.bro);
				}
			}
			local dmg = this.Math.rand(C.SlideHurtMin, C.SlideHurtMax);
			local names = this.hurtAll(hit, dmg);
			if (names.len() > 0)
			{
				rows.push({ id = 10, icon = "ui/icons/health.png",
					text = roped ? "Every brother loses " + dmg + " health"
						: this.namesText(names) + (names.len() == 1 ? " loses " : " lose ") + dmg + " health" });
			}
			rows.extend(this.lossRows(1, "the climb: slide " + slides));
			::Skv.dbg("Skv.Trail: SLIDE " + slides + " (" + r.passed + "/" + r.total + " kept their feet), "
				+ names.len() + " hurt for " + dmg + (roped ? ", roped" : ", the men on the slope"));
			if (slides >= C.MaxSlides) break;
		}
		this.m.Slides = slides;
		if (slides == 0)
		{
			local clean = roped ? C.CleanRoped : C.CleanParties;
			this.addDP(clean, "the climb: a clean crossing, " + (roped ? "roped" : "a few at a time"));
			rows.push(this.pointsRow(clean));
		}
		this.setRows(rows, held != null ? ::Skv.XP.check(held) : []);
		::Skv.dbg("Skv.Trail: CLIMB " + (roped ? "roped" : "a few at a time") + ", " + slides + " slide(s)"
			+ ((this.m.Lore & C.LoreSnow) != 0 ? ", with the snow edge" : "") + ", survey now " + this.m.DP);
		return "Avalanche";
	}

	function afterPass()
	{
		this.clearRows();
		return this.fiveOnTheMountain() ? "Buried" : "Wilbert";
	}

	function resolveBuried( _dig )
	{
		local C = ::Const.Skv.Trail;
		if (!this.fiveOnTheMountain()) return "Wilbert";

		local rows = [];
		if (_dig)
		{
			this.m.Nobles = C.NoblesDugOut;
			rows.extend(this.lossRows(C.DigPoints, "digging the five out"));
			rows.push(this.goodRow("The five come out alive, and will go home"));
		}
		else
		{
			this.m.Nobles = C.NoblesLost;
			::World.Assets.addMoralReputation(-C.LeaveMoral);
			rows.push(this.moralRow(-C.LeaveMoral, "You left five people under the snow"));
			rows.push(this.badRow("The five are lost"));
			::Skv.dbg("Skv.Trail: the five LEFT under the snow, moral -" + C.LeaveMoral);
		}
		this.setRows(rows, []);
		return "Wilbert";
	}

	function ravensSpared()
	{
		local C = ::Const.Skv.Trail;
		return this.m.Ravens == C.RavensCalmPass;
	}

	function enterCabin( _met )
	{
		local C = ::Const.Skv.Trail;
		if ((this.m.Bark & C.BarkMetMask) != 0) return "Cabin";
		this.m.Bark = this.m.Bark | _met;
		if (this.ravensSpared())
		{
			this.clearRows();
			return "Cabin";
		}
		local r = ::Skv.Check.charm(this, this.sb(C.BarkCharmBase));
		this.m.Bark = this.m.Bark | C.BarkCharmRolled;
		this.m.BarkPaid = r.ok ? C.BarkPriceCharmed : C.BarkPrice;
		local who = this.actorName(r);
		this.setRows([r.ok
			? this.goodRow(who + " talks Bark down to " + C.BarkPriceCharmed + " Crowns for tending the wounded")
			: this.badRow(who + " haggles, but Bark will not tend the wounded for less than " + C.BarkPrice + " Crowns")],
			::Skv.XP.check(r));
		::Skv.dbg("Skv.Trail: BARK's price " + this.m.BarkPaid + " (charm by " + who + " chance " + r.chance + (r.ok ? " PASS" : " FAIL") + ")");
		return "Cabin";
	}

	function driveDogOff()
	{
		local C = ::Const.Skv.Trail;
		if ((this.m.Bark & C.BarkMetMask) == 0) this.m.Bark = this.m.Bark | C.BarkDrivenOff;
		::Skv.dbg("Skv.Trail: the dog driven off; no cabin");
		return this.leaveStop2();
	}

	function resolveCabin( _how )
	{
		local C = ::Const.Skv.Trail;
		if ((this.m.Bark & C.BarkVisited) != 0) return "Cabin";
		if (_how == C.BarkHealCrowns)
		{
			if (this.m.BarkPaid <= 0 || ::World.Assets.getMoney() < this.m.BarkPaid)
			{
				::logError("Skv.Trail: Bark's crowns were chosen with too little money (" + this.m.BarkPaid + " asked); nothing taken.");
				return "Cabin";
			}
			::World.Assets.addMoney(-this.m.BarkPaid);
		}
		else if (_how == C.BarkHealGin)
		{
			if (this.m.Gin != C.GinCarried)
			{
				::logError("Skv.Trail: the gin was offered to Bark without the gin; nothing given.");
				return "Cabin";
			}
			this.m.Gin = C.GinToBark;
		}
		if (_how != C.BarkHealSlept)
		{
			local n = 0;
			foreach (bro in ::World.getPlayerRoster().getAll())
			{
				if (bro == null || !bro.isAlive()) continue;
				bro.setHitpoints(bro.getHitpointsMax());
				n++;
			}
			::Skv.dbg("Skv.Trail: BARK tended " + n + " brothers (health only), paid by " + _how);
		}
		this.m.Bark = this.m.Bark | (_how << C.BarkHealShift) | C.BarkVisited;
		this.clearRows();
		return "Cabin";
	}

	function cabinRows()
	{
		local C = ::Const.Skv.Trail;
		local how = (this.m.Bark >> C.BarkHealShift) & 3;
		local rows = [];
		if (how != C.BarkHealSlept)
			rows.push({ id = 10, icon = "ui/icons/health.png", text = "Every brother is restored to full health (injuries still need time)" });
		if (how == C.BarkHealGin) rows.push(this.badRow("You no longer carry the Urglin gin"));
		if (how == C.BarkHealCrowns)
			rows.push({ id = 1, icon = "ui/icons/asset_money.png",
				text = "You pay " + ::MSU.Text.color(::Const.UI.Color.NegativeEventValue, this.m.BarkPaid) + " Crowns" });
		rows.push(this.goodRow("Bark marks the orc camp in the ledger"));
		if (this.m.Nobles == C.NoblesDugOut) rows.push(this.goodRow("The five will start for home in the morning, on Bark's sled"));
		return rows;
	}

	function leaveStop2()
	{
		this.clearRows();
		this.spawnStop(3);
		this.updateObjectives();
		::World.Contracts.updateActiveContract();
		return 0;
	}

	function stop3Screen()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Goats == 0) return "Cliff";
		if (this.m.VantageTasks == 0) return "Herd";
		if (this.travelAt(1) == C.TravelNotRolled) return "View";
		if (this.m.Odvar == C.OdvarNone || this.m.Odvar == C.OdvarFight) return "Odvar";
		if (this.travelAt(2) == C.TravelNotRolled) return "OdvarAfter";
		if (this.m.Orcs == C.OrcsNone) return "OrcCamp";
		if (this.m.Orcs == C.OrcsPeace || this.m.Orcs == C.OrcsRefused) return "Parley";
		return "OrcsAfter";
	}

	function goatsHave( _bit ) { return (this.m.Goats & _bit) != 0; }

	function resolveCliff( _quiet )
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Goats != 0) return "Herd";
		local rows = [];
		local results = [];
		local goats = _quiet ? C.GoatsQuiet : C.GoatsPegs;
		if (_quiet)
		{
			local r = ::Skv.Check.agility(this, this.sb(C.QuietClimbBase));
			local who = this.actorName(r);
			if (r.ok)
			{
				rows.push(this.goodRow(who + " goes up without a sound and drops the rope"));
				results.push(r);
			}
			else
			{
				local dmg = this.Math.rand(C.FallHurtMin, C.FallHurtMax);
				if (r.actor != null) this.hurtAll([r.actor], dmg);
				rows.push(this.badRow(who + " comes off halfway, lands in the bushes and loses " + dmg + " health, and the whole herd hears it"));
				goats = goats | C.GoatsFell | C.GoatsAlerted;
			}
		}
		else
		{
			rows.push(this.badRow("The pegs go in, and every goat on the rim is looking your way"));
			goats = goats | C.GoatsAlerted;
		}
		local need = (goats & C.GoatsAlerted) != 0 ? C.GoatsNeedAlert : C.GoatsNeedCalm;
		local won = 0;
		local lost = 0;
		while (won < need && lost < need)
		{
			local r = ::Skv.Check.wits(this, this.sb(C.GoatBase), C.AnimalLeads, this.animalPerks());
			if (r.ok)
			{
				won++;
				rows.push(this.goodRow(this.actorName(r) + " keeps low and still, and a goat goes back to its grazing"));
				results.push(r);
			}
			else
			{
				lost++;
				rows.push(this.badRow("A goat stamps and snorts, and the rest bunch up"));
			}
		}
		if (won >= need)
		{
			goats = goats | C.GoatsCalmed;
		}
		else
		{
			goats = goats | C.GoatsScattered;

			local rf = ::Skv.Check.reflex(this, this.sb(C.TaskBase), 0.5);
			local hit = [];
			if (rf.rows != null) foreach (cr in rf.rows) if (!cr.ok) hit.push(cr.bro);
			local dmg = this.Math.rand(C.GoatHurtMin, C.GoatHurtMax);
			local names = this.hurtAll(hit, dmg);
			if (names.len() > 0)
				rows.push({ id = 10, icon = "ui/icons/health.png",
					text = this.namesText(names) + (names.len() == 1 ? " loses " : " lose ") + dmg + " health" });
			rows.push(this.badRow("The herd is gone"));
		}
		this.m.Goats = goats;
		this.setRows(rows, ::Skv.XP.checks(results));
		::Skv.dbg("Skv.Trail: THE CRAG " + (_quiet ? "quietly" : "with pegs") + ((goats & C.GoatsFell) != 0 ? ", the climber FELL" : "")
			+ ", the herd " + ((goats & C.GoatsCalmed) != 0 ? "CALMED" : "SCATTERED") + " (" + won + " to " + lost + ", needed " + need + ")");
		return "Herd";
	}

	function vantageTask( _rows, _results, _i, _r, _pass, _fail )
	{
		this.m.VantageTasks = this.mark(this.m.VantageTasks, _i, _r.ok);
		_rows.push(_r.ok ? this.goodRow(_pass) : this.badRow(_fail));
		_results.push(_r);
		::Skv.dbg("Skv.Trail: view task " + _i + " by " + this.actorName(_r) + " chance " + _r.chance + (_r.ok ? " PASS" : " FAIL"));
		return _r.ok ? 1 : 0;
	}

	function resolveView()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.VantageTasks != 0) return "View";
		local anchor = this.sb(C.TaskBase);
		local rows = [];
		local results = [];
		local gained = 0;
		local r;
		if (this.goatsHave(C.GoatsCalmed))
		{
			r = ::Skv.Check.tracking(this, anchor);
			gained += this.vantageTask(rows, results, C.VGoats, r,
				this.actorName(r) + " watches where the goats go: they know every safe ledge on this mountain, and now so does the ledger",
				this.actorName(r) + " watches the goats all afternoon and learns nothing a mule could use");
		}
		r = ::Skv.Check.wits(this, anchor);
		gained += this.vantageTask(rows, results, C.VChart, r,
			this.actorName(r) + " draws the valley from the crag to the far ridge",
			this.actorName(r) + "'s drawing of the valley could be any valley");
		r = ::Skv.Check.perception(this, anchor);
		gained += this.vantageTask(rows, results, C.VGround, r,
			this.actorName(r) + " marks the good climbs and where the streams run",
			this.actorName(r) + " cannot tell a stream from a shadow at this distance");
		r = ::Skv.Check.wits(this, anchor, C.HerbLeads);
		gained += this.vantageTask(rows, results, C.VGrazing, r,
			this.actorName(r) + " picks out the grazing, and the moss that stops bleeding",
			this.actorName(r) + " cannot tell good grass from bad from up here");
		r = ::Skv.Check.wits(this, anchor, C.MountainLeads);
		gained += this.vantageTask(rows, results, C.VMelt, r,
			this.actorName(r) + " spots where the snowmelt will come down in spring, right across the obvious path",
			"Nobody notices the snowmelt channel until it is too late to matter");
		r = ::Skv.Check.perception(this, anchor);
		gained += this.vantageTask(rows, results, C.VShelter, r,
			this.actorName(r) + " finds a dry overhang at the foot of the crag where a caravan could sleep",
			this.actorName(r) + " finds nowhere to sleep that the wind does not already own");

		if (this.isPassed(this.m.VantageTasks, C.VShelter))
		{
			r = ::Skv.Check.brawn(this, anchor);
			gained += this.vantageTask(rows, results, C.VClear, r,
				"The company clears the overhang of rubble and deadfall",
				"The rubble under the overhang will not shift");
		}
		if (gained > 0) this.addDP(gained, "the view survey");
		this.setRows(rows, ::Skv.XP.checks(results));
		::Skv.dbg("Skv.Trail: THE VIEW " + gained + " task(s) passed, survey now " + this.m.DP);
		return "View";
	}

	function vantagePoints() { return this.countPassed(this.m.VantageTasks, 7); }

	function leaveView()
	{
		if (this.travelAt(1) == ::Const.Skv.Trail.TravelNotRolled)
		{
			this.clearRows();
			this.setRows(this.rollTravel(1), []);
		}
		return "Odvar";
	}

	function resolveBargain()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Odvar != C.OdvarNone) return "OdvarAfter";
		this.m.Odvar = C.OdvarBargain;
		::World.Assets.addMoralReputation(-C.BargainMoral);
		local rows = [this.moralRow(-C.BargainMoral, "You sold travellers to a wolf")];
		rows.extend(this.lossRows(C.BargainPoints, "Odvar's bargain", "a road with a man-eater on it is a worse road"));
		this.setRows(rows, []);
		::Skv.dbg("Skv.Trail: ODVAR's bargain struck, moral -" + C.BargainMoral);
		return "OdvarAfter";
	}

	function resolveOdvarFight( _won )
	{
		local C = ::Const.Skv.Trail;
		if (_won)
		{
			this.m.Odvar = C.OdvarWon;
			local paths = [];
			for (local i = 0; i < C.OdvarPotions; i++) paths.push(C.PotionScript);
			local rows = ::Skv.Loot.haul(::Skv.Loot.make(paths));
			if (rows.len() == 0) ::logError("Skv.Trail: the traveller's potions did not reach the stash - check PotionScript.");
			this.setRows(rows, []);
			::Skv.dbg("Skv.Trail: ODVAR is dead; " + C.OdvarPotions + " potions from the traveller's pack");
		}
		else
		{
			this.m.Odvar = C.OdvarFled;
			this.setRows(this.lossRows(C.OdvarFledPoints, "fled from Odvar",
				"the road runs past a man-eater the company could not kill"), []);
			::Skv.dbg("Skv.Trail: FLED from Odvar; the report will cap the pay at poor (stage 4)");
		}
	}

	function leaveOdvar()
	{
		if (this.travelAt(2) == ::Const.Skv.Trail.TravelNotRolled)
		{
			this.clearRows();
			this.setRows(this.rollTravel(2), []);
		}
		return "OrcCamp";
	}

	function resolvePrep( _gin )
	{
		local C = ::Const.Skv.Trail;
		if (_gin)
		{
			if (this.m.Gin != C.GinCarried || (this.m.CampPrep & C.PrepGin) != 0) return "OrcCamp";
			this.m.Gin = C.GinToGrakcha;
			this.m.CampPrep = this.m.CampPrep | C.PrepGin;
			this.addAction([this.badRow("You no longer carry the Urglin gin"),
				this.goodRow("Grakcha weighs the bottle in her hand, and some of the chill goes out of her")], []);
			::Skv.dbg("Skv.Trail: the gin given to Grakcha");
			return "OrcCamp";
		}
		if ((this.m.CampPrep & C.PrepDrink) != 0) return "OrcCamp";
		local r = ::Skv.Check.brawn(this, this.sb(C.DrinkBase));
		local who = this.actorName(r);
		this.m.CampPrep = this.m.CampPrep | C.PrepDrink | (r.ok ? C.PrepDrinkWon : 0);
		this.addAction([r.ok
			? this.goodRow(who + " is still upright when the third orc goes under, and the camp roars")
			: this.badRow(who + " goes under the table first, and the orcs are delighted, if not impressed")],
			::Skv.XP.check(r));
		::Skv.dbg("Skv.Trail: the drinking bout, " + who + " chance " + r.chance + (r.ok ? " WON" : " lost"));
		return "OrcCamp";
	}

	function parleyBase()
	{
		local C = ::Const.Skv.Trail;
		local b = this.sb(C.ParleyBase);
		if ((this.m.CampPrep & C.PrepGin) != 0) b += C.ParleyBonus;
		if ((this.m.CampPrep & C.PrepDrinkWon) != 0) b += C.ParleyBonus;
		if ((this.m.Lore & C.LoreOrc) != 0) b += C.ParleyBonus;
		return b;
	}

	function orcLoot()
	{
		local rows = ::Skv.Loot.haul(::Skv.Loot.make(::Const.Skv.Trail.OrcLoot));
		if (rows.len() == 0) ::logError("Skv.Trail: the orcs' gear did not reach the stash - check OrcLoot.");
		return rows;
	}

	function resolveParley()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Orcs != C.OrcsNone) return "Parley";
		local anchor = this.parleyBase();
		local r = ::Skv.Check.charm(this, anchor);
		local who = this.actorName(r);
		if (r.ok)
		{
			this.m.Orcs = C.OrcsPeace;
			this.m.Cave = this.m.Cave | C.CaveKnown;
			local rows = [this.pointsRow(this.addDP(C.OrcsWinPoints, "the orcs' oath"))];
			rows.extend(this.orcLoot());
			rows.push(this.goodRow("Grakcha shows you the way to the cave"));
			this.setRows(rows, ::Skv.XP.check(r));
		}
		else
		{
			this.m.Orcs = C.OrcsRefused;
			this.setRows([this.badRow(who + " puts the road to Grakcha, and she will not have it")], []);
		}
		::Skv.dbg("Skv.Trail: THE PARLEY by " + who + " base " + anchor + " chance " + r.chance + (r.ok ? " WON (peace)" : " REFUSED (fight 2)"));
		return "Parley";
	}

	function resolveOrcFight( _won )
	{
		local C = ::Const.Skv.Trail;
		local rows = [];
		local xp = [];
		if (_won)
		{
			this.m.Orcs = C.OrcsWon;
			this.m.Cave = this.m.Cave | C.CaveKnown;
			rows.push(this.pointsRow(this.addDP(C.OrcsWinPoints, "the orcs beaten")));
			rows.extend(this.orcLoot());
			rows.push(this.goodRow("You find the way to the cave"));
		}
		else
		{
			this.m.Orcs = C.OrcsFled;
			rows.extend(this.lossRows(C.OrcsFledPoints, "fled from the orcs",
				"an orc band with sellsword blood on its axes sits across the road"));
			local r = ::Skv.Check.tracking(this, this.sb(C.TaskBase));
			local who = this.actorName(r);
			if (r.ok)
			{
				this.m.Cave = this.m.Cave | C.CaveKnown;
				rows.push(this.goodRow(who + " finds the orcs' old trail by morning: it runs up the valley to a cave"));
				xp = ::Skv.XP.check(r);
			}
			else rows.push(this.badRow(who + " casts about for the orcs' old trail and finds only their new ones"));
			::Skv.dbg("Skv.Trail: FLED from the orcs; the cave " + (r.ok ? "FOUND" : "NOT found") + " (" + who + " chance " + r.chance
				+ "); the report will withhold the bonus (stage 4)");
		}
		this.setRows(rows, xp);
	}

	function leaveStop3()
	{
		local C = ::Const.Skv.Trail;
		if ((this.m.Cave & C.CaveKnown) == 0)
		{
			::Skv.dbg("Skv.Trail: the cave was never found; the survey goes straight to the destination.");
			return this.goDestination();
		}
		this.clearRows();
		this.spawnStop(4);
		this.updateObjectives();
		::World.Contracts.updateActiveContract();
		return 0;
	}

	function caveHas( _bit ) { return (this.m.Cave & _bit) != 0; }

	function moneyRow( _n, _suffix = "" )
	{
		return { id = 1, icon = "ui/icons/asset_money.png",
			text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _n) + " Crowns" + _suffix };
	}

	function resolveEntrance()
	{
		local C = ::Const.Skv.Trail;
		if (this.caveHas(C.CaveEntrance)) return "CaveMouth";
		this.m.Cave = this.m.Cave | C.CaveEntrance;
		local r = ::Skv.Check.perception(this, this.sb(C.SearchBase));
		local who = this.actorName(r);
		local rows = [];
		if (r.ok)
		{
			rows.push(this.goodRow(who + " turns up a carved jade brooch in the wreckage"));
			local got = ::Skv.Loot.haul(::Skv.Loot.make([C.JadeBrooch]));
			if (got.len() == 0) ::logError("Skv.Trail: the jade brooch did not reach the stash - check JadeBrooch.");
			rows.extend(got);
		}
		else rows.push(this.badRow(who + " turns over broken shelving and finds only more of it"));
		this.addAction(rows, ::Skv.XP.check(r));
		::Skv.dbg("Skv.Trail: the cave's ENTRANCE searched by " + who + " chance " + r.chance + (r.ok ? " FOUND the brooch" : " nothing"));
		return "CaveMouth";
	}

	function resolveDeeper()
	{
		local C = ::Const.Skv.Trail;
		if (this.caveHas(C.CaveDeeper)) return "CaveMouth";
		this.m.Cave = this.m.Cave | C.CaveDeeper;
		local r = ::Skv.Check.stealth(this, this.sb(C.StenchBase), C.StenchNeed);
		local rows = [];
		if (r.ok) rows.push(this.goodRow("The company holds its breath, and its stomach, all the way through"));
		else
		{
			this.m.Cave = this.m.Cave | C.CaveAlerted;
			rows.push(this.badRow(this.actorName(r) + " loses the fight with the stench, loudly, and somewhere deeper in, the chewing stops"));
		}
		this.addAction(rows, ::Skv.XP.check(r));
		::Skv.dbg("Skv.Trail: THE STENCH " + r.passed + "/" + r.total + " held, needed " + r.needed
			+ (r.ok ? " PASS, the giant unaware" : " FAIL (" + this.actorName(r) + "), the giant ALERTED"));
		return "CaveMouth";
	}

	function resolveBedding()
	{
		local C = ::Const.Skv.Trail;
		if (this.caveHas(C.CaveBedding)) return "CaveMouth";
		this.m.Cave = this.m.Cave | C.CaveBedding;
		local r = ::Skv.Check.perception(this, this.sb(C.SearchBase));
		local who = this.actorName(r);
		local rows = [];
		local n = 0;
		if (r.ok)
		{
			n = ::Math.rand(C.PurseMin, C.PurseMax);
			::World.Assets.addMoney(n);
			rows.push(this.goodRow(who + " digs through the filthy blankets and comes up with a purse of mixed coin"));
			rows.push(this.moneyRow(n));
		}
		else rows.push(this.badRow(who + " finds fleas, and nothing else"));
		this.addAction(rows, ::Skv.XP.check(r));
		::Skv.dbg("Skv.Trail: the BEDDING searched by " + who + " chance " + r.chance + (r.ok ? " FOUND " + n + " crowns" : " nothing"));
		return "CaveMouth";
	}

	function leaveCave()
	{
		local C = ::Const.Skv.Trail;
		if (!this.caveHas(C.CaveOgreDead))
		{
			this.m.Cave = this.m.Cave | C.CaveLeft;
			::Skv.dbg("Skv.Trail: the cave LEFT, the giant alive"
				+ (this.m.Orcs == C.OrcsPeace ? "; the oath and the feast forfeit" : "; its points and loot forgone"));
		}
		return this.goDestination();
	}

	function resolveOgreFight( _won )
	{
		local C = ::Const.Skv.Trail;
		if (_won)
		{
			this.m.Cave = this.m.Cave | C.CaveOgreDead;
			local rows = [this.pointsRow(this.addDP(C.OgreWinPoints, "the giant killed"))];
			local got = ::Skv.Loot.haul(::Skv.Loot.make(C.HeapLoot));
			if (got.len() == 0) ::logError("Skv.Trail: the heap's loot did not reach the stash - check HeapLoot.");
			rows.extend(got);
			if (this.m.Orcs == C.OrcsPeace)
				rows.push(this.goodRow("Grakcha swears the oath: the Shattered Fang will let the carts pass"));
			this.setRows(rows, []);
			::Skv.dbg("Skv.Trail: the GIANT is dead" + (this.m.Orcs == C.OrcsPeace ? "; Grakcha's oath sworn" : ""));
		}
		else
		{

			this.m.Cave = this.m.Cave | C.CaveFled | C.CaveAlerted;
			this.setRows([this.badRow("The company falls back out of the cave, and the giant does not follow")], []);
			::Skv.dbg("Skv.Trail: FLED from the giant; the cave re-opens, the giant alerted");
		}
	}

	function ogreBudget()
	{
		local C = ::Const.Skv.Trail;
		return C.OgreBase * this.getDifficultyMult() * this.getScaledDifficultyMult();
	}
	function ogreIsChampion() { return this.ogreBudget() >= ::Const.Skv.Trail.OgreChampionBudget; }

	function lairBudget()
	{
		return this.ogreBudget() - ::Const.Skv.Trail.GiantCharge;
	}
	function lairHasGuards() { return this.lairBudget() >= ::Const.Skv.Trail.LairGuardMin; }

	function onOgrePlaced( _e, _tag )
	{
		if (_e == null) { ::logError("Skv.Trail: the giant placed as null"); return; }
		local C = ::Const.Skv.Trail;
		local init = "stock (alerted)";
		if (!this.caveHas(C.CaveAlerted))
		{
			try
			{
				local b = _e.getBaseProperties();
				local i0 = b.Initiative;
				b.Initiative = ::Math.floor(i0 * C.OgreSurpriseInit);
				init = i0 + " -> " + b.Initiative + " (caught eating)";
				_e.getSkills().update();
			}
			catch (e) { ::logError("Skv.Trail: could not slow the unalerted giant (it fights ready): " + e); init = "FAILED"; }
		}
		local champ = false;
		if (this.ogreIsChampion())
		{
			try
			{
				champ = _e.makeMiniboss();
				_e.getSkills().update();
			}
			catch (e) { ::logError("Skv.Trail: makeMiniboss threw on the giant: " + e); }
		}
		try { _e.setHitpoints(_e.getHitpointsMax()); }
		catch (e) { ::logError("Skv.Trail: could not fill the giant's HP: " + e); }
		::Skv.dbg("Skv.Trail: the GIANT placed, champion=" + champ + " (raw budget " + this.ogreBudget()
			+ (this.ogreIsChampion() ? " >= " : " < ") + C.OgreChampionBudget + "), initiative " + init
			+ ", HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax());
	}

	function onLairGuardPlaced( _e, _tag )
	{
		if (_e == null) { ::logError("Skv.Trail: a hyena placed as null"); return; }
		local C = ::Const.Skv.Trail;
		if (this.caveHas(C.CaveAlerted)) return;
		try
		{
			local b = _e.getBaseProperties();
			local i0 = b.Initiative;
			b.Initiative = ::Math.floor(i0 * C.OgreSurpriseInit);
			_e.getSkills().update();
			::Skv.dbg("Skv.Trail: " + _e.getName() + " placed, initiative " + i0 + " -> " + b.Initiative + " (caught eating)");
		}
		catch (e) { ::logError("Skv.Trail: could not slow an unalerted hyena (it fights ready): " + e); }
	}

	function destTarget()
	{
		local d = this.destination();
		if (d != null) return d;
		if (this.m.Home == null || this.m.Home.isNull()) return null;
		return this.m.Home;
	}

	function showDestRing( _on )
	{
		local t = this.destTarget();
		if (t == null) return;
		try { t.getSprite("selection").Visible = _on; }
		catch (e) { ::logError("Skv.Trail: the destination's selection ring - " + e); }
	}

	function goDestination()
	{
		this.killMarker();
		this.clearRows();
		this.m.Stop = 5;
		this.showDestRing(true);
		this.updateObjectives();
		::World.Contracts.updateActiveContract();
		local t = this.destTarget();

		::Skv.dbg("Skv.Trail: ON TO THE DESTINATION: " + (t == null ? "NONE (no far town, no home)"
			: t.getName() + (this.destination() != null ? " (the far town, Jasikah Marten)" : " (home, Karla)")));
		return 0;
	}

	function isAtDestination()
	{
		local t = this.destTarget();
		if (t == null) return false;
		if (this.isPlayerAt(t)) return true;
		try
		{
			local cur = ::World.State.getCurrentTown();
			if (cur != null && cur.getID() == t.getID()) return true;
		}
		catch (e) { ::Skv.dbg("Skv.Trail: getCurrentTown threw - " + e); }
		return false;
	}

	function band()
	{
		local C = ::Const.Skv.Trail;
		local raw = this.m.DP < C.PointsFloor ? C.BandFailed
			: (this.m.DP < C.PointsFull ? C.BandPoor : (this.m.DP < C.PointsBonus ? C.BandFull : C.BandBonus));
		local b = raw;
		local capOdvar = false;
		local capOrcs = false;
		if (this.m.Odvar == C.OdvarFled && b > C.BandPoor) { b = C.BandPoor; capOdvar = true; }
		if (this.m.Orcs == C.OrcsFled && b > C.BandFull) { b = C.BandFull; capOrcs = true; }
		return { Band = b, Raw = raw, CapOdvar = capOdvar, CapOrcs = capOrcs };
	}

	function feeFor( _band )
	{
		local C = ::Const.Skv.Trail;
		local full = this.m.Payment.getOnCompletion();
		if (_band == C.BandFailed) return 0;
		if (_band == C.BandPoor) return ::Math.floor(full * C.PoorPayMult);
		return ::Math.floor(full);
	}
	function bonusFor( _band )
	{
		local C = ::Const.Skv.Trail;
		if (_band != C.BandBonus) return 0;
		return ::Math.floor(this.m.Payment.getOnCompletion() * (C.BonusPayMult - 1.0));
	}

	function noblesLived()
	{
		local C = ::Const.Skv.Trail;
		return this.m.Nobles == C.NoblesTurnedBack || this.m.Nobles == C.NoblesDugOut;
	}

	function arriveDestination()
	{
		local C = ::Const.Skv.Trail;
		local B = this.band();
		if (!this.m.BoonGranted && this.m.BoonName == "" && B.Band >= C.BandFull)
		{
			local P = ::Legends.Perk.Pathfinder;
			local pool = [];
			foreach (bro in ::World.getPlayerRoster().getAll())
			{
				local has = true;
				try { has = ::Legends.Perks.has(bro, P); }
				catch (e) { ::logError("Skv.Trail: Perks.has threw on " + bro.getName() + " - " + e); }
				if (!has) pool.push(bro);
			}
			if (pool.len() == 0) ::Skv.dbg("Skv.Trail: every brother already has Pathfinder; no boon to give.");
			else this.m.BoonName = pool[::Math.rand(0, pool.len() - 1)].getName();
		}
		::Skv.dbg("Skv.Trail: ARRIVED, survey " + this.m.DP + ", band " + B.Band + " (raw " + B.Raw
			+ (B.CapOdvar ? ", CAPPED at poor: fled Odvar" : "") + (B.CapOrcs ? ", CAPPED below bonus: fled the orcs" : "")
			+ "), fee " + this.feeFor(B.Band) + " + bonus " + this.bonusFor(B.Band)
			+ ", boon " + (this.m.BoonName == "" ? "none" : "to " + this.m.BoonName));
		return "Report";
	}

	function grantBoon()
	{
		if (this.m.BoonGranted || this.m.BoonName == "") return;
		local P = ::Legends.Perk.Pathfinder;
		local bro = null;
		foreach (b in ::World.getPlayerRoster().getAll())
		{
			if (b.getName() != this.m.BoonName) continue;
			local has = true;
			try { has = ::Legends.Perks.has(b, P); } catch (e) { ::logError("Skv.Trail: Perks.has threw - " + e); }
			if (!has) { bro = b; break; }
		}
		if (bro == null)
		{
			::logError("Skv.Trail: the boon's brother " + this.m.BoonName + " is gone or has Pathfinder now; no boon given.");
			return;
		}
		local res = { Added = null };
		try
		{
			::Legends.Perks.grant(bro, P, function ( _perk )
			{
				res.Added = this.getBackground().addPerk(P, 0, false);
				if (!res.Added) this.getBackground().m.PerkTreeMap[_perk.getID()].IsRefundable = false;
			}.bindenv(bro));
		}
		catch (e)
		{
			::logError("Skv.Trail: Perks.grant threw on " + bro.getName() + " - " + e);
			return;
		}
		this.m.BoonGranted = true;
		local now = false;
		try { now = ::Legends.Perks.has(bro, P); } catch (e) { ::logError("Skv.Trail: the boon's read-back threw - " + e); }
		::Skv.dbg("Skv.Trail: BOON Pathfinder to " + bro.getName() + ", added to his tree: " + res.Added + ", has it: " + now);
	}

	function concludeReport()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Concluded != 0) return;
		this.m.Concluded = 1;
		local B = this.band();
		local pay = this.feeFor(B.Band) + this.bonusFor(B.Band);
		if (pay > 0) ::World.Assets.addMoney(pay);
		local A = ::Const.World.Assets;
		local f = null;
		try { f = ::World.FactionManager.getFaction(this.getFaction()); }
		catch (e) { ::logError("Skv.Trail: the employer's faction did not resolve - " + e); }
		if (B.Band == C.BandFailed)
		{
			::World.Assets.addBusinessReputation(A.ReputationOnContractFail);
			if (f != null) f.addPlayerRelation(A.RelationCivilianContractFail, "Came back from the mountains without a road");
		}
		else if (B.Band == C.BandPoor)
		{
			::World.Assets.addBusinessReputation(A.ReputationOnContractPoor);
			if (f != null) f.addPlayerRelation(A.RelationCivilianContractPoor, "Brought back a poor road over the mountains");
		}
		else
		{
			::World.Assets.addBusinessReputation(A.ReputationOnContractSuccess);
			if (f != null) f.addPlayerRelation(A.RelationCivilianContractSuccess, "Found a road over the mountains");
			this.grantBoon();
		}
		::Skv.dbg("Skv.Trail: REPORT concluded, band " + B.Band + ", paid " + pay + ", boon " + (this.m.BoonGranted ? this.m.BoonName : "none"));
	}

	function concludeLetter()
	{
		local C = ::Const.Skv.Trail;
		if (this.m.Concluded >= 2) return;
		this.m.Concluded = 2;
		local h = this.factionOr(this.m.HouseID);
		if (h == null) { ::logError("Skv.Trail: the house (id " + this.m.HouseID + ") did not resolve; the letter's relations are lost."); return; }
		h.addPlayerRelation(C.NoblesRelation, "Brought five of its sworn families' children home");
		::Skv.dbg("Skv.Trail: THE LETTER, relations with " + h.getName() + " +" + C.NoblesRelation);
	}

	function finishSurvey()
	{
		this.showDestRing(false);
		::World.Contracts.finishActiveContract(this.band().Band == ::Const.Skv.Trail.BandFailed);
		return 0;
	}

	function onOdvarPlaced( _e, _tag )
	{
		if (_e == null) { ::logError("Skv.Trail: Odvar placed as null"); return; }
		local champ = false;
		try { champ = _e.makeMiniboss(); } catch (e) { ::logError("Skv.Trail: makeMiniboss threw on Odvar: " + e); }
		try
		{
			_e.getSkills().update();
			_e.setHitpoints(_e.getHitpointsMax());
		}
		catch (e) { ::logError("Skv.Trail: could not fill Odvar's HP: " + e); }
		local white = null;
		try { white = this.createColor("#ffffff"); } catch (e) { ::logError("Skv.Trail: createColor threw: " + e); }
		local painted = 0;
		foreach (name in ["body", "head", "head_frenzy"])
		{
			try
			{
				if (!_e.hasSprite(name)) continue;
				local spr = _e.getSprite(name);
				spr.Saturation = ::Const.Skv.Trail.OdvarSaturation;
				if (white != null) spr.Color = white;
				painted++;
			}
			catch (e) { ::logError("Skv.Trail: Odvar's sprite '" + name + "' not painted (cosmetic only): " + e); }
		}

		local perks = "?";
		try
		{
			perks = "legendary=" + ::Legends.isLegendaryDifficulty()
				+ " KillingFrenzy=" + ::Legends.Perks.has(_e, ::Legends.Perk.KillingFrenzy)
				+ " Nimble=" + ::Legends.Perks.has(_e, ::Legends.Perk.Nimble);
		}
		catch (e) { ::logError("Skv.Trail: could not read Odvar's Legendary perks: " + e); }
		::Skv.dbg("Skv.Trail: ODVAR placed, champion=" + champ + " HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax()
			+ ", " + painted + " sprite(s) painted pale, " + perks);
	}

	function odvarBudget()
	{
		local C = ::Const.Skv.Trail;
		return ::Math.maxf(C.OdvarWolfMin, C.OdvarWolfBase * this.getDifficultyMult() * this.getScaledDifficultyMult() - C.OdvarCharge);
	}

	function bandBudget()
	{
		local C = ::Const.Skv.Trail;
		return ::Math.maxf(C.BandMin, C.BandBase * this.getDifficultyMult() * this.getScaledDifficultyMult() - C.GrakchaCharge);
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_trail";
		this.m.Name = "Trailblazer's Bounty";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Economy;
		this.m.Rows = [];
		this.m.DescriptionTemplates = [
			"A noble house wants a caravan road found over the mountains, and will pay by how good a road you bring back.",
			"The house's scout is hiring a company to cross the mountains and write down a way a mule train could follow."
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function onPrepareVariables( _vars )
	{
		_vars.push(["SKVNAME", "[color=#9dbccb]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);
		_vars.push(["SKVHOUSE", this.houseName()]);
		_vars.push(["SKVRIVAL", this.rivalName()]);
		local d = this.destination();
		_vars.push(["SKVDEST", d != null ? d.getName() : (this.m.Home != null ? this.m.Home.getName() : "the far side")]);

		_vars.push(["SKVORCLORE", this.m.OrcLoreName != "" ? this.m.OrcLoreName : "one of the men"]);
		_vars.push(["SKVSNOWLORE", this.m.SnowLoreName != "" ? this.m.SnowLoreName : "one of the men"]);
	}

	function start()
	{
		local C = ::Const.Skv.Trail;

		this.m.DifficultyMult = this.Math.rand(C.DiffLo, C.DiffHi) * 0.01;

		this.m.Payment.Advance = 0.0;
		this.m.Payment.Completion = 1.0;
		this.fixRoute();
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.updateObjectives();
				this.Contract.m.BulletpointsObjectives[0] = "Survey a caravan road over the mountains for " + this.Contract.houseName();
				this.Contract.setScreen("Task");
			}

			function end()
			{

				local adv = this.Contract.m.Payment.getInAdvance();
				if (adv > 0)
				{
					::logError("Skv.Trail: an advance of " + adv + " was negotiated although #18 offers none; paid, so the player loses nothing.");
					this.World.Assets.addMoney(adv);
				}
				this.Contract.spawnStop(1);
				this.Contract.updateObjectives();

				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{

				this.Contract.updateObjectives();
				this.Contract.dressMarker();

				if (this.Contract.m.Stop >= 5 && this.Contract.m.Concluded == 0) this.Contract.showDestRing(true);
			}

			function update()
			{
				local c = this.Contract;

				local f = this.Flags.get("F18");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V18") == f;
					local fled = this.Flags.get("R18") == f;
					this.Flags.set("F18", "");
					this.Flags.set("V18", "");
					this.Flags.set("R18", "");
					if (!won && !fled) ::Skv.dbg("Skv.Trail: " + f + " was launched but never resolved - no state change.");
					else if (f == "Skv18Odvar") c.resolveOdvarFight(won);
					else if (f == "Skv18Orcs") c.resolveOrcFight(won);
					else if (f == "Skv18Ogre") c.resolveOgreFight(won);
					else ::logError("Skv.Trail: an unknown fight id resolved: " + f);
					this.TempFlags.set("AtSite", false);
				}

				if (c.m.Stop >= 5)
				{
					if (c.m.Concluded != 0) return;
					if (c.isAtDestination())
					{
						if (!this.TempFlags.get("AtSite"))
						{
							this.TempFlags.set("AtSite", true);
							c.setScreen(c.arriveDestination());
							this.World.Contracts.showActiveContract();
						}
					}
					else this.TempFlags.set("AtSite", false);
					return;
				}

				if (::MSU.isNull(c.m.Marker)) return;
				if (c.isPlayerAt(c.m.Marker))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						local s = c.stopScreen();
						if (s != null)
						{
							c.setScreen(s);
							this.World.Contracts.showActiveContract();
						}
					}
				}
				else
				{
					this.TempFlags.set("AtSite", false);
				}
			}

			function onOdvarFight()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (::MSU.isNull(c.m.Marker)) { ::logError("Skv.Trail: fight 1 with no marker; not started."); return; }
				c.m.Odvar = C.OdvarFight;
				c.clearRows();
				local tile = c.m.Marker.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv18Odvar";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) { ::logError("Skv.Trail: no BeastsTracks: " + e); }
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];

				p.Entities.push({
					ID = ::Const.EntityType.Direwolf,
					Variant = 0,
					Row = -1,
					Script = "scripts/entity/tactical/enemies/skv_frenzied_direwolf",
					Faction = fac,
					Name = C.OdvarName,
					Callback = c.onOdvarPlaced.bindenv(c)
				});
				local budget = c.odvarBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionTormentWolves, budget,
					fac, "Trail/Odvar's pack", ::Const.World.Spawn.GolarionTormentWolves);
				::Skv.dbg("Skv.Trail: FIGHT 1 (Odvar). budget=" + budget + " (" + C.OdvarWolfBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + " - " + C.OdvarCharge + ", floor " + C.OdvarWolfMin + ") units=" + p.Entities.len());
				this.Flags.set("F18", "Skv18Odvar");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onOrcFight()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (::MSU.isNull(c.m.Marker)) { ::logError("Skv.Trail: fight 2 with no marker; not started."); return; }
				c.clearRows();
				local tile = c.m.Marker.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv18Orcs";
				try { p.Music = ::Const.Music.OrcsTracks; } catch (e) { ::logError("Skv.Trail: no OrcsTracks: " + e); }
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				local fac = null;
				try { fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Orcs).getID(); }
				catch (e) { ::logError("Skv.Trail: no Orcs faction (" + e + "); the band fights as Beasts."); }
				if (fac == null) fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];
				p.Entities.push({
					ID = ::Const.EntityType.OrcWarrior,
					Variant = 0,
					Row = 1,
					Script = "scripts/entity/tactical/enemies/orc_warrior",
					Faction = fac,
					Name = C.GrakchaName
				});
				local budget = c.bandBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionTrailOrcs, budget,
					fac, "Trail/Grakcha's band", ::Const.World.Spawn.GolarionTrailOrcs);
				::Skv.dbg("Skv.Trail: FIGHT 2 (the orcs). budget=" + budget + " (" + C.BandBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + " - " + C.GrakchaCharge + ", floor " + C.BandMin + ") units=" + p.Entities.len());
				this.Flags.set("F18", "Skv18Orcs");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onOgreFight()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (::MSU.isNull(c.m.Marker)) { ::logError("Skv.Trail: fight 3 with no marker; not started."); return; }
				c.clearRows();
				local tile = c.m.Marker.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv18Ogre";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) { ::logError("Skv.Trail: no BeastsTracks: " + e); }
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];
				p.Entities.push({
					ID = ::Const.EntityType.Unhold,
					Variant = 0,
					Row = 0,
					Script = "scripts/entity/tactical/enemies/unhold",
					Faction = fac,
					Name = C.OgreName,
					Callback = c.onOgrePlaced.bindenv(c)
				});

				local lair = c.lairBudget();
				local guards = 0;
				if (c.lairHasGuards())
				{
					::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionTrailLair, lair,
						fac, "Trail/the giant's hyenas", ::Const.World.Spawn.GolarionTrailLair);
					for (local i = 1; i < p.Entities.len(); i++)
						p.Entities[i].Callback <- c.onLairGuardPlaced.bindenv(c);
					guards = p.Entities.len() - 1;
				}
				c.m.LairGuards = ::Math.min(255, guards);
				::Skv.dbg("Skv.Trail: FIGHT 3 (the giant). raw budget=" + c.ogreBudget() + " (" + C.OgreBase + " x diff " + c.getDifficultyMult()
					+ " x scaled " + c.getScaledDifficultyMult() + "), champion=" + c.ogreIsChampion()
					+ ", alerted=" + c.caveHas(C.CaveAlerted) + ", fled before=" + c.caveHas(C.CaveFled)
					+ ", lair budget=" + lair + " (raw - " + C.GiantCharge + ", min " + C.LairGuardMin + ") hyenas=" + guards);
				this.Flags.set("F18", "Skv18Ogre");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv18") return;
				this.Flags.set("V18", _combatID);
				::Skv.dbg("Skv.Trail: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F18");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R18", f);
				::Skv.dbg("Skv.Trail: retreated from " + f + " (id=" + _combatID + ")");
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
					::logError("Skv.Trail: the negotiation's advance button was not found (Legends changed its text?); the player can haggle an advance #18 will not pay.");
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
						this.Contract.resolveSetOut();
						return "SettingOut";
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
			Title = "Trailblazer's Bounty",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local where = c.destination() != null
					? "Take it all over the top to %SKVDEST%, to the house's agent there, and she'll weigh it."
					: "Cross, have a look at the far side, and bring it all back down to me.";
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgTask + ".png[/img]{%SKVHOUSE% does not send a steward to hire you. It sends its scout, %SKVNAME%Karla Wesver%SKVNAME_OFF%, a lean woman with a sun-cracked face, who takes the corner table so she can watch the door and orders nothing.%SPEECH_ON%Everything the house sells east goes through %SKVRIVAL%'s land, and %SKVRIVAL% has started stopping every cart at the border and helping itself. The only way round is over the mountains, and there is no road over the mountains. The house means to have one.\n\nNot built. Found. A way a mule train can walk from this side to the other, written down well enough that the next people up there don't die looking for it. Where the water is, where the ground gives, where a caravan can sleep. " + where + " The house pays by what the route is worth. Bring a good one and you'll be glad you went. Bring scraps and you get scraps. Bring nothing and you get nothing.%SPEECH_OFF%She mentions, the way people mention weather, that other crews have gone up after the same prize this season, and that not all of them have come down.}";
				this.Options = [
					{
						Text = "{We'll find the house its road.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{What do the men know about those mountains?}",
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
			Options = [
				{
					Text = "{Back to the scout.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgLore + ".png[/img]{%randombrother% has crossed high country before, and says so like a man who did not enjoy it.%SPEECH_ON%Up there the weather turns in an hour and stays turned for a week. You don't march through snow, you wade it, and the cold takes more men than anything with teeth. Whatever she's paying, half of it goes on boots.%SPEECH_OFF%%randombrother2% is thinking about the house instead of the weather.%SPEECH_ON%A house doesn't pay sellswords to draw it a map unless its own people won't go. Either the road is worse than she's telling us, or somebody up there doesn't want it found.%SPEECH_OFF%}";
			}
		});

		this.m.Screens.push({
			ID = "SettingOut",
			Title = "What the House Packed",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgSetOut + ".png[/img]{Before you go, %SKVNAME%Karla%SKVNAME_OFF% has a crate carried out to the company: fur-lined cloaks and mittens enough to go round, a chest of bandages and salves, a fat ledger bound in oilcloth with the house's seal on the cover, and, packed in straw on its own, a squat clay bottle stopped with pitch.%SPEECH_ON%The ledger is the job. Anything worth knowing goes in it, and it's the ledger the house pays for, not your word. The bottle is Urglin gin. Orc-brewed. The quartermaster swears by it and nobody else can stand it. Don't open it on the way up unless you want to carry whoever drank it. Somebody up there may want it more than you do, and if it comes to that, it burns like lamp oil.%SPEECH_OFF%While the packs are shared out, the talk turns to the mountains, and to what lives in them.}";
				this.List = c.setOutList();
				this.Options = [
					{
						Text = "{Up we go.}",
						function getResult()
						{
							this.Contract.clearRows();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "NoblesCamp",
			Title = "Five by the Fire",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgCamp + ".png[/img]{Three days out, where the ground starts to climb, there is a fire in the open with five people around it and nobody watching the dark. You could have walked a cart up to them. You walk up to them instead, and they come off their logs so fast that one of them kicks the pot over.\n\nThey are young, and everything they own is new: boots without a scuff, packs still stiff from the shop, a scarlet coat that has never been rained on. Once they hear who you are they settle, and the one in the red coat does the introductions. %SKVNAME%Amyas Charthagnion%SKVNAME_OFF%. %SKVNAME%Sarevi Tilernos%SKVNAME_OFF%. %SKVNAME%Leonie Ciucci%SKVNAME_OFF%. %SKVNAME%Dacian Julistarc%SKVNAME_OFF%. The youngest, %SKVNAME%Jasper Caperinas%SKVNAME_OFF%. Younger sons and daughters of the small families who hold land under the great houses, with no inheritance coming and a great deal of expensive gear, going over the mountains to find the road themselves and come home with a name.\n\n%randombrother% watches them try to hang the pot again, and leans over to you.%SPEECH_ON%They'll be dead by the snow line. Or they'll get there first. I can't decide which bothers me more.%SPEECH_OFF%}";
				this.List = [];
				this.Options = [
					{
						Text = "{Sit down with them and talk them out of it.}",
						function getResult() { return this.Contract.resolveTalks(); }
					},
					{
						Text = "{Wish them luck and leave them to it.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Nobles == ::Const.Skv.Trail.NoblesNone)
							{
								c.m.Nobles = ::Const.Skv.Trail.NoblesPressing;
								::Skv.dbg("Skv.Trail: NOBLES left to it, they press on");
							}
							return "NoblesResult";
						}
					},
					{
						Text = "{Point them up the worst of the mountain.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Trail;
							if (c.m.Nobles == C.NoblesNone)
							{
								c.m.Nobles = C.NoblesSabotaged;
								::World.Assets.addMoralReputation(-C.SabotageMoral);
								::Skv.dbg("Skv.Trail: NOBLES SABOTAGED, moral -" + C.SabotageMoral);
							}
							return "NoblesResult";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "NoblesTalk",
			Title = "Around the Fire",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				this.Text = "[img]gfx/ui/events/" + C.ImgCamp + ".png[/img]{They are glad to talk, and the more they talk the plainer it gets: they have bought the best of everything and learned nothing about any of it. None of them will be told to go home by a sellsword. But they listen to each other, and if three of them come round, the other two will follow them down.\n\n%SKVNAME%Jasper%SKVNAME_OFF% has a book on animal tracks and has plainly read it twice. %SKVNAME%Sarevi%SKVNAME_OFF%'s ropes are the best you have seen, tied with all the wrong knots. %SKVNAME%Amyas%SKVNAME_OFF% leads, and his climbing stories keep turning into hunting stories. %SKVNAME%Leonie%SKVNAME_OFF% sits apart with her compass, her mind made up about sellswords. %SKVNAME%Dacian%SKVNAME_OFF%'s bow is worth more than your wagon, and it galls him that they follow Amyas.}";

				this.List = c.listWith([c.goodRow("Won over: " + c.talksWon() + " of the " + C.TalksNeeded + " needed")]);

				this.Options = [];

				if (c.canGift())
				{
					local kind = c.giftSupply();
					this.Options.push({
						Text = "{Leave them some of our own gear. (" + C.GiftAmount
							+ (kind == C.GiftTools ? " Tools and Supplies" : " Medical Supplies") + ")}",
						function getResult() { return this.Contract.resolveGift(); }
					});
				}
				this.Options.push({
					Text = "{That's all we can tell them.}",
					function getResult() { return this.Contract.resolveNobles(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "NoblesResult",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (c.m.Nobles == C.NoblesTurnedBack)
				{
					this.Title = "Turned Back";
					this.Text = "[img]gfx/ui/events/" + C.ImgTurnedBack + ".png[/img]{In the morning it is %SKVNAME%Amyas%SKVNAME_OFF% who says it, which is how it had to be.%SPEECH_ON%We're going home. We'd have died up there, and it would have been a stupid way to go.%SPEECH_OFF%Before they leave, %SKVNAME%Leonie%SKVNAME_OFF% empties her map case into your hands: charts bought from traders and shepherds and anyone else who would sell one, half of them wrong, every one of them better than nothing. Five young nobles walk back down the valley, and the company goes up it with their maps.}";

					this.List = c.giftRows();
					this.List.extend([c.pointsRow(C.TurnBackPoints), c.standsRow()]);
				}
				else if (c.m.Nobles == C.NoblesSabotaged)
				{
					this.Title = "A Shortcut";
					this.Text = "[img]gfx/ui/events/" + C.ImgPressOn + ".png[/img]{You tell them about a shortcut. There isn't one. They thank you for it, which is the worst part, and at first light the scarlet coat leads them off up the line you pointed at. Nobody in the company has much to say about it.}";
					this.List = [
						c.moralRow(-C.SabotageMoral, "Sending them to die sits badly"),
						c.badRow("The five go on up the mountain ahead of you")
					];
				}
				else
				{
					this.Title = "Onward and Upward";
					this.Text = "[img]gfx/ui/events/" + C.ImgPressOn + ".png[/img]{They thank you for the company and are gone before you wake, the scarlet coat at the front of the line, bright as a flag against the grey. %randombrother% watches it until it is out of sight.%SPEECH_ON%Well. We'll see them again, one way or the other.%SPEECH_OFF%}";
					this.List = [c.badRow("The five go on up the mountain ahead of you")];
				}
				this.Options = [
					{
						Text = "{Onward.}",
						function getResult() { return "Ravens"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Ravens",
			Title = "The Nesting Ground",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local gin = c.m.Gin == C.GinCarried;
				this.Text = "[img]gfx/ui/events/" + C.ImgRavens + ".png[/img]{Days later the pines close in and the going gets steep, and then the trees open on a sloping clearing cut through by a fast, cold stream. The trees along the water are black with ravens, hundreds of them, and every branch has a nest in it.\n\nSome of the nests are down. They lie torn apart in the grass with shell scattered round them, and the birds are not in a forgiving mood. The first of them drop off the branches before the company is halfway to the water, and then the air is full of beaks and wings, all of them going for the eyes."
					+ (gin ? " In somebody's pack the house's bottle of Urglin gin knocks against a cooking pot. It would burn." : "") + "}";
				this.List = [];
				this.Options = [];
				if (gin)
				{
					this.Options.push({
						Text = "{Light the orc spirit and throw it into the trees.}",
						function getResult() { return this.Contract.resolveRavens(1); }
					});
				}
				this.Options.push({
					Text = "{Cover your faces and fight through to the water.}",
					function getResult() { return this.Contract.resolveRavens(2); }
				});
				this.Options.push({
					Text = "{Keep your blades down and try to quiet the birds.}",
					function getResult() { return this.Contract.resolveRavens(3); }
				});
			}
		});

		this.m.Screens.push({
			ID = "RavensAfter",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local img = "[img]gfx/ui/events/" + C.ImgRavens + ".png[/img]";
				if (c.m.Ravens == C.RavensGin)
				{
					this.Title = "Fire in the Pines";
					this.Text = img + "{The bottle bursts against a trunk and the whole tree goes up with a roar and a stink like burning tar. The flock breaks and scatters across the valley, shrieking. By the time the fire has burned down to smoking branches the clearing is yours, and quiet, and smells of cooked feathers.}";
				}
				else if (c.m.Ravens == C.RavensFightPass)
				{
					this.Title = "Through the Flock";
					this.Text = img + "{It is a filthy few minutes of flailing and cursing, but the company keeps its eyes and reaches the water, and the flock gives up and wheels away over the trees. %randombrother% pokes through a fallen nest and holds up a handful of shiny pebbles. Most are rubbish. A few are not.}";
				}
				else if (c.m.Ravens == C.RavensFightFail)
				{
					this.Title = "Through the Flock";
					this.Text = img + "{The birds win the first round and most of the second. By the time the company reaches the water, men are bleeding from the scalp and the hands, and it takes the rest of the day to make the flock leave them be.}";
				}
				else if (c.m.Ravens == C.RavensCalmPass)
				{

					this.Title = "Quieting the Flock";
					this.Text = img + "{" + c.m.ActorName + " walks out into the clearing slowly, arms low, making the sort of noise a shepherd makes at a skittish ewe, and does not flinch when the first birds come down. It takes a long time. One by one the ravens go back to the branches and sit there muttering, and let the company pass. On the way back " + c.m.ActorName + " crouches by the torn nests, studies the ground a while, and comes back frowning.%SPEECH_ON%Somebody pulled those nests down by hand and ate the eggs. Big feet, bare, and heavy. Heavier than anyone here. Came down from higher up, and went back up the same way. Orcs, if you want my guess.%SPEECH_OFF%}";
				}
				else
				{

					this.Title = "The Flock Turns";
					this.Text = img + "{" + c.m.ActorName + " goes out slow and quiet, and the birds will have none of it. The whole flock comes off the branches at once, and there is nothing for it but to cover up and fight through to the water. By the time the company gets there the grass is black with feathers, men are bleeding from the scalp and the hands, and the ravens that are left have gone to the far trees to scream about it.}";
				}
				this.List = c.listWith([]);
				this.Options = [
					{
						Text = "{On to the water.}",
						function getResult() { return this.Contract.resolveStream(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "StreamSurvey",
			Title = "The Crossing",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				this.Text = "[img]gfx/ui/events/" + C.ImgStream + ".png[/img]{With the clearing quiet the company can look at the stream properly. It is fast and cold and not very wide, and any caravan coming this way will have to get across it. %randombrother% opens the house's ledger on a flat rock, licks the pencil, and the company goes to work.}";
				this.List = c.listWith([c.pointsRow(c.streamPoints()), c.standsRow()]);
				this.Options = [];
				if (c.canBuildBridge())
				{
					this.Options.push({
						Text = "{Throw a rough bridge across. (" + C.BridgeTools + " Tools and Supplies)}",
						function getResult() { return this.Contract.resolveBridge(); }
					});
				}
				this.Options.push({
					Text = "{Leave the building to the house's masons.}",
					function getResult() { return this.Contract.leaveStop1(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Scree",
			Title = "The Snow Line",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				this.Text = "[img]gfx/ui/events/" + C.ImgSnowLine + ".png[/img]{Above the last of the pines the cold comes down like a lid. Ahead the mountains open into a wide saddle between two peaks, the pass itself, and the only way up to it is a long slope of wind-packed snow.\n\n%randombrother% kicks at the edge of it. A hand's depth down the snow is lying on loose scree, and the whole slope has the look of something waiting to be touched. If enough men slip at once, it will come down, and everyone on it comes down with it, back to the bottom and bruised, to start again. After a few slides there will be nothing left up there to fall, but nobody is keen to find out how many.\n\nThere are two ways to go at it. Roped together, the company goes up in one push, and a slide takes everyone. A few at a time, a slide takes only the men on the slope, but the waiting eats the day, and a day is something the ledger is supposed to be saving the caravans.}";
				local rows = c.travel1Rows();
				if ((c.m.Lore & C.LoreSnow) != 0)
					rows.push(c.goodRow(c.m.SnowLoreName + " knows this snow, and where to put a foot in it: an edge on the climb"));
				rows.push(c.standsRow());
				this.List = rows;
				this.Options = [
					{
						Text = "{Rope up and climb as one company.}",
						function getResult() { return this.Contract.resolveClimb(::Const.Skv.Trail.ClimbRoped); }
					},
					{
						Text = "{Send them up a few at a time.}",
						function getResult() { return this.Contract.resolveClimb(::Const.Skv.Trail.ClimbParties); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Avalanche",
			Title = "The Pass",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local roped = c.m.ClimbMode == C.ClimbRoped;
				local k = c.m.Slides;
				local t = "";
				if (k == 0)
				{
					t = roped
						? "It is slow, cold work, every man kicking steps and trusting the rope, but the snow holds. The company comes over the lip of the pass one after another and stands in the wind, looking down a far side that goes on for a very long way."
						: "The company goes up in knots of four and five, each party waiting on the one before, and the snow holds for every one of them. It takes the whole day. From the top, the far side falls away into cloud.";
				}
				else
				{
					t = "Halfway up, a boot goes through the crust and the whole slope shrugs. "
						+ (roped ? "The rope drags the entire company down with it."
							: "The men on the slope go down with it, in a roar of snow and stone, and have to be dug out at the bottom and set going again.");
					if (k >= 2) t = t + "\n\nIt happens again, higher up, and the second time is worse because everyone knew it was coming.";
					if (k >= 3) t = t + "\n\nAnd a third time. After that there is nothing left on the slope to fall, and the company walks up over bare, wet rock that it has paid for in skin.";
					t = t + "\n\nAt the top nobody says much. Everyone is looking at the far side.";
				}
				this.Text = "[img]gfx/ui/events/" + C.ImgPass + ".png[/img]{" + t + "}";
				this.List = c.listWith([c.standsRow()]);
				this.Options = [
					{
						Text = "{Over the top.}",
						function getResult() { return this.Contract.afterPass(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Buried",
			Title = "Scarlet in the Snow",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				this.Text = "[img]gfx/ui/events/" + C.ImgBuried + ".png[/img]{The company is a little way down the far side when the sound comes: a long, low roar from back over the pass, like surf. From the lip you can see the slope below, on the side you came up. It is moving. A whole face of it is sliding down the mountain, slow and heavy, and in the middle of it something scarlet turns over once, twice, and goes under.\n\nFive of them, then. Somewhere under all that, and nobody else within a week's walk to come for them."
					+ (c.m.Nobles == C.NoblesSabotaged ? " It is the line you sent them up." : "")
					+ "\n\n%randombrother% is already shrugging off a pack, and looking to you.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Go back down and dig them out.}",
						function getResult() { return this.Contract.resolveBuried(true); }
					},
					{
						Text = "{Leave them to the mountain and push on.}",
						function getResult() { return this.Contract.resolveBuried(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Wilbert",
			Title = "The Old Man of the Mountain",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local img = "[img]gfx/ui/events/" + C.ImgDog + ".png[/img]";
				if (c.m.Nobles == C.NoblesDugOut)
				{
					this.Text = img + "{The digging goes on into the dusk, with the snow still settling around the diggers. One by one they come out: blue, battered, one with an arm hanging wrong, all five of them breathing. %SKVNAME%Amyas%SKVNAME_OFF% comes out last, and the scarlet coat is ruined.\n\nThen something the size of a pony comes bounding down the slope toward the company: a dog, shaggy as a haystack, with a little barrel strapped to its collar. Behind it, picking his way down with a stick, comes an old half-orc with a white beard, tusks worn down to yellow stumps, and a sled on a rope. He does not ask what happened. He helps load the worst of the nobles onto the sled, looks the company over, and says his cabin is below the trees, and there is room by the fire.}";

					this.List = c.rowsKept();
					this.List.push(c.standsRow());
					this.Options = [
						{
							Text = "{Follow him down.}",
							function getResult() { return this.Contract.enterCabin(::Const.Skv.Trail.BarkMetDig); }
						}
					];
					return;
				}
				local lost = c.m.Nobles == C.NoblesLost;
				this.Text = img + "{" + (lost ? "Nobody talks much on the way down from the pass.\n\n" : "")
					+ "Where the trees start again, something enormous comes crashing through the undergrowth toward the company: a dog the size of a pony, shaggy as a haystack, with a little barrel strapped to its collar. It stops a few paces off, tail going, and looks at you as if you are late for something.}";
				this.List = c.rowsKept();
				this.Options = [
					{
						Text = "{Scratch its ears and let it lead the way.}",
						function getResult() { return this.Contract.enterCabin(::Const.Skv.Trail.BarkMetDog); }
					},
					{
						Text = "{Throw a stone at it and send it off.}",
						function getResult() { return this.Contract.driveDogOff(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Cabin",
			Title = "Bark",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local dig = (c.m.Bark & C.BarkMetMask) == C.BarkMetDig;
				local spared = c.ravensSpared();
				this.Text = "[img]gfx/ui/events/" + C.ImgCabin + ".png[/img]{The dog leads you to a log cabin in a stand of old pear trees, and to an old half-orc with a white beard and worn-down tusks, who comes out onto the step with a stick in one hand and does not put it down. "
					+ (dig ? "The dog is %SKVNAME%Wilbert%SKVNAME_OFF%; the old man is %SKVNAME%Bark%SKVNAME_OFF%."
						: "He calls the dog %SKVNAME%Wilbert%SKVNAME_OFF%, and calls himself %SKVNAME%Bark%SKVNAME_OFF%.")
					+ (spared ? "%SPEECH_ON%The birds at the stream say you let them be. That's more than most. Come in.%SPEECH_OFF%"
						: "%SPEECH_ON%You came up through the ravens. They're still shouting about it. Well, you're here now.%SPEECH_OFF%")
					+ "He pours something clear out of a stone jar, pear and fire in equal measure, and asks what brings a company of sellswords up his mountain. When he hears about the road he only shrugs; he has no objection to caravans, provided a few of them stop at his door. But he has news, and it is not good. The orcs up here and he have had an arrangement for longer than most of the company has been alive: they keep off his ground, he keeps off theirs, and each side knows what breaking it would cost the other. This season they have been through his woods every other day, hunting his game and setting snares on his paths, and they will not say why. A feud, maybe, or sickness in one of their camps.%SPEECH_ON%If you want mules coming through here, you'll need the orcs to agree to it, or you'll need them gone. There's a small camp of theirs a day's walk from here. I'll show you the way.%SPEECH_OFF%}";

				this.Options = [];
				if ((c.m.Bark & C.BarkVisited) != 0)
				{
					this.List = c.cabinRows();

					this.Options.push(c.gearOption("Cabin"));
					this.Options.push({
						Text = "{Take his directions.}",
						function getResult() { return this.Contract.leaveStop2(); }
					});
					return;
				}
				this.List = c.listWith([]);

				if (spared)
				{
					this.Options.push({
						Text = "{Let him tend the wounded.}",
						function getResult() { return this.Contract.resolveCabin(::Const.Skv.Trail.BarkHealFree); }
					});
				}
				else
				{
					if (c.m.Gin == C.GinCarried)
					{
						this.Options.push({
							Text = "{Give him the Urglin gin for tending the wounded.}",
							function getResult() { return this.Contract.resolveCabin(::Const.Skv.Trail.BarkHealGin); }
						});
					}
					if (c.m.BarkPaid > 0 && ::World.Assets.getMoney() >= c.m.BarkPaid)
					{
						this.Options.push({
							Text = "{Pay him to tend the wounded. (" + c.m.BarkPaid + " Crowns)}",
							function getResult() { return this.Contract.resolveCabin(::Const.Skv.Trail.BarkHealCrowns); }
						});
					}
				}
				this.Options.push({
					Text = "{Thank him, and sleep.}",
					function getResult() { return this.Contract.resolveCabin(::Const.Skv.Trail.BarkHealSlept); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Cliff",
			Title = "The Treeline",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgTreeline + ".png[/img]{Coming down the far side, the company is back among trees by noon, and glad of them. Just below the tree line a crag of grey rock stands up out of the pines, sheer on this side, and flat on top: from up there a man could see half the valley, and draw it.\n\nAlong the rim, against the sky, a row of horned heads is watching you. Mountain goats, a whole herd, grazing up there as if the drop were not there at all. %randombrother% squints up at them.%SPEECH_ON%They'll bolt or they'll fight if we come up among them making a racket, and either way it's us near the edge, not them. Somebody could go up first, quiet, and drop a rope. Or we hammer pegs in and all go up at once, and they'll hear every blow.%SPEECH_OFF%}";
				this.List = [];
				this.Options = [
					{
						Text = "{Send your best climber up first, quietly, with a rope.}",
						function getResult() { return this.Contract.resolveCliff(true); }
					},
					{
						Text = "{Hammer in pegs and go up all together.}",
						function getResult() { return this.Contract.resolveCliff(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Herd",
			Title = "The Herd",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local img = "[img]gfx/ui/events/" + C.ImgHerd + ".png[/img]";
				this.Text = c.goatsHave(C.GoatsCalmed)
					? img + "{The company comes over the rim slowly, keeping low, and the herd lets it. After a while the goats go back to cropping the thin grass along the edge, stepping around the brothers as if they were rocks, and the company has the top of the crag and the whole valley under it.}"
					: img + "{It goes wrong at the rim. A big billy lowers his head and comes on, and then the whole herd is moving, butting and scrambling, and for a few ugly moments it is anyone's guess who goes over the edge. In the end it is none of the brothers, though not for want of trying. The goats pour off down a ledge nobody else could stand on, and are gone.}";
				this.List = c.listWith([]);
				this.Options = [
					{
						Text = "{Look at the view.}",
						function getResult() { return this.Contract.resolveView(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "View",
			Title = "The View",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgView + ".png[/img]{From the top of the crag the valley opens out below like a map somebody has not finished drawing yet, and %randombrother% sets about finishing it. The house's ledger comes out, and so does everyone's opinion.}";
				this.List = c.listWith([c.pointsRow(c.vantagePoints()), c.standsRow()]);
				this.Options = [
					{
						Text = "{Down off the rock.}",
						function getResult() { return this.Contract.leaveView(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Odvar",
			Title = "Something in the Bowl",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgBowl + ".png[/img]{Below the crag the valley flattens and then sinks into a wide, boggy bowl of stunted trees. It stinks of animal. There are kills here, big ones, deer and worse, torn open and left half eaten by something that ate its fill and walked away, and the leavings have been picked over since by smaller mouths.\n\nThe smaller mouths are on the ridge now: wolves, four or five, lying in the heather and watching. Then a wolf the size of a pony comes down out of the trees, pale as old snow, and sits on its haunches in front of the company as if it had been invited.%SPEECH_ON%You're a long way up for sellswords. Mapping, is it? A road. That'll mean carts, and mules, and people walking behind the mules.%SPEECH_OFF%It says its name is %SKVNAME%Odvar%SKVNAME_OFF%, and that it has a proposal. It has lived well on this mountain, it says, and it would like to go on living well. Let the carts come through, and it will see that nothing else on the mountain touches them: no bears, no orcs, no other wolves.%SPEECH_ON%In return I take one. Just one, now and then. The one who lags, the one who coughs, the one nobody will miss before the next town. Every caravan has one. You'd be doing them a kindness, really. Fewer mouths.%SPEECH_OFF%}";
				this.List = c.rowsKept();
				this.Options = [
					{
						Text = "{Refuse him.}",
						function getResult()
						{
							this.Contract.getActiveState().onOdvarFight();
							return 0;
						}
					},
					{
						Text = "{Agree to his price.}",
						function getResult() { return this.Contract.resolveBargain(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "OdvarAfter",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (c.m.Odvar == C.OdvarWon)
				{
					this.Title = "Odvar";
					this.Text = "[img]gfx/ui/events/" + C.ImgOdvarDead + ".png[/img]{The big wolf dies the way it lived, sure to the last that it was the cleverest thing on the mountain. Without it, the pack was only ever wolves.\n\nAt the edge of the bowl, half in the mud, lies what is left of somebody who came up here before you: a traveller's pack, torn open, and a traveller who will not need it. Most of what was in it is ruined. Not all of it.}";
					this.List = c.listWith([]);
				}
				else if (c.m.Odvar == C.OdvarBargain)
				{
					this.Title = "A Bargain";
					this.Text = "[img]gfx/ui/events/" + C.ImgBargain + ".png[/img]{%SKVNAME%Odvar%SKVNAME_OFF% dips its great head, pleased, and trots back into the trees, and the wolves on the ridge melt away after it. Nobody in the company looks at anybody else for a while. Whatever goes in the ledger about this valley, the carts that come through it will be paying a toll after all, and not in coin.}";
					this.List = c.listWith([c.standsRow()]);
				}
				else
				{

					this.Title = "The Bowl Is His";
					this.Text = "[img]gfx/ui/events/" + C.ImgBargain + ".png[/img]{The company gets out of the bowl the way it came in, carrying its wounded and not looking back. Behind it the pale wolf does not bother to follow. It does not need to. It knows where the road will have to go, and it will be there when the carts come.}";
					this.List = c.listWith([c.standsRow()]);
				}
				this.Options = [
					c.gearOption("OdvarAfter"),
					{
						Text = "{On toward the orcs.}",
						function getResult() { return this.Contract.leaveOdvar(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "OrcCamp",
			Title = "Grakcha",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local met = c.m.Bark & C.BarkMetMask;
				local bark = met == C.BarkMetDig || met == C.BarkMetDog;
				local gin = c.m.Gin == C.GinCarried;
				local oath = (c.m.Lore & C.LoreOrc) != 0;
				this.Text = "[img]gfx/ui/events/" + C.ImgOrcCamp + ".png[/img]{"
					+ (bark ? "Bark's directions bring you" : "A line of snares and fresh trails leads you")
					+ " to the orcs' camp late in the day: a few tents pitched inside the broken walls of some old building, cookfires kept small so the smoke will not carry. The orcs see you long before you reach it. Nobody draws, and after a long look neither do they, and you are let in.\n\nIt is not much of a warband. Half of them are bandaged and some of the bandages are old. The one who comes to meet you is a woman with a face full of scars and one tusk snapped off short, and when she speaks it is in your own tongue, slowly, as if she has had reason to learn it and never much reason to use it.%SPEECH_ON%I am %SKVNAME%Grakcha%SKVNAME_OFF%. Say what you want, and then go.%SPEECH_OFF%"
					+ (gin ? "The Urglin gin is still in somebody's pack. It is orc drink, after all." : "")
					+ (oath ? (gin ? " " : "") + "And %SKVORCLORE%'s words about the Shattered Fang come back to you: an oath sworn on their dead is one they keep." : "")
					+ "}";
				this.List = c.listWith(oath ? [c.goodRow("You know what their oath is worth")] : []);
				this.Options = [];
				if (gin && (c.m.CampPrep & C.PrepGin) == 0)
				{
					this.Options.push({
						Text = "{Give Grakcha the Urglin gin.}",
						function getResult() { return this.Contract.resolvePrep(true); }
					});
				}
				if ((c.m.CampPrep & C.PrepDrink) == 0)
				{
					this.Options.push({
						Text = "{Sit down and drink with them, cup for cup.}",
						function getResult() { return this.Contract.resolvePrep(false); }
					});
				}
				this.Options.push({
					Text = "{Put the road to her plainly.}",
					function getResult() { return this.Contract.resolveParley(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Parley",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (c.m.Orcs == C.OrcsPeace)
				{
					this.Title = "Grakcha's Price";
					this.Text = "[img]gfx/ui/events/" + C.ImgParley + ".png[/img]{It takes most of the night. When it is done, %SKVNAME%Grakcha%SKVNAME_OFF% tells you what the orcs have been hiding in Bark's woods from.%SPEECH_ON%We had a cave, a good one, up the valley. Deep and dry. In the autumn something came into it that was bigger than all of us together. It ate what we had put by for winter, and when that was gone it started on us. We could not hold it, so we are here, hunting another's woods like thieves. You want your road? Kill that thing and give us back our home, and I will swear on my dead that your carts go by us untouched. We will trade with them, even, if they are not too proud.%SPEECH_OFF%She sends you off with what her band can spare, which is not much, and with the way to the cave.}";
					this.List = c.listWith([c.standsRow()]);
					this.Options = [
						c.gearOption("Parley"),
						{
							Text = "{We'll deal with it.}",
							function getResult() { return this.Contract.leaveStop3(); }
						}
					];
					return;
				}
				this.Title = "No Deal";
				this.Text = "[img]gfx/ui/events/" + C.ImgNoDeal + ".png[/img]{It goes wrong somewhere between the second cup and the third question. %SKVNAME%Grakcha%SKVNAME_OFF%'s face closes like a door, and around the fires her orcs are getting to their feet.%SPEECH_ON%You came up here with maps and questions to find where we are weak. We have buried enough of our own this year. We will not wait for you to come back with more of you.%SPEECH_OFF%}";
				this.List = c.listWith([]);
				this.Options = [
					{
						Text = "{To arms!}",
						function getResult()
						{
							this.Contract.getActiveState().onOrcFight();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "OrcsAfter",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				if (c.m.Orcs == C.OrcsWon)
				{
					this.Title = "The Camp";
					this.Text = "[img]gfx/ui/events/" + C.ImgOrcsDead + ".png[/img]{When it is over, the camp is quiet except for the fires. There was little enough here to take, and the company takes it.\n\n%randombrother% walks the edge of the ruin and comes back with something. The orcs' tracks, the old ones, all come from one direction: a cave mouth up the valley, and the paths worn to it are deep. Whatever drove the orcs out of it is presumably still in there. The road would be safer without it. Then again, the road is a good deal safer already.}";
				}
				else
				{

					this.Title = "Driven Off";
					this.Text = "[img]gfx/ui/events/" + C.ImgOrcCamp + ".png[/img]{The company falls back out of the ruin with the orcs howling after it, and does not stop until their fires are out of sight. Nobody will be trading with that camp now.}";
				}
				this.List = c.listWith([c.standsRow()]);
				this.Options = [
					c.gearOption("OrcsAfter"),
					{
						Text = "{Onward.}",
						function getResult() { return this.Contract.leaveStop3(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CaveMouth",
			Title = "The Cave",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local deeper = c.caveHas(C.CaveDeeper);
				local text = "[img]gfx/ui/events/" + C.ImgCave + ".png[/img]{The cave is where the orcs said it would be, and you would have found it anyway by the smell. Outside the mouth lie the carcasses of whatever the thing has been eating, too many to count, under a haze of black flies. Inside it is dim and low, and it was a home once: there are racks and shelves, all of them smashed, and the floor is a litter of broken pots and splintered wood.\n\nFrom somewhere further in comes a slow, wet, steady sound, like a very large dog with a very large bone.";
				if (deeper)
				{
					text = text + "\n\nThe way in runs through a side chamber the thing has been using as a privy, and it has been using it for a long time. Past that is a room where beds have been dragged together into one collapsed heap of blankets, and past that, in the biggest chamber, is the thing itself.\n\nIt is sitting on a throne it has made out of its own rubbish: a heap of bones, rinds and rot as high as a man, with a giant lolling on top of it, twice a man's height and fat with the orcs' winter stores, working its way through a whole boar. A bundle of crude javelins leans against the heap within reach of its hand. Small grey shapes scurry in and out of the refuse around its feet, eating what it drops";

					local guards = c.lairHasGuards();
					local alerted = c.caveHas(C.CaveAlerted);
					text = text + (guards ? ", and a pack of hyenas lies around the foot of the heap, fat and filthy, fighting over the bigger scraps. " : ". ");
					if (guards) text = text + (alerted ? "It has stopped chewing, and the hyenas are on their feet. All of them are looking at the doorway." : "It has not looked up, and neither have they.");
					else text = text + (alerted ? "It has stopped chewing. It is looking at the doorway." : "It has not looked up.");
				}
				this.Text = text + "}";
				this.List = c.listWith([]);
				this.Options = [];

				if (c.caveHas(C.CaveFled)) this.Options.push(c.gearOption("CaveMouth"));
				if (!deeper)
				{
					if (!c.caveHas(C.CaveEntrance))
					{
						this.Options.push({
							Text = "{Search the wreckage at the entrance.}",
							function getResult() { return this.Contract.resolveEntrance(); }
						});
					}
					this.Options.push({
						Text = "{Go deeper in.}",
						function getResult() { return this.Contract.resolveDeeper(); }
					});
				}
				else
				{
					if (!c.caveHas(C.CaveBedding))
					{
						this.Options.push({
							Text = "{Search the heap of bedding.}",
							function getResult() { return this.Contract.resolveBedding(); }
						});
					}
					this.Options.push({
						Text = "{Go for the giant.}",
						function getResult()
						{
							this.Contract.getActiveState().onOgreFight();
							return 0;
						}
					});
				}
				this.Options.push({
					Text = "{Leave it be, and go.}",
					function getResult() { return this.Contract.leaveCave(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "OgreAfter",
			Title = "The Heap",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local peace = c.m.Orcs == C.OrcsPeace;
				this.Text = "[img]gfx/ui/events/" + C.ImgHeap + ".png[/img]{The giant goes down at last across its own throne, and the heap collapses under it in a slide of bones. The little grey scavengers are gone before it stops moving."
					+ (c.m.LairGuards > 0 ? " Of its hyenas, the dead lie where they fell, and the rest are halfway down the mountain." : "")
					+ "\n\nSomebody has to search the heap, and %randombrother% draws the short straw. Near the bottom are orcs, or what the giant left of them, their gear gone to rust and rot. Under them are two more bodies, older, and not orcs. Whatever they wore, the giant has squeezed into one twisted lump of gold and silver, the way its kind does with anything that glitters. One of them carried a pack, and the pack is still full of silver: spoons, knives, a cup, all bent where the teeth found them. Whoever they were, they came up this mountain before you did, looking for the same thing.\n\n"
					+ (peace
						? "At dusk the orcs come up the valley, all of them, carrying what they own. %SKVNAME%Grakcha%SKVNAME_OFF% walks through her cave room by room without a word, and then comes back out to the company, and in front of her whole band she kneels in the dirt, presses her palm to it, and swears on her dead that no cart on your road will be touched by the Shattered Fang. After that there is drink, a great deal of it, and singing that is mostly shouting, and nobody in the company is allowed to sleep before dawn."
						: "There is nobody left to give the cave back to. The company leaves it to the flies.")
					+ "}";
				this.List = c.listWith([c.standsRow()]);
				local d = c.destination();
				this.Options = [
					c.gearOption("OgreAfter"),
					{
						Text = "{" + (d != null ? "On to " + d.getName() + "." : "Back down to the house.") + "}",
						function getResult() { return this.Contract.leaveCave(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "The Ledger",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Trail;
				local B = c.band();
				local opening = c.destination() != null
					? "The house's agent in %SKVDEST% is %SKVNAME%Jasikah Marten%SKVNAME_OFF%, a brisk woman with ink on her cuffs, who clears her table, sets the ledger on it and reads every page without a word."
					: "The company comes back down the way it knows, and finds %SKVNAME%Karla%SKVNAME_OFF% at the same corner table, watching the same door. She takes the ledger without a greeting and reads every page.";
				local body = "";
				if (B.Band == C.BandFailed)
					body = "She turns the pages slowly, and then faster, looking for the part that is worth money. There isn't one. She closes the book.%SPEECH_ON%There's no road in here. There's a walk. I can't take this to the house, and the house won't pay for it.%SPEECH_OFF%";
				else if (B.Band == C.BandPoor)
					body = "%SPEECH_ON%It's a road. Of a sort. A caravan could get over on this if it was desperate and lucky, and the house will have to send its own people up to finish what you started. You'll be paid for what's here, and not for what isn't.%SPEECH_OFF%";
				else if (B.Band == C.BandFull)
					body = "%SPEECH_ON%That's a road. Water, grazing, where the ground goes bad, where to sleep. The house asked for a way over and you've brought it one.%SPEECH_OFF%She counts out the fee.";
				else
					body = "%SPEECH_ON%Three other crews have come back down that mountain this season. Two with less than this, one with nothing but frostbite. This is the one the house will build on.%SPEECH_OFF%She counts out the fee, and then, after a moment, some more.";
				this.Text = "[img]gfx/ui/events/" + C.ImgReport + ".png[/img]{" + opening + "\n\n" + body + "}";

				local rows = [c.standsRow()];

				if (B.CapOdvar) rows.push(c.badRow("The house will not pay full for a road with a man-eater on it"));
				if (B.CapOrcs) rows.push(c.badRow("The house will not pay extra for a road past an orc band out for blood"));
				local fee = c.feeFor(B.Band);
				if (fee > 0) rows.push(c.moneyRow(fee));
				local bonus = c.bonusFor(B.Band);
				if (bonus > 0) rows.push(c.moneyRow(bonus, " for the best route of the season"));
				if (B.Band >= C.BandFull && c.m.BoonName != "")
					rows.push(c.goodRow(c.m.BoonName + " gains the Pathfinder perk"));
				this.List = rows;
				this.Options = [
					{
						Text = "{Done.}",
						function getResult()
						{
							local c = this.Contract;
							c.concludeReport();
							if (c.noblesLived()) return "NoblesReward";
							return c.finishSurvey();
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "NoblesReward",
			Title = "Five Signatures",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Trail.ImgLetter + ".png[/img]{Before you leave, a letter is put into your hands. It is addressed to the company, the seal is %SKVHOUSE%'s, and inside is a single sheet with five signatures at the bottom: one huge and looping, one small and careful, one pressed so hard it tore the paper. It says, at more length than it needs to, that five families who hold land under %SKVHOUSE% have told their lords exactly who brought their children home, and that the house has been listening.}";

				this.List = [{ id = 1, icon = "ui/icons/relations.png", text = "Your relations with " + c.houseName() + " improve" }];
				this.Options = [
					{
						Text = "{Good.}",
						function getResult()
						{
							local c = this.Contract;
							c.concludeLetter();
							return c.finishSurvey();
						}
					}
				];
			}
		});
	}

	function onClear()
	{
		local C = ::Const.Skv.Trail;
		::Skv.Once.release(C.OnceKey);
		if (this.m.IsActive)
		{
			::Skv.Once.retire(C.OnceKey);

			this.killMarker();
			if (this.m.Stop >= 5) this.showDestRing(false);
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onSerialize( _out )
	{
		_out.writeU32(::MSU.isNull(this.m.Marker) ? 0 : this.m.Marker.getID());
		_out.writeU32(this.m.DestinationID);
		_out.writeU32(this.m.RivalID);
		_out.writeU32(this.m.HouseID);
		_out.writeI16(this.m.DP);
		_out.writeU8(this.m.Gin);
		_out.writeU8(this.m.Nobles);
		_out.writeU16(this.m.NobleTalks);
		_out.writeU8(this.m.Ravens);
		_out.writeU8(this.m.Lore);
		_out.writeString(this.m.OrcLoreName);
		_out.writeString(this.m.SnowLoreName);
		_out.writeU8(this.m.Travel);
		_out.writeU8(this.m.GiftPaid);
		_out.writeU8(this.m.ClimbMode);
		_out.writeU8(this.m.Slides);
		_out.writeU8(this.m.Bark);
		_out.writeU16(this.m.BarkPaid);
		_out.writeU8(this.m.Goats);
		_out.writeU16(this.m.StreamTasks);
		_out.writeU16(this.m.VantageTasks);
		_out.writeU8(this.m.Odvar);
		_out.writeU8(this.m.Orcs);
		_out.writeU8(this.m.Cave);
		_out.writeU8(this.m.CampPrep);
		_out.writeU8(this.m.Stop);
		_out.writeU8(this.m.Concluded);
		_out.writeBool(this.m.BoonGranted);
		_out.writeString(this.m.BoonName);
		_out.writeString(this.m.ActorName);
		local rows = this.m.Rows == null ? [] : this.m.Rows;
		local n = ::Math.min(255, rows.len());
		if (rows.len() > 255) ::logError("Skv.Trail: " + rows.len() + " rows on the open screen; only 255 are saved.");
		_out.writeU8(n);
		for (local i = 0; i < n; i++)
		{
			_out.writeString(rows[i].icon);
			_out.writeString(rows[i].text);
		}
		_out.writeU8(this.m.LairGuards);
		_out.writeU16(this.m.Res16);
		_out.writeU32(this.m.Res32);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local marker = _in.readU32();
		if (marker != 0)
		{
			this.m.Marker = this.WeakTableRef(::World.getEntityByID(marker));
		}
		this.m.DestinationID = _in.readU32();
		this.m.RivalID = _in.readU32();
		this.m.HouseID = _in.readU32();
		this.m.DP = _in.readI16();
		this.m.Gin = _in.readU8();
		this.m.Nobles = _in.readU8();
		this.m.NobleTalks = _in.readU16();
		this.m.Ravens = _in.readU8();
		this.m.Lore = _in.readU8();
		this.m.OrcLoreName = _in.readString();
		this.m.SnowLoreName = _in.readString();
		this.m.Travel = _in.readU8();
		this.m.GiftPaid = _in.readU8();
		this.m.ClimbMode = _in.readU8();
		this.m.Slides = _in.readU8();
		this.m.Bark = _in.readU8();
		this.m.BarkPaid = _in.readU16();
		this.m.Goats = _in.readU8();
		this.m.StreamTasks = _in.readU16();
		this.m.VantageTasks = _in.readU16();
		this.m.Odvar = _in.readU8();
		this.m.Orcs = _in.readU8();
		this.m.Cave = _in.readU8();
		this.m.CampPrep = _in.readU8();
		this.m.Stop = _in.readU8();
		this.m.Concluded = _in.readU8();
		this.m.BoonGranted = _in.readBool();
		this.m.BoonName = _in.readString();
		this.m.ActorName = _in.readString();
		local n = _in.readU8();
		this.m.Rows = [];
		for (local i = 0; i < n; i++)
		{
			local icon = _in.readString();
			local text = _in.readString();
			this.m.Rows.push({ id = 1, icon = icon, text = text });
		}
		this.m.LairGuards = _in.readU8();
		this.m.Res16 = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.contract.onDeserialize(_in);
	}
});
