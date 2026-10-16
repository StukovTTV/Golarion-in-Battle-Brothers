this.skv_delve_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Site        = null,
		DayAccepted = 0,
		Act         = 0,

		Band        = 0,
		Riders      = 0,
		Maurit      = 0,
		Wary        = 0,
		Way         = 0,
		Deck        = null,
		Pos         = 0,
		Rooms       = 0,
		Passed      = 0,
		Words       = 0,

		Script      = 0,
		Reader      = "",
		Golem       = 0,
		Papers      = 0,
		Clues       = 0,

		Burn        = 0,

		Lamp        = 0,
		Locks       = 0,
		Tarka       = 0,
		Cult        = 0,

		Speaker     = 0,

		Sword       = 0,
		Ending      = 0,
		Fights      = 0,
		Alert       = 0,
		Named       = 0,
		Granted     = 0,

		ActorName   = "",
		Rows        = null,
		Res8        = 0,

		Res16       = 0,
		Res32       = 0,

		ReaderGoneLogged = false
	},

	function hasGrant( _bit ) { return (this.m.Granted & _bit) != 0; }
	function setGrant( _bit ) { this.m.Granted = this.m.Granted | _bit; }

	function factionOr( _id )
	{
		try { return ::World.FactionManager.getFaction(_id); }
		catch (e) { ::logError("Skv.Delve: faction " + _id + " did not resolve - " + e); }
		return null;
	}

	function townName()
	{
		return (this.m.Home != null && !this.m.Home.isNull()) ? this.m.Home.getName() : "the city";
	}

	function goodRow( _text ) { return { id = 1, icon = "ui/icons/special.png", text = _text }; }
	function badRow( _text )  { return { id = 1, icon = "ui/icons/regular_damage.png", text = _text }; }

	function img( _name ) { return "[img]gfx/ui/events/" + _name + ".png[/img]"; }

	function sb( _anchor ) { return ::Skv.Check.scaledBase(this, _anchor); }

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

	function feeShare( _mult )
	{
		local n = ::Math.floor(this.fee() * _mult / 10.0 + 0.5) * 10;
		return n < 10 ? 10 : n;
	}

	function kindOK() { return this.m.Band != ::Const.Skv.Delve.BandLawless; }
	function ruthlessOK() { return this.m.Band != ::Const.Skv.Delve.BandLawful; }

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
		catch (e) { ::logError("Skv.Delve: Legends' renown row strings did not resolve; a plain row stands in - " + e); }
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
		catch (e) { ::logError("Skv.Delve: getMoralReputation threw after a moral change of " + _delta + " - " + e); }
		::logInfo("Skv.Delve: moral " + (_delta < 0 ? "" : "+") + _delta + " (" + _text + ") -> now " + now);
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
			::logInfo("Skv.Delve: hurtBro found no living brother; nobody is hurt.");
			return [];
		}
		return this.hurtThese([ { ok = false, bro = _bro } ], _min, _max);
	}

	function hurtOne( _r, _min, _max )
	{
		return this.hurtBro((_r != null && "actor" in _r) ? _r.actor : null, _min, _max);
	}

	function anyBrother()
	{
		local pool = [];
		foreach (b in ::World.getPlayerRoster().getAll())
		{
			if (b.isInReserves() || !b.isAlive()) continue;
			pool.push(b);
		}
		if (pool.len() == 0) return null;
		return pool[::Math.rand(0, pool.len() - 1)];
	}

	function give( _keys, _rows, _mw = null )
	{
		local C = ::Const.Skv.Delve;
		local keys = [];
		local paths = [];
		foreach (k in _keys)
		{
			if (k in C.Items) { keys.push(k); paths.push(C.Items[k]); }
			else ::logError("Skv.Delve: give() was asked for \"" + k + "\", which is no key of ::Const.Skv.Delve.Items; skipped.");
		}
		local items = [];
		foreach (j, p in paths)
		{
			local made = ::Skv.Loot.make([ p ]);
			if (made.len() == 0) continue;
			if (_mw != null && _mw.find(keys[j]) != null) this.makeMasterwork(made[0], keys[j]);
			items.push(made[0]);
		}
		if (items.len() != paths.len())
			::logError("Skv.Delve: give() made " + items.len() + " of " + paths.len() + " items (" + this.joinList(_keys, ", ") + "); the rest is granted.");
		_rows.extend(::Skv.Loot.haul(items));
		local names = [];
		foreach (it in items) names.push(it.getName());
		::logInfo("Skv.Delve: GRANTED " + items.len() + " item(s): " + this.joinList(names, ", "));
		return items.len();
	}

	function makeMasterwork( _item, _key )
	{
		if (!("GolarionEnchant" in ::getroottable()))
		{
			::logError("Skv.Delve: ::GolarionEnchant is missing; the " + _key + " is granted plain.");
			return false;
		}
		local ok = false;
		try { ok = ::GolarionEnchant.setMasterwork(_item, true); }
		catch (e)
		{
			::logError("Skv.Delve: setMasterwork threw on the " + _key + " - " + e + "; it is granted plain.");
			return false;
		}
		if (!ok) ::logError("Skv.Delve: the " + _key + " refused masterwork; it is granted plain.");
		else ::logInfo("Skv.Delve: the " + _key + " was made masterwork.");
		return ok;
	}

	function coin( _n, _rows )
	{
		if (_n <= 0) return 0;
		::World.Assets.addMoney(_n);
		_rows.push(this.moneyRow(_n));
		::logInfo("Skv.Delve: PAID " + _n + " crowns.");
		return _n;
	}

	function swordHeld() { return this.m.Sword != ::Const.Skv.Delve.SwordNone; }

	function knowsSecret()
	{
		local C = ::Const.Skv.Delve;
		return this.m.Sword == C.SwordPaper || this.m.Sword == C.SwordTaken || (this.m.Clues & C.CluePrince) != 0;
	}

	function paperPay( _half )
	{
		if (this.m.Papers <= 0) return 0;
		local share = ::Const.Skv.Delve.PaperMult * this.m.Papers;
		if (!_half) return this.feeShare(share);
		return ::Math.floor(this.fee() * share * 0.5 / 10.0) * 10;
	}

	function addPapers( _n, _rows )
	{
		local C = ::Const.Skv.Delve;
		if (_n <= 0) return 0;
		if (!this.princeClaims())
		{
			::logInfo("Skv.Delve: addPapers(" + _n + ") with the Prince's terms refused (riders=" + this.m.Riders + "): no buyer, nothing added, no row; " + this.m.Papers + " carried.");
			return 0;
		}
		local cap = C.PapersShelves + C.PapersCase + C.PapersHeap + C.PapersNest;
		local add = _n;
		if (this.m.Papers + add > cap)
		{
			::logError("Skv.Delve: addPapers(" + _n + ") would carry " + (this.m.Papers + _n) + " papers, over the " + cap + " the keep holds; cut to " + (cap - this.m.Papers) + ".");
			add = cap - this.m.Papers;
		}
		if (add <= 0) return 0;
		this.m.Papers = this.m.Papers + add;
		_rows.push(this.goodRow("You gain " + add + (add == 1 ? " old trade agreement" : " old trade agreements") + " (" + this.m.Papers + " carried)"));
		::logInfo("Skv.Delve: PAPERS +" + add + " -> " + this.m.Papers + " carried.");
		return add;
	}

	function partyRows( _r, _did, _rows )
	{
		local failed = [];
		if (_r == null || !("rows" in _r) || !("total" in _r))
		{
			::logError("Skv.Delve: partyRows() was given a result that is not the party form; no row.");
			return failed;
		}
		if (_r.total <= 0)
		{
			::logInfo("Skv.Delve: a party check with nobody to roll it (an empty company); no row.");
			return failed;
		}
		foreach (cr in _r.rows)
		{
			if (!cr.ok) failed.push(cr);
		}
		local text = (_r.total - failed.len()) + " of the " + _r.total + " " + _did;
		_rows.push(failed.len() == 0 ? this.goodRow(text) : this.badRow(text));
		_rows.extend(::Skv.XP.checkEach(_r));
		::logInfo("Skv.Delve: PARTY check: " + (_r.total - failed.len()) + " of " + _r.total + " passed (" + _did + ").");
		return failed;
	}

	function heal( _min, _max, _rows, _only = null )
	{
		local n = 0;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.isInReserves() || !bro.isAlive()) continue;
			if (_only != null && !(bro.getID() in _only)) continue;
			local before = bro.getHitpoints();
			if (before >= bro.getHitpointsMax()) continue;
			bro.setHitpoints(::Math.min(bro.getHitpointsMax(), before + ::Math.rand(_min, _max)));
			local gain = bro.getHitpoints() - before;
			if (gain <= 0) continue;
			n = n + 1;
			_rows.push({ id = 10, icon = "ui/icons/health.png",
				text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]" + bro.getName() + " recovers " + gain + " health[/color]" });
		}
		::logInfo("Skv.Delve: HEALED " + n + " hurt men (" + _min + " to " + _max + " each)"
			+ (_only != null ? ", only among the " + _only.len() + " men the caller named." : "."));
		return n;
	}

	function hurtIds()
	{
		local ids = {};
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			if (bro.isInReserves() || !bro.isAlive()) continue;
			if (bro.getHitpoints() < bro.getHitpointsMax()) ids[bro.getID()] <- true;
		}
		return ids;
	}

	function grantKit( _rows )
	{
		local C = ::Const.Skv.Delve;
		if (this.hasGrant(C.GrantKit))
		{
			::logInfo("Skv.Delve: her kit was already granted (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantKit);
		this.give(C.KitItems, _rows);
	}

	function wandRows( _r, _rows )
	{
		if (_r == null || !("wandRow" in _r)) return;
		local s = _r.wandRow;
		if (s.len() > 0 && s.slice(s.len() - 1) == ".") s = s.slice(0, s.len() - 1);
		_rows.push(this.goodRow(s));
	}

	function gearOption( _screenID )
	{
		return {
			Text = "{Set our gear right. (open loadout)}",
			function getResult()
			{
				if (!::World.State.showLoadoutFromContract())
					::logError("Skv.Delve: the loadout did not open from " + _screenID + " (the contract screen hidden or still animating?)");
				return _screenID;
			}
		};
	}

	function readBand()
	{
		local C = ::Const.Skv.Delve;
		local moral = null;
		try { moral = ::World.Assets.getMoralReputation(); }
		catch (e)
		{
			::logError("Skv.Delve: getMoralReputation threw at accept; the band falls back to NEUTRAL (every button shown) - " + e);
			return C.BandNeutral;
		}
		local band = moral >= C.LawfulMin ? C.BandLawful : (moral < C.LawlessMax ? C.BandLawless : C.BandNeutral);
		::logInfo("Skv.Delve: the band at accept is " + (band == C.BandLawful ? "LAWFUL" : (band == C.BandLawless ? "LAWLESS" : "NEUTRAL"))
			+ " (moral " + moral + "; lawful >= " + C.LawfulMin + ", lawless < " + C.LawlessMax + ")");
		return band;
	}

	function majorOwed() { return (this.m.Riders & ::Const.Skv.Delve.RiderMajorWord) != 0; }
	function princeClaims() { return (this.m.Riders & ::Const.Skv.Delve.RiderPrinceAgreed) != 0; }

	function trusted()
	{
		local C = ::Const.Skv.Delve;
		return this.m.Maurit == C.MauritTrusted || this.m.Maurit == C.MauritAmbush;
	}
	function deadDestroyed()
	{
		local C = ::Const.Skv.Delve;
		return this.m.Maurit == C.MauritKilled || this.m.Maurit == C.MauritAmbush;
	}
	function hasPicks() { return (this.m.Clues & ::Const.Skv.Delve.CluePicks) != 0; }

	function gullyFled() { return this.m.Maurit == ::Const.Skv.Delve.MauritFled; }

	function clamp15( _n ) { return _n > 15 ? 15 : (_n < 0 ? 0 : _n); }
	function wonInside() { return this.m.Fights & 0x0F; }
	function fledCount() { return (this.m.Fights >> 4) & 0x0F; }

	function betrayalDue( _leaving )
	{
		return this.m.Maurit == ::Const.Skv.Delve.MauritTrusted && (_leaving || this.wonInside() > 0);
	}

	function golemJoins() { return this.m.Golem > 0; }
	function servantIn( _key )
	{
		local F = ::Const.Skv.Delve.Fights;
		return this.golemJoins() && (_key in F) && F[_key].Servant;
	}

	function ambushCircle()
	{
		local C = ::Const.Skv.Delve;
		if ((this.m.Wary & 3) == C.WaryCaught) return false;
		if ((this.m.Wary & C.WaryFled) != 0) return false;
		if (this.servantIn("Ambush")) return false;
		return true;
	}

	function canRead() { return this.m.Script != ::Const.Skv.Delve.ScriptUnknown; }
	function spokeAt( _bit ) { return (this.m.Words & _bit) != 0; }

	function readBit( _place )
	{
		local C = ::Const.Skv.Delve;
		if (_place == "air") return C.WordTriedAir;
		if (_place == "stone") return C.WordTriedStone;
		if (_place == "water") return C.WordTriedWater;
		if (_place == "statue") return C.WordTriedStatue;
		if (_place == "archive") return C.WordTriedArchive;
		return 0;
	}

	function readPlace( _i )
	{
		local C = ::Const.Skv.Delve;
		if (_i == C.RoomAir) return "air";
		if (_i == C.RoomStone) return "stone";
		if (_i == C.RoomWater) return "water";
		if (_i == C.RoomFlame) return "statue";
		if (_i == C.RoomArchive) return "archive";
		return null;
	}
	function readTried( _place )
	{
		local b = this.readBit(_place);
		return b != 0 && (this.m.Words & b) != 0;
	}

	function readFailed()
	{
		local C = ::Const.Skv.Delve;
		local n = 0;
		foreach (b in [ C.WordTriedAir, C.WordTriedStone, C.WordTriedWater, C.WordTriedStatue, C.WordTriedArchive ])
			if ((this.m.Words & b) != 0) n = n + 1;
		return n;
	}

	function readAt( _place, _rows )
	{
		local C = ::Const.Skv.Delve;
		if (this.canRead()) return true;
		local bit = this.readBit(_place);
		if (bit == 0)
		{
			::logError("Skv.Delve: readAt() was asked for \"" + _place + "\", which is no place with the old script; no roll.");
			return false;
		}
		if ((this.m.Words & bit) != 0)
		{
			::logInfo("Skv.Delve: the old script at " + _place + " was already tried (words=" + this.m.Words + "); no second roll.");
			return false;
		}
		local failed = this.readFailed();
		this.m.Words = this.m.Words | bit;
		local south = {};
		foreach (id in C.SouthernBgs) south[id] <- C.SouthernBonus;
		local anchor = this.sb(C.ReadBase) + failed * C.FailedReadBonus;
		local r = ::Skv.Check.wits(this, anchor, south);
		if (r.ok)
		{
			this.m.Script = C.ScriptBrother;
			this.m.Reader = r.actor != null ? r.actor.getName() : "";
			_rows.push(this.goodRow(this.actorName(r) + " read the old script"));
			_rows.extend(::Skv.XP.check(r));
		}
		else
		{
			_rows.push(this.badRow(_place == "archive" ? "Nobody could read the old script" : "Nobody could read the word"));
		}
		::logInfo("Skv.Delve: READING at " + _place + ": base " + anchor + " (" + failed + " place(s) failed before, +" + C.FailedReadBonus + " each; a man of the south +" + C.SouthernBonus
			+ ") chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS by " + this.actorName(r) : "FAIL") + " -> script=" + this.m.Script + " words=" + this.m.Words);
		return r.ok;
	}

	function readText( _place, _text )
	{
		return this.readTried(_place) ? "{" + _text + " (nobody could read it)}" : "{" + _text + "}";
	}

	function lampState() { return this.m.Lamp & 3; }

	function lampAtFountain()
	{
		local C = ::Const.Skv.Delve;
		return this.spokeAt(C.WordWater) && !this.roomDone(C.RoomWater) && this.m.Lamp == 0
			&& this.inRun(C.RoomScribes) && !this.roomDone(C.RoomScribes) && !this.roomPassed(C.RoomScribes);
	}

	function spoken()
	{
		local C = ::Const.Skv.Delve;
		local n = 0;
		foreach (b in [ C.WordAir, C.WordStone, C.WordWater ]) if ((this.m.Words & b) != 0) n = n + 1;
		return n;
	}

	function cultState() { return this.m.Cult & 0x0F; }

	function speakerEscapes()
	{
		local C = ::Const.Skv.Delve;
		return this.cultState() == C.CultFought && this.m.Tarka != C.TarkaWon;
	}

	function cultStandsDown() { return this.m.Tarka == ::Const.Skv.Delve.TarkaWon; }

	function tarkaLittle()
	{
		local C = ::Const.Skv.Delve;
		return this.m.Tarka == C.TarkaLittle || this.m.Tarka == C.TarkaPaid;
	}

	function tarkaLine()
	{
		local C = ::Const.Skv.Delve;
		local t = this.m.Tarka;
		if (t == C.TarkaWon) return "Behind you, Tarka is already telling her band how it all went, and her own part in it grows with every telling.";
		if (t == C.TarkaLittle) return "In the gallery Tarka watches you go, and she looks almost pleased.";
		if (t == C.TarkaPaid) return "In the gallery Tarka is counting your crowns again as you pass.";
		if (t == C.TarkaBeaten) return "The dead kobolds still lie in the gallery as you pass, under the names scratched into its walls.";
		::logInfo("Skv.Delve: tarkaLine() with tarka=" + t + " (the gallery not settled): no line.");
		return "";
	}

	function canGiveUp()
	{
		local C = ::Const.Skv.Delve;
		return this.fledCount() > 0 && !this.swordHeld() && this.m.Ending == C.EndNone;
	}

	function lockState( _door ) { return _door ? ((this.m.Locks >> 4) & 0x0F) : (this.m.Locks & 0x0F); }
	function setLock( _door, _v )
	{
		if (_door) this.m.Locks = (this.m.Locks & 0x0F) | ((_v & 0x0F) << 4);
		else this.m.Locks = (this.m.Locks & 0xF0) | (_v & 0x0F);
	}

	function namedOf( _shift ) { return (this.m.Named >> _shift) & 0x0F; }
	function setNamed( _shift, _n )
	{
		this.m.Named = (this.m.Named & ~(0x0F << _shift)) | ((this.clamp15(_n) & 0x0F) << _shift);
	}

	function swordPay() { return this.feeShare(::Const.Skv.Delve.SwordMult); }
	function boneHallCleared() { return this.roomDone(::Const.Skv.Delve.RoomBones); }
	function deadPay() { return (this.majorOwed() && this.deadDestroyed()) ? this.feeShare(::Const.Skv.Delve.DeadMult) : 0; }
	function bonePay() { return (this.majorOwed() && this.boneHallCleared()) ? this.feeShare(::Const.Skv.Delve.BoneHallMult) : 0; }
	function bountyPay() { return this.deadPay() + this.bonePay(); }
	function docPay() { return this.feeShare(::Const.Skv.Delve.DocMult); }
	function pursePay() { return this.feeShare(::Const.Skv.Delve.PurseMult); }
	function hoardPay() { return this.feeShare(::Const.Skv.Delve.HoardMult); }

	function heardSpeaker()
	{
		local C = ::Const.Skv.Delve;
		local t = this.m.Tarka;
		return t == C.TarkaLittle || t == C.TarkaWon || t == C.TarkaPaid;
	}

	function koboldsJudge()
	{
		local C = ::Const.Skv.Delve;
		local st = this.cultState();
		return st == C.CultAside || st == C.CultDragged;
	}

	function majorShown() { return this.majorOwed() || this.deadDestroyed(); }

	function siteLive() { return !::MSU.isNull(this.m.Site); }
	function atSite() { return this.siteLive() && this.isPlayerAt(this.m.Site); }

	function siteTile()
	{
		if (this.siteLive()) return this.m.Site.getTile();
		::logInfo("Skv.Delve: no marker at a fight (a jump?); the fight runs on the party's tile.");
		return ::World.State.getPlayer().getTile();
	}

	function killSite()
	{
		if (this.siteLive())
		{
			this.m.Site.getSprite("selection").Visible = false;
			this.m.Site.die();

			::logInfo("Skv.Delve: the marker " + ::Const.Skv.Delve.SiteName + " is REMOVED.");
		}
		else ::logInfo("Skv.Delve: no marker standing to remove.");
		this.m.Site = null;
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
		catch (e) { ::Skv.dbg("Skv.Delve: getCurrentTown threw - " + e); }
		return false;
	}

	function spawnSite()
	{
		local C = ::Const.Skv.Delve;
		if (this.siteLive()) return "the marker already stands";
		if (this.m.Home == null || this.m.Home.isNull())
		{
			::logError("Skv.Delve: no host to place the keep from; no marker.");
			return null;
		}
		local home = this.m.Home.getTile();

		local st = ::Skv.Delve.siteTiles(this.m.Home);
		local maxSteps = C.SiteMaxDist * 2;
		local tile = null;
		local cut = 0;
		local far = 0;
		foreach (t in ::Skv.Lore.shuffled(st.Tiles))
		{
			local n = ::Skv.Rose.landSteps(home, t);
			if (n < 0) { cut = cut + 1; continue; }
			if (n > maxSteps) { far = far + 1; continue; }
			tile = t;
			break;
		}
		local how = "HILLS, 1 of " + st.Tiles.len() + " free hills tiles (" + st.Hills + " hills in range: "
			+ st.Edge + " at the map's edge, " + st.Busy + " occupied, " + st.Town + " too near a settlement, " + st.Site + " too near a location; "
			+ cut + " cut off, " + far + " over " + maxSteps + " steps before this one)";

		if (tile == null)
		{
			::logError("Skv.Delve: no hills tile around " + this.m.Home.getName() + " passed the placement tests (" + st.Hills + " hills in range: "
				+ st.Edge + " at the map's edge, " + st.Busy + " occupied, " + st.Town + " too near a settlement, " + st.Site + " too near a location, "
				+ cut + " cut off, " + far + " over " + maxSteps + " steps); falling back to " + C.SiteRolls + " rolls of getTileToSpawnLocation.");
			local hill = null;
			local solid = null;
			local any = null;
			local rolls = 0;
			for ( ; rolls < C.SiteRolls && hill == null; rolls = rolls + 1 )
			{
				local t = this.getTileToSpawnLocation(home, C.SiteMinDist, C.SiteMaxDist);
				if (t == null) continue;
				if (any == null) any = t;
				if (!::Skv.Rose.isSolidGround(t)) continue;
				if (solid == null) solid = t;
				if (t.Type == ::Const.World.TerrainType.Hills) hill = t;
			}
			tile = hill != null ? hill : (solid != null ? solid : any);
			if (tile == null)
			{
				::logError("Skv.Delve: getTileToSpawnLocation gave no tile in " + rolls + " rolls around " + this.m.Home.getName() + "; no marker (the repair tries again).");
				return null;
			}
			if (hill == null && solid == null)
				::logError("Skv.Delve: every one of " + rolls + " rolls was shore or impassable ground; the keep stands on terrain " + tile.Type + " all the same.");
			how = "FALLBACK after " + rolls + " rolls: " + (hill != null ? "hills all the same" : "NOT ON HILLS");
		}

		tile.clear();
		local ref = this.WeakTableRef(::World.spawnLocation(C.SiteScript, tile.Coords));

		this.m.Site = ref;
		ref.onSpawned();
		ref.setDiscovered(true);
		ref.setAttackable(false);
		ref.getSprite("selection").Visible = true;
		::World.uncoverFogOfWar(ref.getTile().Pos, 500.0);

		local line = "Skv.Delve: " + C.SiteName + " at " + tile.Coords.X + "," + tile.Coords.Y
			+ " terrain=" + tile.Type + " (" + ::Skv.Trail.terrainName(tile.Type) + ")"
			+ " dist=" + home.getDistanceTo(tile) + " tiles, " + ::Skv.Rose.landSteps(home, tile) + " steps from " + this.m.Home.getName()
			+ " (" + how + ")";
		::logInfo(line);
		return line;
	}

	function setRings()
	{
		local C = ::Const.Skv.Delve;
		if (this.siteLive()) this.m.Site.getSprite("selection").Visible = this.m.Act < C.ActHome;
		if (this.m.Home != null && !this.m.Home.isNull())
			this.m.Home.getSprite("selection").Visible = this.m.Act >= C.ActHome;
	}

	function deck() { return this.m.Deck == null ? [] : this.m.Deck; }

	function ensureDeck( _where )
	{
		local D = ::Skv.Delve;
		local why = D.deckWhy(this.m.Deck);
		if (why == null) return;
		if (this.deck().len() > 0)
			::logError("Skv.Delve: the saved deck is broken at " + _where + " (" + why + "): " + D.deckText(this.m.Deck) + ". Drawing a new one.");
		this.m.Deck = D.drawDeck();
		local again = D.deckWhy(this.m.Deck);
		::logInfo("Skv.Delve: the deck drawn at " + _where + ": " + D.deckText(this.m.Deck) + (again == null ? "" : "  << STILL BROKEN: " + again));
	}

	function runRooms() { return ::Skv.Delve.order(this.deck(), this.m.Way); }
	function roomDone( _i ) { return (this.m.Rooms & (1 << _i)) != 0; }
	function roomPassed( _i ) { return (this.m.Passed & (1 << _i)) != 0; }
	function inRun( _i ) { return this.runRooms().find(_i) != null; }

	function nextRoom()
	{
		foreach (r in this.runRooms())
		{
			if (!this.roomDone(r) && !this.roomPassed(r)) return r;
		}
		return null;
	}

	function stoneWaits()
	{
		local C = ::Const.Skv.Delve;
		return this.roomDone(C.RoomStone) && !this.spokeAt(C.WordStone) && this.inRun(C.RoomStone);
	}

	function rooms()
	{
		local C = ::Const.Skv.Delve;
		return [
			{ Title = "The Stone Face", Img = C.ImgStatue,
			  Door = "{On down the first corridor.}",
			  Seen = "The corridor ends at a great stone face set into the wall: a bearded man with puffed cheeks, and a dark hole as wide as a shield where his mouth should be. A word in an old southern script is cut into his brow.",
			  After = "The stone face is silent, and the corridor runs on behind it." },
			{ Title = "The Wet Door", Img = C.ImgCells,
			  Door = "{The damp room on the left.}",

			  Seen = "A damp room with a locked inner door. Something wet shines on its boards, and the air behind it smells of rot. Through a crack you can see more doors beyond it, black with mould.",
			  After = "The inner door stands open on three cells, their doors black with mould." },
			{ Title = "Thick Webs", Img = C.ImgWebs,
			  Door = "{The room hung with webs.}",
			  Seen = "Webs fill the room from wall to wall. Small dark shapes hang wrapped in them, and something large moves above.",
			  After = "The spiders are dead, and the webs hang in rags." },
			{ Title = "The Painted Hall", Img = C.ImgBones,
			  Door = "{Into the great hall.}",
			  Seen = "A great painted hall. A tunnel has been torn into one wall, and before it lies a heap of gnawed bones. Not all of them are animal bones.",
			  After = "The dead lie still among their own bones, and the heap has been searched." },
			{ Title = "The Fallen Warrior", Img = C.ImgStatue,
			  Door = "{The hall of the fallen statue.}",
			  Seen = "A granite warrior lies broken across the floor. A word in an old southern script is cut into the helmet of its severed head.",
			  After = "The broken warrior is only stone now. Whatever lived in it has stood up and walked." },
			{ Title = "The Dry Fountain", Img = C.ImgStatue,
			  Door = "{The room with the fountain.}",
			  Seen = "Four stone serpent heads rise from the wall over a dry basin, three of them with open jaws. A word in an old southern script is cut into the crest of the fourth head.",
			  After = "Water stands in the basin, and the four stone heads drip." },
			{ Title = "Rotten Shelves", Img = C.ImgArchive,
			  Door = "{The room of shelves.}",

			  Seen = "", After = "" },
			{ Title = "The Rubbish Heap", Img = C.ImgRefuse,
			  Door = "{The warped door.}",
			  Seen = "Behind a door warped by the damp lies a heap of rubbish as high as a man's chest. Rats the size of dogs nest in it.",
			  After = "The rats lie dead, and their heap has been turned over and searched." },
			{ Title = "Broken Desks", Img = C.ImgScribes,
			  Door = "{The room of desks.}",
			  Seen = "Broken writing desks lie about, grown over with pale mushrooms. At the back of the room something crouches in a nest of fungus: a creature much like a toad and as big as a hound, its hide dry and flaking. When it opens its eyes, light pours from them like a lantern's.",
			  After = "The nest at the back of the room is empty, and its lights are out." },
			{ Title = "Barrels and Bottles", Img = C.ImgStores,
			  Door = "{The room of barrels.}",
			  Seen = "Barrels and boxes fill the room, most of them rotten: spoiled food, coils of wire, sharpened stakes. A row of bottles marked with scratches stands along one wall.",
			  After = "The storeroom has been searched." },
			{ Title = "The Swept Gallery", Img = C.ImgGallery,
			  Door = "{The swept gallery.}",
			  Seen = "A swept gallery with names scratched into its walls. Four kobolds stop arguing and take their places, three spears in front and a sling behind.",
			  After = "The gallery is yours to cross." },
			{ Title = "The Red Light", Img = C.ImgFlame,
			  Door = "{Towards the red light.}",

			  Seen = "Two rooms have been knocked into one, with a fallen door laid on stones for an altar and candles burning on it. Four kobolds kneel before a stone dragon. When a thin voice somewhere behind it asks a question, fire bursts from the dragon's mouth, once or twice, and the kobolds bow lower. A word in an old southern script is cut into the dragon's chest.",
			  After = "Nobody kneels before the stone dragon now, and the thin voice behind it has stopped." }
		];
	}

	function roomRow( _i )
	{
		local rows = this.rooms();
		if (typeof _i != "integer" || _i < 0 || _i >= rows.len()) return null;
		return rows[_i];
	}

	function enterRoom( _i )
	{
		local R = ::Const.Skv.Delve.Rooms;
		if (typeof _i != "integer" || _i < 0 || _i >= R.len())
		{
			::logError("Skv.Delve: enterRoom got " + _i + ", which is no room; back to the hub.");
			this.m.Rows = [];
			return this.hubScreen();
		}
		this.m.Pos = _i;
		this.m.Rows = [];
		::logInfo("Skv.Delve: ROOM " + R[_i].Key + " (index " + _i + ") entered. done=" + this.roomDone(_i) + " passed=" + this.roomPassed(_i)
			+ " rooms=" + this.m.Rooms + " passed=" + this.m.Passed + " golem=" + this.m.Golem);
		this.grantVials(_i);
		return R[_i].Key;
	}

	function grantVials( _i )
	{
		local C = ::Const.Skv.Delve;
		if (_i != C.RoomAir && _i != C.RoomStone && _i != C.RoomWater) return;
		if (this.hasGrant(C.GrantVials)) return;
		this.setGrant(C.GrantVials);
		local rows = [ this.goodRow("Someone had left small offerings here: beads, bones, and two clay flasks that smelled of lamp oil") ];
		this.give(C.VialItems, rows);
		this.m.Rows = rows;
		::logInfo("Skv.Delve: THE FIRST TWO VIALS granted at " + C.Rooms[_i].Key + " (granted=" + this.m.Granted + ").");
	}

	function closeRoom( _i, _passed, _rows )
	{
		local R = ::Const.Skv.Delve.Rooms;
		if (_passed) this.m.Passed = this.m.Passed | (1 << _i);
		else this.m.Rooms = this.m.Rooms | (1 << _i);
		this.m.Rows = _rows;
		local nxt = this.nextRoom();
		::logInfo("Skv.Delve: ROOM " + R[_i].Key + (_passed ? " PASSED BY" : " RESOLVED") + " -> rooms=" + this.m.Rooms + " passed=" + this.m.Passed
			+ " next=" + (nxt == null ? "none" : R[nxt].Key));
	}

	function hubScreen()
	{
		local C = ::Const.Skv.Delve;

		local leaving = this.swordHeld();

		if (!leaving && this.roomDone(C.RoomFlame)) return this.flameNext();
		if (this.betrayalDue(leaving)) return "Ambush";
		if (leaving) return "WayOut";
		return "Hub";
	}

	function onward()
	{
		this.m.Rows = [];
		return this.hubScreen();
	}

	function closeAtSite()
	{

		::logInfo("Skv.Delve: the screen closes at the keep (act " + this.m.Act + ", maurit=" + this.m.Maurit + ", fights won/fled " + this.wonInside() + "/" + this.fledCount() + ").");
		this.m.Rows = [];
		this.m.TempFlags.set("DelveAtSite", true);
		return 0;
	}

	function returns() { return this.m.Res8; }

	function restock()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Res8 >= C.RestockMax)
			::logError("Skv.Delve: the keep's returns stand at " + this.m.Res8 + ", the top of their U8 field; the count stays there (fights x" + ::Skv.Delve.restockMult(this.m.Res8) + ").");
		else this.m.Res8 = this.m.Res8 + 1;
		this.m.Rows = [ this.badRow("The keep feels more dangerous than when you left") ];
		::logInfo("Skv.Delve: THE KEEP RESTOCKED: return " + this.m.Res8 + " -> fights x" + ::Skv.Delve.restockMult(this.m.Res8)
			+ " (every fight still to come inside; her ambush " + (this.m.Maurit == C.MauritTrusted ? "owed, so it grows" : "not owed") + "; rooms=" + this.m.Rooms + " passed=" + this.m.Passed + ").");
	}

	function siteScreen()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Maurit == C.MauritUnmet || this.m.Maurit == C.MauritFled) return "Gully";
		if (this.m.Maurit == C.MauritTrusted && this.m.Way == 0) return "Help";

		if (this.m.Act == C.ActRoad || this.m.Way == 0)
		{
			::logError("Skv.Delve: past the gully (maurit " + this.m.Maurit + ") with act " + this.m.Act + " and way " + this.m.Way + "; set to inside, by the door where no way was chosen.");
			if (this.m.Act == C.ActRoad) this.m.Act = C.ActInside;
			if (this.m.Way == 0) this.m.Way = C.WayDoor;
		}
		return this.hubScreen();
	}

	function riderScreen()
	{
		local C = ::Const.Skv.Delve;
		if ((this.m.Riders & C.RiderMajorAsked) == 0) return "Major";
		if ((this.m.Riders & C.RiderPrinceAsked) == 0) return "Prince";
		return "Morning";
	}

	function returnNext()
	{
		local C = ::Const.Skv.Delve;
		if (this.swordHeld())
		{
			if (this.princeClaims() && !this.hasGrant(C.GrantClaim)) return "Claim";
			if (!this.hasGrant(C.GrantAmara)) return "Amara";
		}
		else if (!this.hasGrant(C.GrantAmara)) return "Failed";
		if (this.majorShown() && !this.hasGrant(C.GrantMajorEnd)) return "MajorEnd";
		return null;
	}

	function returnScreen()
	{
		local s = this.returnNext();
		if (s != null) return s;
		::logInfo("Skv.Delve: the return is paid in full (granted=" + this.m.Granted + ") and the contract is still open; its last screen again.");
		if (this.majorShown()) return "MajorEnd";
		return this.swordHeld() ? "Amara" : "Failed";
	}

	function resolveMajor( _word )
	{
		local C = ::Const.Skv.Delve;
		if ((this.m.Riders & C.RiderMajorAsked) == 0)
		{
			this.m.Riders = this.m.Riders | C.RiderMajorAsked | (_word ? C.RiderMajorWord : 0);
			::logInfo("Skv.Delve: the Major's rider " + (_word ? "TAKEN (the word given)" : "declined") + " -> riders=" + this.m.Riders);
		}
		this.m.Rows = [];
		return this.riderScreen();
	}

	function resolvePrince( _agree )
	{
		local C = ::Const.Skv.Delve;
		if ((this.m.Riders & C.RiderPrinceAsked) == 0)
		{
			this.m.Riders = this.m.Riders | C.RiderPrinceAsked | (_agree ? C.RiderPrinceAgreed : 0);
			::logInfo("Skv.Delve: the Prince's rider " + (_agree ? "TAKEN (his terms agreed)" : "declined") + " -> riders=" + this.m.Riders);
		}
		this.m.Rows = [];
		return this.riderScreen();
	}

	function resolveGarden()
	{
		local C = ::Const.Skv.Delve;
		if ((this.m.Riders & C.RiderGarden) != 0) return "Garden";
		this.m.Riders = this.m.Riders | C.RiderGarden;
		local anchor = this.sb(C.GardenBase);
		local r = ::Skv.Check.guile(this, anchor);
		local rows = [];
		if (r.ok)
		{
			this.m.Clues = this.m.Clues | C.ClueGarden;
			if (!this.hasGrant(C.GrantGarden))
			{
				this.setGrant(C.GrantGarden);
				rows.extend(::Skv.XP.check(r));
			}
			rows.push(this.goodRow(this.actorName(r) + " heard that Amara Li owed money to many people in the city"));
			rows.push(this.goodRow("No court here would have upheld the trade prince's claim"));
		}
		else rows.push(this.badRow("The garden told you nothing"));
		this.m.Rows = rows;
		::logInfo("Skv.Delve: GARDEN guile best-of base " + anchor + " " + (r.ok ? "PASS" : "FAIL") + " by " + this.actorName(r)
			+ " -> riders=" + this.m.Riders + " clues=" + this.m.Clues);
		return "Garden";
	}

	function toRoad()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Act == C.ActRiders) this.m.Act = C.ActRoad;
		this.m.Rows = [];
		this.updateObjectives();
		this.setRings();
		::logInfo("Skv.Delve: ON THE ROAD -> act " + this.m.Act + " riders=" + this.m.Riders
			+ " (word to the Major " + this.majorOwed() + ", the Prince's terms " + this.princeClaims() + ") clues=" + this.m.Clues);
		return 0;
	}

	function resolveTrust()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Maurit != C.MauritUnmet) return this.siteScreen();
		this.m.Maurit = C.MauritTrusted;
		this.m.Clues = this.m.Clues | C.ClueHerWord;
		local anchor = this.sb(C.WaryBase);
		local r = ::Skv.Check.perception(this, anchor);
		this.m.Wary = (this.m.Wary & C.WaryFled) | (r.ok ? C.WaryCaught : C.WaryMissed);
		local rows = [];
		if (r.ok)
		{
			rows.extend(::Skv.XP.check(r));
			rows.push(this.goodRow(this.actorName(r) + " did not believe her about the beasts"));
		}
		if (this.majorOwed() && !this.hasGrant(C.GrantTrust))
		{
			this.setGrant(C.GrantTrust);
			this.moral(C.TrustMoral, "You gave your word to destroy the dead, and took a dead woman's help", rows);
		}
		this.m.Rows = rows;
		::logInfo("Skv.Delve: TRUSTED. her lie: perception best-of base " + anchor + " " + (r.ok ? "PASS" : "FAIL") + " by " + this.actorName(r)
			+ " -> maurit=" + this.m.Maurit + " wary=" + this.m.Wary + " clues=" + this.m.Clues + " (her ambush is owed; Circle now=" + this.ambushCircle() + ")");
		return "Help";
	}

	function chooseWay( _way )
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Way == 0)
		{
			local way = _way;
			if (way == C.WayCave && !this.trusted())
			{
				::logError("Skv.Delve: the cave was asked for by a company she never showed it to; the door it is.");
				way = C.WayDoor;
			}
			this.ensureDeck("the way in");
			this.m.Way = way;
			this.m.Act = C.ActInside;
			local run = this.runRooms();
			this.m.Pos = run.len() > 0 ? run[0] : 0;
			::logInfo("Skv.Delve: THE WAY IN " + ::Skv.Delve.wayLine(this.deck(), this.m.Way, this.trusted()) + " | deck " + ::Skv.Delve.deckText(this.deck()));
			this.updateObjectives();
		}
		return this.onward();
	}

	function resolveRead( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		local place = this.readPlace(_i);
		if (place == null)
		{
			::logError("Skv.Delve: a read button in " + key + ", a room with no old script; nothing happens.");
			return key;
		}
		if (this.canRead() || this.readTried(place))
		{
			::logInfo("Skv.Delve: the read button at " + key + " with script=" + this.m.Script + " words=" + this.m.Words + " (already read, or tried here); nothing happens.");
			return key;
		}
		local rows = this.m.Rows == null ? [] : clone this.m.Rows;
		this.readAt(place, rows);
		this.m.Rows = rows;
		return key;
	}

	function holdWord( _i )
	{
		local C = ::Const.Skv.Delve;
		if (!this.roomDone(_i)) this.closeRoom(_i, false, []);
		if (_i == C.RoomStone)
			::logInfo("Skv.Delve: the stone warrior's word is HELD (not yet). script=" + this.m.Script + " words=" + this.m.Words + " golem=" + this.m.Golem);
		return this.onward();
	}

	function golemFightsText()
	{
		local n = ::Const.Skv.Delve.GolemFights;
		return n == 1 ? "one battle" : (n == 2 ? "two battles" : (n == 3 ? "three battles" : n + " battles"));
	}

	function resolveSpeak( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		local bit = _i == C.RoomAir ? C.WordAir : (_i == C.RoomStone ? C.WordStone : C.WordWater);
		local rows = [];
		if (!this.canRead())
		{
			::logInfo("Skv.Delve: the word at " + key + " was asked for and nobody can read it; nothing happens.");
			return key;
		}
		if (this.spokeAt(bit)) return key;
		this.m.Words = this.m.Words | bit;
		if (_i == C.RoomAir)
		{
			rows.push(this.goodRow("A gale roared out of the stone mouth and down the corridor"));
			local r = ::Skv.Check.reflex(this, this.sb(C.AirBase), C.AirNeed);
			local failed = this.partyRows(r, "were not knocked down", rows);
			rows.extend(this.hurtThese(failed, C.GaleHurtMin, C.GaleHurtMax));
			::logInfo("Skv.Delve: THE GALE: base " + this.sb(C.AirBase) + ", " + failed.len() + " man/men thrown and hurt.");
		}
		else if (_i == C.RoomStone)
		{

			this.m.Golem = C.GolemFights;
			rows.push(this.goodRow("A servant of stone and sand rose out of the broken warrior"));
			rows.push(this.goodRow("It would serve you through " + this.golemFightsText() + " and then go back into the stone"));
		}
		else if (_i == C.RoomWater)
		{

			local hurtBefore = this.hurtIds();
			local r = ::Skv.Check.reflex(this, this.sb(C.JetsBase));
			if (r.ok)
			{
				rows.push(this.goodRow(this.actorName(r) + " called a warning in time, and the jets hit nobody"));
				rows.extend(::Skv.XP.check(r));
			}
			else
			{
				rows.push(this.badRow("The jets struck " + this.actorName(r, true) + " before anyone could call a warning"));
				rows.extend(this.hurtOne(r, C.HurtMin, C.HurtMax));
			}
			::logInfo("Skv.Delve: THE JETS: chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS" : "FAIL") + " by " + this.actorName(r));
			rows.push(this.goodRow("The basin filled with clean water"));
			if (!this.hasGrant(C.GrantWater))
			{
				this.setGrant(C.GrantWater);
				this.heal(C.HealMin, C.HealMax, rows, hurtBefore);
				rows.extend(this.washSick());
			}
			else ::logInfo("Skv.Delve: the basin's healing was already given (granted=" + this.m.Granted + "); not again.");
			if (this.lampAtFountain())
			{
				rows.push(this.badRow("The noise of the water drew something up the corridor"));
				this.m.Rows = rows;
				::logInfo("Skv.Delve: the word SPOKEN at " + key + " -> words=" + this.m.Words + "; THE LAMP-EYED CREATURE comes to the fountain (the room stays open on it).");
				return key;
			}
		}
		::logInfo("Skv.Delve: the word SPOKEN at " + key + " -> words=" + this.m.Words + " (spoken at " + this.spoken() + " of 3 devices) golem=" + this.m.Golem);
		this.closeRoom(_i, false, rows);
		return key;
	}

	function resolveLamp( _i, _cloak )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		local fountain = _i == C.RoomWater;

		if (fountain ? !this.lampAtFountain() : (this.roomDone(_i) || this.roomPassed(_i) || this.lampState() == C.LampFountain))
		{
			::logInfo("Skv.Delve: the lamp-eyed creature at " + key + " is already settled (lamp=" + this.m.Lamp + "); nothing happens.");
			return (!fountain && (this.roomDone(_i) || this.roomPassed(_i))) ? this.leaveRoom(_i) : key;
		}
		if (!fountain && this.m.Lamp != 0)
			::logError("Skv.Delve: the room of desks is open with lamp=" + this.m.Lamp + " (no path leaves that); the creature is met as alive.");
		local val = fountain ? C.LampFountain : C.LampNest;
		this.m.Lamp = val;
		local anchor = this.sb(_cloak ? C.CloakBase : C.NerveBase) - (fountain ? C.FountainPenalty : 0);
		local r = _cloak ? ::Skv.Check.handEye(this, anchor) : ::Skv.Check.nerve(this, anchor);
		if (!r.ok) this.m.Lamp = val + C.LampFailed;
		local who = this.actorName(r);
		local rows = [];
		if (r.ok)
		{
			rows.push(this.goodRow(_cloak ? who + " threw a cloak over its eyes, and it was killed while it was blind"
				: who + " kept the shields close and every eye down, and it was killed before it could bite"));
			rows.extend(::Skv.XP.check(r));
		}
		else
		{
			rows.push(this.badRow(_cloak ? who + " threw a cloak and missed, and was bitten before it was killed"
				: who + " looked up into its light and was bitten before it was killed"));
			rows.extend(this.hurtOne(r, C.BadHurtMin, C.BadHurtMax));
		}
		::logInfo("Skv.Delve: THE LAMP-EYED CREATURE at " + key + ": " + (_cloak ? "the cloak (handEye)" : "the shields (nerve)") + " base " + anchor
			+ (fountain ? " (at the fountain, -" + C.FountainPenalty + ")" : "") + " chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS" : "FAIL")
			+ " by " + who + " -> lamp=" + this.m.Lamp);
		if (!fountain) this.searchNest(rows);
		this.closeRoom(_i, false, rows);
		return key;
	}

	function leaveLamp( _i )
	{
		local C = ::Const.Skv.Delve;
		if (!this.roomDone(_i) && !this.roomPassed(_i))
		{
			if (this.m.Lamp == 0) this.m.Lamp = C.LampLeft;
			this.closeRoom(_i, true, []);
		}
		return this.onward();
	}

	function searchNestRoom( _i )
	{
		local C = ::Const.Skv.Delve;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		local rows = [];
		this.searchNest(rows);
		this.closeRoom(_i, false, rows);
		return C.Rooms[_i].Key;
	}

	function searchNest( _rows )
	{
		local C = ::Const.Skv.Delve;
		if (this.hasGrant(C.GrantScribes))
		{
			::logInfo("Skv.Delve: the nest was already searched (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantScribes);
		_rows.push(this.goodRow("Among the rubbish of the nest lay things dragged in from the desks"));
		this.addPapers(C.PapersNest, _rows);
		this.give(C.ScribesItems, _rows);
		if (this.m.Script == C.ScriptUnknown)
		{
			this.m.Script = C.ScriptList;
			_rows.push(this.goodRow("A clerk's list gave each word of the old script with its meaning beside it, and now the script could be read"));
		}
		else _rows.push(this.goodRow("A clerk's list gave each word of the old script with its meaning beside it"));
		::logInfo("Skv.Delve: THE NEST searched -> papers=" + this.m.Papers + " script=" + this.m.Script + " granted=" + this.m.Granted);
	}

	function washSick()
	{
		local rows = [];
		local sick = 0;
		local washed = 0;
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			local sk = bro.getSkills();
			if (!sk.hasSkill("injury.sickness")) continue;
			sick = sick + 1;
			try { sk.removeByID("injury.sickness"); }
			catch (e)
			{
				::logError("Skv.Delve: removeByID(injury.sickness) THREW on " + bro.getName() + " - " + e);
				continue;
			}
			if (sk.hasSkill("injury.sickness"))
			{
				::logError("Skv.Delve: " + bro.getName() + " is STILL sick after removeByID(injury.sickness); the fountain did nothing for him.");
				continue;
			}
			washed = washed + 1;
			rows.push(this.goodRow(bro.getName() + " was no longer sick"));
			::logInfo("Skv.Delve: the fountain removed injury.sickness from " + bro.getName() + " (HP " + bro.getHitpoints() + "/" + bro.getHitpointsMax() + " afterwards)");
		}
		::logInfo("Skv.Delve: the fountain's wash: " + sick + " sick, " + washed + " washed" + (sick == 0 ? " (nobody was sick: nothing to prove here)" : ""));
		return rows;
	}

	function resolveLock( _door, _pick )
	{
		local C = ::Const.Skv.Delve;
		local room = _door ? C.RoomCells : C.RoomArchive;
		local key = C.Rooms[room].Key;
		if (this.roomDone(room) || this.roomPassed(room))
		{
			::logInfo("Skv.Delve: a lock button in " + key + ", a room already over; nothing happens.");
			return this.leaveRoom(room);
		}
		if (this.lockState(_door) != C.LockUntried)
		{
			::logInfo("Skv.Delve: the lock in " + key + " was already dealt with (locks=" + this.m.Locks + "); nothing happens.");
			return key;
		}
		local rows = [];
		if (_pick)
		{
			local picks = this.hasPicks();
			local anchor = this.sb(_door ? C.DoorPickBase : C.CasePickBase) + (picks ? C.PicksBonus : 0);
			local r = ::Skv.Check.lockpick(this, anchor);
			this.setLock(_door, r.ok ? C.LockPicked : C.LockFailed);
			local who = this.actorName(r);
			::logInfo("Skv.Delve: LOCK " + (_door ? "the cells' door" : "the archive's case") + " PICK base " + anchor + (picks ? " (her picks +" + C.PicksBonus + ")" : "")
				+ " chance " + (("chance" in r) ? r.chance : "?") + " roll " + (("roll" in r) ? r.roll : "?") + " " + (r.ok ? "PASS" : "FAIL") + " by " + who
				+ " wand=" + (("wandRow" in r) ? "\"" + r.wandRow + "\"" : "none carried by the picker") + " -> locks=" + this.m.Locks);
			if (r.ok)
			{
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow(who + (_door ? " opened the door without a sound" : " opened the case whole")));
			}
			else
			{
				rows.push(this.badRow(_door ? who + " could not pick the lock, and the door had to be forced"
					: "A needle in the lock pricked " + this.actorName(r, true) + ", and the case had to be broken open"));

				if (_door) this.doorAfter(r, rows);
				else rows.extend(this.hurtOne(r, C.HurtMin, C.HurtMax));
			}
			if (picks) rows.push(this.goodRow("The dead woman's picks were used"));
			this.wandRows(r, rows);
			if (_door && r.ok) this.doorAfter(r, rows);
		}
		else
		{
			this.setLock(_door, C.LockForced);
			rows.push(this.badRow(_door ? "The door was shoved in" : "The case was broken open"));
			::logInfo("Skv.Delve: LOCK " + (_door ? "the cells' door" : "the archive's case") + " FORCED (no roll) -> locks=" + this.m.Locks);
			if (_door) this.doorAfter(null, rows);
		}
		if (!_door) this.caseLoot(rows);
		this.m.Rows = rows;
		return key;
	}

	function doorAfter( _pick, _rows )
	{
		local C = ::Const.Skv.Delve;
		if (_pick != null && _pick.ok)
		{
			_rows.push(this.goodRow("Nothing was shaken loose from the door or the walls"));
		}
		else
		{
			if (_pick != null)
			{
				_rows.push(this.badRow("The wet slime slid off the boards and burned " + this.actorName(_pick, true)));
				_rows.extend(this.hurtOne(_pick, C.HurtMin, C.HurtMax));
				::logInfo("Skv.Delve: THE SHINE dropped on the picker " + this.actorName(_pick) + " (the pick failed; no check).");
			}
			else
			{
				local s = ::Skv.Check.perception(this, this.sb(C.ShineBase));
				if (s.ok)
				{
					_rows.push(this.goodRow(this.actorName(s) + " saw the slime on the boards move, and the company scraped it off before shoving the door in"));
					_rows.extend(::Skv.XP.check(s));
				}
				else
				{
					_rows.push(this.badRow("The slime on the boards was alive. It dropped onto " + this.actorName(s, true) + " as the door broke open and burned wherever it touched"));
					_rows.extend(this.hurtOne(s, C.HurtMin, C.HurtMax));
				}
				::logInfo("Skv.Delve: THE SHINE (the door shoved in): base " + this.sb(C.ShineBase) + " chance " + s.chance + " roll " + s.roll + " " + (s.ok ? "PASS" : "FAIL") + " by " + this.actorName(s));
			}
			_rows.push(this.badRow("The mould on the cell doors burst into a cloud of spores"));
			local mr = ::Skv.Check.brawn(this, this.sb(C.MouldBase), C.MouldNeed);
			local failed = this.partyRows(mr, "did not breathe in the spores", _rows);
			local sick = this.sicken(failed, _rows);
			::logInfo("Skv.Delve: THE MOULD: base " + this.sb(C.MouldBase) + ", " + failed.len() + " man/men failed, " + sick + " made sick.");
		}
		this.m.Clues = this.m.Clues | C.ClueSeal;
		::logInfo("Skv.Delve: THE CELLS opened (locks=" + this.m.Locks + "): the seal is seen -> clues=" + this.m.Clues);
	}

	function sicken( _failed, _rows )
	{
		local C = ::Const.Skv.Delve;
		local n = 0;
		foreach (cr in _failed)
		{
			local bro = cr.bro;
			if (bro == null || !bro.isAlive()) continue;

			local excluded = false;
			try { excluded = bro.m.ExcludedInjuries.find("injury.sickness") != null; }
			catch (e) { ::logError("Skv.Delve: reading ExcludedInjuries on " + bro.getName() + " THREW - " + e + "; treated as able to fall sick."); }
			if (excluded)
			{
				::logInfo("Skv.Delve: sicken: " + bro.getName() + " failed, but injury.sickness is excluded (undead); neither sick nor hurt.");
				continue;
			}
			local sk = bro.getSkills();
			if (sk.hasSkill("injury.sickness"))
			{
				_rows.push(this.badRow(bro.getName() + " was already sick"));
				::logInfo("Skv.Delve: sicken: " + bro.getName() + " failed and was sick already; left as is.");
				continue;
			}
			local icon = null;
			try
			{
				local inj = ::new("scripts/skills/injury/sickness_injury");
				sk.add(inj);
				icon = inj.getIcon();
			}
			catch (e) { ::logError("Skv.Delve: adding injury.sickness to " + bro.getName() + " THREW - " + e); }
			if (icon != null && sk.hasSkill("injury.sickness"))
			{
				n = n + 1;
				_rows.push({ id = 10, icon = icon, text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]" + bro.getName() + " is sick[/color]" });
				::logInfo("Skv.Delve: sicken: " + bro.getName() + " is made sick (has it now: true; the mould or the stakes).");
				continue;
			}
			::logError("Skv.Delve: " + bro.getName() + " is NOT sick after the add (icon " + icon + "); he is hurt instead.");
			_rows.extend(this.hurtBro(bro, C.HurtMin, C.HurtMax));
		}
		return n;
	}

	function caseLoot( _rows )
	{
		local C = ::Const.Skv.Delve;
		if (this.hasGrant(C.GrantCase))
		{
			::logInfo("Skv.Delve: the case's contents were already granted (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantCase);
		local whole = this.lockState(false) == C.LockPicked;
		if (whole)
		{
			this.give(C.CaseItems, _rows);
			this.addPapers(C.PapersCase, _rows);
		}
		else _rows.push(this.badRow("Two jars of dye broke inside, and the papers under them were soaked through"));
		this.coin(this.feeShare(C.CaseMult), _rows);
		::logInfo("Skv.Delve: THE CASE (" + (whole ? "picked whole" : "broken") + ") -> papers=" + this.m.Papers + " granted=" + this.m.Granted);
	}

	function burialFee() { return this.feeShare(::Const.Skv.Delve.BurialMult); }
	function cellsOpened() { return this.lockState(true) != ::Const.Skv.Delve.LockUntried; }

	function burialOwed()
	{
		local C = ::Const.Skv.Delve;
		return this.hasGrant(C.GrantBurialOwed) && !this.hasGrant(C.GrantBurialPaid);
	}

	function burialDue( _extra )
	{
		if (!this.burialOwed()) return 0;
		local fee = this.burialFee();
		local held = ::World.Assets.getMoney() + _extra;
		if (held < 0) held = 0;
		return held < fee ? held : fee;
	}

	function burialRow( _n )
	{
		return { id = 1, icon = "ui/icons/asset_money.png",
			text = "You pay " + ::MSU.Text.color(::Const.UI.Color.NegativeEventValue, _n) + " Crowns for his priest and grave" };
	}

	function payBurial( _rows )
	{
		local C = ::Const.Skv.Delve;
		if (!this.burialOwed())
		{
			if ((this.m.Clues & C.ClueBurial) != 0)
				::logInfo("Skv.Delve: the burial's fee is not owed at the return (granted=" + this.m.Granted + ": "
					+ (this.hasGrant(C.GrantBurialPaid) ? "paid already" : "paid at the cells by a 1.8.9-1.8.11 save, or a jump's hand-set clue") + "); nothing taken.");
			return 0;
		}
		local fee = this.burialFee();
		local held = ::World.Assets.getMoney();
		local n = this.burialDue(0);
		this.setGrant(C.GrantBurialPaid);
		if (n > 0) ::World.Assets.addMoney(-n);
		_rows.push(this.burialRow(n));
		if (n < fee) ::logInfo("Skv.Delve: the company held " + held + " crowns at the return, less than the burial's fee of " + fee + "; it paid " + n + ".");
		::logInfo("Skv.Delve: THE BURIAL paid at the return: " + n + " crowns (fee " + fee + ", " + held + " held before) -> granted=" + this.m.Granted);
		return n;
	}

	function buryEnvoy( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if (!this.cellsOpened() || !this.kindOK() || this.hasGrant(C.GrantCells))
		{
			::logInfo("Skv.Delve: the burial was asked for and refused (door open " + this.cellsOpened() + ", band " + this.m.Band + ", granted=" + this.m.Granted + "); nothing set.");
			return key;
		}
		this.setGrant(C.GrantCells);
		this.setGrant(C.GrantBurialOwed);
		this.m.Clues = this.m.Clues | C.ClueBurial;
		local rows = [ this.goodRow("His bones and his letter were wrapped in a cloak for the road home") ];
		::logInfo("Skv.Delve: THE BURIAL taken: the bones go home, " + this.burialFee() + " crowns owed at the return (" + ::World.Assets.getMoney() + " held now) -> clues=" + this.m.Clues + " granted=" + this.m.Granted);
		this.closeRoom(_i, false, rows);
		return key;
	}

	function leaveEnvoy( _i )
	{
		if (!this.roomDone(_i) && !this.roomPassed(_i)) this.closeRoom(_i, false, []);
		return this.onward();
	}

	function bundleShelves( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if (this.hasGrant(C.GrantShelves) || this.hasGrant(C.GrantShelvesLeft))
		{
			::logInfo("Skv.Delve: the agreements on the shelves were asked for again and are settled (granted=" + this.m.Granted + "); nothing happens.");
			return key;
		}
		if (!this.princeClaims())
		{
			this.setGrant(C.GrantShelvesLeft);
			this.m.Rows = [ this.badRow("Nobody will buy them, so the bundle stays on its shelf") ];
			::logInfo("Skv.Delve: THE SHELVES left: the trade prince was refused (riders=" + this.m.Riders + ") -> granted=" + this.m.Granted);
			return key;
		}
		this.setGrant(C.GrantShelves);
		local rows = [];
		this.addPapers(C.PapersShelves, rows);
		this.m.Rows = rows;
		::logInfo("Skv.Delve: THE SHELVES bundled -> papers=" + this.m.Papers + " granted=" + this.m.Granted);
		return key;
	}

	function readSheet( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if ((this.m.Clues & C.ClueSheet) != 0) return key;
		local rows = [];
		if (!this.canRead())
		{
			if (this.readTried("archive"))
			{
				::logInfo("Skv.Delve: the archive's read button with script=" + this.m.Script + " words=" + this.m.Words + " (tried here and failed); nothing happens.");
				return key;
			}
			this.readAt("archive", rows);
		}
		else rows.push(this.goodRow(this.m.Script == C.ScriptList ? "The clerk's list was enough to read the sheets" : this.readerName() + " read the sheets"));
		if (this.canRead())
		{
			this.m.Clues = this.m.Clues | C.ClueSheet;
			::logInfo("Skv.Delve: THE SHEET read (script=" + this.m.Script + ") -> clues=" + this.m.Clues);
		}
		this.m.Rows = rows;
		return key;
	}

	function leaveArchive( _i )
	{
		if (!this.roomDone(_i) && !this.roomPassed(_i)) this.closeRoom(_i, false, []);
		return this.onward();
	}

	function passRoom( _i )
	{
		if (!this.roomDone(_i) && !this.roomPassed(_i)) this.closeRoom(_i, true, []);
		return this.onward();
	}

	function burnBit( _i )
	{
		local C = ::Const.Skv.Delve;
		return _i == C.RoomWebs ? C.BurnWebs : C.BurnHeap;
	}

	function fireHeld()
	{
		foreach (k in ::Const.Skv.Kinds.Fire)
		{
			if (::Skv.Held.has(k.ID, "Skv.Delve", k.Ammo)) return k;
		}
		return null;
	}

	function burnText( _i )
	{
		local t = _i == ::Const.Skv.Delve.RoomWebs ? "Burn the webs first." : "Burn it from the door.";
		local k = this.fireHeld();
		return k != null ? "{" + t + " (spends 1 " + k.Name + ")}" : "{" + t + " (no Alchemist's Fire or Fire Pot)}";
	}

	function burnRoom( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;

		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		local bit = this.burnBit(_i);
		if ((this.m.Burn & bit) == 0)
		{
			local k = this.fireHeld();
			local f = k != null ? ::Skv.Held.spend(k.ID, "Skv.Delve", k.Ammo) : null;
			if (f == null)
			{
				::logInfo("Skv.Delve: BURN at " + key + " asked for and no alchemist's fire or fire pot could be spent; nothing happens.");
				return key;
			}
			this.m.Burn = this.m.Burn | bit;
			local next = this.fireHeld();
			::logInfo("Skv.Delve: BURN at " + key + ": one " + k.Name + " spent from " + ::Skv.Held.whereOf(f)
				+ " -> burn=" + this.m.Burn + "; " + (next != null ? "next: " + next.Name : "no fire left"));
		}
		return this.fightRoom(_i);
	}

	function roomLoot( _i, _rows )
	{
		local C = ::Const.Skv.Delve;
		if (_i == C.RoomWebs) this.webLoot(_rows);
		else if (_i == C.RoomBones) this.boneLoot(_rows);
		else if (_i == C.RoomRefuse) this.heapLoot(_rows);

		else if (_i == C.RoomGallery) this.giveBags(_rows);
		else if (_i == C.RoomFlame) this.altarLoot(_rows);
	}

	function webLoot( _rows )
	{
		local C = ::Const.Skv.Delve;
		local burned = (this.m.Burn & C.BurnWebs) != 0;
		if (burned)
		{
			_rows.push(this.goodRow("Fewer spiders came out of the smoke"));
			_rows.push(this.goodRow("Nothing dropped on you from above"));
		}
		this.m.Clues = this.m.Clues | C.ClueKobolds;
		_rows.push(this.goodRow(burned ? "The bodies burned in the webs were kobolds" : "The bodies wrapped in the webs were kobolds"));
		if (this.hasGrant(C.GrantWebs))
		{
			::logInfo("Skv.Delve: the webs' purse was already settled (granted=" + this.m.Granted + "); not again. clues=" + this.m.Clues);
			return;
		}
		this.setGrant(C.GrantWebs);
		local paid = 0;
		if (burned) _rows.push(this.badRow("A purse had burned with one of the bodies, and its coins were lost"));
		else
		{
			_rows.push(this.goodRow("One of them still carried a purse"));
			paid = this.coin(this.feeShare(C.WebPurseMult), _rows);
		}
		::logInfo("Skv.Delve: THE WEBS " + (burned ? "BURNED: the purse lost" : "CUT: the purse paid " + paid) + " -> clues=" + this.m.Clues + " granted=" + this.m.Granted);
	}

	function boneLoot( _rows )
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Way == C.WayCave) _rows.push(this.goodRow("You came in behind them, and fewer of the dead rose in time"));
		if (this.hasGrant(C.GrantBones))
		{
			::logInfo("Skv.Delve: the bone hall's loot was already granted (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantBones);
		this.give(C.BonesItems, _rows, [ "Shortsword" ]);
		::logInfo("Skv.Delve: THE BONE HALL searched (way " + this.m.Way + ") -> granted=" + this.m.Granted);
	}

	function heapLoot( _rows )
	{
		local C = ::Const.Skv.Delve;
		local burned = (this.m.Burn & C.BurnHeap) != 0;
		if (burned) _rows.push(this.goodRow("Fewer rats came out of the burning heap"));
		if (this.hasGrant(C.GrantRefuse))
		{
			::logInfo("Skv.Delve: the heap's loot was already granted (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantRefuse);
		this.give(C.RefuseItems, _rows);
		if (!burned) this.addPapers(C.PapersHeap, _rows);
		else if (this.princeClaims()) _rows.push(this.badRow("A bundle of old papers in the heap had burned to black scraps"));
		::logInfo("Skv.Delve: THE HEAP " + (burned ? "BURNED: its " + C.PapersHeap + " papers lost" : "TURNED OVER") + " -> papers=" + this.m.Papers + " granted=" + this.m.Granted);
	}

	function searchStores( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		local rows = [];

		local trap = this.m.Burn & (C.BurnTrapPass | C.BurnTrapFail);
		if (trap == 0)
		{
			local t = ::Skv.Check.reflex(this, this.sb(C.StoresTrapBase));
			this.m.Burn = this.m.Burn | (t.ok ? C.BurnTrapPass : C.BurnTrapFail);
			if (t.ok)
			{
				rows.push(this.goodRow(this.actorName(t) + " felt a wire pull tight between the boxes and jumped back as a rack of sharpened stakes came down"));
				rows.extend(::Skv.XP.check(t));
			}
			else
			{
				rows.push(this.badRow("A wire between the boxes brought a rack of sharpened stakes down on " + this.actorName(t, true) + ", and the stakes had been smeared with filth"));
				rows.extend(this.hurtOne(t, C.StoresTrapHurtMin, C.StoresTrapHurtMax));
				local bro = ("actor" in t) ? t.actor : null;
				if (bro != null) this.sicken([ { bro = bro } ], rows);
				else ::logError("Skv.Delve: the stake trap failed with no man named; nobody is made sick.");
			}
			::logInfo("Skv.Delve: THE STAKE TRAP: base " + this.sb(C.StoresTrapBase) + " chance " + t.chance + " roll " + t.roll + " " + (t.ok ? "PASS" : "FAIL")
				+ " by " + this.actorName(t) + " -> burn=" + this.m.Burn);
		}
		else
		{
			rows.push((trap & C.BurnTrapPass) != 0 ? this.goodRow("The kobolds' stakes had already been found")
				: this.badRow("Someone had already sprung the kobolds' stakes"));
			::logInfo("Skv.Delve: the stake trap was already rolled (burn=" + this.m.Burn + "); no second roll.");
		}
		local mark = this.m.Burn & (C.BurnBottlesPass | C.BurnBottlesFail);
		if (mark == 0)
		{
			local r = ::Skv.Check.perception(this, this.sb(C.BottlesBase));
			this.m.Burn = this.m.Burn | (r.ok ? C.BurnBottlesPass : C.BurnBottlesFail);
			local who = this.actorName(r);
			if (r.ok)
			{
				rows.push(this.goodRow(who + " smelled lamp oil in two of the bottles, not drink"));
				rows.extend(::Skv.XP.check(r));
			}
			else
			{
				rows.push(this.badRow(who + " drank from the wrong bottle, and it was lamp oil, not drink"));
				rows.extend(this.hurtOne(r, C.BottleHurtMin, C.BottleHurtMax));
			}
			::logInfo("Skv.Delve: THE BOTTLES: base " + this.sb(C.BottlesBase) + " chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS" : "FAIL")
				+ " by " + who + " -> burn=" + this.m.Burn);
		}
		else
		{
			rows.push((mark & C.BurnBottlesPass) != 0 ? this.goodRow("Two of the bottles had already been found to hold lamp oil")
				: this.badRow("Someone had already tasted the lamp oil in the wrong bottle"));
			::logInfo("Skv.Delve: the bottles' check was already made (burn=" + this.m.Burn + "); no second roll.");
		}
		if (this.hasGrant(C.GrantStores))
			::logInfo("Skv.Delve: the storeroom's finds were already granted (granted=" + this.m.Granted + "); not again.");
		else
		{
			this.setGrant(C.GrantStores);
			this.give(C.StoresItems, rows);
			::logInfo("Skv.Delve: THE STOREROOM searched -> granted=" + this.m.Granted);
		}
		this.closeRoom(_i, false, rows);
		return key;
	}

	function fledRowText( _i )
	{
		local C = ::Const.Skv.Delve;
		if (_i == C.RoomWebs) return "You fled from the spiders in the webs";
		if (_i == C.RoomBones) return "You fled from the dead in the painted hall";
		if (_i == C.RoomRefuse) return "You fled from the rats in the rubbish heap";
		if (_i == C.RoomGallery) return "You fled from the kobolds in the gallery";
		if (_i == C.RoomFlame) return "You fled from the kobolds at the stone dragon";
		::logError("Skv.Delve: fledRowText(" + _i + ") is no fight room; a plain row stands in.");
		return "You fled from the fight";
	}

	function passageFee()
	{
		local C = ::Const.Skv.Delve;
		return ::Math.max(C.PassageMin, this.feeShare(C.PassageMult));
	}

	function parleyAnchor()
	{
		local C = ::Const.Skv.Delve;
		return this.sb(C.ParleyBase) + C.SpokenBonus * this.spoken()
			+ ((this.m.Clues & C.ClueHerWord) != 0 ? C.ClueBonus : 0)
			+ ((this.m.Clues & C.ClueKobolds) != 0 ? C.ClueBonus : 0);
	}

	function openParley( _i )
	{
		local C = ::Const.Skv.Delve;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if (this.m.Tarka != C.TarkaUnmet)
		{
			::logInfo("Skv.Delve: the talk in the gallery was asked for with tarka=" + this.m.Tarka + " (a fight came first): no second talk.");
			return C.Rooms[_i].Key;
		}
		this.m.Rows = [];
		return "Parley";
	}

	function giveBags( _rows )
	{
		local C = ::Const.Skv.Delve;
		if (this.hasGrant(C.GrantBags))
		{
			::logInfo("Skv.Delve: her bags were already granted (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantBags);
		this.give(C.BagsItems, _rows);
		::logInfo("Skv.Delve: HER BAGS granted (tarka=" + this.m.Tarka + ") -> granted=" + this.m.Granted);
	}

	function talkTarka()
	{
		local C = ::Const.Skv.Delve;
		local i = C.RoomGallery;
		if (this.roomDone(i) || this.roomPassed(i)) return this.leaveRoom(i);
		if (this.m.Tarka != C.TarkaUnmet)
		{
			::logInfo("Skv.Delve: the talk was asked for with tarka=" + this.m.Tarka + "; no second roll.");
			return "Parley";
		}
		if (this.hasGrant(C.GrantParley))
			::logInfo("Skv.Delve: the parley was settled once before (granted=" + this.m.Granted + "), and she is unmet again (a jump back): the talk again.");
		this.setGrant(C.GrantParley);
		local anchor = this.parleyAnchor();
		local r = ::Skv.Check.charm(this, anchor);
		local who = this.actorName(r);
		local rows = [];
		if (r.ok)
		{
			this.m.Tarka = C.TarkaWon;
			rows.push(this.goodRow(who + " won her over"));
			rows.extend(::Skv.XP.check(r));
			rows.push(this.goodRow("Her band would go with you to the red light"));
			this.giveBags(rows);
			this.closeRoom(i, false, rows);
		}
		else if (r.roll <= r.chance + C.LittleMargin)
		{
			this.m.Tarka = C.TarkaLittle;
			rows.push(this.goodRow(who + " talked her into letting you pass"));
			rows.push(this.badRow("She would not help you any further"));
			this.closeRoom(i, false, rows);
		}
		else
		{
			this.m.Tarka = C.TarkaBotched;
			if (this.m.Alert == 0) this.m.Alert = C.CultAlert;
			else ::logInfo("Skv.Delve: a botched talk found the cult already warned (alert=" + this.m.Alert + ", a hand-set state); kept, not added again.");
			rows.push(this.badRow(who + " said the wrong thing, and the talk was over"));
			rows.push(this.badRow("One of them ran deeper into the keep to raise the alarm"));
			this.m.Rows = rows;
		}
		::logInfo("Skv.Delve: THE TALK with her: base " + anchor + " (sb " + this.sb(C.ParleyBase) + ", spoken " + this.spoken() + " x" + C.SpokenBonus
			+ ", her word " + ((this.m.Clues & C.ClueHerWord) != 0) + ", the wrapped kobolds " + ((this.m.Clues & C.ClueKobolds) != 0) + ", +" + C.ClueBonus + " each)"
			+ " chance " + r.chance + " roll " + r.roll + " (a little up to " + (r.chance + C.LittleMargin) + ") by " + who
			+ " -> " + (this.m.Tarka == C.TarkaWon ? "WON OVER" : (this.m.Tarka == C.TarkaLittle ? "A LITTLE" : "BOTCHED"))
			+ " tarka=" + this.m.Tarka + " alert=" + this.m.Alert + " granted=" + this.m.Granted);
		return "Parley";
	}

	function payPassage()
	{
		local C = ::Const.Skv.Delve;
		local i = C.RoomGallery;
		if (this.roomDone(i) || this.roomPassed(i)) return this.leaveRoom(i);
		local fee = this.passageFee();
		local money = ::World.Assets.getMoney();
		if (this.m.Tarka != C.TarkaUnmet || money < fee)
		{
			::logInfo("Skv.Delve: passage was asked for and refused (tarka=" + this.m.Tarka + ", " + money + " crowns held, " + fee + " asked); nothing taken.");
			return "Parley";
		}
		if (this.hasGrant(C.GrantParley))
			::logInfo("Skv.Delve: the parley was settled once before (granted=" + this.m.Granted + "), and she is unmet again (a jump back): passage paid again.");
		this.setGrant(C.GrantParley);
		this.m.Tarka = C.TarkaPaid;
		::World.Assets.addMoney(-fee);
		local rows = [
			{ id = 1, icon = "ui/icons/asset_money.png", text = "You pay " + ::MSU.Text.color(::Const.UI.Color.NegativeEventValue, fee) + " Crowns" },
			this.goodRow("The kobolds let you pass")
		];
		::logInfo("Skv.Delve: PASSAGE PAID: " + fee + " crowns (" + money + " held before) -> tarka=" + this.m.Tarka + " granted=" + this.m.Granted);
		this.closeRoom(i, false, rows);
		return "Parley";
	}

	function altarLoot( _rows, _why = "The offerings on their altar were yours to take" )
	{
		local C = ::Const.Skv.Delve;
		if (this.hasGrant(C.GrantAltar))
		{
			::logInfo("Skv.Delve: the altar's offerings were already taken (granted=" + this.m.Granted + "); not again.");
			return;
		}
		this.setGrant(C.GrantAltar);
		_rows.push(this.goodRow(_why));
		local paid = this.coin(this.feeShare(C.AltarMult), _rows);
		::logInfo("Skv.Delve: THE ALTAR's offerings taken with no moral cost (cult=" + this.m.Cult + "): " + paid + " crowns -> granted=" + this.m.Granted);
	}

	function speakFlame( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if (!this.canRead())
		{
			::logInfo("Skv.Delve: the word at the flame was asked for and nobody can read it; nothing happens.");
			return key;
		}
		if (this.spokeAt(C.WordFire))
		{
			::logInfo("Skv.Delve: the word at the flame was already spoken (cult=" + this.m.Cult + "); no second roll.");
			return this.cultState() == C.CultUnmaskedFought ? "Unmasked" : key;
		}
		local fled = this.cultState() == C.CultFled;
		this.m.Words = this.m.Words | C.WordFire;
		if (fled)
		{
			if (this.m.Alert == 0) this.m.Alert = C.CultAlert;
			else ::logInfo("Skv.Delve: the word after a fled fight at the flame found the cult already warned (alert=" + this.m.Alert + "); kept, not added again.");
		}
		local rows = [ this.goodRow("The kobolds watched their god answer to you") ];
		if (this.cultStandsDown())
		{
			this.m.Cult = (this.m.Cult & 0xF0) | C.CultAside;
			rows.push(this.goodRow("The kobolds stood aside, and the voice behind the dragon had nowhere left to hide"));
			::logInfo("Skv.Delve: THE WORD SPOKEN at the flame with her band (no check) -> cult=" + this.m.Cult + " words=" + this.m.Words);
			this.closeRoom(_i, false, rows);
			return "Unmasked";
		}
		local anchor = this.sb(C.UnmaskBase) + C.SpokenBonus * this.spoken() + (this.tarkaLittle() ? C.ClueBonus : 0);
		local r = ::Skv.Check.charm(this, anchor);
		local who = this.actorName(r);
		if (r.ok)
		{
			this.m.Cult = (this.m.Cult & 0xF0) | C.CultAside;
			rows.push(this.goodRow(who + " talked them into standing aside"));
			rows.extend(::Skv.XP.check(r));
			this.closeRoom(_i, false, rows);
		}
		else
		{
			this.m.Cult = (this.m.Cult & 0xF0) | C.CultUnmaskedFought;
			rows.push(this.badRow(who + " could not talk them out of a fight"));
			rows.push(this.goodRow("They had lost faith in their god, and fewer of them stood up to fight"));
			rows.push(this.goodRow("The thin voice behind the dragon had nowhere left to hide"));
			this.m.Rows = rows;
		}
		::logInfo("Skv.Delve: THE UNMASKING: base " + anchor + " (sb " + this.sb(C.UnmaskBase) + ", spoken " + this.spoken() + " x" + C.SpokenBonus
			+ ", a little or paid " + this.tarkaLittle() + " +" + C.ClueBonus + ", after a fled fight " + fled + ") chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS" : "FAIL") + " by " + who
			+ " -> cult=" + this.m.Cult + " words=" + this.m.Words + " alert=" + this.m.Alert);
		return "Unmasked";
	}

	function chargeIn( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if (this.cultStandsDown())
		{
			::logInfo("Skv.Delve: [Attack.] at the flame with her band beside you (tarka=" + this.m.Tarka + "); nothing happens.");
			return key;
		}

		if (this.cultState() == C.CultUnmaskedFought) return this.fightRoom(_i);
		local rows = [];
		if ((this.m.Cult & C.CultBreath) == 0)
		{
			this.m.Cult = this.m.Cult | C.CultBreath;
			local r = ::Skv.Check.reflex(this, this.sb(C.BreathBase));
			if (r.ok)
			{
				rows.push(this.goodRow(this.actorName(r) + " saw the dragon's breath coming, and it caught nobody"));
				rows.extend(::Skv.XP.check(r));
			}
			else
			{
				rows.push(this.badRow("The dragon's breath caught " + this.actorName(r, true)));
				rows.extend(this.hurtOne(r, C.BadHurtMin, C.BadHurtMax));
			}
			::logInfo("Skv.Delve: THE BREATH: base " + this.sb(C.BreathBase) + " chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS" : "FAIL") + " by " + this.actorName(r) + " -> cult=" + this.m.Cult);
		}
		else ::logInfo("Skv.Delve: the breath was already rolled (cult=" + this.m.Cult + "); no second roll.");
		this.m.Rows = rows;
		return "Charge";
	}

	function dragOut( _i )
	{
		local C = ::Const.Skv.Delve;
		local key = C.Rooms[_i].Key;
		if (this.roomDone(_i) || this.roomPassed(_i))
		{
			local st = this.cultState();
			return (st == C.CultDragged || st == C.CultDragFail) ? "Dragged" : this.leaveRoom(_i);
		}
		if (!this.cultStandsDown())
		{
			::logInfo("Skv.Delve: [Drag him out.] without her band (tarka=" + this.m.Tarka + "); nothing happens.");
			return key;
		}
		local r = ::Skv.Check.brawn(this, this.sb(C.DragBase));
		local who = this.actorName(r);
		local rows = [];
		if (r.ok)
		{
			this.m.Cult = (this.m.Cult & 0xF0) | C.CultDragged;
			rows.push(this.goodRow(who + " dragged him out from behind the dragon"));
			rows.extend(::Skv.XP.check(r));
			this.altarLoot(rows, "The kobolds kept their god, and gave you the offerings from its altar");
		}
		else
		{
			this.m.Cult = (this.m.Cult & 0xF0) | C.CultDragFail;
			rows.push(this.badRow("The dragon's breath caught " + this.actorName(r, true) + ", who still dragged him out"));
			rows.extend(this.hurtOne(r, C.BadHurtMin, C.BadHurtMax));
		}
		::logInfo("Skv.Delve: THE DRAG: base " + this.sb(C.DragBase) + " chance " + r.chance + " roll " + r.roll + " " + (r.ok ? "PASS" : "FAIL") + " by " + who
			+ " -> cult=" + this.m.Cult + " granted=" + this.m.Granted);
		this.closeRoom(_i, false, rows);
		return "Dragged";
	}

	function takeAltar()
	{
		local C = ::Const.Skv.Delve;
		if (this.cultState() != C.CultAside || !this.ruthlessOK() || this.hasGrant(C.GrantAltar))
		{
			::logInfo("Skv.Delve: the altar's coin was asked for and refused (cult=" + this.m.Cult + ", band " + this.m.Band + ", granted=" + this.m.Granted + "); nothing taken.");
			return "Unmasked";
		}
		this.setGrant(C.GrantAltar);
		local rows = this.m.Rows == null ? [] : clone this.m.Rows;
		local paid = this.coin(this.feeShare(C.AltarMult), rows);
		this.moral(C.AltarMoral, "You robbed the kobolds' altar of its offerings", rows);
		this.m.Rows = rows;
		::logInfo("Skv.Delve: THE ALTAR ROBBED: " + paid + " crowns -> granted=" + this.m.Granted);
		return "Unmasked";
	}

	function leaveRoom( _i )
	{
		return this.onward();
	}

	function flameNext()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Speaker == C.SpeakerUnmet)
		{
			this.m.Speaker = this.speakerEscapes() ? C.SpeakerOnRope : C.SpeakerCornered;
			::logInfo("Skv.Delve: THE SPEAKER " + (this.m.Speaker == C.SpeakerOnRope ? "is down the shaft on a rope" : "is cornered")
				+ " (cult=" + this.m.Cult + " tarka=" + this.m.Tarka + ") -> speaker=" + this.m.Speaker);
		}
		if (this.m.Speaker == C.SpeakerOnRope) return "Rope";
		if (this.m.Speaker == C.SpeakerCornered) return "Cornered";

		if (!this.swordHeld())
		{
			::logError("Skv.Delve: the Speaker's fate is decided (speaker " + this.m.Speaker + ") and the sword is not held; it is taken now.");
			this.m.Sword = C.SwordHeld;
		}
		return "Sword";
	}

	function resolveSpeaker( _how )
	{
		local C = ::Const.Skv.Delve;
		local was = this.m.Speaker;
		if (was == C.SpeakerUnmet)
		{
			::logError("Skv.Delve: his fate was asked for (" + _how + ") before he was met (speaker 0); his screen by the saved fields.");
			return this.flameNext();
		}
		if (was != C.SpeakerCornered && was != C.SpeakerOnRope)
		{
			::logInfo("Skv.Delve: his fate is already decided (speaker " + was + "); the sword.");
			return "Sword";
		}
		local rope = was == C.SpeakerOnRope;
		local ok = rope ? (_how == C.SpeakerBargain || (_how == C.SpeakerCut && this.ruthlessOK()))
			: (_how == C.SpeakerSpared || (_how == C.SpeakerGiven && this.koboldsJudge()) || (_how == C.SpeakerKilled && this.ruthlessOK()));
		if (!ok)
		{
			::logInfo("Skv.Delve: his fate " + _how + " is not offered here (speaker " + was + ", band " + this.m.Band + ", cult " + this.m.Cult + "); nothing happens.");
			return rope ? "Rope" : "Cornered";
		}
		this.m.Speaker = _how;
		this.m.Sword = C.SwordHeld;
		local rows = [];
		if (this.hasGrant(C.GrantSpeaker))
		{
			::logInfo("Skv.Delve: his hoard was already granted (granted=" + this.m.Granted + ", a jump back); the sword only, nothing paid again.");
		}
		else
		{
			this.setGrant(C.GrantSpeaker);
			if (_how == C.SpeakerBargain)
			{

				rows.push(this.goodRow("He sent the sword up on the rope, then his heavy book so that he could climb lighter, and went down into the dark with the rest of his bundle"));
				this.give(C.RopeItems, rows);
			}
			else if (_how == C.SpeakerCut)
			{
				rows.push(this.badRow("He fell into the shallow stream below, and did not get up"));
				rows.push(this.goodRow("You pulled the sword and his bundle out of the water"));
				this.give(C.HoardAll, rows);
				this.coin(this.hoardPay(), rows);
				this.moral(C.KillMoral, "You cut the rope while he hung helpless below you", rows);
			}
			else if (_how == C.SpeakerSpared)
			{
				rows.push(this.goodRow("He gave up the sword, his purse and the bottles on his belt, and climbed down the well"));
				this.give(C.HoardSpared, rows);
				this.coin(this.pursePay(), rows);
			}
			else if (_how == C.SpeakerGiven)
			{
				rows.push(this.goodRow("The kobolds took him away, and brought you the one thing of his they had no use for"));
				this.give(C.HoardKobolds, rows);
			}
			else
			{
				rows.push(this.goodRow("You took his belt, his purse, a heavy book, and the coin he had hidden behind the dragon"));
				this.give(C.HoardAll, rows);
				this.coin(this.hoardPay(), rows);
				this.moral(C.KillMoral, "You killed him while he begged for his life", rows);
			}
		}
		this.m.Rows = rows;
		this.updateObjectives();
		::logInfo("Skv.Delve: THE SWORD IS OURS. speaker " + was + " -> " + this.m.Speaker + " (3 spared, 4 killed, 5 given to the kobolds, 6 the rope bargain, 7 the rope cut) sword=" + this.m.Sword
			+ " cult=" + this.m.Cult + " tarka=" + this.m.Tarka + " band=" + this.m.Band + " purse " + this.pursePay() + " hoard " + this.hoardPay() + " granted=" + this.m.Granted);
		return "Sword";
	}

	function searchHilt()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Sword != C.SwordHeld)
		{
			::logInfo("Skv.Delve: the hilt was asked for with sword " + this.m.Sword + " (searched already, or not held); no second roll.");
			return "Sword";
		}
		if ((this.m.Clues & C.ClueSheet) == 0)
		{

			if (!this.hasGrant(C.GrantHiltLeft))
			{
				this.setGrant(C.GrantHiltLeft);
				if (this.m.Rows == null) this.m.Rows = [];
				this.m.Rows.push(this.badRow("Nothing said the sword hid anything, so you left the hilt as it was"));
			}
			::logInfo("Skv.Delve: the hilt was asked for and nothing says there is a hiding place (clues=" + this.m.Clues + "); the button goes (granted=" + this.m.Granted + ").");
			return "Sword";
		}
		this.m.Sword = C.SwordSearched;
		local seal = (this.m.Clues & C.ClueSeal) != 0;
		local hunch = (this.m.Clues & C.ClueGarden) != 0;
		local anchor = this.sb(C.HiltBase) + (seal ? C.ClueBonus : 0) + (hunch ? C.ClueBonus : 0);
		local r = ::Skv.Check.secretDoor(this, anchor);
		local rows = this.m.Rows == null ? [] : clone this.m.Rows;
		if (r.ok)
		{
			this.m.Sword = C.SwordPaper;
			rows.push(this.goodRow(this.actorName(r) + " found a hollow in the hilt, with a rolled paper inside"));
			rows.extend(::Skv.XP.check(r));
			if (this.canRead())
			{
				rows.push(this.goodRow(this.m.Script == C.ScriptList ? "With the clerk's list you could read the half written in the old southern script"
					: this.readerName() + " read the half written in the old southern script"));
				rows.push(this.goodRow("The Way of the Kirin promised ships and supplies for war to whoever held it"));
			}
			else rows.push(this.badRow("It was written in two scripts, and nobody could read either"));
		}
		else rows.push(this.badRow("Nobody found a hiding place in it"));
		this.m.Rows = rows;
		::logInfo("Skv.Delve: THE HILT: secretDoor base " + anchor + " (sb " + this.sb(C.HiltBase) + ", the seal " + seal + ", the garden " + hunch + ", +" + C.ClueBonus + " each) chance " + r.chance
			+ " roll " + r.roll + " " + (r.ok ? "PASS by " + this.actorName(r) : "FAIL") + " -> sword=" + this.m.Sword + " script=" + this.m.Script);
		return "Sword";
	}

	function wayOut()
	{
		this.m.Rows = [];
		return this.betrayalDue(true) ? "Ambush" : "WayOut";
	}

	function goHome()
	{
		local C = ::Const.Skv.Delve;
		this.m.Act = C.ActHome;
		this.m.Rows = [];
		this.updateObjectives();
		this.setRings();
		::logInfo("Skv.Delve: HEADING HOME -> act " + this.m.Act + " sword=" + this.m.Sword + " ending=" + this.m.Ending
			+ " maurit=" + this.m.Maurit + " fights won/fled=" + this.wonInside() + "/" + this.fledCount() + " golem=" + this.m.Golem);
		return this.closeAtSite();
	}

	function giveUp()
	{
		local C = ::Const.Skv.Delve;
		if (!this.canGiveUp())
		{
			::logError("Skv.Delve: the give-up was pressed where it is not allowed (fled " + this.fledCount() + ", sword " + this.m.Sword + ", ending " + this.m.Ending + "); nothing happens.");
			return this.atSite() ? this.siteScreen() : this.closeAtSite();
		}
		this.m.Ending = C.EndGaveUp;
		::logInfo("Skv.Delve: THE SWORD GIVEN UP -> ending " + this.m.Ending);
		return this.goHome();
	}

	function agreementsText( _n ) { return _n == 1 ? "1 old trade agreement" : _n + " old trade agreements"; }

	function finishPaid()
	{
		local C = ::Const.Skv.Delve;
		if (this.m.Ending == C.EndNone)
		{
			this.m.Ending = this.swordHeld() ? C.EndUnknowing : C.EndGaveUp;
			::logError("Skv.Delve: the return was paid with no ending saved (granted=" + this.m.Granted + ", a jump?); recorded as " + this.m.Ending + ".");
		}
		this.m.Act = C.ActPaid;
		this.m.Rows = [];
		return this.finish();
	}

	function claimPaper( _how )
	{
		local C = ::Const.Skv.Delve;
		if (this.hasGrant(C.GrantClaim))
		{
			::logInfo("Skv.Delve: the steward was already answered (ending " + this.m.Ending + ", granted=" + this.m.Granted + "); nothing again.");
			return "Claim";
		}
		if (!this.swordHeld() || !this.princeClaims())
		{
			::logError("Skv.Delve: the steward's claim with sword " + this.m.Sword + " and riders " + this.m.Riders + "; the return's screen by the saved fields.");
			return this.returnScreen();
		}
		local ok = _how == C.EndPrince || (_how == C.EndDebt && this.kindOK()) || (_how == C.EndKept && this.ruthlessOK());
		if (!ok)
		{
			::logInfo("Skv.Delve: the answer " + _how + " to the steward is not offered to band " + this.m.Band + "; nothing happens.");
			return "Claim";
		}
		this.setGrant(C.GrantClaim);
		local opened = this.m.Sword != C.SwordPaper;
		if (opened) this.m.Clues = this.m.Clues | C.CluePrince;
		this.m.Ending = _how;
		local n = this.m.Papers;
		local rows = [];
		local paid = 0;
		if (_how == C.EndPrince)
		{
			if (n > 0)
			{
				rows.push(this.goodRow("The steward paid for " + this.agreementsText(n)));
				paid = paid + this.coin(this.paperPay(false), rows);
			}
			rows.push(this.goodRow("The steward paid for the paper from the hilt"));
			paid = paid + this.coin(this.docPay(), rows);
			this.moral(C.EndPrinceMoral, "You sold your employer's secret to the trade prince", rows);
		}
		else
		{
			if (n > 0)
			{

				local half = this.paperPay(true);
				rows.push(this.badRow(half > 0 ? "The steward paid only half for " + this.agreementsText(n) : "The steward paid nothing for the agreements"));
				paid = paid + this.coin(half, rows);
			}
			if (_how == C.EndKept)
			{
				this.give(C.LetterItems, rows);
				this.m.Sword = C.SwordTaken;
				this.moral(C.EndKeptMoral, "You kept what you were sent to fetch", rows);
			}
			this.moral(C.BrokenWordMoral, "You broke your word to the trade prince", rows);
		}
		this.m.Rows = rows;
		::logInfo("Skv.Delve: THE CLAIM answered: ending " + _how + " (3 sold, 1 to her, 4 kept) papers " + n + " paid " + paid + " (full " + this.paperPay(false) + ", half " + this.paperPay(true)
			+ ", the paper " + this.docPay() + ") opened by the steward " + opened + " -> sword=" + this.m.Sword + " clues=" + this.m.Clues + " granted=" + this.m.Granted);
		return "Claim";
	}

	function leaveClaim()
	{
		local C = ::Const.Skv.Delve;
		if (!this.hasGrant(C.GrantClaim))
		{
			::logInfo("Skv.Delve: the steward's screen was left unanswered (a stale button); it stays.");
			return "Claim";
		}
		this.m.Rows = [];
		local n = this.returnNext();
		return n == null ? this.finishPaid() : n;
	}

	function giveAmara( _how )
	{
		local C = ::Const.Skv.Delve;
		local A = ::Const.World.Assets;
		if (this.hasGrant(C.GrantAmara))
		{
			::logInfo("Skv.Delve: Amara was already paid (ending " + this.m.Ending + ", granted=" + this.m.Granted + "); nothing again.");
			return "Amara";
		}
		if (!this.swordHeld())
		{
			::logError("Skv.Delve: Amara's button with no sword held (sword " + this.m.Sword + "); the return's screen by the saved fields.");
			return this.returnScreen();
		}
		if (this.princeClaims() && !this.hasGrant(C.GrantClaim))
		{
			::logInfo("Skv.Delve: Amara was opened before the trade prince's steward was answered (a save from before stage 2); the steward first.");
			this.m.Rows = [];
			return "Claim";
		}
		local e = this.m.Ending;
		local here = e == C.EndNone;
		if (here)
		{
			if (this.knowsSecret())
			{
				if (_how == C.EndDebt && this.kindOK()) e = C.EndDebt;
				else if (_how == C.EndKept && this.ruthlessOK()) e = C.EndKept;
				else
				{
					::logInfo("Skv.Delve: the answer " + _how + " to Amara is not offered (band " + this.m.Band + ", the secret known); nothing happens.");
					return "Amara";
				}
			}
			else e = C.EndUnknowing;
		}
		this.setGrant(C.GrantAmara);
		this.m.Ending = e;
		local rows = [];
		local paid = this.coin(this.swordPay(), rows);
		local renown = A.ReputationOnContractSuccess + (e == C.EndDebt ? C.DebtRenown : 0);
		::World.Assets.addBusinessReputation(renown);
		rows.push(this.renownRow(renown));
		if (e == C.EndDebt || e == C.EndUnknowing)
		{
			local f = this.factionOr(this.getFaction());
			if (f == null) ::logError("Skv.Delve: the host's faction did not resolve; the relation gain of " + A.RelationNobleContractSuccess + " is lost.");
			else
			{
				f.addPlayerRelation(A.RelationNobleContractSuccess, "Brought back the sword of the Li family");
				rows.push(this.relRow(f.getName(), true));
			}
		}
		if (e == C.EndDebt) this.moral(C.EndDebtMoral, "You gave her the sword as you found it", rows);
		if (e == C.EndKept && here)
		{
			this.give(C.LetterItems, rows);
			this.m.Sword = C.SwordTaken;
			this.moral(C.EndKeptMoral, "You kept what you were sent to fetch", rows);
		}
		local burialPaid = 0;
		if ((this.m.Clues & C.ClueBurial) != 0)
		{
			burialPaid = this.payBurial(rows);
			this.moral(C.BurialMoral, "You saw her kinsman buried", rows);
		}
		this.m.Rows = rows;
		::logInfo("Skv.Delve: AMARA PAID: ending " + e + " (1 the debt, 2 unknowing, 3 sold, 4 kept; decided " + (here ? "here" : "at the steward") + ") fee=" + this.fee() + " sword " + paid
			+ " renown " + renown + " relation " + ((e == C.EndDebt || e == C.EndUnknowing) ? A.RelationNobleContractSuccess : 0) + " burial " + ((this.m.Clues & C.ClueBurial) != 0)
			+ " (fee paid " + burialPaid + ") -> sword=" + this.m.Sword + " granted=" + this.m.Granted);
		return "Amara";
	}

	function leaveAmara()
	{
		local C = ::Const.Skv.Delve;
		if (!this.hasGrant(C.GrantAmara))
		{
			::logInfo("Skv.Delve: Amara's screen was left before she was paid (a stale button); it stays.");
			return "Amara";
		}
		this.m.Rows = [];
		local n = this.returnNext();
		return n == null ? this.finishPaid() : n;
	}

	function failedSettle( _apply )
	{
		local C = ::Const.Skv.Delve;
		local A = ::Const.World.Assets;
		local rows = [];
		local papers = this.princeClaims() ? this.paperPay(false) : 0;
		if (papers > 0)
		{
			rows.push(this.goodRow("The trade prince's steward paid for " + this.agreementsText(this.m.Papers)));
			if (_apply) this.coin(papers, rows);
			else rows.push(this.moneyRow(papers));
		}
		if (_apply) ::World.Assets.addBusinessReputation(A.ReputationOnContractFail);
		rows.push(this.renownRow(A.ReputationOnContractFail));
		if ((this.m.Clues & C.ClueBurial) != 0)
		{
			if (_apply) this.payBurial(rows);
			else if (this.burialOwed()) rows.push(this.burialRow(this.burialDue(papers > 0 ? papers : 0)));
			if (_apply) this.moral(C.BurialMoral, "You saw her kinsman buried", rows);
			else rows.push(this.moralRow(C.BurialMoral, "You saw her kinsman buried"));
		}
		return rows;
	}

	function leaveFailed()
	{
		local C = ::Const.Skv.Delve;
		if (this.swordHeld())
		{
			::logError("Skv.Delve: Failed's button with the sword held (sword " + this.m.Sword + "); the return's screen by the saved fields.");
			return this.returnScreen();
		}
		local papers = 0;
		if (!this.hasGrant(C.GrantAmara))
		{
			this.setGrant(C.GrantAmara);
			papers = this.princeClaims() ? this.paperPay(false) : 0;
			this.failedSettle(true);
		}
		if (this.m.Ending == C.EndNone) this.m.Ending = C.EndGaveUp;
		::logInfo("Skv.Delve: NO SWORD. papers paid " + papers + " renown " + ::Const.World.Assets.ReputationOnContractFail + " burial " + ((this.m.Clues & C.ClueBurial) != 0)
			+ " ending=" + this.m.Ending + " granted=" + this.m.Granted);
		this.m.Rows = [];
		local n = this.returnNext();
		return n == null ? this.finishPaid() : n;
	}

	function majorSettle( _apply )
	{
		local rows = [];
		if (!this.majorOwed()) return rows;
		local d = this.deadPay();
		local b = this.bonePay();
		if (d > 0)
		{
			rows.push(this.goodRow("Major Maldris paid for the dead woman you destroyed"));
			if (_apply) this.coin(d, rows);
			else rows.push(this.moneyRow(d));
		}
		if (b > 0)
		{
			rows.push(this.goodRow("Major Maldris paid for the dead you destroyed in the painted hall"));
			if (_apply) this.coin(b, rows);
			else rows.push(this.moneyRow(b));
		}
		if (d + b == 0) rows.push(this.badRow("Major Maldris paid no bounty"));
		return rows;
	}

	function farewellMajor()
	{
		local C = ::Const.Skv.Delve;
		local paid = 0;
		if (!this.hasGrant(C.GrantMajorEnd))
		{
			this.setGrant(C.GrantMajorEnd);
			paid = this.bountyPay();
			this.majorSettle(true);
		}
		::logInfo("Skv.Delve: THE MAJOR: bounty " + paid + " (word " + this.majorOwed() + ", dead destroyed " + this.deadDestroyed() + ", bone hall cleared " + this.boneHallCleared() + ") granted=" + this.m.Granted);
		local n = this.returnNext();
		if (n != null)
		{
			::logError("Skv.Delve: the Major's farewell with " + n + " still owed (granted=" + this.m.Granted + "); that first.");
			this.m.Rows = [];
			return n;
		}
		return this.finishPaid();
	}

	function fightPlan( _key )
	{
		local C = ::Const.Skv.Delve;
		local D = ::Skv.Delve;
		local dm = this.getDifficultyMult();
		local sc = this.getScaledDifficultyMult();

		if (_key == "Door") return D.ghoulFight(dm, sc, false, false);
		local q = null;
		if (_key == "Ambush") q = D.ghoulFight(dm, sc, true, this.ambushCircle());
		else if (_key == "Webs") q = D.webFight(dm, sc, (this.m.Burn & C.BurnWebs) != 0);
		else if (_key == "Bones") q = D.boneFight(dm, sc, this.m.Way == C.WayCave);
		else if (_key == "Rats") q = D.ratFight(dm, sc, (this.m.Burn & C.BurnHeap) != 0);

		else if (_key == "Gallery") q = D.galleryFight(dm, sc, this.m.Alert > 0);
		else if (_key == "Cult") q = D.cultFight(dm, sc, this.m.Alert, this.cultState() == C.CultUnmaskedFought);
		if (q == null)
		{
			::logError("Skv.Delve: no fight is called '" + _key + "'.");
			return null;
		}

		return D.restocked(q, this.returns());
	}

	function fightKeyOf( _combatID )
	{
		foreach (k, f in ::Const.Skv.Delve.Fights)
		{
			if (f.ID == _combatID) return k;
		}
		return null;
	}

	function roomOfFight( _key )
	{
		foreach (i, r in ::Const.Skv.Delve.Rooms)
		{
			if (r.Fight == _key) return i;
		}
		return null;
	}

	function launch( _key )
	{
		local C = ::Const.Skv.Delve;
		local D = ::Skv.Delve;
		local q = this.fightPlan(_key);
		if (q == null) return false;
		local fac = D.factionOf(q);
		if (fac == 0)
		{
			::logError("Skv.Delve: " + q.ID + " has no faction to fight under; the fight is NOT started.");
			return false;
		}
		local tile = this.siteTile();
		local p = _key == "Door" ? D.gullyArena(q.ID, tile, q.Music) : D.arena(q.ID, tile, q.Circle, q.Music);
		local got = D.fillPlan(p.Entities, q, fac);

		if (_key == "Door" || _key == "Ambush") this.setNamed(C.NamedPackShift, got.Named);
		else if (_key == "Gallery") this.setNamed(C.NamedGalleryShift, got.Named);
		local stood = false;
		if (this.servantIn(_key))
		{
			stood = D.addServant(p, q);
			if (stood) D.watchArm(p);
			else ::logError("Skv.Delve: the servant should stand in " + q.ID + " and could not be added; its counter is not touched.");
		}
		local F = this.m.Flags;
		F.set("F22", q.ID);
		F.set("V22", "");
		F.set("R22", "");
		F.set("G22", stood ? q.ID : "");
		::logInfo("Skv.Delve: LAUNCH " + q.ID + " (" + _key + ") diff=" + this.getDifficultyMult() + " scaled=" + this.getScaledDifficultyMult()
			+ " fee=" + this.fee() + " way=" + this.m.Way + " room=" + ::Skv.Delve.roomKey(this.m.Pos)
			+ " budget=" + q.Budget + " restock=" + (_key == "Door" ? "never (outside the keep)" : "x" + D.restockMult(this.returns()) + " (" + this.returns() + " returns)")
			+ " units=" + got.Units + " named=" + got.Named + " field=" + (_key == "Door" ? "the gully (outdoors)" : "indoors")
			+ " deploy=" + (p.EnemyDeploymentType == ::Const.Tactical.DeploymentType.Circle ? "Circle" : "Line")
			+ " servant=" + (stood ? "IN (it has " + this.m.Golem + " fights left, this one among them)" : (this.golemJoins() ? "not in this fight (" + this.m.Golem + " left)" : "none"))
			+ " won/fled so far=" + this.wonInside() + "/" + this.fledCount());
		::World.Contracts.startScriptedCombat(p, false, true, true);
		return true;
	}

	function fightRoom( _i )
	{
		local R = ::Const.Skv.Delve.Rooms;

		if (this.roomDone(_i) || this.roomPassed(_i)) return this.leaveRoom(_i);
		if (!this.launch(R[_i].Fight)) return R[_i].Key;
		return 0;
	}

	function afterFight( _combatID, _won, _stood )
	{
		local C = ::Const.Skv.Delve;
		local R = C.Rooms;
		local key = this.fightKeyOf(_combatID);
		if (key == null)
		{
			::logError("Skv.Delve: the fight '" + _combatID + "' resolved and no fight row has that id; back to the hub with no state change.");
			this.m.Rows = [];
			return this.atSite() ? this.siteScreen() : "Fled";
		}
		local rows = [];
		if (_stood)
		{
			local was = this.m.Golem;
			if (this.m.Golem > 0) this.m.Golem = this.m.Golem - 1;
			rows.push(this.goodRow(this.m.Golem > 0 ? "The stone servant fought beside you. It had " + this.m.Golem + (this.m.Golem == 1 ? " fight" : " fights") + " left to give"
				: "The stone servant fought beside you, and went back into the stone"));
			::logInfo("Skv.Delve: the servant stood in " + _combatID + " (" + (_won ? "won" : "fled") + "): golem " + was + " -> " + this.m.Golem);
		}
		if (_won && key != "Door") this.m.Fights = (this.m.Fights & 0xF0) | this.clamp15(this.wonInside() + 1);
		if (!_won) this.m.Fights = (this.m.Fights & 0x0F) | (this.clamp15(this.fledCount() + 1) << 4);

		local next = "Fled";
		if (key == "Door")
		{
			if (_won)
			{

				this.m.Maurit = C.MauritKilled;
				this.m.Clues = this.m.Clues | C.CluePicks;
				this.ensureDeck("the gully won");
				if (this.m.Way == 0) this.m.Way = C.WayDoor;
				this.m.Act = C.ActInside;
				local run = this.runRooms();
				this.m.Pos = run.len() > 0 ? run[0] : 0;
				rows.push(this.goodRow("You took her lock picks"));
				this.grantKit(rows);
				::logInfo("Skv.Delve: THE WAY IN " + ::Skv.Delve.wayLine(this.deck(), this.m.Way, false) + " | deck " + ::Skv.Delve.deckText(this.deck()));
				next = "DoorWon";
			}
			else
			{
				this.m.Maurit = C.MauritFled;
				rows.push(this.badRow("You fled from the pack at the door"));
			}
		}
		else if (key == "Ambush")
		{
			if (_won)
			{
				this.m.Maurit = C.MauritAmbush;
				this.m.Clues = this.m.Clues | C.CluePicks;
				rows.push(this.goodRow("You took her lock picks"));
				this.grantKit(rows);
				next = "AmbushWon";
			}
			else
			{

				this.m.Wary = this.m.Wary | C.WaryFled;
				rows.push(this.badRow("You fled from the dead woman's pack"));
			}
		}
		else
		{
			local i = this.roomOfFight(key);
			if (i == null)
			{
				::logError("Skv.Delve: the fight " + key + " belongs to no room; back to the hub with no room change.");
				this.m.Rows = rows;
				return _won ? this.hubScreen() : "Fled";
			}
			if (_won)
			{
				if (i == C.RoomGallery) this.m.Tarka = C.TarkaBeaten;
				if (i == C.RoomFlame && this.cultState() != C.CultUnmaskedFought) this.m.Cult = (this.m.Cult & 0xF0) | C.CultFought;
				rows.push(this.goodRow("The fight was won"));
				this.roomLoot(i, rows);
				this.closeRoom(i, false, rows);
				next = R[i].Key;
			}
			else
			{
				if (i == C.RoomGallery) this.m.Tarka = C.TarkaFled;
				if (i == C.RoomFlame && this.cultState() != C.CultUnmaskedFought) this.m.Cult = (this.m.Cult & 0xF0) | C.CultFled;
				rows.push(this.badRow(this.fledRowText(i)));
			}
		}
		this.m.Rows = rows;
		this.updateObjectives();
		::logInfo("Skv.Delve: " + _combatID + " " + (_won ? "WON" : "FLED") + " -> " + next + ". act=" + this.m.Act + " maurit=" + this.m.Maurit + " wary=" + this.m.Wary
			+ " way=" + this.m.Way + " rooms=" + this.m.Rooms + " passed=" + this.m.Passed + " fights won/fled=" + this.wonInside() + "/" + this.fledCount()
			+ " golem=" + this.m.Golem + " tarka=" + this.m.Tarka + " cult=" + this.m.Cult + " named=" + this.m.Named
			+ " betrayal due=" + this.betrayalDue(false));
		return next;
	}

	function outcomeOf( _ending )
	{
		local C = ::Const.Skv.Delve;
		if (_ending == C.EndDebt) return C.OutcomeDebt;
		if (_ending == C.EndUnknowing) return C.OutcomeUnknowing;
		if (_ending == C.EndPrince) return C.OutcomePrince;
		if (_ending == C.EndKept) return C.OutcomeKept;
		if (_ending == C.EndGaveUp) return C.OutcomeGaveUp;
		return null;
	}

	function recordOutcome( _v )
	{
		local C = ::Const.Skv.Delve;
		::World.Flags.set(C.ArcFlagOutcome, _v);
		::logInfo("Skv.Delve: outcome recorded, " + C.ArcFlagOutcome + "=" + _v
			+ " (" + C.OutcomeDebt + " the sword as it was, " + C.OutcomeUnknowing + " the same, unknowing, " + C.OutcomePrince + " the paper sold, "
			+ C.OutcomeKept + " the paper kept, " + C.OutcomeGaveUp + " gave up, " + C.OutcomeAbandoned + " cancelled or abandoned)");
	}

	function finish()
	{
		local C = ::Const.Skv.Delve;
		::logInfo("Skv.Delve: CLOSED. ending=" + this.m.Ending + " sword=" + this.m.Sword + " speaker=" + this.m.Speaker + " maurit=" + this.m.Maurit
			+ " way=" + this.m.Way + " rooms=" + this.m.Rooms + " passed=" + this.m.Passed + " riders=" + this.m.Riders + " band=" + this.m.Band
			+ " fights won/fled=" + this.wonInside() + "/" + this.fledCount() + " granted=" + this.m.Granted);
		this.m.Rows = [];

		local v = this.outcomeOf(this.m.Ending);
		if (v == null)
			::logError("Skv.Delve: finish() with no ending saved (ending " + this.m.Ending + "); nothing is recorded here, so onClear records it as abandoned.");
		else this.recordOutcome(v);
		::World.Contracts.finishActiveContract(this.m.Ending == C.EndGaveUp);
		return 0;
	}

	function updateObjectives()
	{
		local C = ::Const.Skv.Delve;
		local b = [];
		if (this.m.Act >= C.ActHome)
		{
			b.push(this.swordHeld() ? "Bring the jade sword to Amara Li in " + this.townName()
				: "Return to Amara Li in " + this.townName());
		}
		else
		{
			b.push(this.swordHeld() ? "Leave " + C.SiteName + " with the jade sword" : "Find the jade sword in " + C.SiteName);
			b.push("Return to Amara Li in " + this.townName());
		}
		this.m.BulletpointsObjectives = b;

		::World.Contracts.updateActiveContract();
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_delve";
		this.m.Name = "To Delve the Dungeon Deep";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A lady of the Lantern Lodge wants her family's sword fetched out of a ruin in the hills.",
			"A ruined keep has been found in the hills, and a sword lies in it that one family wants back."
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
		local C = ::Const.Skv.Delve;
		this.m.DifficultyMult = this.Math.rand(C.DiffLo, C.DiffHi) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, C.PayBase);

		this.m.Payment.Advance = 0.0;
		this.m.Payment.Completion = 1.0;

		::logInfo("Skv.Delve: created at " + this.m.Home.getName() + " diff=" + this.m.DifficultyMult
			+ " pool=" + this.m.Payment.Pool + " fee=" + this.fee() + " scaled=" + this.getScaledDifficultyMult()
			+ " (design: fee about 170 / 310 / 440 at DM 0.70 / 0.90 / 1.05, scaled 0.6375 for a fresh company)");
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Find the jade sword in " + ::Const.Skv.Delve.SiteName,
					"Return to Amara Li in " + this.Contract.townName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;

				local adv = c.m.Payment.getInAdvance();
				if (adv > 0)
				{
					::logError("Skv.Delve: an advance of " + adv + " was negotiated although #22 offers none; paid, so the player loses nothing.");
					::World.Assets.addMoney(adv);
				}
				c.m.DayAccepted = ::World.getTime().Days;
				c.m.Act = C.ActRiders;
				c.m.Band = c.readBand();

				try { c.ensureDeck("the accept"); }
				catch (e) { ::logError("Skv.Delve: the deck's draw threw at the accept - " + e); }
				try { c.spawnSite(); }
				catch (e) { ::logError("Skv.Delve: placing the keep threw at the accept (the repair tries again) - " + e); }
				c.updateObjectives();
				::logInfo("Skv.Delve: ACCEPTED day=" + c.m.DayAccepted + " diff=" + c.getDifficultyMult() + " scaled=" + c.getScaledDifficultyMult()
					+ " fee=" + c.fee() + " band=" + c.m.Band + " marker=" + (c.siteLive() ? "placed" : "MISSING")
					+ " deck=" + ::Skv.Delve.deckText(c.deck()));

				::World.Contracts.setActiveContract(c);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				local c = this.Contract;
				c.updateObjectives();
				c.setRings();
			}

			function update()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;

				if (::Skv.Screens.hold(c)) return;

				local f = this.Flags.get("F22");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V22") == f;
					local ran = this.Flags.get("R22") == f;
					local stood = this.Flags.get("G22") == f;
					this.Flags.set("F22", "");
					this.Flags.set("V22", "");
					this.Flags.set("R22", "");
					this.Flags.set("G22", "");

					if (!won && !ran)
					{

						::logInfo("Skv.Delve: " + f + " was launched but never resolved - no state change (golem " + c.m.Golem + ").");
						this.TempFlags.set("DelveAtSite", false);
					}
					else
					{

						this.TempFlags.set("DelveAtSite", true);
						local s = c.afterFight(f, won, stood);
						c.setScreen(s);
						::World.Contracts.showActiveContract();
						return;
					}
				}

				if (c.m.Act == C.ActRiders)
				{
					if (c.getActiveScreen() == null)
					{
						local s = c.riderScreen();
						::logInfo("Skv.Delve: act 0 with no screen open -> " + s);
						c.setScreen(s);
						::World.Contracts.showActiveContract();
					}
					return;
				}

				if (c.m.Act >= C.ActHome)
				{
					if (c.getActiveScreen() != null || !c.atHome()) return;
					if (c.m.Act == C.ActHome) c.m.Act = C.ActHost;
					local s = c.returnScreen();
					c.m.Rows = [];
					::logInfo("Skv.Delve: act " + c.m.Act + " at the host with no screen open -> " + s);
					c.setScreen(s);
					::World.Contracts.showActiveContract();
					return;
				}

				if (!c.siteLive())
				{
					local tries = this.TempFlags.get("DelveRepairs");
					if (typeof tries != "integer") tries = 0;
					if (tries < C.RepairTries)
					{
						this.TempFlags.set("DelveRepairs", tries + 1);

						try { c.spawnSite(); }
						catch (e) { ::logError("Skv.Delve: REPAIR of the marker threw (attempt " + (tries + 1) + " of " + C.RepairTries + ") - " + e); }
						if (c.siteLive()) ::logInfo("Skv.Delve: REPAIRED a missing marker (attempt " + (tries + 1) + " of " + C.RepairTries + ").");
						else ::logError("Skv.Delve: REPAIR left no marker (attempt " + (tries + 1) + " of " + C.RepairTries + ").");
						c.setRings();
					}
					else if (!this.TempFlags.get("DelveRepairGaveUp"))
					{
						this.TempFlags.set("DelveRepairGaveUp", true);
						::logError("Skv.Delve: the marker is still missing after " + C.RepairTries
							+ " repair attempts; giving up until the next load (::skvdelvejump can open any stop by hand).");
					}
					if (!c.siteLive()) return;
				}

				if (c.isPlayerAt(c.m.Site))
				{
					if (!this.TempFlags.get("DelveAtSite") && c.getActiveScreen() == null)
					{
						this.TempFlags.set("DelveAtSite", true);
						c.m.Rows = [];

						local away = this.TempFlags.get("DelveAway") == true;
						this.TempFlags.set("DelveAway", false);
						if (away && c.m.Act == C.ActInside) c.restock();
						local s = c.siteScreen();
						::logInfo("Skv.Delve: at " + C.SiteName + " -> " + s + " (act " + c.m.Act + ", maurit " + c.m.Maurit + ", way " + c.m.Way + ", from the map " + away + ", returns " + c.returns() + ")");
						c.setScreen(s);
						::World.Contracts.showActiveContract();
						return;
					}
				}
				else
				{
					this.TempFlags.set("DelveAtSite", false);
					this.TempFlags.set("DelveAway", true);
				}
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv22") return;
				this.Flags.set("V22", _combatID);
				::Skv.dbg("Skv.Delve: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F22");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R22", f);
				::Skv.dbg("Skv.Delve: retreated from " + f + " (id=" + _combatID + ")");
			}
		});
	}

	function roomOpen( _i )
	{
		local C = ::Const.Skv.Delve;
		if (_i == C.RoomStone) return !this.spokeAt(C.WordStone);
		return !this.roomDone(_i);
	}

	function roomText( _i )
	{
		local C = ::Const.Skv.Delve;
		local row = this.roomRow(_i);
		if (_i == C.RoomCells) return this.cellsText(row);
		if (_i == C.RoomArchive) return this.archiveText();
		if (_i == C.RoomGallery) return this.galleryText(row);
		if (_i == C.RoomFlame) return this.flameText(row);
		if (this.roomOpen(_i))
		{
			if (_i == C.RoomBones && this.m.Way == C.WayCave)
				return "Her cave ends at a torn hole in the wall of a great painted hall. The heap of bones before you faces the other way, towards the door.";
			if (_i == C.RoomAir || _i == C.RoomStone || _i == C.RoomWater) return this.deviceText(_i, row);
			if (_i == C.RoomScribes && this.lampState() == C.LampFountain)
				return "Broken writing desks lie about, grown over with pale mushrooms. The nest of fungus at the back is empty: the pale thing you killed at the fountain must have lived here.";

			if (_i == C.RoomWebs && (this.m.Burn & C.BurnWebs) != 0)
				return "The webs have burned down to black threads, and the spiders are still in there.";
			if (_i == C.RoomRefuse && (this.m.Burn & C.BurnHeap) != 0)
				return "The heap has burned black, and the rats are still in what is left of it.";
			return row.Seen;
		}

		if (_i == C.RoomWebs && (this.m.Burn & C.BurnWebs) != 0)
			return "The webs have burned away, and the spiders lie dead and curled up in the ashes.";
		if (_i == C.RoomRefuse && (this.m.Burn & C.BurnHeap) != 0)
			return "The heap has burned down to ash, and the dead rats lie all around it.";
		if (_i == C.RoomStores && this.hasGrant(C.GrantStores))
			return "The storeroom has been searched down to the last sack of spoiled flour. Someone hid something in that one.";
		if (_i == C.RoomWater && this.lampState() == C.LampFountain)
			return row.After + " The pale thing that came to the noise lies dead beside it.";
		if (_i == C.RoomScribes && this.lampState() == C.LampFountain)
			return "The room is quiet, and the nest at the back has been searched.";
		return row.After;
	}

	function galleryText( _row )
	{
		local C = ::Const.Skv.Delve;
		local t = this.m.Tarka;
		if (!this.roomDone(C.RoomGallery))
		{
			if (t == C.TarkaBotched)
				return "The kobolds have their spears up, and they will not talk any more. One of them is gone, run off towards the red glow deeper in.";
			if (t == C.TarkaFled)
				return "The kobolds are waiting in the gallery with their spears up. There will be no more talk.";
			return _row.Seen;
		}
		if (t == C.TarkaBeaten)
			return "The kobolds lie where they fell, under the names scratched into the walls."
				+ (this.hasGrant(C.GrantBags) ? " Their leader's bags held weighted nets and a heavy grey stone wrapped in cloth." : "");
		if (t == C.TarkaWon) return "Tarka's band waits for you at the far end of the gallery.";
		return "The kobolds stand aside and watch you pass.";
	}

	function flameText( _row )
	{
		local C = ::Const.Skv.Delve;
		local st = this.cultState();
		if (!this.roomDone(C.RoomFlame))
		{
			if (st == C.CultUnmaskedFought)
				return "The kobolds stand before the stone dragon with their weapons out, but they keep looking back at it. The thin voice behind it has nowhere left to hide.";

			local meaning = this.canRead()
				? " " + (this.m.Script == C.ScriptList ? "The clerk's list gives its meaning" : this.readerText()) + ": the word means fire."
				: "";
			if (st == C.CultFled)
				return "The kobolds stand between you and the stone dragon now, weapons in hand, and the candles on the altar have been kicked over. The thin voice behind the dragon is still giving orders. A word in an old southern script is cut into the dragon's chest." + meaning;
			local t = _row.Seen;

			if (this.m.Alert > 0)
				t = "Two rooms have been knocked into one, with a fallen door laid on stones for an altar and candles burning on it. Four kobolds stand guard before a stone dragon with their weapons ready. When a thin voice somewhere behind it asks a question, fire bursts from the dragon's mouth, once or twice. A word in an old southern script is cut into the dragon's chest.";
			if (this.cultStandsDown())
				t = "Two rooms have been knocked into one, with a fallen door laid on stones for an altar and candles burning on it. Four kobolds kneel before a stone dragon. %SKVNAME%Tarka%SKVNAME_OFF% goes in ahead of you and talks to them fast and low, and one by one they get up off their knees. Then she turns to the dark behind the dragon and shouts.%SPEECH_ON%Speaker! Dragon send strangers. Strangers say you liar. You true, dragon burn them. You come out!%SPEECH_OFF%Nobody comes out, but something behind the dragon shifts. A word in an old southern script is cut into the dragon's chest, and every kobold in the room is watching you.";
			return t + meaning;
		}
		if (st == C.CultAside) return "The kobolds have drawn back from the dragon. The thin voice behind it has stopped.";
		if (st == C.CultDragged || st == C.CultDragFail) return "The kobolds have gathered round their stone dragon again, and none of them is kneeling.";
		if (st == C.CultFought || st == C.CultUnmaskedFought)
			return "The kobolds lie where they fell before the stone dragon, and the candles on the altar burn on."
				+ (this.hasGrant(C.GrantAltar) ? " Their offerings are in your packs." : "");
		return _row.After;
	}

	function cellsText( _row )
	{
		local C = ::Const.Skv.Delve;
		if (!this.roomDone(C.RoomCells))
		{
			if (!this.cellsOpened()) return _row.Seen;
			return _row.After + " Two hold only scattered bones. In the third, nearest the door, one skeleton lies with a folded letter beneath it. The writing is foreign to all of you, but its broken seal is not: a horned beast among three clouds, the beast painted on the lanterns in Amara Li's garden. Whoever he was, he must have come from her people.";
		}
		if ((this.m.Clues & C.ClueBurial) != 0)
			return "The cell nearest the door stands empty now. His bones go home with you, and on your return you will pay for a priest and a grave.";
		return _row.After;
	}

	function archiveText()
	{
		local C = ::Const.Skv.Delve;
		local t = "Three alcoves of rotten shelves hold scroll tubes by the dozen, and water runs down one corner. Most of the scrolls have rotted away.";

		if (!this.hasGrant(C.GrantShelves) && (this.roomDone(C.RoomArchive) || this.hasGrant(C.GrantShelvesLeft)))
			t = t + " The bundle on the high shelf was left where it lay.";
		else if (!this.hasGrant(C.GrantShelves))
			t = t + " On a high shelf a bundle of sheets under wax seals has stayed dry. They are written in an old southern script, with columns of figures: agreements, by the look of them.";
		else t = t + " The dry agreements from the high shelf are bundled up and packed.";
		if ((this.m.Clues & C.ClueSheet) != 0)
			t = t + " One sheet among them is no agreement but a letter to the keep's old master. It praises him for winning the Li family's sword, and still more for what the sword carried inside it.";
		local lock = this.lockState(false);
		if (lock == C.LockUntried) t = t + " One iron-bound letter case is still locked.";
		else if (lock == C.LockPicked) t = t + " The letter case stands open and empty.";
		else t = t + " The letter case lies broken, stained with dye.";
		return t;
	}

	function deviceText( _i, _row )
	{
		local C = ::Const.Skv.Delve;
		if (_i == C.RoomWater && this.lampAtFountain())
			return "Two lights come up the corridor towards the noise, low to the floor: a pale creature much like a toad and as big as a hound, its hide dry and flaking. Light pours from its eyes like a lantern's, and it comes straight at you.";
		if (!this.canRead()) return _row.Seen;
		local who = this.m.Script == C.ScriptList ? "The clerk's list gives its meaning" : this.readerText();
		local meaning = _i == C.RoomAir ? "wind" : (_i == C.RoomStone ? "earth" : "water");
		local t = _row.Seen + " " + who + ": the word means " + meaning + ".";
		if (_i == C.RoomStone)
			t = t + " Smaller letters under it say more: it serves whoever calls it for " + this.golemFightsText() + ", and then it goes back into the stone.";
		return t;
	}

	function readerText() { return this.readerProse() + " can read it"; }

	function readerProse()
	{
		local n = this.readerName();
		return n == "One of the company" ? n : "%SKVNAME%" + n + "%SKVNAME_OFF%";
	}

	function readerName()
	{
		if (this.m.Reader != "")
		{
			foreach (bro in ::World.getPlayerRoster().getAll())
				if (bro.isAlive() && bro.getName() == this.m.Reader) return this.m.Reader;
		}
		if (!this.m.ReaderGoneLogged)
		{
			this.m.ReaderGoneLogged = true;
			::logInfo("Skv.Delve: the reader of the old script (\"" + this.m.Reader + "\") is no living man of the company; the text says \"One of the company\".");
		}
		return "One of the company";
	}

	function servantLeftRows()
	{
		local rows = [];
		if (!this.spokeAt(::Const.Skv.Delve.WordStone)) return rows;
		rows.push(this.golemJoins() ? this.goodRow("Stone servant: " + this.m.Golem + (this.m.Golem == 1 ? " fight" : " fights") + " left to give")
			: this.badRow("Stone servant: back in the stone"));
		return rows;
	}

	function servantRows( _key )
	{
		local C = ::Const.Skv.Delve;
		local rows = [];
		if (!this.spokeAt(C.WordStone)) return rows;

		if (this.servantIn(_key))
			rows.push(this.goodRow("Stone servant: with you in this fight (" + this.m.Golem + (this.m.Golem == 1 ? " fight" : " fights") + " left, this one among them)"));
		else if (this.golemJoins())
			rows.push(this.badRow("Stone servant: not with you here (" + this.m.Golem + (this.m.Golem == 1 ? " fight" : " fights") + " left)"));
		else
			rows.push(this.badRow("Stone servant: back in the stone"));
		return rows;
	}

	function roomRows( _i )
	{
		local C = ::Const.Skv.Delve;
		local rows = this.m.Rows == null ? [] : clone this.m.Rows;
		local fight = C.Rooms[_i].Fight;
		if (fight != null && this.roomOpen(_i))
		{

			if (_i == C.RoomBones && this.m.Way == C.WayCave) rows.push(this.goodRow("You come in behind them, so fewer will be ready to meet you"));

			if (_i == C.RoomGallery && this.m.Alert > 0) rows.push(this.badRow("They are angry after the failed talk, and ready for you"));

			if (_i == C.RoomFlame && this.m.Alert > 0) rows.push(this.badRow("They had been warned, and were ready for you"));
			if (_i == C.RoomFlame && this.tarkaLittle() && !this.spokeAt(C.WordFire)) rows.push(this.goodRow("Tarka had told you that their leader was a cheat"));

			if (!(_i == C.RoomFlame && this.cultStandsDown())) rows.extend(this.servantRows(fight));
		}
		return rows;
	}

	function speakText( _place, _text )
	{
		if (this.canRead()) return "{" + _text + "}";
		return this.readTried(_place) ? "{" + _text + " (nobody can read the word)}" : "{" + _text + " (the word is not read yet)}";
	}

	function roomOptions( _i )
	{
		local C = ::Const.Skv.Delve;
		local i = _i;
		local key = C.Rooms[i].Key;
		local fight = C.Rooms[i].Fight;
		local opts = [];

		if (!this.roomOpen(i))
		{
			opts.push({
				Text = "{Go on.}",
				function getResult() { return this.Contract.leaveRoom(i); }
			});
			if (fight != null) opts.push(this.gearOption(key));
			return opts;
		}

		if (i == C.RoomAir || i == C.RoomStone || i == C.RoomWater)
		{

			if (i == C.RoomWater && this.lampAtFountain())
			{
				opts.push({
					Text = "{Meet it behind shields, eyes down.}",
					function getResult() { return this.Contract.resolveLamp(i, false); }
				});
				opts.push({
					Text = "{Throw a cloak over its eyes.}",
					function getResult() { return this.Contract.resolveLamp(i, true); }
				});
				return opts;
			}

			if (!this.canRead() && !this.readTried(this.readPlace(i)))
			{
				opts.push({
					Text = this.readText(this.readPlace(i), "Read the word."),
					function getResult() { return this.Contract.resolveRead(i); }
				});
			}
			opts.push({
				Text = this.speakText(this.readPlace(i), i == C.RoomStone ? "Speak the word now." : "Speak the word."),
				function getResult() { return this.Contract.resolveSpeak(i); }
			});
			opts.push({
				Text = i == C.RoomStone ? "{Not yet.}" : "{Leave the word unspoken and go on.}",
				function getResult() { return this.Contract.holdWord(i); }
			});
			return opts;
		}

		if (i == C.RoomCells)
		{
			if (!this.cellsOpened())
			{
				opts.push({
					Text = "{Pick the lock.}",
					function getResult() { return this.Contract.resolveLock(true, true); }
				});
				opts.push({
					Text = "{Shove the door in.}",
					function getResult() { return this.Contract.resolveLock(true, false); }
				});
				opts.push({
					Text = "{Leave the cells shut.}",
					function getResult() { return this.Contract.passRoom(i); }
				});
				return opts;
			}
			if (this.hasGrant(C.GrantCells))
			{
				opts.push({
					Text = "{Go on.}",
					function getResult() { return this.Contract.leaveEnvoy(i); }
				});
				return opts;
			}
			if (this.kindOK())
			{
				opts.push({
					Text = "{Take his bones for burial. (" + this.burialFee() + " crowns, paid on your return)}",
					function getResult() { return this.Contract.buryEnvoy(i); }
				});
			}
			opts.push({
				Text = "{Leave him.}",
				function getResult() { return this.Contract.leaveEnvoy(i); }
			});
			return opts;
		}

		if (i == C.RoomArchive)
		{
			if (!this.hasGrant(C.GrantShelves) && !this.hasGrant(C.GrantShelvesLeft))
			{
				opts.push({
					Text = this.princeClaims() ? "{Bundle up the agreements.}" : "{Bundle up the agreements. (nobody will buy them)}",
					function getResult() { return this.Contract.bundleShelves(i); }
				});
			}
			if ((this.m.Clues & C.ClueSheet) == 0 && (this.canRead() || !this.readTried("archive")))
			{
				opts.push({
					Text = this.canRead() ? "{Read the old script.}" : this.readText("archive", "Read the old script."),
					function getResult() { return this.Contract.readSheet(i); }
				});
			}
			if (this.lockState(false) == C.LockUntried)
			{
				opts.push({
					Text = "{Pick the lock of the case.}",
					function getResult() { return this.Contract.resolveLock(false, true); }
				});
				opts.push({
					Text = "{Break the case open.}",
					function getResult() { return this.Contract.resolveLock(false, false); }
				});
			}
			opts.push({
				Text = "{Go on.}",
				function getResult() { return this.Contract.leaveArchive(i); }
			});
			return opts;
		}

		if (i == C.RoomScribes)
		{
			if (this.lampState() == C.LampFountain)
			{
				opts.push({
					Text = "{Search the nest.}",
					function getResult() { return this.Contract.searchNestRoom(i); }
				});
				return opts;
			}
			opts.push({
				Text = "{Go in behind shields, eyes down.}",
				function getResult() { return this.Contract.resolveLamp(i, false); }
			});
			opts.push({
				Text = "{Throw a cloak over its eyes.}",
				function getResult() { return this.Contract.resolveLamp(i, true); }
			});
			opts.push({
				Text = "{Leave the room to it.}",
				function getResult() { return this.Contract.leaveLamp(i); }
			});
			return opts;
		}

		if (i == C.RoomStores)
		{
			opts.push({
				Text = "{Search the stores.}",
				function getResult() { return this.Contract.searchStores(i); }
			});
			opts.push({
				Text = "{Leave.}",
				function getResult() { return this.Contract.passRoom(i); }
			});
			return opts;
		}

		if (i == C.RoomGallery)
		{
			opts.push({
				Text = "{Attack.}",
				function getResult() { return this.Contract.fightRoom(i); }
			});
			if (this.m.Tarka == C.TarkaUnmet)
			{
				opts.push({
					Text = "{Lower your weapons and speak to the one who leads.}",
					function getResult() { return this.Contract.openParley(i); }
				});
			}
			opts.push(this.gearOption(key));
			return opts;
		}

		if (i == C.RoomFlame)
		{
			local st = this.cultState();
			if (!this.canRead() && !this.readTried("statue"))
			{
				opts.push({
					Text = this.readText("statue", "Read the word."),
					function getResult() { return this.Contract.resolveRead(i); }
				});
			}
			if (!this.spokeAt(C.WordFire))
			{
				opts.push({
					Text = this.speakText("statue", "Speak the word yourself."),
					function getResult() { return this.Contract.speakFlame(i); }
				});
			}
			if (this.cultStandsDown())
			{
				opts.push({
					Text = "{Drag him out.}",
					function getResult() { return this.Contract.dragOut(i); }
				});
			}
			else if (st == C.CultUnmaskedFought)
			{
				opts.push({
					Text = "{Fight them.}",
					function getResult() { return this.Contract.fightRoom(i); }
				});
			}
			else
			{
				opts.push({
					Text = "{Attack.}",
					function getResult() { return this.Contract.chargeIn(i); }
				});
			}
			opts.push(this.gearOption(key));
			return opts;
		}

		local cave = i == C.RoomBones && this.m.Way == C.WayCave;

		local webBurned = i == C.RoomWebs && (this.m.Burn & C.BurnWebs) != 0;

		local heapBurned = i == C.RoomRefuse && (this.m.Burn & C.BurnHeap) != 0;
		local attack = i == C.RoomWebs ? (webBurned ? "{Go in after the spiders.}" : "{Cut a way through.}")
			: (i == C.RoomBones ? (cave ? "{Attack them from behind.}" : "{Search the heap.}")
			: (i == C.RoomRefuse ? (heapBurned ? "{Go in after the rats.}" : "{Turn the heap over.}") : "{Attack.}"));
		opts.push({
			Text = attack,
			function getResult() { return this.Contract.fightRoom(i); }
		});

		if ((i == C.RoomWebs || i == C.RoomRefuse) && (this.m.Burn & this.burnBit(i)) == 0)
		{
			opts.push({
				Text = this.burnText(i),
				function getResult() { return this.Contract.burnRoom(i); }
			});
		}
		if (i == C.RoomWebs || i == C.RoomRefuse || (i == C.RoomBones && !cave))
		{
			opts.push({
				Text = i == C.RoomWebs ? (webBurned ? "{Leave the spiders alone.}" : "{Leave the webs alone.}") : (i == C.RoomBones ? "{Keep to the wall.}" : "{Leave it.}"),
				function getResult() { return this.Contract.passRoom(i); }
			});
		}
		opts.push(this.gearOption(key));
		return opts;
	}

	function roomScreen( _i )
	{
		return {
			ID = ::Const.Skv.Delve.Rooms[_i].Key,
			Room = _i,
			Title = "",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local i = this.Room;
				local row = c.roomRow(i);
				this.Title = row.Title;
				this.Text = c.img(row.Img) + "{" + c.roomText(i) + "}";
				this.List = c.roomRows(i);
				this.Options = c.roomOptions(i);
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
					::logError("Skv.Delve: the negotiation's advance button was not found (Legends changed its text?); the player can haggle an advance #22 will not pay.");
			};
			this.m.Screens.push(neg);
		}

		local stock = this.Const.Contracts.Overview[0];
		local ov = clone stock;
		ov.Options = [];
		local found = false;
		foreach (o in stock.Options)
		{
			if (o.Text == "I accept this contract.")
			{
				found = true;
				local inner = o.getResult;
				ov.Options.push({
					Text = o.Text,
					getResult = function ()
					{
						inner();
						return "Major";
					}
				});
			}
			else
			{
				ov.Options.push({ Text = o.Text, getResult = o.getResult });
			}
		}
		if (!found)
			::logError("Skv.Delve: the Overview's accept option was not found by its text; the rider screens open one tick late, from Running.update.");
		this.m.Screens.push(ov);

		this.m.Screens.push({
			ID = "Task",
			Title = "To Delve the Dungeon Deep",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Delve.ImgAmara) + "{%SKVNAME%Amara Li%SKVNAME_OFF% of the %SKVLOC%Lantern Lodge%SKVLOC_OFF% holds a feast tonight. Lanterns painted with a horned beast hang over her garden, the guests drink plum wine, and rockets burst above the pond. She receives you in her study and shuts the door.\n\nLong ago one of her family gave the jade sword away, to a general from across the sea, %SKVNAME%Asad%SKVNAME_OFF%, who had come to make war here. He lost his war, an earthquake brought his fortress down the same day, and the sword was buried in it. To her family it was never just a blade: the gift was a matter of honour, and its loss has shamed the Li name ever since. She wants it home. Now the ruin has been found in the hills. The lodge sent its own people in once, and one of them did not come back.\n\nThe lodge was content with your last work, she says, and so she asks you. She pays when the sword is in her hands, and nothing before.}";
				this.Options = [
					{
						Text = "{We will fetch your sword.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (::World.getPlayerRoster().getAll().len() >= 2)
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
					Text = "{Back to Amara Li.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
				this.Text = this.Contract.img(::Const.Skv.Delve.ImgAmara) + "{%SKVNAME%%randombrother%%SKVNAME_OFF% knows the lanterns, if not the lady.%SPEECH_ON%%SKVLOC%Lantern Lodge%SKVLOC_OFF%. Their people come from %SKVLOC%Tian Xia%SKVLOC_OFF%, on the far side of the world, and few of them ever make the crossing. They keep their own feasts and their own manners, and they remember their grandfathers better than most of us remember last winter. A family like that does not forget what it has lost.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% is thinking about the general instead.%SPEECH_ON%%SKVLOC%Qadira%SKVLOC_OFF%. A rich country across the sea, and the western corner of an empire that is richer still. Every so often one of its generals brings an army over to take what he can. They build keeps on the plains and up in the hills to wait out a siege, and when the siege fails they leave them standing. A ruin built for a whole army does not stay empty for long.%SPEECH_OFF%Of the lodge itself the company knows what every tavern knows. Its people dig up old places for a living and write down everything they find there, and when a ruin is more than they can manage, they pay others to go in.}";
			}
		});

		this.m.Screens.push({
			ID = "Major",
			Title = "The Officer",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Delve.ImgMajor) + "{In the garden an officer stops you: a blue coat, gold eagles on the shoulders, and a loud voice. %SKVNAME%Major Maldris%SKVNAME_OFF% of %SKVLOC%Andoran%SKVLOC_OFF% has heard where you are going. The old ruins of this country are full of walking dead, she says, and to her a dead man made to walk is the worst kind of slave there is. She asks for your word that you will destroy any of them you meet there, and she will pay for it when you are back.}";
				this.List = [];
				this.Options = [
					{
						Text = "{You have our word.}",
						function getResult() { return this.Contract.resolveMajor(true); }
					},
					{
						Text = "{We are paid for a sword, not a crusade.}",
						function getResult() { return this.Contract.resolveMajor(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Prince",
			Title = "The Trade Prince",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Delve.ImgPrince) + "{At the gate a quiet, exact man is waiting for you: the trade prince %SKVNAME%Aaqir al'Hakam%SKVNAME_OFF%. Where the Major was loud, he is not. He says the ruin belongs to %SKVLOC%Qadira%SKVLOC_OFF%. He wants every trade agreement you find in it brought to him, and he will pay for each one.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Agreed.}",
						function getResult() { return this.Contract.resolvePrince(true); }
					},
					{
						Text = "{We carry for one master.}",
						function getResult() { return this.Contract.resolvePrince(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Morning",
			Title = "The Road",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				this.Text = c.img(C.ImgParty) + "{Dawn comes up over the lodge. The road to the ruin is marked on your map, and a few guests are still talking in the garden. %SKVNAME%%randombrother%%SKVNAME_OFF% studies the map.%SPEECH_ON%Hills, a ruin, and a sword nobody else could fetch. I would like to know what happened to the ones the lodge sent first.%SPEECH_OFF%}";
				this.List = [];
				this.Options = [];
				if ((c.m.Riders & C.RiderGarden) == 0)
				{
					this.Options.push({
						Text = "{What is said in the garden?}",
						function getResult() { return this.Contract.resolveGarden(); }
					});
				}
				this.Options.push({
					Text = "{To the road.}",
					function getResult() { return this.Contract.toRoad(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Garden",
			Title = "The Garden",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Delve.ImgParty) + "{You spend the last hour of the feast among the guests, and listen more than you talk.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{To the road.}",
						function getResult() { return this.Contract.toRoad(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Gully",
			Title = "The Door in the Cliff",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local fled = c.gullyFled();
				this.Text = fled
					? c.img(C.ImgMaurit) + "{The pack has gone back to its rocks above the door. %SKVNAME%Maurit Zergo%SKVNAME_OFF% watches you climb the slope again, and this time she offers nothing.}"
					: c.img(C.ImgGully) + "{The ruin is a door three men high in a cliff, at the top of a slope of rubble. A thin, grey thing crouches on the cliff above it and speaks before anyone has drawn a blade. She is hungry, and she says so. When she hears whose pay you take, her face changes. She names herself: %SKVNAME%Maurit Zergo%SKVNAME_OFF%. She came here with the lodge's first party and died in these hills, and she did not stay dead. She offers what she knows of the place, and another way in. More of her kind sit among the rocks behind her and say nothing.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if (!fled)
				{
					this.Options.push({
						Text = "{Take her help.}",
						function getResult() { return this.Contract.resolveTrust(); }
					});
				}
				this.Options.push({
					Text = "{Kill her.}",
					function getResult()
					{
						local c = this.Contract;
						local C = ::Const.Skv.Delve;

						if (c.m.Maurit != C.MauritUnmet && c.m.Maurit != C.MauritFled) return c.siteScreen();
						if (!c.launch("Door")) return "Gully";
						return 0;
					}
				});
				this.Options.push(c.gearOption("Gully"));

				if (fled)
				{
					this.Options.push({
						Text = "{Fall back for now.}",
						function getResult() { return this.Contract.closeAtSite(); }
					});
				}
				if (c.canGiveUp())
				{
					this.Options.push({
						Text = "{Give the sword up.}",
						function getResult() { return "GiveUp"; }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Help",
			Title = "What She Knows",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				this.Text = c.img(C.ImgMaurit) + "{She scratches the keep into the dust. Kobolds live deep inside it. Their leader is no kobold: a tall thing with bare skin that takes the colour of the wall behind it, and it wears a jade sword. Old papers lie all through the place, and the walls answer to words. Her own way in is a cave that comes out behind a heap of bones in the great hall, so whatever lies there will have its back to you. The place is empty of beasts, she says.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Follow her to the cave.}",
						function getResult() { return this.Contract.chooseWay(::Const.Skv.Delve.WayCave); }
					},
					{
						Text = "{We go in by the door.}",
						function getResult() { return this.Contract.chooseWay(::Const.Skv.Delve.WayDoor); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "DoorWon",
			Title = "The Door in the Cliff",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				this.Text = c.img(C.ImgGully) + "{The pack is dead. %SKVNAME%Maurit Zergo%SKVNAME_OFF% lies among them, the only one that still looked like someone."
					+ (c.hasGrant(C.GrantKit) ? " On her belt you find what she came here with: lock picks, three small flasks, and a purple stone in a pouch." : "")
					+ " The great door stands open above you. %SKVNAME%%randombrother%%SKVNAME_OFF% looks up at the open door.%SPEECH_ON%She came here for the same sword and ended up guarding the door. Let's not do the same.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Go on.}",
						function getResult() { return this.Contract.onward(); }
					},
					c.gearOption("DoorWon")
				];
			}
		});

		this.m.Screens.push({
			ID = "Ambush",
			Title = "Behind the Last Man",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				this.Text = c.img(C.ImgMaurit) + "{%SKVNAME%Maurit Zergo%SKVNAME_OFF% comes out of the dark behind the last of you, and her pack comes with her.}";

				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if ((c.m.Wary & 3) == C.WaryMissed) rows.push(c.badRow("Nobody had seen through her, and she came at your backs"));
				if ((c.m.Wary & C.WaryFled) != 0) rows.push(c.goodRow("This time you were ready for her"));
				rows.extend(c.servantRows("Ambush"));
				this.List = rows;
				this.Options = [
					{
						Text = "{Turn and fight.}",
						function getResult()
						{
							local c = this.Contract;

							if (c.m.Maurit != ::Const.Skv.Delve.MauritTrusted) return c.onward();

							if (!c.launch("Ambush")) return c.closeAtSite();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AmbushWon",
			Title = "Behind the Last Man",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Delve.ImgMaurit) + "{The pack is dead, and she with it. She was the only one of them that still looked like someone."
					+ (c.hasGrant(::Const.Skv.Delve.GrantKit) ? " On her belt you find what she came here with: lock picks, three small flasks, and a purple stone in a pouch." : "")
					+ " %SKVNAME%%randombrother%%SKVNAME_OFF% spits on the nearest of the dead.%SPEECH_ON%She told us the way in and then came at our backs. I will not trust a guide like that again.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Go on.}",
						function getResult() { return this.Contract.onward(); }
					}
				];

				if (!c.swordHeld())
				{
					this.Options.push({
						Text = "{Leave the keep for now.}",
						function getResult()
						{
							local c = this.Contract;
							::logInfo("Skv.Delve: LEFT THE KEEP for now, after her ambush (act " + c.m.Act + ", rooms=" + c.m.Rooms + " passed=" + c.m.Passed + " golem=" + c.m.Golem + ").");
							return c.closeAtSite();
						}
					});
				}
				this.Options.push(c.gearOption("AmbushWon"));
			}
		});

		this.m.Screens.push({
			ID = "Hub",
			Title = ::Const.Skv.Delve.SiteName,
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local run = c.runRooms();
				local nxt = c.nextRoom();
				local begun = false;
				foreach (r in run) if (c.roomDone(r) || c.roomPassed(r)) begun = true;

				local text = "";
				if (c.swordHeld())
					text = "The jade sword is wrapped and ready, and nothing holds you in the keep.";
				else if (nxt == null)
					text = "Every door you know of has been tried.";
				else if (!begun)
					text = c.m.Way == C.WayCave
						? "Her cave is a wet crack in the rock that climbs a long way in the dark, and it ends at a torn hole in a painted wall."
						: "Behind the great door a corridor runs straight into the rock. No lamp has burned here for a very long time.";
				else
					text = "You stand between rooms in the dark of the keep, and listen.";
				this.Text = c.img(C.ImgKeep) + "{" + text + "}";

				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				local ahead = 0;
				foreach (r in run)
				{
					local t = c.roomRow(r).Title;
					if (c.roomDone(r)) rows.push(c.goodRow("Behind you: " + t));
					else if (c.roomPassed(r)) rows.push(c.badRow("Passed by: " + t));
					else if (c.trusted()) rows.push(c.goodRow((r == nxt ? "Next on the map: " : "Ahead on the map: ") + t));
					else ahead = ahead + 1;
				}
				if (ahead > 0) rows.push(c.badRow(ahead == 1 ? "One room lies ahead, unknown" : ahead + " rooms lie ahead, unknown"));
				if (c.spokeAt(C.WordStone))
					rows.push(c.golemJoins() ? c.goodRow("Stone servant: " + c.m.Golem + (c.m.Golem == 1 ? " fight" : " fights") + " left to give")
						: c.badRow("Stone servant: back in the stone"));
				this.List = rows;

				this.Options = [];
				if (nxt != null)
				{
					this.Options.push({
						Text = c.roomRow(nxt).Door,
						function getResult()
						{
							local c = this.Contract;
							local n = c.nextRoom();
							if (n == null) return c.onward();
							return c.enterRoom(n);
						}
					});
				}
				if (c.stoneWaits())
				{
					this.Options.push({
						Text = c.speakText("stone", "Go back to the stone warrior."),
						function getResult() { return this.Contract.enterRoom(::Const.Skv.Delve.RoomStone); }
					});
				}
				this.Options.push(c.gearOption("Hub"));
				if (c.swordHeld())
				{
					this.Options.push({
						Text = "{The way out.}",
						function getResult() { return this.Contract.wayOut(); }
					});
				}
				else
				{

					this.Options.push({
						Text = "{Leave the keep for now.}",
						function getResult()
						{
							local c = this.Contract;
							c.m.Rows = [];
							if (c.betrayalDue(true)) return "Ambush";

							::logInfo("Skv.Delve: LEFT THE KEEP for now (act " + c.m.Act + ", rooms=" + c.m.Rooms + " passed=" + c.m.Passed + " golem=" + c.m.Golem + ").");
							return c.closeAtSite();
						}
					});
				}
				if (c.canGiveUp())
				{
					this.Options.push({
						Text = "{Give the sword up.}",
						function getResult() { return "GiveUp"; }
					});
				}
			}
		});

		foreach (i, r in ::Const.Skv.Delve.Rooms) this.m.Screens.push(this.roomScreen(i));

		this.m.Screens.push({
			ID = "Fled",
			Title = "Driven Off",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				this.Text = c.gullyFled()
					? c.img(C.ImgGully) + "{You fall back down the slope of rubble, and the pack does not follow you past the foot of the slope. They are still up there among the rocks above the door, watching the road.}"
					: c.img(C.ImgGully) + "{You fall back out of the keep, and nothing follows you far. Whatever drove you off is still in there.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if (c.swordHeld())
				{
					this.Options.push({
						Text = "{Home.}",
						function getResult() { return this.Contract.goHome(); }
					});
				}
				else
				{
					this.Options.push({
						Text = "{Fall back for now.}",
						function getResult() { return this.Contract.closeAtSite(); }
					});
				}
				if (c.canGiveUp())
				{
					this.Options.push({
						Text = "{Give the sword up.}",
						function getResult() { return "GiveUp"; }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Parley",
			Title = "A Few Words",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local t = c.m.Tarka;
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				local text = "";
				this.Options = [];
				if (t == C.TarkaUnmet && !c.roomDone(C.RoomGallery))
				{
					local word = (c.m.Clues & C.ClueHerWord) != 0;
					text = "You lower your weapons. The spears stay up, but the four look to the smallest of them, a sharp-eyed kobold with two bags slung across her chest. She steps forward, looks you over, and taps her own chest.%SPEECH_ON%%SKVNAME%Tarka%SKVNAME_OFF%. You talk. Talk quick.%SPEECH_OFF%She has only a few words of your tongue, but she is listening."
						+ (word ? " The dead woman at the door said these kobolds follow a leader who is no kobold. From the way these four were arguing, not all of them follow gladly." : "");
					rows.extend(c.servantLeftRows());
					this.Options.push({
						Text = word ? "{Tell her you have come for the tall one with the jade sword, not for her people.}" : "{Tell her you have no quarrel with her people.}",
						function getResult() { return this.Contract.talkTarka(); }
					});
					local fee = c.passageFee();
					this.Options.push({
						Text = "{Pay for passage. (" + fee + " crowns)" + (::World.Assets.getMoney() < fee ? " (not enough crowns)}" : "}"),
						function getResult() { return this.Contract.payPassage(); }
					});
					this.Options.push({
						Text = "{Enough talk.}",
						function getResult() { return this.Contract.fightRoom(::Const.Skv.Delve.RoomGallery); }
					});
					this.Options.push(c.gearOption("Parley"));
				}
				else if (t == C.TarkaBotched && !c.roomDone(C.RoomGallery))
				{
					text = "She does not like what she hears. %SKVNAME%Tarka%SKVNAME_OFF% snarls a word in her own tongue, and the spears come up. One of the four darts away down the gallery towards the red glow further in.";
					rows.extend(c.servantRows("Gallery"));
					this.Options.push({
						Text = "{Defend yourselves.}",
						function getResult() { return this.Contract.fightRoom(::Const.Skv.Delve.RoomGallery); }
					});
					this.Options.push(c.gearOption("Parley"));
				}
				else
				{
					if (t == C.TarkaWon)
						text = "The talk goes on longer than anyone expected. At last %SKVNAME%Tarka%SKVNAME_OFF% turns to her three and talks at them in her own tongue for a long time, pointing at you, at the ceiling, and at the red glow further in. The spears come down. She turns back to you, very pleased with herself.%SPEECH_ON%Dragon send you. Dragon want to know: Speaker true, or Speaker liar? Tarka help. We all go, we all see.%SPEECH_OFF%Her three do not look sure that any dragon sent anybody, but none of them argues with her. She hands over her two bags to show that she means it.";
					else if (t == C.TarkaLittle)
						text = "%SKVNAME%Tarka%SKVNAME_OFF% listens with her head tilted. Then she spits on the floor, and it takes you a moment to see that it is not meant for you.%SPEECH_ON%Speaker. Big voice, no fire. Dragon burn, Speaker say dragon talk to him. Before Speaker come out of the hole, Tarka lead. Now Tarka fetch water.%SPEECH_OFF%She waves her three aside, and makes it clear that she will not help you past this gallery.";
					else if (t == C.TarkaPaid)
						text = "%SKVNAME%Tarka%SKVNAME_OFF% bites one of the coins, counts the rest twice, and waves her three aside.%SPEECH_ON%Pay, pass. No pay, no pass. Tarka fair. Speaker not fair.%SPEECH_OFF%";
					else
						text = "The gallery is quiet.";
					this.Options.push({
						Text = "{Go on.}",
						function getResult() { return this.Contract.onward(); }
					});

					this.Options.push(c.gearOption("Parley"));
				}
				this.Text = c.img(C.ImgFlame) + "{" + text + "}";
				this.List = rows;
			}
		});

		this.m.Screens.push({
			ID = "Unmasked",
			Title = "The Dragon Answers",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local st = c.cultState();
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				local they = c.m.Alert > 0 ? "The kobolds" : "The kneeling kobolds";
				local text = (c.m.Script == C.ScriptList ? "One of the company reads the word off the clerk's list and says it aloud, standing well to one side of the stone dragon."
					: c.readerProse() + " steps to one side of the stone dragon and says the word.")
					+ " Fire bursts from its mouth, just as it does for the voice behind it.";
				this.Options = [];
				if (st == C.CultUnmaskedFought && !c.roomDone(C.RoomFlame))
				{
					text = text + " " + they + " stare at the fire, then at you, and for a moment nobody moves. Then the thin voice behind the dragon screams at them, and they still come at you, slowly, looking back at the dragon as they come.";
					rows.extend(c.servantRows("Cult"));
					this.Options.push({
						Text = "{Fight them.}",
						function getResult() { return this.Contract.fightRoom(::Const.Skv.Delve.RoomFlame); }
					});
					this.Options.push(c.gearOption("Unmasked"));
				}
				else
				{
					if (c.cultStandsDown())
						text = text + " %SKVNAME%Tarka%SKVNAME_OFF% points at the dark behind the statue and says something short in her own tongue, and every kobold in the room turns to look there.";
					else if (st == C.CultAside)
						text = text + " " + they + " stare at the fire, then at you. Before they can move, the company makes it clear, with few words and a lot of pointing: anyone can make this god speak, and the voice behind it has been doing so all along. One by one they lower their weapons and back away from the altar. Behind the dragon, the thin voice has gone quiet.";
					if (st == C.CultAside && c.ruthlessOK() && !c.hasGrant(C.GrantAltar))
					{
						this.Options.push({
							Text = "{Take the altar's coin.}",
							function getResult() { return this.Contract.takeAltar(); }
						});
					}
					this.Options.push({
						Text = "{Go on.}",
						function getResult() { return this.Contract.onward(); }
					});
					this.Options.push(c.gearOption("Unmasked"));
				}
				this.Text = c.img(C.ImgFlame) + "{" + text + "}";
				this.List = rows;
			}
		});

		this.m.Screens.push({
			ID = "Charge",
			Title = "Into the Red Light",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				this.Text = c.img(C.ImgFlame) + (c.m.Alert > 0 || c.cultState() == C.CultFled
					?"{You go in at a run. The kobolds are on their feet and waiting for you, and behind the stone dragon a thin voice screams orders at them. The dragon's mouth glows red.}"
					: "{You go in at a run. The kneeling kobolds come up off their knees and snatch up their weapons, and behind the stone dragon a thin voice screams orders at them. The dragon's mouth glows red.}");
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				rows.extend(c.servantRows("Cult"));
				this.List = rows;
				this.Options = [
					{
						Text = "{Into them.}",
						function getResult() { return this.Contract.fightRoom(::Const.Skv.Delve.RoomFlame); }
					},
					c.gearOption("Charge")
				];
			}
		});

		this.m.Screens.push({
			ID = "Dragged",
			Title = "The Trial",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local st = c.cultState();
				local text = "If the god is real, %SKVNAME%Tarka%SKVNAME_OFF% has told them, it will burn the strangers who lay hands on its Speaker. The strongest of the company reaches in behind the stone dragon and takes hold of something cold and smooth that is not stone.";
				if (st == C.CultDragged)
					text = text + " The dragon breathes, too late and too high. Out comes a tall creature with bare grey skin, kicking and shrieking. The kobolds stare at it, then at the dragon, which has gone quiet. Tarka says a few words to them, and they bring the offerings from the altar and lay them at your feet.";
				else if (st == C.CultDragFail)
					text = text + " The dragon breathes first, straight along the reaching arm, but the grip holds. Out comes a tall creature with bare grey skin, kicking and shrieking. The kobolds look from it to the burns and back, and none of them goes near the altar.";
				this.Text = c.img(C.ImgFlame) + "{" + text + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Go on.}",
						function getResult() { return this.Contract.onward(); }
					},
					c.gearOption("Dragged")
				];
			}
		});

		this.m.Screens.push({
			ID = "Rope",
			Title = "The Well",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local who = c.heardSpeaker() ? "the one Tarka called the Speaker" : "the owner of the thin voice";
				this.Text = c.img(C.ImgFlame) + "{When the last of the kobolds falls, the dark behind the stone dragon is empty. An old well goes down through the floor there, and a rope tied off at its edge is pulled tight. On the rope, below you, hangs " + who
					+ ": a tall creature with bare grey skin, the jade sword at his hip and a bundle on his back. Far below him, water runs over stones. He looks up, sees who holds the rope, and stops climbing.%SPEECH_ON%The sword! You came for the sword, yes? I send it up to you, you let me go down. A good bargain. Nobody has to fall.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{The rope for the sword.}",
						function getResult() { return this.Contract.resolveSpeaker(::Const.Skv.Delve.SpeakerBargain); }
					}
				];
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Cut the rope.}",
						function getResult() { return this.Contract.resolveSpeaker(::Const.Skv.Delve.SpeakerCut); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Cornered",
			Title = "Behind the Dragon",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local st = c.cultState();
				local heard = c.heardSpeaker();
				local who = heard ? "the Speaker" : "the owner of the thin voice";
				this.Title = heard ? "The Speaker" : "Behind the Dragon";
				local text = "";
				if (st == C.CultDragged || st == C.CultDragFail)
				{
					text = "The Speaker crouches on the floor where he was thrown down, blinking in the candlelight. Behind the dragon an old well goes down through the floor, and two of the company stand between him and it.";
					if (st == C.CultDragged)
						text = text + " The kobolds stand round him in a ring. The dragon did not burn the strangers who laid hands on him, and by Tarka's own test that makes him a liar. Every spear is pointed at him, and %SKVNAME%Tarka%SKVNAME_OFF% is watching you, waiting to see what you will do with him.";
					else
						text = text + " The kobolds keep well back from him. The dragon burned the hand that reached for him, and to them that means their god still speaks for him. Even %SKVNAME%Tarka%SKVNAME_OFF% looks less sure now.";
				}
				else if (st == C.CultAside && c.cultStandsDown())
					text = "Two of the kobolds go in behind the stone dragon, and come out dragging the Speaker between them: a tall creature with bare grey skin, blinking in the candlelight. Behind the dragon an old well goes down through the floor, and they caught him at its edge. The kobolds stand round him in a ring with their spears pointed at him, and %SKVNAME%Tarka%SKVNAME_OFF% is watching you, waiting to see what you will do with him.";
				else
				{
					text = (st == C.CultUnmaskedFought ? "The last of the kobolds is down. " : "")
						+ "You go round behind the stone dragon. An old well goes down through the floor there, and between you and it crouches " + who
						+ ": a tall creature with bare grey skin, pressed flat against the wall as if he could hide in the stone.";
					if (st == C.CultAside)
						text = text + " Out by the altar the kobolds have stopped backing away. They are watching him now, and muttering among themselves.";
				}
				text = text + " He holds out the jade sword, hilt first, and his purse after it.%SPEECH_ON%Take it, take it! The sword, the purse, the little bottles on my belt. Then I go down the well, very far, and you never see me again. A cheap price for one small life, yes?%SPEECH_OFF%";
				this.Text = c.img(C.ImgFlame) + "{" + text + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Take the sword and his purse, and let him go.}",
						function getResult() { return this.Contract.resolveSpeaker(::Const.Skv.Delve.SpeakerSpared); }
					}
				];
				if (c.koboldsJudge())
				{
					this.Options.push({
						Text = "{Give him to the kobolds.}",
						function getResult() { return this.Contract.resolveSpeaker(::Const.Skv.Delve.SpeakerGiven); }
					});
				}
				if (c.ruthlessOK())
				{
					this.Options.push({
						Text = "{Kill him.}",
						function getResult() { return this.Contract.resolveSpeaker(::Const.Skv.Delve.SpeakerKilled); }
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Sword",
			Title = "The Jade Sword",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local sheet = (c.m.Clues & C.ClueSheet) != 0;
				local untried = c.m.Sword == C.SwordHeld;
				this.Text = c.img(C.ImgSword) + "{The jade sword is yours. Its blade is green stone, and its hilt is wound with old silk."
					+ (untried && sheet ? " The letter you read in the archive said that the sword carried something inside it." : "") + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [];
				if (untried && !c.hasGrant(C.GrantHiltLeft))
				{
					this.Options.push({
						Text = sheet ? "{Look for a hiding place.}" : "{Look for a hiding place. (nothing says there is one)}",
						function getResult() { return this.Contract.searchHilt(); }
					});
				}

				this.Options.push({
					Text = "{Wrap it and go.}",
					function getResult() { return this.Contract.wayOut(); }
				});
				this.Options.push(c.gearOption("Sword"));
			}
		});

		this.m.Screens.push({
			ID = "WayOut",
			Title = "The Way Out",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local line = c.tarkaLine();
				this.Text = c.img(C.ImgGully) + "{" + (line != "" ? line + " " : "") + (c.m.Way == C.WayCave
					? "You come out through her cave with the sword wrapped in a cloak. %SKVTOWN% lies beyond the hills."
					: "You come out through the great door with the sword wrapped in a cloak. %SKVTOWN% lies beyond the hills.")
					+ " %SKVNAME%%randombrother%%SKVNAME_OFF% weighs the wrapped sword in both hands.%SPEECH_ON%All that for a piece of green stone. It had better be worth what she says.%SPEECH_OFF%}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Home.}",
						function getResult() { return this.Contract.goHome(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "GiveUp",
			Title = "Empty Hands",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = c.img(::Const.Skv.Delve.ImgGully) + "{The keep has driven you off once already. You can leave the sword where it lies and go back to %SKVTOWN% with empty hands.}";
				this.List = [];
				this.Options = [
					{
						Text = "{The sword stays here.}",
						function getResult() { return this.Contract.giveUp(); }
					},
					{
						Text = "{Not yet.}",
						function getResult()
						{
							local c = this.Contract;
							c.m.Rows = [];
							return c.atSite() ? c.siteScreen() : c.closeAtSite();
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Claim",
			Title = "The Steward",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local n = c.m.Papers;
				local text = "";
				this.Options = [];
				if (!c.hasGrant(C.GrantClaim))
				{
					local full = c.paperPay(false);
					local half = c.paperPay(true);
					text = "At the city gate a thin, neat man in a dark coat is waiting for you, with a clerk and an iron-bound box: the steward of the trade prince %SKVNAME%Aaqir al'Hakam%SKVNAME_OFF%."
						+ (n > 0 ? " The clerk counts the agreements you carried out of the keep, sheet by sheet, and writes the number down." : " You carried no agreements out of the keep, and he does not seem surprised.")
						+ " Then the steward asks to see the sword."
						+ (c.m.Sword == C.SwordPaper ? " When he sees the paper you found in its hilt, he smiles for the first time, and reads it through."
							: " He turns the hilt in his hands, presses at the silk until a hidden catch opens, and draws a rolled paper out of a hollow inside it. He reads it through.")
						+ "%SPEECH_ON%A letter of credit. The %SKVLOC%Way of the Kirin%SKVLOC_OFF%, across the sea, promises ships, weapons and supplies for war to whoever holds it. It is also an agreement of trade, and it was found in the keep, so by your word it belongs to my master."
						+ (n > 0 ? " For the agreements, " + full + " crowns, as he promised. For this paper, " + c.docPay() + " crowns more. If you will not sell it, you have not kept your word, and "
							+ (half > 0 ? "I pay half for the agreements: " + half + " crowns." : "I pay nothing for the agreements.")
							: " For this paper, " + c.docPay() + " crowns. If you will not sell it, you have not kept your word, and my master will hear of it.")
						+ "%SPEECH_OFF%";
					this.Options.push({
						Text = "{Sell him the paper.}",
						function getResult() { return this.Contract.claimPaper(::Const.Skv.Delve.EndPrince); }
					});
					if (c.kindOK())
					{
						this.Options.push({
							Text = "{It goes to her with the sword.}",
							function getResult() { return this.Contract.claimPaper(::Const.Skv.Delve.EndDebt); }
						});
					}
					if (c.ruthlessOK())
					{
						this.Options.push({
							Text = "{It stays with us.}",
							function getResult() { return this.Contract.claimPaper(::Const.Skv.Delve.EndKept); }
						});
					}
				}
				else
				{
					local e = c.m.Ending;
					if (e == C.EndPrince)
						text = "The steward rolls the paper up and puts it away inside his coat, and the clerk counts out the crowns. Then the steward bows, and the two of them are gone into the crowd. %SKVNAME%Amara Li%SKVNAME_OFF% is waiting for her sword.";
					else
						text = (e == C.EndKept ? "The steward watches the paper go into your pack and not back into the hilt. He looks at it for a long moment."
							: "The steward watches you roll the paper up and put it back into the hilt. He does not argue.")
							+ (n > 0 && c.paperPay(true) > 0 ? " He has the clerk count out half of what was promised for the agreements, and the two of them leave without another word."
								: (n > 0 ? " He pays nothing for the agreements, and he and his clerk leave without another word." : " He and his clerk leave without another word."))
							+ " %SKVNAME%Amara Li%SKVNAME_OFF% is waiting for her sword.";
					this.Options.push({
						Text = "{Go on to Amara Li.}",
						function getResult() { return this.Contract.leaveClaim(); }
					});
				}
				this.Text = c.img(C.ImgPrince) + "{" + text + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
			}
		});

		this.m.Screens.push({
			ID = "Amara",
			Title = "Amara Li",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local buried = (c.m.Clues & C.ClueBurial) != 0;
				local text = "";
				this.Options = [];
				if (!c.hasGrant(C.GrantAmara))
				{
					local choose = c.m.Ending == C.EndNone && c.knowsSecret();
					text = "%SKVNAME%Amara Li%SKVNAME_OFF% receives you in her study, as she did on the night of the feast, and shuts the door behind you."
						+ (buried ? " You have brought back two bundles: the sword, and the bones from the cell with the letter that lay under them." : "")

						+ (!choose ? " She asks for the sword."
							: c.m.Sword == C.SwordTaken ? " The paper from the hilt is in your pack. She asks only for the sword."
							: " You know what the hollow in the hilt holds. She asks only for the sword.");
					if (!choose)
					{
						this.Options.push({
							Text = "{Give her the sword.}",
							function getResult() { return this.Contract.giveAmara(::Const.Skv.Delve.EndNone); }
						});
					}
					else
					{
						if (c.kindOK())
						{
							this.Options.push({
								Text = "{Give her the sword as it is.}",
								function getResult() { return this.Contract.giveAmara(::Const.Skv.Delve.EndDebt); }
							});
						}
						if (c.ruthlessOK())
						{
							this.Options.push({
								Text = "{Give her the sword. The paper stays with us.}",
								function getResult() { return this.Contract.giveAmara(::Const.Skv.Delve.EndKept); }
							});
						}
					}
				}
				else
				{
					local e = c.m.Ending;
					local cold = e == C.EndPrince || e == C.EndKept;
					if (e == C.EndDebt)
						text = "She unwraps the sword herself and holds it for a long time. Then she presses at the silk on the hilt, a hollow opens, and when she sees the paper still inside it she sits down.%SPEECH_ON%"
							+ (c.hasGrant(C.GrantClaim) ? "%SKVNAME%Aaqir al'Hakam%SKVNAME_OFF% was a guest at my feast. I think his people asked you for it. And still you brought it back to me." : "You found it, and still you brought it back to me.")
							+ " I never told you it was there. I could not be sure of you, and I was wrong. The lodge owes you a debt, and so do I. While I live in %SKVTOWN%, you will always be welcome in my house.%SPEECH_OFF%";
					else if (cold)
						text = "She unwraps the sword herself, presses at the silk on the hilt, and a hollow opens. It is empty. She closes it again and looks at each of you in turn.%SPEECH_ON%"
							+ (e == C.EndPrince ? "I never told you what it carried, so I cannot blame you that somebody else learned of it."
								: "I never told you what it carried, so I cannot say it was not yours to find.")
							+ "%SPEECH_OFF%She pays what she promised for the sword.";
					else
						text = "She unwraps the sword herself and holds it for a long time. She turns the hilt over in her hands, as if to make sure of something, and only then does she smile. She thanks you, and pays what she promised.";
					if (buried)
						text = text + " Then she unwraps the second bundle and reads the letter twice. The name in it is %SKVNAME%Xeng Li%SKVNAME_OFF%, one of her own family, who carried the sword over the sea long ago and never came home. That evening he is buried in the lodge's garden, and the company stands at the grave.";
					this.Options.push({
						Text = "{Leave.}",
						function getResult() { return this.Contract.leaveAmara(); }
					});
				}
				this.Text = c.img(C.ImgAmara) + "{" + text + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
			}
		});

		this.m.Screens.push({
			ID = "Failed",
			Title = "Amara Li",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local text = "%SKVNAME%Amara Li%SKVNAME_OFF% listens to all of it, and thanks you for coming back at all.";
				if ((c.m.Clues & C.ClueBurial) != 0)
					text = text + " Before you go, you hand over the bones from the cell and the letter that lay under them. She reads it twice. The name in it is %SKVNAME%Xeng Li%SKVNAME_OFF%, one of her own family, who carried the sword over the sea long ago and never came home. That evening he is buried in the lodge's garden, and the company stands at the grave.";
				text = text + " Then a servant shows you to the gate.";
				if (c.princeClaims() && c.paperPay(false) > 0 && !c.hasGrant(C.GrantAmara))
					text = text + " The trade prince's steward is waiting there, and his clerk counts out what his master promised for the agreements.";
				this.Text = c.img(C.ImgAmara) + "{" + text + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantAmara)) rows.extend(c.failedSettle(false));
				this.List = rows;
				this.Options = [
					{
						Text = "{Leave.}",
						function getResult() { return this.Contract.leaveFailed(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "MajorEnd",
			Title = "The Officer",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Delve;
				local text = "Before you leave %SKVTOWN%, %SKVNAME%Major Maldris%SKVNAME_OFF% finds you.";
				if (c.majorOwed() && c.bountyPay() > 0)
					text = text + " She wants to hear about every dead thing you met on the way and how it ended, and she listens to all of it.%SPEECH_ON%Then those are free, at least. Nobody will make them walk again. %SKVLOC%Andoran%SKVLOC_OFF% thanks you, even if %SKVLOC%Andoran%SKVLOC_OFF% never hears of it.%SPEECH_OFF%She pays what she promised, and shakes hands with each of you.";
				else if (c.majorOwed())
					text = text + " She wants to hear about the dead in the keep, and when you have told her, she says nothing for a while.%SPEECH_ON%You gave me your word, and they are still walking. I pay for the dead set free, not for stories.%SPEECH_OFF%She leaves you there.";
				else
					text = text + " She has heard that you destroyed the dead woman who met you at the keep.%SPEECH_ON%You never promised me that, and still you did it. I have no bounty for a promise you never made, but I will remember it.%SPEECH_OFF%";
				this.Text = c.img(C.ImgMajor) + "{" + text + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantMajorEnd)) rows.extend(c.majorSettle(false));
				this.List = rows;
				this.Options = [
					{
						Text = "{Farewell.}",
						function getResult() { return this.Contract.farewellMajor(); }
					}
				];
			}
		});
	}

	function onClear()
	{
		local C = ::Const.Skv.Delve;
		::Skv.Once.release(C.OnceKey);
		if (this.m.IsActive)
		{
			::Skv.Once.retire(C.OnceKey);

			if (!::World.Flags.has(C.ArcFlagOutcome))
				this.recordOutcome(C.OutcomeAbandoned);
			if (this.m.Home != null && !this.m.Home.isNull())
				this.m.Home.getSprite("selection").Visible = false;
		}

		this.killSite();
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
			::logInfo("Skv.Delve: the saved marker id " + id + " resolved to nothing on load; the repair will respawn it if the sword is still in the keep.");
			return null;
		}
		return this.WeakTableRef(e);
	}

	function onSerialize( _out )
	{
		this.writeMarker(_out, this.m.Site);
		_out.writeU16(this.m.DayAccepted);
		_out.writeU8(this.m.Act);
		_out.writeU8(this.m.Band);
		_out.writeU8(this.m.Riders);
		_out.writeU8(this.m.Maurit);
		_out.writeU8(this.m.Wary);
		_out.writeU8(this.m.Way);
		local deck = this.m.Deck == null ? [] : this.m.Deck;
		local dn = ::Math.min(255, deck.len());
		if (deck.len() > 255) ::logError("Skv.Delve: a deck of " + deck.len() + " rooms; only 255 are saved.");
		_out.writeU8(dn);
		for (local i = 0; i < dn; i++)
		{
			_out.writeU8(deck[i]);
		}
		_out.writeU8(this.m.Pos);
		_out.writeU16(this.m.Rooms);
		_out.writeU16(this.m.Passed);
		_out.writeU16(this.m.Words);
		_out.writeU8(this.m.Script);
		_out.writeString(this.m.Reader);
		_out.writeU8(this.m.Golem);
		_out.writeU8(this.m.Papers);
		_out.writeU16(this.m.Clues);
		_out.writeU8(this.m.Burn);
		_out.writeU8(this.m.Lamp);
		_out.writeU8(this.m.Locks);
		_out.writeU8(this.m.Tarka);
		_out.writeU8(this.m.Cult);
		_out.writeU8(this.m.Speaker);
		_out.writeU8(this.m.Sword);
		_out.writeU8(this.m.Ending);
		_out.writeU8(this.m.Fights);
		_out.writeU8(this.m.Alert);
		_out.writeU16(this.m.Named);
		_out.writeU32(this.m.Granted);
		_out.writeString(this.m.ActorName);
		local rows = this.m.Rows == null ? [] : this.m.Rows;
		local n = ::Math.min(255, rows.len());
		if (rows.len() > 255) ::logError("Skv.Delve: " + rows.len() + " rows on the open screen; only 255 are saved.");
		_out.writeU8(n);
		for (local i = 0; i < n; i++)
		{
			_out.writeString(rows[i].icon);
			_out.writeString(rows[i].text);
		}
		_out.writeU8(this.m.Res8);
		_out.writeU16(this.m.Res16);
		_out.writeU32(this.m.Res32);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.m.Site = this.readMarker(_in);
		this.m.DayAccepted = _in.readU16();
		this.m.Act = _in.readU8();
		this.m.Band = _in.readU8();
		this.m.Riders = _in.readU8();
		this.m.Maurit = _in.readU8();
		this.m.Wary = _in.readU8();
		this.m.Way = _in.readU8();
		local dn = _in.readU8();
		this.m.Deck = [];
		for (local i = 0; i < dn; i++)
		{
			this.m.Deck.push(_in.readU8());
		}
		this.m.Pos = _in.readU8();
		this.m.Rooms = _in.readU16();
		this.m.Passed = _in.readU16();
		this.m.Words = _in.readU16();
		this.m.Script = _in.readU8();
		this.m.Reader = _in.readString();
		this.m.Golem = _in.readU8();
		this.m.Papers = _in.readU8();
		this.m.Clues = _in.readU16();
		this.m.Burn = _in.readU8();
		this.m.Lamp = _in.readU8();
		this.m.Locks = _in.readU8();
		this.m.Tarka = _in.readU8();
		this.m.Cult = _in.readU8();
		this.m.Speaker = _in.readU8();
		this.m.Sword = _in.readU8();
		this.m.Ending = _in.readU8();
		this.m.Fights = _in.readU8();
		this.m.Alert = _in.readU8();
		this.m.Named = _in.readU16();
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
		this.m.Res8 = _in.readU8();
		this.m.Res16 = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.contract.onDeserialize(_in);

		if (this.m.IsActive)
		{
			local why = ::Skv.Delve.deckWhy(this.m.Deck);
			if (why != null)
				::logError("Skv.Delve: the loaded deck is broken (" + why + "): " + ::Skv.Delve.deckText(this.m.Deck));

			::logInfo("Skv.Delve: LOADED act=" + this.m.Act + " way=" + this.m.Way + " maurit=" + this.m.Maurit + " wary=" + this.m.Wary
				+ " rooms=" + this.m.Rooms + " passed=" + this.m.Passed + " words=" + this.m.Words + " golem=" + this.m.Golem
				+ " locks=" + this.m.Locks + " sword=" + this.m.Sword + " fights=" + this.m.Fights + " granted=" + this.m.Granted
				+ " marker=" + (this.siteLive() ? "standing" : "NONE") + " deck " + ::Skv.Delve.deckText(this.m.Deck));

			local C = ::Const.Skv.Delve;
			if (this.deadDestroyed() && !this.hasGrant(C.GrantKit))
				::logInfo("Skv.Delve: LOADED: she was put down (maurit " + this.m.Maurit + ") and her kit was never granted (a save from before stage 2, or a jump past the gully). Accepted, not paid now.");

			if (this.m.Script == C.ScriptBrother && this.readFailed() == 0)
				::logInfo("Skv.Delve: LOADED: the old script is read by " + this.m.Reader + " with no roll on record (a save from before stage 2: the stub read it). Kept.");

			local devices = 0;
			local inRunN = 0;
			foreach (d in [ C.RoomAir, C.RoomStone, C.RoomWater ])
			{
				if (!this.inRun(d)) continue;
				inRunN = inRunN + 1;
				if (this.roomDone(d)) devices = devices + 1;
			}
			if (devices > 0 && !this.hasGrant(C.GrantVials))
				::logInfo("Skv.Delve: LOADED: " + devices + " of the " + inRunN + " device rooms of this run were reached and the first two vials were never granted (a save from before stage 2). "
					+ (devices < inRunN ? "They are granted at the next device room entered." : "Accepted, not paid now."));
			if (this.spokeAt(C.WordWater) && !this.hasGrant(C.GrantWater))
				::logInfo("Skv.Delve: LOADED: the fountain was spoken at with no healing given (a save from before stage 2: the stub washed the sick only). Accepted, not paid now.");
			if (this.roomDone(C.RoomScribes) && !this.hasGrant(C.GrantScribes))
				::logInfo("Skv.Delve: LOADED: the room of desks was resolved and its nest never searched (a save from before stage 2; lamp=" + this.m.Lamp + "). Accepted, not paid now.");

			if (this.roomDone(C.RoomCells) && this.cellsOpened() && (this.m.Clues & C.ClueSeal) == 0)
				::logInfo("Skv.Delve: LOADED: the cells were opened (locks=" + this.m.Locks + ") with no seal seen and no burial offered (a save from before stage 2). Accepted: the room stays resolved.");

			if (this.hasGrant(C.GrantCells) && (this.m.Clues & C.ClueBurial) != 0 && !this.hasGrant(C.GrantBurialOwed))
				::logInfo("Skv.Delve: LOADED: the bones were taken with the fee paid at the cells (no GrantBurialOwed: a save from 1.8.9-1.8.11; granted=" + this.m.Granted + "). The return does not charge it again.");
			else if (this.burialOwed())
				::logInfo("Skv.Delve: LOADED: the burial's fee of " + this.burialFee() + " is owed at the return (granted=" + this.m.Granted + ").");
			if (this.roomDone(C.RoomArchive) && !this.hasGrant(C.GrantShelves) && !this.hasGrant(C.GrantCase) && (this.m.Clues & C.ClueSheet) == 0)
				::logInfo("Skv.Delve: LOADED: the archive was resolved with no papers bundled, no sheet read and nothing taken from the case (locks=" + this.m.Locks
					+ "; a save from before stage 2, or the company went on). Accepted: the room stays resolved.");

			if (this.roomDone(C.RoomWebs) && !this.hasGrant(C.GrantWebs))
				::logInfo("Skv.Delve: LOADED: the webs were won with no purse settled and the wrapped kobolds never seen (clues=" + this.m.Clues
					+ "; a save from before stage 2). Accepted, not paid now: the talk in the gallery goes without that clue.");
			if (this.roomDone(C.RoomBones) && !this.hasGrant(C.GrantBones))
				::logInfo("Skv.Delve: LOADED: the bone hall was won with its sword and ring never granted (a save from before stage 2). Accepted, not paid now.");
			if (this.roomDone(C.RoomRefuse) && !this.hasGrant(C.GrantRefuse))
				::logInfo("Skv.Delve: LOADED: the rubbish heap was won with its silver, bracers and papers never granted (burn=" + this.m.Burn
					+ "; a save from before stage 2). Accepted, not paid now.");
			if (this.roomDone(C.RoomStores) && !this.hasGrant(C.GrantStores))
				::logInfo("Skv.Delve: LOADED: the storeroom was searched by the stub with no stake trap, no bottles' check and nothing granted (burn=" + this.m.Burn
					+ "; a save from before stage 2). Accepted, not paid now.");

			if (this.roomDone(C.RoomGallery) && this.m.Tarka == C.TarkaLittle && !this.hasGrant(C.GrantParley))
				::logInfo("Skv.Delve: LOADED: the gallery was talked past with no roll on record (tarka 1; a save from before stage 2). Kept: she let you pass, and her \"a little\" counts at the flame.");
			if (this.m.Tarka == C.TarkaBeaten && !this.hasGrant(C.GrantBags))
				::logInfo("Skv.Delve: LOADED: her band was beaten with her bags never granted (a save from before stage 2). Accepted, not paid now.");
			local cs = this.cultState();
			if (this.roomDone(C.RoomFlame) && (cs == C.CultFought || cs == C.CultUnmaskedFought) && !this.hasGrant(C.GrantAltar))
				::logInfo("Skv.Delve: LOADED: the cult was beaten with the altar's offerings never taken (cult=" + this.m.Cult + "; a save from before stage 2). Accepted, not paid now.");

			if (this.m.Speaker >= C.SpeakerSpared && !this.hasGrant(C.GrantSpeaker))
				::logInfo("Skv.Delve: LOADED: his fate was decided (speaker " + this.m.Speaker + ") with nothing of his granted (a save from before stage 2). Accepted, not paid now.");
			local scr = this.getActiveScreen();
			if (scr != null && scr.ID == "Amara" && this.princeClaims() && !this.hasGrant(C.GrantClaim) && !this.hasGrant(C.GrantAmara))
				::logInfo("Skv.Delve: LOADED: Amara's screen open with the trade prince's terms agreed and his steward never met (a save from before stage 2). Her button opens the steward first.");
		}
	}
});
