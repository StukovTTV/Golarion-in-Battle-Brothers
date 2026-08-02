this.skv_threshold_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Act         = 1,
		Leg         = "",

		KnowsRune   = false,
		Advantage   = 0,
		HasBracelet = false,
		HasCharms   = false,

		GiftDone    = false,

		Beetles     = 0,
		FoundMask   = 0,
		FoundNotes  = 0,
		Footprints  = false,

		ChaseStep   = 0,
		ChaseWins   = 0,
		ChasePick   = 0,
		DoorGate    = 0,
		DoorTries   = 0,
		DoorHint    = 0,
		RuneLesson  = 0,

		Gusa        = 0,
		Kobolds     = 0,
		Swim        = 0,
		Jubo        = 0,
		Approach    = 0,
		GrottoPick  = 0,
		Watched     = false,
		NgajaDead   = false,
		OtFound     = false,
		Students    = 0,
		Flipped     = false,

		Arrived     = false,

		ClockDay    = 0,
		HoursSpent  = 0.0,
		HoursLimit  = 0,
		RunesDone   = 0,
		RunesSearched = 0,
		RuneAt      = 0,
		Outcome     = 0,
		Reported    = false,

		Aborted     = false,

		Concluded   = false,

		DoorKey     = 0,

		Act2Reads   = 0,
		Res32       = 0,
		ResStr      = "",

		ActorName   = "",

		DoorSeats   = 4,

		PrevX       = 0.0,
		PrevY       = 0.0,
		HavePrev    = false,

		NgajaInitPct = 0,
		NgajaFatPct  = 0,
		ResultRows  = null,
		ResultText  = "",
		ResultNext  = "",
		ResultTitle = "Threshold of Knowledge",

		Rung = {
			Caught  = 0x01,
			Gusa    = 0x02,
			Jubo    = 0x04,
			Ground  = 0x08,
			Water   = 0x10,
			Watch   = 0x20
		},

	},

	function hasRung( _bit )
	{
		return (this.m.Advantage & _bit) != 0;
	}

	function addRung( _bit )
	{
		if (this.hasRung(_bit))
		{
			return;
		}
		this.m.Advantage = this.m.Advantage | _bit;
		::Skv.dbg("Skv.Threshold: rung " + _bit + " earned, ladder = " + this.m.Advantage
			+ " (" + this.rungCount() + " of 6)");
	}

	function rungCount()
	{
		local n = 0;
		foreach (bit in this.m.Rung)
		{
			if (this.hasRung(bit))
			{
				n = n + 1;
			}
		}
		return n;
	}

	function runeName( _i )
	{
		if (_i == 1) return "the map room";
		if (_i == 2) return "the stair head";
		if (_i == 3) return "the reading gallery";
		return "the cistern room";
	}

	function runeBit( _i )
	{
		return 1 << (_i - 1);
	}

	function runesDone()
	{
		local n = 0;
		for ( local i = 1; i <= 4; i = i + 1 )
		{
			if ((this.m.RunesDone & this.runeBit(i)) != 0) n = n + 1;
		}
		return n;
	}

	function runeCost()
	{
		return this.m.KnowsRune ? 2.0 : 4.0;
	}

	function hoursLeft()
	{
		local left = this.m.HoursLimit - this.m.HoursSpent;
		return left < 0 ? 0.0 : left;
	}

	function spend( _h )
	{
		this.m.HoursSpent = this.m.HoursSpent + _h;
		return this.m.HoursSpent >= this.m.HoursLimit;
	}

	function resolveArchive()
	{
		local done = this.runesDone();
		local inTime = this.m.HoursSpent < this.m.HoursLimit;

		if (done >= 4 && inTime)      this.m.Outcome = 1;
		else if (done >= 2)           this.m.Outcome = 2;
		else                          this.m.Outcome = 3;

		::Skv.dbg("Skv.Threshold: archive resolved - runes=" + done + "/4 hours="
			+ this.m.HoursSpent + "/" + this.m.HoursLimit + " inTime=" + inTime
			+ " -> outcome=" + this.m.Outcome);
		return this.m.Outcome;
	}

	function finalPay()
	{
		if (this.m.Outcome == 1) return this.m.Payment.getOnCompletion();
		if (this.m.Outcome == 2) return (this.m.Payment.getOnCompletion() * 0.5).tointeger();
		return 0;
	}

	function archiveScreen()
	{
		if (this.m.Outcome != 0)                     return "Report";

		if ((this.m.Act2Reads & 0x04) == 0 && this.runesDone() >= 2) return "Hazard";
		if (this.m.RuneAt != 0)                      return "Rune";
		return "Archive";
	}

	function clockRows()
	{
		local rows = [];
		local left = this.hoursLeft();
		rows.push({
			id = 20,
			icon = "ui/icons/days_wounded.png",
			text = left <= 0
				? "[color=" + this.Const.UI.Color.NegativeEventValue + "]The water is already coming[/color]"
				: (left <= 4
					? "[color=" + this.Const.UI.Color.NegativeEventValue + "]About " + left.tointeger() + " hours before the last mark closes[/color]"
					: "About " + left.tointeger() + " hours before the last mark closes")
		});
		rows.push({
			id = 21,
			icon = "ui/icons/special.png",
			text = this.runesDone() + " of the four marks are out"
		});
		return rows;
	}

	function canalScreen()
	{
		if (this.m.Leg == "")                          return "Canal";

		if (this.m.Gusa == 0 || this.m.Gusa == 3)      return "Gusa";
		if (this.m.Kobolds != 1)                       return "Collapse";
		if (this.m.Swim == 0)                          return "Swim";
		if (this.m.Jubo == 0)                          return "Jubo";
		if (!this.m.OtFound)                           return "Approach";

		if (this.m.Students != 0 && !this.m.Flipped)   return "Reveal";
		return "Prisoners";
	}

	function abortIsFailure()
	{
		if (this.m.Act >= 3)
		{
			return true;
		}
		if (this.m.Act == 2 && this.m.Swim != 0)
		{
			return true;
		}
		return false;
	}

	function rungs()
	{
		return this.rungCount();
	}

	function koboldBudget()
	{
		local b = 70.0 * this.getScaledDifficultyMult() * this.getDifficultyMult();

		if ((this.m.Act2Reads & 0x02) != 0)
		{
			b = b * 0.85;
		}

		if (this.m.Kobolds == 3)
		{
			b = b * 0.70;
		}

		return b;
	}

	function escortBudget()
	{
		local b = 55.0 * this.getScaledDifficultyMult() * this.getDifficultyMult();

		if (this.hasRung(this.m.Rung.Ground))
		{
			b = b * 0.85;
		}

		return b;
	}

	function canalCombat( _id, _surprised )
	{
		local p = ::Const.Tactical.CombatInfo.getClone();
		p.CombatID = _id;
		p.TerrainTemplate = "tactical.skv_ruin_floor";
		p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
		p.EnemyDeploymentType = _surprised
			? ::Const.Tactical.DeploymentType.Circle
			: ::Const.Tactical.DeploymentType.Line;
		p.IsWithoutAmbience = true;

		p.Entities = [];
		return p;
	}

	function moodShift( _amount, _reason, _ids )
	{
		local rows = [];
		foreach (bro in this.World.getPlayerRoster().getAll())
		{
			if (bro.isInReserves())
			{
				continue;
			}
			local id = bro.getBackground().getID();
			local hit = false;
			foreach (x in _ids) if (x == id) { hit = true; break; }
			if (!hit)
			{
				continue;
			}
			rows.push(::Legends.EventList.changeMood(bro, _amount, _reason));
		}
		return rows;
	}

	function gentleBackgrounds()
	{
		return [ "background.monk", "background.legend_pilgrim", "background.legend_battle_sister",
			"background.farmhand", "background.milkmaid", "background.shepherd", "background.gravedigger",
			"background.beggar", "background.juggler", "background.legend_philosopher",
			"background.historian", "background.legend_scribe" ];
	}

	function hardBackgrounds()
	{
		return [ "background.raider", "background.killer_on_the_run", "background.assassin",
			"background.assassin_southern", "background.brawler", "background.butcher",
			"background.executioner", "background.houndmaster", "background.barbarian",
			"background.gladiator" ];
	}

	function grottoPlan()
	{
		local bits = [];
		if (this.hasRung(this.m.Rung.Caught))
		{
			bits.push("they do not know we are coming, because the girl told us the way in and she is not down here to tell them otherwise");
		}
		if (this.hasRung(this.m.Rung.Gusa))
		{
			bits.push("there are two prisoners and not one, and the little ones in the side tunnels are hers");
		}
		if (this.hasRung(this.m.Rung.Jubo))
		{
			bits.push("the beast on the beach is asleep and stays asleep - I have seen what wakes it and it is not us");
		}
		if (this.hasRung(this.m.Rung.Ground))
		{
			bits.push("I have been down and looked, and I can put us on the dry shelf with the water in front of us");
		}
		if (this.hasRung(this.m.Rung.Water))
		{
			bits.push("she is watching the mouth of the pool and not the ledge, so the first thing she does will not be to us");
		}
		if (this.hasRung(this.m.Rung.Watch))
		{
			bits.push("and she is tired - she has been at him all night and she has not slept, and it shows in her hands");
		}

		if (bits.len() == 0)
		{
			return "I do not know what is down there and neither do you.";
		}

		local s = "";
		for ( local i = 0; i < bits.len(); i = i + 1 )
		{
			if (i == 0) s = bits[i];
			else if (i == bits.len() - 1) s = s + ", and " + bits[i];
			else s = s + ", " + bits[i];
		}
		return s.slice(0, 1).toupper() + s.slice(1) + ".";
	}

	function twoVoices()
	{
		return this.World.getPlayerRoster().getAll().len() >= 2;
	}

	function hubScreen()
	{
		if (this.m.Act >= 3)
		{
			return this.archiveScreen();
		}
		if (this.m.Act == 2)
		{
			return this.canalScreen();
		}
		if (!this.m.GiftDone)
		{
			return "Gift";
		}
		return "House";
	}

	function row( _ok, _text )
	{
		return {
			id = 12,
			icon = "ui/icons/special.png",
			text = "[color=" + (_ok ? this.Const.UI.Color.PositiveEventValue : this.Const.UI.Color.NegativeEventValue) + "]"
				+ _text + "[/color]"
		};
	}

	function rowsWith( _ok, _text, _rows )
	{
		local out = [ this.row(_ok, _text) ];
		if (_rows != null) foreach (r in _rows) out.push(r);
		return out;
	}

	function say( _title, _text, _rows = null, _next = "" )
	{
		this.m.ResultTitle = _title;
		this.m.ResultText  = _text;
		this.m.ResultRows  = _rows == null ? [] : _rows;
		this.m.ResultNext  = _next;
	}

	function hurtSome( _n, _min, _max, _injuryScript = "", _injuryLabel = "", _injuryID = "" )
	{
		local rows = [];
		local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
		if (pool.len() == 0)
		{
			return rows;
		}

		local n = this.Math.min(_n, pool.len());
		local taken = {};
		for ( local i = 0; i < n; i = i + 1 )
		{
			local bro = null;
			for ( local tries = 0; tries < 12; tries = tries + 1 )
			{
				local c = pool[this.Math.rand(0, pool.len() - 1)];
				if (!(c.getID() in taken)) { bro = c; break; }
			}
			if (bro == null) break;
			taken[bro.getID()] <- true;

			if (i == 0 && _injuryScript != "" && !(_injuryID != "" && bro.getSkills().hasSkill(_injuryID)))
			{
				local inj = ::new(_injuryScript);
				bro.getSkills().add(inj);
				rows.push({
					id = 10,
					icon = inj.getIcon(),
					text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + bro.getName() + " " + _injuryLabel + "[/color]"
				});
			}

			local before = bro.getHitpoints();
			bro.setHitpoints(this.Math.max(1, before - this.Math.rand(_min, _max)));
			local lost = before - bro.getHitpoints();
			if (lost > 0)
			{
				rows.push({
					id = 11,
					icon = "ui/icons/health.png",
					text = bro.getName() + " loses [color=" + this.Const.UI.Color.NegativeEventValue + "]" + lost + "[/color] health"
				});
			}
		}
		return rows;
	}

	function rollDoorKey()
	{
		if ((this.m.DoorKey & 0x80) != 0)
		{
			return;
		}
		this.m.DoorKey = 0x80 | this.Math.rand(0, 63);
		::Skv.dbg("Skv.Threshold: door key rolled = " + this.m.DoorKey);
	}

	function doorRot( _gate )
	{
		this.rollDoorKey();
		if (_gate == 1) return this.m.DoorKey & 0x03;
		if (_gate == 2) return (this.m.DoorKey >> 2) & 0x03;
		if (_gate == 3) return ((this.m.DoorKey & 0x03) + 1) & 0x03;
		return (this.m.DoorKey >> 4) & 0x03;
	}

	function doorTexts( _gate, _texts )
	{
		local n = _texts.len();
		local rot = this.doorRot(_gate) % n;
		local out = [];
		for ( local i = 0; i < n; i = i + 1 )
		{
			out.push(_texts[(i - rot + n) % n]);
		}
		return out;
	}

	function doorPress( _i, _n = 4 )
	{
		local gate = this.m.DoorGate + 1;
		if (_i == this.doorRot(gate) % _n)
		{
			this.m.DoorGate = this.m.DoorGate + 1;
			this.m.DoorHint = 0;
			if (this.m.DoorGate >= 4)
			{

				local doorRows = [ this.row(true, "The door is open, and it was opened by the company") ];
				doorRows.push(this.row(true, "Behind it: the storeroom, and something drawn badly on a beam"));
				foreach (r in ::Skv.XP.partyEach(20)) doorRows.push(r);
				this.say("The Reshelving Door",
					"[img]gfx/ui/events/event_74.png[/img]{The ring turns a last quarter under the flat of a hand and stops with a sound like a lock giving up an argument. The shelves walk apart from each other - not fast, and not quietly - and behind them there is a doorway with water coming out of it over the sill.\n\nNobody in the reading room says anything for a moment. Then one of the students, very quietly, says that nobody has had that open since before she came here.}",
					doorRows, "");
				::Skv.dbg("Skv.Threshold: door solved by the company after " + this.m.DoorTries + " wrong press(es)");
				return "Result";
			}
			this.say("The Reshelving Door",
				"[img]gfx/ui/events/event_74.png[/img]{Something behind the wall lets go and takes up again one notch further round. The ring has moved. It is waiting for the next thing.}",
				[ this.row(true, "Right. " + this.m.DoorGate + " of the four given, and " + (4 - this.m.DoorTries) + " wrong presses still in hand") ],
				"Door");
			return "Result";
		}

		this.m.DoorTries = this.m.DoorTries + 1;
		if (this.m.DoorTries >= 4)
		{
			this.m.DoorGate = 4;

			this.m.RuneLesson = 1;
			this.say("The Reshelving Door",
				"[img]gfx/ui/events/event_74.png[/img]{%SKVNAME%Nhyria%SKVNAME_OFF% has been standing at the end of the shelves for some while, holding a lamp and saying nothing, and at the fourth wrong press she comes down the aisle and puts her hand flat on three places in an order that looks like no order at all. The shelves walk apart.%SPEECH_ON%It is a door in a school. It was never meant to keep anybody out. It was meant to make you think about the man who built it.%SPEECH_OFF%Behind it is a flooded storeroom, and something half-drawn on the beam over the water that she looks at once and then puts out with the flat of her hand, hard, before anyone can get close enough to see how it was made.%SPEECH_ON%Not that. Not today.%SPEECH_OFF%}",
				[ this.row(false, "Four wrong presses - she opened it, and she put the rune out herself"),
				  this.row(false, "The practice rune is gone: one of the two ways to learn what a rune IS, lost") ],
				"");
			::Skv.dbg("Skv.Threshold: door opened by Nhyria - RuneLesson locked at 1, no second KnowsRune route");
			return "Result";
		}

		this.say("The Reshelving Door",
			"[img]gfx/ui/events/event_74.png[/img]{The whole wall shrugs. Two shelves change places with each other, a third turns its back, and the ring rolls itself round to where it started. Somewhere behind the plaster a counterweight settles.\n\nWhatever that was, it was not the time.}",
			[ this.row(false, "Wrong. " + (4 - this.m.DoorTries) + " more wrong presses and she opens it herself - and puts the rune out with it") ],
			"Door");
		return "Result";
	}

	function chaseResolve( _ok, _win, _lose, _rows )
	{
		if (_ok)
		{
			this.m.ChaseWins = this.m.ChaseWins + 1;
		}
		this.m.ChaseStep = this.m.ChaseStep + 1;

		local rows = _rows == null ? [] : _rows;

		rows.insert(0, this.row(_ok, (_ok ? "That street went your way - " : "That street did not - ")
			+ this.m.ChaseWins + " won of " + this.m.ChaseStep + " run, and three of the five takes her"));
		local body = "[img]gfx/ui/events/event_84.png[/img]{" + (_ok ? _win : _lose);

		if (this.m.ChaseWins >= 3)
		{
			return this.chaseCaught(body, rows);
		}
		if (this.m.ChaseWins + (5 - this.m.ChaseStep) < 3)
		{
			return this.chaseLost(body, rows);
		}

		rows.push(this.row(true, (5 - this.m.ChaseStep) + " streets left, and "
			+ (3 - this.m.ChaseWins) + " more needed"));
		this.say("The Chase", body + "}", rows, "Chase");
		return "Result";
	}

	function chaseAbandon()
	{
		this.m.ChaseStep = 6;
		return this.chaseLost("[img]gfx/ui/events/event_84.png[/img]{The company stops running. Somebody puts his hands on his knees.",
			[this.row(false, "Broken off at " + this.m.ChaseWins + " of five - a choice, not a bad roll")]);
	}

	function chaseCaught( _body, _rows )
	{
		this.m.ChaseStep = 6;
		local rows = _rows == null ? [] : _rows;
		this.addRung(this.m.Rung.Caught);
		rows.push(this.row(true, "Caught her - " + this.m.ChaseWins + " of five, and three was the bar"));
		rows.push(this.row(true, "She has a name for the thing in the canal, and a way down to it"));
		rows.push(this.row(true, "The company will not be walking into that grotto blind"));
		foreach (r in ::Skv.XP.partyEach(20)) rows.push(r);
		this.say("The Chase", _body + "\n\nShe goes down in a doorway with somebody's forearm across her chest, and she is perhaps sixteen, and she talks before anybody has asked her anything. Her name is %SKVNAME%Mnroba%SKVNAME_OFF%. It was not supposed to hurt him. There is a woman in the water under the old cistern - not a woman, she says, and then says it again - and she has him in a grotto off the third branch of the canal, and there is another student down there who still thinks all of this is going to work.\n\nShe tells you where the way down is, and which turning to take at the collapse, and she goes on talking long after she has run out of anything useful, the way people do.}",
			rows, "");
		return "Result";
	}

	function chaseLost( _body, _rows )
	{
		this.m.ChaseStep = 6;
		local rows = _rows == null ? [] : _rows;
		rows.push(this.row(false, "Lost her - " + this.m.ChaseWins + " of five, and three was the bar"));
		rows.push(this.row(false, "No name, and nobody to tell you what is down there"));
		this.say("The Chase", _body + "\n\nThe alley gives onto a market and the market gives onto four more streets, and by the time the company is through the awnings there is nothing ahead but people carrying things on their heads. Whoever she was, she is somebody's daughter in a crowd now.\n\nWhat you have is what you took out of that room.}",
			rows, "");
		return "Result";
	}

	function doorKnown()
	{
		return this.m.FoundMask == 2 || this.m.FoundNotes == 2 || this.hasRung(this.m.Rung.Caught);
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_threshold";
		this.m.Name = "Threshold of Knowledge";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 12.0;

		this.m.Category = this.Const.Contracts.Categories.Hunt;

		this.m.DescriptionTemplates = [
			"A scholar of the southern school has been taken out of his own office in the night, through a smashed skylight, and dragged down into the canals under the city. The house that employs him will not send its own students after him and cannot be seen asking the city for help.",
			"There is a chapter house of a foreign school in the city, and something came through its roof and took one of its teachers. The juniors left behind are frightened, badly out of their depth, and quietly hiring."
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{

		this.m.Payment.Pool = 300 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();

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
					"Find the instructor taken from the school in " + this.Contract.m.Home.getName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}

		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
				{
					this.Contract.m.Home.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				local c = this.Contract;
				local home = c.m.Home;
				if (home == null || home.isNull())
				{
					return;
				}

				local v = this.Flags.get("V12");
				if (v != null && v != false && v != "")
				{
					this.Flags.set("V12", "");
					if (v == "Skv12Kobolds")
					{
						c.m.Kobolds = 1;
						c.say("The Fallen Tunnel",
							"[img]gfx/ui/events/event_160.png[/img]{They are small and there were a great many of them and they knew the ground, and none of that is worth anything once a shield wall is through the gap and standing on dry stone.\n\nThe side tunnels go quiet one after another. Somewhere further in, something that is not a kobold has heard the whole thing and has not come to see.}",
							::Skv.XP.partyEach(30), "");
					}
					else if (v == "Skv12Ngaja")
					{
						c.m.NgajaDead = true;
						c.m.OtFound = true;
						c.say("The Grotto",
							"[img]gfx/ui/events/event_106.png[/img]{She goes down in her own pool with her hands still out of the water, and the green light goes out of it about a breath afterwards, and the room is suddenly only a flooded cellar with three frightened people in it.\n\nNobody in the company says anything for a moment. Then somebody remembers the man tied to the ring.}",
							::Skv.XP.partyEach(40), "Prisoners");
					}
					this.TempFlags.set("AtHouse", true);
					c.setScreen("Result");
					this.World.Contracts.showActiveContract();
					return;
				}

				local d = this.Flags.get("D12");
				if (d != null && d != false && d != "")
				{
					this.Flags.set("D12", "");

					if (d == "Skv12Kobolds")
					{
						c.m.Kobolds = 3;
						c.say("The Fallen Tunnel",
							"[img]gfx/ui/events/event_160.png[/img]{The company comes back out over its own rubble and does not stop until there is daylight somewhere above it.\n\nThey are still down there. So are the ones the company took with it, and that is a number the warren cannot make up.}",
							[ c.row(false, "Driven back out of the tunnel - but the dead stay dead, and there are fewer of them now") ],
							"");
					}
					else if (d == "Skv12Ngaja")
					{

						c.m.GrottoPick = 3;
						c.say("The Grotto",
							"[img]gfx/ui/events/event_106.png[/img]{Whatever the plan was, it ends with the company backing along the shelf in water up to the knee with something behind it that does not need to hurry.\n\nShe does not follow past the turn. She goes back to the pool, and to the man on the ring, and there is no version of this now where anybody creeps up on anybody.}",
							[ c.row(false, "Driven off the shelf - the quiet way is the only way left in") ],
							"");
					}
					this.TempFlags.set("AtHouse", true);
					c.setScreen("Result");
					this.World.Contracts.showActiveContract();
					return;
				}

				if (::Skv.Town.consume(home.getID()))
				{
					this.TempFlags.set("AtHouse", false);
					::Skv.dbg("Skv.Threshold: latch re-armed by a settlement visit - stepping back out re-opens the chain.");
				}

				local px = 0.0;
				local py = 0.0;
				local havePos = false;
				try
				{
					local v = this.World.State.getPlayer().getPos();
					px = v.X;
					py = v.Y;
					havePos = true;
				}
				catch (e)
				{
					::Skv.dbg("Skv.Threshold: player getPos() unusable, the standing-still test is off: " + e);
				}

				local movedSq = 0.0;
				local hadPrev = c.m.HavePrev;
				if (havePos && hadPrev)
				{
					movedSq = (px - c.m.PrevX) * (px - c.m.PrevX) + (py - c.m.PrevY) * (py - c.m.PrevY);
				}
				if (havePos)
				{
					c.m.PrevX = px;
					c.m.PrevY = py;
					c.m.HavePrev = true;
				}

				if (!c.isPlayerAt(home))
				{
					if (this.TempFlags.get("AtHouse"))
					{
						this.TempFlags.set("AtHouse", false);
						::Skv.dbg("Skv.Threshold: latch re-armed by leaving the city (>150 units).");
					}
					return;
				}

				if (this.TempFlags.get("AtHouse"))
				{
					return;
				}

				if (havePos && (!hadPrev || movedSq > 1.0))
				{
					return;
				}

				this.TempFlags.set("AtHouse", true);
				c.setScreen(c.hubScreen());
				this.World.Contracts.showActiveContract();
			}

			function onCombatKobolds()
			{
				local c = this.Contract;
				local surprised = !c.hasRung(c.m.Rung.Gusa);
				local p = c.canalCombat("Skv12Kobolds", surprised);
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				local budget = c.koboldBudget();

				local list = budget >= 80 ? ::Const.World.Spawn.GolarionKoboldsCasters : ::Const.World.Spawn.GolarionKobolds;

				::Skv.Spawn.fill(p.Entities, list, budget, fac, "Threshold/Collapse",
					::Const.World.Spawn.GolarionKobolds);

				::Skv.dbg("Skv.Threshold: collapse fight budget=" + budget + " surprised=" + surprised
					+ " retry=" + (c.m.Kobolds == 3) + " read=" + ((c.m.Act2Reads & 0x02) != 0));

				this.Flags.set("F12", "Skv12Kobolds");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatNgaja()
			{
				local c = this.Contract;

				local surprised = !c.hasRung(c.m.Rung.Caught) || c.m.Jubo == 2;
				local p = c.canalCombat("Skv12Ngaja", surprised);
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();

				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionKoboldsCasters, c.escortBudget(),
					fac, "Threshold/Grotto", ::Const.World.Spawn.GolarionKobolds);

				local rungs = c.rungs();
				c.m.NgajaInitPct = 5 * rungs;
				c.m.NgajaFatPct = 5 * rungs;
				if (c.hasRung(c.m.Rung.Water))
				{
					c.m.NgajaInitPct = c.m.NgajaInitPct + 12;
				}

				if (c.m.NgajaInitPct > 45) c.m.NgajaInitPct = 45;
				if (c.m.NgajaFatPct > 45) c.m.NgajaFatPct = 45;

				p.BeforeDeploymentCallback = function ()
				{
					try
					{
						local ct = this.World.Contracts.getActiveContract();
						if (ct == null)
						{
							return;
						}

						local tile = null;
						for ( local tries = 0; tries < 60 && tile == null; tries = tries + 1 )
						{
							local cand = this.Tactical.getTileSquare(this.Math.rand(10, 28), this.Math.rand(6, 26));
							if (cand.IsEmpty)
							{
								tile = cand;
							}
						}
						if (tile == null)
						{
							::logError("Skv.Threshold: no empty tile for Ngaja -- the grotto fight has no hexe in it.");
							return;
						}

						local boss = this.Tactical.spawnEntity("scripts/entity/tactical/enemies/hexe", tile.Coords);
						boss.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID());
						boss.setName("Ngaja");

						local b = boss.getBaseProperties();
						local init0 = b.Initiative;
						local fat0 = b.FatigueRecoveryRate;

						local initCut = this.Math.floor(init0 * ct.m.NgajaInitPct / 100.0);
						local fatCut = this.Math.floor(fat0 * ct.m.NgajaFatPct / 100.0);
						b.Initiative = init0 - initCut;
						b.FatigueRecoveryRate = fat0 - fatCut;
						boss.getSkills().update();

						::Skv.dbg("Skv.Threshold: Ngaja in. Initiative " + init0 + " -> " + b.Initiative
							+ " (-" + ct.m.NgajaInitPct + "%), FatigueRecovery " + fat0 + " -> "
							+ b.FatigueRecoveryRate + " (-" + ct.m.NgajaFatPct + "%)");
					}
					catch (e)
					{
						::logError("Skv.Threshold: Ngaja could not be spawned (the escort still fights): " + e);
					}
				};

				::Skv.dbg("Skv.Threshold: grotto fight escort=" + c.escortBudget() + " rungs=" + rungs
					+ " jubo=" + c.m.Jubo + " ground=" + c.hasRung(c.m.Rung.Ground));

				this.Flags.set("F12", "Skv12Ngaja");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string")
				{
					return;
				}
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv12")
				{
					return;
				}
				this.Flags.set("V12", _combatID);
				::Skv.dbg("Skv.Threshold: victory id=" + _combatID);
			}

			function onCombatFinished()
			{
				this.contract_state.onCombatFinished();

				local f = this.Flags.get("F12");
				if (f == null || f == false || f == "")
				{
					return;
				}
				this.Flags.set("F12", "");

				if (this.Flags.get("V12") == f)
				{
					return;
				}
				this.Flags.set("D12", f);
				::Skv.dbg("Skv.Threshold: DEFEAT id=" + f);
			}

		});
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "Threshold of Knowledge",
			Text = "[img]gfx/ui/events/event_163.png[/img]{You are brought in through a side door of a house that does not advertise itself, past a courtyard of very young people who stop talking when they see you. The woman waiting inside gives her name as %SKVNAME%Nhyria%SKVNAME_OFF% and does not offer a title.%SPEECH_ON%We keep a house here. A small one - a reading room, a store of books, four instructors and rather too many students. We are guests in %townname% and we are tolerated, and that is the whole of our standing.%SPEECH_OFF%She sets a lamp down on a table that has water standing on it.%SPEECH_ON%Something came through the skylight of that room two nights ago. It took %SKVNAME%Ot Vaunder%SKVNAME_OFF% out of it and went down into the canal under this house with him, and it did not come alone - one of my own students helped it in. I cannot send children after them. I cannot go to the palace, because whatever this house asks of this city we are made to pay for twice over. So I am asking you. Find him. Bring him up.%SPEECH_OFF%}",
			Image = "",
			List = [],

			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],

			function start()
			{
				this.Options = [
					{
						Text = "{We will go down and find your man.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{%SKVLOC%The Magaambya%SKVLOC_OFF%. Has anyone here heard of it?}",
						function getResult() { return "Lore"; }
					});
				}

				this.Options.push({
					Text = "{This is not for us.}",
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
			Title = "The Magaambya",
			Text = "[img]gfx/ui/events/event_15.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% has heard of it, and is not impressed. %SPEECH_ON%A school. Oldest one there is, they say - some fellow called Jatembe walked out of the jungle a very long time ago with ten students behind him and started teaching, and they have not stopped since. They take anybody. That is the part people find hard to believe. No coin, no house, no letters - if you can learn, they will teach you.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% asks what a place like that is doing in a city like this one. %SPEECH_ON%Being careful, I should think. The mother school is a very long way south of here. This is an outpost - a reading room and a few teachers, sitting in a city run by things that do not love scholars. They keep their heads down and they do not ask the palace for anything.%SPEECH_OFF%He thinks about it. %SPEECH_ON%Which is why they are talking to us, and not to a magistrate.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Let us hear the terms again.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
			}

		});

		this.m.Screens.push({
			ID = "Gift",
			Title = "A Bead and a Scale",
			Text = "[img]gfx/ui/events/event_112.png[/img]{Before you go down, %SKVNAME%Nhyria%SKVNAME_OFF% puts a bead of dull green glass into somebody's hand and closes his fingers over it.%SPEECH_ON%I keep the twin of that. If it goes badly - if it goes badly in a way you cannot fight your way out of - then break it, and I will come and get you out, and we will call the matter closed and nobody will be blamed. I would rather have you alive and the job undone.%SPEECH_OFF%In the courtyard on the way out, a girl of about twelve, who has plainly been waiting for you and has plainly been told not to, holds out a scale the length of a thumb. It is wet. It stays wet.%SPEECH_ON%It is for the water. My aunt fishes the delta and she says you put it under your tongue and the water lets you alone a while. Everyone says it is nothing.%SPEECH_OFF%She does not look like somebody who thinks it is nothing.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [];
				this.Options = [
					{
						Text = "{Take the bead. And take the girl's charm, and thank her for it in front of the others.}",
						function getResult()
						{
							this.Contract.m.HasBracelet = true;
							this.Contract.m.HasCharms = true;
							this.Contract.m.GiftDone = true;
							this.Contract.say("A Bead and a Scale",
								"[img]gfx/ui/events/event_112.png[/img]{The scale goes into the company's kit wrapped in a rag, which is more ceremony than it has any right to, and the girl goes back across the courtyard at a dead run to tell somebody.}",
								[ this.Contract.row(true, "The bubbling scale is in the company's kit") ],
								"");
							return "Result";
						}
					},
					{
						Text = "{Take the bead. The bead is business. Leave the child her charm.}",
						function getResult()
						{
							this.Contract.m.HasBracelet = true;
							this.Contract.m.HasCharms = false;
							this.Contract.m.GiftDone = true;
							this.Contract.say("A Bead and a Scale",
								"[img]gfx/ui/events/event_112.png[/img]{She closes her hand round it and says of course, and that it was a stupid thing, and goes back inside without running.}",
								[], "");
							return "Result";
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "House",
			Title = "The Reading Room",
			Text = "[img]gfx/ui/events/event_63.png[/img]{%SKVNAME%Ot Vaunder%SKVNAME_OFF% worked in a corner room with one high window in the roof, and the roof is where they came in: the skylight is gone, frame and all, and there is a fall of glass across the desk that somebody has already tried to sweep and given up on. There is water on the floor to the depth of a finger, all through the room, and it has not dried in two days. Blood has gone into the water and stayed near the door, spreading the way ink does.\n\nThe display case against the far wall has been emptied. The desk has not been touched, which is the strange part.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				if (c.m.Beetles == 0 || c.m.Beetles == 3)
				{
					this.Options.push({
						Text = "{Something is still moving in the wreck of the case.}",
						function getResult() { return "Beetles"; }
					});
				}
				else
				{
					if (c.m.FoundMask == 0)
					{
						this.Options.push({
							Text = "{Go over the floor of the room, corner by corner.}",
							function getResult()
							{
								local r = ::Skv.Check.perception(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
								if (r.ok)
								{
									this.Contract.m.FoundMask = 2;
									this.Contract.say("The Reading Room",
										"[img]gfx/ui/events/event_63.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% goes down on his heels at the skirting behind the door and comes up with a sodden handful of stiffened cloth. It is a mask, or it was: a hare's face, made the way a student makes a thing for a festival, with the ears torn off it and one of the ties still knotted.\n\nThe woman at the end of the corridor takes one look at it and gives you a name without being asked, and then looks unhappy about having given it.}",
										this.Contract.rowsWith(true, "A name out of the wreck - and a reason to look at the back of the reading room",
											::Skv.XP.check(r)),
										"");
								}
								else
								{
									this.Contract.m.FoundMask = 1;
									this.Contract.say("The Reading Room",
										"[img]gfx/ui/events/event_63.png[/img]{The floor is glass and water and two days of everybody's boots. Whatever is down there is under something else by now, and the company has been through it twice.}",
										[ this.Contract.row(false, "Nothing found, and the floor is spent - one of three ways to the back room, gone") ],
										"");
								}
								return "Result";
							}
						});
					}

					if (c.m.FoundNotes == 0)
					{
						this.Options.push({
							Text = "{Go through what is still on the desk.}",
							function getResult()
							{
								local r = ::Skv.Check.wits(this.Contract, ::Skv.Check.scaledBase(this.Contract, 45));
								if (r.ok)
								{
									this.Contract.m.FoundNotes = 2;
									this.Contract.m.KnowsRune = true;
									this.Contract.say("The Reading Room",
										"[img]gfx/ui/events/event_15.png[/img]{Most of it is a lecture on river silt. Under the lecture, in a different and much worse hand, there are four pages that are not about silt at all: a figure drawn and redrawn and drawn again, each time a little more wrong, with the order of the strokes numbered down the margin and the numbers crossed out and renumbered.\n\n%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% cannot read a word of the script and does not need to. Somebody was being taught to make a sign, and was making it badly, and was practising it here - in this house, on this desk - and the last page names a storeroom behind the reading room where they were doing it where nobody would look.}",
										this.Contract.rowsWith(true, "You know what a rune of theirs looks like being built - and where they built it",
											::Skv.XP.check(r)),
										"");
								}
								else
								{
									this.Contract.m.FoundNotes = 1;
									this.Contract.say("The Reading Room",
										"[img]gfx/ui/events/event_15.png[/img]{It is all in a script nobody in the company reads, and a great deal of it, and after an hour of it the only thing anyone is sure of is that the man kept very tidy notes about mud.}",
										[ this.Contract.row(false, "Nothing read out of the desk, and it will not read any better tomorrow"),
										  this.Contract.row(false, "One of the two ways to learn what a rune IS, gone - the other is behind the door") ],
										"");
								}
								return "Result";
							}
						});
					}
				}

				if (!c.m.Footprints)
				{
					this.Options.push({
						Text = "{The water runs out under the door, and it keeps going.}",
						function getResult()
						{
							this.Contract.m.Footprints = true;
							this.Contract.say("The Reading Room",
								"[img]gfx/ui/events/event_63.png[/img]{It goes out of the room, down the corridor, across the courtyard where the students are pretending not to watch, and out through the gate into the street, and it is still just wet enough to follow in the shade.\n\nIt is not one trail. Something was dragged, and somebody walked beside it, and at the gate the somebody stops - stands a while, from the look of the puddle - and then goes off at a different angle entirely.\n\nAnd forty paces up that angle, in the mouth of an alley, a young person in a rabbit's-face mask is standing very still watching your company come out of the gate. Then they are not standing still.}",
								[], "Chase");
							return "Result";
						}
					});
				}
				else if (c.m.ChaseStep < 6)
				{
					this.Options.push({
						Text = "{Back out into the street. She cannot have got far.}",
						function getResult() { return "Chase"; }
					});
				}

				if (c.doorKnown() && c.m.DoorGate < 4)
				{
					this.Options.push({
						Text = "{The back of the reading room, where the shelves do not match the wall.}",
						function getResult() { return "Door"; }
					});
				}

				if (c.m.DoorGate >= 4 && c.m.RuneLesson == 0)
				{
					this.Options.push({
						Text = "{Through the shelves, into the storeroom.}",
						function getResult() { return "Storeroom"; }
					});
				}

				if (c.m.Footprints)
				{
					this.Options.push({
						Text = "{Enough of the house. Down into the canal.}",
						function getResult()
						{
							this.Contract.m.Act = 2;
							::Skv.dbg("Skv.Threshold: act I closed - rungs=" + this.Contract.rungCount()
								+ " KnowsRune=" + this.Contract.m.KnowsRune
								+ " charms=" + this.Contract.m.HasCharms
								+ " mask=" + this.Contract.m.FoundMask + " notes=" + this.Contract.m.FoundNotes
								+ " rune=" + this.Contract.m.RuneLesson);
							this.Contract.say("Beneath the House",
								"[img]gfx/ui/events/event_89.png[/img]{Under the reading room is a storeroom, and under the storeroom is water.}",
								[], "Canal");
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = "{Enough for now.}",
					function getResult() { return 0; }
				});

				if (c.m.HasBracelet)
				{
					this.Options.push({
						Text = "{The bead. We are not doing this.}",
						function getResult() { return "Abort"; }
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Beetles",
			Title = "What Is In The Case",
			Text = "[img]gfx/ui/events/event_63.png[/img]{There are four of them in the wreck of the display case, each about the size of a closed fist, and when the light moves they answer it - a hard white flare off the back plates that leaves everyone in the room blinking at nothing for a count of three. They are not going anywhere. They have arranged themselves across the bottom of the case like men at a table.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				if (c.m.Beetles != 3)
				{
					this.Options.push({
						Text = "{Nothing comes through a roof for a display case. What are they here for?}",
						function getResult()
						{
							local r = ::Skv.Check.perception(this.Contract, ::Skv.Check.scaledBase(this.Contract, 55));
							if (r.ok)
							{
								this.Contract.m.Beetles = 1;
								this.Contract.say("What Is In The Case",
									"[img]gfx/ui/events/event_63.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% works it out from the shelf below: a shallow bowl, tipped over, with the last of something dark and sweet-smelling still in the bottom of it. They were brought in for that. They are sitting in an empty case waiting for somebody to fill it up again.\n\nThe bowl goes back on the floor with what is left in it scraped into the middle, and the four of them come down off the glass one at a time and put their heads in it, and that is the end of the flash beetles.}",
									this.Contract.rowsWith(true, "The beetles are dealt with, and nobody was burned doing it",
										::Skv.XP.check(r)),
									"");
							}
							else
							{
								this.Contract.m.Beetles = 3;
								this.Contract.say("What Is In The Case",
									"[img]gfx/ui/events/event_63.png[/img]{Nobody can make anything of them. They sit in the broken case and flare at every lamp that moves, and the room is no more usable than it was.}",
									[ this.Contract.row(false, "Nothing worked out - and that is the one look you get at them"),
									  this.Contract.row(false, "What is left is driving them out, and that will cost blood") ],
									"");
							}
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = "{Shields up and drive them out the door.}",
					function getResult()
					{
						this.Contract.m.Beetles = 2;
						local rows = this.Contract.hurtSome(2, 6, 14);
						rows.insert(0, this.Contract.row(false, "Driven out the hard way - no Story Award for this one"));
						this.Contract.say("What Is In The Case",
							"[img]gfx/ui/events/event_63.png[/img]{It works, in the sense that they end up outside. It takes rather longer than anybody expects, involves two shields and a chair, and the flare goes off directly in a man's face at arm's length, which turns out to be worse than being bitten.\n\nOne of the students watches the whole thing from the doorway with her hand over her mouth. They were somebody's, and they were being kept.}",
							rows, "");
						return "Result";
					}
				});

				this.Options.push({
					Text = "{Leave them where they are.}",
					function getResult() { return "House"; }
				});
			}

		});

		this.m.Screens.push({
			ID = "Chase",
			Title = "The Chase",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local step = c.m.ChaseStep;
				this.List = [];
				this.Options = [];

				if (step == 0)
				{
					this.Text = "[img]gfx/ui/events/event_84.png[/img]{She goes left out of the alley mouth and she does not go the way a frightened person goes - she goes the way somebody goes who has run this street before, under the awnings where the company is a head too tall, and she is already twenty paces up on you.}";
					this.Options.push({
						Text = "{Never mind following her. Work out where she is going and be there.}",
						function getResult()
						{
							local r = ::Skv.Check.wits(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							return this.Contract.chaseResolve(r.ok,
								"%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% has been in the city two days and has the shape of it: the awnings run to the cistern square and the cistern square only lets out three ways, and two of them are stairs. The company comes out of a side street ahead of her and she has to break right, into the crowd, and lose half of what she had.",
								"The awnings all look the same from underneath. The company takes the turn that looks like the turn and comes out on a wall, and by the time anybody is back on the street she is a shape going away under the cloth.",
								::Skv.XP.check(r));
						}
					});
				}
				else if (step == 1)
				{
					this.Text = "[img]gfx/ui/events/event_84.png[/img]{The square gives onto the water. She is over the low wall and into the front of a punt that a man is poling out with a load of melons on it, and the man is shouting, and the punt is going.}";
					this.Options.push({
						Text = "{Get a hand on the pole and haul the thing back in.}",
						function getResult()
						{
							local r = ::Skv.Check.brawn(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							return this.Contract.chaseResolve(r.ok,
								"%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% gets two hands on the wet end of the pole and simply does not let go, and the punt comes back to the wall sideways with the boatman screaming and the melons going over the side one after another. She has to jump for the far steps and she lands badly.",
								"The pole comes out of the water, out of the boatman's hands, and out of everybody else's, and goes into the canal. The punt keeps going. She is off the front of it at the next set of steps and gone up them before anyone is round the head of the basin.",
								::Skv.XP.check(r));
						}
					});
				}
				else if (step == 2)
				{
					this.Text = "[img]gfx/ui/events/event_84.png[/img]{Up the steps is the middle of the market at the middle of the day: a solid press of people, baskets on heads, a rope of goats, and a boy with a tray of glasses that is going to end badly for somebody.}";
					this.Options.push({
						Text = "{Straight through. Do not stop for anything.}",
						function getResult()
						{
							local r = ::Skv.Check.agility(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							return this.Contract.chaseResolve(r.ok,
								"%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% goes through it like water goes through a fence - over the goat rope, off a barrel, past the boy without touching one glass - and comes out at the top of the market close enough to hear her breathing.",
								"Somebody puts a shoulder into the goat rope. The goats have opinions. What follows is thirty seconds of the company being shouted at by four separate people while a rabbit's-face mask goes up the far side of the market at a walk, because at that point she can afford to walk.",
								::Skv.XP.check(r));
						}
					});
				}
				else if (step == 3)
				{
					this.Text = "[img]gfx/ui/events/event_84.png[/img]{And of course the market has a watch on it. Six of them at the top end under a striped awning, bored, armed, and paid by a palace that would very much like a reason to take an interest in armed foreigners running in a public street.}";
					this.Options.push({
						Text = "{Slow down. Spread out. Be nobody.}",
						function getResult()
						{

							local r = ::Skv.Check.stealth(this.Contract, ::Skv.Check.scaledBase(this.Contract, 45), 0.5);
							return this.Contract.chaseResolve(r.ok,
								"The company comes apart into ones and twos and goes up the last of the market at the speed of men who are buying rope, and the watch watches the crowd the way men watch a crowd they have watched all morning. " + r.passed + " of " + r.total + " through without a head turning, which is more than enough.",
								"%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% is carrying too much iron to be a man buying rope, and a watchman steps off the kerb with his hand out. It is four minutes of names and the word Magaambya and a coin that is not quite a bribe - and four minutes is the whole street.",
								::Skv.XP.check(r));
						}
					});
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_84.png[/img]{She goes over a fence at the top of the market and into the hog pens behind the shambles, and she goes over the second fence too, and that one has forty hogs behind it that have been standing in the same mud since dawn and are extremely pleased that something is finally happening.}";

					this.Options.push({
						Text = "{Over the top of them. Straight line.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.ChasePick = 1;
							local r = ::Skv.Check.brawn(c2, ::Skv.Check.scaledBase(c2, 50));
							return c2.chaseResolve(r.ok,
								"%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% goes across the backs of them like a man crossing a stream on stones, which should not work and does, and comes off the far rail directly on top of her.",
								"It goes exactly as forty hogs and a fence should be expected to go. When the company is out of the pen the yard gate is standing open and the far lane is empty.",
								::Skv.XP.check(r));
						}
					});
					this.Options.push({
						Text = "{Along the rail. Do not touch the ground.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.ChasePick = 2;
							local r = ::Skv.Check.agility(c2, ::Skv.Check.scaledBase(c2, 50));
							return c2.chaseResolve(r.ok,
								"%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% takes the top rail at a run, all the way round the pen, and drops off the end of it into the gateway before she gets there.",
								"It goes exactly as forty hogs and a fence should be expected to go. When the company is out of the pen the yard gate is standing open and the far lane is empty.",
								::Skv.XP.check(r));
						}
					});
					this.Options.push({
						Text = "{Walk in among them. Hogs know a scared thing when they see one.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.ChasePick = 3;
							local r = ::Skv.Check.nerve(c2, ::Skv.Check.scaledBase(c2, 50));
							return c2.chaseResolve(r.ok,
								"%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% walks into forty hogs at a steady pace without once making a sudden movement, and they part for him and close behind him, and they do not part for her at all.",
								"It goes exactly as forty hogs and a fence should be expected to go. When the company is out of the pen the yard gate is standing open and the far lane is empty.",
								::Skv.XP.check(r));
						}
					});
					this.Options.push({
						Text = "{Get the swineherd on side and have him open the far gate.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.ChasePick = 4;
							local r = ::Skv.Check.charm(c2, ::Skv.Check.scaledBase(c2, 50));
							return c2.chaseResolve(r.ok,
								"%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% has the swineherd's far gate open in the time it takes to say who is paying, and forty hogs go out of the pen in the one direction she was running.",
								"It goes exactly as forty hogs and a fence should be expected to go. When the company is out of the pen the yard gate is standing open and the far lane is empty.",
								::Skv.XP.check(r));
						}
					});
				}

				this.Options.push({
					Text = "{Let her go. She is a child and this is a street.}",
					function getResult() { return this.Contract.chaseAbandon(); }
				});
			}

		});

		this.m.Screens.push({
			ID = "Door",
			Title = "The Reshelving Door",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local gate = c.m.DoorGate + 1;
				this.List = [];
				this.Options = [];

				local head = "[img]gfx/ui/events/event_74.png[/img]{At the back of the reading room the shelves stop matching the wall, and set into the stone behind them is a ring of twelve carved roundels: ten beasts, a starburst, and a man's face. Opposite the ring, cut into the facing stone, is a clock with three hands.\n\nThe clock is mirrored. It was cut to be read from behind the wall rather than from in front of it, so nothing on it points where it appears to point: a hand lying across one roundel is naming a different one, counted the other way round the ring. Reading it forwards is the mistake the door was built to catch.\n\n";

				if (gate == 1)
				{
					this.Text = head + "The thickest hand is the hour, and it lies across the ring towards the beasts. Which beast it MEANS is the first thing the door wants - and that is not the one it is lying on.}";
				}
				else if (gate == 2)
				{
					this.Text = head + "Something turned over behind the wall and the ring took up a notch. The middle hand is the minute, and it is not still - it creeps while you watch it. So it is the mirror twice over: not where the hand is, and not even where it is going, but where the reflection of it is going.}";
				}
				else if (gate == 3)
				{
					this.Text = head + "Two of the three are answered. The last hand is the second, and it goes round the face once every breath and a half, and there is no roundel that corresponds to it at all.\n\nThe mirror is no help here and no hindrance either - a reflection of a moment is still that moment. This one is not a question about the ring, and it is not a question about the glass. It is a question about when.}";
				}
				else
				{
					local g4 = "The clock is told, to the second, and nothing has opened. The ring sits there with its ten beasts and its starburst and its one carved face, and behind you a student who has been watching the whole performance says, not helpfully, that it is a door in a school.";
					if (c.m.DoorHint == 2)
					{

						g4 = g4 + "\n\nAnd then, because somebody asked her properly and nobody else in two days has, she says the rest of it.%SPEECH_ON%It is not a lock. That is what everyone gets wrong - they tell the clock and then they stand there waiting, because they think they have picked something. My teacher says the man who cut that door cut it for the reading room of the man who taught him, and the ring is not a puzzle, it is the register of who was let in. Ten of them were let in.%SPEECH_OFF%She looks at the twelve roundels and then at her own feet.%SPEECH_ON%Ten. And I have never been able to work out why they carved twelve.%SPEECH_OFF%";
					}
					this.Text = head + g4 + "}";
				}

				if (c.m.DoorHint == 0 && gate <= 2)
				{
					this.Options.push({
						Text = "{Somebody read that ring properly before anyone touches it.}",
						function getResult()
						{
							local g = this.Contract.m.DoorGate + 1;

							local r = ::Skv.Check.wits(this.Contract, ::Skv.Check.scaledBase(this.Contract, g == 1 ? 50 : 45),
								{ ["background.historian"] = 6, ["background.legend_magister"] = 4 });
							if (r.ok)
							{
								this.Contract.m.DoorHint = 2;
								this.Contract.say("The Reshelving Door",
									"[img]gfx/ui/events/event_74.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% has it, or has enough of it. " + (g == 1
										? "The ten beasts are the Ten Magic Warriors, in the order they came to the old man out of the jungle, and the hour hand is on the third of them. It is not a puzzle. It is a register, and it is asking you to know who is on it."
										: "The minute hand is moving because the second of them was still coming when the first arrived. Whatever the door wants, it is one of two, and not the one the hand is on now.")
									+ "}",
									this.Contract.rowsWith(true, this.Contract.m.DoorGate == 0
										? "The ring is read: the door wants one particular beast"
										: "Narrowed to two - and it is not the one the hand is on",
										::Skv.XP.check(r)), "Door");
							}
							else
							{
								this.Contract.m.DoorHint = 1;
								this.Contract.say("The Reshelving Door",
									"[img]gfx/ui/events/event_74.png[/img]{The company looks at ten carved animals for a while. Everybody has a theory. Two of the theories are about goats.}",
									[ this.Contract.row(false, "No read on this gate - press it blind, and a wrong press costs an attempt") ],
									"Door");
							}
							return "Result";
						}
					});
				}

				if (gate == 4 && c.m.DoorHint == 0)
				{
					this.Options.push({
						Text = "{That student has been watching this whole performance. Somebody talk to her.}",
						function getResult()
						{
							local r = ::Skv.Check.charm(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							if (r.ok)
							{
								this.Contract.m.DoorHint = 2;
								this.Contract.say("The Reshelving Door",
									"[img]gfx/ui/events/event_74.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% gets down to her height to do it, which is more thought than anybody in this house has given her since it happened, and asks what she knows about the door rather than what she knows about the men who came through the roof.\n\nShe knows a great deal about the door.}",
									this.Contract.rowsWith(true, "She tells you what the ring is FOR - and it is not a lock",
										::Skv.XP.check(r)),
									"Door");
							}
							else
							{
								this.Contract.m.DoorHint = 1;
								this.Contract.say("The Reshelving Door",
									"[img]gfx/ui/events/event_74.png[/img]{She is twelve, and there are eight armed strangers in her school, and the last adult who walked past that wall went out through the roof. She says she does not know anything about the door and then finds somewhere else to be.}",
									[ this.Contract.row(false, "She will not talk - and there is nobody else in this house who was watching") ],
									"Door");
							}
							return "Result";
						}
					});
				}

				local texts = null;
				local n = 4;

				if (gate == 1)
				{

					texts = c.doorTexts(1, [
						"{The ibis, third round the ring.}",
						"{The ibex, where the hand lies.}",
						"{The leopard, largest of the ten.}",
						"{The hare, opposite the hand.}"
					]);
					if (c.m.DoorHint == 2)
					{

						texts = c.doorTexts(1, [
							"{The ibis - the THIRD of the Ten, which is what the mirror makes of where the hand lies.}",
							"{The ibex, where the hand lies.}",
							"{The leopard, largest of the ten.}",
							"{The hare, opposite the hand.}"
						]);
					}
				}
				else if (gate == 2)
				{
					if (c.m.DoorHint == 2)
					{
						n = 2;
						texts = c.doorTexts(2, [
							"{The crane - where the reflection is going, not where the hand is going.}",
							"{The crocodile - where the hand itself is going.}"
						]);
					}
					else
					{
						texts = c.doorTexts(2, [
							"{The crane.}",
							"{The crocodile.}",
							"{The starburst.}",
							"{The leopard again.}"
						]);
					}
				}
				else if (gate == 3)
				{

					texts = c.doorTexts(3, [
						"{Press nothing. Wait for it to come round to the top.}",
						"{Press on the beat, the moment it passes.}",
						"{Press a breath early, to allow for the mirror.}",
						"{Hold the hand still with a thumb.}"
					]);
				}
				else
				{

					texts = c.doorTexts(4, [
						"{The twelfth roundel - the face.}",
						"{The starburst above the ring.}",
						"{Turn the whole ring back to where it began.}",
						"{Nothing. Wait, and let the door decide.}"
					]);
				}

				c.m.DoorSeats = n;

				this.Options.push({
					Text = texts[0],
					function getResult() { return this.Contract.doorPress(0, this.Contract.m.DoorSeats); }
				});
				this.Options.push({
					Text = texts[1],
					function getResult() { return this.Contract.doorPress(1, this.Contract.m.DoorSeats); }
				});
				if (n > 2)
				{
					this.Options.push({
						Text = texts[2],
						function getResult() { return this.Contract.doorPress(2, this.Contract.m.DoorSeats); }
					});
					this.Options.push({
						Text = texts[3],
						function getResult() { return this.Contract.doorPress(3, this.Contract.m.DoorSeats); }
					});
				}

				this.Options.push({
					Text = "{Step back from it. It is a door, and we are not here for doors.}",
					function getResult() { return "House"; }
				});
			}

		});

		this.m.Screens.push({
			ID = "Storeroom",
			Title = "The Storeroom",
			Text = "[img]gfx/ui/events/event_98.png[/img]{It is a store for things nobody has needed in twenty years, and it is under a foot of water that has come up through the floor rather than in through the door. Crates have swollen and split. Something that was a drum is a hoop and a smell.\n\nOn the beam over the water, just above the waterline and drawn in a wax that has not run, there is a figure the length of a forearm. It is the same figure that is drawn four times on the pages from the desk, and it is drawn badly here too - a stroke doubled, and the last one closed when it should be open - and where it is wrong the wax has gone brown and the beam under it is wet in a way the rest of the beam is not.\n\nIt has been sitting here failing to work, quietly, for some while.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [];
				this.Options = [
					{
						Text = "{Take it apart. Slowly, and in the right order.}",
						function getResult()
						{
							local r = ::Skv.Check.wits(this.Contract, ::Skv.Check.scaledBase(this.Contract, 58));
							if (r.ok)
							{
								this.Contract.m.RuneLesson = 2;
								this.Contract.m.KnowsRune = true;
								this.Contract.say("The Storeroom",
									"[img]gfx/ui/events/event_98.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% does it with a knife and the flat of a thumbnail, and does it backwards: last stroke first, and the doubled one lifted whole, and the closed one opened before anything else is touched. The wax comes off the beam in one piece and goes cold in his hand, and the beam under it steams for a moment and then is only a beam.\n\nWhat the company has now is not learning. It is the order. Whatever else these things are, they come apart in the reverse of the order they were put on - and having taken one apart with your own hands, you would know one again in a dark room in a hurry.}",
									this.Contract.rowsWith(true, "Taken apart in the right order - the company would know one again in the dark",
										::Skv.XP.check(r)),
									"");
							}
							else
							{
								this.Contract.m.RuneLesson = 1;
								local rows = this.Contract.hurtSome(1, 6, 14);
								rows.insert(0, this.Contract.row(false, "It came off wrong, and nobody could say in what order"));
								this.Contract.say("The Storeroom",
									"[img]gfx/ui/events/event_98.png[/img]{The doubled stroke comes away first, which is the wrong first, and the whole figure lets go of the beam at once with a noise like a wet rope parting. There is no fire and no flash. There is simply, briefly, a great deal more water in the room than there was, and it arrives in one place, from one direction, hard.\n\nThe rune is off the beam. Nobody could say in what order it came off.}",
									rows, "");
							}
							return "Result";
						}
					},
					{
						Text = "{Do not touch it. Copy it, stroke for stroke, and get out.}",
						function getResult()
						{
							this.Contract.m.RuneLesson = 1;
							this.Contract.say("The Storeroom",
								"[img]gfx/ui/events/event_98.png[/img]{Two pages of it, in charcoal, from three angles, with the doubled stroke marked. It is an honest copy of a thing nobody in the company understands, which is worth something, and less than it looks.}",
								this.Contract.rowsWith(false, "Copied, not learned - this is not the second route to knowing a rune",
									::Skv.XP.partyEach(10)), "");
							return "Result";
						}
					},
					{
						Text = "{Leave it be.}",
						function getResult() { return "House"; }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Result",
			Title = "Threshold of Knowledge",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Title = this.Contract.m.ResultTitle;
				this.Text  = this.Contract.m.ResultText;
				this.List  = this.Contract.m.ResultRows == null ? [] : this.Contract.m.ResultRows;
				this.Options = [
					{
						Text = "{Good.}",
						function getResult()
						{
							local next = this.Contract.m.ResultNext;
							return next == "" ? this.Contract.hubScreen() : next;
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Abort",
			Title = "The Bead",
			Text = "[img]gfx/ui/events/event_112.png[/img]{It is a bead of dull green glass and it comes apart between finger and thumb with less resistance than glass has any right to, and it does not cut anybody.\n\nThere is no sound and no light. Somewhere behind you, in a room in a house that is tolerated here, a woman who was not expecting this today puts down what she was holding.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{

				local c = this.Contract;

				local tail = "";
				if (c.m.Act >= 3)
				{
					tail = "\n\nThere is a building over your head with four marks going quietly wrong in it, and you are the only people in %townname% who know that. Crushing this now is a decision about the lower gallery, whatever anybody calls it afterwards.";
				}
				else if (c.m.Act == 2)
				{
					tail = "\n\nWhatever is down that channel stays down it. So does the man they took.";
				}
				else
				{
					tail = "\n\nNobody has been down there yet. Nobody will be.";
				}
				this.Text = "[img]gfx/ui/events/event_112.png[/img]{It is a bead of dull green glass and it comes apart between finger and thumb with less resistance than glass has any right to, and it does not cut anybody.\n\nThere is no sound and no light. Somewhere behind you, in a room in a house that is tolerated here, a woman who was not expecting this today puts down what she was holding." + tail + "}";

				this.List = [];
				this.Options = [
					{
						Text = "{Crush it. She said she would rather have us alive.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Aborted = true;
							c2.m.Concluded = true;

							if (c2.abortIsFailure())
							{
								c2.m.Outcome = 3;
							}
							::Skv.dbg("Skv.Threshold: aborted via the bead - no reputation, no relation, advance kept."
								+ " act=" + c2.m.Act + " rungs=" + c2.rungCount()
								+ " failure=" + c2.abortIsFailure());
							this.World.Contracts.finishActiveContract(true);
							return 0;
						}
					},
					{
						Text = "{Not yet. Put it away.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Canal",
			Title = "Beneath the House",
			Text = "[img]gfx/ui/events/event_89.png[/img]{Under the reading room is a storeroom, and under the storeroom is water. The house stands over one of the old canals - half of %townname% does - and the grating that should close it off has been prised out of its seat and left leaning against the brick. There are marks on the stone where something heavy was dragged in. They do not come back out again.\n\nThe water is warm and about thigh-deep and it is moving, slowly, inward. Forty paces along, the brick stops being brick and becomes something older and better cut, and the sound of the city stops with it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [];
				this.Options = [
					{
						Text = "{Down into the dark.}",
						function getResult()
						{
							this.Contract.m.Leg = "canal";
							::Skv.dbg("Skv.Threshold: act II entered - rungs=" + this.Contract.rungCount()
								+ " KnowsRune=" + this.Contract.m.KnowsRune + " charms=" + this.Contract.m.HasCharms);
							this.Contract.say("Beneath the House",
								"[img]gfx/ui/events/event_89.png[/img]{Somebody counts the company through the grating out loud, the way you do, and the number is right, and that is the last ordinary thing that happens for a while.}",
								[], "");
							return "Result";
						}
					},
					{
						Text = "{Not yet.}",
						function getResult() { return 0; }
					}
				];

				if (this.Contract.m.HasBracelet)
				{
					this.Options.push({
						Text = "{Crush the bead. Let her pull us out.}",
						function getResult() { return "Abort"; }
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Gusa",
			Title = "The Thing In The Doorway",
			Text = "[img]gfx/ui/events/event_114.png[/img]{Where the old brick starts, something stands up out of the water that the company had taken for a drowned stump. It is about the height of a man and about the shape of one, and it is made of bark and rope-root and a great deal of pale fungus, and it has been growing here a long time. It holds up one hand.%SPEECH_ON%No. Not this way. Go back.%SPEECH_OFF%It does not come any closer. It says it again, and then a third time, and the third time it sounds less like a warning and more like somebody asking.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				if (c.m.Gusa == 0)
				{
					this.Options.push({
						Text = "{It is talking. Talk back.}",
						function getResult()
						{
							local r = ::Skv.Check.charm(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							if (r.ok)
							{
								this.Contract.m.Gusa = 1;
								this.Contract.addRung(this.Contract.m.Rung.Gusa);
								this.Contract.say("The Thing In The Doorway",
									"[img]gfx/ui/events/event_114.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% asks it what is down there, which is not a question it was expecting, and it thinks about that for long enough that somebody's arm gets tired.%SPEECH_ON%%SKVNAME%Gusa%SKVNAME_OFF% keeps this water. There is a woman in it now and she is not a woman. She has a man of yours - no. A man of theirs. Two of the little ones are hers, and they are frightened, and they will not go home.%SPEECH_OFF%It moves aside, into the reeds, and then adds the thing that is worth more than everything else it has said.%SPEECH_ON%The tunnel is fallen in. That was them. There are little ones behind it with crossbows, and they have been waiting two days for somebody to come along and be surprised.%SPEECH_OFF%}",
									this.Contract.rowsWith(true, "Gusa steps aside - and you will not be walking into the collapse blind",
										::Skv.XP.check(r)),
									"");
							}
							else
							{
								this.Contract.m.Gusa = 3;
								this.Contract.say("The Thing In The Doorway",
									"[img]gfx/ui/events/event_114.png[/img]{It does not have enough words for this and neither, it turns out, does the company. It says no. It keeps saying no. It is still saying it while the water goes on moving past everybody's knees.}",
									[ this.Contract.row(false, "It will not be talked round - and it will not stand aside either") ],
									"");
							}
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = "{It is in the way. Move it.}",
					function getResult()
					{
						this.Contract.m.Gusa = 2;
						local rows = this.Contract.hurtSome(2, 8, 16);
						rows.insert(0, this.Contract.row(false, "Gusa is dead, and it never did anything but ask"));
						rows.push(this.Contract.row(false, "Nobody warned you about the collapse"));
						foreach (r in this.Contract.moodShift(-1, "Killed a thing that asked us three times to leave",
							this.Contract.gentleBackgrounds())) rows.push(r);
						foreach (r in this.Contract.moodShift(1, "Cleared the way without a lot of talking",
							this.Contract.hardBackgrounds())) rows.push(r);

						this.Contract.say("The Thing In The Doorway",
							"[img]gfx/ui/events/event_114.png[/img]{It is not much of a fight. It is strong the way a wet log is strong and it does not seem to have understood, even at the end, that this was the sort of thing that could happen to it - it goes on saying no, and then it is a great deal of broken bark in the water, going slowly inwards with everything else.\n\nSomething small further up the tunnel hears all of it and does not come to look.}",
							rows, "");
						return "Result";
					}
				});

				this.Options.push({
					Text = "{Wait. Say nothing yet.}",
					function getResult() { return 0; }
				});
			}

		});

		this.m.Screens.push({
			ID = "Collapse",
			Title = "The Fallen Tunnel",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				local body = "[img]gfx/ui/events/event_160.png[/img]{The roof of the tunnel is on the floor of it. Somebody brought down thirty feet of old vaulting across the channel, and did it badly enough to be underneath a good deal of it - there are small bodies in the rubble, four or five, in the postures of things that were still holding the props when the props went.\n\nThe water goes through. So can a man, on his belly, one at a time, in the dark.";

				if (c.hasRung(c.m.Rung.Gusa))
				{
					body = body + "\n\nAnd because a thing made of bark told you so, nobody does that. The company takes the dry side passage instead, and comes out behind the rubble with its shields already up.}";
				}
				else
				{
					body = body + "\n\nThere is no other way through that anybody can see.}";
				}
				this.Text = body;

				if ((c.m.Act2Reads & 0x01) == 0)
				{
					this.Options.push({
						Text = "{Before anybody crawls into that - where are they actually coming from?}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Act2Reads = c2.m.Act2Reads | 0x01;
							local r = ::Skv.Check.perception(c2, ::Skv.Check.scaledBase(c2, 55));
							if (r.ok)
							{
								c2.m.Act2Reads = c2.m.Act2Reads | 0x02;
								c2.say("The Fallen Tunnel",
									"[img]gfx/ui/events/event_160.png[/img]{%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% puts a hand flat on the rubble and finds it dry, then finds the place two yards left where it is not, and works back from there: they are not coming over the fall at all. There is a service channel above the vault, and it is wet, and it is wet in one direction.\n\nHalf of them are on the wrong side of their own collapse and will still be digging when this is finished.}",
									c2.rowsWith(true, "Half the warren is behind its own rubble - the fight just got smaller",
										::Skv.XP.check(r)),
									"Collapse");
							}
							else
							{
								c2.say("The Fallen Tunnel",
									"[img]gfx/ui/events/event_160.png[/img]{It is a heap of wet stone in the dark with water going through it. It could be hiding anything, and after a quarter of an hour of looking at it that is still the whole of what anybody can say.}",
									[ c2.row(false, "No read on the rubble - you will meet whatever is behind it, all of it") ],
									"Collapse");
							}
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = c.m.Kobolds == 3 ? "{Back in. They are fewer than they were.}" : "{Through, then. Shields.}",
					function getResult()
					{
						this.Contract.getActiveState().onCombatKobolds();
						return 0;
					}
				});

				this.Options.push({
					Text = "{Not yet.}",
					function getResult() { return 0; }
				});

				if (c.m.HasBracelet)
				{
					this.Options.push({
						Text = "{Crush the bead.}",
						function getResult() { return "Abort"; }
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Swim",
			Title = "The Flooded Reach",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				local head = "[img]gfx/ui/events/event_89.png[/img]{Behind the collapse the floor drops away and the vault comes down to meet it, and for a stretch of maybe forty feet there is no air in the tunnel at all. The water is black and moving and it smells of the sea, which it should not, this far up.";
				if (c.m.HasCharms)
				{
					head = head + "\n\nSomebody remembers the rag in the kit with the scale in it - the wet one, the length of a thumb, that the girl in the courtyard would not take back. Her aunt fishes the delta, she said. You put it under your tongue and the water lets you alone a while. Everyone says it is nothing.";
				}

				if ((c.m.Act2Reads & 0x08) == 0)
				{
					head = head + "\n\nThere is a canvas pack against the wall where the side passage comes in, above the waterline and out of the wet. Somebody has been through it already, roughly, and put nothing back.";
				}

				this.Text = head + "}";

				if ((c.m.Act2Reads & 0x08) == 0)
				{
					this.Options.push({
						Text = "{Turn the pack out before anybody gets wet.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Act2Reads = c2.m.Act2Reads | 0x08;

							local sickle   = ::Skv.Loot.make([ "scripts/items/weapons/legend_sickle" ]);
							local supplies = ::Skv.Loot.make([ "scripts/items/supplies/medicine_item" ]);

							local marked = false;
							try { marked = ::GolarionEnchant.apply(sickle.len() > 0 ? sickle[0] : null, 1); }
							catch (e) { ::logError("Skv.Threshold: wordreaper enchant threw: " + e); }
							if (!marked)
							{
								::logError("Skv.Threshold: the sickle dropped UNENCHANTED - is mod_golarion/config/78_enchant.nut loaded?");
							}

							if (supplies.len() > 0)
							{
								try { supplies[0].setAmount(5); }
								catch (e) { ::logError("Skv.Threshold: medicine setAmount failed: " + e); }
							}

							local items = [];
							foreach (it in sickle)   items.push(it);
							foreach (it in supplies) items.push(it);

							local rows = ::Skv.Loot.haul(items);
							::Skv.dbg("Skv.Threshold: Okulou's pack taken - items=" + items.len() + " enchanted=" + marked);

							c2.say("The Flooded Reach",
								"[img]gfx/ui/events/event_89.png[/img]{Four stoppered draughts in a roll of cloth, labelled in a careful round hand by somebody who expected to be reading them in a hurry.\n\nTwo clay flasks bedded in sawdust, waxed shut and marked with a stroke of red. Nobody opens those, and nobody is carrying them into forty feet of black water either, so they go back against the wall for whoever comes down here next.\n\nAt the bottom, wrapped twice in oilcloth, a sickle. The blade is cut to the shape of a quill feather and the handle finishes in a pen nib, and it is far too fine a thing to be at the bottom of a canvas bag under a canal. It has never been near a crop in its life.\n\nThere is a name inked inside the flap in the same careful hand, and it is a boy's.}",
								rows, "");
							return "Result";
						}
					});
				}

				if (c.m.HasCharms)
				{
					this.Options.push({
						Text = "{The girl's scale, then. Under the tongue, and one at a time through.}",
						function getResult()
						{
							this.Contract.m.Swim = 2;
							this.Contract.say("The Flooded Reach",
								"[img]gfx/ui/events/event_89.png[/img]{The scale goes round the company one man at a time and comes back wet, and every man who has had it under his tongue goes through that forty feet without hurrying and comes up on the far side wondering what the fuss was about.\n\nNobody says anything clever about it. One or two of them look at it differently afterwards.}",
								this.Contract.rowsWith(true, "The girl's charm was not nothing",
									::Skv.XP.partyEach(15)),
								"");
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = "{Straight through. Pull hard and do not stop.}",
					function getResult()
					{
						local c2 = this.Contract;
						local r = ::Skv.Check.brawn(c2, ::Skv.Check.scaledBase(c2, 50));
						c2.m.Swim = 1;
						if (r.ok)
						{
							c2.say("The Flooded Reach",
								"[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% goes first with a line round his chest and hauls the rest through it hand over hand, and the whole company is on the far side coughing and swearing inside two minutes.}",
								c2.rowsWith(true, "Through, and nobody left in the dark", ::Skv.XP.check(r)), "");
						}
						else
						{
							local rows = c2.hurtSome(2, 6, 14);
							rows.insert(0, c2.row(false, "Through - but it took two of them apart on the way"));
							c2.say("The Flooded Reach",
								"[img]gfx/ui/events/event_89.png[/img]{Two men come out on the far side at the wrong angle and at the wrong speed, and one of them comes out at all only because somebody had a fist in his collar. Everybody is through. Everybody is worse.}",
								rows, "");
						}
						return "Result";
					}
				});

				this.Options.push({
					Text = "{Feel the way along the roof. Slowly.}",
					function getResult()
					{
						local c2 = this.Contract;
						local r = ::Skv.Check.agility(c2, ::Skv.Check.scaledBase(c2, 50));
						c2.m.Swim = 1;
						if (r.ok)
						{
							c2.say("The Flooded Reach",
								"[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% finds what the old builders left up there - a rib every few feet, for exactly this - and the company goes along it in the dark hand to hand like men on a rope, unhurried, and comes up together.}",
								c2.rowsWith(true, "Through, and nobody left in the dark", ::Skv.XP.check(r)), "");
						}
						else
						{
							local rows = c2.hurtSome(2, 6, 14);
							rows.insert(0, c2.row(false, "Through - but it took two of them apart on the way"));
							c2.say("The Flooded Reach",
								"[img]gfx/ui/events/event_89.png[/img]{The ribs run out halfway, which nobody could have known, and the back half of the company finds that out with no air left and nothing overhead. Everybody is through. Two of them are a long time getting their colour back.}",
								rows, "");
						}
						return "Result";
					}
				});
			}

		});

		this.m.Screens.push({
			ID = "Jubo",
			Title = "The Beach",
			Text = "[img]gfx/ui/events/event_130.png[/img]{The channel opens into a chamber with a shelf of silt along one wall - a beach, of a sort, under a city - and on it, mostly out of the water, is something with a great deal of green scale and a great many teeth, asleep with its jaw across its own foreleg.\n\nIt is not a small one. It is between the company and the only way on, and it is breathing very slowly.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [];
				this.Options = [
					{
						Text = "{Along the wall. One at a time. Nobody hurries.}",
						function getResult()
						{
							local c2 = this.Contract;

							local r = ::Skv.Check.stealth(c2, ::Skv.Check.scaledBase(c2, 45), 0.5);
							if (r.ok)
							{
								c2.m.Jubo = 1;
								c2.addRung(c2.m.Rung.Jubo);
								c2.say("The Beach",
									"[img]gfx/ui/events/event_130.png[/img]{" + r.passed + " of " + r.total + " go along the wall without putting a foot wrong, and the two or three who do put a foot wrong do it in the water rather than on the silt, which turns out to be the whole trick.\n\nIt does not wake. It does not wake later, either.}",
									c2.rowsWith(true, "Past it - and it stays asleep, whatever happens in the grotto beyond",
										::Skv.XP.check(r)),
									"");
							}
							else
							{
								c2.m.Jubo = 2;
								local rows = c2.hurtSome(1, 8, 18);

								rows.insert(0, c2.row(false, c2.m.ActorName + " put a boot through the silt - it is awake, and it is following"));
								c2.say("The Beach",
									"[img]gfx/ui/events/event_130.png[/img]{Only " + r.passed + " of " + r.total + " get along that wall properly, and it takes one bad step to end the exercise. The jaw comes off the foreleg like a door coming off a wall and the chamber is suddenly extremely loud.\n\nThe company gets past it. It does not go back to sleep, and it does not stay where it is.}",
									rows, "");
							}
							return "Result";
						}
					},
					{
						Text = "{Wake it deliberately, and drive it off the beach.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Jubo = 3;
							local rows = c2.hurtSome(2, 8, 18);
							rows.insert(0, c2.row(false, "Driven off, on your terms - it will not be in the grotto, and it cost blood"));
							c2.say("The Beach",
								"[img]gfx/ui/events/event_130.png[/img]{It is done properly, at least: shields set, two men on the flanks with spears, and everybody knowing exactly when it is going to start. That is worth a great deal, and it is still a very large animal in a small room.\n\nIt goes into the water in the end and does not come back out of it. Whatever is further in has heard every second of that.}",
								rows, "");
							return "Result";
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Approach",
			Title = "The Grotto Mouth",
			Text = "[img]gfx/ui/events/event_103.png[/img]{Past the beach the channel turns twice and then stops being a channel: the vault opens out into a flooded room the size of a barn, with a pool in the middle of it that is deeper than anything has any business being under a city, and a dry shelf running round two sides.\n\nThere is light in there. Not lamplight. Something further in is lit from underneath, in green, and it moves when the water moves.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				if ((c.m.Approach & 0x01) == 0)
				{
					this.Options.push({
						Text = "{One man forward, quietly, to look at the ground.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Approach = c2.m.Approach | 0x01;

							local r = ::Skv.Check.stealth(c2, ::Skv.Check.scaledBase(c2, 45));
							if (r.ok)
							{
								c2.addRung(c2.m.Rung.Ground);
								c2.say("The Grotto Mouth",
									"[img]gfx/ui/events/event_103.png[/img]{%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% goes in along the shelf with his shield off and comes back a long time later with the whole shape of the room in his head: where the shelf is dry and where it is not, which end of it a man can stand on without being in the water, and where the roof comes down far enough that nothing tall can come at you from behind.\n\nIf there is going to be a fight, the company now gets to say where it happens.}",
									c2.rowsWith(true, "You pick the ground - and there will be fewer of them on it",
										::Skv.XP.check(r)),
									"Approach");
							}
							else
							{
								c2.say("The Grotto Mouth",
									"[img]gfx/ui/events/event_103.png[/img]{He gets twenty feet, finds that the shelf is not a shelf but a lip with nothing under it, and comes back rather faster than he went. Nobody heard him. Nobody learned anything either.}",
									[ c2.row(false, "No ground scouted - if it comes to a fight, it happens where she wants it") ],
									"Approach");
							}
							return "Result";
						}
					});
				}

				if ((c.m.Approach & 0x02) == 0)
				{
					this.Options.push({
						Text = "{Never mind the floor. Watch the water.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Approach = c2.m.Approach | 0x02;
							local r = ::Skv.Check.perception(c2, ::Skv.Check.scaledBase(c2, 50));
							if (r.ok)
							{
								c2.addRung(c2.m.Rung.Water);
								c2.say("The Grotto Mouth",
									"[img]gfx/ui/events/event_103.png[/img]{%SKVNAME%" + c2.m.ActorName + "%SKVNAME_OFF% spends a while on the green light and works out that it is not light: it is her, or it is what she is doing, and it is pointed at the mouth of the pool. She is watching the water. She has been watching the water for two days, because the water is the way anything down here comes in.\n\nWhich means she is not watching the shelf.}",
									c2.rowsWith(true, "She is looking the wrong way - the first thing she does will not be to you",
										::Skv.XP.check(r)),
									"Approach");
							}
							else
							{
								c2.say("The Grotto Mouth",
									"[img]gfx/ui/events/event_103.png[/img]{The green comes and goes and means nothing to anybody, and after a while looking at it makes the back of the eyes ache.}",
									[ c2.row(false, "Nothing read off the water - assume she sees you the moment you are in the room") ],
									"Approach");
							}
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = "{Enough looking. In.}",
					function getResult() { return "Grotto"; }
				});

				if (c.m.HasBracelet)
				{
					this.Options.push({
						Text = "{Crush the bead.}",
						function getResult() { return "Abort"; }
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Grotto",
			Title = "The Grotto",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				local seen = "[img]gfx/ui/events/event_106.png[/img]{From the last turn of the shelf you can see all of it. There is a man tied at the wrist to a ring in the wall with his feet in the water, and he is alive, and he is in a bad way. There are two more further back who are not tied to anything and are not going anywhere either - young, both of them, and one of them has been crying for some while.\n\nAnd there is a woman in the pool. She is up to the waist in it with her back to the shelf, and she is not a woman, and every man in this company has seen one before or been told about one by somebody who had.\n\n";

				if (c.m.GrottoPick == 3)
				{
					seen = seen + "She knows the company is here now. There is no version of this where anybody surprises anybody.}";
				}
				else if (c.twoVoices())
				{
					seen = seen + "%SKVNAME%%randombrother%%SKVNAME_OFF% says it first, and quietly.%SPEECH_ON%That is a Hexe. That is beyond us.%SPEECH_OFF%Then, because he has been thinking about it the whole way down: %SPEECH_ON%" + c.grottoPlan() + " We take the prisoners and we are gone before she is out of that water.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% does not take his eyes off the pool.%SPEECH_ON%But what of the glory? Killing a Hexe is a story worth telling, and there is not a company on this coast that has one. Whatever she has been paid in is down there with her besides. We can do it.%SPEECH_OFF%}";
				}
				else
				{
					seen = seen + "There is nobody to argue with about it. The whole of the company's opinion is one man's, and what he has is this: %SPEECH_ON%" + c.grottoPlan() + "%SPEECH_OFF%}";
				}
				this.Text = seen;

				if (c.m.GrottoPick != 3)
				{
					this.Options.push({
						Text = "{Take her.}",
						function getResult()
						{
							this.Contract.m.GrottoPick = 1;
							this.Contract.getActiveState().onCombatNgaja();
							return 0;
						}
					});
				}

				this.Options.push({
					Text = c.m.GrottoPick == 3
						? "{Take the prisoners and go. She has already seen us.}"
						: "{Take the prisoners and go. She can keep the water.}",
					function getResult()
					{
						local c2 = this.Contract;
						c2.m.OtFound = true;

						if (c2.m.GrottoPick == 3)
						{
							local rows = c2.hurtSome(2, 8, 16);
							rows.insert(0, c2.row(false, "Out with all three of them - and she made you pay for every yard"));
							c2.say("The Grotto",
								"[img]gfx/ui/events/event_103.png[/img]{There is nothing clever left to do. The company goes back along the shelf into a room that is watching it, gets the ring out of the wall with four hands on it, and carries three people out of the water at a dead run with something behind them the whole way.\n\nShe does not follow past the turn. She never does. She has what she actually came for and it is not any of you.}",
								rows, "Prisoners");
							return "Result";
						}

						c2.m.GrottoPick = 2;
						local rows = c2.rowsWith(true, "Out with all three of them, and not a blade drawn",
							::Skv.XP.partyEach(30));

						if (c2.m.Jubo == 2)
						{
							foreach (x in c2.hurtSome(1, 10, 20)) rows.push(x);
							rows.push(c2.row(false, "The thing off the beach came up the channel behind you"));
						}

						c2.say("The Grotto",
							"[img]gfx/ui/events/event_103.png[/img]{It takes four minutes and every one of them is a long one. The ring in the wall is old and the mortar round it is older, and the man tied to it has the sense not to make a sound while it comes out. The two young ones are carried, one of them over a shoulder, because neither of them can be reasoned with by then.\n\nThe last man off the shelf watches her the whole way. She does not turn round. Whatever she is doing in that water, it is taking all of her.}",
							rows, "Prisoners");
						return "Result";
					}
				});

				if (!c.m.Watched && c.m.GrottoPick != 3)
				{
					this.Options.push({
						Text = "{Say nothing. Watch her.}",
						function getResult()
						{
							local c2 = this.Contract;
							c2.m.Watched = true;
							c2.addRung(c2.m.Rung.Watch);
							c2.say("The Grotto",
								"[img]gfx/ui/events/event_106.png[/img]{Nobody moves for a quarter of an hour, which is a long time to stand in cold water, and it buys exactly one thing: she is tired. Not sleepy. Tired the way a person is at the end of a job that is not going well - she has been at the man on the ring all night and she has got nothing out of him, and twice in that quarter of an hour she puts a hand flat on the rock and just stands there.\n\nWhatever she is, she has been awake as long as you have.}",
								[ this.Contract.row(true, "She is worn down, and now you know it") ],
								"Grotto");
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = "{Back to the mouth. Look again.}",
					function getResult() { return "Approach"; }
				});

				if (c.m.HasBracelet)
				{
					this.Options.push({
						Text = "{Crush the bead. Leave them where they are.}",
						function getResult() { return "Abort"; }
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Prisoners",
			Title = "What Is Left On The Shelf",
			Text = "[img]gfx/ui/events/event_166.png[/img]{The man on the ring is %SKVNAME%Ot Vaunder%SKVNAME_OFF%, and once he has had water and somebody's cloak he is a great deal more coherent than he has any right to be. He asks after the house first. He asks after the students second, which is the awkward part, because the students are sitting four feet away with their wrists tied.\n\nThey are the two who let it in. %SKVNAME%Mnroba%SKVNAME_OFF% - if you took her in the street, you have already met her - and a heavy-set boy called %SKVNAME%Okulou%SKVNAME_OFF% who has not said one word. They were promised something. Neither of them can now say what. And whatever they were promised, the thing in the pool stopped pretending about two days ago, and there is a good deal of bruising on both of them to show for it.\n\nOt says nothing at all about what should happen to them. He looks at you and waits, which is worse.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];
				c.m.OtFound = true;

				this.Options.push({
					Text = "{They go back to the house. It is the house's business.}",
					function getResult()
					{
						this.Contract.m.Students = 1;
						this.Contract.say("What Is Left On The Shelf",
							"[img]gfx/ui/events/event_166.png[/img]{Ot nods once, as if that had been obvious, and does not say thank you for it. The boy starts crying at that point and not before.}",
							[ this.Contract.row(true, "The students go back to the Magaambya - to be dealt with by their own") ],
							"Reveal");
						return "Result";
					}
				});

				this.Options.push({
					Text = "{They go to the palace. Let the city have them.}",
					function getResult()
					{
						local c2 = this.Contract;
						c2.m.Students = 2;
						local rows = [ c2.row(false, "The students go to the city's people - and everyone here knows what that means") ];
						foreach (r in c2.moodShift(-1, "Handed two children to this city's magistrates",
							c2.gentleBackgrounds())) rows.push(r);
						c2.say("What Is Left On The Shelf",
							"[img]gfx/ui/events/event_166.png[/img]{Ot does not argue. He looks at the water for a while instead, and then says, in the voice of a man reciting a rule he has taught for thirty years, that the school does not hand people to this city.\n\nThen he says he supposes the school did not come down here either.}",
							rows, "Reveal");
						return "Result";
					}
				});

				this.Options.push({
					Text = "{They opened a door for that. They can answer for it here.}",
					function getResult()
					{
						local c2 = this.Contract;
						c2.m.Students = 3;
						local rows = [ c2.row(false, "The students do not come back up the canal") ];
						foreach (r in c2.moodShift(-2, "Killed two bound students in a cellar",
							c2.gentleBackgrounds())) rows.push(r);
						foreach (r in c2.moodShift(1, "Left no loose ends behind us",
							c2.hardBackgrounds())) rows.push(r);
						c2.say("What Is Left On The Shelf",
							"[img]gfx/ui/events/event_166.png[/img]{It is quick, and it is done out of Ot's sight, and he knows exactly what it was because he can count.\n\nHe does not say anything about it on the way up. He does not say anything about it later either, which turns out to be the part that stays with people.}",
							rows, "Reveal");
						return "Result";
					}
				});
			}

		});

		this.m.Screens.push({
			ID = "Reveal",
			Title = "What He Was Taken For",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				local body = "[img]gfx/ui/events/event_45.png[/img]{Halfway back along the channel %SKVNAME%Ot%SKVNAME_OFF% stops walking, which nobody expects, and asks what day it is. He is told. He works something out on his fingers, twice, and gets the same answer both times, and then he is not a rescued man any more, he is a teacher with about four minutes of somebody's attention and something urgent to put into it.%SPEECH_ON%She did not want me. She wanted a fortnight in which nobody was reading the Heron Archives, and I was the way to get one. There are runes going up in that building - the children were setting them, that is what they were for - and when the last one closes, the whole of the lower gallery takes the canal in through the floor.%SPEECH_OFF%He is already walking again, faster than he can really manage.%SPEECH_ON%Luckily for us, %SKVNAME%Okulou%SKVNAME_OFF% was never very good at making them. That is the only reason we are having this conversation instead of standing in it.%SPEECH_OFF%";

				if (c.m.KnowsRune)
				{
					body = body + "\n\nAnd the company already knows what he is talking about, which he notices, and which visibly rearranges his opinion of who he has been rescued by.}";
				}
				else
				{
					body = body + "\n\nNobody in the company has the first idea what he is talking about. He can hear that, and there is no time to fix it.}";
				}
				this.Text = body;

				this.Options.push({
					Text = "{Then we are going the wrong way. Up.}",
					function getResult()
					{
						local c2 = this.Contract;
						c2.m.Flipped = true;
						c2.m.Act = 3;
						c2.m.Leg = "archive";

						c2.m.ClockDay = ::World.getTime().Days;
						c2.m.HoursSpent = 0.0;
						c2.m.HoursLimit = 14 + ::Math.rand(0, 4);
						if (!c2.m.KnowsRune)
						{

							::Skv.dbg("Skv.Threshold: flip with NO KnowsRune - act III is blind");
						}

						c2.m.BulletpointsObjectives = [
							"Get back to the Heron Archives and put out the runes before the water comes"
						];

						::Skv.dbg("Skv.Threshold: OBJECTIVE FLIPPED - act=3 clockDay=" + c2.m.ClockDay
							+ " limit=" + c2.m.HoursLimit + "h rungs=" + c2.rungCount()
							+ " KnowsRune=" + c2.m.KnowsRune + " ngajaDead=" + c2.m.NgajaDead
							+ " students=" + c2.m.Students);

						c2.say("What He Was Taken For",
							"[img]gfx/ui/events/event_45.png[/img]{The way out takes half the time the way in did, which is what happens when nobody is being careful any more.}",
							[ { id = 12, icon = "ui/icons/special.png", text = "The job is not the man. The job is the building" },
							  { id = 12, icon = "ui/icons/days_wounded.png", text = "You have until the last rune closes" } ],
							"");
						return "Result";
					}
				});
			}

		});

		this.m.Screens.push({
			ID = "Archive",
			Title = "The Heron Archives",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = c.clockRows();
				this.Options = [];

				local head = "[img]gfx/ui/events/event_15.png[/img]{";

				if (!c.m.Arrived)
				{

					c.m.Arrived = true;
					head = head + "%SKVNAME%Ot%SKVNAME_OFF% goes up the stairs ahead of everybody, which for a man who was tied to a ring four hours ago is a remarkable piece of work, and starts opening doors and calling numbers back down the stair.\n\nFour rooms. The map room, the head of the stair, the reading gallery you were standing in two days ago, and the cistern room at the bottom where the floor is already wet. One mark in each, all four drawn by a boy who was not very good at it, and all four very nearly finished.\n\n";

					if (c.m.KnowsRune)
					{
						head = head + "And the company has taken one of these apart before, in a storeroom, with a knife and the flat of a thumbnail. It comes off backwards: last stroke first. Knowing that is worth about half the night.";
					}
					else
					{
						head = head + "Nobody in the company has ever taken one apart. Ot can say what a mark is FOR and cannot say how it comes off, and the difference between those two things is going to be measured in hours.";
					}
					head = head + "\n\n";

					::Skv.dbg("Skv.Threshold: archive entered - window=" + c.m.HoursLimit
						+ "h knowsRune=" + c.m.KnowsRune + " ngajaDead=" + c.m.NgajaDead);
				}

				if (c.runesDone() == 0)
				{
					head = head + "Nothing has been touched yet.}";
				}
				else if (c.runesDone() >= 4)
				{
					head = head + "All four are out. The building has stopped making that sound.}";
				}
				else
				{
					head = head + "The rooms that are still to do are quieter than the ones that are done, which is the wrong way round and nobody likes it.}";
				}
				this.Text = head;

				for ( local i = 1; i <= 4; i = i + 1 )
				{
					if ((c.m.RunesDone & c.runeBit(i)) != 0)
					{
						continue;
					}

					if (i == 1) this.Options.push({ Text = "{The map room.}",       function getResult() { this.Contract.m.RuneAt = 1; return "Rune"; } });
					if (i == 2) this.Options.push({ Text = "{The head of the stair.}", function getResult() { this.Contract.m.RuneAt = 2; return "Rune"; } });
					if (i == 3) this.Options.push({ Text = "{The reading gallery.}",   function getResult() { this.Contract.m.RuneAt = 3; return "Rune"; } });
					if (i == 4) this.Options.push({ Text = "{The cistern room.}",      function getResult() { this.Contract.m.RuneAt = 4; return "Rune"; } });
				}

				this.Options.push({
					Text = c.runesDone() >= 4 ? "{That is all of them. Find Nhyria.}" : "{Enough. Get everyone out of this building.}",
					function getResult()
					{
						this.Contract.resolveArchive();
						return "Report";
					}
				});

				this.Options.push({
					Text = "{Wait.}",
					function getResult() { return 0; }
				});

				if (c.m.HasBracelet)
				{
					this.Options.push({
						Text = "{Crush the bead.}",
						function getResult() { return "Abort"; }
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Rune",
			Title = "The Mark",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local i = c.m.RuneAt;
				if (i < 1 || i > 4)
				{
					i = 1;
					c.m.RuneAt = 1;
				}
				this.List = c.clockRows();
				this.Options = [];

				local where = c.runeName(i);
				local body = "[img]gfx/ui/events/event_98.png[/img]{In " + where + " it is on the wall about shoulder height, in the same wax and the same bad hand as the one in the storeroom, and the plaster under it has gone the colour of a bruise.\n\n";

				if (i == 4)
				{
					body = body + "There is four inches of water on this floor and it was dry this morning. Whatever the rest of the building is doing, this room has started.";
				}
				else if (i == 3)
				{
					body = body + "There is glass on the floor and a desk with nothing on it. This is where the whole thing started, two days and one canal ago.";
				}
				else if (i == 2)
				{
					body = body + "It is drawn across the join of two stones at the head of the stair, which is either clever or lucky, and either way it means the whole stair goes when it closes.";
				}
				else
				{
					body = body + "Charts of the delta, three hundred years of them, in racks from the floor to the ceiling. If this room takes water, that is the end of knowing what this coast used to look like.";
				}

				if (c.m.KnowsRune)
				{
					body = body + "\n\nLast stroke first. The company has done this before.}";
				}
				else
				{
					body = body + "\n\nNobody is sure where to start.}";
				}
				this.Text = body;

				if ((c.m.RunesSearched & c.runeBit(i)) == 0)
				{
					this.Options.push({
						Text = "{Turn the room over first. An hour, and nobody is watching.}",
						function getResult()
						{
							local c2 = this.Contract;
							local n = c2.m.RuneAt;
							c2.m.RunesSearched = c2.m.RunesSearched | c2.runeBit(n);

							local pool = ::Skv.Loot.pool([
								[35, "scripts/items/loot/ornate_tome_item"],
								[20, "scripts/items/loot/silver_bowl_item"],
								[20, "scripts/items/loot/bead_necklace_item"],
								[15, "scripts/items/loot/jade_broche_item"],
								[10, "scripts/items/loot/ancient_gold_coins_item"]
							]);
							local paths = [ pool.roll() ];
							local rows = ::Skv.Loot.haul(::Skv.Loot.make(paths), ::Math.rand(30, 70));

							local out = c2.spend(1.0);
							rows.insert(0, c2.row(true, "An hour spent, and the room gave something up"));

							if (out)
							{
								rows.push(c2.row(false, "And that was the hour you did not have"));
								c2.resolveArchive();
								c2.say("The Mark",
									"[img]gfx/ui/events/event_98.png[/img]{Somebody is still holding a silver bowl when the sound changes.}",
									rows, "Report");
								return "Result";
							}

							c2.say("The Mark",
								"[img]gfx/ui/events/event_98.png[/img]{This is a school, and a school keeps things. Most of it is paper and most of the paper is worth nothing to anybody outside this building - but there are cases, and drawers, and a locked press that is not locked any more.}",
								rows, "Rune");
							return "Result";
						}
					});
				}

				this.Options.push({
					Text = c.m.KnowsRune ? "{Take it apart. Last stroke first.}" : "{Take it apart. Somehow.}",
					function getResult()
					{
						local c2 = this.Contract;
						local n = c2.m.RuneAt;
						local rows = [];
						local cost = c2.runeCost();

						if (!c2.m.KnowsRune)
						{
							local r = ::Skv.Check.wits(c2, ::Skv.Check.scaledBase(c2, 55));
							if (r.ok)
							{
								rows.push(c2.row(true, c2.m.ActorName + " worked out the order from the wax - four hours, and no worse"));
								foreach (x in ::Skv.XP.check(r)) rows.push(x);
							}
							else
							{
								cost = cost + 2.0;
								foreach (x in c2.hurtSome(1, 8, 16)) rows.push(x);
								rows.insert(0, c2.row(false, "It came off wrong and it took two hours longer than it should have"));
							}
						}
						else
						{
							rows.push(c2.row(true, "Backwards, and clean - two hours"));
							foreach (x in ::Skv.XP.partyEach(10)) rows.push(x);
						}

						c2.m.RunesDone = c2.m.RunesDone | c2.runeBit(n);
						c2.m.RuneAt = 0;
						local out = c2.spend(cost);
						rows.push(c2.row(true, c2.runesDone() + " of the four are out"));

						::Skv.dbg("Skv.Threshold: rune " + n + " out, cost " + cost + "h, spent "
							+ c2.m.HoursSpent + "/" + c2.m.HoursLimit);

						if (out || c2.runesDone() >= 4)
						{
							c2.resolveArchive();
							c2.say("The Mark",
								"[img]gfx/ui/events/event_98.png[/img]{The wax comes off the plaster in one piece and goes cold in somebody's hand.}",
								rows, "Report");
							return "Result";
						}

						c2.say("The Mark",
							"[img]gfx/ui/events/event_98.png[/img]{The wax comes off the plaster in one piece and goes cold in somebody's hand, and the room stops doing whatever it had been quietly doing all morning.}",
							rows, "");
						return "Result";
					}
				});

				this.Options.push({
					Text = "{Leave this one. Back to the hall.}",
					function getResult()
					{
						this.Contract.m.RuneAt = 0;
						return "Archive";
					}
				});
			}

		});

		this.m.Screens.push({
			ID = "Hazard",
			Title = "Something In The Lower Gallery",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = c.clockRows();
				this.Options = [];
				c.m.Act2Reads = c.m.Act2Reads | 0x04;

				if (c.m.NgajaDead)
				{
					this.Text = "[img]gfx/ui/events/event_103.png[/img]{The water in the lower gallery is a foot deep now and it is moving against the slope, which water does not do.\n\nWhatever she put in it is still in it. It is not large and it is not quick and it does not appear to want anything except to be between the company and the stair - and it has been in that canal a great deal longer than it has been in this building.}";

					this.Options.push({
						Text = "{Round the long way, through the racks. It costs us time.}",
						function getResult()
						{
							local c2 = this.Contract;
							local rows = [ c2.row(true, "Round it, dry - and two hours poorer") ];
							local out = c2.spend(2.0);
							if (out) { rows.push(c2.row(false, "And that was the last of the time")); c2.resolveArchive(); }
							c2.say("Something In The Lower Gallery",
								"[img]gfx/ui/events/event_103.png[/img]{It takes two hours to get twelve men and one exhausted instructor round three sides of a flooded gallery without any of them going into the water, and every minute of it is audible upstairs.}",
								rows, out ? "Report" : "");
							return "Result";
						}
					});

					this.Options.push({
						Text = "{Straight through it. We have no hours to give away.}",
						function getResult()
						{
							local c2 = this.Contract;
							local rows = c2.hurtSome(2, 8, 18);
							rows.insert(0, c2.row(false, "Through it, and it cost blood instead of hours"));
							c2.say("Something In The Lower Gallery",
								"[img]gfx/ui/events/event_103.png[/img]{Shields down, spears out, and a great deal of shouting in a room built for silence. It goes back under the water in the end and does not come up again where anybody can see it.\n\nTwo men will be picking glass and worse out of their legs for a week.}",
								rows, "");
							return "Result";
						}
					});
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_106.png[/img]{She came up the canal after you.\n\nShe is standing at the bottom of the stair in a foot of her own water with her hands out of it, and she is not tired any more, and it is entirely clear from her face that she has understood what the company is doing upstairs and exactly how little time she needs to undo it.}";

					this.Options.push({
						Text = "{Hold the stair. Nobody goes past.}",
						function getResult()
						{
							local c2 = this.Contract;
							local rows = c2.hurtSome(1, 10, 20);
							rows.insert(0, c2.row(false, "The stair held - three hours and a man half drowned for it"));
							local out = c2.spend(3.0);
							if (out) { rows.push(c2.row(false, "And that was the last of the time")); c2.resolveArchive(); }
							c2.say("Something In The Lower Gallery",
								"[img]gfx/ui/events/event_106.png[/img]{Six feet of stair and a shield wall on it, and three hours of her trying to find a way through six feet of stair. She does not get up it. She does not stop trying until the light changes outside, and then she is simply not there any more.\n\nNobody upstairs got anything done in those three hours either.}",
								rows, out ? "Report" : "");
							return "Result";
						}
					});

					this.Options.push({
						Text = "{Leave her the stair. Keep working.}",
						function getResult()
						{
							local c2 = this.Contract;
							local rows = [];

							local lost = 0;
							for ( local i = 1; i <= 4; i = i + 1 )
							{
								if ((c2.m.RunesDone & c2.runeBit(i)) != 0) { lost = i; break; }
							}
							if (lost != 0)
							{
								c2.m.RunesDone = c2.m.RunesDone & ~c2.runeBit(lost);
								c2.m.RunesSearched = c2.m.RunesSearched | c2.runeBit(lost);
								rows.push(c2.row(false, "She has re-drawn the mark in " + c2.runeName(lost) + " - that work is gone"));
							}
							else
							{
								rows.push(c2.row(false, "She is loose in the building behind you"));
							}

							c2.say("Something In The Lower Gallery",
								"[img]gfx/ui/events/event_106.png[/img]{The company goes back up the stair and gets on with it, and for about a quarter of an hour that feels like the right decision.\n\nThen somebody in " + (lost != 0 ? c2.runeName(lost) : "the gallery") + " says a word that carries the length of the building, and everybody who is not holding something puts their head round a door, and the wax is back on the wall - fresh, and wet, and drawn by a hand that has done it ten thousand times.}",
								rows, "");
							return "Result";
						}
					});
				}
			}

		});

		this.m.Screens.push({
			ID = "Report",
			Title = "The Side Door",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [];
				this.Options = [];

				::Skv.dbg("Skv.Threshold: REPORT screen start() - outcome=" + c.m.Outcome
					+ " runes=" + c.runesDone() + " hours=" + c.m.HoursSpent + "/" + c.m.HoursLimit
					+ " reported=" + c.m.Reported);

				local body = "[img]gfx/ui/events/event_63.png[/img]{";

				if (c.m.Outcome == 1)
				{
					body = body + "The building does not flood.\n\nThat is the whole of it, and it is the sort of thing nobody can be shown. There is no water in the map room and none at the head of the stair, and by the middle of the afternoon the four inches in the cistern room have gone back down the drain they came up, and three hundred years of charts of this coast are exactly where they were on Tuesday.\n\n%SKVNAME%Nhyria%SKVNAME_OFF% walks the four rooms twice. The second time she does it alone.";
				}
				else if (c.m.Outcome == 2)
				{
					body = body + "Most of the building does not flood.\n\nThe cistern room goes, and the floor above it goes with it about an hour later, which nobody had expected and which takes the lower third of the collection into eight feet of canal water in the time it takes to get down one staircase. What is above that line is dry. What is below it is paper in a cistern.\n\n%SKVNAME%Nhyria%SKVNAME_OFF% stands in the doorway of the reading gallery for a long time working out which of those two facts to say first.";
				}
				else
				{
					body = body + "The building floods.\n\nIt happens faster than a building that size has any right to - the marks close within a few minutes of each other and the canal comes up through the floor of the lower gallery like something being poured, and after that it is only a question of how much anybody can carry up a staircase in the dark.\n\nNobody is killed. That is said several times, by several people, in the tone of men who have noticed it is the only thing available to say.";
				}

				if (!c.m.NgajaDead)
				{
					body = body + "\n\nAnd she is not in the canal any more. Whatever she was paid to do here, some of it got done, and the water under this city goes a long way.";
				}

				if (c.m.Students == 1)
				{
					body = body + "\n\nThe two students are somewhere in the house being dealt with by their own, which is a longer and quieter business than anything the company would have done.";
				}
				else if (c.m.Students == 2)
				{
					body = body + "\n\nNobody mentions the two students. The palace has them, and this house will not be asking after them, and everyone standing in this corridor knows both of those things.";
				}
				else if (c.m.Students == 3)
				{
					body = body + "\n\nNobody mentions the two students at all.";
				}

				body = body + "\n\n%SKVNAME%Ot Vaunder%SKVNAME_OFF% is upright, and thinner than he was on Tuesday, and back at work.}";
				this.Text = body;

				local rows = [];
				local pay = c.finalPay();

				if (c.m.Outcome == 1)
				{
					rows.push(c.row(true, "All four marks out, and inside the window"));
				}
				else if (c.m.Outcome == 2)
				{

					rows.push(c.row(false, "The lower gallery is under water - part of the collection is gone"));
				}
				else
				{

					rows.push(c.row(false, "The archive is a cistern - there is nothing to be paid for"));
				}

				rows.push({
					id = 22,
					icon = "ui/icons/special.png",
					text = c.runesDone() + " of four marks out, in " + c.m.HoursSpent.tointeger()
						+ " of " + c.m.HoursLimit + " hours"
				});

				if (pay > 0)
				{
					foreach (r in ::Skv.Loot.previewRows([], pay)) rows.push(r);
				}

				this.List = rows;

				this.Options.push({
					Text = c.m.Outcome == 1 ? "{Good.}" : "{We did what could be done.}",
					function getResult()
					{
						local c2 = this.Contract;
						if (!c2.m.Reported)
						{
							c2.m.Reported = true;
							c2.m.Concluded = true;

							local paid = c2.finalPay();
							if (paid > 0) this.World.Assets.addMoney(paid);

							::Skv.dbg("Skv.Threshold: CONCLUDED outcome=" + c2.m.Outcome + " paid=" + paid
								+ " runes=" + c2.runesDone() + " hours=" + c2.m.HoursSpent + "/" + c2.m.HoursLimit
								+ " ngajaDead=" + c2.m.NgajaDead + " students=" + c2.m.Students);

							this.World.Contracts.finishActiveContract();
						}
						return 0;
					}
				});
			}

		});

	}

	function onClear()
	{
		::Skv.Once.release("Threshold");

		if (this.m.IsActive)
		{
			::Skv.Once.retire("Threshold");

			if (this.m.Home != null && !this.m.Home.isNull())
			{
				this.m.Home.getSprite("selection").Visible = false;
			}

		}
	}

	function onIsValid()
	{
		return true;
	}

	function onPrepareVariables( _vars )
	{
		local nameColor = "#9dbccb";
		_vars.push(["SKVNAME", "[color=" + nameColor + "]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);

		local locColor = "#b39dbc";
		_vars.push(["SKVLOC", "[color=" + locColor + "]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);
	}

	function onSerialize( _out )
	{
		_out.writeU8(this.m.Act);
		_out.writeString(this.m.Leg);

		_out.writeU8(this.m.KnowsRune ? 1 : 0);
		_out.writeU16(this.m.Advantage);
		_out.writeU8(this.m.HasBracelet ? 1 : 0);
		_out.writeU8(this.m.HasCharms ? 1 : 0);

		_out.writeU8(this.m.GiftDone ? 1 : 0);
		_out.writeU8(this.m.Beetles);
		_out.writeU8(this.m.FoundMask);
		_out.writeU8(this.m.FoundNotes);
		_out.writeU8(this.m.Footprints ? 1 : 0);
		_out.writeU8(this.m.ChaseStep);
		_out.writeU8(this.m.ChaseWins);
		_out.writeU8(this.m.ChasePick);
		_out.writeU8(this.m.DoorGate);
		_out.writeU8(this.m.DoorTries);
		_out.writeU8(this.m.DoorHint);
		_out.writeU8(this.m.RuneLesson);

		_out.writeU8(this.m.Gusa);
		_out.writeU8(this.m.Kobolds);
		_out.writeU8(this.m.Swim);
		_out.writeU8(this.m.Jubo);
		_out.writeU8(this.m.Approach);
		_out.writeU8(this.m.GrottoPick);
		_out.writeU8(this.m.Watched ? 1 : 0);
		_out.writeU8(this.m.NgajaDead ? 1 : 0);
		_out.writeU8(this.m.OtFound ? 1 : 0);
		_out.writeU8(this.m.Students);
		_out.writeU8(this.m.Flipped ? 1 : 0);

		_out.writeU8(this.m.Arrived ? 1 : 0);
		_out.writeU16(this.m.ClockDay);
		_out.writeF32(this.m.HoursSpent);
		_out.writeU16(this.m.HoursLimit);
		_out.writeU8(this.m.RunesDone);
		_out.writeU8(this.m.RunesSearched);
		_out.writeU8(this.m.RuneAt);
		_out.writeU8(this.m.Outcome);
		_out.writeU8(this.m.Reported ? 1 : 0);

		_out.writeU8(this.m.Aborted ? 1 : 0);
		_out.writeU8(this.m.Concluded ? 1 : 0);

		_out.writeU8(this.m.DoorKey);
		_out.writeU16(this.m.Act2Reads);
		_out.writeU32(this.m.Res32);
		_out.writeString(this.m.ResStr);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.m.Act = _in.readU8();
		this.m.Leg = _in.readString();

		this.m.KnowsRune   = _in.readU8() == 1;
		this.m.Advantage   = _in.readU16();
		this.m.HasBracelet = _in.readU8() == 1;
		this.m.HasCharms   = _in.readU8() == 1;

		this.m.GiftDone   = _in.readU8() == 1;
		this.m.Beetles    = _in.readU8();
		this.m.FoundMask  = _in.readU8();
		this.m.FoundNotes = _in.readU8();
		this.m.Footprints = _in.readU8() == 1;
		this.m.ChaseStep  = _in.readU8();
		this.m.ChaseWins  = _in.readU8();
		this.m.ChasePick  = _in.readU8();
		this.m.DoorGate   = _in.readU8();
		this.m.DoorTries  = _in.readU8();
		this.m.DoorHint   = _in.readU8();
		this.m.RuneLesson = _in.readU8();

		this.m.Gusa       = _in.readU8();
		this.m.Kobolds    = _in.readU8();
		this.m.Swim       = _in.readU8();
		this.m.Jubo       = _in.readU8();
		this.m.Approach   = _in.readU8();
		this.m.GrottoPick = _in.readU8();
		this.m.Watched    = _in.readU8() == 1;
		this.m.NgajaDead  = _in.readU8() == 1;
		this.m.OtFound    = _in.readU8() == 1;
		this.m.Students   = _in.readU8();
		this.m.Flipped    = _in.readU8() == 1;

		this.m.Arrived       = _in.readU8() == 1;
		this.m.ClockDay      = _in.readU16();
		this.m.HoursSpent    = _in.readF32();
		this.m.HoursLimit    = _in.readU16();
		this.m.RunesDone     = _in.readU8();
		this.m.RunesSearched = _in.readU8();
		this.m.RuneAt        = _in.readU8();
		this.m.Outcome       = _in.readU8();
		this.m.Reported      = _in.readU8() == 1;

		this.m.Aborted   = _in.readU8() == 1;
		this.m.Concluded = _in.readU8() == 1;

		this.m.DoorKey = _in.readU8();
		this.m.Act2Reads = _in.readU16();
		this.m.Res32  = _in.readU32();
		this.m.ResStr = _in.readString();

		this.contract.onDeserialize(_in);
	}

});
