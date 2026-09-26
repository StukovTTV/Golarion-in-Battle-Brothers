this.skv_fane_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Destination = null,
		Act       = 0,

		Clues     = 0,
		Beats     = 0,
		Reveal    = 0,
		SprungBy  = 0,
		Outcome   = 0,
		Concluded = 0,
		Res8      = 0,
		Marks     = 0,
		Res32     = 0,
		Speaker   = "",

		ActorName   = "",
		RevealRows  = null,
		VerdictRows = null,
		SayTitle  = "",
		SayText   = "",
		SayRows   = null,
		SayNext   = "",
		SayImage  = "",
	},

	function say( _title, _text, _rows, _next = "", _image = "" )
	{
		this.m.SayTitle = _title;
		this.m.SayText  = _text;
		this.m.SayRows  = _rows == null ? [] : _rows;
		this.m.SayNext  = _next;
		this.m.SayImage = _image;
		return "Result";
	}

	function hasMark( _bit ) { return (this.m.Marks & _bit) != 0; }
	function setMark( _bit ) { this.m.Marks = this.m.Marks | _bit; }
	function hasClue( _bit ) { return (this.m.Clues & _bit) != 0; }

	function clueCount()
	{
		local F = ::Const.Skv.Fane;
		local n = 0;
		foreach (b in [F.ClueTracks, F.ClueFangs, F.ClueBlood, F.ClueTalk])
		{
			if (this.hasClue(b)) n = n + 1;
		}
		return n;
	}

	function hubScreen()
	{
		if (this.m.Outcome == 2) return "RelicGone";
		if (this.m.Outcome == 3) return "FaneFalls";
		if (this.m.Act == 0) return "Arrival";
		if (this.m.Act == 1)
		{
			if (this.m.Reveal == 1) return "Unmasked";
			if (this.m.Reveal == 2) return "Burned";
			if (this.m.Reveal == 3) return "Sprung";
			return "Courtyard";
		}
		if (this.m.Act == 2) return "Wakes";
		if (this.m.Act == 3) return "Sanctum";
		return "Aftermath";
	}

	function clockRow()
	{
		local F = ::Const.Skv.Fane;
		local left = ::Math.max(0, F.ClockLimit - this.m.Beats);
		return { id = 20, icon = "ui/icons/special.png",
			text = left == 0 ? "The priests' patience has run out"
				: "The priests' patience: " + left + " of " + F.ClockLimit + " questions left" };
	}

	function clueRows()
	{
		local F = ::Const.Skv.Fane;
		local rows = [];
		if (this.hasClue(F.ClueTracks)) rows.push({ id = 21, icon = "ui/icons/vision.png", text = "Boots went in behind the priests, and none came out" });
		if (this.hasClue(F.ClueFangs))  rows.push({ id = 22, icon = "ui/icons/vision.png", text = "Fangs cut into Erastil's statues: Anogetz's mark" });
		if (this.hasClue(F.ClueBlood))  rows.push({ id = 23, icon = "ui/icons/vision.png", text = "Blood in the moss, hours old" });
		if (this.hasClue(F.ClueTalk))   rows.push({ id = 24, icon = "ui/icons/vision.png", text = "They talk like men who were told what priests say" });
		return rows;
	}

	function mercBudget()
	{
		local F = ::Const.Skv.Fane;
		return this.Math.maxf(F.MercMin, F.MercBase * this.getDifficultyMult() * this.getScaledDifficultyMult());
	}

	function wolfBudget()
	{
		local F = ::Const.Skv.Fane;
		return this.Math.maxf(F.WolfMin, F.WolfBase * this.getDifficultyMult() * this.getScaledDifficultyMult() - F.DaemonCharge);
	}

	function finalPay()
	{
		return this.m.Payment.getOnCompletion();
	}

	function verdictChance()
	{
		local F = ::Const.Skv.Fane;
		local c = ::Skv.Check.scaledBase(this, F.VerdictBase);
		if (this.hasMark(F.MarkSymbols)) c = c + F.VerdictSymbols;
		c = c + F.VerdictPerClue * this.clueCount();
		if (this.m.Reveal == 1) c = c + F.VerdictUnmasked;
		return ::Math.min(95, c);
	}

	function moralFor()
	{
		local F = ::Const.Skv.Fane;
		return this.hasMark(F.MarkVerdict) ? F.MoralPass : F.MoralFail;
	}

	function moralRow()
	{
		local n = this.moralFor();
		local text = n > 0 ? "They believe you put down a daemon" : "Officially, the company killed two priests";
		local col = n > 0 ? ::Const.UI.Color.PositiveEventValue : ::Const.UI.Color.NegativeEventValue;
		return { id = 10, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + col + "]" + text + " (" + (n > 0 ? "+" : "") + n + ")[/color]" };
	}

	function makeSpear()
	{
		local F = ::Const.Skv.Fane;
		local items = ::Skv.Loot.make([F.SpearPath]);
		if (items.len() == 0) return null;
		local ok = false;
		try { ok = ::GolarionEnchant.apply(items[0], F.SpearTier); }
		catch (e) { ::logError("Skv.Fane: the spear would not take its +" + F.SpearTier + " (it is still a spear): " + e); }
		if (!ok) ::logError("Skv.Fane: GolarionEnchant.apply returned false on the spear - it is a plain spear.");
		return items[0];
	}

	function actorName( _r )
	{
		return (_r.actor != null) ? _r.actor.getName() : "%randombrother%";
	}

	function resolveTracks()
	{
		local F = ::Const.Skv.Fane;
		this.setMark(F.MarkTracksTried);
		local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, F.TracksBase));
		local who = this.actorName(r);
		local rows = [];
		local text;
		if (r.ok)
		{
			this.m.Clues = this.m.Clues | F.ClueTracks;
			text = "{" + who + " goes down on one knee in the mud and takes his time about it. Two sets of sandals went in this morning, small and careful. After them, boots: a good many boots, heavy men walking close together.\n\nNone of them came back out.}";
			rows.push({ id = 1, icon = "ui/icons/vision.png", text = "Boots went in behind the priests, and none came out" });
			rows.extend(::Skv.XP.check(r));
		}
		else
		{
			text = "{" + who + " looks the path over. It has been walked by a great many feet and rained on since, and the mud has kept nothing worth reading.}";
			rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "The ground tells you nothing" });
		}
		::Skv.dbg("Skv.Fane: tracks " + (r.ok ? "READ" : "missed") + " by " + who + " clues=" + this.m.Clues);
		return this.say("The Path In", text, rows, "Arrival", "event_128");
	}

	function resolveLook( _which )
	{
		local F = ::Const.Skv.Fane;
		local r;
		local who;
		local rows = [];
		local text;
		local image = "event_178";
		if (_which == "statues")
		{
			this.setMark(F.MarkStatuesTried);
			r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, F.StatuesBase));
			who = this.actorName(r);
			if (r.ok)
			{
				this.m.Clues = this.m.Clues | F.ClueFangs;
				text = "{" + who + " walks the ring of statues. On every one of them the elk-headed hunter's mouth has been worked over with a knife: crude fangs cut across the stone, fresh dust still in the grooves. " + who + " has seen that mark before, scratched on old boundary stones, where the grandmothers say it belongs to a daemon.}";
				rows.push({ id = 1, icon = "ui/icons/vision.png", text = "Fangs cut into Erastil's statues: Anogetz's mark" });
			}
			else
			{
				text = "{The statues are old, weathered and broken in places, and that is all " + who + " can make of them.}";
			}
		}
		else if (_which == "moss")
		{
			this.setMark(F.MarkMossTried);
			r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, F.MossBase));
			who = this.actorName(r);
			if (r.ok)
			{
				this.m.Clues = this.m.Clues | F.ClueBlood;
				text = "{Down among the moss by the broken column, " + who + " finds it: blood, a great deal of it, soaked into the green and not yet gone brown. Hours old, not days.}";
				rows.push({ id = 1, icon = "ui/icons/vision.png", text = "Blood in the moss, hours old" });
			}
			else
			{
				text = "{Moss, wet flagstones and lantern light. Nothing " + who + " can put a name to.}";
			}
		}
		else
		{
			this.setMark(F.MarkTalkTried);
			r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, F.TalkBase));
			who = this.actorName(r);
			image = "event_40";
			if (r.ok)
			{
				this.m.Clues = this.m.Clues | F.ClueTalk;
				text = "{" + who + " asks about the broken statues, then about the rite, then about nothing in particular, the way you talk to a man you mean to trust. The answers come quickly and say very little. The rite? The usual one. The mess? Animals, most likely, got in and hurt themselves.\n\nThen the big one suggests, a little too eagerly, that the company fan out and search the temple for whoever did this. " + who + " has listened to a lot of priests. These two talk like men who were told what priests say.}";
				rows.push({ id = 1, icon = "ui/icons/vision.png", text = "They talk like men who were told what priests say" });
			}
			else
			{
				text = "{" + who + " asks what happened here. The big one talks about vandals and the rite and the dark of the moon, easily, the way a priest would, and suggests the company fan out and search the temple for whoever did it.}";
			}
		}

		if (r.ok) rows.extend(::Skv.XP.check(r));
		else rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "Nothing learned" });

		this.m.Beats = this.m.Beats + 1;
		local next = "Courtyard";
		if (this.m.Beats >= F.ClockLimit)
		{
			this.m.Reveal = 3;
			this.m.SprungBy = 1;
			next = "Sprung";
		}
		rows.push(this.clockRow());
		::Skv.dbg("Skv.Fane: look '" + _which + "' " + (r.ok ? "FOUND" : "nothing") + " by " + who
			+ " beats=" + this.m.Beats + " clues=" + this.m.Clues + (next == "Sprung" ? " -> the clock ran out: SPRUNG" : ""));
		return this.say("The Courtyard", text, rows, next, image);
	}

	function resolveCallOut()
	{
		local F = ::Const.Skv.Fane;
		local baseChance = ::Math.min(95, ::Skv.Check.scaledBase(this, F.CallOutBase) + F.CallOutPerClue * this.clueCount());
		local r = ::Skv.Check.wits(this, baseChance);
		local who = this.actorName(r);
		this.m.Speaker = who;
		local rows = [];
		if (r.ok)
		{
			this.m.Reveal = 1;
			rows.push({ id = 1, icon = "ui/icons/special.png", text = "Seen through, and the company is facing them" });
			rows.extend(::Skv.XP.check(r));
		}
		else
		{
			this.m.Reveal = 3;
			this.m.SprungBy = 2;
			rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "They were ready for it" });
		}
		this.m.RevealRows = rows;
		::Skv.dbg("Skv.Fane: CALL-OUT by " + who + " baseChance=" + baseChance + " (clues " + this.clueCount() + ") "
			+ (r.ok ? "PASSED -> Unmasked (Line)" : "FAILED -> Sprung (Circle)"));
		return r.ok ? "Unmasked" : "Sprung";
	}

	function resolvePools()
	{
		local F = ::Const.Skv.Fane;
		if (this.hasMark(F.MarkPools)) return "Wakes";
		this.setMark(F.MarkPools);
		local rows = ::Skv.Loot.haul(::Skv.Loot.make([F.SymbolPath]));
		if (rows.len() > 0) this.setMark(F.MarkSymbols);
		else ::logError("Skv.Fane: the holy symbols did not reach the stash - the door will have to be forced.");
		local text = "{Three shallow pools are cut into the floor of the back room. One holds clear water, thick with sap. One holds green shoots. The third has gone red.\n\nTwo bodies float in it, a broad man and a tall woman in the green of Erastil, white as candles. They are the two the sellswords were pretending to be: the real %SKVNAME%Enogas%SKVNAME_OFF% and %SKVNAME%Larya%SKVNAME_OFF%. Around their necks, on leather cords, hang little bows of antler with an arrow nocked across each.\n\n%randombrother% cuts the cords and closes their eyes. Somebody back home will want to know what happened to them.}";
		::Skv.dbg("Skv.Fane: pools searched, symbols=" + this.hasMark(F.MarkSymbols));
		return this.say("The Pools", text, rows, "Wakes", "event_178");
	}

	function resolveDoors()
	{
		local F = ::Const.Skv.Fane;
		this.m.Act = 3;
		local rows = [];
		local text;
		if (this.hasMark(F.MarkSymbols))
		{
			text = "{The inner doors are carved with a hunt: men with bows, an elk turning at bay. In the centre, where a handle ought to be, there is a niche in the shape of a bow of antler. %randombrother% presses one of the priests' symbols into it. It fits. Something heavy shifts behind the stone, and the doors swing in on their own.}";
			rows.push({ id = 1, icon = "ui/icons/special.png", text = "The priests' symbol opens the way" });
		}
		else
		{
			this.setMark(F.MarkForced);
			text = "{The inner doors have no handle, only a niche in the shape of a bow of antler, and nothing the company carries fits it. It takes axes, a beam from the broken column and far too long. By the time the doors give, the howling outside has stopped.\n\nWhatever is inside is not waking any more. It is awake.}";
			rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "Forced, and slowly: getting the arrow home will be harder" });
		}
		::Skv.dbg("Skv.Fane: inner doors " + (this.hasMark(F.MarkForced) ? "FORCED" : "opened with the symbol") + " -> Act 3");
		return this.say("The Inner Doors", text, rows, "Sanctum", "event_74");
	}

	function resolveRitual()
	{
		local F = ::Const.Skv.Fane;
		this.setMark(F.MarkRitualTried);
		local baseChance = ::Skv.Check.scaledBase(this, F.RitualBase) - (this.hasMark(F.MarkForced) ? F.RitualForced : 0);
		local r = ::Skv.Check.agility(this, ::Math.max(5, baseChance));
		local who = this.actorName(r);
		this.m.Speaker = who;
		local rows = [];
		local text;
		if (r.ok)
		{
			this.setMark(F.MarkRitualHeld);
			text = "{" + who + " goes for it. A claw the size of a scythe comes round and he is already under it, and then he is at the statue, and he drives the black arrow into the wound in its chest with both hands.\n\nThe smoke stops. A crack runs out from the arrow through the black stone, and a sound goes through the fane like a great bell struck once. The daemon screams. The wolves flatten to the floor. Whatever it was wearing a moment ago, its hide is only hide now.}";
			rows.push({ id = 1, icon = "ui/icons/special.png", text = "The daemon and its beasts are weakened and shaken" });
			rows.extend(::Skv.XP.check(r));
		}
		else
		{
			text = "{" + who + " goes for it and gets halfway. The daemon turns its head, opens its jaws, and breathes. He comes back rolling, beating out his own sleeves, with the arrow still in his hands.}";
			local hit = r.actor;
			local inj = null;
			if (hit != null)
			{
				try { inj = hit.addInjury(::Const.Injury.Burning); }
				catch (e) { ::logError("Skv.Fane: the runner's burn would not apply: " + e); }
			}
			rows.push({ id = 1, icon = (inj != null ? inj.getIcon() : "ui/icons/health.png"),
				text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]" + who + (inj != null ? " - " + inj.getNameOnly() : " is burned") + "[/color]" });
			rows.push({ id = 2, icon = "ui/icons/regular_damage.png", text = "The daemon is at full strength" });
		}
		::Skv.dbg("Skv.Fane: RITUAL by " + who + " baseChance=" + baseChance + (this.hasMark(F.MarkForced) ? " (door forced)" : "")
			+ (r.ok ? " HELD -> weakened + shaken" : " FAILED -> full strength"));
		return this.say("The Arrow", text, rows, "", "event_131");
	}

	function resolveVerdict()
	{
		local F = ::Const.Skv.Fane;
		if (this.hasMark(F.MarkVerdictDone)) return;
		this.setMark(F.MarkVerdictDone);
		local chance = this.verdictChance();
		local r = ::Skv.Check.charm(this, chance);
		local rows = [];
		if (r.ok)
		{
			this.setMark(F.MarkVerdict);
			rows.extend(::Skv.XP.check(r));
		}
		this.m.VerdictRows = rows;
		::Skv.dbg("Skv.Fane: VERDICT " + (r.ok ? "BELIEVED" : "not believed") + " (chance " + chance
			+ ", symbols=" + this.hasMark(F.MarkSymbols) + " clues=" + this.clueCount() + " reveal=" + this.m.Reveal + ")");
	}

	function failContract( _why )
	{
		if (this.m.Concluded != 0) return;
		this.m.Concluded = 1;
		this.m.Act = 5;
		local A = ::Const.World.Assets;
		::World.Assets.addBusinessReputation(A.ReputationOnContractFail);
		local f = ::World.FactionManager.getFaction(this.getFaction());
		if (f != null) f.addPlayerRelation(A.RelationCivilianContractFail, _why);
		::Skv.dbg("Skv.Fane: FAILED (" + _why + ") outcome=" + this.m.Outcome + " marks=" + this.m.Marks);
	}

	function onDaemonPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Fane: onDaemonPlaced got a null entity - the daemon is plain.");
			return;
		}
		local F = ::Const.Skv.Fane;
		local held = this.hasMark(F.MarkRitualHeld);

		local champ = false;
		try { champ = _e.makeMiniboss(); }
		catch (e) { ::logError("Skv.Fane: makeMiniboss threw on the daemon: " + e); }

		try
		{
			if (held)
			{
				local b = _e.getBaseProperties();
				b.HitpointsMult = b.HitpointsMult * F.RitualDaemonHP;
			}
			_e.getSkills().update();
			_e.setHitpoints(_e.getHitpointsMax());
			if (held) _e.setMoraleState(::Const.MoraleState.Wavering);
		}
		catch (e)
		{
			::logError("Skv.Fane: could not weaken or fill the daemon: " + e);
		}

		this.tintActor(_e, F.DaemonTint, ["body", "head", "injury"]);
		::Skv.dbg("Skv.Fane: the daemon is in. champion=" + champ + " ritual=" + held
			+ " HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax()
			+ " morale=" + _e.getMoraleState() + " size=" + _e.getSize());
	}

	function onWolfPlaced( _e, _tag )
	{
		if (_e == null) return;
		local F = ::Const.Skv.Fane;
		local held = this.hasMark(F.MarkRitualHeld);
		try
		{
			if (held)
			{
				local b = _e.getBaseProperties();
				b.HitpointsMult = b.HitpointsMult * F.RitualWolfHP;
				_e.getSkills().update();
				_e.setHitpoints(_e.getHitpointsMax());
				_e.setMoraleState(::Const.MoraleState.Wavering);
			}
		}
		catch (e)
		{
			::logError("Skv.Fane: could not weaken a wolf: " + e);
		}
		this.tintActor(_e, F.WolfTint, ["body", "head", "head_frenzy"], F.WolfSaturation);
	}

	function tintActor( _e, _hex, _sprites, _saturation = null )
	{
		local col = null;
		try { col = this.createColor(_hex); }
		catch (e) { ::logError("Skv.Fane: could not build the tint " + _hex + ": " + e); return; }
		foreach (name in _sprites)
		{
			try
			{
				if (!_e.hasSprite(name)) continue;
				local sp = _e.getSprite(name);
				sp.Color = col;
				if (_saturation != null) sp.Saturation = _saturation;
			}
			catch (e) { ::logError("Skv.Fane: tint on sprite '" + name + "' failed (cosmetic only): " + e); }
		}
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_fane";
		this.m.Name = "Fane of Fangs";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"The village priest of Erastil needs a sacred arrow carried to an old temple in the forest before the dark of the moon.",
			"A relic of Erastil has come home, and the two priests at the forest shrine are waiting for it. The road is no place for an old man to carry it alone."
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
		_vars.push(["SKVLOC", "[color=#b39dbc]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);
	}

	function start()
	{
		local F = ::Const.Skv.Fane;

		this.m.DifficultyMult = this.Math.rand(80, 125) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, F.PayBase, F.PayWealthLo, F.PayWealthHi);

		this.m.Payment.Advance = 0.0;
		this.m.Payment.Completion = 1.0;
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Carry Erastil's arrow to the fane in the forest",
					"Put it in the hands of the priests Enogas and Larya"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				local home = this.Contract.m.Home.getTile();
				local tiles = this.Contract.m.Home.getSurroundingTilesOfType(::Const.Skv.Fane.forestTypes(), 3);
				local tile = null;
				foreach (t in tiles)
				{
					if (!t.IsOccupied && t.getDistanceTo(home) >= 2) { tile = t; break; }
				}
				if (tile == null)
				{
					foreach (t in tiles)
					{
						if (!t.IsOccupied) { tile = t; break; }
					}
				}
				if (tile == null)
				{

					tile = this.Contract.getTileToSpawnLocation(home, 3, 6);
				}
				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_fane_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);
				::Skv.dbg("Skv.Fane: fane at " + tile.Coords.X + "," + tile.Coords.Y + " terrain=" + tile.Type
					+ " pay=" + this.Contract.finalPay() + " diff=" + this.Contract.getDifficultyMult());
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Carry Erastil's arrow to the fane in the forest",
					"Put it in the hands of the priests Enogas and Larya"
				];
				if (!::MSU.isNull(this.Contract.m.Destination))
				{
					this.Contract.m.Destination.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				if (::MSU.isNull(this.Contract.m.Destination))
				{
					return;
				}

				local f = this.Flags.get("F16");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V16") == f;
					local fled = this.Flags.get("R16") == f;
					this.Flags.set("F16", "");
					this.Flags.set("V16", "");
					this.Flags.set("R16", "");
					local c = this.Contract;

					if (!won && !fled)
					{
						::Skv.dbg("Skv.Fane: " + f + " was launched but never resolved - no state change.");
					}
					else if (f == "Skv16Priests")
					{
						if (won)
						{
							c.m.Act = 2;
							::Skv.dbg("Skv.Fane: the false priests are DEAD -> Act 2");
						}
						else
						{
							c.m.Outcome = 2;
							::Skv.dbg("Skv.Fane: driven out of the courtyard -> Outcome 2 (FAILED: the arrow is gone)");
						}
					}
					else if (f == "Skv16Daemon")
					{
						if (won)
						{
							c.m.Act = 4;
							::Skv.dbg("Skv.Fane: the daemon is DEAD -> Act 4");
						}
						else
						{
							c.m.Outcome = 3;
							::Skv.dbg("Skv.Fane: driven out of the sanctum -> Outcome 3 (FAILED: the fane is the daemon's)");
						}
					}
					this.TempFlags.set("AtSite", false);
				}

				if (this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						this.Contract.setScreen(this.Contract.hubScreen());
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtSite", false);
				}
			}

			function onCombatPriests()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				local tile = c.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv16Priests";
				try { p.Music = ::Const.Music.BanditTracks; } catch (e) {}

				local sprung = c.m.Reveal == 3;
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
				p.EnemyDeploymentType = sprung
					? ::Const.Tactical.DeploymentType.Circle
					: ::Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				p.Entities = [];
				local budget = c.mercBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionFaneMercs, budget,
					fac, "Fane/Mercs", ::Const.World.Spawn.GolarionFaneMercs);
				::Skv.dbg("Skv.Fane: fight 1 budget=" + budget
					+ " (" + F.MercBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ ", floor " + F.MercMin + ") units=" + p.Entities.len()
					+ " reveal=" + c.m.Reveal + " sprungBy=" + c.m.SprungBy
					+ " deploy=" + (sprung ? "AMBUSH (Circle)" : "Line"));

				this.Flags.set("F16", "Skv16Priests");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatDaemon()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				local tile = c.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv16Daemon";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) {}
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];

				p.Entities.push({
					ID = ::Const.EntityType.SkvCeustodaemon,
					Variant = 0,
					Row = 1,
					Script = "scripts/entity/tactical/enemies/skv_ceustodaemon",
					Faction = fac,
					Name = F.DaemonName,
					Callback = c.onDaemonPlaced.bindenv(c)
				});

				local before = p.Entities.len();
				local budget = c.wolfBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionFaneWolves, budget,
					fac, "Fane/Wolves", ::Const.World.Spawn.GolarionFaneWolves);

				for (local i = before; i < p.Entities.len(); i = i + 1)
				{
					p.Entities[i].Callback <- c.onWolfPlaced.bindenv(c);
				}
				::Skv.dbg("Skv.Fane: fight 2 wolf budget=" + budget
					+ " (" + F.WolfBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ " - daemon " + F.DaemonCharge + ", floor " + F.WolfMin + ") units=" + p.Entities.len()
					+ " ritual=" + c.hasMark(F.MarkRitualHeld) + " forced=" + c.hasMark(F.MarkForced));

				this.Flags.set("F16", "Skv16Daemon");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv16") return;
				this.Flags.set("V16", _combatID);
				::Skv.dbg("Skv.Fane: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F16");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R16", f);
				::Skv.dbg("Skv.Fane: retreated from " + f + " (id=" + _combatID + ")");
			}
		});

		this.m.States.push({
			ID = "Return",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Return to " + this.Contract.m.Home.getName()
				];
				if (!::MSU.isNull(this.Contract.m.Destination))
				{
					this.Contract.m.Destination.getSprite("selection").Visible = false;
				}
			}

			function update()
			{
				local c = this.Contract;
				if (c.m.Concluded != 0) return;
				if (c.m.Home == null || c.m.Home.isNull()) return;
				local arrived = c.isPlayerAt(c.m.Home);
				if (!arrived)
				{
					try
					{
						local t = ::World.State.getCurrentTown();
						if (t != null && t.getID() == c.m.Home.getID()) arrived = true;
					}
					catch (e) { ::Skv.dbg("Skv.Fane: getCurrentTown threw - " + e); }
				}
				if (!arrived) return;
				c.resolveVerdict();
				c.setScreen("Report");
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
			Title = "Fane of Fangs",
			Text = "[img]gfx/ui/events/skv_erastil.png[/img]{%employer% has brought the village priest along, an old man in hunter's green with a little bow of antler hung around his neck. Between them on the table lies an arrow as long as a man is tall, of black wood, its head wrapped in oilcloth.%SPEECH_ON%You know the old fane in the wood? Before it was Old Deadeye's, it was a daemon's. Anogetz, they called him, the one who drives the beasts mad and sets sons against their fathers. When his priests were cornered there, Erastil loosed this arrow through the roof and split their altar in two.%SPEECH_OFF%The priest lays a hand on the black shaft.%SPEECH_ON%Every dark of the moon, two of ours set it back in the wound it made, and the old thing stays asleep. Thieves took it two months ago. It is back now, but the dark of the moon is nearly on us, and that road is no place for an old man carrying the one thing that daemon fears. Brother %SKVNAME%Enogas%SKVNAME_OFF% and Sister %SKVNAME%Larya%SKVNAME_OFF% are waiting at the fane for it. Put it in their hands, and the shrine will pay what it can.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We'll see it there.}",
						function getResult() { return "Negotiation"; }
					}
				];
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{What do the men know about that temple?}",
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
			Text = "[img]gfx/ui/events/event_133.png[/img]{%randombrother% speaks up.%SPEECH_ON%Erastil's lot are hunters and farmers. Plain folk. They say what they mean and they're no good at saying anything else, priests least of all.%SPEECH_OFF%%randombrother2% is looking at the black arrow and not liking it.%SPEECH_ON%Daemons, though. Where one gets its claws into a place, it's the beasts that go wrong first. Birds all in one flock, wolves that won't run from fire. If the woods out there have gone quiet, that's why.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Back to the priest.}",
					function getResult() { return "Task"; }
				}
			]
		});

		this.m.Screens.push({
			ID = "Arrival",
			Title = "The Fane in the Wood",
			Text = "[img]gfx/ui/events/event_128.png[/img]{The fane stands in a clearing the forest has been trying to take back for a very long time: moss on every stone, a roof of old oak shingles, and over the great doors the bow and arrow of Erastil, carved deep. The doors stand a little open. Lanterns are burning somewhere inside. Dusk is coming on, and the woods have gone very quiet.\n\nThe path to the doors is soft ground, churned by a good many feet.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				this.List = c.clueRows();
				this.Options = [];
				if (!c.hasMark(F.MarkTracksTried))
				{
					this.Options.push({
						Text = "{Read the ground before going in.}",
						function getResult() { return this.Contract.resolveTracks(); }
					});
				}

				this.Options.push({
					Text = "{Check our gear before we go in. (open loadout)}",
					function getResult()
					{
						::World.State.showLoadoutFromContract();
						return "Arrival";
					}
				});
				this.Options.push({
					Text = "{Go in.}",
					function getResult()
					{
						this.Contract.m.Act = 1;
						::Skv.dbg("Skv.Fane: into the courtyard -> Act 1");
						return "Courtyard";
					}
				});
				this.Options.push({
					Text = "{Not yet. Pull back.}",
					function getResult() { return 0; }
				});
			}
		});

		this.m.Screens.push({
			ID = "Courtyard",
			Title = "The Courtyard",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				if (c.m.Beats == 0)
				{
					this.Text = "[img]gfx/ui/events/event_178.png[/img]{Past the doors the courtyard lies open to the sky and gone green with moss. Statues of the elk-headed hunter keep watch from the edges, worn soft by the weather; one of them is face-down on the flags, with two fallen columns beside it. Lanterns burn in the alcoves.\n\nTwo figures in the green of Erastil's priesthood come out to meet you, a broad man and a tall woman, hoods up against the evening chill. The man spreads his hands.%SPEECH_ON%Old Deadeye be thanked, you've brought it. I'm %SKVNAME%Enogas%SKVNAME_OFF%, this is %SKVNAME%Larya%SKVNAME_OFF%. Vandals again, you can see what they did to the statues. Give us the arrow and we'll see the rite done before moonrise.%SPEECH_OFF%}";
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_178.png[/img]{The two priests wait by the broken statue with their hands folded in their sleeves. The big one keeps glancing at the arrow, and then at the side rooms, and then at the arrow again.%SPEECH_ON%The moon won't wait on us, friends.%SPEECH_OFF%}";
				}

				local rows = c.clueRows();
				rows.push(c.clockRow());
				this.List = rows;

				this.Options = [];
				if (!c.hasMark(F.MarkStatuesTried))
				{
					this.Options.push({
						Text = "{Look over the statues.}",
						function getResult() { return this.Contract.resolveLook("statues"); }
					});
				}
				if (!c.hasMark(F.MarkMossTried))
				{
					this.Options.push({
						Text = "{Look at the ground by the columns.}",
						function getResult() { return this.Contract.resolveLook("moss"); }
					});
				}
				if (!c.hasMark(F.MarkTalkTried))
				{
					this.Options.push({
						Text = "{Ask them what happened here.}",
						function getResult() { return this.Contract.resolveLook("talk"); }
					});
				}
				else
				{
					this.Options.push({
						Text = "{Split up and search the temple, as they ask.}",
						function getResult()
						{
							this.Contract.m.Reveal = 3;
							this.Contract.m.SprungBy = 3;
							::Skv.dbg("Skv.Fane: the company SPLIT UP -> Sprung (Circle)");
							return "Sprung";
						}
					});
				}
				this.Options.push({
					Text = "{Hand them the arrow.}",
					function getResult()
					{
						this.Contract.m.Reveal = 2;
						::Skv.dbg("Skv.Fane: the arrow HANDED OVER -> Burned (Line)");
						return "Burned";
					}
				});
				this.Options.push({
					Text = "{Something is wrong here. Say so.}",
					function getResult() { return this.Contract.resolveCallOut(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Unmasked",
			Title = "No Priests of Erastil",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/event_40.png[/img]{" + (c.m.Speaker == "" ? "%randombrother%" : c.m.Speaker) + " says it plainly: whatever these two are, they are no priests of Erastil.\n\nFor a moment nobody moves. Then the big one sighs, pushes back the green hood, and there is a sellsword's face under it, and mail under the robe. Armed men step out of the side rooms. They were waiting to hear the arrow change hands. They have not heard it, and the company is already facing them.}";
				this.List = c.m.RevealRows == null ? [] : c.m.RevealRows;
				this.Options = [
					{
						Text = "{At them!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatPriests();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Burned",
			Title = "The Arrow Knows",
			Text = "[img]gfx/ui/events/event_40.png[/img]{%randombrother% holds out the arrow, and the big priest takes it in both hands, and screams. Smoke curls up between his fingers. The black wood has burned him the way it would burn anything that belongs to Anogetz.\n\nThe arrow clatters to the flagstones. The robe falls open on mail, and armed men come boiling out of the side rooms. Whoever they are, nobody will ever be able to say now what they were doing here.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/special.png", text = "They are revealed, and the company is facing them" },
					{ id = 2, icon = "ui/icons/regular_damage.png", text = "Nothing was proved: the village has only your word" }
				];
				this.Options = [
					{
						Text = "{Grab the arrow and fight!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatPriests();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Sprung",
			Title = "Sprung",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local lead = c.m.SprungBy == 3
					? "The company fans out through the side rooms, two and three together, and that is exactly what they were waiting for."
					: c.m.SprungBy == 2
						? "The big priest only smiles at the accusation, and his smile is the signal."
						: "The big priest stops talking in the middle of a word. He has run out of patience, or out of reasons to keep pretending.";
				this.Text = "[img]gfx/ui/events/event_165.png[/img]{" + lead + " Men come out of the dark with steel already drawn, from every side at once. The two in green throw off their robes. They were never Erastil's, and the company is in the middle of them.}";

				local rows = [];
				if (c.m.SprungBy == 2 && c.m.RevealRows != null) rows.extend(c.m.RevealRows);
				rows.push({ id = 9, icon = "ui/icons/regular_damage.png", text = "They strike first, and from every side" });
				this.List = rows;
				this.Options = [
					{
						Text = "{Back to back!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatPriests();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Wakes",
			Title = "The Temple Wakes",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				this.Text = "[img]gfx/ui/events/event_178.png[/img]{The last of the sellswords goes down, and the fane goes quiet. Too quiet: every lantern flame leans the same way, toward the inner doors. Water is seeping out of the walls in a pattern that was not there an hour ago, a crown ringed with fangs. Outside, birds by the thousand are screaming in one great flock, and under them comes the howling of beasts that ought to be running from all this and are coming closer instead.\n\nWhatever sleeps behind the inner doors is waking up. The side rooms hold prayer mats, blankets and pots of seed, and at the back there are pools.}";
				this.List = [];
				this.Options = [];
				if (!c.hasMark(F.MarkPools))
				{
					this.Options.push({
						Text = "{Search the back room.}",
						function getResult() { return this.Contract.resolvePools(); }
					});
				}
				this.Options.push({
					Text = "{Catch our breath and set our gear right. (open loadout)}",
					function getResult()
					{
						::World.State.showLoadoutFromContract();
						return "Wakes";
					}
				});
				this.Options.push({
					Text = "{To the inner doors.}",
					function getResult() { return this.Contract.resolveDoors(); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Sanctum",
			Title = "The Sanctum",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				local tried = c.hasMark(F.MarkRitualTried);
				if (!tried)
				{
					this.Text = "[img]gfx/ui/events/event_131.png[/img]{Where the altar stood there is a statue now: a man of black stone with a ram's curling horns and a snake in each fist, and a ragged hole through his chest where an arrow once went. Smoke like ink pours out of the wound and crawls across the floor and up the walls.\n\nBefore it crouches the thing that has been waiting: a hunched, red-brown bulk the size of a cart, all jaw, with teeth like knives. It turns its head. A flock of starlings pours in through the doors behind you, whirls once around the chamber in a shrieking storm, and wherever it passes, wolves are standing, red-eyed, their fur smouldering.\n\nThe hole in the statue's chest is the wound the arrow made. Somebody could run for it.}";
					this.List = [];
					this.Options = [
						{
							Text = "{Run for the statue and drive the arrow home!}",
							function getResult() { return this.Contract.resolveRitual(); }
						},
						{
							Text = "{Hold the line and fight.}",
							function getResult()
							{
								this.Contract.getActiveState().onCombatDaemon();
								return 0;
							}
						}
					];
				}
				else
				{
					local held = c.hasMark(F.MarkRitualHeld);
					this.Text = "[img]gfx/ui/events/event_131.png[/img]{" + (held
						? "The black arrow stands in the statue's chest, and the cracks are still spreading. The daemon has not stopped screaming, and its wolves hang back behind it."
						: "The statue's wound still pours out smoke, and the daemon is coming.") + "}";
					this.List = [
						held
							? { id = 1, icon = "ui/icons/special.png", text = "The daemon and its beasts are weakened and shaken" }
							: { id = 1, icon = "ui/icons/regular_damage.png", text = "The daemon is at full strength" }
					];
					this.Options = [
						{
							Text = "{Here it comes!}",
							function getResult()
							{
								this.Contract.getActiveState().onCombatDaemon();
								return 0;
							}
						}
					];
				}
			}
		});

		this.m.Screens.push({
			ID = "Aftermath",
			Title = "The Forest Goes Quiet",
			Text = "[img]gfx/ui/events/event_142.png[/img]{The daemon dies hard, and when it dies the statue dies with it: the black stone cracks, and cracks again, and comes down in pieces. The smoke is gone. Outside, the birds have stopped. The wolves that are left slink off into the dark, and their fur is only fur again.\n\nThe arrow lies in the rubble where the altar was. %randombrother% picks it up. It is a spear, near enough, and nothing is left here for it to guard.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Back to the village.}",
						function getResult()
						{
							this.Contract.setState("Return");
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "RelicGone",
			Title = "The Arrow Is Gone",
			Text = "[img]gfx/ui/events/event_165.png[/img]{The company is driven back out through the great doors and into the dark of the wood. Behind it, in the lantern light, one of the sellswords holds the black arrow over his knee and snaps it in two.\n\nThere is nothing left to carry anywhere. Before long, the birds start screaming.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png", text = "The contract has failed" }
				];
				this.Options = [
					{
						Text = "{There is nothing more to do here.}",
						function getResult()
						{
							this.Contract.failContract("Lost Erastil's arrow at the fane");
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "FaneFalls",
			Title = "The Fane Falls",
			Text = "[img]gfx/ui/events/event_131.png[/img]{The company is thrown back out of the sanctum, and the inner doors swing shut behind it on their own. From the other side comes a sound like laughter, if a thing that size could laugh.\n\nThe arrow is still in there. So is the daemon. The fane in the wood will not be Erastil's much longer.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png", text = "The contract has failed" }
				];
				this.Options = [
					{
						Text = "{There is nothing more to do here.}",
						function getResult()
						{
							this.Contract.failContract("Lost the fane to a daemon");
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "Old Deadeye's Due",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local F = ::Const.Skv.Fane;
				local believed = c.hasMark(F.MarkVerdict);
				local first = "The old priest hears the whole of it standing up, one hand on the doorframe of his shrine." + (c.hasMark(F.MarkSymbols)
					? " When %randombrother% puts the two little bows of antler into his hand, he closes his fingers over them and does not say anything for a long time."
					: "");
				local second = believed
					? "Then he nods, slowly.%SPEECH_ON%Sellswords in their robes, and a daemon under the floor. And you put it down. Keep the arrow. It has nothing left to guard, and Old Deadeye knows whose hands carried it home.%SPEECH_OFF%He pays you from the shrine's box, and by evening the whole village knows what the company did at the fane."
					: "Word got here ahead of you: two priests dead at the fane, and a band of sellswords walking back out of the wood. The priest listens to all of it and pays what was promised, and tells you to keep the arrow. But he does not look at you while he says it, and neither does anyone else in the lane.";
				this.Text = "[img]gfx/ui/events/skv_erastil.png[/img]{" + first + "\n\n" + second + "}";

				local rows = [];
				rows.push({ id = 1, icon = "ui/icons/asset_money.png",
					text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.finalPay()) + " Crowns" });
				local spear = c.makeSpear();
				if (spear != null)
				{
					rows.push({ id = 2, icon = "ui/items/" + spear.getIcon(), imageOverlayPath = spear.getIconOverlay(),
						text = "You gain " + spear.getName() });
				}
				rows.push(c.moralRow());
				if (c.m.VerdictRows != null) rows.extend(c.m.VerdictRows);
				this.List = rows;

				this.Options = [
					{
						Text = believed ? "{Erastil keep you.}" : "{We did what we were paid to do.}",
						function getResult()
						{
							local c = this.Contract;
							local F = ::Const.Skv.Fane;
							if (c.m.Concluded == 0)
							{
								c.m.Concluded = 1;
								c.m.Act = 5;
								c.m.Outcome = 1;
								local pay = c.finalPay();
								::World.Assets.addMoney(pay);
								local spear = c.makeSpear();
								if (spear != null) ::Skv.Loot.haul([spear]);
								::World.Assets.addBusinessReputation(::Const.World.Assets.ReputationOnContractSuccess);
								local moral = c.moralFor();
								::World.Assets.addMoralReputation(moral);
								local f = ::World.FactionManager.getFaction(c.getFaction());
								local A = ::Const.World.Assets;
								local rel = c.hasMark(F.MarkVerdict) ? A.RelationCivilianContractSuccess * 2.0 : A.RelationCivilianContractPoor;
								if (f != null)
								{
									f.addPlayerRelation(rel, c.hasMark(F.MarkVerdict) ? "Put down a daemon at the fane" : "Came back from the fane, and the priests did not");
								}
								::Skv.dbg("Skv.Fane: ENDING pay=" + pay + " spear=" + (spear != null ? spear.getName() : "NONE")
									+ " moral=" + moral + " relation=" + rel + " clues=" + c.m.Clues + " reveal=" + c.m.Reveal
									+ " marks=" + c.m.Marks);
							}
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Result",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Title = this.Contract.m.SayTitle;
				this.Text = (this.Contract.m.SayImage == "" ? "" : "[img]gfx/ui/events/" + this.Contract.m.SayImage + ".png[/img]")
					+ this.Contract.m.SayText;
				this.List = this.Contract.m.SayRows == null ? [] : this.Contract.m.SayRows;
				this.Options = [
					{
						Text = "{Onward.}",
						function getResult()
						{
							local n = this.Contract.m.SayNext;
							return n == "" ? this.Contract.hubScreen() : n;
						}
					}
				];
			}
		});
	}

	function onClear()
	{
		::Skv.Once.release("Fane");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Fane");

			if (!::MSU.isNull(this.m.Destination))
			{
				this.m.Destination.getSprite("selection").Visible = false;
				this.m.Destination.die();
				this.m.Destination = null;
			}
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onSerialize( _out )
	{
		if (!::MSU.isNull(this.m.Destination))
		{
			_out.writeU32(this.m.Destination.getID());
		}
		else
		{
			_out.writeU32(0);
		}
		_out.writeU8(this.m.Act);
		_out.writeU8(this.m.Clues);
		_out.writeU8(this.m.Beats);
		_out.writeU8(this.m.Reveal);
		_out.writeU8(this.m.SprungBy);
		_out.writeU8(this.m.Outcome);
		_out.writeU8(this.m.Concluded);
		_out.writeU8(this.m.Res8);
		_out.writeU16(this.m.Marks);
		_out.writeU32(this.m.Res32);
		_out.writeString(this.m.Speaker);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local destination = _in.readU32();
		if (destination != 0)
		{
			this.m.Destination = this.WeakTableRef(::World.getEntityByID(destination));
		}
		this.m.Act = _in.readU8();
		this.m.Clues = _in.readU8();
		this.m.Beats = _in.readU8();
		this.m.Reveal = _in.readU8();
		this.m.SprungBy = _in.readU8();
		this.m.Outcome = _in.readU8();
		this.m.Concluded = _in.readU8();
		this.m.Res8 = _in.readU8();
		this.m.Marks = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.m.Speaker = _in.readString();
		this.contract.onDeserialize(_in);
	}
});
