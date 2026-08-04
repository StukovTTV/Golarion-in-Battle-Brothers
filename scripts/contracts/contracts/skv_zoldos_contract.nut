this.skv_zoldos_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Act = 0,

		Destination = null,

		Rockslide = 0,

		Shrine    = 0,

		Cages     = 0,
		CagesTried = 0,

		Fight1 = 0,
		Fight2 = 0,

		Outcome  = 0,
		Reported = 0,

		Aborted   = 0,
		Concluded = 0,

		Hoard     = 0,
		Res16     = 0,
		HoardCoin = 0,
		ResStr    = "",

		ActorName = "",
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

	function paras( _list )
	{
		local out = "";
		foreach (t in _list)
		{
			if (t == null || t == "") continue;
			if (out != "")
			{

				local n = out.len();
				local endsSpeech = n >= 12 && out.slice(n - 12) == "%SPEECH_OFF%";
				if (!endsSpeech) out = out + "\n\n";
			}
			out = out + t;
		}
		return "{" + out + "}";
	}

	function hubScreen()
	{
		if (this.m.Rockslide == 0) return "Climb";
		if (this.m.Rockslide <= 2) return "Slide";
		if (this.m.Shrine == 0)    return "Shrine";
		if (this.m.Act < 4)        return "Caves";

		if (this.m.Fight1 != 1)    return "Deeper";

		if (this.m.Fight2 != 1)    return "Lair";

		if (this.m.Hoard == 0)     return "Aftermath";
		return "Down";
	}

	function hoardPaths()
	{
		return [
			"scripts/items/loot/jeweled_crown_item",
			"scripts/items/loot/gemstones_item",
			"scripts/items/loot/ancient_gold_coins_item"
		];
	}

	function hoardCoin()
	{
		if (this.m.HoardCoin == 0) this.m.HoardCoin = this.Math.rand(800, 1600);
		return this.m.HoardCoin;
	}

	function hoardPreview()
	{
		local rows = [{ id = 1, icon = "ui/icons/special.png",
			text = this.savedCount() + " of 4 sent down the path" }];
		rows.extend(::Skv.Loot.previewRows(this.hoardPaths(), this.hoardCoin()));
		return rows;
	}

	function takeHoard()
	{
		if (this.m.Hoard != 0) return;
		this.m.Hoard = 1;

		local items = ::Skv.Loot.make(this.hoardPaths());
		::Skv.Loot.haul(items, this.hoardCoin());
		::Skv.dbg("Skv.Zoldos: hoard taken - " + items.len() + " items + " + this.m.HoardCoin + " crowns");
	}

	function wyrmBudget()
	{
		return 75.0 * this.getDifficultyMult() * this.getScaledDifficultyMult();
	}

	function wyrmIsChampion()
	{
		return this.wyrmBudget() >= ::Const.Skv.ZikritraxChampionBudget;
	}

	function onWyrmPlaced( _entity, _tag )
	{
		if (_entity == null)
		{
			::logError("Skv.Zoldos: onWyrmPlaced got a null entity - Zikritrax is unpainted and unnamed.");
			return;
		}

		if (this.wyrmIsChampion())
		{

			local ok = _entity.makeMiniboss();
			::Skv.dbg("Skv.Zoldos: Zikritrax championed=" + ok + " (budget " + this.wyrmBudget()
				+ " >= " + ::Const.Skv.ZikritraxChampionBudget + ")");
		}

		local tint = null;
		try { tint = this.createColor(::Const.Skv.ZikritraxTint); }
		catch (e) { ::logError("Skv.Zoldos: could not build Zikritrax's tint - " + e); }

		this.tintWyrm(_entity, tint);
	}

	function tintWyrm( _e, _tint )
	{
		local targets = [_e];
		try
		{
			local t = _e.getTail();
			if (t != null && !t.isNull())
			{
				targets.push(t);

				try
				{
					t.setName(::Const.Skv.ZikritraxTailName);
					t.m.IsGeneratingKillName = false;
				}
				catch (e) { ::Skv.dbg("Skv.Zoldos: could not name the tail - " + e); }
			}
			else ::Skv.dbg("Skv.Zoldos: Zikritrax has no tail to paint - no free adjacent tile at placement.");
		}
		catch (e) { ::Skv.dbg("Skv.Zoldos: tail lookup failed - " + e); }

		foreach (target in targets)
		{
			foreach (layer in ::Const.Skv.ZikritraxLayers)
			{
				try
				{
					local sp = target.getSprite(layer);
					if (sp == null) continue;
					if (_tint != null) sp.Color = _tint;
					sp.Saturation = ::Const.Skv.ZikritraxSaturation;

					::Skv.dbg("Skv.Zoldos: tinted '" + layer + "' -> Saturation now " + sp.Saturation);
				}
				catch (e) { ::Skv.dbg("Skv.Zoldos: tint failed on '" + layer + "' - " + e); }
			}
		}
	}

	function hurtSome( _n, _min, _max )
	{
		local rows = [];
        local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
		if (pool.len() == 0) return rows;

		local n = this.Math.min(_n, pool.len());
		local taken = {};
		for (local i = 0; i < n; i = i + 1)
		{
			local bro = null;
			for (local t = 0; t < 12 && bro == null; t = t + 1)
			{
				local c = pool[this.Math.rand(0, pool.len() - 1)];
				if (!(c.getID() in taken)) bro = c;
			}
			if (bro == null) continue;
			taken[bro.getID()] <- true;

			local dmg = this.Math.rand(_min, _max);
			local hp = bro.getHitpoints() - dmg;
			if (hp < 1) hp = 1;
			bro.setHitpoints(hp);
			rows.push({ id = 10, icon = "ui/icons/health.png", text = bro.getName() + " loses " + dmg + " health" });
		}
		return rows;
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

	function resolveRead()
	{
		local rows = [];
		local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, 45));
		local text;

		if (r.ok)
		{
			this.m.Rockslide = 2;
			rows.push({ id = 1, icon = "ui/icons/special.png", text = r.actor.getName() + " reads the slope" });
			text = "{Half an hour above the shelter cave " + r.actor.getName() + " stops the line without being asked, and stands with his head on one side.%SPEECH_ON%This whole face is loose. Shale on shale, and nothing holding it but habit. If it goes, it goes all at once and it goes quietly until it does not.%SPEECH_OFF%He points out the lee of a dressed wall, forty feet on, and makes every man look at it before moving off.}";
		}
		else
		{
			this.m.Rockslide = 1;
			rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "Nobody reads the slope" });
			text = "{The path above the shelter cave is shale on shale, and the company walks it the way they would walk a road. Nobody looks up. Nobody picks out the ground they would want to be standing on if they had to choose in a hurry.}";
		}

		rows.extend(::Skv.XP.check(r));
		return this.say("The Slope", text, rows, "Slide", "event_113");
	}

	function resolveSlide()
	{
		local rows = [];

		local warned = this.m.Rockslide == 2;
		local chance = ::Skv.Check.scaledBase(this, 50) + (warned ? 15 : 0);
		local r = ::Skv.Check.reflex(this, chance, 0.5);

		local caught = r.total - r.passed;
		local clear = r.star  != null ? r.star.getName()  : "somebody";
		local hit   = r.worst != null ? r.worst.getName() : "somebody";

		local opening = "The mountain makes a sound like a door being dragged, somewhere above and to the right, and then the whole face of it is moving.";
		local second;
		local third;

		if (caught == 0)
		{
			this.m.Rockslide = 3;
			second = warned
				? clear + " is at the dressed wall the moment the sound starts, and so is everybody else. They were walked to it an hour ago and not one of them needed telling twice."
				: clear + " goes flat into the lee of a dressed wall nobody had picked out, and the rest of them go where he goes, on nothing but the sight of him going.";
			third = "The mountain goes past rather than through. When it stops there is a new slope where the path used to be, and the company is on the wrong side of it, and every man who started up here is standing.";
			rows.push({ id = 2, icon = "ui/icons/special.png",
				text = "The whole line reaches the wall" });
		}
		else if (caught < r.total)
		{
			this.m.Rockslide = 4;
			second = warned
				? clear + " is at the dressed wall the moment the sound starts and most of the line is with him. Being shown a thing and reaching it are not the same, and the slowest of them learn the difference in the open."
				: clear + " goes flat into the lee of a dressed wall nobody had picked out, and most of the line follows him on nothing but the sight of him going - not all of it, and not the ones who were still deciding.";
			third = caught == 1
				? "The stone comes through in three long pushes with a breath between each. When the dust drops there is a new slope where the path used to be, and one man out on it who has to be dug up out of what stopped on top of him - and who then keeps climbing, because there is nowhere behind him to be sent."
				: "The stone comes through in three long pushes with a breath between each. When the dust drops there is a new slope where the path used to be, and there are men out on it who need digging up out of what stopped on top of them, and who then have to keep climbing, because there is nowhere behind them to be sent.";
			rows.push({ id = 2, icon = "ui/icons/regular_damage.png",
				text = r.passed + " of " + r.total + " reach the wall" });
		}
		else
		{
			this.m.Rockslide = 4;
			second = warned
				? "Every man knows exactly where he is meant to be standing, and the mountain is faster than the distance to it. The wall might as well have been in the next valley."
				: "Nobody has picked out anywhere to be, so every man settles it for himself with the ground already moving under him, and not one of them settles it well.";
			third = hit + " is the last man anybody can account for. When the dust drops the path is gone and the company is on the wrong side of whatever replaced it, every one of them bleeding, and still nearer the caves than the village.";
			rows.push({ id = 2, icon = "ui/icons/regular_damage.png",
				text = "Nobody reaches the wall" });
		}

		rows.extend(this.hurtThese(r.rows, 8, 18));

		local text = this.paras([opening, second, third]);

		rows.extend(::Skv.XP.checkEach(r));
		this.m.Act = 2;

		return this.say("Rocks Tumble", text, rows, "", "event_160");
	}

	function resolveShrine()
	{
		local rows = [];
		local opening = "The lid is seized rather than locked, and comes up on the third try.%SPEECH_ON%Tools. Somebody's whole working life, laid out and left.%SPEECH_OFF%";
		local sigil;

		local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, 40));
		rows.extend(::Skv.XP.check(r));
		if (r.ok)
		{
			rows.push({ id = 1, icon = "ui/icons/special.png", text = r.actor.getName() + " names the hammer on the lid" });
			sigil = r.actor.getName() + " puts a thumb on the hammer cut into the lid.%SPEECH_ON%Torag. The forge, and holding what you have got. Dwarves do not leave a shrine unless they leave in a hurry.%SPEECH_OFF%";
		}
		else
		{
			sigil = "Nobody can put a name to the hammer on the lid. Somebody's god, and not one that has been prayed to here in a long while.";
		}

		local orbs = "Under the tools, in a nest of oiled rag, four grey spheres the size of plums - far heavier than they have any business being. Nobody can make them do anything, and after a while they go back in the rag.";
		local text = this.paras([opening, sigil, orbs]);

		local items = ::Skv.Loot.make(["scripts/items/loot/silverware_item"]);
		local coin = this.Math.rand(60, 110);
		rows.extend(::Skv.Loot.haul(items, coin));

		this.m.Shrine = 1;
		this.m.Act = 3;

		return this.say("Torag's Treasure", text, rows, "", "skv_torag");
	}

	function cageName( _i )
	{
		if (_i == 0) return "Lydia";
		if (_i == 1) return "Alyx";
		if (_i == 2) return "Caelia";
		return "Eide";
	}

	function resolveCage( _i )
	{
		local bit = 1 << _i;
		if ((this.m.CagesTried & bit) != 0) return this.hubScreen();
		this.m.CagesTried = this.m.CagesTried | bit;

		local who = this.cageName(_i);
		local r, opening, won, lost;

		if (_i == 0)
		{
			r = ::Skv.Check.lockpick(this, ::Skv.Check.scaledBase(this, 50));
			opening = "The first is a dwarf-cut grate wedged into a seam of the rock, and it is held by a lock somebody has since beaten flat with a stone. The woman behind it does not ask who you are.%SPEECH_ON%Lydia. Eliana's wife, from the village down there. Do the children first.%SPEECH_OFF%";
			won  = r.actor.getName() + " works the flattened lock for a long quiet while and then it simply opens, the way a lock does when it has decided to.";
			lost = r.actor.getName() + " cannot get anything to move in it. The lock is not locked so much as ruined, and ruined is worse.";
		}
		else if (_i == 1)
		{
			r = ::Skv.Check.brawn(this, ::Skv.Check.scaledBase(this, 50));
			opening = "The second is green timber lashed with wire and driven into the floor, and the boy inside it has stopped expecting anything. He is perhaps nine.";
			won  = r.actor.getName() + " gets both hands under the frame, sets his feet, and lifts until something in the timber gives rather than something in him.";
			lost = r.actor.getName() + " gets it up to the height of his knee, and holds it there, and it does not go further no matter what the rest of them add to it.";
		}
		else if (_i == 2)
		{
			r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 50));
			opening = "The third looks solid from every angle, and it is not; something in it is carrying more weight than it should. The girl inside watches the company circle it without saying anything at all.";
			won  = r.actor.getName() + " finds it on the second pass - one upright split along the grain, hidden behind the lashing. After that it is a matter of where to push.";
			lost = "Nobody finds the fault in it. There is one, and it is in there, and the company walks around that cage until walking around it stops being useful.";
		}
		else
		{
			r = ::Skv.Check.handEye(this, ::Skv.Check.scaledBase(this, 50));
			opening = "The fourth is the neatest of them: one iron pin carrying the whole frame, set deep where a hand cannot follow it. The smallest of the three children is behind it, and she is the only one who has been crying.";
			won  = r.actor.getName() + " sets a spike on the head of the pin, hits it once, and the whole cage comes apart around the child like something remembering it was only ever sticks.";
			lost = r.actor.getName() + " sets the spike three times and drives the pin further in twice. The fourth attempt splits the spike.";
		}

		local rows = [];
		local text;

		local last = this.m.CagesTried == 15;

		if (r.ok)
		{
			this.m.Cages = this.m.Cages | bit;
			rows.push({ id = 1, icon = "ui/icons/special.png", text = who + " is out" });
			local tail = this.savedCount() == 1
				? who + " is put on the path down alone, and told to keep going and not to wait."
				: who + " is put on the path down after the others, and told to keep going and not to wait.";
			text = this.paras([opening, won, tail]);
		}
		else
		{

			rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "We could not reach " + who });
			local tail = last
				? "The company has to leave that one where it stands. There is nothing else in the room to turn to instead, and standing here is not going to open it."
				: "The company has to leave that one where it stands. Nobody says anything on the way to the next.";
			text = this.paras([opening, lost, tail]);
		}

		rows.extend(::Skv.XP.check(r));
		return this.say("The Cages", text, rows, "", "event_182");
	}

	function cavesText()
	{
		local img = "[img]gfx/ui/events/event_89.png[/img]";

		if (this.m.CagesTried == 0)
		{
			return img + this.paras([
				"Above the shrine the face opens into a proper mouth - thirty feet of it, and torches burning inside where no villager put them. Something has been living here long enough to want the light.",
				"%SPEECH_ON%Bones down the left of the path. Sheep, mostly. Not only sheep.%SPEECH_OFF%",
				"The first chamber is wide and low and there are four cages in it, set well apart, each one built out of whatever was nearest when it was needed. Nobody who built them meant them to be opened.",
				"%SPEECH_ON%Quiet, now. There is more than one thing in here, and it is not in this room yet.%SPEECH_OFF%"
			]);
		}

		if (this.m.CagesTried != 15)
		{
			local middle = this.savedCount() > 0
				? "The ones who are out are out. They were pointed at the light and told not to wait for anybody, and not one of them looked much like waiting."
				: "Nothing has come out of this room yet. The ones still in it have stopped asking, and the company has learned to work without being asked.";

			return img + this.paras([
				"The chamber holds a sound the way a low room does - everything done in it happens twice, once at the hands and once a moment later in the walls.",
				middle,
				"%SPEECH_ON%The rest are where we found them. Pick one and be quick, because whatever is further in is not deaf.%SPEECH_OFF%"
			]);
		}

		local middle = this.savedCount() > 0
			? "The freed are on the path already, moving badly and moving all the same."
			: "Nobody is on the path. The company came up this mountain to carry four people down it and is standing here with empty hands and somewhere left to go.";

		return img + this.paras([
			"That is every cage in the room, and the room has nothing else in it to be done. The torches keep burning for something that is not here.",
			middle,
			"%SPEECH_ON%Down, then. It is not going to come up and meet us in the doorway.%SPEECH_OFF%"
		]);
	}

	function familyRenown()
	{
		local ladder = [-100, -20, 0, 5, 25];
		return ::Const.World.Assets.ReputationOnContractSuccess + ladder[this.savedCount()];
	}

	function familyRelation()
	{
		local ladder = [-25.0, -10.0, -5.0, 0.0, 10.0];
		return ::Const.World.Assets.RelationCivilianContractSuccess + ladder[this.savedCount()];
	}

	function endingPay()
	{
		local full = this.m.Payment.getOnCompletion();
		return this.m.Fight2 == 1 ? full : this.Math.floor(full * 0.5);
	}

	function endingTier()
	{
		local n = this.savedCount();
		if (n == 4) return 1;
		if (n > 0)  return 2;
		return 3;
	}

	function savedCount()
	{
		local n = 0;
		for (local i = 0; i < 4; i = i + 1)
		{
			if ((this.m.Cages & (1 << i)) != 0) n = n + 1;
		}
		return n;
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_zoldos";

		this.m.Name = "The Scourge of Mount Zoldos";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Hunt;
		this.m.DescriptionTemplates = [
			"A village under the mountains is feeding something on a schedule. Sheep first, then cattle, and the herds are nearly gone. The mayor wants it ended, and wants her family back out of its caves before it is.",
			"Every third day a village drives livestock up the mountain and comes back without it. The thing in the caves of Mount Zoldos took the mayor's wife and children when the village last said no, and has been fed ever since.",
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

		this.m.DifficultyMult = this.Math.rand(90, 140) * 0.01;

		this.m.Payment.Pool = ::Skv.Econ.pool(this, 500, 0.6, 1.4);

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

				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
				{
					this.Contract.m.Name = "The Scourge of " + this.Contract.m.Home.getName();
				}

				this.Contract.m.BulletpointsObjectives = [
					"Hear out Eliana, the mayor of " + this.Contract.m.Home.getName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				local tiles = this.Contract.m.Home.getSurroundingTilesOfType([this.Const.World.TerrainType.Mountains], 3);
				local tile = null;
				foreach (t in tiles)
				{
					if (!t.IsOccupied) { tile = t; break; }
				}

				if (tile == null)
				{
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 3, 6);
				}

				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_zoldos_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);

				::Skv.dbg("Skv.zoldos: lair at " + tile.Coords.X + "," + tile.Coords.Y
					+ " terrain=" + tile.Type
					+ (tile.Type == this.Const.World.TerrainType.Mountains ? " (Mountains)" : " (NOT Mountains -- fallback ran)"));

				this.Contract.m.Act = 1;
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}

		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Climb Mount Zoldos"
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

				local f = this.Flags.get("F13");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V13") == f;
					local fled = this.Flags.get("R13") == f;
					this.Flags.set("F13", "");
					this.Flags.set("V13", "");
					this.Flags.set("R13", "");

					if (!won && !fled)
					{
						::Skv.dbg("Skv.Zoldos: " + f + " was launched but never resolved - dialog cancelled, no state change.");
					}
					else if (f == "Skv13Wyrm")
					{
						this.Contract.m.Fight2 = won ? 1 : 2;
						::Skv.dbg("Skv.Zoldos: Zikritrax " + (won ? "KILLED" : "DROVE THEM OUT")
							+ " -> Fight2=" + this.Contract.m.Fight2);
						this.TempFlags.set("AtSite", false);
					}
					else if (f == "Skv13Bears")
					{

						this.Contract.m.Fight1 = won ? 1 : 2;
						::Skv.dbg("Skv.Zoldos: den " + (won ? "WON" : "REPULSED") + " -> Fight1=" + this.Contract.m.Fight1);

						this.TempFlags.set("AtSite", false);
					}
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

			function onCombatBears()
			{
				local c = this.Contract;

				local p = ::Const.Tactical.CombatInfo.getClone();
				p.CombatID = "Skv13Bears";
				p.TerrainTemplate = "tactical.skv_ruin_floor";
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;

				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.IsWithoutAmbience = true;

				p.Entities = [];

				local budget = 80 * c.getDifficultyMult() * c.getScaledDifficultyMult();
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();

				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionCaveBears, budget,
					fac, "Zoldos/Den", ::Const.World.Spawn.GolarionCaveBears);

				::Skv.dbg("Skv.Zoldos: den fight budget=" + budget
					+ " diff=" + c.getDifficultyMult() + " scaled=" + c.getScaledDifficultyMult()
					+ " retry=" + (c.m.Fight1 == 2) + " saved=" + c.savedCount());

				this.Flags.set("F13", "Skv13Bears");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatWyrm()
			{
				local c = this.Contract;

				local p = ::Const.Tactical.CombatInfo.getClone();
				p.CombatID = "Skv13Wyrm";
				p.TerrainTemplate = "tactical.skv_ruin_floor";
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;

				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;
				p.IsWithoutAmbience = true;
				p.Entities = [];

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();

				p.Entities.push({
					ID = ::Const.EntityType.Lindwurm,
					Variant = 0,
					Row = -1,
					Script = "scripts/entity/tactical/enemies/lindwurm",
					Faction = fac,
					Name = ::Const.Skv.ZikritraxName,
					Callback = c.onWyrmPlaced.bindenv(c)
				});

				local budget = c.wyrmBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionCaveBears, budget,
					fac, "Zoldos/Court", ::Const.World.Spawn.GolarionCaveBears);

				::Skv.dbg("Skv.Zoldos: lair fight budget=" + budget
					+ " diff=" + c.getDifficultyMult() + " scaled=" + c.getScaledDifficultyMult()
					+ " champion=" + c.wyrmIsChampion() + " retry=" + (c.m.Fight2 == 2)
					+ " saved=" + c.savedCount());

				this.Flags.set("F13", "Skv13Wyrm");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string")
				{
					return;
				}
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv13")
				{
					return;
				}
				this.Flags.set("V13", _combatID);
				::Skv.dbg("Skv.Zoldos: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F13");
				if (f == null || f == false || f == "")
				{
					return;
				}
				this.Flags.set("R13", f);
				::Skv.dbg("Skv.Zoldos: retreated from " + f + " (id=" + _combatID + ")");
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
				if (c.m.Reported != 0) return;
				if (c.m.Home == null || c.m.Home.isNull()) return;

				local arrived = c.isPlayerAt(c.m.Home);
				if (!arrived)
				{
					try
					{
						local t = ::World.State.getCurrentTown();
						if (t != null && t.getID() == c.m.Home.getID()) arrived = true;
					}
					catch (e) {}
				}

				if (!arrived) return;

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
			Title = "The Scourge of Mount Zoldos",

			Text = "[img]gfx/ui/events/skv_andoran.png[/img]{Half the houses are down. The rest have been patched with whatever was standing nearby, and the square is a tent. The woman who ducks out of it is wearing a hat too big for the weather and has a smith's forearms under the sleeves.%SPEECH_ON%%SKVNAME%Eliana%SKVNAME_OFF%. I am the mayor here. I was a smith before that, and I would rather be one now.%SPEECH_OFF%She does not sit down.%SPEECH_ON%There is a wyrm in the caves of %SKVLOC%Mount Zoldos%SKVLOC_OFF%, above us. It came down at the last election, put the meeting hall through the ground, and told us what it wanted. I went up to argue. It threw me out of its own cave. I went up again with my guards, and it followed us home and did this.%SPEECH_OFF%She gestures at the square without looking at it.%SPEECH_ON%It has my wife and my three children in those caves. Since then we have fed it every third day. Sheep, and now the cattle, and after that the horses, and after that I do not know. My militia is what you can see. I have coin, and I have nobody to spend it on but you.%SPEECH_OFF%}",
			Image = "",
			List = [],

			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{

				this.Options = [
					{
						Text = "{We will go up and put an end to it.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{%SKVLOC%Mount Zoldos%SKVLOC_OFF%. What is up there besides the wyrm?}",
						function getResult() { return "Lore"; }
					});
				}

				this.Options.push({
					Text = "{Feed it, then. This is not for us.}",
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
			Title = "The Mountain",
			Text = "[img]gfx/ui/events/event_126.png[/img]{%randombrother% has been looking at the peak since they rode in.%SPEECH_ON%Bear country, that. And the paths will be shedding rock this time of year - you hear it before you see it, and you do not outrun it. You get small, or you get under something.%SPEECH_OFF%%randombrother2% is less interested in the weather.%SPEECH_ON%The mayor says caves. Caves means it is not flying about, whatever else it is. And it means whatever it has taken is in there with it.%SPEECH_OFF%%randombrother% shrugs.%SPEECH_ON%There is meant to be an old dwarf shrine halfway up. Torag's, if it is anyone's. Nobody has been in it for a long while.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Back to the mayor.}",
					function getResult() { return "Task"; }
				}
			]
		});

		this.m.Screens.push({
			ID = "Climb",
			Title = "The Road Up",
			Text = "[img]gfx/ui/events/event_113.png[/img]{The path is a goat track with pretensions. The village drops away below, and with it the last of the warm air; by the second hour the grass has given out and there is nothing underfoot but shale that moves when you put weight on it.%SPEECH_ON%There is the cave the mayor drew. Old dwarf work, by the lintel.%SPEECH_OFF%It is a black slot in the rock a little off the path, and it is the only thing on this face of the mountain that would stop a wind, never mind anything else.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Up, and past the shelter cave.}",
						function getResult() { return this.Contract.resolveRead(); }
					},
					{
						Text = "{This is a bad mountain. Turn back.}",
						function getResult() { return "Abandon"; }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Slide",
			Title = "Above the Shelter Cave",
			Text = "[img]gfx/ui/events/event_113.png[/img]{The path narrows to a ledge a shoulder wide, with the whole of the valley hanging off the left of it. Somewhere up and to the right a stone lets go of another stone.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Keep moving.}",
						function getResult() { return this.Contract.resolveSlide(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Shrine",
			Title = "The Shelter Cave",
			Text = "[img]gfx/ui/events/event_154.png[/img]{Inside, out of the wind, the cave smells of old soot and older metal. It is not a cave so much as a room that a cave grew around: the walls were dressed once, and there is a low bench cut along one side with the shape of an anvil still worn into it.%SPEECH_ON%Somebody worked here. A long time before anybody in that village down there.%SPEECH_OFF%At the back, under a fall of grit, there is a chest with a hammer cut into the lid.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [];

				if (this.Contract.m.Shrine == 0)
				{
					this.Options.push({
						Text = "{Get the lid off it.}",
						function getResult() { return this.Contract.resolveShrine(); }
					});
				}

				this.Options.push({
					Text = "{Leave it. The caves are above us.}",
					function getResult()
					{

						if (this.Contract.m.Shrine == 0) this.Contract.m.Shrine = 2;
						this.Contract.m.Act = 3;
						return this.Contract.hubScreen();
					}
				});
			}

		});

		this.m.Screens.push({
			ID = "Caves",
			Title = "The Caves of Mount Zoldos",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;

				this.Text = c.cavesText();

				this.List = [];
				if (c.m.CagesTried != 0)
				{
					this.List.push({ id = 1, icon = "ui/icons/special.png",
						text = c.savedCount() + " of 4 sent down the path" });
				}

				this.Options = [];

				if ((c.m.CagesTried & 1) == 0)
				{
					this.Options.push({
						Text = "{The grate with the beaten lock.}",
						function getResult() { return this.Contract.resolveCage(0); }
					});
				}
				if ((c.m.CagesTried & 2) == 0)
				{
					this.Options.push({
						Text = "{The lashed timber frame.}",
						function getResult() { return this.Contract.resolveCage(1); }
					});
				}
				if ((c.m.CagesTried & 4) == 0)
				{
					this.Options.push({
						Text = "{The one that looks solid.}",
						function getResult() { return this.Contract.resolveCage(2); }
					});
				}
				if ((c.m.CagesTried & 8) == 0)
				{
					this.Options.push({
						Text = "{The frame on the single iron pin.}",
						function getResult() { return this.Contract.resolveCage(3); }
					});
				}

				if (c.m.CagesTried == 15)
				{
					this.Options.push({
						Text = "{That is all of them. Deeper, then.}",
						function getResult()
						{
							this.Contract.m.Act = 4;
							return "Deeper";
						}
					});
				}

				this.Options.push({
					Text = "{This is beyond us. Go back down.}",
					function getResult() { return "Abandon"; }
				});
			}

		});

		this.m.Screens.push({
			ID = "Deeper",
			Title = "Further In",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;

				if (c.m.Fight1 == 2)
				{
					this.Text = "[img]gfx/ui/events/event_89.png[/img]" + c.paras([
						"The passage is where it was and so is what is in it. The company came out of here at a run once already, and going back to a place you have been beaten out of is a different walk entirely.",
						"%SPEECH_ON%They will be fed and slow now. That is the best we are going to get out of it.%SPEECH_OFF%"
					]);
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_89.png[/img]" + c.paras([
						"Past the cages the floor tilts down and the torches stop. Whatever keeps them lit does not come this far, and the air coming up is warm, and moves.",
						"The smell arrives before anything else does - wet fur and old kill, banked up in the warm the way a cellar holds a smell all winter. Something in the dark ahead stands up out of a bed it has been keeping for a long time, and then something else does.",
						"%SPEECH_ON%Bears. They den where it is warm and they eat what it leaves, and it leaves plenty.%SPEECH_OFF%"
					]);
				}

				this.List = [
					{ id = 1, icon = "ui/icons/special.png", text = c.savedCount() + " of 4 sent down the path" }
				];

				this.Options = [
					{
						Text = c.m.Fight1 == 2 ? "{Back in. Shields first this time.}" : "{Shields. Take the passage.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatBears();
							return 0;
						}
					},
					{
						Text = "{We have who we came for. Go back down.}",
						function getResult() { return "Abandon"; }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Lair",
			Title = "Zikritrax",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;

				local opening = c.m.Fight2 == 2
					? "The passage is unchanged and so is what is at the end of it. The torches come up as the company reaches the turn, the same as last time, and the ground is already moving to the same slow beat."
					: "The passage runs down a long way and then opens, and the opening does not end. The ceiling goes up out of the torchlight entirely. The torches themselves come up as the company enters - not one by one, all of them, and nobody is holding a taper.%SPEECH_ON%The ground. Feel it. That is not the mountain settling. That is the mountain breathing.%SPEECH_OFF%";

				local him = c.wyrmIsChampion()
					? "He is the size of a barn and the colour of a cold anvil, and the scales are not scales so much as plate that grew there. Where the torchlight touches him it does not come back. There is nothing in these mountains that has made him move faster than he wanted to in a very long time, and it shows in how little attention he pays to armed men."
					: "He is the size of a barn and the colour of a cold anvil, and the scales are not scales so much as plate that grew there. Where the torchlight touches him it does not come back.";

				local court = "Around him, in the dark at the edges, the bears. Their hides are studded with his cast scales, driven in and grown over, and they do not look at the company at all - they look at him, and wait.";

				local speech = "%SPEECH_ON%So. Instead of my proper sacrifice - two dozen head of cattle, which is not a great deal to ask of a village that keeps its houses standing at my discretion - they have sent me a motley band of foolhardy sellswords.%SPEECH_OFF%He does not get up. He has not needed to get up for anything in years.%SPEECH_ON%You truly dare? Me? Zikritrax the mighty. Zikritrax the fearsome. Zikritrax the destroyer.%SPEECH_OFF%Somewhere back along the line a man shifts his grip and the sound goes all the way up into the dark and comes back.%SPEECH_ON%Come. Grovel, and throw what you are carrying down at my feet, and I may let you walk out of here. Or I could put you in the boulder cage with that irritating mayor's family. There is room. There has been room for a while now.%SPEECH_OFF%";

				this.Text = "[img]gfx/ui/events/event_129.png[/img]" + c.paras([opening, him, court, speech]);

				this.List = [
					{ id = 1, icon = "ui/icons/special.png", text = c.savedCount() + " of 4 sent down the path" }
				];

				this.Options = [
					{
						Text = c.m.Fight2 == 2 ? "{He talks. Get in close and stay there.}" : "{Nobody is grovelling. Kill it.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatWyrm();
							return 0;
						}
					},
					{
						Text = "{We have who we came for. Go back down.}",
						function getResult() { return "Abandon"; }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Aftermath",
			Title = "The Hoard",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;

				this.Text = "[img]gfx/ui/events/event_04.png[/img]" + c.paras([
					"It takes a long time to stop moving, and longer for anybody to go near it.",
					"Behind where it lay the chamber keeps going, and the floor of it is money. Not a pile - a floor, ankle-deep in places, of coin and plate and cut stone hauled up here over years from places that never found out where any of it went. Somebody turns up an amulet cut from a bone too big to name and puts it in his shirt without saying anything about it.",
					"There is also, penned at the back behind a rockfall he built himself, a small and extremely frightened group of sheep.%SPEECH_ON%He was saving them.%SPEECH_OFF%%SPEECH_ON%He was saving them for later. That is what that is.%SPEECH_OFF%",
					"The way out is the way in, and it is a long way, and there are people down at the bottom of it waiting to be told."
				]);

				this.List = c.hoardPreview();

				this.Options = [
					{
						Text = "{Take what we can carry and get out.}",
						function getResult()
						{
							local c = this.Contract;
							c.takeHoard();
							return "Down";
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Down",
			Title = "Down",
			Text = "[img]gfx/ui/events/event_113.png[/img]{The descent takes what is left of the day. Nobody talks much on it. The village is a smudge of roofs a very long way below, and somewhere between here and there are however many people the company managed to get out of that mountain, going the same way on worse legs.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/special.png", text = this.Contract.savedCount() + " of 4 sent down the path" }
				];
				this.Options = [
					{
						Text = "{Go and tell her.}",
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
			ID = "Abandon",
			Title = "Down",
			Text = "",
			Image = "",
			List = [],
			Options = [],

			function start()
			{
				local c = this.Contract;
				local carrying = c.savedCount() > 0;

				this.Text = carrying
					? c.paras([
						"Nobody argues. The mountain has already made its case, and the men who were loudest in the village square are the quietest on the way down.",
						"There are people on the path ahead of them who would not be on it otherwise, walking badly and not looking back at the mouth of the cave, and that is not nothing to be carrying down.%SPEECH_ON%We did not get what she paid for. We got what she asked for. There is a difference and she will know it.%SPEECH_OFF%"
					])
					: "{Nobody argues. The mountain has already made its case, and the men who were loudest in the village square are the quietest on the way down.%SPEECH_ON%She keeps her coin. We keep our people. That is a trade I can put my name to.%SPEECH_OFF%}";

				this.List = carrying
					? [{ id = 1, icon = "ui/icons/special.png", text = c.savedCount() + " of 4 coming down with you" }]
					: [];

				this.Options = [];

				if (carrying)
				{
					this.Options.push({
						Text = "{Take them down to their mother.}",
						function getResult()
						{
							this.Contract.setState("Return");
							return 0;
						}
					});
				}
				else
				{

					this.Options.push({
						Text = "{Go down.}",
						function getResult()
						{
							this.Contract.m.Aborted = 1;
							this.World.Contracts.finishActiveContract(true);
							return 0;
						}
					});
				}

				this.Options.push({
					Text = "{No. We came up here for a reason.}",
					function getResult() { return this.Contract.hubScreen(); }
				});
			}

		});

		this.m.Screens.push({
			ID = "Report",
			Title = "",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local n = c.savedCount();
				local dead = c.m.Fight2 == 1;
				local lydia = (c.m.Cages & 1) != 0;

				this.Title = dead ? "The Scourge Ended" : "What We Could Carry";

				local first = dead
					? "The tent in the square is still a tent. %SKVNAME%Eliana%SKVNAME_OFF% comes out of it before anybody can send for her, because the noise the village makes when the company walks in is not a noise it has made in a long time.%SPEECH_ON%Say it plainly.%SPEECH_OFF%Somebody says it plainly. She puts a hand flat on the trestle and leaves it there a while."
					: "The tent in the square is still a tent, and %SKVNAME%Eliana%SKVNAME_OFF% is in it, and she knows before anybody speaks - because a company that has killed a dragon does not come down a mountain walking like that.%SPEECH_ON%It is alive.%SPEECH_OFF%Nobody contradicts her. She takes that the way a smith takes a burn: all at once, and without any noise about it.";

				local second;
				if (n == 4)
				{
					second = "And then the four of them come up the road behind you, slow, in the wrong order, and after that there is nothing useful for anybody to say for some time. She gets to Lydia last, and only because the children reach her first.";
				}
				else if (n > 0 && lydia)
				{
					second = "Lydia comes up the road behind you with " + (n == 2 ? "one of the children" : "two of the children") + ", and the two women hold on to each other in the middle of the square like people who have both already done their grieving in private. Neither of them asks the question. Both of them look, once, at the road behind the company, and at how it stays empty.";
				}
				else if (n > 0)
				{
					second = (n == 1 ? "One of the children comes" : n == 2 ? "Two of the children come" : "Three of the children come")
						+ " up the road behind you and " + (n == 1 ? "goes" : "go") + " straight to her, and she gets down on the stones to take " + (n == 1 ? "the child" : "them") + ". It is a long moment before she looks up, past them, at the road, and at how much of it is empty.";
				}
				else
				{
					second = "The road behind the company stays empty. She looks at it for a while anyway, the way you check a sum you already know the answer to.%SPEECH_ON%None.%SPEECH_OFF%%SPEECH_ON%We could not reach them.%SPEECH_OFF%She nods once, and does not ask any of the questions she is entitled to ask.";
				}

				local third;
				if (dead && n == 4)
					third = "%SPEECH_ON%I was a smith before I was a mayor. I know what it costs to make a thing, and I know what it costs to unmake one. Take the whole of it, and take the ram carts too - we will not be needing them on the third day any more.%SPEECH_OFF%";
				else if (dead && n > 0)
					third = "%SPEECH_ON%You did what you could get done. I have been the one who could not get it done, so I am not going to stand here and audit you for it.%SPEECH_OFF%She counts out the full fee anyway, and does not look at anybody while she does it.";
				else if (dead)
					third = "%SPEECH_ON%The thing is dead. That is what I hired, and that is what I will pay for.%SPEECH_OFF%She counts out the full fee. It takes a while, and she gets it right, and nobody in the square finds anything to say about the price of it.";
				else
					third = "%SPEECH_ON%Half, then. Half is what half a job is worth and I will not insult either of us by pretending otherwise.%SPEECH_OFF%She counts it out.%SPEECH_ON%It is still up there. It will want its sheep on the third day, and I have no sheep and no wife-and-children left to take, and I do not know yet what it will ask for instead.%SPEECH_OFF%";

				local fourth = c.m.Shrine == 1
					? "Somebody mentions the dwarf shrine halfway up, and the hammer cut into the chest lid. She writes it down on the back of a tally sheet.%SPEECH_ON%Torag. There will be a temple somewhere that wants to know its shrine is still standing, and I will find it a messenger. That much I can do from a tent.%SPEECH_OFF%"
					: null;

				this.Text = "[img]gfx/ui/events/skv_andoran.png[/img]"
					+ c.paras([first, second, third, fourth]);

				local rows = [{ id = 1, icon = "ui/icons/special.png",
					text = n + " of 4 brought down off the mountain" }];
				if (!dead)
					rows.push({ id = 2, icon = "ui/icons/regular_damage.png", text = "Zikritrax is still in the caves" });
				rows.push({ id = 3, icon = "ui/icons/asset_money.png",
					text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.endingPay()) + " Crowns" });
				this.List = rows;

				this.Options = [
					{
						Text = "{Take the coin.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Reported == 0)
							{
								c.m.Reported = 1;
								c.m.Outcome = c.endingTier();
								c.m.Concluded = 1;

								::World.Assets.addMoney(c.endingPay());
								::World.Assets.addBusinessReputation(c.familyRenown());

								local f = ::World.FactionManager.getFaction(c.getFaction());
								if (f != null)
								{
									f.addPlayerRelation(c.familyRelation(),
										c.savedCount() > 0
											? "brought some of the mayor's family down off Mount Zoldos"
											: "left the mayor's family on Mount Zoldos");
								}

								::Skv.dbg("Skv.Zoldos: ENDING saved=" + c.savedCount() + " wyrmDead=" + (c.m.Fight2 == 1)
									+ " pay=" + c.endingPay() + " renown=" + c.familyRenown()
									+ " relation=" + c.familyRelation() + " tier=" + c.m.Outcome);
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
		::Skv.Once.release("Zoldos");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Zoldos");
			if (!::MSU.isNull(this.m.Destination))
			{
				this.m.Destination.getSprite("selection").Visible = false;
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
		_out.writeU8(this.m.Rockslide);
		_out.writeU8(this.m.Shrine);
		_out.writeU8(this.m.Cages);
		_out.writeU8(this.m.CagesTried);
		_out.writeU8(this.m.Fight1);
		_out.writeU8(this.m.Fight2);
		_out.writeU8(this.m.Outcome);
		_out.writeU8(this.m.Reported);
		_out.writeU8(this.m.Aborted);
		_out.writeU8(this.m.Concluded);

		_out.writeU8(this.m.Hoard);
		_out.writeU16(this.m.Res16);
		_out.writeU32(this.m.HoardCoin);
		_out.writeString(this.m.ResStr);

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
		this.m.Rockslide = _in.readU8();
		this.m.Shrine = _in.readU8();
		this.m.Cages = _in.readU8();
		this.m.CagesTried = _in.readU8();
		this.m.Fight1 = _in.readU8();
		this.m.Fight2 = _in.readU8();
		this.m.Outcome = _in.readU8();
		this.m.Reported = _in.readU8();
		this.m.Aborted = _in.readU8();
		this.m.Concluded = _in.readU8();

		this.m.Hoard = _in.readU8();
		this.m.Res16 = _in.readU16();
		this.m.HoardCoin = _in.readU32();
		this.m.ResStr = _in.readString();

		this.contract.onDeserialize(_in);
	}

});
