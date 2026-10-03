this.skv_bygones_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Marker        = null,
		HouseID       = 0,
		MoralSnapshot = 50,
		ArenzoBase    = 1,
		DayAccepted   = 0,
		ArrivalDay    = 0,
		Act           = 0,
		Zefiro        = 0,
		Checkpoint    = 0,
		Noticed       = false,
		FinePaid      = 0,
		FoxDen        = 0,
		Knock         = 0,
		BribePaid     = 0,
		Mireille      = 0,
		Watch         = 0,
		JailHours     = 0,
		Garden        = 0,
		Ambush        = false,
		Keepsakes     = false,
		Mortuary      = 0,
		Troll         = 0,
		Crypt         = 0,
		Arenzo        = 0,
		Granted       = 0,
		ActorName     = "",
		Rows          = null,
		Res16         = 0,
		Res32         = 0
	},

	function gearOption( _screenID )
	{
		return {
			Text = "{Set our gear right. (open loadout)}",
			function getResult()
			{
				if (!::World.State.showLoadoutFromContract())
					::logError("Skv.Bygones: the loadout did not open from " + _screenID + " (the contract screen hidden or still animating?)");
				return _screenID;
			}
		};
	}

	function hasGrant( _bit ) { return (this.m.Granted & _bit) != 0; }
	function setGrant( _bit ) { this.m.Granted = this.m.Granted | _bit; }
	function hasFox( _bit ) { return (this.m.FoxDen & _bit) != 0; }
	function setFox( _bit ) { this.m.FoxDen = this.m.FoxDen | _bit; }
	function warned() { return this.hasFox(::Const.Skv.Bygones.FoxWarned); }

	function factionOr( _id )
	{
		if (_id == 0) return null;
		try { return ::World.FactionManager.getFaction(_id); }
		catch (e) { ::logError("Skv.Bygones: faction " + _id + " did not resolve - " + e); }
		return null;
	}

	function houseName()
	{
		local f = this.factionOr(this.m.HouseID);
		return f != null ? f.getName() : "The house";
	}

	function townName()
	{
		return (this.m.Home != null && !this.m.Home.isNull()) ? this.m.Home.getName() : "the town";
	}

	function actorName( _r )
	{
		return (_r != null && "actor" in _r && _r.actor != null) ? _r.actor.getName() : "One of the company";
	}

	function goodRow( _text ) { return { id = 1, icon = "ui/icons/special.png", text = _text }; }
	function badRow( _text )  { return { id = 1, icon = "ui/icons/regular_damage.png", text = _text }; }

	function moralRow( _delta, _text )
	{
		local col = _delta < 0 ? ::Const.UI.Color.NegativeEventValue : ::Const.UI.Color.PositiveEventValue;
		return { id = 1, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + col + "]" + _text + " (" + (_delta < 0 ? "" : "+") + _delta + ")[/color]" };
	}

	function relRow( _name, _better )
	{
		return { id = 1, icon = "ui/icons/relations.png",
			text = "Your relations with " + _name + (_better ? " improve" : " worsen") };
	}

	function moral( _delta, _text, _rows )
	{
		if (_delta == 0) return;
		::World.Assets.addMoralReputation(_delta);
		_rows.push(this.moralRow(_delta, _text));
	}

	function townRel( _delta, _why, _rows )
	{
		local t = this.factionOr(this.getFaction());
		if (t == null) { ::logError("Skv.Bygones: the town faction did not resolve; its relation is lost (" + _why + ")."); return; }
		t.addPlayerRelation(_delta, _why);
		_rows.push(this.relRow(this.townName(), _delta > 0));
	}

	function houseRel( _delta, _why, _rows )
	{
		local h = this.factionOr(this.m.HouseID);
		if (h == null) { ::logError("Skv.Bygones: the house (id " + this.m.HouseID + ") did not resolve; its relation is lost (" + _why + ")."); return; }
		h.addPlayerRelation(_delta, _why);
		_rows.push(this.relRow(h.getName(), _delta > 0));
	}

	function checkBase( _base, _ruthless, _extra, _rows )
	{
		local pen = this.moralPenalty(_ruthless);
		if (pen > 0)
			_rows.push(this.badRow("Your reputation goes ahead of you (-" + pen + " to the attempt)"));
		return ::Skv.Check.scaledBase(this, _base) - pen + _extra;
	}

	function knockExtra()
	{
		local C = ::Const.Skv.Bygones;
		return (this.m.Noticed ? -C.NoticedPenalty : 0) + (this.warned() ? C.WarnedBonus : 0);
	}

	function spendHours( _h )
	{
		if (_h <= 0) return;
		if (::World.Assets != null)
		{
			::World.Assets.m.LastFoodConsumed = ::World.Assets.m.LastFoodConsumed - _h * (this.World.getTime().SecondsPerDay / 24.0);
			::World.Assets.consumeFood();
		}
		::Skv.dbg("Skv.Bygones: " + _h + " hours spent off the clock (food charged)");
	}

	function topBand()
	{
		return this.getDifficultyMult() >= ::Const.Skv.Bygones.SizeSplitDiff;
	}

	function keepsakePaths()
	{
		local C = ::Const.Skv.Bygones;
		local p = [C.ItemTome];
		if (this.topBand()) { p.push(C.ItemRuby); p.push(C.ItemBanner); }
		return p;
	}

	function seedPaths()
	{
		local C = ::Const.Skv.Bygones;
		local p = [];
		for (local i = 0; i < C.SeedCount; i = i + 1) p.push(C.ItemSeeds);
		return p;
	}

	function arrivedLate()
	{
		local day = this.m.ArrivalDay > 0 ? this.m.ArrivalDay : ::World.getTime().Days;
		return day - this.m.DayAccepted > ::Const.Skv.Bygones.LateDays;
	}

	function arenzoGrowth()
	{
		local s = ::Math.max(::Const.Skv.Bygones.ArenzoBase, this.m.ArenzoBase);
		if (this.m.JailHours > 0) s = s + 1;
		if (this.arrivedLate()) s = s + 1;
		return s;
	}

	function arenzoSize()
	{
		return ::Math.min(3, this.arenzoGrowth());
	}

	function arenzoChampion()
	{
		return this.arenzoGrowth() > 3;
	}

	function moralPenalty( _ruthless )
	{
		local C = ::Const.Skv.Bygones;
		local s = this.m.MoralSnapshot;
		local off = _ruthless ? (s - C.RuthlessCeiling) : (C.DecentFloor - s);
		if (off <= 0) return 0;
		return ::Math.min(C.PenaltyCap, off * C.PenaltyPerPoint);
	}

	function finalPay()
	{
		local pay = this.m.Payment.getOnCompletion();
		if (this.m.Crypt == 2) pay = ::Math.floor(pay * ::Const.Skv.Bygones.PoorPayMult);
		return pay;
	}

	function bountyPay()
	{
		return ::Math.floor(this.m.Payment.getOnCompletion() * ::Const.Skv.Bygones.BountyMult);
	}

	function headPay()
	{
		return ::Math.floor(this.m.Payment.getOnCompletion() * ::Const.Skv.Bygones.HeadMult);
	}

	function bribeCost()
	{
		return ::Math.max(10, ::Math.round(this.m.Payment.getOnCompletion() * ::Const.Skv.Bygones.BribeMult / 10.0) * 10);
	}

	function thanksPay()
	{
		return ::Math.floor(this.m.Payment.getOnCompletion() * ::Const.Skv.Bygones.ThanksMult);
	}

	function fled()
	{
		return this.m.Crypt == 2;
	}

	function meadItems()
	{
		local items = ::Skv.Loot.make([::Const.Skv.Bygones.ItemMead]);
		foreach (it in items)
		{
			try { it.setAmount(::Const.Skv.Bygones.MeadAmount); }
			catch (e) { ::logError("Skv.Bygones: could not set the mead's amount (it ships as made): " + e); }
		}
		return items;
	}

	function drawerOpen()
	{
		return this.m.Mireille == 1 && this.m.Zefiro != 3;
	}

	function packBudget()
	{
		local C = ::Const.Skv.Bygones;
		return ::Math.maxf(C.PackMin, C.PackBase * this.getDifficultyMult() * this.getScaledDifficultyMult());
	}

	function watchBudget()
	{
		local C = ::Const.Skv.Bygones;
		local b = ::Math.maxf(C.WatchMin, C.WatchBase * this.getDifficultyMult() * this.getScaledDifficultyMult());
		if (this.m.Noticed) b = b + C.WatchNoticedExtra;
		return b;
	}

	function cityScreen()
	{
		local C = ::Const.Skv.Bygones;
		if (this.m.Zefiro == 0) return "Curator";
		if (this.m.Checkpoint == 0) return "Checkpoint";
		if (!this.hasFox(C.FoxDoorDone)) return "FoxDoor";
		if (!this.hasFox(C.FoxDogDone)) return "Storyteller";
		if (this.m.Mireille == 0 && this.m.Watch == 0) return "Knock";
		return "Records";
	}

	function siteScreen()
	{
		if (this.m.Garden == 0) return "Anglemire";
		if (this.m.Garden == 3 && this.m.Ambush && this.m.Crypt == 0) return "FloorGives";
		if (this.m.Crypt == 0 && this.m.Mortuary == 0) return "Mortuary";
		if (this.m.Crypt == 0) return "Crypt";
		if (this.m.Crypt == 1 && this.m.Arenzo == 0) return "ArenzoFate";
		return null;
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

	function isSolidGround( _t )
	{
		local T = ::Const.World.TerrainType;
		return _t.Type != T.Ocean && _t.Type != T.Shore && _t.Type != T.Impassable;
	}

	function landSteps( _from, _to )
	{
		try
		{
			local nav = ::World.getNavigator().createSettings();
			nav.ActionPointCosts = ::Const.World.TerrainTypeNavCost_Flat;
			local p = ::World.getNavigator().findPath(_from, _to, nav, 0);
			if (p.isEmpty()) return -1;
			return p.getSize();
		}
		catch (e) { ::logError("Skv.Bygones: findPath threw - " + e); }
		return -2;
	}

	function nearMapEdge( _t )
	{
		local E = ::Const.Skv.Bygones.MarkerEdge;
		local ms = ::World.getMapSize();
		return _t.SquareCoords.X <= E || _t.SquareCoords.X >= ms.X - E
			|| _t.SquareCoords.Y <= E || _t.SquareCoords.Y >= ms.Y - E;
	}

	function spawnMarker()
	{
		if (!::MSU.isNull(this.m.Marker)) return;
		local C = ::Const.Skv.Bygones;
		local home = this.m.Home.getTile();
		local shores = this.m.Home.getSurroundingTilesOfType([::Const.World.TerrainType.Shore], C.MarkerRadius);
		local valid = [];
		local seen = {};
		local edge = 0;
		foreach (s in shores)
		{

			for (local i = 0; i != 6; i = ++i)
			{
				if (!s.hasNextTile(i)) continue;
				local t = s.getNextTile(i);
				if (t.IsOccupied || !this.isSolidGround(t)) continue;
				if (t.getDistanceTo(home) < C.MarkerMinDist) continue;
				local key = t.Coords.X + "," + t.Coords.Y;
				if (key in seen) continue;
				seen[key] <- true;
				if (this.nearMapEdge(t)) { edge = edge + 1; continue; }
				valid.push(t);
			}
		}

		local total = valid.len();
		local tried = 0;
		local cut = 0;
		local far = 0;
		local tile = null;
		local steps = 0;
		while (valid.len() > 0)
		{
			local k = ::Math.rand(0, valid.len() - 1);
			local t = valid[k];
			valid.remove(k);
			tried = tried + 1;
			local n = this.landSteps(home, t);
			if (n < 0) { cut = cut + 1; continue; }
			if (n > C.MarkerPathMax) { far = far + 1; continue; }
			tile = t;
			steps = n;
			break;
		}
		local route = "inland of the shore (" + total + " candidates, " + edge + " more at the map edge; tried " + tried
			+ ": " + cut + " cut off, " + far + " over " + C.MarkerPathMax + " steps) " + steps + " steps on foot";
		if (tile == null)
		{

			route = "FALLBACK (no walkable solid tile beside a shore tile, " + C.MarkerMinDist + "-" + C.MarkerRadius + " out: "
				+ total + " candidates, " + cut + " cut off, " + far + " too far, " + edge + " at the map edge)";
			tile = this.getTileToSpawnLocation(home, 3, 8);
		}
		tile.clear();
		this.m.Marker = this.WeakTableRef(::World.spawnLocation("scripts/entity/world/locations/skv_bygones_location", tile.Coords));
		this.m.Marker.onSpawned();
		this.m.Marker.setDiscovered(true);
		this.m.Marker.setAttackable(false);
		this.m.Marker.getSprite("selection").Visible = true;
		::World.uncoverFogOfWar(this.m.Marker.getTile().Pos, 500.0);
		::Skv.dbg("Skv.Bygones: Emberhold at " + tile.Coords.X + "," + tile.Coords.Y + " terrain=" + tile.Type
			+ " route=" + route + " " + tile.getDistanceTo(home) + " tiles from " + this.m.Home.getName());
	}

	function onArenzoPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Bygones: onArenzoPlaced got a null entity - Arenzo is a plain size-1 ghoul.");
			return;
		}
		local size = this.arenzoSize();
		try
		{
			for (local i = 1; i < size; i = i + 1) _e.grow(true);
		}
		catch (e) { ::logError("Skv.Bygones: Arenzo could not grow to size " + size + ": " + e); }
		local regen = false;
		try
		{
			_e.getSkills().add(this.new("scripts/skills/racial/unhold_racial"));
			regen = _e.getSkills().hasSkill("racial.unhold");
		}
		catch (e) { ::logError("Skv.Bygones: Arenzo could not take the regeneration (racial.unhold): " + e); }

		local champ = false;
		if (this.arenzoChampion())
		{
			try { champ = _e.makeMiniboss(); }
			catch (e) { ::logError("Skv.Bygones: makeMiniboss threw on Arenzo: " + e); }
			if (!champ) ::logError("Skv.Bygones: Arenzo should be a champion (growth " + this.arenzoGrowth() + ") but makeMiniboss returned false (no Wildmen DLC?).");
		}
		try
		{
			_e.getSkills().update();

			_e.setHitpoints(_e.getHitpointsMax());
		}
		catch (e) { ::logError("Skv.Bygones: could not fill Arenzo's HP: " + e); }
		::Skv.dbg("Skv.Bygones: Arenzo is in. size=" + _e.getSize() + " (wanted " + size + ": base " + this.m.ArenzoBase
			+ ", jailed=" + (this.m.JailHours > 0) + ", late=" + this.arrivedLate() + ")"
			+ " HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax() + " regen=" + regen
			+ " champion=" + champ + " (growth " + this.arenzoGrowth() + ")");
	}

	function onTrollPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Bygones: onTrollPlaced got a null entity - the troll is not in the fight.");
			return;
		}
		local C = ::Const.Skv.Bygones;
		try
		{
			local b = _e.getBaseProperties();
			b.HitpointsMult = b.HitpointsMult * C.TrollHPMult;
			b.MeleeSkill = b.MeleeSkill - C.TrollMeleeLoss;
			_e.getSkills().update();

			_e.setHitpoints(::Math.max(1, ::Math.floor(_e.getHitpointsMax() * C.TrollHPStart)));
		}
		catch (e) { ::logError("Skv.Bygones: could not weaken the troll: " + e); }
		local dazed = false;
		try
		{
			_e.getSkills().add(this.new("scripts/skills/effects/dazed_effect"));
			dazed = _e.getSkills().hasSkill("effects.dazed");
		}
		catch (e) { ::logError("Skv.Bygones: could not daze the troll: " + e); }
		::Skv.dbg("Skv.Bygones: the troll is in, faction=" + _e.getFaction()
			+ " (PlayerAnimals=" + ::Const.Faction.PlayerAnimals + ") HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax()
			+ " melee=" + _e.getBaseProperties().MeleeSkill + " dazed=" + dazed);
	}

	function resolveCurator( _calm )
	{
		if (this.m.Zefiro != 0) return "CuratorAfter";
		local C = ::Const.Skv.Bygones;
		local rows = [];
		if (_calm)
		{

			this.moral(C.MoralCalm, "You were patient with a frightened old man", rows);
			local r = ::Skv.Check.charm(this, this.checkBase(C.ZefiroCalmBase, false, 0, rows));
			if (r.ok)
			{
				this.m.Zefiro = 1;
				rows.extend(::Skv.XP.check(r));
				if (!this.hasGrant(C.GrantHolyWater))
				{
					this.setGrant(C.GrantHolyWater);
					rows.extend(::Skv.Loot.haul(::Skv.Loot.make([C.ItemHolyWater])));
				}
			}
			else
			{
				this.m.Zefiro = 2;
				rows.push(this.badRow("He talks, but he gives you nothing from the cases"));
			}
		}
		else
		{
			this.m.Zefiro = 3;
			rows.push(this.badRow("He talks, and he will not forget how he was made to"));

			if (!this.hasGrant(C.GrantAntidote))
			{
				this.setGrant(C.GrantAntidote);
				rows.extend(::Skv.Loot.haul(::Skv.Loot.make([C.ItemAntidote])));
			}
			this.moral(C.MoralLean, "You bullied a frightened old man into talking", rows);
		}
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: CURATOR -> Zefiro=" + this.m.Zefiro + " actor=" + this.m.ActorName);
		return "CuratorAfter";
	}

	function resolveCheckpoint( _talk )
	{
		if (this.m.Checkpoint != 0) return "CheckpointAfter";
		local C = ::Const.Skv.Bygones;
		local rows = [];
		if (!_talk)
		{
			this.m.Checkpoint = 1;
			this.m.Noticed = true;
			rows.push(this.badRow("The watch knows who you are, and where you were going"));

			this.houseRel(C.HouseDeclared, "Declared itself at the harbour checkpoint", rows);
		}
		else
		{
			local r = ::Skv.Check.guile(this, ::Skv.Check.scaledBase(this, C.CheckpointBase));
			if (r.ok)
			{
				this.m.Checkpoint = 2;
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("Nobody writes your name down"));
			}
			else
			{
				this.m.Checkpoint = 3;
				this.m.Noticed = true;
				local fine = ::Math.min(C.CheckpointFine, ::World.Assets.getMoney());
				this.m.FinePaid = fine;
				if (fine > 0) rows.push(::Legends.EventList.changeMoney(-fine));
				rows.push(this.badRow("The watch knows who you are, and where you were going"));
			}
		}
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: CHECKPOINT -> " + this.m.Checkpoint + " noticed=" + this.m.Noticed + " fine=" + this.m.FinePaid);
		return "CheckpointAfter";
	}

	function resolveDoor()
	{
		local C = ::Const.Skv.Bygones;
		if (this.hasFox(C.FoxDoorDone)) return "Storyteller";
		local rows = [];
		local r = ::Skv.Check.charm(this, this.checkBase(C.VeliaBase, false, 0, rows));
		this.setFox(C.FoxDoorDone);
		if (r.ok)
		{
			this.setFox(C.FoxVelia);
			rows.extend(::Skv.XP.check(r));
		}
		else
		{
			rows.push(this.badRow("Velia keeps you on the step too long"));
		}
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: VELIA -> passed=" + r.ok);
		return "Storyteller";
	}

	function resolveDog()
	{
		local C = ::Const.Skv.Bygones;
		if (this.hasFox(C.FoxDogDone)) return "Knock";
		local rows = [];
		this.setFox(C.FoxDogDone);
		if (this.hasFox(C.FoxVelia))
		{
			local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, C.DogBase));
			if (r.ok)
			{
				this.setFox(C.FoxWarned);
				rows.extend(::Skv.XP.check(r));
				rows.push(this.goodRow("A moment's warning before the knock"));
			}
			else
			{
				rows.push(this.badRow("Nobody looks at the dog until it is too late"));
			}
		}
		else
		{
			rows.push(this.badRow("No time to notice anything"));
		}
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: DOG -> warned=" + this.warned());
		return "Knock";
	}

	function resolveKnock( _method )
	{
		if (this.m.Mireille != 0 || this.m.Watch != 0) return this.cityScreen();
		local C = ::Const.Skv.Bygones;
		local rows = [];
		local r = null;
		if (_method == 1)
			r = ::Skv.Check.stealth(this, this.checkBase(C.BackDoorBase, false, this.knockExtra(), rows), 0.5);
		else if (_method == 2)
			r = ::Skv.Check.charm(this, this.checkBase(C.TalkWatchBase, false, this.knockExtra(), rows));
		else if (_method == 3)
			r = ::Skv.Check.guile(this, this.checkBase(C.BribeBase, false, this.knockExtra(), rows));
		else if (_method == 4)
			r = ::Skv.Check.guile(this, this.checkBase(C.DisguiseBase, false, this.knockExtra(), rows));
		else
			r = ::Skv.Check.charm(this, this.checkBase(C.GiveUpBase, true, 0, rows));
		this.m.Knock = _method + (r.ok ? C.KnockPassed : 0);
		if (r.ok) rows.extend(::Skv.XP.check(r));

		if (_method == 3 && this.m.BribePaid == 0)
		{
			this.m.BribePaid = ::Math.min(this.bribeCost(), ::World.Assets.getMoney());
			if (this.m.BribePaid > 0) rows.push(::Legends.EventList.changeMoney(-this.m.BribePaid));
			if (!r.ok) rows.push(this.badRow("They take the money, and they come in anyway"));
		}

		if (_method == 6)
		{
			this.moral(C.MoralGivenUp, "You handed a storyteller to the watch", rows);
			this.townRel(C.TownGivenUp, "Handed one of their own to the watch", rows);
			if (r.ok)
			{
				this.m.Mireille = 2;
				if (!this.hasGrant(C.GrantBounty))
				{
					this.setGrant(C.GrantBounty);
					rows.push(::Legends.EventList.changeMoney(this.bountyPay()));
				}
				this.houseRel(C.HouseGivenUp, "Gave the watch a wanted woman", rows);
			}
			else
			{
				this.m.Mireille = 3;
				rows.push(this.badRow("They take her, and they pay you nothing"));
			}
			this.m.Rows = rows;
			::Skv.dbg("Skv.Bygones: KNOCK give-up -> believed=" + r.ok + " Mireille=" + this.m.Mireille);
			return "GivenUp";
		}

		if (r.ok)
		{
			this.m.Mireille = 1;
			this.moral(C.MoralSaved, "You helped a hunted woman get away", rows);
			this.townRel(C.TownMireille, "Got Mireille away from the watch", rows);
			this.m.Rows = rows;
			::Skv.dbg("Skv.Bygones: KNOCK method " + _method + " PASSED -> she is away");
			return "Away";
		}
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: KNOCK method " + _method + " FAILED -> cornered");
		return "Cornered";
	}

	function grantWeapons()
	{
		local C = ::Const.Skv.Bygones;
		if (this.hasGrant(C.GrantWeapons)) return;
		this.setGrant(C.GrantWeapons);
		local items = ::Skv.Loot.make([C.ItemSap, C.ItemSword, C.ItemMace]);
		foreach (it in items)
		{
			if (it.getID() == "weapon.longsword")
			{
				try { it.setCondition(::Math.floor(it.getConditionMax() * C.SwordCondition)); }
				catch (e) { ::logError("Skv.Bygones: could not break the naval sword: " + e); }
			}
		}
		::Skv.Loot.haul(items);
		::Skv.dbg("Skv.Bygones: Velia's weapons granted (" + items.len() + ")");
	}

	function resolveSurrender()
	{
		if (this.m.Watch != 0) return "Jail";
		local C = ::Const.Skv.Bygones;
		local rows = [];
		this.m.Watch = 3;
		this.m.Mireille = 4;
		this.m.Knock = 7;
		if (this.m.JailHours == 0)
		{
			this.m.JailHours = C.JailHours;
			this.spendHours(C.JailHours);
		}
		rows.push(this.badRow("Three days in the cells, eating your own provisions"));
		rows.push(this.badRow("Mireille is taken"));
		this.townRel(C.TownArrested, "Was arrested in the West Drenches", rows);
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: SURRENDERED -> jail " + this.m.JailHours + "h, Mireille taken");
		return "Jail";
	}

	function resolveGarden()
	{
		if (this.m.Garden != 0) return "GardenAfter";
		local C = ::Const.Skv.Bygones;
		local rows = [];
		this.moral(C.MoralTend, "You trod carefully among growing things", rows);
		local r = ::Skv.Check.tracking(this, this.checkBase(C.GardenBase, false, 0, rows));
		if (!r.ok)
		{
			this.m.Garden = 2;
			rows.push(this.badRow("A gourd splits under a boot, and the garden goes still"));
			this.m.Rows = rows;
			::Skv.dbg("Skv.Bygones: GARDEN tracking FAILED -> they hide");
			return "GardenAfter";
		}
		rows.extend(::Skv.XP.check(r));
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: GARDEN tracking passed -> the leshys show themselves");
		return "Leshys";
	}

	function resolveLeshys()
	{
		if (this.m.Garden != 0) return "GardenAfter";
		local C = ::Const.Skv.Bygones;
		local rows = [];
		local r = ::Skv.Check.charm(this, this.checkBase(C.LeshyBase, false, 0, rows));
		if (r.ok)
		{
			this.m.Garden = 1;
			this.m.Keepsakes = true;
			rows.extend(::Skv.XP.check(r));
			local paths = [];
			if (!this.hasGrant(C.GrantKeepsakes)) { this.setGrant(C.GrantKeepsakes); paths.extend(this.keepsakePaths()); }
			if (!this.hasGrant(C.GrantSeeds)) { this.setGrant(C.GrantSeeds); paths.extend(this.seedPaths()); }
			rows.extend(::Skv.Loot.haul(::Skv.Loot.make(paths)));
		}
		else
		{
			this.m.Garden = 2;
			rows.push(this.badRow("They listen, and then they are only gourds again"));
		}
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: LESHYS -> Garden=" + this.m.Garden);
		return "GardenAfter";
	}

	function resolveMortuary()
	{
		if (this.m.Mortuary != 0) return "Crypt";
		local C = ::Const.Skv.Bygones;
		local rows = [];
		local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, C.MortuaryBase));
		this.m.Mortuary = r.ok ? 1 : 2;
		if (r.ok) rows.extend(::Skv.XP.check(r));
		this.m.Rows = rows;
		::Skv.dbg("Skv.Bygones: MORTUARY -> read=" + r.ok);
		return "Crypt";
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_bygones";
		this.m.Name = "Let Bygones Be";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"An envoy of the house wants a ruined keep up the coast searched, and wants outsiders to do it.",
			"The house is digging up an old enemy's grave, and it wants hired hands with no stake in what they find."
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
		_vars.push(["SKVTOWN", this.townName()]);
	}

	function start()
	{
		local C = ::Const.Skv.Bygones;
		this.m.DifficultyMult = this.Math.rand(C.DiffLo, C.DiffHi) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, C.PayBase);

		this.m.Payment.Advance = 0.0;
		this.m.Payment.Completion = 1.0;

		local h = ::Skv.Trail.house(this.m.Home);
		this.m.HouseID = h != null ? h.getID() : 0;
		if (h == null) ::logError("Skv.Bygones: the host " + this.m.Home.getName() + " has no noble house at creation - the action should not have posted it.");
		this.m.ArenzoBase = C.ArenzoBase;
		::Skv.dbg("Skv.Bygones: created at " + this.m.Home.getName() + " diff=" + this.m.DifficultyMult
			+ " pool=" + this.m.Payment.Pool + " fee=" + this.finalPay() + " house=" + this.houseName()
			+ " arenzoBase=" + this.m.ArenzoBase);
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Search the ruin of Emberhold up the coast",
					"Bring back proof of what House Davian was"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				local c = this.Contract;

				local mr = 50;
				try { mr = ::World.Assets.getMoralReputation(); }
				catch (e) { ::logError("Skv.Bygones: getMoralReputation threw; the snapshot is neutral 50 - " + e); }
				c.m.MoralSnapshot = ::Math.max(0, ::Math.min(100, mr.tointeger()));
				c.m.DayAccepted = ::World.getTime().Days;
				::Skv.dbg("Skv.Bygones: ACCEPTED day=" + c.m.DayAccepted + " moral snapshot=" + c.m.MoralSnapshot
					+ " (penalty decent " + c.moralPenalty(false) + " / ruthless " + c.moralPenalty(true) + ")");

				this.World.Contracts.setActiveContract(c);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				local c = this.Contract;
				if (c.m.Act == 0)
				{
					c.m.BulletpointsObjectives = [
						"See the curator in " + c.townName(),
						"Search the ruin of Emberhold"
					];
				}
				else
				{
					c.m.BulletpointsObjectives = [
						"Search the ruin of Emberhold up the coast"
					];
				}
				if (!::MSU.isNull(c.m.Marker))
				{
					c.m.Marker.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;

				local f = this.Flags.get("F19");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V19") == f;
					local ran = this.Flags.get("R19") == f;
					this.Flags.set("F19", "");
					this.Flags.set("V19", "");
					this.Flags.set("R19", "");

					if (!won && !ran)
					{
						::Skv.dbg("Skv.Bygones: " + f + " was launched but never resolved - no state change.");
					}
					else if (f == "Skv19Watch")
					{

						local rows = [];
						c.m.Watch = won ? 1 : 2;
						c.m.Mireille = won ? 1 : 4;
						if (won)
						{
							c.townRel(C.TownWatchFight + C.TownMireille, "Fought the town watch to get Mireille away", rows);
							c.moral(C.MoralSaved, "You helped a hunted woman get away", rows);
						}
						else
						{
							c.townRel(C.TownWatchFight, "Fought the town watch", rows);
						}
						c.m.Rows = rows;
						::Skv.dbg("Skv.Bygones: the watch fight " + (won ? "WON" : "FLED") + " -> Watch=" + c.m.Watch
							+ " Mireille=" + c.m.Mireille);
						c.setScreen("WatchAfter");
						this.World.Contracts.showActiveContract();
						return;
					}
					else if (f == "Skv19Leshy")
					{
						c.m.Garden = 3;
						c.m.Ambush = won;
						c.m.Keepsakes = won;
						::Skv.dbg("Skv.Bygones: the leshy fight " + (won ? "WON -> the floor gives way" : "FLED -> the garden is lost"));
						c.setScreen(won ? "FloorGives" : "GardenFled");
						this.World.Contracts.showActiveContract();
						return;
					}
					else if (f == "Skv19Crypt")
					{
						if (won)
						{
							c.m.Crypt = 1;
							::Skv.dbg("Skv.Bygones: the crypt is WON -> Arenzo's fate");
							c.setScreen("ArenzoFate");
						}
						else
						{

							c.m.Crypt = 2;
							c.killMarker();
							::Skv.dbg("Skv.Bygones: FLED the crypt -> the site is gone, a poor result");
							c.setScreen("Fled");
						}
						this.World.Contracts.showActiveContract();
						return;
					}
				}

				if (c.m.Act == 0)
				{
					if (c.m.Home == null || c.m.Home.isNull()) return;
					if (c.isPlayerAt(c.m.Home))
					{
						if (!this.TempFlags.get("CityOpen"))
						{
							this.TempFlags.set("CityOpen", true);
							if (c.getActiveScreen() == null)
							{
								c.setScreen(c.cityScreen());
								this.World.Contracts.showActiveContract();
							}
						}
					}
					else
					{
						this.TempFlags.set("CityOpen", false);
					}
					return;
				}

				if (::MSU.isNull(c.m.Marker)) return;
				if (c.isPlayerAt(c.m.Marker))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						if (c.m.ArrivalDay == 0)
						{
							c.m.ArrivalDay = ::World.getTime().Days;
							c.m.Act = 2;
							::Skv.dbg("Skv.Bygones: AT EMBERHOLD day " + c.m.ArrivalDay + " (accepted " + c.m.DayAccepted
								+ ", late=" + c.arrivedLate() + ", jailed=" + (c.m.JailHours > 0) + ") -> Arenzo size " + c.arenzoSize()
								+ (c.arenzoChampion() ? " + CHAMPION" : ""));
						}
						local s = c.siteScreen();
						if (s != null && c.getActiveScreen() == null)
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

			function onCombatWatch()
			{
				local c = this.Contract;
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.CombatID = "Skv19Watch";
				p.Tile = ::World.State.getPlayer().getTile();
				p.TerrainTemplate = "tactical.plains";
				p.LocationTemplate = clone ::Const.Tactical.LocationTemplate;

				p.LocationTemplate.Template = clone ::Const.Tactical.LocationTemplate.Template;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = ::Const.Tactical.FortificationType.None;

				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				try { p.Music = ::Const.Music.CivilianTracks; } catch (e) { ::logError("Skv.Bygones: no CivilianTracks - " + e); }
				p.Entities = [];
				local budget = c.watchBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.Militia, budget,
					::Const.Faction.Enemy, "Bygones/Watch", ::Const.World.Spawn.Militia);
				::Skv.dbg("Skv.Bygones: the watch fight. budget=" + budget + " noticed=" + c.m.Noticed + " units=" + p.Entities.len());
				this.Flags.set("F19", "Skv19Watch");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatLeshy()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local tile = c.m.Marker.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.LocationTemplate = clone ::Const.Tactical.LocationTemplate;
				p.LocationTemplate.Template = clone ::Const.Tactical.LocationTemplate.Template;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = ::Const.Tactical.FortificationType.None;
				p.Tile = tile;
				p.CombatID = "Skv19Leshy";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) { ::logError("Skv.Bygones: no BeastsTracks - " + e); }
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];
				local n = c.topBand() ? C.LeshyHigh : C.LeshyLow;
				for (local i = 0; i < n; i = i + 1)
				{
					p.Entities.push({
						ID = ::Const.EntityType.SchratSmall,
						Variant = 0,
						Row = -1,
						Script = "scripts/entity/tactical/enemies/schrat_small",
						Faction = fac
					});
				}
				::Skv.Spawn.check(p.Entities, "Bygones/Leshy");
				::Skv.dbg("Skv.Bygones: the leshy fight. saplings=" + n);
				this.Flags.set("F19", "Skv19Leshy");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatCrypt()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local tile = c.m.Marker.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.LocationTemplate = clone ::Const.Tactical.LocationTemplate;
				p.LocationTemplate.Template = clone ::Const.Tactical.LocationTemplate.Template;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = ::Const.Tactical.FortificationType.None;
				p.Tile = tile;
				p.CombatID = "Skv19Crypt";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) { ::logError("Skv.Bygones: no BeastsTracks - " + e); }

				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Line;

				p.EnemyDeploymentType = c.m.Ambush
					? ::Const.Tactical.DeploymentType.Circle
					: ::Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];
				p.Entities.push({
					ID = ::Const.EntityType.Ghoul,
					Variant = 0,
					Row = 1,
					Script = "scripts/entity/tactical/enemies/ghoul",
					Faction = fac,
					Name = C.ArenzoName,
					Callback = c.onArenzoPlaced.bindenv(c)
				});
				local budget = c.packBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.Ghouls, budget,
					fac, "Bygones/Pack", ::Const.World.Spawn.Ghouls);
				if (c.m.Troll == 1 && !c.m.Ambush)
				{

					p.Entities.push({
						ID = ::Const.EntityType.Unhold,
						Variant = 0,
						Row = 1,
						Script = "scripts/entity/tactical/enemies/unhold",
						Faction = ::Const.Faction.PlayerAnimals,
						Name = C.TrollName,
						Callback = c.onTrollPlaced.bindenv(c)
					});
				}
				::Skv.Spawn.check(p.Entities, "Bygones/Crypt");
				::Skv.dbg("Skv.Bygones: the crypt. arenzo size=" + c.arenzoSize() + (c.arenzoChampion() ? " +champion" : "")
					+ " pack budget=" + budget
					+ " (" + C.PackBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ ", floor " + C.PackMin + ") units=" + p.Entities.len() + " troll=" + (c.m.Troll == 1 && !c.m.Ambush ? "FREED (ally)" : "not in the fight")
					+ " deploy=" + (c.m.Ambush ? "AMBUSH (Circle)" : "Line"));

				this.Flags.set("F19", "Skv19Crypt");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv19") return;
				this.Flags.set("V19", _combatID);
				::Skv.dbg("Skv.Bygones: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F19");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R19", f);
				::Skv.dbg("Skv.Bygones: retreated from " + f + " (id=" + _combatID + ")");
			}
		});

		this.m.States.push({
			ID = "Return",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Return to " + this.Contract.townName()
				];
			}

			function update()
			{
				local c = this.Contract;
				if (c.m.Act != 3) return;
				if (c.m.Home == null || c.m.Home.isNull()) return;
				local arrived = c.isPlayerAt(c.m.Home);
				if (!arrived)
				{
					try
					{
						local t = ::World.State.getCurrentTown();
						if (t != null && t.getID() == c.m.Home.getID()) arrived = true;
					}
					catch (e) { ::Skv.dbg("Skv.Bygones: getCurrentTown threw - " + e); }
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
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "Let Bygones Be",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgOffer + ".png[/img]{The woman who sends for you wears a black breastplate and a red cloak, and she does not sit. %SKVNAME%Ianareth Alazario%SKVNAME_OFF%, envoy of %SKVHOUSE%.%SPEECH_ON%Up the coast there is a keep called Emberhold. It belonged to House Davian, who made war on my house a long lifetime ago and lost. The festival comes soon, and the people should be reminded what the Davians were. I want the place searched, and whatever you find brought to me.\n\nYou are wondering why I do not send my own men. Proof that my house's soldiers dig up is proof nobody believes. Proof that strangers bring back is a story.%SPEECH_OFF%There is a curator in town, she adds, who knows more of the place than anyone. She does not say it as though she likes him.}";
				this.Options = [
					{
						Text = "{We'll search your ruin.}",
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
					Text = "{Find other strangers.}",
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
					Text = "{Back to the envoy.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Bygones.ImgLore + ".png[/img]{%randombrother% has heard of the Davians, which is more than most people have, and says so with some pride.%SPEECH_ON%Great house, once. Fought the house that rules here now, and lost, and that was the end of them. My grandmother said you could be flogged in some towns for singing the songs they used to sing about them.%SPEECH_OFF%%randombrother2% is less interested in the singing than in the keep.%SPEECH_ON%A burned keep with a crypt under it and nobody living near. Whatever has a place like that to itself has had a long time to get comfortable, and I would not give it any longer than we have to.%SPEECH_OFF%The oldest of them has been quiet until now.%SPEECH_ON%This whole nation had a war like that. The side with the devils won it, burned every book that said otherwise, and chased out the scholars who kept them. Now they are asking those scholars back. Nobody asks back the people they chased off unless they want something written down.%SPEECH_OFF%Somebody wonders aloud why a house that won its war needs to dig up the side that lost, and nobody has an answer.}";
			}
		});

		this.m.Screens.push({
			ID = "Curator",
			Title = "The Curator",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local warn = c.moralPenalty(false) > 0
					? "\n\nHe has heard of your company, and it shows in how far he stands from you."
					: "";
				this.Text = "[img]gfx/ui/events/" + C.ImgCurator + ".png[/img]{The museum was a courthouse once, and it still has a courthouse's steps. The curator, %SKVNAME%Zefiro Balinger%SKVNAME_OFF%, is a thin man in good clothes gone shiny at the elbows, and he spends your whole first minute looking past you at the window. The watchmen who stood on the corner outside are gone, and he has noticed.\n\nHe knows the keep. He knows a great deal more than that, plainly, and he is deciding how much a company of armed strangers sent by the envoy should be allowed to hear." + warn + "}";
				this.List = [];
				this.Options = [
					{
						Text = "{Talk him down, gently.}",
						function getResult() { return this.Contract.resolveCurator(true); }
					},
					{
						Text = "{Threaten him until he talks.}",
						function getResult() { return this.Contract.resolveCurator(false); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CuratorAfter",
			Title = "The Curator",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local body;
				if (c.m.Zefiro == 1)
					body = "It takes patience, and %SKVNAME%" + c.m.ActorName + "%SKVNAME_OFF% has it. By the end Zefiro is sitting down, and talking, and then he is unlocking a case. He takes out a little flask of blessed water from some old temple's store and holds it a moment before he hands it over.%SPEECH_ON%Nobody will miss it now. Take it where you are going. And there is someone in the West Drenches I need you to look in on, before anyone else does. A friend. She tells the children the stories the house would rather they forgot, and the watch has started to listen.%SPEECH_OFF%";
				else if (c.m.Zefiro == 2)
					body = "He does not calm down so much as run out of fear to spend. He tells you about the keep, grudgingly, and then about something he plainly cares about more.%SPEECH_ON%A friend of mine in the West Drenches. She tells the children the stories the house would rather they forgot, and the watch has started to listen. See that they have not found her yet.%SPEECH_OFF%The cases stay locked.";
				else
					body = "It does not take much. A hand on the shoulder, a word about how very far the watch has gone, and he is telling you everything at once, including the thing he plainly did not want to tell anyone, and pushing a little stoppered vial across the desk as though it might buy him something.%SPEECH_ON%A friend. In the West Drenches. She tells the children the old stories, and the watch is looking for her. Please. If they take her, they will take me next.%SPEECH_OFF%";
				this.Text = "[img]gfx/ui/events/" + C.ImgCurator + ".png[/img]{" + body + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{To the West Drenches, then.}",
						function getResult() { return "Checkpoint"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Checkpoint",
			Title = "The Checkpoint",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgCheckpoint + ".png[/img]{The way down into the West Drenches is barred with a cart and a rope, and behind them a customs man called %SKVNAME%Tamrin Credence%SKVNAME_OFF% is going through everything anybody carries. A slave broke his chains in the market this morning and went into the harbour, and until somebody finds him the whole quarter is being turned inside out.\n\nTamrin smiles a great deal and writes everything down. His deputies do not smile at all.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Declare everything. We have nothing to hide.}",
						function getResult() { return this.Contract.resolveCheckpoint(false); }
					},
					{
						Text = "{Talk our way through without giving names.}",
						function getResult() { return this.Contract.resolveCheckpoint(true); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CheckpointAfter",
			Title = "The Checkpoint",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local body;
				if (c.m.Checkpoint == 1)
					body = "Tamrin writes it all down, every blade and every name, and thanks you for your honesty. One of the deputies goes off up the hill at a trot before you are through the rope.";
				else if (c.m.Checkpoint == 2)
					body = "%SKVNAME%" + c.m.ActorName + "%SKVNAME_OFF% talks about the weather and the fishing and a cousin who works the docks, and somewhere in it Tamrin forgets to ask for names. The rope is lifted. Nobody writes anything down.";
				else
					body = "The story falls apart on the second question. Tamrin finds something undeclared, charges for it, and writes down a good deal more than the company would have liked. A deputy goes up the hill at a trot.";
				this.Text = "[img]gfx/ui/events/" + C.ImgCheckpoint + ".png[/img]{" + body + "}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Find the Fox Den.}",
						function getResult() { return "FoxDoor"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "FoxDoor",
			Title = "The Fox Den",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local warn = c.moralPenalty(false) > 0
					? " Your company's name has come down here ahead of you."
					: "";
				this.Text = "[img]gfx/ui/events/" + C.ImgDocks + ".png[/img]{The West Drenches are wooden houses on stilts over water that runs black and fast to the sea, and walkways that are mostly mud where they are not mostly holes. The Fox Den has boarded windows and a faded sign, and a little pane of fogged glass in the door that someone is already looking through.\n\nThe woman behind it is called %SKVNAME%Velia%SKVNAME_OFF%, and she does not open the door to strangers." + warn + "}";
				this.List = [];
				this.Options = [
					{
						Text = "{Tell her the curator sent us.}",
						function getResult() { return this.Contract.resolveDoor(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Storyteller",
			Title = "The Storyteller",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local door = c.hasFox(C.FoxVelia)
					? "Velia opens the door as soon as she hears the curator's name, and puts a finger to her lips."
					: "Velia keeps you on the step a long time, asking who you are and who sent you and who saw you come, before she lets you in with a finger to her lips.";
				this.Text = "[img]gfx/ui/events/" + C.ImgDen + ".png[/img]{" + door + "\n\nInside there is a good fire, and nine children on the floor in front of it, and an elf with her eyes closed telling them a story. %SKVNAME%Mireille Goldenglow%SKVNAME_OFF% is telling them about a builder of bridges who loved beautiful things, who would not bow to the house when it brought devils into the city, and who went up on the great arch one night and fought one of them hand to hand. Half the arch fell into the sea, she says. The whole town felt it. And afterwards the house made it a crime to say his name.\n\nShe opens her eyes when she is done, and smiles at you as if she has been expecting you. By the fire, a big old dog lifts its head.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Tell her why we came.}",
						function getResult() { return this.Contract.resolveDog(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Knock",
			Title = "The Knock",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local warnLine = c.warned()
					? "The dog is on its feet and growling at the door a long breath before anyone knocks, and that breath is enough to think in."
					: "Nobody hears them coming.";
				local noticed = c.m.Noticed
					? " There are more of them than a patrol needs: the watch knows exactly whom it is looking for."
					: "";
				this.Text = "[img]gfx/ui/events/" + C.ImgKnock + ".png[/img]{" + warnLine + " Then the knock comes, hard enough to rattle the little pane, and a voice outside says the watch is to be let in. Up on the roof opposite a raven sits and watches the door, and does not look away." + noticed + "\n\nMireille has been taken once before. She does not want to be taken again, and her own house is not far, she says, if she can only get there.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Out the back, quietly, all of us.}",
						function getResult() { return this.Contract.resolveKnock(1); }
					},
					{
						Text = "{Open the door and talk to them.}",
						function getResult() { return this.Contract.resolveKnock(2); }
					}
				];
				if (::World.Assets.getMoney() >= c.bribeCost())
				{
					this.Options.push({
						Text = "{Slip them something to go away. (" + c.bribeCost() + " Crowns)}",
						function getResult() { return this.Contract.resolveKnock(3); }
					});
				}
				if (c.warned())
				{
					this.Options.push({
						Text = "{Paint her face and hide her in plain sight.}",
						function getResult() { return this.Contract.resolveKnock(4); }
					});
				}
				this.Options.push({
					Text = "{Open the door with steel in hand.}",
					function getResult()
					{
						local c = this.Contract;
						c.m.Knock = 5;
						c.grantWeapons();
						return "VeliaArms";
					}
				});
				this.Options.push({
					Text = "{Open the door and give them what they came for.}",
					function getResult() { return this.Contract.resolveKnock(6); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Away",
			Title = "Away",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local how;
				local m = c.m.Knock - (c.m.Knock >= C.KnockPassed ? C.KnockPassed : 0);
				if (m == 1) how = "Out through the back, along a walkway that is more hole than plank, over a canal and up between two houses that lean together like drunks.";
				else if (m == 2) how = "%SKVNAME%" + c.m.ActorName + "%SKVNAME_OFF% opens the door and keeps on talking until the watchmen are tired of listening, and by then the room behind him holds nobody worth searching.";
				else if (m == 3) how = "Money changes hands under the eye of that raven without the raven seeing it, and the watch decides the Fox Den is a very dull place to search.";
				else how = "When the watch comes in it finds an old woman with a painted face asleep by the fire, and a good deal of children, and nothing else of interest.";
				this.Text = "[img]gfx/ui/events/" + C.ImgEscape + ".png[/img]{" + how + "\n\nAt the door of a narrow house a few streets on, %SKVNAME%Mireille%SKVNAME_OFF% stops, and pulls her hood down, and looks back the way you came. Then she presses a little bottle and a purse into the nearest hand.%SPEECH_ON%For your trouble, and for the curator's. Tell him I will lie quiet a while. Not too long. Somebody has to tell them.%SPEECH_OFF%The door shuts behind her.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantThanks))
					this.List.extend(::Skv.Loot.previewRows([C.ItemPotion], c.thanksPay()));
				this.Options = [
					{
						Text = "{Back to the curator.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (!c.hasGrant(C.GrantThanks))
							{
								c.setGrant(C.GrantThanks);
								::Skv.Loot.haul(::Skv.Loot.make([C.ItemPotion]), c.thanksPay());
							}
							return "Records";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "GivenUp",
			Title = "Given Up",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local body = c.m.Mireille == 2
					? "The sergeant at the door listens, and looks past you at the elf by the fire, and then he smiles. He counts the bounty out on the table in front of the children. Mireille does not fight. She only looks at you once on her way out, the way you would look at weather."
					: "The sergeant does not believe a word of it. Sellswords who hand over their own catch are sellswords who are up to something, he says, and he takes her anyway, and he takes your names with her. There is no bounty for people the watch does not trust.";
				this.Text = "[img]gfx/ui/events/" + C.ImgWatch + ".png[/img]{" + body + "\n\nBehind you, Velia has put herself between the children and the door. None of them is crying. They have seen this before.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the curator.}",
						function getResult() { return "Records"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Cornered",
			Title = "Cornered",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgKnock + ".png[/img]{It does not work. The watch is in the room, and in the yard behind it, and there are more of them in the street. Their sergeant has his hand on a club, not a sword, and he would like very much for everybody to come quietly.\n\nVelia, without a word, has taken down a bundle of weapons from behind her counter.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Take Velia's weapons. We fight.}",
						function getResult()
						{
							local c = this.Contract;
							c.grantWeapons();
							return "VeliaArms";
						}
					},
					{
						Text = "{Lay down our arms.}",
						function getResult() { return this.Contract.resolveSurrender(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "VeliaArms",
			Title = "Velia's Weapons",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local first = c.m.Knock == 5
					? "Nobody has touched the latch yet. Velia has a bundle down from behind her counter and open on the table before the second knock."
					: "While the sergeant is still talking, Velia drops a bundle on the table and cuts its cord.";
				this.Text = "[img]gfx/ui/events/" + C.ImgKnock + ".png[/img]{" + first + " A sap, a morning star, and a long sword gone dull and spotted with rust: things guests left behind and never came back for.%SPEECH_ON%Take whatever fits your hands. They will not wait for you to choose.%SPEECH_OFF%}";
				this.List = ::Skv.Loot.previewRows([C.ItemSap, C.ItemSword, C.ItemMace]);
				this.Options = [
					{
						Text = "{Let them come.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatWatch();
							return 0;
						}
					},
					c.gearOption("VeliaArms")
				];
			}
		});

		this.m.Screens.push({
			ID = "Jail",
			Title = "Three Days",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgWatch + ".png[/img]{Three days in the cells under the watch house, eating your own provisions, which the watch has been kind enough to bring along. Nobody asks you anything. Nobody needs to.\n\nOn the third morning a clerk opens the door and says the envoy has spoken for you, and that the company is to finish what it was hired for and give the watch no further trouble. Of Mireille he says nothing at all.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Back to the curator.}",
						function getResult() { return "Records"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "WatchAfter",
			Title = "After the Watch",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				if (c.m.Watch == 1)
				{
					this.Text = "[img]gfx/ui/events/" + C.ImgEscape + ".png[/img]{The watchmen who can still walk are gone up the street, shouting for more. In the noise %SKVNAME%Mireille%SKVNAME_OFF% slips away along the canal path. At the corner she turns, and comes back long enough to press a little bottle and a purse into the nearest hand, and then she is gone.\n\nThe town will remember this, and so will the watch.}";
					this.List = c.m.Rows == null ? [] : clone c.m.Rows;
					if (!c.hasGrant(C.GrantThanks))
						this.List.extend(::Skv.Loot.previewRows([C.ItemPotion], c.thanksPay()));
					if (c.hasGrant(C.GrantWeapons)) this.List.push(c.goodRow("Velia's weapons are yours to keep"));
				}
				else
				{
					this.Text = "[img]gfx/ui/events/" + C.ImgWatch + ".png[/img]{There are too many of them. The company breaks out through the back and runs, and does not stop until the streets are behind it. %SKVNAME%Mireille%SKVNAME_OFF% did not get out. The last anyone sees of her, the watch is walking her up the hill.}";
					this.List = c.m.Rows == null ? [] : clone c.m.Rows;
					if (c.hasGrant(C.GrantWeapons)) this.List.push(c.goodRow("Velia's weapons are yours to keep"));
				}
				this.Options = [
					{
						Text = "{To the curator.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (c.m.Watch == 1 && !c.hasGrant(C.GrantThanks))
							{
								c.setGrant(C.GrantThanks);
								::Skv.Loot.haul(::Skv.Loot.make([C.ItemPotion]), c.thanksPay());
							}
							return "Records";
						}
					}

				];
			}
		});

		this.m.Screens.push({
			ID = "Records",
			Title = "The Curator's Records",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local body;
				if (c.drawerOpen())
					body = "When he hears she is safe, Zefiro sits down very suddenly and does not say anything for a while. Then he goes to the back of the room and opens a drawer that has a second lock on it.\n\nInside is what the house wanted burned: an old order from the war, letters in a dead hand, and a map that still shows a town called Anglemire, up the coast where the hills come down to the sea. The keep is marked on it. So is a door below the keep that is not on any map the house has.\n\nBehind the papers stands a stone jar sealed with old wax. He puts it into the nearest hands.%SPEECH_ON%Mead. I was keeping it for the day the house fell. Do not wait that long.%SPEECH_OFF%";
				else if (c.m.Mireille == 1)
					body = "He hears that she is safe and nods without looking at you. He gives you what he must: an old order from the war and a map that still shows a town called Anglemire, up the coast where the hills come down to the sea. The keep is marked on it. Whatever else he keeps, he keeps.";
				else
					body = "He hears what happened in the West Drenches and his face closes like a door. He gives you what he must and no more: a map that still shows a town called Anglemire, up the coast where the hills come down to the sea, with the keep marked on it.";
				this.Text = "[img]gfx/ui/events/" + C.ImgRecords + ".png[/img]{" + body + "}";
				this.List = [];

				if (c.drawerOpen() && !c.hasGrant(C.GrantMead))
					this.List.extend(::Skv.Loot.previewItems(c.meadItems()));
				this.Options = [
					{
						Text = "{Then we go to Emberhold.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (c.drawerOpen() && !c.hasGrant(C.GrantMead))
							{
								c.setGrant(C.GrantMead);
								::Skv.Loot.haul(c.meadItems());
							}
							c.spawnMarker();
							c.m.Act = 1;
							c.m.Rows = [];
							c.getActiveState().start();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Anglemire",
			Title = "Anglemire",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgKeep + ".png[/img]{Anglemire is a handful of stone houses with no roofs and gulls in the doorways. Nobody has lived here for a long time. At the top of the town, where the hills come down to the sea, the walls of Emberhold still stand, black to the height of a man where the fire licked them, and green above that where the ivy has taken over.\n\nThe great hall has no floor. Where the floor was, there is a garden: thick, wild, heavy with gourds, growing in the pit where the cellars used to be.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Go down into the garden.}",
						function getResult() { return "Garden"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Garden",
			Title = "The Garden",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgGarden + ".png[/img]{Somebody has been tending this. The vines are trained up the old pillars, the paths between the gourds are clear, and the biggest gourds have been propped on stones so they will not rot. An iron gate stands in the far wall of the pit, rusted half shut, with steps going down behind it.\n\nAnd some of the gourds, when nobody is looking straight at them, are not quite where they were.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Walk carefully. Crush nothing.}",
						function getResult() { return this.Contract.resolveGarden(); }
					},
					{
						Text = "{Cut a way through to the gate.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							local rows = [];
							c.moral(C.MoralClear, "You cut down what someone was tending", rows);
							c.m.Rows = rows;
							c.getActiveState().onCombatLeshy();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Leshys",
			Title = "The Gardeners",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgGarden + ".png[/img]{%SKVNAME%" + c.m.ActorName + "%SKVNAME_OFF% leads the company down through the garden without so much as bruising a leaf, and halfway across, one of the gourds stands up.\n\nIt is about the height of a child, with a carved face and a body of knotted vines, and it is wearing a coat that must have belonged to someone in this keep, cleaned and mended with great care. More of them are standing up all around. The one in front holds up a lantern and looks at you, and waits.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Speak to them, and mean it.}",
						function getResult() { return this.Contract.resolveLeshys(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "GardenAfter",
			Title = "The Garden",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local body = c.m.Garden == 1
					? "Their warden is called %SKVNAME%Harvest Stripe%SKVNAME_OFF%, or something that sounds like it, and once it has decided you are no danger to the garden it cannot do enough for you. The little gardeners dig beside you. They bring out things they have found in the ruin and kept: a book, a child's doll with a tiara, a silver locket with a young man's face painted inside it. Everything is clean, and mended, and offered with both hands. When you go, Harvest Stripe presses a few seeds into your palm."
					: "The gardeners do not trust you, or something in the way you came made them afraid. One moment they were there and the next there is only a garden full of gourds, very still. Nothing stops you crossing to the gate. Nothing helps you either.";
				this.Text = "[img]gfx/ui/events/" + C.ImgGarden + ".png[/img]{" + body + "\n\nBehind the gate the steps go down into the dark, and the air that comes up them smells of old bones and something newer.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Down the steps.}",
						function getResult() { return "Mortuary"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "GardenFled",
			Title = "The Garden",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgKeep + ".png[/img]{The company backs out of the pit with seeds stinging in its skin and vines round its ankles. The garden goes quiet behind it, every gourd exactly where it was.\n\nThere is another way down: round the outside of the hall, through the old kitchen, and down a stair the fire did not reach.}";
				this.List = this.Contract.m.Rows == null ? [] : clone this.Contract.m.Rows;
				this.Options = [
					{
						Text = "{Take the kitchen stair.}",
						function getResult() { return "Mortuary"; }
					},
					this.Contract.gearOption("GardenFled")
				];
			}
		});

		this.m.Screens.push({
			ID = "FloorGives",
			Title = "The Floor Gives Way",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgCrypt + ".png[/img]{Every gardener that falls bursts like a seed pod, and the gourds around it swell. By the end some of them are as big as a man, and the old floor under the garden is groaning. Then it goes.\n\nThe company comes down in a rain of earth and roots and gourds into a room full of bones, with the light of the hole far above. In the dark beyond, something is moving. Several somethings. They have heard you come, and they are not afraid.\n\nAmong the earth on the floor lie the things the gardeners kept in their heads: a book, a doll, a locket.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				if (!c.hasGrant(C.GrantKeepsakes))
					this.List.extend(::Skv.Loot.previewRows(c.keepsakePaths()));
				this.Options = [
					{
						Text = "{Up and fight!}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (!c.hasGrant(C.GrantKeepsakes))
							{
								c.setGrant(C.GrantKeepsakes);
								::Skv.Loot.haul(::Skv.Loot.make(c.keepsakePaths()));
							}
							if (c.m.Troll == 0) c.m.Troll = 2;
							c.getActiveState().onCombatCrypt();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Mortuary",
			Title = "The Mortuary",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgCrypt + ".png[/img]{This is where the family laid out its dead before they went into the tombs. The bones in it now are not laid out. They are heaped, against a throne on which somebody has sat a skeleton in black mail with a dull iron crown on its skull, held together with dried vines.\n\nThe walls are covered in pictures, painted in something brown, over and over, by somebody who had a great deal of time.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				this.Options = [
					{
						Text = "{Read the walls.}",
						function getResult() { return this.Contract.resolveMortuary(); }
					},
					c.gearOption("Mortuary")
				];
			}
		});

		this.m.Screens.push({
			ID = "Crypt",
			Title = "Under Emberhold",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local walls = c.m.Mortuary == 1
					? "%SKVNAME%" + c.m.ActorName + "%SKVNAME_OFF% reads the pictures for the rest of you. The oldest show the ruling house torn apart by men and devils. The newest show ordinary people burning under the house's banner. The brown is blood, and the bones round the throne are not the family's: those were taken from the tombs, and put together, and given the crown."
					: "Nobody can make sense of the pictures, except that the paint is blood and the painter was angry for a very long time.";
				if (c.m.Keepsakes)
					walls = walls + " One of the faces painted over and over on the walls is the young man in the locket.";
				local size = c.arenzoSize();
				local bones = size >= 3
					? "Some of the bones in the passage are still wet. Whatever eats down here has eaten very well, and lately."
					: (size == 2
						? "The newest bones in the passage are only days old."
						: "The bones in the passage are old and picked clean. Whatever eats here has gone hungry a while.");
				this.Text = "[img]gfx/ui/events/" + C.ImgTroll + ".png[/img]{" + walls + "\n\n" + bones + " At the end of the tombs something huge hangs from a chain by its one remaining arm, and it turns its head toward your torches. It is a troll, or what is left of one. The pieces that are missing have been cut off with a cleaver, and some of the cuts are healing.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;
				if (size >= 2)
				{
					this.List.push(c.badRow(c.arrivedLate() || c.m.JailHours > 0
						? "He has fed well these last days"
						: "He has fed well"));
				}
				this.Options = [
					{
						Text = "{Cut the troll down.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Troll == 0) c.m.Troll = 1;
							return "TrollFreed";
						}
					},
					{
						Text = "{Leave the thing hanging.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Troll == 0) c.m.Troll = 2;
							c.getActiveState().onCombatCrypt();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "TrollFreed",
			Title = "The Chain Parts",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgTroll + ".png[/img]{It takes three blows to part the chain. The troll comes down on the stone like a sack of wet grain and lies there, breathing hard, and looks at you with eyes the colour of old pus. It does not thank you. It does not try to kill you either.\n\nThen it lifts its head and snarls past you into the dark, and from the cracks in the tomb walls the things that have been eating it come out to see what the noise was.}";
				this.List = [];
				this.Options = [
					{
						Text = "{To arms!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatCrypt();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "ArenzoFate",
			Title = "The Last Davian",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local troll = c.m.Troll == 1
					? " The troll is gone, back up into the daylight, without a backward look."
					: "";
				this.Text = "[img]gfx/ui/events/" + C.ImgArenzo + ".png[/img]{The others are dead. The one they made way for in the dark, the one that came last and fought hardest, is down and not dead. Under the company's eyes the cuts along its ribs are closing, slowly, the way the troll's did. Somebody holds a torch to its face, and the face is a man's, once, and a nobleman's." + troll + "\n\n%SKVNAME%" + C.ArenzoName + "%SKVNAME_OFF%. The curator would give a great deal to hear what he remembers. The envoy would give a great deal for his head.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Bind him. The curator can have him.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (c.m.Arenzo == 0)
							{
								c.m.Arenzo = 1;
								local rows = [];
								c.moral(C.MoralBound, "You kept the last Davian for the truth, not the gallows", rows);
								c.m.Rows = rows;
							}
							c.killMarker();
							c.m.Act = 3;
							c.setState("Return");
							::Skv.dbg("Skv.Bygones: Arenzo BOUND for the curator");
							return 0;
						}
					},
					{
						Text = "{Take his head to the envoy.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (c.m.Arenzo == 0)
							{
								c.m.Arenzo = 2;
								local rows = [];
								c.moral(C.MoralHead, "You gave the house its monster for the festival", rows);
								c.m.Rows = rows;
							}
							c.killMarker();
							c.m.Act = 3;
							c.setState("Return");
							::Skv.dbg("Skv.Bygones: Arenzo's HEAD for the envoy");
							return 0;
						}
					},
					c.gearOption("ArenzoFate")
				];
			}
		});

		this.m.Screens.push({
			ID = "Fled",
			Title = "Out of the Dark",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgKeep + ".png[/img]{The company comes up out of the tombs faster than it went down, and nobody stops until the burned hall is behind them. Down there the thing that was a Davian is already knitting itself back together.\n\nWhoever goes down those stairs next, it will be the house's own soldiers and not this company. What the company has is what it saw.}";
				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png", text = "Arenzo lives on under Emberhold" }
				];
				this.Options = [
					{
						Text = "{Back to the envoy, with what we have.}",
						function getResult()
						{
							local c = this.Contract;
							c.m.Act = 3;
							c.m.Rows = [];
							c.setState("Return");
							return 0;
						}
					},
					this.Contract.gearOption("Fled")
				];
			}
		});

		this.m.Screens.push({
			ID = "Pay",
			Title = "The Envoy Pays",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				local body;
				if (c.fled())
					body = "%SKVNAME%Ianareth Alazario%SKVNAME_OFF% hears that the last of the Davians is alive under his own house, and for a moment she almost smiles.%SPEECH_ON%A traitor's line that ends in a monster. The people will like that story nearly as well. You will be paid for the telling, and not for the rest.%SPEECH_OFF%";
				else if (c.m.Arenzo == 2)
					body = "%SKVNAME%Ianareth Alazario%SKVNAME_OFF% has the sack opened on her table and looks at what is inside for a long time.%SPEECH_ON%The last of the Davians, who ate his own family and then their neighbours for a hundred years. The festival will not need any other speech. The house thanks you, and pays above the price.%SPEECH_OFF%";
				else
					body = "%SKVNAME%Ianareth Alazario%SKVNAME_OFF% listens to all of it without sitting down, and pays what was agreed.%SPEECH_ON%The house thanks you. It will remember that you found what it asked you to find.%SPEECH_OFF%If she knows where the last Davian has gone, she does not say.";
				this.Text = "[img]gfx/ui/events/" + C.ImgPay + ".png[/img]{" + body + "}";
				local rows = c.m.Rows == null ? [] : clone c.m.Rows;
				rows.push({ id = 1, icon = "ui/icons/asset_money.png",
					text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.finalPay()) + " Crowns" });
				if (c.m.Arenzo == 2 && !c.fled())
					rows.push({ id = 1, icon = "ui/icons/asset_money.png",
						text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.headPay()) + " Crowns for his head" });

				rows.push(c.relRow(c.townName(), true));
				if (!c.fled()) rows.push(c.relRow(c.houseName(), true));
				this.List = rows;
				this.Options = [
					{
						Text = c.m.Arenzo == 1 ? "{And now to the curator.}" : "{Then we're done here.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							local A = ::Const.World.Assets;
							local rows = [];
							if (!c.hasGrant(C.GrantFee))
							{
								c.setGrant(C.GrantFee);
								::World.Assets.addMoney(c.finalPay());
							}
							if (c.m.Arenzo == 2 && !c.fled() && !c.hasGrant(C.GrantHead))
							{
								c.setGrant(C.GrantHead);
								::World.Assets.addMoney(c.headPay());
							}
							if (!c.hasGrant(C.GrantRenown))
							{
								c.setGrant(C.GrantRenown);

								::World.Assets.addBusinessReputation(c.fled() ? A.ReputationOnContractPoor : A.ReputationOnContractSuccess);

								::World.Flags.set(C.ArcFlagArenzo, c.fled() ? 0 : c.m.Arenzo);
							}
							if (!c.hasGrant(C.GrantRelations))
							{
								c.setGrant(C.GrantRelations);

								c.townRel(c.fled() ? C.TownFled : C.TownDone, "Searched the ruin of Emberhold", rows);
								if (!c.fled()) c.houseRel(C.HouseDone, "Brought back proof from Emberhold", rows);
								if (c.m.Arenzo == 2 && !c.fled()) c.houseRel(C.HouseHead, "Gave the house the last Davian for its festival", rows);
								if (c.m.Arenzo == 1) c.townRel(C.TownBound, "Brought the last Davian to the curator", rows);
							}

							c.m.Rows = c.m.Arenzo == 1 ? [c.relRow(c.townName(), true)] : [];
							::Skv.dbg("Skv.Bygones: PAID fee=" + c.finalPay() + " head=" + (c.m.Arenzo == 2 ? c.headPay() : 0)
								+ " fled=" + c.fled() + " arenzo=" + c.m.Arenzo + " mireille=" + c.m.Mireille + " watch=" + c.m.Watch
								+ " garden=" + c.m.Garden + " troll=" + c.m.Troll + " granted=" + c.m.Granted);
							if (c.m.Arenzo == 1) return "Curator2";
							c.m.Act = 4;
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Curator2",
			Title = "What He Remembers",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Bygones;
				this.Text = "[img]gfx/ui/events/" + C.ImgCurator + ".png[/img]{Zefiro has the bound thing taken down into a cellar under the museum that he does not show you, and when he comes back up he has to sit down.%SPEECH_ON%He remembers all of it. The siege. Who held out and who did not, and what the house did to the ones who tried to bring them bread. Nobody has heard that told in a hundred years.%SPEECH_OFF%He does not thank you, exactly. He shakes every hand in the company, one after another, presses a flask of the temple's best healing draught on whoever looks worst, and then he goes back down to listen.}";
				this.List = c.m.Rows == null ? [] : clone c.m.Rows;

				if (!c.hasGrant(C.GrantCuratorGift))
					this.List.extend(::Skv.Loot.previewRows([C.ItemCuratorGift]));
				this.Options = [
					{
						Text = "{Let the bygones be told, then.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Bygones;
							if (!c.hasGrant(C.GrantCuratorGift))
							{
								c.setGrant(C.GrantCuratorGift);
								::Skv.Loot.haul(::Skv.Loot.make([C.ItemCuratorGift]));
							}
							c.m.Act = 4;
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
		::Skv.Once.release(::Const.Skv.Bygones.OnceKey);
		if (this.m.IsActive)
		{
			::Skv.Once.retire(::Const.Skv.Bygones.OnceKey);

			this.killMarker();
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onSerialize( _out )
	{
		if (!::MSU.isNull(this.m.Marker))
		{
			_out.writeU32(this.m.Marker.getID());
		}
		else
		{
			_out.writeU32(0);
		}
		_out.writeU32(this.m.HouseID);
		_out.writeU8(this.m.MoralSnapshot);
		_out.writeU8(this.m.ArenzoBase);
		_out.writeU16(this.m.DayAccepted);
		_out.writeU16(this.m.ArrivalDay);
		_out.writeU8(this.m.Act);
		_out.writeU8(this.m.Zefiro);
		_out.writeU8(this.m.Checkpoint);
		_out.writeBool(this.m.Noticed);
		_out.writeU16(this.m.FinePaid);
		_out.writeU8(this.m.FoxDen);
		_out.writeU8(this.m.Knock);
		_out.writeU16(this.m.BribePaid);
		_out.writeU8(this.m.Mireille);
		_out.writeU8(this.m.Watch);
		_out.writeU16(this.m.JailHours);
		_out.writeU8(this.m.Garden);
		_out.writeBool(this.m.Ambush);
		_out.writeBool(this.m.Keepsakes);
		_out.writeU8(this.m.Mortuary);
		_out.writeU8(this.m.Troll);
		_out.writeU8(this.m.Crypt);
		_out.writeU8(this.m.Arenzo);
		_out.writeU16(this.m.Granted);
		_out.writeString(this.m.ActorName);
		local rows = this.m.Rows == null ? [] : this.m.Rows;
		local n = ::Math.min(255, rows.len());
		if (rows.len() > 255) ::logError("Skv.Bygones: " + rows.len() + " rows on the open screen; only 255 are saved.");
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
		local marker = _in.readU32();
		if (marker != 0)
		{
			this.m.Marker = this.WeakTableRef(::World.getEntityByID(marker));
		}
		this.m.HouseID = _in.readU32();
		this.m.MoralSnapshot = _in.readU8();
		this.m.ArenzoBase = _in.readU8();
		this.m.DayAccepted = _in.readU16();
		this.m.ArrivalDay = _in.readU16();
		this.m.Act = _in.readU8();
		this.m.Zefiro = _in.readU8();
		this.m.Checkpoint = _in.readU8();
		this.m.Noticed = _in.readBool();
		this.m.FinePaid = _in.readU16();
		this.m.FoxDen = _in.readU8();
		this.m.Knock = _in.readU8();
		this.m.BribePaid = _in.readU16();
		this.m.Mireille = _in.readU8();
		this.m.Watch = _in.readU8();
		this.m.JailHours = _in.readU16();
		this.m.Garden = _in.readU8();
		this.m.Ambush = _in.readBool();
		this.m.Keepsakes = _in.readBool();
		this.m.Mortuary = _in.readU8();
		this.m.Troll = _in.readU8();
		this.m.Crypt = _in.readU8();
		this.m.Arenzo = _in.readU8();
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
