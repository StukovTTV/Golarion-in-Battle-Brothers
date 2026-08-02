this.skv_hollows_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Destination = null,

		HoursSpent  = 0.0,
		DayAccepted = 0,
		Dead        = 0,
		Failed      = false,

		HasMoss   = false,
		HasTail   = false,
		Mushrooms = 0,

		BaitDone    = false,
		PendingSite = "",
		RouteKnown  = false,
		Climbed     = false,
		WyrmDead    = false,
		DeckMask    = 0,
		HasLight    = false,
		WolvesMet   = false,
		KnowsWitch  = false,

		Rooms       = null,
		Room        = "",
		AtSite      = "",
		RuinArrived = false,
		KnowsTorag  = false,
		KnowsNorth  = false,
		RuinMapped  = false,
		SpiderDead  = false,
		GurtDead    = false,
		GurtWarned  = false,
		HasRuby     = false,
		RubyUsed    = false,
		MantlesDone = false,
		BatsDone    = false,
		SecretTried = false,
		SecretFound = false,
		DenDead     = false,
		GraypeltDead = false,
		HasRing     = false,
		Bargain     = 0,
		Errands     = 0,
		ToldShrine  = false,
		Reported    = false

		Sites = null,

		LegHours = {
			Elder    = 6,
			Hut      = 7,
			Crucible = 11
		},

		ReturnHours = {
			Elder    = 4,
			Hut      = 4,
			Crucible = 7
		},

		BudgetGrung = 45,
		BudgetWyrm  = 45,

		BudgetWolves = 60,
		BudgetSpider = 65,
		BudgetGurt   = 45,
		BudgetDen    = 60,
		BudgetGraypelt = 90,
		EncounterChance = 65,

		DeathMarks = [0, 3, 5, 10, 18, 28, 40],

		ActorName  = "",

		ResultRows = null,
		ResultText = "",
		ResultNext = "",
		ResultTitle = "Darkmoon Vale",
		RoadNext   = ""
	},

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_hollows";
		this.m.Name = "Hollow's Last Hope";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 20.0;
		this.m.Category = this.Const.Contracts.Categories.Hunt;
		this.m.ResultRows = [];
		this.m.Sites = {
			Elder    = { Visited = false, Done = false, Step = 0 },
			Hut      = { Visited = false, Done = false, Step = 0 },
			Crucible = { Visited = false, Done = false, Step = 0 }
		};

		this.m.Rooms = {};
		foreach (k in this.roomKeys())
		{
			this.m.Rooms[k] <- { Seen = false, Done = false, Step = 0 };
		}
		this.m.DescriptionTemplates = [
			"A hacking sickness has taken hold in a village at the edge of the wood, and the graves are being dug faster than they can be filled. The local herbalist believes there is a cure, but she lacks three of its ingredients - and all three lie somewhere out in the forest.",
			"Word from a forest village: a fungal blight is in their water and their people are dying of it. Their herbalist has an old recipe and none of what it calls for. She wants someone willing to go into the vale and bring the rest back before the last of the sick are buried."
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(75, 120) * 0.01;

		this.m.Payment.Pool = 120 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		this.m.Payment.Completion = 1.0;
		this.m.Payment.Advance = 0.0;

		this.m.DayAccepted = this.World.getTime().Days;
		this.contract.start();
	}

	function addHours( _h )
	{
		if (_h <= 0)
		{
			return;
		}

		this.m.HoursSpent = this.m.HoursSpent + _h;

		if (::World.Assets != null)
		{
			::World.Assets.m.LastFoodConsumed = ::World.Assets.m.LastFoodConsumed - _h * (this.World.getTime().SecondsPerDay / 24.0);
			::World.Assets.consumeFood();
		}

		this.updateDeathToll();
		::Skv.dbg("Skv.Hollows +" + _h + "h  spent=" + this.m.HoursSpent + "  elapsed=" + this.elapsedDays() + "d  dead=" + this.m.Dead);
	}

	function elapsedDays()
	{
		local real = this.World.getTime().Days - this.m.DayAccepted;
		if (real < 0)
		{
			real = 0;
		}
		return this.m.HoursSpent / 24.0 + real;
	}

	function deathsAt( _days )
	{
		local marks = this.m.DeathMarks;
		if (_days >= marks.len() - 1)
		{
			return marks[marks.len() - 1];
		}
		local i = this.Math.floor(_days);
		local f = _days - i;
		return this.Math.round(marks[i] + (marks[i + 1] - marks[i]) * f);
	}

	function tier()
	{
		local d = this.elapsedDays();
		if (d <= 3.0) return "InTime";
		if (d <= 4.0) return "Late";
		if (d <= 5.0) return "Grim";
		return "Failed";
	}

	function homeName()
	{
		return this.m.Home != null && !this.m.Home.isNull() ? this.m.Home.getName() : "the village";
	}

	function updateDeathToll()
	{
		this.m.Dead = this.deathsAt(this.elapsedDays());

		if (this.m.Dead >= this.m.DeathMarks[this.m.DeathMarks.len() - 1])
		{
			this.m.Failed = true;
		}

		this.m.BulletpointsObjectives = [
			"Gather the three reagents and bring them back to " + this.homeName()
		];
	}

	function haveAll()
	{
		return this.m.HasMoss && this.m.HasTail && this.m.Mushrooms >= 7;
	}

	function reagentLine()
	{
		return "Elderwood moss: " + (this.m.HasMoss ? "carried" : "not found")
			+ "   Rat's tail: " + (this.m.HasTail ? "carried" : "not found")
			+ "   Ironbloom: " + this.m.Mushrooms + " of 7";
	}

	function screenFor( _key )
	{
		if (_key == "Elder")    return "ElderSite";
		if (_key == "Hut")      return "HutSite";
		if (_key == "Crucible") return "CrucibleSite";
		return "Hub";
	}

	function travelTo( _key )
	{
		this.addHours(this.m.LegHours[_key]);
		this.m.AtSite = _key;

		if (!this.m.BaitDone)
		{
			this.m.BaitDone = true;
			this.m.PendingSite = _key;
			return "BaitSite";
		}

		this.m.Sites[_key].Visited = true;

		local card = this.drawCard(_key);
		if (card != "")
		{
			this.m.PendingSite = _key;
			return this.resolveCard(card, _key);
		}

		return this.screenFor(_key);
	}

	function travelToHub( _key )
	{

		this.addHours(this.m.ReturnHours[_key]);
		this.m.AtSite = "";

		local card = this.drawCard(_key);
		if (card != "")
		{
			this.m.PendingSite = "Home";
			return this.resolveCard(card, "Home");
		}

		return "Hub";
	}

	function result( _rows, _text, _next, _title = "Darkmoon Vale" )
	{
		this.m.ResultRows  = _rows;
		this.m.ResultText  = _text;
		this.m.ResultNext  = _next;
		this.m.ResultTitle = _title;
		return "Result";
	}

	function deckIDs()
	{
		return ["wolves", "moorsnake", "snare", "shaman", "mosquito",
		        "woodsmen", "glowmold", "tracks", "fey", "wyvern"];
	}

	function drawCard( _key )
	{
		if (this.Math.rand(1, 100) > this.m.EncounterChance)
		{
			return "";
		}

		local ids = this.deckIDs();
		local avail = [];
		foreach (i, id in ids)
		{
			if ((this.m.DeckMask & (1 << i)) == 0)
			{

				if (id == "wolves" && _key != "Crucible" && this.Math.rand(1, 100) > 20)
				{
					continue;
				}
				avail.push(i);
			}
		}
		if (avail.len() == 0)
		{
			return "";
		}

		local pick = avail[this.Math.rand(0, avail.len() - 1)];
		this.m.DeckMask = this.m.DeckMask | (1 << pick);
		::Skv.dbg("Skv.Hollows card=" + ids[pick] + " leg=" + _key);
		return ids[pick];
	}

	function pickVictim( _injury = "" )
	{
		local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
		if (_injury != "")
		{
			pool = pool.filter(@(_, b) !b.getSkills().hasSkill(_injury));
		}
		if (pool.len() == 0)
		{
			return null;
		}
		return pool[this.Math.rand(0, pool.len() - 1)];
	}

	function hurt( _bro, _min, _max, _injuryScript, _injuryLabel )
	{
		local rows = [];
		if (_bro == null)
		{
			return rows;
		}
		if (_injuryScript != "")
		{
			local inj = ::new(_injuryScript);
			_bro.getSkills().add(inj);
			rows.push({
				id = 10,
				icon = inj.getIcon(),
				text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + _bro.getName() + " " + _injuryLabel + "[/color]"
			});
		}
		_bro.setHitpoints(this.Math.max(1, _bro.getHitpoints() - this.Math.rand(_min, _max)));
		return rows;
	}

	function resolveCard( _id, _key )
	{
		local next = this.screenFor(_key);
		local img  = "[img]gfx/ui/events/event_25.png[/img]";

		if (_id == "wolves")
		{
			this.m.WolvesMet = true;
			return "WolvesCard";
		}

		if (_id == "moorsnake")
		{

			if (this.World.getTime().IsDaytime)
			{
				return this.result([], img + "{Something long and grey-brown slides off a half-sunk log as the company comes down to the water, and is gone under the surface before anyone has finished reaching for a weapon. It is thicker through the body than a man's thigh. Nobody suggests filling the skins here.}", next, "Darkmoon Vale");
			}
			local bro = this.pickVictim();

			local r = ::Skv.Check.brawn(this, ::Skv.Check.scaledBase(this, 55));
			if (r.ok)
			{
				return this.result([], img + "{Something comes into the camp in the black hours and is around %actor% before he is properly awake - cold, and heavier than a man, and tightening. He gets a hand inside the coil before it closes and holds it there, swearing through his teeth, while the watch beats at the thing with a spear-butt until it lets go and pours away into the dark.}", next, "Darkmoon Vale");
			}
			local rows = this.hurt(bro, 8, 18, "scripts/skills/injury/fractured_ribs_injury", "has fractured ribs");
			return this.result(rows, img + "{Something comes into the camp in the black hours. The first anyone knows of it is the sound a man makes when he cannot get enough air to scream. By the time the watch has it off him and driven it back into the water, something in his chest has gone, and the rest of the night is spent listening to him breathe.}", next, "Darkmoon Vale");
		}

		if (_id == "snare")
		{
			local spot = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 50));
			if (spot.ok)
			{
				local rows = ("XP" in ::Skv) ? ::Skv.XP.check(spot) : [];
				return this.result(rows, img + "{%actor% stops the column with a raised fist. Along an overgrown deer trail ahead, a rabbit lies dead in the leaf litter - too neatly, too openly, and with no mark on it. The ground a pace short of it gives back the wrong sound. Under a lattice of sticks and leaves is a pit as deep as a man is tall. Somebody out here lays traps for things bigger than rabbits.}", next, "Darkmoon Vale");
			}
			local bro = this.pickVictim("injury.bruised_leg");
			local rows = this.hurt(bro, 5, 15, "scripts/skills/injury/bruised_leg_injury", "has a bruised leg");
			return this.result(rows, img + "{There is a dead rabbit lying in the leaf litter along an overgrown deer trail, and the man in front walks straight past it and drops out of the world. The pit is as deep as a man is tall and floored with cold mud. He is hauled out filthy, furious and limping, and the rabbit is still lying there, untouched, waiting for the next thing to come down that trail.}", next, "Darkmoon Vale");
		}

		if (_id == "shaman")
		{
			return this.result([], img + "{Something is moving through the trees ahead on a course that takes no account of the ground, the light, or you. It is a kobold, or was: grey, opened up across the belly, and walking with the deliberate aimlessness of a thing with nowhere in particular to be. A rat is living in the ruin of its skull and looks out at the company with mild interest as the two of them go past. Around its neck, on a cord, is a crude wooden board with one word gouged into it in Draconic. The nearest thing to a scholar you have reads it, twice, and reports that it says SHAMAN.\n\nNobody follows it.}", next, "Darkmoon Vale");
		}

		if (_id == "mosquito")
		{
			local bro = this.pickVictim("injury.infected_wound");
			if (this.Math.rand(1, 100) <= 40 && bro != null)
			{
				local rows = this.hurt(bro, 3, 8, "scripts/skills/injury/infected_wound_injury", "has an infected wound");
				return this.result(rows, img + "{The thing that fastens onto the last man in the column is the size of a crow and makes no sound at all. He does not notice until his own shout tells him, and by then it has been drinking long enough to come away fat and unhurried when he crushes it. The wound it leaves is small, and it is already the wrong colour.}", next, "Darkmoon Vale");
			}
			return this.result([], img + "{Something the size of a crow settles silently onto the back of the last man in the column and is halfway to a meal before he feels the weight. He goes over backwards into the brush swearing and comes up with it in both hands, and the thing bursts. The company is a good deal more careful about who walks last after that.}", next, "Darkmoon Vale");
		}

		if (_id == "woodsmen")
		{
			this.m.HoursSpent = this.Math.maxf(0.0, this.m.HoursSpent - 2.0);
			this.updateDeathToll();
			return this.result([], img + "{Three men out of Falcon's Hollow are working this stretch of wood, and they are drunk in the way of men who have been out four days and caught two rabbits. They are delighted to see anybody. They are also, once the talking is done, genuinely useful: between the three of them and a good deal of contradiction they put you on a deer road that runs the way you are going, and save the company the better part of the afternoon.\n\n[color=" + this.Const.UI.Color.PositiveEventValue + "]Two hours saved[/color]}", next, "Darkmoon Vale");
		}

		if (_id == "glowmold")
		{
			local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, 45));
			if (r.ok)
			{
				this.m.HasLight = true;
				local rows = ("XP" in ::Skv) ? ::Skv.XP.check(r) : [];
				return this.result(rows, img + "{The undersides of a cluster of great rocks off the path are furred with something that is quietly, steadily giving off light - a cold green that does not flicker. %actor% works a good sheet of it free without tearing the growth, packs it in a helm lined with moss, and reports that in his experience the stuff keeps burning for days once it is off the stone. Wherever you are going, you will not be going into it blind.}", next, "Darkmoon Vale");
			}
			return this.result([], img + "{The undersides of a cluster of great rocks off the path are furred with something giving off a cold green light. It comes away from the stone in wet handfuls and dies in the palm within a minute, every time, no matter how carefully it is lifted. Eventually the company gives up and moves on, with nothing to show for it but green hands.}", next, "Darkmoon Vale");
		}

		if (_id == "tracks")
		{
			local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, 45));
			if (r.ok)
			{
				local rows = ("XP" in ::Skv) ? ::Skv.XP.check(r) : [];
				return this.result(rows, img + "{%actor% crouches over a line of prints pressed deep into the soft ground and does not say anything for a while. They are cloven, like a goat's, and far too large, and they are set one in front of the other in a way no goat has ever walked - upright, and unhurried, and heavy. He follows them fifty feet to where they stop. Not fade. Stop, mid-stride, in open ground, with nothing overhead and nowhere to go.\n\nHe stands up, looks at the trees for a moment, and suggests the company keep moving.}", next, "Darkmoon Vale");
			}
			return this.result([], img + "{There are marks in the soft ground where something heavy crossed the path. Nobody can make anything of them beyond that, though a couple of the men keep glancing back at them long after the company has moved on.}", next, "Darkmoon Vale");
		}

		if (_id == "fey")
		{
			local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, 40));
			if (r.ok)
			{
				local rows = ("XP" in ::Skv) ? ::Skv.XP.check(r) : [];
				return this.result(rows, img + "{A dead tree beside the path is streaked from crown to root with something that has dried the colours of a spilled rainbow. Three small shapes are pinned to the trunk, arms out. They were people, more or less, once - a hand's length each, wings like a dragonfly's, and every drop of them drawn out, so that what is left has gone hard and grey and grained, like knots of wood.\n\n%actor% has heard of this. Not the killing - the harvest. There is an old story in the low countries that fairy blood, taken fresh and taken all at once, will turn lead into gold, and that the men who believe it never stay believers long, because something always comes looking for them.}", next, "Darkmoon Vale");
			}
			return this.result([], img + "{Three small dead things are pinned to a dead tree beside the path, arms out, dried to grey wood, with something iridescent streaked down the trunk beneath them. Nobody in the company can say what they were, and nobody wants to touch them to find out.}", next, "Darkmoon Vale");
		}

		local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 55));
		if (r.ok)
		{
			local rows = ("XP" in ::Skv) ? ::Skv.XP.check(r) : [];
			return this.result(rows, img + "{The wood goes quiet all at once - not gradually, the way it does for men, but between one step and the next. %actor% is the only one who looks up in time: a shadow crossing the canopy, going fast and low, wings the blue-black of a beetle's back and a tail behind it with a hook on the end. It does not slow and it does not turn. It is hunting something that is not you.\n\nThe birds start again a good while later.}", next, "Darkmoon Vale");
		}
		return this.result([], img + "{For no reason anybody can name, the wood goes completely silent for a count of ten, and then starts up again. The horses would have known what it was. You do not have horses.}", next, "Darkmoon Vale");
	}

	function pickSiteTile()
	{
		local home = this.m.Home.getTile();
		local candidates = this.m.Home.getSurroundingTilesOfType([
			this.Const.World.TerrainType.Forest,
			this.Const.World.TerrainType.LeaveForest,
			this.Const.World.TerrainType.AutumnForest
		], 6);
		local valid = [];
		foreach (t in candidates)
		{
			if (!t.IsOccupied && home.getDistanceTo(t) >= 3)
			{
				valid.push(t);
			}
		}
		if (valid.len() == 0)
		{
			return null;
		}
		return valid[this.Math.rand(0, valid.len() - 1)];
	}

	function roomKeys()
	{
		return ["Yard", "Tower", "EntryHall", "Waiting", "Cloak", "Guest", "Gurtlekep",
		        "Library", "Shrine", "Hallway", "Infested", "Armory", "Prison",
		        "WolfDen", "Graypelt"];
	}

	function roomTitle( _id )
	{
		local t = {
			Yard      = "The Yard",
			Tower     = "The Watchtower",
			EntryHall = "The Entry Hall",
			Waiting   = "The Waiting Room",
			Cloak     = "The Cloak Room",
			Guest     = "The Guest Quarters",
			Gurtlekep = "The Kobold's Room",
			Library   = "The Ruined Library",
			Shrine    = "The Desecrated Shrine",
			Hallway   = "The Long Hallway",
			Infested  = "The Infested Ruins",
			Armory    = "The Armory",
			Prison    = "The Secret Prison",
			WolfDen   = "The Wolf Den",
			Graypelt  = "Graypelt's Chamber"
		};
		return (_id in t) ? t[_id] : "Droskar's Crucible";
	}

	function enterRoom( _id )
	{
		this.m.Room = _id;
		this.m.Rooms[_id].Seen = true;
		return "Ruin";
	}

	function leaveRuin()
	{
		this.m.Room = "";
		this.addHours(3);
		return this.travelToHub("Crucible");
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
			bro.setHitpoints(this.Math.max(1, bro.getHitpoints() - this.Math.rand(_min, _max)));
		}
		return rows;
	}

	function roomExits( _id )
	{
		local g = {
			Yard = [
				{ To = "Tower",     New = "The low door into the squat tower, southeast.", Back = "Back into the tower." },
				{ To = "EntryHall", New = "The double doors, east - the main way in.",    Back = "Back through the double doors." },
				{ To = "Hallway",   New = "The single door, north.",                       Back = "Back through the north door." }
			],
			Tower = [
				{ To = "Yard", New = "Out into the yard.", Back = "Out into the yard." }
			],
			EntryHall = [
				{ To = "Yard", New = "Back out into the yard.", Back = "Back out into the yard." }
			],
			Waiting = [
				{ To = "Cloak",     New = "A low opening at the back of the room - pegs on the wall inside.", Back = "On to the cloak room." },
				{ To = "EntryHall", New = "Back into the entry hall.",                                        Back = "Back into the entry hall." }
			],
			Cloak = [
				{ To = "Guest",   New = "A plain door past the pegs, shut.", Back = "On to the sitting room." },
				{ To = "Waiting", New = "Back to the waiting room.",         Back = "Back to the waiting room." }
			],
			Guest = [
				{ To = "Library", New = "Shattered double doors beyond the table, one of them flat on the floor.", Back = "On to the library." },
				{ To = "Cloak",   New = "Back to the cloak room.",                                                Back = "Back to the cloak room." }
			],
			Gurtlekep = [
				{ To = "Guest", New = "Back into the sitting room.", Back = "Back into the sitting room." }
			],
			Library = [
				{ To = "Shrine", New = "An arch at the far end, and rows of pews beyond it.", Back = "On to the shrine." },
				{ To = "Guest",  New = "Back to the sitting room.",                           Back = "Back to the sitting room." }
			],
			Shrine = [
				{ To = "Library", New = "Back to the library.", Back = "Back to the library." }
			],

			Hallway = [
				{ To = "Infested", New = "A gap where the wall has come down, and cold air out of it.", Back = "On to the fallen study." },
				{ To = "Yard",     New = "Back out into the yard.",                                    Back = "Back out into the yard." }
			],
			Infested = [
				{ To = "Armory",  New = "A low door, iron-banded, still on its hinges.", Back = "On to the armory." },
				{ To = "Hallway", New = "Back into the hallway.",                        Back = "Back into the hallway." }
			],

			Armory = [
				{ To = "Graypelt", New = "A doorway at the far end, and daylight coming through a roof beyond it.", Back = "On to the far chamber." },
				{ To = "WolfDen",  New = "A stone door in the side wall, standing half open on a stink.",           Back = "Aside, into the den." },
				{ To = "Infested", New = "Back to the fallen study.",                                              Back = "Back to the fallen study." }
			],
			Prison = [
				{ To = "Armory", New = "Back out through the armory wall.", Back = "Back out through the armory wall." }
			],
			WolfDen = [
				{ To = "Armory", New = "Back to the armory.", Back = "Back to the armory." }
			],
			Graypelt = [
				{ To = "Armory", New = "Back to the armory.", Back = "Back to the armory." }
			]
		};
		return (_id in g) ? g[_id] : [];
	}

	function isDeepRoom( _id )
	{
		local deep = { Waiting = true, Cloak = true, Guest = true, Gurtlekep = true,
		               Library = true, Shrine = true, Infested = true, Armory = true,
		               Prison = true, WolfDen = true, Graypelt = true };
		return _id in deep;
	}

	function roomText( _id )
	{

		local r = this.m.Rooms[_id];
		local first = (r.Step & 1) == 0;
		r.Step = r.Step | 1;

		if (_id == "Yard")
		{
			if (first) return "[img]gfx/ui/events/event_111.png[/img]{Tall grass and chunks of fallen stone have all but taken the little yard. A wooden stable has gone down on one side into a mound of rotted timber and black straw, and the outer wall to the east has come down with it, leaving a ragged hole a man could walk through.\n\nThree ways out, and the grass is trodden towards none of them in particular: a pair of double doors east, a single door north, and a low door into the squat tower in the corner. Somewhere out of sight a bird is making a noise like a cough.}";
			return "[img]gfx/ui/events/event_111.png[/img]{The yard again, and the grass moving where nothing is walking in it.}";
		}

		if (_id == "Tower")
		{
			if (!this.m.SpiderDead) return "[img]gfx/ui/events/event_98.png[/img]{The door is swollen into its frame and comes open only on the third shoulder, with a crack that goes round the yard and back. Inside: old crates and barrels stacked to the wall, a rickety wooden stair climbing to an open trapdoor thirty feet up - and webbing over all of it, thick as sailcloth, grey with thirty years of dust.\n\nThe dust is moving. Something the size of a war-dog comes down the inside of the webbing head-first, unhurried, and it does not stop coming.}";
			if (first) return "[img]gfx/ui/events/event_98.png[/img]{The base of the tower, and the webbing hanging in torn sheets now. Crates and barrels along the wall. The stair goes up the inside to a trapdoor open on grey sky.}";
			return "[img]gfx/ui/events/event_98.png[/img]{The tower, and the stair going up into the light.}";
		}

		if (_id == "EntryHall")
		{
			if (first) return "[img]gfx/ui/events/event_89.png[/img]{Beyond the double doors is a small dark hall, and a year of dead leaves has blown into it and lain down. Debris in mounds along the walls. Through the middle of it, quite clearly, a narrow path is worn - something goes in and out of this building often enough to keep a track open.\n\nThe hall runs east and ends at a single door that has swollen into its frame and will not be opened politely.}";
			return "[img]gfx/ui/events/event_89.png[/img]{The entry hall, its leaves scuffed into ridges now where the company has crossed it.}";
		}

		if (_id == "Waiting")
		{
			if (first) return "[img]gfx/ui/events/event_87.png[/img]{The door gives with a crack and shatters an ancient chair somebody had propped against it from the inside. The room beyond is dry and dark and smells of dust and old decay.\n\nIn the middle of the floor a dwarf is lying, mummified, in the leather of a working blacksmith. There are the shards of a glass vial in one hand and a scrap of parchment in the other, and he has been there a very long time.}";
			return "[img]gfx/ui/events/event_87.png[/img]{The waiting room, and the dwarf on the floor where he lay down.}";
		}

		if (_id == "Cloak")
		{
			if (first) return "[img]gfx/ui/events/event_74.png[/img]{A small room for the cloaks and hats of visitors. A row of pegs, a few moth-eaten rags still hanging off them, and one soiled hat on a table. Nothing has visited in a long time.}";
			return "[img]gfx/ui/events/event_74.png[/img]{The cloak room, its pegs bare.}";
		}

		if (_id == "Guest")
		{
			if (first) return "[img]gfx/ui/events/event_63.png[/img]{A sitting room, and the only room in this building that anybody has kept: a table and two chairs, both sound. On the table is a half-eaten crow, a crude knife, and a cracked mug.\n\nThere is a door in the far wall, shut.}";
			return "[img]gfx/ui/events/event_63.png[/img]{The sitting room, and the crow going cold on the table.}";
		}

		if (_id == "Gurtlekep")
		{
			if (!this.m.GurtDead) return "[img]gfx/ui/events/event_81.png[/img]{Two beds in a cramped stone cell, one under a drift of bird bones, the other slept in. A sack. An array of old tools laid out in a row with a care nothing else here has been given.\n\nThe thing that comes off the second bed is small, scaled and dog-faced, and it has a shortsword in its hand and its back to a hole in the wall.}";
			if (first) return "[img]gfx/ui/events/event_81.png[/img]{The kobold's cell. Two beds, a sack, and his tools laid out in their row.}";
			return "[img]gfx/ui/events/event_81.png[/img]{The kobold's cell, and the hole in the wall he did not reach.}";
		}

		if (_id == "Library")
		{
			if (first) return "[img]gfx/ui/events/event_15.png[/img]{The double doors into this room are shattered, one of them flat on the floor. What was a library is a wreck: a corner of it has come down entirely and the hole is full of standing black water. Shelves still line the walls, and the books still on them are furred over with a pale grey fungus that has grown out into the room and stopped, as if waiting.}";
			return "[img]gfx/ui/events/event_15.png[/img]{The library, and the water in the corner giving nothing back.}";
		}

		if (_id == "Shrine")
		{
			if (first) return "[img]gfx/ui/events/event_178.png[/img]{Half the roof is down here, and the moon comes through it onto darkwood pews lying tipped over on both sides under a finger of dust. Two of the columns have gone with the roof, and a carved figure that stood between them is in pieces across the flags.\n\nAt the far end, where a shrine ought to have an altar, sits a great ceremonial anvil - and its face has been beaten and scored until whatever was written on it cannot be read.}";
			return "[img]gfx/ui/events/event_178.png[/img]{The shrine, and the ruined anvil at the end of it.}";
		}

		if (_id == "Hallway")
		{
			if (first) return "[img]gfx/ui/events/event_89.png[/img]{The north door comes open onto a corridor that runs the length of the building, and the cold in it is a different cold - moving, and coming from somewhere ahead.\n\nAt the end of it a dwarven statue has been smashed. A monk, by what is left of him: his stone hammer is lying on the flags beside the shattered pieces of his own head, and the pieces have been kicked apart since they fell.\n\nThe floor of this corridor is not dusty. It is worn, in a track down the middle, by something that goes up and down it every day.}";
			return "[img]gfx/ui/events/event_89.png[/img]{The long corridor, and the broken monk at the end of it.}";
		}

		if (_id == "Infested")
		{
			if (first) return "[img]gfx/ui/events/event_89.png[/img]{This was a study once. Now most of the outer wall is down and half the ceiling with it, and the floor is a slope of broken stone that has to be climbed rather than walked.\n\nWhat is left of the roof is black. Not burnt - occupied. It shifts very slightly, all of it together, in a way that a roof should not, and the smell in here is ammonia and old droppings.}";
			return "[img]gfx/ui/events/event_89.png[/img]{The fallen study, and the rubble slope, and whatever is left in the rafters.}";
		}

		if (_id == "Armory")
		{
			if (first) return "[img]gfx/ui/events/event_98.png[/img]{Racks and armour stands under thirty years of cobweb, and not a blade or a breastplate left on any of them. Somebody emptied this room a long time ago and did it thoroughly, which is its own kind of information: somebody got in here before you, and got out again.\n\nOne of the bolt cases has been knocked over and left where it fell.}";
			return "[img]gfx/ui/events/event_98.png[/img]{The armory, its racks bare and its cobwebs torn where the company came through.}";
		}

		if (_id == "Prison")
		{
			if (first) return "[img]gfx/ui/events/event_53.png[/img]{Behind the wall is a short corridor with a wall of bars down one side of it, and four rusted doors standing in the bars, and four cells behind the doors.\n\nThere are dwarves in all four. They have been there a very long time. The locks rusted through long ago - these doors were not what kept them in.}";
			return "[img]gfx/ui/events/event_53.png[/img]{The cells, and the four who were left in them.}";
		}

		if (_id == "WolfDen")
		{
			if (!this.m.DenDead) return "[img]gfx/ui/events/event_25.png[/img]{The high priest wrote his sermons in this room. There is a stone desk in the middle of it still, scratched to ruin, and the floor around it is gnawed bones and grey fur and the wet-fur stink of a den in use.\n\nTwo shapes come up from behind the desk where they were sleeping. They are big, and they are not surprised, and they do not bark.}";
			if (first) return "[img]gfx/ui/events/event_25.png[/img]{The old study, the scratched stone desk, and the bones the two of them left.}";
			return "[img]gfx/ui/events/event_25.png[/img]{The den, quiet now.}";
		}

		if (_id == "Graypelt")
		{
			if (this.m.GraypeltDead) return "[img]gfx/ui/events/event_118.png[/img]{His chamber, and the light coming down through the holes in the roof onto what is left of him.}";
			if (first) return "[img]gfx/ui/events/event_118.png[/img]{Holes in the roof let grey light down into a wide ruined chamber. One of the stone columns has come down and lies broken across the floor.\n\nIn the far corner, out of the light, there is a patch of black mushrooms growing in the damp - and the company can count them from the doorway, because there are not many. Six.\n\nThe seventh thing in the room is on top of the fallen column, and it has been watching the doorway since before anybody came through it. It is a wolf the size of a pony, grey through to white at the muzzle, and when it has let the silence run exactly as long as it wants to, it speaks.}";
			return "[img]gfx/ui/events/event_118.png[/img]{The far chamber, the fallen column, and the grey thing on top of it.}";
		}

		return "[img]gfx/ui/events/event_89.png[/img]{Stone, dark, and the smell of a building that has outlived its people.}";
	}

	function roomList( _id )
	{
		return [
			{ id = 1, icon = "ui/icons/asset_money.png", text = "Ironbloom: " + this.m.Mushrooms + " of 7" },
			{ id = 2, icon = "ui/icons/special.png", text = "Dead in " + this.homeName() + ": " + this.m.Dead }
		];
	}

	function yardSearch()
	{
		this.addHours(1);
		this.m.Rooms.Yard.Done = true;

		local rows = ::Skv.Loot.haul([], 42);

		local extra = "";
		local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, 45));
		if (r.ok)
		{

			local items = ::Skv.Loot.make(["scripts/items/supplies/medicine_item"]);
			if (items.len() > 0)
			{
				items[0].setAmount(::Math.max(1, ::Math.floor(items[0].getAmount() / 2)));
			}
			foreach (row in ::Skv.Loot.haul(items, 0)) rows.push(row);

			extra = "\n\n%actor% reads the ground where the grass is bent and gets two answers, not one. Something long and low goes in and out by the main doors and away into the wild - it does not live here. Something four-legged and heavy uses the main doors AND the hole in the east wall, and it lives here, and there are a great many of it.\n\nHe goes back to the dead man afterwards and turns out the rest of the pack properly, which nobody had thought to do: under the bedroll, wrapped against the damp, is half a surgeon's kit - gut, needles, a stoppered vial and clean linen, carried by a man who expected to need it.";
			local xp = ::Skv.XP.check(r);
			foreach (row in xp) rows.push(row);
			this.m.KnowsNorth = true;
		}

		return this.result(rows, "[img]gfx/ui/events/event_111.png[/img]{The grass hides more than it looks able to. There is a well in the north-west corner with ten feet of rope still on it and the water more than thirty feet down, brackish and drinkable. The stable's bones turn out to be a pony's.\n\nAnd beside the well there is a man, or was, a year or so ago. He has been opened from the shoulder to the hip by something with a mouth big enough to do it in one, and he was not robbed afterwards: his pack is still under him, and there is coin in it." + extra + "}", "Ruin", "The Yard");
	}

	function towerStair()
	{
		this.addHours(1);
		this.m.Rooms.Tower.Done = true;

		local r = ::Skv.Check.agility(this, ::Skv.Check.scaledBase(this, 45));
		if (r.ok)
		{
			this.m.RuinMapped = true;
			local rows = ::Skv.XP.check(r);
			return this.result(rows, "[img]gfx/ui/events/event_98.png[/img]{%actor% goes up the stair a tread at a time with his weight where the wall is, and it holds him, and he puts his head out of the trapdoor into the wind.\n\nFrom up there the whole building lies open like a drawing of itself: the yard and its well, the long hall running east off the double doors and the rooms hung along it, and - through the fallen roof on the north side - a corridor running the length of the building with four more chambers off it, one of them very large, its floor black with something that has been dragged in and eaten there. He is a while coming down, and he takes the shape of the place down with him.}", "Ruin", "The Watchtower");
		}

		local rows = this.hurtSome(1, 10, 22, "scripts/skills/injury/bruised_leg_injury", "has a badly bruised leg", "injury.bruised_leg");
		return this.result(rows, "[img]gfx/ui/events/event_98.png[/img]{%actor% is four treads from the trapdoor when the stair remembers how old it is. It goes in the middle, all at once, and takes him down with it in a slide of rotten timber and thirty years of dust, and the men below get out from under it rather than catch him.\n\nHe is helped up swearing. The stair is a heap. Nobody is going up there today.}", "Ruin", "The Watchtower");
	}

	function towerCrates()
	{
		this.addHours(1);
		this.m.Rooms.Tower.Step = this.m.Rooms.Tower.Step | 2;

		local items = ::Skv.Loot.make(["scripts/items/weapons/shortsword"]);
		if (items.len() > 0) this.enhance(items[0], 0, true);
		local rows  = ::Skv.Loot.haul(items, 0);
		return this.result(rows, "[img]gfx/ui/events/event_98.png[/img]{Most of what the dwarves stored down here went to powder a long time ago - grain, cloth, whatever was in the barrels, all of it gone to a grey dust that comes up round the boots. One small crate has held, because it was packed properly by someone who cared: a short blade wrapped in oiled cloth, laid straight, and not a spot of rust on it in thirty years. It is nobody's heirloom, but it is not an ordinary blade either: the edge is even along its whole length, the tang is properly peened, and it has the balance of something a good smith took his time over. Somebody greased it and put it away, and then did not come back for it.}", "Ruin", "The Watchtower");
	}

	function hallTracks()
	{
		this.addHours(1);
		this.m.Rooms.EntryHall.Done = true;

		local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, 40));
		if (!r.ok)
		{
			return this.result([], "[img]gfx/ui/events/event_89.png[/img]{The leaves are a year deep and they have been walked through by everything in the vale. Whatever the path through them means, nobody here can read it.}", "Ruin", "The Entry Hall");
		}

		this.m.KnowsNorth = true;
		local rows = ::Skv.XP.check(r);
		return this.result(rows, "[img]gfx/ui/events/event_89.png[/img]{%actor% squats in the middle of the hall and puts his hand flat on the leaf-mould without disturbing it.%SPEECH_ON%Two sorts. Something with claws and a long tail that comes in the front and goes out the front, and does not stay. And dogs - wolves - and they do stay, and every one of them turns north out of this hall. That is where they live. Whatever else is in this building, that is where the most of it is.%SPEECH_OFF%}", "Ruin", "The Entry Hall");
	}

	function waitingDwarf()
	{
		this.addHours(1);
		this.m.Rooms.Waiting.Done = true;

		local items = ::Skv.Loot.make(["scripts/items/loot/silverware_item"]);
		local rows  = ::Skv.Loot.haul(items, 0);

		local extra = "";
		local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, 40));
		if (r.ok)
		{
			this.m.KnowsTorag = true;
			local xp = ::Skv.XP.check(r);
			foreach (row in xp) rows.push(row);
			extra = "\n\n%actor% turns the hammer over twice and does not much like it. %SPEECH_ON%This is a smith's god, and it is not the smith's god you are thinking of. The good one takes an anvil and a hammer laid crossed. This one is a hammer alone, with a whip beside it. Toil, and nothing at the end of the toil. Whoever kept this house changed gods at some point, and they did not change to a better one.%SPEECH_OFF%";
		}

		return this.result(rows, "[img]gfx/ui/events/event_87.png[/img]{The parchment in his hand is dwarven, and short, and the ink has held: FORGIVE ME, DARK FATHER OF THE FORGE. MY TOILS SHALL NEVER BE ENOUGH.\n\nHe drank whatever was in the vial and lay down in the guest room to do it, which says something about how he felt regarding the rest of the house. Tucked into his belt is a light hammer of worked silver with a god's mark cut into the head, worth taking on the weight of the metal alone." + extra + "}", "Ruin", "The Waiting Room");
	}

	function cloakSearch()
	{
		this.addHours(1);
		this.m.Rooms.Cloak.Done = true;

		local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 50));
		if (!r.ok)
		{
			return this.result([], "[img]gfx/ui/events/event_74.png[/img]{Rags, a hat, and pegs. Whatever was worth having in this room went out of it on somebody's back a long time ago.}", "Ruin", "The Cloak Room");
		}

		this.m.Mushrooms = this.m.Mushrooms + 1;
		local rows = ::Skv.XP.check(r);
		rows.push({ id = 11, icon = "ui/icons/asset_supplies.png", text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]One ironbloom mushroom[/color]" });
		return this.result(rows, "[img]gfx/ui/events/event_74.png[/img]{%actor% is the one who thinks to look under the table rather than on it, in the corner where the damp comes through the outside wall and the stone is dark with it.\n\nIt is the size of a thumb-joint, dull orange, and heavier than a mushroom has any business being - it weighs in the hand like a musket ball. Laurel's book wants seven. This is one.}", "Ruin", "The Cloak Room");
	}

	function enterGuest()
	{
		local r = this.m.Rooms.Guest;
		this.m.Room = "Guest";
		r.Seen = true;

		if ((r.Step & 2) != 0)
		{
			return "Ruin";
		}
		r.Step = r.Step | 2;

		local spot = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 45));
		if (spot.ok)
		{

			local rows = ::Skv.XP.check(spot);
			local items = ::Skv.Loot.make(["scripts/items/tools/throwing_net"]);
			local haul = ::Skv.Loot.haul(items, 0);
			foreach (row in haul) rows.push(row);

			return this.result(rows, "[img]gfx/ui/events/event_63.png[/img]{%actor% has a hand up before the door is a foot open. There is a cord at shin height across the frame, waxed, tied off at both ends, and it goes up into the dark of the ceiling where somebody has slung a net full of stones and a small iron anvil.\n\nIt is cut down slowly, one corner at a time, with two men taking the weight so the stones do not come out of it all at once. The room is then entered like a room instead of like a trap.\n\nAnd the net itself is worth having. Whoever knotted it knew the work - small mesh, waxed cord, weighted at the hem - and it goes into the company's kit, because a man who can throw one of these over a charging animal is worth two who cannot. Whoever set it is close, does not sleep well, and is afraid of something in this building.}", "Ruin", "The Guest Quarters");
		}

		this.m.GurtWarned = true;
		local rows = this.hurtSome(2, 6, 14, "", "");
		return this.result(rows, "[img]gfx/ui/events/event_63.png[/img]{The door opens outward and the cord across the bottom of it goes taut, and the ceiling comes down.\n\nIt is a net, and it is full of stones and one small iron anvil, and it lands on the two men in the doorway with a noise like a cart tipping. Nothing is broken that will not mend. But the noise goes down the hall and round the corner and into every room in this building, and somewhere behind the far door something small stops moving and starts listening.}", "Ruin", "The Guest Quarters");
	}

	function enterShrine()
	{
		local r = this.m.Rooms.Shrine;
		this.m.Room = "Shrine";
		r.Seen = true;

		if (this.m.MantlesDone)
		{
			return "Ruin";
		}
		this.m.MantlesDone = true;

		local dc = this.m.HasLight ? 50 : 40;
		local dodge = ::Skv.Check.agility(this, ::Skv.Check.scaledBase(this, dc));
		if (dodge.ok)
		{
			local safe = ::Skv.XP.check(dodge);
			return this.result(safe, "[img]gfx/ui/events/event_178.png[/img]{The lamps go out. Not blown out - out, all of them together, and the dark that replaces them is thicker than the dark outside, and it is only in this room.\n\n%actor% does not wait to be told what that means. He has the second man through the arch by the collar and off his feet before the ceiling finishes letting go, and the thing that was meant for that man's head hits the flags instead and lies there for a moment looking like a dropped cloak.\n\nAfter that it is butcher's work, done by men who can see it coming: they are the size of cloaks, they have no faces, and they are unbelievably strong, but a thing that has missed its drop is only strong. It is over in half a minute. The lamps come back on their own as what is left of the pair goes up into the roof and stops moving.}", "Ruin", "The Desecrated Shrine");
		}

		local rows = this.hurtSome(2, 10, 20, "scripts/skills/injury/severe_concussion_injury", "has a severe concussion", "injury.severe_concussion");
		return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{The lamps go out. Not blown out - out, all of them together, and the dark that replaces them is thicker than the dark outside, and it is only in this room.\n\nThen something comes off the ceiling onto the second man through the arch and folds itself round his head, and he goes down on the flags with it. There is another. They are the size of cloaks and they have no faces and they are unbelievably strong, and getting them off takes knives, and the knives cannot be swung with any conviction while the thing is wrapped round a friend's skull.\n\nIt is over in half a minute. Two men are sat down hard against a pew, and the lamps come back on their own as whatever was left of the pair goes back up into the roof and stops moving.}", "Ruin", "The Desecrated Shrine");
	}

	function openGurtDoor()
	{
		this.addHours(1);
		this.m.Room = "Gurtlekep";
		this.m.Rooms.Gurtlekep.Seen = true;

		local r = ::Skv.Check.lockpick(this, ::Skv.Check.scaledBase(this, 40));
		if (r.ok)
		{
			local rows = ::Skv.XP.check(r);
			return this.result(rows, "[img]gfx/ui/events/event_63.png[/img]{The lock is old enough that it barely deserves the name, and %actor% has it over in under a minute with the door held hard against its frame so the tongue does not snap back and announce itself.\n\nIt comes open on a black room that smells of bird.}", "Ruin", "The Guest Quarters");
		}

		this.m.GurtWarned = true;
		return this.result([], "[img]gfx/ui/events/event_63.png[/img]{The lock is old and the wards inside it are rusted into a shape no pick was ever cut for, and after a while of quiet swearing the quiet part is given up on.\n\nIt takes two men and three goes, and the third one takes the frame with it. Whatever is on the other side of that door has had a count of thirty to decide what to do about it.}", "Ruin", "The Guest Quarters");
	}

	function findRuby()
	{
		if (::World.Assets == null)
		{
			return null;
		}

		local stash = ::World.Assets.getStash();
		if (stash == null)
		{
			return null;
		}

		foreach (it in stash.getItems())
		{
			if (it != null && it.getID() == "misc.skv_cut_ruby")
			{
				return it;
			}
		}
		return null;
	}

	function hasRuby()
	{
		return this.findRuby() != null;
	}

	function gurtSack()
	{
		this.addHours(1);
		this.m.Rooms.Gurtlekep.Done = true;
		this.m.HasRuby = true;

		local items = ::Skv.Loot.make(["scripts/items/misc/legend_masterwork_tools", "scripts/items/loot/skv_cut_ruby"]);
		local rows  = ::Skv.Loot.haul(items, 62);

		return this.result(rows, "[img]gfx/ui/events/event_81.png[/img]{The sack holds coin, most of it old, and a set of stonemason's tools good enough that a guild would ask where they came from.\n\nAnd at the bottom, wrapped in a rag by itself, one cut ruby the size of a thumbnail. It has been kept apart from the coin - which means the little creature knew it was different, and did not know why, and kept it anyway.}", "Ruin", "The Kobold's Room");
	}

	function libraryShelves()
	{
		this.addHours(1);
		this.m.Rooms.Library.Done = true;

		local rows = [];
		local prize = "\n\nAnd the book at the top of the last shelf was never reached by the fur: dwarven, illuminated in gold leaf and lamp-black, hymns to a god whose name has been beaten off an anvil in the next room but is written out perfectly plainly here. Folded into the back is a single page of prayer, in another hand entirely.";

		local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 45));
		if (r.ok)
		{
			local items = ::Skv.Loot.make(["scripts/items/loot/ornate_tome_item"]);
			rows = ::Skv.Loot.haul(items, 0);
			local xp = ::Skv.XP.check(r);
			foreach (row in xp) rows.push(row);
			return this.result(rows, "[img]gfx/ui/events/event_15.png[/img]{%actor% stops the first man with a hand on his wrist before the book is off the shelf. The grey fur on the spines is not mould. Looked at closely it is fruiting - the whole shelf is furred with little grey heads all turned the same way, into the room.\n\nSo it is done at arm's length, with cloth over every face and the shutters broken out for the draught, and the puffs that come off the books go up and out instead of into anybody. Nobody breathes properly until they are back in the hall." + prize + "}", "Ruin", "The Ruined Library");
		}

		local hurt = this.hurtSome(3, 8, 16, "", "");
		foreach (row in hurt) rows.push(row);
		return this.result(rows, "[img]gfx/ui/events/event_15.png[/img]{The first book comes off the shelf and the fur on it lets go all at once - a soft grey cloud that is across the room before anybody has thought to move, and then it is in every mouth and every eye.\n\nIt is not fatal. It is a bad quarter of an hour on hands and knees in the doorway, and a headache that will last the day, and for hours afterwards the men keep turning to look at something moving at the edge of their sight that is not there when they look.\n\nNobody goes back in for the top shelf.}", "Ruin", "The Ruined Library");
	}

	function shrineAnvil()
	{
		local rows = [];
		if (this.m.KnowsTorag)
		{
			return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{It is the same mark as the hammer on the dead smith in the waiting room - the good one, the crossed hammer and anvil - and it has been beaten off the face of this anvil with something heavy, over and over, by somebody who had the time to be thorough.\n\nSet into the top of it are five small round depressions. Four are empty. The fifth has been empty a long time too, but the stone around it is a different colour, the way a ring's mark stays on a finger.}", "Ruin", "The Desecrated Shrine");
		}

		local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, 40));
		if (!r.ok)
		{
			return this.result([], "[img]gfx/ui/events/event_178.png[/img]{Somebody has taken a great deal of trouble to ruin the face of this anvil, and nobody here can say what was on it before they started. Set into the top of it are five small round depressions, all of them empty.}", "Ruin", "The Desecrated Shrine");
		}

		this.m.KnowsTorag = true;
		rows = ::Skv.XP.check(r);
		return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{%actor% gets down on his heels in front of it with a thumb on the scoring. %SPEECH_ON%This was a smith-god's house, and the anvil IS the altar - that is how they do it. Somebody has hammered the mark off the face of it and left the thing standing, which is not what you do to a god you have stopped believing in. That is what you do to one you have taken up against.%SPEECH_OFF%Set into the top are five small round depressions. All five are empty, and one of them is a different colour underneath.}", "Ruin", "The Desecrated Shrine");
	}

	function shrineRuby()
	{

		local ruby = this.findRuby();
		if (ruby == null)
		{
			return "Ruin";
		}
		::World.Assets.getStash().remove(ruby);

		this.m.RubyUsed = true;
		this.addHours(1);

		local rows = [];
		local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
		foreach (bro in pool)
		{
			local before = bro.getHitpoints();
			bro.setHitpoints(this.Math.min(bro.getHitpointsMax(), before + this.Math.rand(8, 14)));
			local gain = bro.getHitpoints() - before;
			if (gain > 0)
			{
				rows.push({
					id = 13,
					icon = "ui/icons/health.png",
					text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]" + bro.getName() + " recovers " + gain + " health[/color]"
				});
			}

			rows.push(::Legends.EventList.changeMood(bro, 1.0, "Heard the dwarves sing under Droskar's Crag"));
		}

		return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{The ruby goes into the depression it was cut for and sits down into it with a small sound like a latch.\n\nWhat comes out of the anvil is not light. It is a note - one note, held, sung by a great many voices in a language nobody in the company has ever heard, and it is coming from inside the stone. It goes through the room and through the men in it, and where it passes, wounds that were bleeding this morning are closed and pink, and the ache goes out of the ones that were carried in.\n\nIt lasts as long as a breath and then the shrine is a cold ruin again. The ruby has gone the colour of a dirty window. It is still a ruby, and it is still worth what a ruby is worth. It is simply not that any more.}", "Ruin", "The Desecrated Shrine");
	}

	function shrineSearch()
	{
		this.addHours(1);
		this.m.Rooms.Shrine.Done = true;

		if (!this.m.ToldShrine)
		{
			local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 50));
			if (!r.ok)
			{
				return this.result([], "[img]gfx/ui/events/event_178.png[/img]{Dust, pews, and the cold coming up out of the floor. If anything grows in this room it is not growing where anyone here thinks to look.}", "Ruin", "The Desecrated Shrine");
			}
		}

		this.m.Mushrooms = this.m.Mushrooms + 1;
		local rows = [];
		rows.push({ id = 11, icon = "ui/icons/asset_supplies.png", text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]One ironbloom mushroom[/color]" });
		return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{Dark places thick with metal - that is what the herbalist said, and there is no place in this building thicker with metal than the foot of a ceremonial anvil that has stood on the same flagstone for four hundred years.\n\nA man goes down on his belly with a knife and comes up with it: one ironbloom, dull orange, grown in the crack where the anvil's footing meets the floor, in the dark, out of the rust.}", "Ruin", "The Desecrated Shrine");
	}

	function enhance( _item, _tier = 0, _masterwork = false )
	{
		if (_item == null)
		{
			return _item;
		}
		if (!("GolarionEnchant" in ::getroottable()))
		{
			return _item;
		}

		try
		{
			if (_tier > 0) ::GolarionEnchant.apply(_item, _tier);
			else if (_masterwork) ::GolarionEnchant.setMasterwork(_item, true);
		}
		catch (e)
		{
			::logError("Skv.Hollows enhance failed: " + e);
		}
		return _item;
	}

	function finalPay()
	{

		local pay = this.m.Payment.getOnCompletion();
		local t = this.tier();
		if (t == "Late") pay = pay * 0.8;
		if (t == "Grim") pay = pay * 0.4;
		return this.Math.floor(pay);
	}

	function ruinCombat( _id, _terrain )
	{
		local p = ::Const.Tactical.CombatInfo.getClone();
		p.CombatID = _id;
		p.TerrainTemplate = _terrain;
		p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
		p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Circle;
		p.IsWithoutAmbience = true;

		p.Entities = [];
		return p;
	}

	function alarm()
	{
		return (this.m.Rooms.Infested.Step & 4) != 0 ? 1.15 : 1.0;
	}

	function batSwarm()
	{
		this.m.BatsDone = true;

		local spot = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 45));
		if (spot.ok)
		{
			local rows = ::Skv.XP.check(spot);
			return this.result(rows, "[img]gfx/ui/events/event_89.png[/img]{%actor% has the column stopped before the second man is off the rubble, and points up without saying anything. The ceiling is not black with soot.\n\nThe module for crossing a floor under four hundred sleeping bats is not stealth, it is FOOTING: what wakes them is a slab going over. So it is done one man at a time, weight tested on every stone before it is trusted, nothing dropped, nothing kicked, and no armoured man allowed to jump the last yard - the better part of an hour to cross a room eight paces wide. The roof shifts once, resettles, and stays where it is.}", "Ruin", "The Infested Ruins");
		}

		this.m.Rooms.Infested.Step = this.m.Rooms.Infested.Step | 4;

		local rows = this.hurtSome(3, 5, 12, "", "");
		return this.result(rows, "[img]gfx/ui/events/event_89.png[/img]{Somebody puts his weight on a slab halfway up the rubble that has nothing under it, and it goes down four feet into the cellar with a noise like a door slamming in a church - and the whole ceiling comes off at once.\n\nIt is not a fight. There is nothing to hit. It is four hundred bats in a room with eight men, and the men go down on the floor with their arms over their faces and stay there while it goes over them and out through the hole in the wall, and it takes a long time to pass. When it is gone there is blood on two or three faces and a great deal of dignity left on the flags.\n\nThey do not come back. But every living thing on this side of the building heard them go.}", "Ruin", "The Infested Ruins");
	}

	function armorySearch()
	{
		this.addHours(1);
		this.m.Rooms.Armory.Done = true;

		local items = ::Skv.Loot.make(["scripts/items/ammo/legend_armor_piercing_bolts"]);
		if (items.len() > 0) this.enhance(items[0], 1);
		local rows  = ::Skv.Loot.haul(items, 0);
		return this.result(rows, "[img]gfx/ui/events/event_98.png[/img]{The looters took the racks down to the wood and the cases down to the straw, and they did it in a hurry - which is why the bolts that went under the bottom rack when they knocked the case over are still under the bottom rack.\n\nGood ones, too, and dry - and heavier in the head than they ought to be, with a bodkin point made for going through plate rather than through a boar. Held up to what light there is, the heads have something worked into the metal in a script nobody here reads, and they are warm.\n\nThere are as many as there are. Nobody is making more.}", "Ruin", "The Armory");
	}

	function armorySecret()
	{
		this.addHours(1);
		this.m.SecretTried = true;

		local r = ::Skv.Check.secretDoor(this, ::Skv.Check.scaledBase(this, 50));
		if (!r.ok)
		{
			return this.result([], "[img]gfx/ui/events/event_98.png[/img]{The walls are gone over a hand's breadth at a time, and the floor, and the backs of the racks. Cold stone, cobweb, and the marks where the armour stands stood.\n\nIf this room is keeping anything, it keeps it.}", "Ruin", "The Armory");
		}

		this.m.SecretFound = true;
		local rows = ::Skv.XP.check(r);
		return this.result(rows, "[img]gfx/ui/events/event_98.png[/img]{%actor% is not looking for a door. He is looking at the cobwebs - at the north-east corner, where thirty years of them hang in a straight vertical line and not a spider in the world would build them that way.\n\nThere is a draught coming through. The stone swings inward on a pivot when the right block is leaned on, and behind it is a passage that was cut after this building was finished, by someone who did not want it found.}", "Ruin", "The Armory");
	}

	function prisonCells()
	{
		this.m.Rooms.Prison.Done = true;
		this.m.HasRing = true;
		this.m.Mushrooms = this.m.Mushrooms + 2;

		local items = ::Skv.Loot.make(["scripts/items/accessory/skv_ring_of_torag"]);
		local rows  = ::Skv.Loot.haul(items, 0);
		rows.push({ id = 11, icon = "ui/icons/asset_supplies.png", text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]Two ironbloom mushrooms[/color]" });

		return this.result(rows, "[img]gfx/ui/events/event_53.png[/img]{Three of them come off the straw as the first door swings, and they are quick about it for men who have been dead four centuries. No weapons - the leather aprons are still on them, and they use their hands. It is short and it is ugly and it is over.\n\nThe fourth does not move, and did not, and is lying on his cot in a way none of the others are: on his back, arms folded, composed. Somebody arranged him, and there was nobody in here to do it but himself.\n\nOn his hand is a gold ring with a red stone in it, and the stone still has something moving in it. And growing up through the bars of his ribcage, in the dark, out of four hundred years of him - two ironbloom mushrooms.}", "Ruin", "The Secret Prison");
	}

	function denDesk()
	{
		this.addHours(1);
		this.m.Rooms.WolfDen.Done = true;

		local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 45));
		if (!r.ok)
		{
			return this.result([], "[img]gfx/ui/events/event_25.png[/img]{The desk is empty but for a few scraps of parchment gone to lace and a quill nobody has held since the dwarves. The drawers come out and go back in. There is nothing in this room but bones and the smell.}", "Ruin", "The Wolf Den");
		}

		local items = ::Skv.Loot.make(["scripts/items/weapons/hand_axe", "scripts/items/loot/ornate_tome_item"]);
		if (items.len() > 0) this.enhance(items[0], 1);
		local rows  = ::Skv.Loot.haul(items, 240);
		local xp = ::Skv.XP.check(r);
		foreach (row in xp) rows.push(row);

		return this.result(rows, "[img]gfx/ui/events/event_25.png[/img]{%actor% takes the middle drawer all the way out and turns it over, which is how you find the ones with false backs.\n\nCoin - good coin, the heavy old kind. A hand-axe wrapped in oiled leather, which comes out of the wrapping cold and stays cold, and which puts a nick in the stone desk-top when somebody sets it down too hard. And a prayer book, dwarven, describing the worship of the Dark Smith in a careful hand. Inside the cover somebody has written a single line, and it is not scripture: TORAG IS NO LONGER WORTHY OF OUR DEVOTION. ONLY DROSKAR CAN DELIVER US FROM THE FAILINGS OF KING GARBOLD.\n\nSo that is what happened here. Not a conquest. A vote.}", "Ruin", "The Wolf Den");
	}

	function errandsLeft()
	{
		local n = 0;
		if (!this.m.MantlesDone) n = n + 1;
		if (!this.m.BatsDone)    n = n + 1;
		if (!this.m.SpiderDead)  n = n + 1;
		return n;
	}

	function graypeltSpeaks()
	{
		this.m.Bargain = 1;
		local left = this.errandsLeft();

		if (left == 0)
		{
			return this.result([], "[img]gfx/ui/events/event_178.png[/img]{%SPEECH_ON%You have come a long way for mushrooms,%SPEECH_OFF% it says, and its voice is a man's voice used by something that is not one. %SPEECH_ON%I am reasonable. There are things in this house I would be rid of - the ones on the shrine ceiling, the ones in the rafters, the fat one in the tower. Clear them out and the corner is your--%SPEECH_OFF%It stops. Its ears have gone back. Somewhere under that grey skull it is running through the building room by room and finding all three of them already done, by the men standing in its doorway, before it had thought to ask.\n\nThe silence goes on a beat too long for anybody to pretend it did not happen.}", "Ruin", "Graypelt's Chamber");
		}

		return this.result([], "[img]gfx/ui/events/event_178.png[/img]{%SPEECH_ON%You have come a long way for mushrooms,%SPEECH_OFF% it says, and its voice is a man's voice used by something that is not one. %SPEECH_ON%I know what you are. I have eaten four of you. But I am reasonable, and there are things in this house I would be rid of.%SPEECH_OFF%It does not name all of them. It names one, and waits to see whether you go and do it.}", "Ruin", "Graypelt's Chamber");
	}

	function graypeltErrand()
	{
		this.m.Bargain = 2;
		this.m.Errands = this.m.Errands + 1;

		if (!this.m.MantlesDone)
		{
			this.m.Room = "Shrine";
			this.m.Rooms.Shrine.Seen = true;

			local told = "";
			if (!this.m.Rooms.Shrine.Done && this.m.Mushrooms < 7)
			{
				this.m.ToldShrine = true;
				told = "%SPEECH_ON%And since you are going: there is one of your toadstools growing at the foot of that anvil, in the crack where it meets the floor. I have no use for it. Bring me the ceiling and take it with my blessing.%SPEECH_OFF%It says it the way a man mentions the weather, and every one of you hears the arithmetic in it: six in his corner, one under the anvil, and the herbalist wants seven.\n\n";
			}

			return this.result([], "[img]gfx/ui/events/event_178.png[/img]{%SPEECH_ON%The shrine, then. There are two things on that ceiling that come down on whatever walks under it, and they have been there longer than I have.%SPEECH_OFF%" + told + "It is a long walk back through a building you have already crossed once, and nobody enjoys it. The pews are where they were. The anvil is where it was.\n\nAnd the lamps go out.}", "Ruin", "The Desecrated Shrine");
		}

		if (!this.m.BatsDone)
		{
			this.m.Room = "Infested";
			this.m.Rooms.Infested.Seen = true;
			return this.result([], "[img]gfx/ui/events/event_178.png[/img]{%SPEECH_ON%The fallen room, then. The ceiling of it is alive and I am tired of the noise.%SPEECH_OFF%Back down the corridor, over the rubble slope, into the ammonia and the dark - and above, the roof shifts very slightly, all of it together.}", "Ruin", "The Infested Ruins");
		}

		this.m.Room = "Tower";
		this.m.Rooms.Tower.Seen = true;
		return this.result([], "[img]gfx/ui/events/event_178.png[/img]{%SPEECH_ON%The tower, then. There is a fat thing in the webbing at the bottom of it and I do not go in there.%SPEECH_OFF%Out through the whole building and across the yard, and the low door comes open on the third shoulder, and the dust in the webbing is already moving.}", "Ruin", "The Watchtower");
	}

	function graypeltHoard()
	{
		this.addHours(1);
		this.m.Rooms.Graypelt.Done = true;
		this.m.Mushrooms = this.m.Mushrooms + 6;
		this.m.HasLight = true;
		this.m.Sites.Crucible.Done = this.m.Mushrooms >= 7;
		this.updateDeathToll();

		local items = ::Skv.Loot.make(["scripts/items/weapons/light_crossbow", "scripts/items/misc/skv_potion_of_cure_light_wounds"]);
		if (items.len() > 0) this.enhance(items[0], 0, true);
		local rows  = ::Skv.Loot.haul(items, 354);
		rows.push({ id = 11, icon = "ui/icons/asset_supplies.png", text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]Six ironbloom mushrooms[/color]" });

		return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{The patch in the corner comes up whole, roots and all, into a helm somebody empties for the purpose. Six of them, dull orange, heavier in the hand than a mushroom has any business being.\n\nBehind the fallen column is the rest of it: a bag of coin gone green at the seams, a crossbow somebody cared about a great deal once - the stock is inlaid and the lath is still true, a stoppered flask, and a short rod of pale wood that has no business still being warm. Held up, it throws a steady white light that does not flicker and does not go out, and the men look at each other over it and nobody says the obvious thing, which is that this building has a great deal of dark left in it.}", "Ruin", "Graypelt's Chamber");
	}

	function graypeltRead()
	{
		local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, 45));
		if (r.ok)
		{
			this.m.Bargain = 3;

			local rows = ::Skv.XP.check(r);
			return this.result(rows, "[img]gfx/ui/events/event_178.png[/img]{%actor% is not listening to the words. He is watching the feet.%SPEECH_ON%It has not moved off that column,%SPEECH_OFF% he says, quietly, in the way a man does when he does not want to be the reason a thing starts. %SPEECH_ON%All this talk and it has kept its weight on the front paws the whole time. It is not bargaining with us. It is waiting for us to be tired.%SPEECH_OFF%So the company does not go and do its errand, and does not turn its back. It picks its ground in that doorway, in its own time, with its shields where it wants them - and lets the grey thing find out that the talking is over.}", "Ruin", "Graypelt's Chamber");
		}

		this.m.Bargain = 2;
		return this.result([], "[img]gfx/ui/events/event_178.png[/img]{It talks well. It talks like something that has had four hundred years to learn what men want to hear, and what it says is reasonable, and the corner of mushrooms is right there, and nobody in the company can find the flaw in it.\n\nSo the errand it names is the errand that gets done.}", "Ruin", "Graypelt's Chamber");
	}

	function roomOptions( _id )
	{
		local out = [];
		local r = this.m.Rooms[_id];

		if (_id == "Yard")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Beat through the tall grass. (1 hour)}",
					function getResult() { return this.Contract.yardSearch(); }
				});
			}

		}

		if (_id == "Tower")
		{
			if (!this.m.SpiderDead)
			{
				out.push({
					Text = "{Get between it and the door.}",
					function getResult()
					{
						this.Contract.getActiveState().onCombatSpider();
						return 0;
					}
				});
				out.push({
					Text = "{Out, and pull the door to behind us.}",
					function getResult() { return this.Contract.enterRoom("Yard"); }
				});
				return out;
			}

			if ((r.Step & 2) == 0)
			{
				out.push({
					Text = "{Break open the crates. (1 hour)}",
					function getResult() { return this.Contract.towerCrates(); }
				});
			}
			if (!r.Done)
			{
				out.push({
					Text = "{Send a man up the stair to the trapdoor. (1 hour)}",
					function getResult() { return this.Contract.towerStair(); }
				});
			}
		}

		if (_id == "EntryHall")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Read the floor. (1 hour)}",
					function getResult() { return this.Contract.hallTracks(); }
				});
			}
		}

		if (_id == "Waiting")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Look the dwarf over. (1 hour)}",
					function getResult() { return this.Contract.waitingDwarf(); }
				});
			}
		}

		if (_id == "Cloak")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Turn out the pegs and the table. (1 hour)}",
					function getResult() { return this.Contract.cloakSearch(); }
				});
			}
		}

		if (_id == "Guest")
		{
			if (!this.m.Rooms.Gurtlekep.Seen)
			{
				out.push({
					Text = "{The far door - and it is locked. (1 hour)}",
					function getResult() { return this.Contract.openGurtDoor(); }
				});
			}
			else
			{
				out.push({
					Text = "{Back through the far door.}",
					function getResult() { return this.Contract.enterRoom("Gurtlekep"); }
				});
			}
		}

		if (_id == "Gurtlekep")
		{
			if (!this.m.GurtDead)
			{
				out.push({
					Text = "{Take him before he reaches that hole.}",
					function getResult()
					{
						this.Contract.getActiveState().onCombatGurt();
						return 0;
					}
				});
				out.push({
					Text = "{Back out and shut the door on him.}",
					function getResult() { return this.Contract.enterRoom("Guest"); }
				});
				return out;
			}

			if (!r.Done)
			{
				out.push({
					Text = "{Turn out the sack and the tools. (1 hour)}",
					function getResult() { return this.Contract.gurtSack(); }
				});
			}
		}

		if (_id == "Library")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Take the shelves apart. (1 hour)}",
					function getResult() { return this.Contract.libraryShelves(); }
				});
			}
		}

		if (_id == "Shrine")
		{
			if ((r.Step & 2) == 0)
			{
				out.push({
					Text = "{Look the anvil over.}",
					function getResult()
					{
						this.Contract.m.Rooms.Shrine.Step = this.Contract.m.Rooms.Shrine.Step | 2;
						return this.Contract.shrineAnvil();
					}
				});
			}

			if (!this.m.RubyUsed && (r.Step & 2) != 0 && this.hasRuby())
			{
				out.push({
					Text = "{Set the kobold's ruby into the anvil. (1 hour)}",
					function getResult() { return this.Contract.shrineRuby(); }
				});
			}
			if (!r.Done)
			{
				out.push({
					Text = "{Search the anvil's footings. (1 hour)}",
					function getResult() { return this.Contract.shrineSearch(); }
				});
			}
		}

		if (_id == "Infested")
		{
			if (!this.m.BatsDone)
			{
				out.push({
					Text = "{Cross the rubble.}",
					function getResult() { return this.Contract.batSwarm(); }
				});
			}
		}

		if (_id == "Armory")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Go through the racks and the fallen bolt case. (1 hour)}",
					function getResult() { return this.Contract.armorySearch(); }
				});
			}
			if (!this.m.SecretTried)
			{
				out.push({
					Text = "{Somebody emptied this room and got out again. Find how. (1 hour)}",
					function getResult() { return this.Contract.armorySecret(); }
				});
			}
			if (this.m.SecretFound)
			{
				out.push({
					Text = "{Through the wall, into the passage.}",
					function getResult() { return this.Contract.enterRoom("Prison"); }
				});
			}
		}

		if (_id == "Prison")
		{
			if (!r.Done)
			{
				out.push({
					Text = "{Open the cells.}",
					function getResult() { return this.Contract.prisonCells(); }
				});
			}
		}

		if (_id == "WolfDen")
		{
			if (!this.m.DenDead)
			{
				out.push({
					Text = "{Kill them here, before they can get past us and warn him.}",
					function getResult()
					{
						this.Contract.getActiveState().onCombatDen();
						return 0;
					}
				});
				out.push({
					Text = "{Out, and shut the stone door on them.}",
					function getResult() { return this.Contract.enterRoom("Armory"); }
				});
				return out;
			}

			if (!r.Done)
			{
				out.push({
					Text = "{Turn the priest's desk out. (1 hour)}",
					function getResult() { return this.Contract.denDesk(); }
				});
			}
		}

		if (_id == "Graypelt" && !this.m.GraypeltDead)
		{
			if (this.m.Bargain == 0)
			{
				out.push({
					Text = "{Let it talk.}",
					function getResult() { return this.Contract.graypeltSpeaks(); }
				});
				return out;
			}

			if (this.m.Bargain != 3)
			{
				if (this.errandsLeft() > 0)
				{

					out.push({
						Text = "{Do the thing it asks. (it names one)}",
						function getResult() { return this.Contract.graypeltErrand(); }
					});
				}
				out.push({
					Text = "{Say nothing, and watch it instead.}",
					function getResult() { return this.Contract.graypeltRead(); }
				});
			}

			out.push({
				Text = this.m.Bargain == 3
					? "{Now - while we are the ones who chose the moment.}"
					: "{Enough talk. Take it.}",
				function getResult()
				{
					this.Contract.getActiveState().onCombatGraypelt();
					return 0;
				}
			});

			out.push({
				Text = "{Back out of the doorway. Slowly.}",
				function getResult() { return this.Contract.enterRoom("WolfDen"); }
			});
			return out;
		}

		if (_id == "Graypelt" && this.m.GraypeltDead && !r.Done)
		{
			out.push({
				Text = "{The corner, and whatever he was sitting on. (1 hour)}",
				function getResult() { return this.Contract.graypeltHoard(); }
			});
		}

		if (_id == "EntryHall" && !this.m.Rooms.Waiting.Seen)
		{
			out.push({
				Text = "{Put a shoulder to the stuck door at the end of the hall. (1 hour)}",
				function getResult()
				{
					this.Contract.addHours(1);
					return this.Contract.enterRoom("Waiting");
				}
			});
		}
		else if (_id == "EntryHall")
		{
			out.push({
				Text = "{On to the waiting room.}",
				function getResult() { return this.Contract.enterRoom("Waiting"); }
			});
		}

		foreach (e in this.roomExits(_id))
		{

			local dest = e.To;
			local seen = this.m.Rooms[dest].Seen;
			out.push({
				Text = "{" + (seen ? e.Back : e.New) + "}",
				function getResult()
				{

					if (dest == "Guest")  return this.Contract.enterGuest();
					if (dest == "Shrine") return this.Contract.enterShrine();
					return this.Contract.enterRoom(dest);
				}
			});
		}

		if (this.m.Bargain >= 2 && !this.m.GraypeltDead && _id != "Graypelt" && this.m.Rooms.Graypelt.Seen)
		{
			out.push({
				Text = this.errandsLeft() > 0
					? "{Back to the far chamber, and tell it what it wants to hear.}"
					: "{Back to the far chamber. It has run out of errands.}",
				function getResult() { return this.Contract.enterRoom("Graypelt"); }
			});
		}

		if (this.isDeepRoom(_id) && this.m.Rooms.Yard.Seen)
		{
			out.push({
				Text = "{Cross back through the building to the yard.}",
				function getResult() { return this.Contract.enterRoom("Yard"); }
			});
		}

		if (_id == "Yard")
		{
			out.push({
				Text = "{Out of this place, and down the water to the camp. (3 hours, then " + this.m.ReturnHours.Crucible + " on the river)}",
				function getResult() { return this.Contract.leaveRuin(); }
			});
		}

		return out;
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Hear out the herbalist of " + this.Contract.homeName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				local tile = this.Contract.pickSiteTile();
				if (tile == null)
				{
					local excluded = this.Const.World.getAllTerrainTypesExcept([
						this.Const.World.TerrainType.Forest,
						this.Const.World.TerrainType.LeaveForest,
						this.Const.World.TerrainType.AutumnForest
					]);
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 3, 6, excluded, false);
				}

				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_hollows_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);

				this.Contract.m.DayAccepted = this.World.getTime().Days;
				this.Contract.updateDeathToll();

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}

		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull())
				{
					this.Contract.m.Destination.getSprite("selection").Visible = true;
				}
				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
				{
					this.Contract.m.Home.getSprite("selection").Visible = true;
				}
			}

			function update()
			{

				this.Contract.updateDeathToll();

				if (this.Flags.get("IsVictory"))
				{
					this.Flags.set("IsVictory", false);
					local vid = this.Flags.get("VictoryID");

					if (vid == "HollowsWyrm")
					{
						this.Contract.m.WyrmDead = true;
						this.Contract.m.ResultNext = "ElderSite";
					}
					else if (vid == "HollowsSpider")
					{
						this.Contract.m.SpiderDead = true;
						this.Contract.m.ResultNext = "Ruin";
					}
					else if (vid == "HollowsGurt")
					{
						this.Contract.m.GurtDead = true;
						this.Contract.m.ResultNext = "Ruin";
					}
					else if (vid == "HollowsDen")
					{
						this.Contract.m.DenDead = true;
						this.Contract.m.ResultNext = "Ruin";
					}
					else if (vid == "HollowsGraypelt")
					{
						this.Contract.m.GraypeltDead = true;
						this.Contract.m.ResultNext = "Ruin";
					}
					else if (vid == "HollowsRuinWolves")
					{
						this.Contract.m.ResultNext = "CrucibleSite";
					}
					else if (vid == "HollowsWolves")
					{
						local k = this.Contract.m.PendingSite;
						this.Contract.m.PendingSite = "";
						this.Contract.m.ResultNext = (k != "") ? this.Contract.screenFor(k) : "Hub";
					}
					else
					{
						local key = this.Contract.m.PendingSite;
						this.Contract.m.PendingSite = "";

						if (key != "" && (key in this.Contract.m.Sites))
						{
							this.Contract.m.Sites[key].Visited = true;
							this.Contract.m.ResultNext = this.Contract.screenFor(key);
						}
						else
						{
							this.Contract.m.ResultNext = "Hub";
						}
					}
					this.Contract.setScreen("Breather");
					this.World.Contracts.showActiveContract();
					return;
				}

				local atHome = this.Contract.isPlayerAt(this.Contract.m.Home);
				if (atHome && this.Contract.haveAll() && !this.Contract.m.Reported)
				{
					this.Contract.m.Reported = true;
					::Skv.dbg("Skv.Hollows report fires: dead=" + this.Contract.m.Dead + " failed=" + this.Contract.m.Failed);
					this.Contract.setScreen(this.Contract.m.Failed ? "ReportFailed" : "Report");
					this.World.Contracts.showActiveContract();
					return;
				}

				if (atHome)
				{

					if (this.Contract.haveAll() && !this.TempFlags.get("HomeNag"))
					{
						this.TempFlags.set("HomeNag", true);
						::Skv.dbg("Skv.Hollows at home, haveAll=true, Reported=" + this.Contract.m.Reported);
					}
					return;
				}

				if (this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (!this.TempFlags.get("AtHub"))
					{
						this.TempFlags.set("AtHub", true);

						local screen = "Hub";
						if (this.Contract.m.AtSite != "")
						{
							screen = this.Contract.m.Room != "" ? "Ruin" : this.Contract.screenFor(this.Contract.m.AtSite);
						}

						this.Contract.setScreen(screen);
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtHub", false);
				}
			}

			function onCombatBait()
			{
				local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
				p.CombatID = "HollowsBait";
				p.Tile = this.World.State.getPlayer().getTile();
				p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				local budget = this.Contract.m.BudgetGrung * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult();

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.BanditRaiders, budget, fac);
				::Skv.dbg("Skv.Hollows bait budget=" + budget);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatWyrm()
			{
				local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
				p.CombatID = "HollowsWyrm";
				p.Tile = this.World.State.getPlayer().getTile();
				p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				local budget = this.Contract.m.BudgetWyrm * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult();

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionTatzlwyrms, budget, fac);
				::Skv.dbg("Skv.Hollows wyrm budget=" + budget);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatWolves()
			{
				local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
				p.CombatID = "HollowsWolves";
				p.Tile = this.World.State.getPlayer().getTile();
				p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				local budget = this.Contract.m.BudgetWolves * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult();

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionValeWolves, budget, fac);
				::Skv.dbg("Skv.Hollows wolves budget=" + budget);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string")
				{
					return;
				}
				if (_combatID.len() < 7 || _combatID.slice(0, 7) != "Hollows")
				{
					return;
				}

				this.Flags.set("IsVictory", true);
				this.Flags.set("VictoryID", _combatID);
				::Skv.dbg("Skv.Hollows victory id=" + _combatID);
			}

			function onCombatSpider()
			{
				local p = this.Contract.ruinCombat("HollowsSpider", "tactical.skv_ruin_floor");

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				local budget = this.Contract.m.BudgetSpider * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult() * this.Contract.alarm();
				if (this.Contract.m.HasLight) budget = budget * 0.85;

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.Spiders, budget, fac);
				::Skv.dbg("Skv.Hollows spider budget=" + budget);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatGurt()
			{
				local p = this.Contract.ruinCombat("HollowsGurt", "tactical.skv_ruin_floor");

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				local budget = this.Contract.m.BudgetGurt * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult() * this.Contract.alarm();
				if (this.Contract.m.GurtWarned) budget = budget * 1.35;
				if (this.Contract.m.HasLight) budget = budget * 0.85;

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionKobolds, budget, fac);
				::Skv.dbg("Skv.Hollows gurt budget=" + budget + " warned=" + this.Contract.m.GurtWarned);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatDen()
			{
				local p = this.Contract.ruinCombat("HollowsDen", "tactical.skv_ruin_floor");

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				local budget = this.Contract.m.BudgetDen * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult() * this.Contract.alarm();
				if (this.Contract.m.HasLight) budget = budget * 0.85;

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionValeWolves, budget, fac);
				::Skv.dbg("Skv.Hollows den budget=" + budget);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatGraypelt()
			{

				local p = this.Contract.ruinCombat("HollowsGraypelt", "tactical.skv_ruin_floor");

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				local mult = this.Contract.getScaledDifficultyMult();
				local budget = this.Contract.m.BudgetGraypelt * this.Contract.getDifficultyMult() * mult * this.Contract.alarm();

				if (!this.Contract.m.DenDead)
				{
					budget = budget + this.Contract.m.BudgetDen * 0.60 * this.Contract.getDifficultyMult() * mult * this.Contract.alarm();
				}

				if (this.Contract.m.Errands > 0) budget = budget * (1.0 + 0.10 * this.Contract.m.Errands);

				if (this.Contract.m.Bargain == 3) budget = budget * 0.85;

				local script = "scripts/entity/tactical/enemies/direwolf";
				local id = ::Const.EntityType.Direwolf;
				if (mult >= 2.5 && ("LegendWhiteDirewolf" in ::Const.EntityType))
				{
					script = "scripts/entity/tactical/enemies/legend_white_direwolf";
					id = ::Const.EntityType.LegendWhiteDirewolf;
				}
				else if (mult >= 1.3)
				{
					script = "scripts/entity/tactical/enemies/direwolf_high";
					id = ::Const.EntityType.Direwolf;
				}

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionValeWolves, budget, fac);
				p.Entities.push({
					ID = id, Variant = 200, Row = 0, Name = "Graypelt",
					Script = script, Faction = fac
				});

				::Skv.dbg("Skv.Hollows graypelt budget=" + budget + " tier=" + script + " errands=" + this.Contract.m.Errands + " bargain=" + this.Contract.m.Bargain);
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatRuinWolves()
			{
				local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
				p.CombatID = "HollowsRuinWolves";
				p.Tile = this.World.State.getPlayer().getTile();
				p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				local budget = this.Contract.m.BudgetWolves * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult();

				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionValeWolves, budget, fac);
				::Skv.dbg("Skv.Hollows ruin-wolves budget=" + budget);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onRetreatedFromCombat( _combatID )
			{
				this.Flags.set("IsVictory", false);
				::Skv.dbg("Skv.Hollows retreat id=" + _combatID);
			}

		});
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "Hollow's Last Hope",
			Text = "[img]gfx/ui/events/event_124.png[/img]{The line outside the herbalist's door runs the length of the street - pale children, men holding rags to their mouths, a woman who has stopped crying. Inside, %SKVNAME%Laurel%SKVNAME_OFF% does not look up from her pot. %SPEECH_ON%Blackscour. It is in the water and it is in them now, growing, and they cough until their insides come apart. I have tried everything I know.%SPEECH_OFF% She wipes her hands and pulls down a book so old its spine is cloth. %SPEECH_ON%There is one more thing in here, in a hand that is not my grandmother's. She had it off the witch of the vale. I have never dared it, because I have none of what it wants. Elderwood moss - grows only on the oldest tree in a forest, and damned if I know where that is. A pickled rat's tail, which sounds like hoojoo to me, but Ulizmila may still have one in that hut of hers. And seven ironbloom mushrooms, which want dark places thick with metal - and the only such place hereabouts is the dwarves' old ruin under the crag. If they are anywhere, they are there.%SPEECH_OFF% She finally looks at you, and she does not dress it up. %SPEECH_ON%There is a box under that counter with everything I have in it and everything the street could put in it, and that is the whole of what I can offer you - and I cannot even give it you now, because until the pot is standing I am still buying what I can still buy. Bring me the three and you will have all of it. I know what that is worth against a week in the vale.%SPEECH_OFF% She goes back to her stirring. %SPEECH_ON%I also know how many I buried this week.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We will bring you your three things.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{A witch, a dwarf-hole and the oldest tree in the wood. Does anyone know this country?}",
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
			Title = "Darkmoon Vale",
			Text = "[img]gfx/ui/events/event_26.png[/img]{The herbalist has gone back to her pot and her line of sick, and is not listening. %SKVNAME%%randombrother%%SKVNAME_OFF% says it quietly all the same, with his back half to her. %SPEECH_ON%I have swung an axe in %SKVLOC%Darkmoon Wood%SKVLOC_OFF%. That timber is darkwood - worth more by the yard than the men who fell it, and the %SKVLOC%Lumber Consortium%SKVLOC_OFF% owns every stick of it, along with the mill, the axes, and the beds those people sleep in. There is no lord out here to go crying to. There is a company. And a company has never yet dug anybody a grave.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% is not thinking about the town. %SPEECH_ON%She named two places in that room and both are worse than the coughing. The hollow is the witch's. %SKVNAME%Ulizmila%SKVNAME_OFF% - the vale has been telling stories about her since before that town had a name, and children go missing, and it is always her. Every telling gets one thing the same, mind. The pot. They say she keeps it fed.%SPEECH_OFF% He turns his hand over. %SPEECH_ON%I would take the tail off her shelf and I would put my hands in my pockets and touch not one other thing in there.%SPEECH_OFF%%SPEECH_ON%And the dwarf-hole under the %SKVLOC%Crags%SKVLOC_OFF% is no mine. That was built by the ones who never came up to the sky - who stayed under and knelt to %SKVNAME%Droskar%SKVNAME_OFF%, the Dark Smith, who taught them a man is his labour and nothing else besides. They worked themselves dead in there to prove him right. Whatever squats in it now did not build it. It only found the door open.%SPEECH_OFF%%SKVNAME%%randombrother%%SKVNAME_OFF% shrugs. %SPEECH_ON%Three errands, then. A tree, a witch and a dwarves' hell - and she is only paying us for the walking.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Let us hear her terms.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
				this.Contract.m.KnowsWitch = true;
			}
		});

		this.m.Screens.push({
			ID = "Hub",
			Title = "Consortium Lumber Camp",
			Text = "[img]gfx/ui/events/event_39.png[/img]{The camp cuts an ugly scar of stumps into a stand of proud darkwood - bunkhouse, meal hall, office, barn, smithy, and sawdust over all of it. %SKVNAME%Milon Rhoddam%SKVNAME_OFF% draws in the dirt with a stick: the lake here, the old tree somewhere north of it, the witch's hollow west of that. He stops at the edge of his own drawing. %SPEECH_ON%The dwarf-place is past the Crags, and I have never been past the Crags. Nobody from this camp has. It is that way, and that is all I can give you.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 0, icon = "ui/icons/special.png", text = this.Contract.haveAll()
						? "[color=" + this.Const.UI.Color.PositiveEventValue + "]All three are in the pack - the road home is the last of it[/color]"
						: "Still wanted by the herbalist of " + this.Contract.homeName() },
					{ id = 1, icon = "ui/icons/asset_money.png", text = this.Contract.reagentLine() },
					{ id = 2, icon = "ui/icons/special.png", text = "Dead in " + this.Contract.homeName() + ": " + this.Contract.m.Dead }
				];

				this.Options = [];

				if (!this.Contract.m.Sites.Elder.Done)
				{
					this.Options.push({
						Text = "{North, to the oldest tree in the vale. (" + this.Contract.m.LegHours.Elder + " hours)}",
						function getResult() { return this.Contract.travelTo("Elder"); }
					});
				}

				if (!this.Contract.m.Sites.Hut.Done)
				{
					this.Options.push({
						Text = "{West, to the witch's hollow. (" + this.Contract.m.LegHours.Hut + " hours)}",
						function getResult() { return this.Contract.travelTo("Hut"); }
					});
				}

				if (this.Contract.m.RouteKnown && !this.Contract.m.Sites.Crucible.Done)
				{
					this.Options.push({
						Text = "{North-west, past the Crags, to the dwarves' ruin. (" + this.Contract.m.LegHours.Crucible + " hours)}",
						function getResult() { return this.Contract.travelTo("Crucible"); }
					});
				}

				this.Options.push({
					Text = "{Leave the vale for now.}",
					function getResult() { return 0; }
				});
			}
		});

		this.m.Screens.push({
			ID = "BaitSite",
			Title = "Bait",
			Text = "[img]gfx/ui/events/event_10.png[/img]{The way runs down to open water, and something is screaming on the shore. A fox - large-eared, its paws the colour of flame - with its hindquarters caught in the jaws of a crude iron trap, ten feet from the water and twenty from the trees. It has been screaming a long time. Nothing about it is an accident: the trap is set in the open, on a shore where things come to drink, and whoever laid it wanted the noise.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Cut the animal loose.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatBait();
							return 0;
						}
					},
					{
						Text = "{Leave it. Watch the treeline instead.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatBait();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "ElderSite",
			Title = "The Forest Elder",
			Text = "[img]gfx/ui/events/event_128.png[/img]{The dense trees and thick brush give way, parting seemingly in respect for the titanic darkwood that dominates this clearing. Several times taller than a temple minaret, in one direction it reaches into the sky with branches like a giant's arms, while in the other it plumbs the earth with roots thicker than a man's waist. Its bark is so richly coloured as to be almost black, its leaves the size of bucklers. The thing is less a tree than a cathedral of boughs and branches.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local s = this.Contract.m.Sites.Elder;

				if (!this.Contract.m.WyrmDead)
				{
					s.Step = 1;
					this.List = [];
					this.Text = "[img]gfx/ui/events/event_128.png[/img]{The dense trees and thick brush give way, parting seemingly in respect for the titanic darkwood that dominates this clearing - branches like a giant's arms above, roots thicker than a man's waist below, leaves the size of bucklers. Less a tree than a cathedral of boughs.\n\nThen a whole section of that green ceiling moves.\n\nIt comes down the trunk head-first and far too fast for its size: a long clawed thing with a dragon's head and a sick green mist curling from its open mouth. Something dry and pale is caught in its teeth from the last time it did this.}";
					this.Options = [
						{
							Text = "{Blades. Now.}",
							function getResult()
							{
								this.Contract.getActiveState().onCombatWyrm();
								return 0;
							}
						}
					];
					return;
				}

				if (s.Step == 0)
				{
					s.Step = 1;
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_128.png[/img]{The glade is quiet now. The wyrm lies among the roots where it came down, and the great darkwood stands over it as though nothing had happened at all.}";
				}

				this.List = [];
				this.Options = [];

				if (!this.Contract.m.HasMoss)
				{
					this.Options.push({
						Text = "{Take the moss from the trunk.}",
						function getResult()
						{
							this.Contract.m.HasMoss = true;
							this.Contract.m.Sites.Elder.Done = true;
							this.Contract.updateDeathToll();
							return this.Contract.result([], "{The patch is at the base of the trunk, exactly where the book said it would be, and it comes away in one soft green sheet. One of three.}", "ElderSite", "The Forest Elder");
						}
					});
				}

				if (!this.Contract.m.Climbed)
				{
					this.Options.push({
						Text = "{Send a man up for a look at the country. (2 hours)}",
						function getResult()
						{
							this.Contract.m.Climbed = true;
							this.Contract.addHours(2);

							local r = ::Skv.Check.agility(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));

							if (r.ok)
							{
								this.Contract.m.RouteKnown = true;
								this.Contract.m.RoadNext = "ElderSite";

								this.Contract.m.Sites.Elder.Step = this.Contract.m.Sites.Elder.Step | 2;
								local rows = ::Skv.XP.check(r);
								return this.Contract.result(rows, "{%actor% goes up the low branches easily enough and then keeps going, and keeps going, until the men below stop watching and start listening. When he comes down he is grey in the face and certain of one thing: from up there the whole vale lies open, and there is a way through the northern woods to the crag - a thin line of older trees running north-west, and the ruin sitting grey at the end of it. He also saw what is hanging in the high limbs on the far side of the trunk.}", "RoadNorth", "The Forest Elder");
							}

							return this.Contract.result([], "{%actor% gets as far as the first great smooth stretch of trunk above the low branches and can find nothing to hold. He comes down slowly, swearing, with bark under his fingernails and nothing to show for the morning.}", "ElderSite", "The Forest Elder");
						}
					});
				}

				if ((this.Contract.m.Sites.Elder.Step & 2) != 0 && (this.Contract.m.Sites.Elder.Step & 1) == 0)
				{
					this.Options.push({
						Text = "{Bring down what is caught in the high limbs. (1 hour)}",
						function getResult()
						{
							this.Contract.addHours(1);
							this.Contract.m.Sites.Elder.Step = this.Contract.m.Sites.Elder.Step | 1;

							local rows = ::Skv.Loot.haul([], 40);
							rows.extend(::Skv.XP.partyEach(20));

							return this.Contract.result(rows, "{They are three, and they have been up there a long while. Wedged into a fork forty feet from the ground, one across another, and what the weather and the birds have left of them is held together mostly by their own clothing. Bringing them down takes an hour, a rope, and a certain amount of quiet swearing.\n\nThey were hunters - good ones, by their gear, which is not the gear of men who were careless. The oldest of the company turns one of them over and does not say anything for a moment.\n\nThe wounds are not a fall. Something took each of them low, at the back of the leg, and then took them UP: the clothing is torn downward from the shoulders where they were carried, and there is not a mark on any of them made by a thing standing on the ground. A hunter looks up the trunk, and then at the trees around it, and then rather carefully at the branches over his own head.\n\nWhatever hunts this vale does not chase. It waits above the trail and it drops. The purse comes out of the youngest one's coat, and everybody is very glad to be walking away from that tree.}", "ElderSite", "The Forest Elder");
						}
					});
				}

				this.Options.push({
					Text = "{Down the water to the camp. (" + this.Contract.m.ReturnHours.Elder + " hours)}",
					function getResult() { return this.Contract.travelToHub("Elder"); }
				});
			}
		});

		this.m.Screens.push({
			ID = "HutSite",
			Title = "The Hag-Haunted Hollow",
			Text = "[img]gfx/ui/events/event_115.png[/img]{The sounds of the forest become suddenly distant as the trees part, opening into a small, almost perfectly circular glade. The nearest stands of pine and darkwood twist away from the clearing, as if bent by some impossibly strong wind, or trying to flee despite their paralysed roots. At its centre squats an ugly cottage - twigs, shoots and ivy stacked on mud walls, with bundles of gnarled root, dried carcasses and knucklebone bangles clattering from the thatch. A dozen small thatched fetishes, each shaped like a tiny man or a rearing serpent, stand propped in the yard before a rickety plank door.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local s = this.Contract.m.Sites.Hut;
				if (s.Step == 0)
				{
					s.Step = 1;
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_115.png[/img]{The glade is as you left it. The fetishes lean in the long grass, and the door of the cottage stands open on the dark inside.}";
				}

				this.Options = [];

				if (!this.Contract.m.HasTail)
				{

					this.Options.push({

						Text = this.Contract.m.KnowsWitch
							? "{Turn the place over. Quickly. (they say she keeps the pot fed)}"
							: "{Turn the place over. Quickly.}",
						function getResult()
						{
							this.Contract.m.HasTail = true;
							this.Contract.m.RouteKnown = true;
							this.Contract.m.RoadNext = "HutSite";
							this.Contract.m.Sites.Hut.Done = true;
							this.Contract.updateDeathToll();

							local rows = [];
							local who = "one of the company";
							local pool = this.World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves() && !b.getSkills().hasSkill("injury.fractured_ribs"));

							if (pool.len() > 0)
							{
								local victim = pool[this.Math.rand(0, pool.len() - 1)];
								local inj = ::new("scripts/skills/injury/fractured_ribs_injury");
								victim.getSkills().add(inj);

								victim.setHitpoints(this.Math.max(1, victim.getHitpoints() - this.Math.rand(10, 25)));
								who = victim.getName();
								rows.push({
									id = 10,
									icon = inj.getIcon(),
									text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + who + " has fractured ribs[/color]"
								});
							}

							return this.Contract.result(rows, "[img]gfx/ui/events/event_115.png[/img]{You go through her shelves at speed, and the jar is found inside ten minutes.\n\nWhat none of you were watching was the cauldron - a rusted iron thing five feet across, its ash-caked flank worked with a relief of capering fiends, squatting in the middle of the floor exactly where a cauldron ought to squat.\n\nIt comes off the ground and takes %SKVNAME%" + who + "%SKVNAME_OFF% around the middle, and the rim of it closes like a mouth. It takes three men hauling on his arms and a fourth beating the thing with an axe-haft to get him back out, and when he comes he comes with a sound nobody wants to hear again. The cauldron settles onto its base, rocks once, and is a cauldron.\n\nAmong the charts pinned under it, in the same crabbed hand as the recipe in Laurel's book, is a page naming where ironbloom grows, and drawing the way to it.}", "RoadNorth", "The Hag-Haunted Hollow");
						}
					});

					this.Options.push({
						Text = "{Search it properly. Touch nothing on the shelves. (4 hours)}",
						function getResult()
						{
							this.Contract.addHours(4);
							this.Contract.m.HasTail = true;
							this.Contract.m.RouteKnown = true;
							this.Contract.m.RoadNext = "HutSite";
							this.Contract.m.Sites.Hut.Done = true;
							return this.Contract.result([], "[img]gfx/ui/events/event_115.png[/img]{It takes most of the morning, done the slow way, hands kept off her shelves and every jar set down exactly where it was lifted from. Nothing in that room ever wakes - though at one point the great rusted cauldron in the middle of the floor is found to have moved about a foot, and no man will admit to having moved it.\n\nThe jar is where the book said. So, folded under a cracked scrying bowl, is a page in the same crabbed hand as the recipe: where ironbloom grows, and the way north to it.}", "RoadNorth", "The Hag-Haunted Hollow");
						}
					});
				}

				this.Options.push({
					Text = "{Down the water to the camp. (" + this.Contract.m.ReturnHours.Hut + " hours)}",
					function getResult() { return this.Contract.travelToHub("Hut"); }
				});
			}
		});

		this.m.Screens.push({
			ID = "CrucibleSite",
			Title = "Droskar's Crucible",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = this.Contract.roomList("");
				this.Options = [];

				local night = !this.World.getTime().IsDaytime;
				if (!this.Contract.m.RuinArrived)
				{
					this.Contract.m.RuinArrived = true;

					if (night)
					{
						this.Contract.m.WolvesMet = true;
						this.Title = "The Thorn Field";
						this.Text = "[img]gfx/ui/events/event_25.png[/img]{The ruin comes up out of the dark all at once: a low black shape at the foot of the crag, roofless in places, with the field of weed and wild thorn running up to a pair of standing stones and a doorway beyond them.\n\nAnd there is something in the thorn. Two somethings, grey and long-legged, quartering the field the way animals do when they are working rather than travelling. They have the company's scent before the company has taken three more steps - and they do not run at it. One of them puts its head back and howls, twice, at the building. Then they come.}";
						this.Options = [
							{
								Text = "{Bring them both down. Neither of them goes home.}",
								function getResult()
								{
									this.Contract.getActiveState().onCombatRuinWolves();
									return 0;
								}
							}
						];
						return;
					}

					this.Text = "[img]gfx/ui/events/event_108.png[/img]{Sitting squat at the foot of an imposing mountain, a ruined monastery comes into view between ancient gnarled trees. Simple stone blocks worn smooth with time; sections of the slanted shale roof fallen in; the outer wall crumbled in places. Weeds and wild thorn run rampant over the field before it, leaving only the slightest indication of a path, ending at ruined front doors. Beyond, an overgrown yard sits in shadow.\n\nThe path gives out fifty feet short of the wall, between a pair of old stone statues. One is rubble. The other is a dwarf, five feet of him, holding a great stone hammer up over his head, and moss and creeper have taken everything but the shape.\n\nHigh on the squat tower, three big black birds put their heads over the edge and start to shout about it.}";
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_111.png[/img]{The ruin under the crag, and the thorn field trodden into a path now where the company has crossed it.}";
				}

				if (!this.Contract.m.KnowsTorag)
				{
					this.Options.push({
						Text = "{Pull the creeper off the standing statue.}",
						function getResult()
						{
							local r = ::Skv.Check.wits(this.Contract, ::Skv.Check.scaledBase(this.Contract, 40));
							if (!r.ok)
							{
								return this.Contract.result([], "[img]gfx/ui/events/event_108.png[/img]{Under the creeper is an inscription cut deep into the base, and it is dwarven, and it might as well be a woodworm's track for all anybody here can do with it. Two words in, somebody has scratched the rest of it off the stone - that much is plain even to men who cannot read it. The gouges are old, and there are a great many of them.}", "CrucibleSite", "Droskar's Crucible");
							}

							this.Contract.m.KnowsTorag = true;
							local rows = ::Skv.XP.check(r);
							return this.Contract.result(rows, "[img]gfx/ui/events/event_108.png[/img]{%actor% gets the creeper off in handfuls and reads what is cut into the base, slowly, the way a man does when he has been taught letters he does not often use.%SPEECH_ON%ALL PRAISE - and then nothing. There was a name here and somebody has taken it off the stone with a chisel and taken their time about it. This is old work, mind. Kings' work. That is a smith holding a hammer up, and there is only one of those worth building a house for.%SPEECH_OFF% He puts the creeper back over it, which nobody asks him to do.}", "CrucibleSite", "Droskar's Crucible");
						}
					});
				}

				this.Options.push({
					Text = "{In through the front doors, into the yard.}",
					function getResult() { return this.Contract.enterRoom("Yard"); }
				});

				this.Options.push({
					Text = "{Down the water to the camp. (" + this.Contract.m.ReturnHours.Crucible + " hours)}",
					function getResult() { return this.Contract.travelToHub("Crucible"); }
				});
			}
		});

		this.m.Screens.push({
			ID = "Ruin",
			Title = "Droskar's Crucible",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local id = this.Contract.m.Room;
				if (id == "" || !(id in this.Contract.m.Rooms))
				{
					id = "Yard";
					this.Contract.m.Room = id;
					this.Contract.m.Rooms[id].Seen = true;
				}

				this.Title   = this.Contract.roomTitle(id);
				this.Text    = this.Contract.roomText(id);
				this.List    = this.Contract.roomList(id);
				this.Options = this.Contract.roomOptions(id);
			}
		});

		this.m.Screens.push({
			ID = "Breather",
			Title = "A Breather",
			Text = "[img]gfx/ui/events/event_21.png[/img]{The wood goes quiet again. Before moving on, the company takes the few minutes it takes to bind the worst of it, cinch a loose strap, put an edge back on a notched blade, and drink.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [

					{
						Text = "{Set our gear right. (open loadout)}",
						function getResult()
						{
							::World.State.showLoadoutFromContract();
							return "Breather";
						}
					},
					{
						Text = "{On.}",
						function getResult()
						{
							return this.Contract.m.ResultNext == "" ? "Hub" : this.Contract.m.ResultNext;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "RoadNorth",
			Title = "The Road North",
			Text = "[img]gfx/ui/events/event_45.png[/img]{So there is a way after all, and now you know where it starts. %SKVNAME%%randombrother%%SKVNAME_OFF% looks north-west at the grey shoulder of the crag for a while, and spits. %SPEECH_ON%A day past the Crags, on a hedge-witch's guess about mushrooms. I'll walk it if you say walk it. But the near work is half a morning each and we are standing next to it, and that ruin will still be there tonight.%SPEECH_OFF% Nobody disagrees with him. Nobody tells him to shut up either.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Noted.}",
						function getResult()
						{
							return this.Contract.m.RoadNext == "" ? "Hub" : this.Contract.m.RoadNext;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "WolvesCard",
			Title = "Darkmoon Wolves",
			Text = "[img]gfx/ui/events/event_25.png[/img]{They do not come out of the trees so much as resolve out of them, in the unhurried way of animals that have already decided. Four of them, grey and long-legged and in no particular hurry, spreading as they come. These are not starving. These are patrolling.\n\nOne hangs back at the treeline, watching the others work. That one is not going to fight.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Form up. And someone bring down the one at the back.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatWolves();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Result",
			Title = "Darkmoon Vale",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Title = this.Contract.m.ResultTitle;
				this.Text  = this.Contract.m.ResultText;
				this.List  = this.Contract.m.ResultRows;
				this.Options = [
					{
						Text = "{Good.}",
						function getResult() { return this.Contract.m.ResultNext == "" ? "Hub" : this.Contract.m.ResultNext; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "The Brewing",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local t = c.tier();
				local town = c.homeName();

				local body = "[img]gfx/ui/events/event_85.png[/img]{%SKVNAME%Laurel%SKVNAME_OFF% takes the three of them out of your hands without a word: the moss in its cloth, the jar with the tail in it, and seven dull orange mushrooms that weigh like musket balls. She does not thank anybody. She is already at the fire.\n\n";

				if (t == "InTime")
				{
					body = body + "By evening the smell of it is through the whole street - sharp, and green, and nothing like the smell that has been in these houses for a fortnight. By morning the coughing in the row nearest her door has loosened, and a child who was not expected to see the week is sitting up and complaining about the taste.\n\nThe grave-digger goes home at noon with nothing to do. That is the part the town notices.\n\nThey buried " + c.m.Dead + " before you got back. Everybody in " + town + " knows exactly what that number would have been.}";
				}
				else if (t == "Late")
				{
					body = body + "It works. That is the first thing, and it should be said first: the pot goes on, the smell goes through the street, and the ones still breathing begin to mend.\n\nBut you were a day longer than the vale allowed, and the row nearest her door had already gone quiet before you came up it. " + c.m.Dead + " went into the ground in " + town + " while you were out in the wood, and a good many of them went in the last two days.\n\nShe pays you. She counts it out slowly, from a box that has less in it than it did, and she does not look up while she does it.}";
				}
				else
				{
					body = body + "It works, on what is left. The pot goes on, and the smell goes through a street where a great many doors are standing open with nobody behind them.\n\n" + c.m.Dead + " dead in " + town + ". There are houses on that row where the cure arrived for nobody at all, and the men carrying it up the street had to walk past them to reach her door.\n\nShe pays you what she promised, because she promised it. Nobody says the obvious thing. It is a small town and it will be a smaller one.}";
				}

				this.Title = t == "InTime" ? "The Brewing" : "The Brewing, Late";
				this.Text = body;

				local rows = [];
				rows.push({ id = 1, icon = "ui/icons/asset_money.png", text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]" + c.finalPay() + " crowns[/color]" + (t == "InTime" ? "" : " - the fee, cut for the days it took") });
				rows.push({ id = 2, icon = "ui/icons/special.png", text = "The blackscour lifts from [color=" + this.Const.UI.Color.PositiveEventValue + "]" + town + "[/color]" });
				if (t == "InTime")
				{
					rows.push({ id = 3, icon = "ui/icons/asset_moral_reputation.png", text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]Renown[/color] - the company that beat the vale's own clock" });
				}
				rows.push({ id = 4, icon = "ui/icons/days_wounded.png", text = "Buried in " + town + " before you returned: [color=" + this.Const.UI.Color.NegativeEventValue + "]" + c.m.Dead + "[/color]" });

				if (c.m.GraypeltDead)
				{
					rows.push({ id = 5, icon = "ui/icons/special.png", text = "The worg of Droskar's Crucible is dead in his own hall" });
				}
				if (c.m.HasRing)
				{
					rows.push({ id = 6, icon = "ui/icons/special.png", text = "Torag's ring came out of that building after four hundred years" });
				}
				if (c.m.RubyUsed)
				{
					rows.push({ id = 7, icon = "ui/icons/special.png", text = "An anvil sang once, under the crag, and then went cold again" });
				}
				this.List = rows;

				this.Options = [
					{
						Text = "{Our due, then.}",
						function getResult()
						{
							local t = this.Contract.tier();

							if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
							{
								this.Contract.m.Home.removeSituationByID("situation.sickness");
							}

							this.World.Assets.addMoney(this.Contract.finalPay());
							if (t == "InTime")
							{
								this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
							}
							this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Cured the blackscour taint");
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "ReportFailed",
			Title = "Too Late",
			Text = "[img]gfx/ui/events/event_57.png[/img]{The street is quiet. %SKVNAME%Laurel%SKVNAME_OFF% takes the three of them out of your hands, looks at them a while, and sets them down on the bench beside her. %SPEECH_ON%It has burned itself out. The ones it was going to take are taken, and the rest got well on their own.%SPEECH_OFF% Somewhere behind her, a shutter is being nailed closed over a window.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{We were too slow.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(-this.Const.World.Assets.ReputationOnContractFailed);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(-this.Const.World.Assets.RelationCivilianContractFailed, "Failed to cure the blackscour taint");
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
			}
		});
	}

	function onClear()
	{
		::Skv.Once.release("HollowsLastHope");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("HollowsLastHope");
			if (!::MSU.isNull(this.m.Destination))
			{
				this.m.Destination.getSprite("selection").Visible = false;
				this.m.Destination.die();
				this.m.Destination = null;
			}
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

		local nm = (this.m.ActorName != null && this.m.ActorName != "") ? this.m.ActorName : "one of the company";
		_vars.push(["actor", "[color=" + nameColor + "]" + nm + "[/color]"]);

		_vars.push(["SKVNAME", "[color=#9dbccb]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);
		_vars.push(["SKVLOC", "[color=#b39dbc]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);
	}

	function siteKeys()
	{
		return ["Elder", "Hut", "Crucible"];
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

		_out.writeF32(this.m.HoursSpent);
		_out.writeU16(this.m.DayAccepted);
		_out.writeU16(this.m.Dead);
		_out.writeU8(this.m.Failed ? 1 : 0);

		_out.writeU8(this.m.HasMoss ? 1 : 0);
		_out.writeU8(this.m.HasTail ? 1 : 0);
		_out.writeU8(this.m.Mushrooms);

		_out.writeU8(this.m.BaitDone ? 1 : 0);
		_out.writeU8(this.m.RouteKnown ? 1 : 0);
		_out.writeU8(this.m.Climbed ? 1 : 0);
		_out.writeU8(this.m.WyrmDead ? 1 : 0);
		_out.writeU16(this.m.DeckMask);
		_out.writeU8(this.m.HasLight ? 1 : 0);
		_out.writeU8(this.m.WolvesMet ? 1 : 0);
		_out.writeU8(this.m.KnowsWitch ? 1 : 0);
		_out.writeString(this.m.PendingSite);

		foreach (k in this.siteKeys())
		{
			local s = this.m.Sites[k];
			_out.writeU8(s.Visited ? 1 : 0);
			_out.writeU8(s.Done ? 1 : 0);
			_out.writeU8(s.Step);
		}

		_out.writeU8(this.m.RuinArrived ? 1 : 0);
		_out.writeU8(this.m.KnowsTorag ? 1 : 0);
		_out.writeU8(this.m.KnowsNorth ? 1 : 0);
		_out.writeU8(this.m.RuinMapped ? 1 : 0);
		_out.writeU8(this.m.SpiderDead ? 1 : 0);
		_out.writeU8(this.m.GurtDead ? 1 : 0);
		_out.writeU8(this.m.GurtWarned ? 1 : 0);
		_out.writeU8(this.m.HasRuby ? 1 : 0);
		_out.writeU8(this.m.RubyUsed ? 1 : 0);
		_out.writeU8(this.m.MantlesDone ? 1 : 0);
		_out.writeString(this.m.Room);
		foreach (k in this.roomKeys())
		{
			local r = this.m.Rooms[k];
			_out.writeU8(r.Seen ? 1 : 0);
			_out.writeU8(r.Done ? 1 : 0);
			_out.writeU8(r.Step);
		}
		_out.writeString(this.m.AtSite);
		_out.writeU8(this.m.BatsDone ? 1 : 0);
		_out.writeU8(this.m.SecretTried ? 1 : 0);
		_out.writeU8(this.m.SecretFound ? 1 : 0);
		_out.writeU8(this.m.DenDead ? 1 : 0);
		_out.writeU8(this.m.GraypeltDead ? 1 : 0);
		_out.writeU8(this.m.HasRing ? 1 : 0);
		_out.writeU8(this.m.Bargain);
		_out.writeU8(this.m.Errands);
		_out.writeU8(this.m.ToldShrine ? 1 : 0);
		_out.writeU8(this.m.Reported ? 1 : 0);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local destination = _in.readU32();
		if (destination != 0)
		{
			this.m.Destination = this.WeakTableRef(::World.getEntityByID(destination));
		}

		this.m.HoursSpent  = _in.readF32();
		this.m.DayAccepted = _in.readU16();
		this.m.Dead        = _in.readU16();
		this.m.Failed      = _in.readU8() == 1;

		this.m.HasMoss   = _in.readU8() == 1;
		this.m.HasTail   = _in.readU8() == 1;
		this.m.Mushrooms = _in.readU8();

		this.m.BaitDone    = _in.readU8() == 1;
		this.m.RouteKnown  = _in.readU8() == 1;
		this.m.Climbed     = _in.readU8() == 1;
		this.m.WyrmDead    = _in.readU8() == 1;
		this.m.DeckMask    = _in.readU16();
		this.m.HasLight    = _in.readU8() == 1;
		this.m.WolvesMet   = _in.readU8() == 1;
		this.m.KnowsWitch  = _in.readU8() == 1;
		this.m.PendingSite = _in.readString();

		foreach (k in this.siteKeys())
		{
			local s = this.m.Sites[k];
			s.Visited = _in.readU8() == 1;
			s.Done    = _in.readU8() == 1;
			s.Step    = _in.readU8();
		}

		this.m.RuinArrived = _in.readU8() == 1;
		this.m.KnowsTorag  = _in.readU8() == 1;
		this.m.KnowsNorth  = _in.readU8() == 1;
		this.m.RuinMapped  = _in.readU8() == 1;
		this.m.SpiderDead  = _in.readU8() == 1;
		this.m.GurtDead    = _in.readU8() == 1;
		this.m.GurtWarned  = _in.readU8() == 1;
		this.m.HasRuby     = _in.readU8() == 1;
		this.m.RubyUsed    = _in.readU8() == 1;
		this.m.MantlesDone = _in.readU8() == 1;
		this.m.Room        = _in.readString();
		foreach (k in this.roomKeys())
		{
			local r = this.m.Rooms[k];
			r.Seen = _in.readU8() == 1;
			r.Done = _in.readU8() == 1;
			r.Step = _in.readU8();
		}
		this.m.AtSite = _in.readString();
		this.m.BatsDone     = _in.readU8() == 1;
		this.m.SecretTried  = _in.readU8() == 1;
		this.m.SecretFound  = _in.readU8() == 1;
		this.m.DenDead      = _in.readU8() == 1;
		this.m.GraypeltDead = _in.readU8() == 1;
		this.m.HasRing      = _in.readU8() == 1;
		this.m.Bargain      = _in.readU8();
		this.m.Errands      = _in.readU8();
		this.m.ToldShrine   = _in.readU8() == 1;
		this.m.Reported     = _in.readU8() == 1;

		this.contract.onDeserialize(_in);
	}

});
