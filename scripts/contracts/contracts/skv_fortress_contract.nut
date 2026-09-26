this.skv_fortress_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Destination = null,

		Rooms = 0,

		Found = 0,

		Access = 0,

		Balenar = 0,

		Handed = 0,

		Outcome = 0,
		Concluded = 0,
		Aborted = 0,

		Alert = 0,
		Res16 = 0,
		Res32 = 0,
		ResStr = "",

		ActorName = "",
		SayTitle = "",
		SayText = "",
		SayRows = null,
		SayNext = "",
		SayImage = "",
	},

	function bitRoom( _n )   { return 1 << _n; }

	function hasRoom( _bit )  { return (this.m.Rooms & _bit) != 0; }
	function hasFound( _bit ) { return (this.m.Found & _bit) != 0; }
	function hasAccess( _bit )  { return (this.m.Access & _bit) != 0; }

	function homeName()
	{
		return this.m.Home != null && !this.m.Home.isNull() ? this.m.Home.getName() : "the lodge";
	}

	function say( _title, _text, _rows = null, _next = "", _image = "" )
	{
		this.m.SayTitle = _title;
		this.m.SayText = _text;
		this.m.SayRows = _rows == null ? [] : _rows;
		this.m.SayNext = _next;
		this.m.SayImage = _image;
		return "Result";
	}

	function rooms()
	{
		return [
			{ Bit = 0x001, Area = 1,  Floor = 0, Title = "Ravenous Dogs",
			  Label = "",
			  Blurb = "The dogs come off the rubble in a rush, and they are starving, and starving is the only dangerous thing about them. It is short." },

			{ Bit = 0x002, Area = 2,  Floor = 0, Title = "The Spider's Lair",
			  Label = "{In at the foot of the rubble - the ground floor.}",
			  Blurb = "The hole opens into the northern wing, and the northern wing is webs from the floor to the ceiling. Something heavy comes down out of them." },

			{ Bit = 0x004, Area = 3,  Floor = 2, Title = "The Storeroom",
			  Label = "{Up the rubble slope to the second floor.}",
			  Blurb = "There is a crack in the wall of the storeroom and a puddle standing under it, and the beasts Tasskar keeps have the run of both." },

			{ Bit = 0x008, Area = 4,  Floor = 2, Title = "The Armoury",
			  Label = "{The far door off the landing - the stench comes from behind it.}",
			  Blurb = "The smell reaches the landing before the room does. Young troglodytes, loud and eager, and the racks of somebody else's war behind them. The eastern door goes through to the stair, and from this floor up the stair is whole." },

			{ Bit = 0x010, Area = 5,  Floor = 2, Title = "The Trapped Entry",
			  Label = "{The last door on the second floor.}",
			  Blurb = "Octagonal, and thick with dust, and the dust in front of the northwestern door has been walked through by something that does not wear boots." },

			{ Bit = 0x020, Area = 6,  Floor = 3, Title = "The Bats' Roost",
			  Label = "{Up the stair to the third floor.}",
			  Blurb = "Half of the third floor is on the second floor. The ceiling of what is left of it is moving." },

			{ Bit = 0x040, Area = 7,  Floor = 3, Title = "The Temple of Nethys",
			  Label = "{Through the wall - the temple.}",
			  Blurb = "Behind the wall the third floor is a temple with two altars, one black and one white, and two troglodytes burned down to the bone lying between them." },

			{ Bit = 0x080, Area = 8,  Floor = 4, Title = "The Flooded Chamber",
			  Label = "{Up the stair to the fourth floor.}",
			  Blurb = "The western room of the fourth floor stands ankle-deep in water, and one of the things in the water is not a fallen beam." },

			{ Bit = 0x100, Area = 9,  Floor = 4, Title = "The Barracks",
			  Label = "{The bunkroom.}",
			  Blurb = "Crude bunks, the smell again, and the ones who were asleep in them until a moment ago." },

			{ Bit = 0x200, Area = 10, Floor = 4, Title = "Tulok's Room",
			  Label = "{The room with the brazier.}",
			  Blurb = "A brazier of coals, knives and pokers laid out on a rusted iron box, and the biggest of them yet standing over the lot of it." },

			{ Bit = 0x400, Area = 11, Floor = 4, Title = "The Cell",
			  Label = "{The last door on this floor.}",
			  Blurb = "The last door on the floor is a cupboard with a man in it, and it takes him a moment to understand that this is not another beating." },

			{ Bit = 0x800, Area = 12, Floor = 5, Title = "The Top of the Tower",
			  Label = "{Up the last of the stair.}",
			  Blurb = "The top of the tower is one cross-shaped room with the sky standing in four arches, and the troglodyte at the eastern arch is looking at the city." }
		];
	}

	function roomRow( _bit )
	{
		foreach (r in this.rooms())
		{
			if (r.Bit == _bit) return r;
		}
		return null;
	}

	function isSpine( _bit ) { return _bit != 0x040; }

	function nextRoom()
	{
		foreach (r in this.rooms())
		{
			if (!this.isSpine(r.Bit)) continue;
			if (!this.hasRoom(r.Bit)) return r.Bit;
		}
		return 0;
	}

	function templeOpen()
	{
		if (!this.hasAccess(0x04) || this.hasRoom(0x040)) return false;
		if (this.hasAccess(0x100) && !this.hasAccess(0x02) && !this.hasAccess(0x200)) return false;
		return true;
	}

	function enterRoom( _bit )
	{
		local row = this.roomRow(_bit);

		if (row == null)
		{
			::Skv.dbg("Skv.Fortress: enterRoom got an unknown bit " + _bit);
			return this.hubScreen();
		}

		if (_bit == 0x001) return "Dogs";
		if (_bit == 0x002) return "SpiderLair";
		if (_bit == 0x004) return "Storeroom";
		if (_bit == 0x008) return "Armoury";
		if (_bit == 0x010) return "TrapEntry";
		if (_bit == 0x020) return "BatsRoost";
		if (_bit == 0x040) return this.hasAccess(0x200) ? "Temple" : "TempleDoor";
		if (_bit == 0x080) return "Flooded";
		if (_bit == 0x100) return "Barracks";
		if (_bit == 0x200) return "TulokRoom";
		if (_bit == 0x400) return "Cell";
		if (_bit == 0x800) return (this.hasAccess(0x20) || this.hasAccess(0x400)) ? "TopFight" : "TopOfTower";

		this.m.Rooms = this.m.Rooms | _bit;

		::Skv.dbg("Skv.Fortress: area " + row.Area + " (" + row.Title + ") resolved"
			+ "  Rooms=" + this.m.Rooms + " Access=" + this.m.Access
			+ "  next=" + this.nextRoom());

		return this.say(row.Title, "{" + row.Blurb + "}", [], "", "");
	}

	function fortressCombat( _id, _indoor )
	{
		local p = ::Const.Tactical.CombatInfo.getClone();
		p.CombatID = _id;
		p.Music = ::Const.Music.BeastsTracks;
		p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Circle;

		if (_indoor)
		{

			p.TerrainTemplate = "tactical.skv_ruin_floor";
			p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
			p.IsWithoutAmbience = true;
		}
		else
		{
			local tile = this.m.Destination.getTile();
			p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
			p.Tile = tile;

			p.LocationTemplate = clone ::Const.Tactical.LocationTemplate;
			p.LocationTemplate.Template = clone ::Const.Tactical.LocationTemplate.Template;
			p.LocationTemplate.Template[0] = "tactical.ruins";
			p.LocationTemplate.Fortification = ::Const.Tactical.FortificationType.None;
			p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.Center;
		}

		return p;
	}

	function startFight( _bit )
	{
		local fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Beasts).getID();
		local mult = this.getDifficultyMult() * this.getScaledDifficultyMult();
		local p = null;
		local list = null;
		local price = 0;

		if (_bit == 0x001)
		{

			p = this.fortressCombat("FortressDogs", false);
			list = ::Const.World.Spawn.GolarionFortressDogs;
			price = 60;
		}
		else if (_bit == 0x002)
		{

			p = this.fortressCombat("FortressSpider", true);
			list = ::Const.World.Spawn.GolarionFortressSpiders;
			price = 70;
		}
		else if (_bit == 0x004)
		{

			p = this.fortressCombat("FortressHyenas", true);
			list = ::Const.World.Spawn.GolarionFortressHyenas;
			price = 75;
		}
		else if (_bit == 0x040)
		{

			fac = ::World.FactionManager.getFactionOfType(::Const.FactionType.Undead).getID();
			p = this.fortressCombat("FortressTemple", true);
			list = ::Const.World.Spawn.GolarionFortressSkeletons;
			price = 90;
		}
		else if (_bit == 0x800)
		{

			p = this.fortressCombat("FortressTop", true);
			list = ::Const.World.Spawn.GolarionFallenFortress;
			price = this.hasAccess(0x20) ? 40 : 60;
			this.pushTopBosses(p, fac);
		}
		else if (_bit == 0x080)
		{

			p = this.fortressCombat("FortressSerpents", true);
			list = ::Const.World.Spawn.GolarionFortressSerpents;
			price = 50;
		}
		else if (_bit == 0x100)
		{

			p = this.fortressCombat("FortressBarracks", true);
			list = ::Const.World.Spawn.GolarionFallenFortress;
			price = 74;
		}
		else if (_bit == 0x200)
		{

			p = this.fortressCombat("FortressTulok", true);
			list = ::Const.World.Spawn.GolarionFallenFortress;
			price = 90;
		}
		else if (_bit == 0x008)
		{

			p = this.fortressCombat("FortressArmoury", true);
			list = ::Const.World.Spawn.GolarionFallenFortress;
			price = 68;
		}
		else
		{
			::Skv.dbg("Skv.Fortress: startFight got a room with no fight, bit " + _bit);
			return;
		}

		local alert = 1.0 + this.m.Alert / 100.0;
		local budget = price * mult * alert;
		::Const.World.Common.addUnitsToCombat(p.Entities, list, budget, fac);
		::Skv.dbg("Skv.Fortress: " + p.CombatID + " budget=" + budget
			+ " (base " + price + " x " + mult + " x alert " + alert + ")  units=" + p.Entities.len());

		::World.Contracts.startScriptedCombat(p, false, true, true);
	}

	function afterFight( _bit )
	{
		this.m.Rooms = this.m.Rooms | _bit;
		::Skv.dbg("Skv.Fortress: area won, bit " + _bit + "  Rooms=" + this.m.Rooms
			+ " Found=" + this.m.Found + "  next=" + this.nextRoom());

		if (_bit == 0x001)
		{
			return this.say("Ravenous Dogs",
				"{It is short and it is ugly, and at the end of it there are dogs lying on the rubble that were somebody's once - collars on some of them, and ribs on all of them. Nobody has fed these animals in a long while, and nothing on this plain has been willing to be fed to them.\n\n%randombrother% turns one over with his boot.%SPEECH_ON%They were not hunting us. They were just hungry, and we were the first thing that came along.%SPEECH_OFF%The rubble slope runs up against the broken side of the tower, and at the bottom of it the stones frame a hole into the dark.}",
				[], "", "gfx/ui/events/event_108.png");
		}

		if (_bit == 0x002)
		{
			local rows = [];
			if (!this.hasFound(0x01))
			{
				this.m.Found = this.m.Found | 0x01;
				rows = ::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/loot/skv_kita_collar"]));
			}

			return this.say("The Spider's Lair",
				"{When the last of it stops moving the company cuts its way into the webs and finds out what else has been hanging in them.\n\nMost of it is rats and birds and things that were once rats and birds. One bundle is larger, and when %randombrother% opens it with his knife there is a dog inside - long dead, dried to leather, still wearing its collar. Blue stones set in the leather, and a little silver tag on the buckle with a name scratched into it: Kita.\n\nThe door in the western wing opens onto the tower's stair, and the stair is packed solid with fallen stone to above head height. Whatever is above this floor is not reached from this floor. Outside, the rubble runs up against the broken face of the second storey.}",
				rows, "", "gfx/ui/events/event_110.png");
		}

		if (_bit == 0x004)
		{
			return this.say("The Storeroom",
				"{They came at the company the way dogs come at a kitchen door, and they went down the way dogs do. Nobody has been feeding them either - whatever Tasskar keeps them for, it is not for their own sake.\n\nThe crack in the wall lets the rain in and the puddle under it has been lapped down to mud. And somewhere beyond the far door off the landing, voices that were talking a moment ago have stopped.}",
				[], "", "gfx/ui/events/event_148.png");
		}

		if (_bit == 0x008)
		{

			this.m.Access = this.m.Access | 0x01;
			return this.armouryRacks();
		}

		if (_bit == 0x040)
		{
			return this.templeAltars();
		}

		if (_bit == 0x080)
		{

			local rows = [];
			local found = "";
			if (!this.hasFound(0x10))
			{
				local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 60));
				if (r.ok)
				{
					this.m.Found = this.m.Found | 0x10;
					found = "\n\n" + this.m.ActorName + " is fishing a boot out of the water when his hand closes on something under the broken table that is not a stone - a small figure carved in green jade, very old, with flecks of red paint still in the carving.";
					rows = ::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/loot/skv_jade_angel"]));
					rows.extend(::Skv.XP.check(r));
				}
			}
			return this.say("The Flooded Chamber",
				"{The water settles. What was in it lies half out of it now, long and still, and the mould on the walls goes on glistening as though nothing had happened. The troglodytes do not come in here unless they are made to, and it is not hard to see why." + found + "}",
				rows, "", "gfx/ui/events/event_149.png");
		}

		if (_bit == 0x100)
		{
			return this.say("The Barracks",
				"{The troglodytes in the bunkroom were half asleep when the company came in, and most of them never got all the way awake. The bunks are heaps of rotten straw and old hides, and the stink is worse in here than anywhere in the tower. There is nothing worth carrying out.}",
				[], "", "gfx/ui/events/event_48.png");
		}

		if (_bit == 0x200)
		{
			return this.tulokChest();
		}

		if (_bit == 0x800)
		{
			return this.tasskarChest();
		}

		return this.hubScreen();
	}

	function armouryRacks()
	{
		local rows = [];
		local named = false;

		if (!this.hasFound(0x02))
		{
			this.m.Found = this.m.Found | 0x02;

			local r = ::Skv.Check.wits(this, ::Skv.Check.scaledBase(this, 40), { ["background.historian"] = 5 });
			named = r.ok;

			local dagger = ::new("scripts/items/weapons/dagger");
			local shield = ::new("scripts/items/shields/buckler_shield");
			if ("GolarionEnchant" in ::getroottable())
			{
				try
				{

					if (!::GolarionEnchant.setMasterwork(dagger, true))
						::logError("Skv.Fortress: the racks' dagger refused masterwork");
					if (!::GolarionEnchant.setMasterwork(shield, true))
						::logError("Skv.Fortress: the racks' buckler refused masterwork -- is hooks/47_shield_masterwork loaded?");
				}
				catch (e)
				{
					::logError("Skv.Fortress: masterwork failed on the racks: " + e);
				}
			}
			local banner = ::new(named ? "scripts/items/loot/skv_phoenix_banner" : "scripts/items/loot/skv_faded_banner");

			rows = ::Skv.Loot.haul([dagger, shield, banner]);
			rows.extend(::Skv.XP.check(r));
		}

		local tail = named
			? "%randombrother% holds the banner up to the light and goes very still.%SPEECH_ON%That is the Band of the Phoenix. Absalom, the Age of Blades - a hunting lodge, and a famous one. Somebody in the Grand Lodge will want this badly, and pay for wanting it.%SPEECH_OFF%"
			: "There is a banner, too, faded nearly to nothing - a bird made of flame on it, once. Nobody in the company can say whose it was. It rolls up small, and cloth is cloth.";

		return this.say("The Armoury",
			"{The young troglodytes fought the way youngsters fight - loud, all at once, and without the sense to run. The dead lizard-men stink as badly as the living ones did, and the smell does not leave with the bodies. It is soaked into the walls.\n\nThe racks are somebody else's war. Most of it has rotted where it hangs, but not all: a dagger with a good edge still on it, a small round shield with a leaping dolphin worked into the face, both made by hands that knew the trade.\n\n" + this.para(tail, "The eastern door opens onto the tower's stair, and from here up the stair is whole.") + "}",
			rows, "", "gfx/ui/events/event_48.png");
	}

	function resolveTrap()
	{
		local rows = [];
		local text = "";

		local tr = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, 55));
		local tracker = this.m.ActorName;
		rows.extend(::Skv.XP.check(tr));
		if (tr.ok)
		{
			text = tracker + " is down on one knee in the dust before anybody else has looked at it.%SPEECH_ON%Lizard feet. Lots of them, none of them big - young ones, the same few coming and going. And these, over the top of theirs.%SPEECH_OFF%A bare foot, and beside it the prints of something heavy and four-legged that walks where the man walks. Somebody up there is not one of them, and keeps an animal.\n\n";
		}
		else
		{
			text = "The dust before the northwestern door has been walked through, and walked through often, by things that do not wear boots. Nobody can make more of it than that.\n\n";
		}

		local d = ::Skv.Check.disarm(this, ::Skv.Check.scaledBase(this, 50));
		local fixer = this.m.ActorName;
		local image = "gfx/ui/events/event_89.png";

		if (d.ok)
		{
			rows.extend(::Skv.XP.check(d));
			if (!this.hasFound(0x80))
			{
				this.m.Found = this.m.Found | 0x80;
				rows.extend(::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/weapons/javelin"])));
			}
			text = text + fixer + " finds the plate under the dust in front of the door and follows the cord from it up into the wall, and takes his time. When he is finished the mechanism is in pieces on the floor and its javelins are in his hands.";
		}
		else
		{
			image = "gfx/ui/events/event_21.png";
			rows.push(this.javelinHit(d.actor));

			local s = ::Skv.Check.stealth(this, ::Skv.Check.scaledBase(this, 55), 0.5);

			rows.extend(::Skv.XP.checkEach(s));
			local heard = [];
			foreach (row in s.rows)
			{
				if (!row.ok) heard.push(row.name);
			}
			local add = heard.len() * 4;
			this.m.Alert = ::Math.min(255, this.m.Alert + add);

			text = text + "Something clicks under " + fixer + "'s hand, and the wall spits a javelin at him from somewhere nobody was looking. It is loud - the bang of the mechanism, the shaft going home, the man going down - and then the company is standing very still in an octagonal room, listening to the tower.";

			if (add > 0)
			{
				local names = "";
				foreach (i, n in heard) names = names + (i == 0 ? "" : ", ") + n;
				rows.push({ id = 10, icon = "ui/icons/regular_damage.png",
					text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]The tower heard " + names
						+ ": every fight from here +" + add + "% (now +" + this.m.Alert + "%)[/color]" });
				text = text + " Not everyone manages it. A boot scrapes, a buckle rings, somebody swears - and above them, faintly, something that was asleep is not asleep any longer.";
			}
			else
			{
				rows.push({ id = 10, icon = "ui/icons/special.png",
					text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]Every man froze - nothing upstairs stirs[/color]" });
				text = text + " Nobody moves. After a long while, nothing above them does either.";
			}
		}

		this.m.Rooms = this.m.Rooms | 0x010;
		::Skv.dbg("Skv.Fortress: area 5 tracks=" + tr.ok + " disarm=" + d.ok + "  Alert=" + this.m.Alert
			+ "  Rooms=" + this.m.Rooms + " Found=" + this.m.Found);

		return this.say("The Trapped Entry", "{" + text + "}", rows, "", image);
	}

	function findFirePot()
	{
		local stash = ::World.Assets.getStash();
		if (stash == null) return null;
		foreach (it in stash.getItems())
		{
			if (it != null && it.getID() == "weapon.fire_bomb") return it;
		}
		return null;
	}

	function biteWound( _bro )
	{
		local pool = ["ripped_ear", "pierced_cheek", "cut_arm", "grazed_neck"];
		local free = [];
		foreach (n in pool)
		{
			if (!_bro.getSkills().hasSkill("injury." + n)) free.push(n);
		}
		if (free.len() == 0) return null;
		local inj = ::new("scripts/skills/injury/" + free[::Math.rand(0, free.len() - 1)] + "_injury");
		_bro.getSkills().add(inj);
		return inj;
	}

	function resolveRoost( _usePot )
	{

		local rows = [];
		local loot = [];
		local xp = [];
		local text = "";
		local image = "gfx/ui/events/event_44.png";

		if (_usePot)
		{
			local pot = this.findFirePot();
			if (pot == null) return "BatsRoost";
			::World.Assets.getStash().remove(pot);
			this.m.Access = this.m.Access | 0x40;
			rows.push({ id = 10, icon = "ui/items/" + pot.getIcon(), text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]You lose Fire Pot[/color]" });
			text = "The pot bursts against the far wall and the ceiling comes apart into a thousand screaming pieces. The swarm goes out through the broken side of the tower in one black rush, and the smoke goes after it, and then there is only the smell of burnt oil and a floor a foot deep in droppings.\n\n";
		}
		else
		{
			local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
			foreach (bro in pool)
			{
				local dmg = ::Math.rand(6, 18);
				local hp = bro.getHitpoints() - dmg;
				if (hp < 1) hp = 1;
				local lost = bro.getHitpoints() - hp;
				bro.setHitpoints(hp);
				rows.push({ id = 10, icon = "ui/icons/health.png", text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]" + bro.getName() + " loses " + lost + " health[/color]" });
			}

			local ag = ::Skv.Check.reflex(this, ::Skv.Check.scaledBase(this, 55), 0.5);
			xp.extend(::Skv.XP.checkEach(ag));
			local bitten = 0;
			if ("rows" in ag)
			{
				foreach (cr in ag.rows)
				{
					if (cr.ok || !("bro" in cr) || cr.bro == null) continue;
					local inj = this.biteWound(cr.bro);
					if (inj == null) continue;
					bitten = bitten + 1;
					rows.push({ id = 10, icon = inj.getIcon(), text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]" + cr.bro.getName() + " - " + inj.getNameOnly() + "[/color]" });
				}
			}
			text = "The company goes in with cloaks over their heads and the ceiling comes down on them - not stone, bats, thousands of them, a roaring black wind of wings and teeth that fills the room from wall to wall. It lasts perhaps as long as it takes to say a prayer twice. Then the swarm pours out through the broken side of the tower and is gone, and the men are standing in a foot of droppings, bleeding from a hundred small bites."
				+ (bitten > 0 ? " Not every bite was small." : "") + "\n\n";
		}

		local pr = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, 50));
		local finder = this.m.ActorName;
		if (pr.ok && !this.hasFound(0x04))
		{
			this.m.Found = this.m.Found | 0x04;
			xp.extend(::Skv.XP.check(pr));
			loot.extend(::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/misc/skv_potion_of_cure_light_wounds"])));
			text = text + finder + " kicks something in the rubble that rings like glass, and digs out a stoppered vial, whole, the wax still on it.\n\n";
		}

		local sd = ::Skv.Check.secretDoor(this, ::Skv.Check.scaledBase(this, 50));
		local spotter = this.m.ActorName;
		if (sd.ok)
		{
			this.m.Access = this.m.Access | 0x04;
			xp.extend(::Skv.XP.check(sd));
			text = text + spotter + " stops at the western wall and runs his hand along it.%SPEECH_ON%This is not a wall. It is a door somebody wanted you to think was a wall.%SPEECH_OFF%There is a seam in the stone, and low down in it, a keyhole.";
		}
		else
		{
			text = text + "The western wall bothers somebody - it is too clean, perhaps, or the dust lies wrong along the foot of it - but nobody can say what is wrong with it, and the stair goes on up.";
		}

		this.m.Rooms = this.m.Rooms | 0x020;
		::Skv.dbg("Skv.Fortress: area 6 pot=" + _usePot + " potion=" + pr.ok + " secretDoor=" + sd.ok
			+ "  Rooms=" + this.m.Rooms + " Found=" + this.m.Found + " Access=" + this.m.Access);

		rows.extend(loot);
		rows.extend(xp);
		return this.say("The Bats' Roost", "{" + text + "}", rows, "", image);
	}

	function pickTempleLock()
	{
		local r = ::Skv.Check.lockpick(this, ::Skv.Check.scaledBase(this, 40));
		local who = this.m.ActorName;
		if (r.ok)
		{
			this.m.Access = this.m.Access | 0x200;
			return this.say("The Temple Door", "{" + who + " works at the lock for a long time with his ear against the stone, and then it gives with a sound like a knuckle cracking, and the door swings in.}", ::Skv.XP.check(r), "Temple", "gfx/ui/events/event_178.png");
		}
		this.m.Access = this.m.Access | 0x100;
		::Skv.dbg("Skv.Fortress: temple lock beat the company  Access=" + this.m.Access);
		return this.say("The Temple Door", "{" + who + " works at the lock until his picks are bent and his fingers are bleeding, and it does not give. It is a good lock, far better than the wall it hides behind has any right to.%SPEECH_ON%Whoever sealed this has the key. Find him, and we find the key.%SPEECH_OFF%}", [
			{ id = 10, icon = "ui/icons/special.png", text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]The temple stays locked until the key is found[/color]" } ], "", "gfx/ui/events/event_178.png");
	}

	function templeAltars()
	{
		local rows = [];
		if (!this.hasFound(0x08))
		{
			this.m.Found = this.m.Found | 0x08;
			rows = ::Skv.Loot.haul(::Skv.Loot.make([
				"scripts/items/loot/silverware_item",
				"scripts/items/loot/skv_nethys_symbol",
				"scripts/items/loot/skv_nethys_symbol",
				"scripts/items/accessory/berserker_mushrooms_item",
				"scripts/items/accessory/iron_will_potion_item"
			]));
		}
		return this.say("The Temple of Nethys",
			"{The dead do not stop burning when they fall. The skeletons lie where they came apart, still wrapped in a pale fire that gives off no heat at all, and nobody goes near enough to find out whether it would.\n\nThe altars are what they were: one black, one white, the god of magic in his two faces. On the white altar a plain service of silver, and two holy symbols - a mask, half dark and half light. On the black altar, a twist of dried mushrooms in a cloth, laid there like an offering to the half of the god that breaks things. Behind the white one, a stoppered flask of something that smells of iron.\n\nThe burnt troglodytes by the door came in here and met what the company just met, and lost. Whoever sent them in sealed the room behind them.}",
			rows, "", "gfx/ui/events/event_178.png");
	}

	function tulokChest()
	{
		this.m.Access = this.m.Access | 0x08;
		local rows = [];
		if (!this.hasFound(0x20))
		{
			this.m.Found = this.m.Found | 0x20;
			rows = ::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/misc/skv_potion_of_cure_moderate_wounds"]), 100);
		}
		return this.say("Tulok's Room",
			"{The big one went down last, and it took a long time about it. Still not fully grown, and bigger than any troglodyte the company has seen - and the only one in the tower with a room of its own.\n\nThe brazier is still burning. The knives and pokers laid out on the iron box beside it are clean: whatever they were put there for, somebody told the big one not to use them. Inside the box are a few coins, a sealed bottle, and on a nail above it, a key too small for any door. A manacle key.}",
			rows, "", "gfx/ui/events/event_48.png");
	}

	function pushTopBosses( _p, _fac )
	{
		local ts = ::Const.World.Spawn.Troops.SkvTroglodyteBeastSpeaker;
		_p.Entities.push({
			ID = ts.ID, Variant = 0, Row = ts.Row, Script = ts.Script, Faction = _fac,
			Name = "Tasskar",
			Callback = this.onTasskarPlaced.bindenv(this)
		});
		local hy = ::Const.World.Spawn.Troops.Hyena;
		_p.Entities.push({
			ID = hy.ID, Variant = 0, Row = ("Row" in hy) ? hy.Row : 0, Script = hy.Script, Faction = _fac,
			Name = "Snapjaw",
			Callback = this.onSnapjawPlaced.bindenv(this)
		});
	}

	function onTasskarPlaced( _e, _tag )
	{
		if (_e == null) { ::logError("Skv.Fortress: Tasskar placed as null"); return; }
		local ok = false;
		try { ok = _e.makeMiniboss(); } catch (e) { ::logError("Skv.Fortress: makeMiniboss threw on Tasskar: " + e); }
		::Skv.dbg("Skv.Fortress: Tasskar placed, championed=" + ok);
	}

	function onSnapjawPlaced( _e, _tag )
	{
		if (_e == null) { ::logError("Skv.Fortress: Snapjaw placed as null"); return; }
		local white = null;
		try { white = this.createColor("#ffffff"); } catch (e) { ::logError("Skv.Fortress: createColor threw: " + e); }
		local painted = [];
		foreach (name in ["body", "head", "tail"])
		{
			try
			{
				if (!_e.hasSprite(name)) continue;
				local spr = _e.getSprite(name);
				spr.Saturation = 0.05;
				if (white != null) spr.Color = white;
				spr.setBrightness(1.35);
				painted.push(name + "(sat=" + spr.Saturation + " bright set 1.35)");
			}
			catch (e) { ::Skv.dbg("Skv.Fortress: Snapjaw sprite '" + name + "' not painted: " + e); }
		}
		local list = "";
		foreach (i, t in painted) list = list + (i == 0 ? "" : ", ") + t;
		::Skv.dbg("Skv.Fortress: Snapjaw placed, painted " + painted.len() + ": " + list);
	}

	function topRoute( _east )
	{
		if (!_east)
		{
			this.m.Access = this.m.Access | 0x400;
			return "TopFight";
		}
		this.m.Access = this.m.Access | 0x20;
		local rows = [];
		local r = ::Skv.Check.reflex(this, ::Skv.Check.scaledBase(this, 60), 0.5);
		local fell = [];
		if ("rows" in r)
		{
			foreach (cr in r.rows)
			{
				if (cr.ok || !("bro" in cr) || cr.bro == null) continue;
				local bro = cr.bro;
				local dmg = 0;
				for (local i = 0; i < 6; i = i + 1) dmg = dmg + ::Math.rand(1, 6);
				local hp = bro.getHitpoints() - dmg;
				if (hp < 1) hp = 1;
				local lost = bro.getHitpoints() - hp;
				bro.setHitpoints(hp);
				fell.push(bro.getName());
				rows.push({ id = 10, icon = "ui/icons/health.png", text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]" + bro.getName() + " falls and loses " + lost + " health[/color]" });
			}
		}
		rows.extend(::Skv.XP.checkEach(r));
		::Skv.dbg("Skv.Fortress: east wing, " + fell.len() + " fell  Access=" + this.m.Access);
		local text = fell.len() == 0
			? "The company goes in through the eastern arch fast and spread out, and the floor groans under them and holds. Every man is across."
			: "The company goes in through the eastern arch fast and spread out, and a whole section of the floor goes out from under them with a noise like a cart going over a cliff. The men who were standing on it go down with it, into the dust and the dark of the storey below, and come back up the stair bloody and swearing.";
		return this.say("The Eastern Wing", "{" + text + "\n\nTasskar has turned from the arch. He is not surprised.}", rows, "TopFight", "gfx/ui/events/event_108.png");
	}

	function tasskarChest()
	{
		this.m.Access = this.m.Access | 0x02;
		local rows = [];
		if (!this.hasFound(0x40))
		{
			this.m.Found = this.m.Found | 0x40;
			local items = ::Skv.Loot.make([
				"scripts/items/weapons/shortsword",
				"scripts/items/weapons/knife",
				"scripts/items/weapons/knife",
				"scripts/items/tools/acid_flask_item",
				"scripts/items/tools/acid_flask_item",
				"scripts/items/accessory/cat_potion_item",
				"scripts/items/accessory/recovery_potion_item",
				"scripts/items/loot/skv_amethyst"
			]);
			if ("GolarionEnchant" in ::getroottable())
			{
				for (local i = 0; i < 3 && i < items.len(); i = i + 1)
				{
					local ok = false;
					try { ok = ::GolarionEnchant.setMasterwork(items[i], true); } catch (e) {}
					if (!ok) ::logError("Skv.Fortress: Tasskar's chest item " + i + " refused masterwork");
				}
			}
			rows = ::Skv.Loot.haul(items, 500);
		}
		local templeLine = (this.hasAccess(0x04) && !this.hasRoom(0x040))
			? " Two of the keys on the ring are old and heavy, and one of them was made for the lock in the western wall of the third floor."
			: "";
		return this.say("The Top of the Tower",
			"{Tasskar fought to the end. He was always going to - he stood at that arch every day and looked at the city and told himself what he would do to it, and a man, or a troglodyte, does not surrender a dream like that to a company of sellswords. The white beast fought beside him and died beside him.\n\nThe chest in the eastern wing is his: a good short sword, a pair of fine throwing knives, two flasks of something that smokes where it touches the lid, a pair of stoppered potions, a purple stone, and a purse. On his belt, a ring of keys." + templeLine + "}",
			rows, "", "gfx/ui/events/event_108.png");
	}

	function para( _a, _b )
	{
		if (_a.len() == 0) return _b;
		local tail = "%SPEECH_OFF%";
		if (_a.len() >= tail.len() && _a.slice(_a.len() - tail.len()) == tail) return _a + _b;
		return _a + "\n\n" + _b;
	}

	function hasHanded( _bit ) { return (this.m.Handed & _bit) != 0; }

	function rosterHasRoom()
	{
		return ::World.getPlayerRoster().getSize() < ::World.Assets.getBrothersMax();
	}

	function nethysSymbols()
	{
		local out = [];
		foreach (it in ::World.Assets.getStash().getItems())
		{
			if (it != null && it.getID() == "misc.skv_nethys_symbol") out.push(it);
		}
		return out;
	}

	function countNethysSymbols() { return this.nethysSymbols().len(); }

	function symbolPrice()
	{
		local sum = 0;
		foreach (it in this.nethysSymbols()) sum = sum + it.getValue();
		return ::Math.floor(sum / 2);
	}

	function handSymbols()
	{
		local pay = this.symbolPrice();
		local list = this.nethysSymbols();
		if (list.len() == 0) return "Report";
		foreach (it in list) ::World.Assets.getStash().remove(it);
		this.m.Handed = this.m.Handed | 0x02;
		::World.Assets.addMoralReputation(5);
		local rows = [ ::Legends.EventList.changeMoney(pay),
			{ id = 10, icon = "ui/icons/asset_moral_reputation.png", text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]The holy symbols go home to the temple (reputation +5)[/color]" } ];
		::Skv.dbg("Skv.Fortress: handed " + list.len() + " holy symbols for " + pay);
		return this.say("The Lodge", "{Valsin wraps the masks in a cloth himself, carefully, and counts out the priests' money from his own strongbox.%SPEECH_ON%They will hear who brought them back. That is worth more than the silver, in the long run.%SPEECH_OFF%}", rows, "Report", "gfx/ui/events/skv_grandlodge.png");
	}

	function hireBalenar()
	{
		if (!this.rosterHasRoom()) return "Report";
		local roster = ::World.getTemporaryRoster();
		local dude = roster.create("scripts/entity/tactical/player");
		dude.setStartValuesEx(["minstrel_background"]);
		dude.setName("Balenar Forsend");
		dude.setTitle("the Pathfinder");
		::World.getPlayerRoster().add(dude);
		roster.clear();
		dude.onHired();
		this.m.Balenar = 5;
		::Skv.dbg("Skv.Fortress: Balenar joined the company");
		return this.say("The Lodge", "{Balenar shakes every hand in the company, one after another, and then asks where the baggage is kept.}",
			[ { id = 10, icon = "ui/icons/special.png", text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]Balenar Forsend joins the company[/color]" } ],
			"Report", "gfx/ui/events/skv_grandlodge.png");
	}

	function settle()
	{
		if (this.m.Concluded != 0) return "Paid";
		this.m.Concluded = 1;
		this.m.Outcome = 1;
		if (this.m.Balenar == 2) this.m.Balenar = 6;

		local rows = [];
		rows.push(::Legends.EventList.changeMoney(this.m.Payment.getOnCompletion()));
		::World.Assets.addBusinessReputation(::Const.World.Assets.ReputationOnContractSuccess);
		::World.FactionManager.getFaction(this.getFaction()).addPlayerRelation(
			::Const.World.Assets.RelationCivilianContractSuccess, "Cleared the Fallen Fortress");

		local text = "Valsin counts out the fee without haggling.";
		if (this.m.Balenar == 6)
		{
			rows.push(::Legends.EventList.changeMoney(150));
			text = text + " Then he counts out more, for Forsend, and does not pretend it is not personal.";
		}
		if (this.m.Balenar == 5 || this.m.Balenar == 6)
		{
			rows.push(::Legends.EventList.changeMoney(500));
			text = text + " Forsend's wayfinder goes back into the lodge's strongbox, and the lodge pays for its return the way it pays for all of them.";
		}
		this.m.SayText = text;
		this.m.SayRows = rows;
		::Skv.dbg("Skv.Fortress: concluded, Rooms=" + this.m.Rooms + " Found=" + this.m.Found + " Access=" + this.m.Access
			+ " Balenar=" + this.m.Balenar + " Handed=" + this.m.Handed);
		return "Paid";
	}

	function cellOutcome( _how )
	{
		local rows = [];
		local text = "";
		if (_how == 2)
		{
			this.m.Balenar = 2;
			local hurt = null;
			foreach (bro in ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves()))
			{
				if (bro.getHitpoints() >= bro.getHitpointsMax()) continue;
				if (hurt == null || bro.getHitpoints() * 1.0 / bro.getHitpointsMax() < hurt.getHitpoints() * 1.0 / hurt.getHitpointsMax()) hurt = bro;
			}
			if (hurt != null)
			{
				local before = hurt.getHitpoints();
				hurt.setHitpoints(::Math.min(hurt.getHitpointsMax(), before + ::Math.rand(8, 14)));
				rows.push({ id = 10, icon = "ui/icons/health.png", text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]" + hurt.getName() + " gains " + (hurt.getHitpoints() - before) + " health[/color]" });
			}
			text = "The key turns and the manacles fall open, and it takes the man a long moment to believe it. He gets up slowly.%SPEECH_ON%Balenar Forsend. Pathfinder, of a sort. Valsin sent you? No - Valsin would never admit he sent anyone.%SPEECH_OFF%He lays a hand on the worst-hurt of the company and hums something under his breath, and the wound closes a little. Then he takes a small brass disc on a chain from inside his shirt, the only thing the troglodytes did not find, and presses it into your hand.%SPEECH_ON%My wayfinder. Keep it for me until the lodge. If I carry it out of here, I will lose it again.%SPEECH_OFF%He walks down the stair on his own, and does not look back at the cell.";
		}
		else if (_how == 3)
		{
			this.m.Balenar = 3;
			::World.Assets.addMoralReputation(-10);
			rows.push({ id = 10, icon = "ui/icons/asset_moral_reputation.png", text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]A chained man, put to the sword (-10)[/color]" });
			text = "It is quick. Nobody says much afterwards, and nobody looks at the cell on the way past it.";
		}
		else
		{
			this.m.Balenar = 4;
			text = "You pull the door shut on him. He says something through it, and then he says nothing, and the company goes on up the stair without him.";
		}
		this.m.Rooms = this.m.Rooms | 0x400;
		::Skv.dbg("Skv.Fortress: the cell, Balenar=" + this.m.Balenar + "  Rooms=" + this.m.Rooms);
		return this.say("The Cell", "{" + text + "}", rows, "", "gfx/ui/events/event_100.png");
	}

	function javelinHit( _bro )
	{
		local hit = _bro;
		if (hit == null)
		{
			local roster = ::World.getPlayerRoster().getAll();
			if (roster.len() > 0) hit = roster[::Math.rand(0, roster.len() - 1)];
		}
		if (hit == null)
		{
			return { id = 10, icon = "ui/icons/health.png", text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]A javelin out of the wall[/color]" };
		}
		local inj = hit.addInjury(::Const.Injury.PiercingBody);
		local label = hit.getName() + (inj != null ? " - " + inj.getNameOnly() : " is hit by a javelin");
		return {
			id = 10,
			icon = (inj != null ? inj.getIcon() : "ui/icons/health.png"),
			text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]" + label + "[/color]"
		};
	}

	function hubScreen()
	{
		if (this.m.Concluded != 0) return "Result";
		if (!this.hasRoom(0x001)) return "Approach";
		return "Hub";
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_fortress";

		this.m.Name = "The Fallen Fortress";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A siege castle out on the plain was cracked open by the quake, and something moved into it before the scholars could. A Pathfinder went in after the first of the treasure and has not come back out.",
			"The Society wants a man back. He went into a sealed tower that stopped being sealed a month ago, alone, and whatever is living in it now has had him for a fortnight.",
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

		this.m.DifficultyMult = this.Math.rand(50, 100) * 0.01;

		this.m.Payment.Pool = ::Skv.Econ.pool(this, 300, 0.6, 1.3);

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
					"Hear out the Venture-Captain"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());

				local want = [
					this.Const.World.TerrainType.Plains,
					this.Const.World.TerrainType.Steppe,
					this.Const.World.TerrainType.Badlands,
					this.Const.World.TerrainType.Farmland
				];
				local home = this.Contract.m.Home.getTile();
				local tile = null;
				local tries = 0;

				for ( ; tries < 12 && tile == null; tries = tries + 1 )
				{
					local t = this.Contract.getTileToSpawnLocation(home, 5, 9);
					if (t == null) continue;
					foreach (w in want)
					{
						if (t.Type == w) { tile = t; break; }
					}
				}

				if (tile == null)
				{
					tile = this.Contract.getTileToSpawnLocation(home, 5, 9);
				}

				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_fortress_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);

				::Skv.dbg("Skv.Fortress: tower at " + tile.Coords.X + "," + tile.Coords.Y
					+ " terrain=" + tile.Type
					+ " dist=" + home.getDistanceTo(tile) + " tiles from " + this.Contract.m.Home.getName()
					+ " (rolls=" + tries + (tries >= 12 ? ", GAVE UP ON TERRAIN" : "") + ")");

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}

		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Find a way into the Fallen Fortress",
					"Bring the Pathfinder out"
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

				local won = this.Flags.getAsInt("FortressWon");
				if (won != 0)
				{
					this.Flags.remove("FortressWon");
					this.TempFlags.set("AtSite", true);
					this.Contract.setScreen(this.Contract.afterFight(won));
					this.World.Contracts.showActiveContract();
					return;
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

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 8 || _combatID.slice(0, 8) != "Fortress") return;

				local bit = 0;
				if (_combatID == "FortressDogs")   bit = 0x001;
				if (_combatID == "FortressSpider") bit = 0x002;
				if (_combatID == "FortressHyenas") bit = 0x004;
				if (_combatID == "FortressArmoury") bit = 0x008;
				if (_combatID == "FortressTemple")  bit = 0x040;
				if (_combatID == "FortressSerpents") bit = 0x080;
				if (_combatID == "FortressBarracks") bit = 0x100;
				if (_combatID == "FortressTulok")    bit = 0x200;
				if (_combatID == "FortressTop")      bit = 0x800;

				if (bit == 0)
				{
					::logError("Skv.Fortress: won '" + _combatID + "' but no room maps to it -- add it to onCombatVictory");
					return;
				}

				this.Flags.set("FortressWon", bit);
				::Skv.dbg("Skv.Fortress: victory " + _combatID + " -> bit " + bit);
			}

			function onRetreatedFromCombat( _combatID )
			{
				this.Flags.remove("FortressWon");
				::Skv.dbg("Skv.Fortress: retreated from " + _combatID + "  Rooms=" + this.Contract.m.Rooms);
			}

		});

		this.m.States.push({
			ID = "Return",

			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Bring word to Venture-Captain Valsin",
					"Return to " + this.Contract.homeName()
				];

				if (!::MSU.isNull(this.Contract.m.Destination))
				{
					this.Contract.m.Destination.getSprite("selection").Visible = false;
				}

				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
				{
					this.Contract.m.Home.getSprite("selection").Visible = true;
				}
			}

			function update()
			{

				if (this.Contract.isPlayerAt(this.Contract.m.Home))
				{
					if (!this.TempFlags.get("AtHome"))
					{
						this.TempFlags.set("AtHome", true);
						this.Contract.setScreen("Report");
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtHome", false);
				}
			}

		});
	}

	function createScreens()
	{

		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "The Fallen Fortress",

			Text = "[img]gfx/ui/events/skv_grandlodge.png[/img]{The lodge is two rooms over a chandler's and smells of it. %SKVNAME%Venture-Captain Ambrus Valsin%SKVNAME_OFF% does not stand up when you come in, and does not stop writing for a while after that.%SPEECH_ON%A month ago the ground moved and one of the old siege castles out on the plain came open. Sealed since before anybody's grandfather, and now there is a hole in the side of it you could drive a cart through.%SPEECH_OFF%He puts the pen down.%SPEECH_ON%I have a man in there. Balenar Forsend. He went out to make a name and he did not tell me he was going, which is the sort of thing that gets written on a stone. That was a fortnight past. The tower is not empty. Something has moved into it and it was not scholars. I want him out, and I would rather not send another of my own in after him to find out what the first one found.%SPEECH_OFF%}",
			Image = "",
			List = [],

			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{

				this.Options = [
					{
						Text = "{We will bring your man out.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{A sealed tower. What was it sealed against?}",
						function getResult() { return "Lore"; }
					});
				}

				this.Options.push({
					Text = "{Send another of your own. This is not for us.}",
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
			Title = "What It Was Sealed Against",
			Text = "[img]gfx/ui/events/event_117.png[/img]{%randombrother% has seen the towers on the plain before, from a road, at a distance.%SPEECH_ON%Siege castles. Somebody built a ring of them to take a city and the city is still there, so you can guess how that went. They are full of whoever built them, mostly.%SPEECH_OFF%%randombrother2% is less interested in the history.%SPEECH_ON%Sealed is the part I would want explaining. Nobody seals a tower from the outside. They seal it from the inside, and then they are inside it.%SPEECH_OFF%%randombrother% shrugs.%SPEECH_ON%A month of a hole in the wall is long enough for anything on that plain to have found it and moved in. That is the part I would plan for. Not what was sealed in - what has walked in since.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Back to the Venture-Captain.}",
					function getResult() { return "Task"; }
				}
			]
		});

		this.m.Screens.push({
			ID = "Approach",
			Title = "The Fallen Fortress",
			Text = "[img]gfx/ui/events/event_108.png[/img]{It stands out of the churned ground on its own, and it is bigger than it looked from the road. Four wings, no doors, no windows - the walls are one smooth expanse of stone from the earth to the top.\n\nThe eastern wing has come down. A mountain of rubble lies against that side, and above it the floors stand open to the air, three of them, cut through like a loaf. Only the top level looks whole, and the eastern end of that hangs out over the fall with nothing under it.\n\nAt the bottom, the rubble frames a hole into the dark.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;

				this.Options = [
					{
						Text = "{Walk the foot of it and look the place over.}",
						function getResult()
						{
							return this.Contract.say(
								"The Foot of the Tower",
								"{The hole at the bottom of the rubble is a hole into a ground floor and not into a tower. Whatever stair runs up the middle of this place, it does not start down there - and if the ground floor has a door onto it, the ground floor is where that door stays.\n\nHigher up, the same slope of rubble runs against the broken face of the second storey, and the second storey stands open to the weather. That is the way up, and it is a walk rather than a climb.\n\nNothing else about this tower is a way in. The walls are one piece of stone from the ground to the roof, and the roof hangs out over the fall.}",
								[],
								"");
						}
					},
					{

						Text = "{Cross to the tower.}",
						function getResult()
						{
							return this.Contract.enterRoom(0x001);
						}
					},
					{

						Text = "{Set our gear right - it mends nothing. (open loadout)}",
						function getResult()
						{
							::World.State.showLoadoutFromContract();
							return "Approach";
						}
					},
					{
						Text = "{Leave the tower to itself.}",
						function getResult() { return "Abandon"; }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Dogs",
			Title = "Ravenous Dogs",
			Text = "[img]gfx/ui/events/event_37.png[/img]{Halfway across the open ground a pack of dogs comes off the rubble, all ribs and teeth. Some of them still wear collars. No hand has fed these animals in a long time, and they do not bark. The pack runs low and quiet and straight at whoever is at the end of the line.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Close up and take them.}",
						function getResult()
						{
							this.Contract.startFight(0x001);
							return 0;
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "SpiderLair",
			Title = "The Spider's Lair",
			Text = "[img]gfx/ui/events/event_110.png[/img]{Past the hole in the rubble the ground floor is webbed from floor to ceiling, grey sheets of it thick enough to hold the dust that has settled on them. Something has been wrapped and hung near the back wall - a bundle about the size of a dog.\n\nUp near the ceiling, in the dark, something shifts its weight.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Cut through to it.}",
						function getResult()
						{
							this.Contract.startFight(0x002);
							return 0;
						}
					},
					{
						Text = "{Back out, and think about it.}",
						function getResult()
						{
							return this.Contract.hubScreen();
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Storeroom",
			Title = "The Storeroom",
			Text = "[img]gfx/ui/events/event_148.png[/img]{A storeroom, once. A crack runs down the outer wall and the rain comes in through it, and a puddle stands under it on the floor.\n\nThey are round the puddle when the company comes in - a handful of them, spotted and high-shouldered, and they get up all at once and come trotting over with their heads low and their tails going, the way a dog comes to the man with the bucket. Somebody keeps them here, and they think you have brought dinner.\n\nThey will work out that you have not in about three more steps.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Put them down before they work it out.}",
						function getResult()
						{
							this.Contract.startFight(0x004);
							return 0;
						}
					},
					{
						Text = "{Back out onto the landing.}",
						function getResult()
						{
							return this.Contract.hubScreen();
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Armoury",
			Title = "The Armoury",
			Text = "[img]gfx/ui/events/event_48.png[/img]{The smell reaches the landing before the room does - rotten eggs and an open sewer, and it gets into the back of the throat and stays there. Behind the far door stand racks of old weapons, shields and standards, and among the racks wait troglodytes: squat, grey-scaled lizard-men with javelins in their fists and that stink rolling off their hides.\n\nThese troglodytes are not grown. It shows in the way the young lizard-men stand, bunched too close and too eager, and in how none of them glances back at the door behind for help. No help is coming. No grown troglodyte would follow whoever brought these youngsters here.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Go in hard before the javelins are up.}",
						function getResult()
						{
							this.Contract.startFight(0x008);
							return 0;
						}
					},
					{
						Text = "{Back off down the landing, and think about it.}",
						function getResult()
						{
							return this.Contract.hubScreen();
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "TrapEntry",
			Title = "The Trapped Entry",
			Text = "[img]gfx/ui/events/event_89.png[/img]{Octagonal, and thick with dust, and the dust has not been left alone. Something has walked through it in front of the northwestern door, over and over, and it did not wear boots.\n\nAnd nobody walks through the same doorway that many times without having a reason to want to know who else does.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Read the dust, then see to the door.}",
						function getResult()
						{
							return this.Contract.resolveTrap();
						}
					},
					{
						Text = "{Leave it for now.}",
						function getResult()
						{
							return this.Contract.hubScreen();
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "BatsRoost",
			Title = "The Bats' Roost",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local hasPot = c.findFirePot() != null;

				this.Text = "[img]gfx/ui/events/event_44.png[/img]{The stair comes out on the third floor, and half of the third floor is on the second floor - the eastern side has gone down with the rest and left a ragged edge open to the sky. What is left is dark, and it stinks of droppings, and a living, moving fabric seems to cover the ceiling.\n\nIt rustles. Thousands of small bodies, packed wing to wing, and the moment a light or a man moves under them, the whole ceiling is going to come down."
					+ (hasPot ? " There is a fire pot in the baggage." : "") + "}";

				this.Options = [];
				if (hasPot)
				{
					this.Options.push({
						Text = "{Throw a fire pot into the roost. (spends 1 Fire Pot)}",
						function getResult() { return this.Contract.resolveRoost(true); }
					});
				}
				this.Options.push({
					Text = "{Cover your heads and push through them.}",
					function getResult() { return this.Contract.resolveRoost(false); }
				});
				this.Options.push({
					Text = "{Back down the stair, for now.}",
					function getResult() { return this.Contract.hubScreen(); }
				});
			}

		});

		this.m.Screens.push({
			ID = "TempleDoor",
			Title = "The Temple Door",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/event_178.png[/img]{The seam in the western wall is a door, and the door is locked. It is newer than the wall - somebody hung it, and somebody took the trouble to make it look like stone. There is a smell of old burning from behind it.}";
				this.Options = [];
				if (c.hasAccess(0x02))
				{
					this.Options.push({
						Text = "{Try Tasskar's key.}",
						function getResult()
						{
							this.Contract.m.Access = this.Contract.m.Access | 0x200;
							return "Temple";
						}
					});
				}
				else if (!c.hasAccess(0x100))
				{
					this.Options.push({
						Text = "{Get the lock open.}",
						function getResult() { return this.Contract.pickTempleLock(); }
					});
				}
				this.Options.push({
					Text = "{Leave it.}",
					function getResult() { return this.Contract.hubScreen(); }
				});
			}

		});

		this.m.Screens.push({
			ID = "Temple",
			Title = "The Temple of Nethys",
			Text = "[img]gfx/ui/events/event_178.png[/img]{Two altars, one black and one white, and above them the rotted remains of tapestries and words cut into the stone - the same god, twice, the one who guards and the one who unmakes. Two troglodytes lie burnt to the bone on the floor between the altars, and they did not burn here by accident.\n\nOther things are lying in the rubble by the black altar, and as the company comes in, they get up: skeletons, wrapped in a pale fire that makes no sound and throws no heat, their jaws open in screams nobody can hear.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Put them back down.}",
						function getResult()
						{
							this.Contract.startFight(0x040);
							return 0;
						}
					},
					{
						Text = "{Back out and shut the door on it.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Flooded",
			Title = "The Flooded Chamber",
			Text = "[img]gfx/ui/events/event_149.png[/img]{The western room of the fourth floor stands ankle-deep in black water. Mould and pale fungus furs the walls, and a broken table lies on its side in the middle of the floor.\n\nOne of the things lying in the water is not a fallen beam. It lifts its head. Tasskar keeps a serpent in here, and the troglodytes will not come near the room unless they are made to.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Wade in and kill it.}",
						function getResult()
						{
							this.Contract.startFight(0x080);
							return 0;
						}
					},
					{
						Text = "{Back out onto the stair.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Barracks",
			Title = "The Barracks",
			Text = "[img]gfx/ui/events/event_48.png[/img]{The bunkroom: heaps of rotten straw and hides along the walls, and the stench thick enough to lean on. The troglodytes sleeping in them are only just starting to move - young ones, like the rest, and slow with sleep.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Hit them before they are on their feet.}",
						function getResult()
						{
							this.Contract.startFight(0x100);
							return 0;
						}
					},
					{
						Text = "{Back away before they wake.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "TulokRoom",
			Title = "Tulok's Room",
			Text = "[img]gfx/ui/events/event_48.png[/img]{A brazier of coals burns in the middle of the room, and knives and pokers lie in a neat row on a rusted iron box beside it. The troglodyte standing over them is bigger than any the company has seen - still not fully grown, and already bigger than the grown ones - and it has a few more of them with it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Take the big one down.}",
						function getResult()
						{
							this.Contract.startFight(0x200);
							return 0;
						}
					},
					{
						Text = "{Not yet. Back to the stair.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Cell",
			Title = "The Cell",
			Text = "[img]gfx/ui/events/event_100.png[/img]{The last door on the floor opens on a room no bigger than a cupboard, and there is a man in it, chained by the wrists to the wall. It takes him a few moments to understand that this is not another beating.\n\nHe has been beaten, often, but nothing worse than that - no burns, no cuts, nothing that the knives in the next room were laid out for. He is thin, but not starving. And he does not seem to notice the stench at all.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Unlock the manacles and let him go.}",
						function getResult() { return this.Contract.cellOutcome(2); }
					},
					{
						Text = "{Kill him where he sits in his chains.}",
						function getResult() { return this.Contract.cellOutcome(3); }
					},
					{
						Text = "{Shut the door and leave him to it.}",
						function getResult() { return this.Contract.cellOutcome(4); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "TopOfTower",
			Title = "The Top of the Tower",
			Text = "[img]gfx/ui/events/event_108.png[/img]{The stair comes out in the middle of one great cross-shaped room: four wings, four arches twenty feet high, a rotten carpet running from each of them to the stair. The whole eastern end of the tower hangs out over the fall, and its floor sags.\n\nAt the eastern arch stands a troglodyte in a cloak of feathers and bones, looking out at the city in the distance, and beside him a white beast, a big pale hyena with red eyes. A throne-like chair and a heavy chest stand in the eastern wing behind them. That is Tasskar.\n\nThe quick way to him is straight across the eastern wing, and that floor will not hold many men. The long way is round through the other wings, and gives him time to call up every guard he has left.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Straight across the eastern wing. (every man risks the floor; fewer guards)}",
						function getResult() { return this.Contract.topRoute(true); }
					},
					{
						Text = "{The long way round the other wings. (no risk from the floor; more guards)}",
						function getResult() { return this.Contract.topRoute(false); }
					},
					{
						Text = "{Not yet. Back down the stair.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "TopFight",
			Title = "Tasskar",
			Text = "[img]gfx/ui/events/event_108.png[/img]{Tasskar raises his staff, and the white beast comes forward with its lips drawn back, and from the other wings his last guards come running.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{End it.}",
						function getResult()
						{
							this.Contract.startFight(0x800);
							return 0;
						}
					},
					{
						Text = "{Fall back down the stair.}",
						function getResult() { return this.Contract.hubScreen(); }
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Hub",
			Title = "The Fallen Fortress",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local nxt = c.nextRoom();

				if (nxt == 0)
				{
					this.Text = "{Nothing is moving in the tower that the company did not leave moving. From the top of the stair you can hear the wind going through four archways and nothing else at all.}";
				}
				else if (c.hasAccess(0x01))
				{
					this.Text = "{The stair runs whole from the second floor up, a spiral in the middle of the tower with a landing on every level, and the tower is open above you.}";
				}
				else if (c.hasRoom(0x004))
				{
					this.Text = "{The second-floor landing, open to the weather on its eastern side where the wall came down. The storeroom behind you is quiet now. The far door off the landing is shut, and the stink coming under it is enough to water the eyes.}";
				}
				else if (c.hasRoom(0x002))
				{
					this.Text = "{The ground floor is finished with. The door in the western wing opens onto the stairwell, and the stairwell is packed solid with fallen stone to well above head height - whatever is above this floor is not reached from this floor.\n\nOutside, the rubble runs up against the broken face of the second storey.}";
				}
				else
				{
					this.Text = "{The dogs are quiet. The rubble lies against the broken side of the tower like a ramp somebody left there, and at the bottom of it the stones frame a hole into the dark.}";
				}

				if (c.m.Alert > 0)
				{
					this.Text = this.Text.slice(0, this.Text.len() - 1)
						+ "\n\nThe tower knows you are here. [color=" + ::Const.UI.Color.NegativeEventValue + "]Every fight ahead: +" + c.m.Alert + "%[/color]}";
				}

				this.Options = [];

				if (nxt != 0)
				{
					this.Options.push({
						Text = c.roomRow(nxt).Label,
						function getResult()
						{
							return this.Contract.enterRoom(this.Contract.nextRoom());
						}
					});
				}
				else
				{

					this.Options.push({

						Text = "{We have what we came for. Out of the tower, and back to the lodge.}",
						function getResult()
						{
							this.Contract.setState("Return");
							return "Out";
						}
					});
				}

				if (c.templeOpen())
				{
					this.Options.push({
						Text = c.roomRow(0x040).Label,
						function getResult()
						{
							return this.Contract.enterRoom(0x040);
						}
					});
				}

				this.Options.push({
					Text = "{Set our gear right - it mends nothing. (open loadout)}",
					function getResult()
					{
						::World.State.showLoadoutFromContract();
						return "Hub";
					}
				});

				this.Options.push({
					Text = "{Leave the tower to itself.}",
					function getResult() { return "Abandon"; }
				});
			}

		});

		this.m.Screens.push({
			ID = "Out",
			Title = "Out of the Tower",
			Text = "[img]gfx/ui/events/event_108.png[/img]{You come down eighty feet of somebody else's stair and out through the hole at the bottom of it, and the light is going. The tower stands out of the churned ground behind you exactly as it stood before, which after all of that seems as though it ought to be against some rule.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{The lodge, then.}",
					function getResult() { return 0; }
				}
			]
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "The Lodge",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local t = "[img]gfx/ui/events/skv_grandlodge.png[/img]{%SKVNAME%Venture-Captain Ambrus Valsin%SKVNAME_OFF% hears it out with the pen down, which from him is a considerable courtesy, and does not interrupt once.%SPEECH_ON%A troglodyte. A druid. In a Gorgorite siege castle, in my Cairnlands, with a squad of children behind him.%SPEECH_OFF%";
				if (c.m.Balenar == 2)
				{
					t = c.para(t, "Balenar Forsend is sitting on the bench by the door, thinner than a man ought to be and cleaner than he was in the cell. He stands up when the company comes in.%SPEECH_ON%I sold my kit to pay what I owed. I have nothing to go back to but debts. If your company has room for a man who can sing a wound shut, I would sooner go on with you than sit here.%SPEECH_OFF%");
					if (!c.rosterHasRoom())
						t = c.para(t, "The company is at full strength. There is no place for him unless somebody else gives up theirs.");
				}
				else if (c.m.Balenar == 5)
				{
					t = c.para(t, "Balenar has already gone to find a bedroll among the company's baggage.");
				}
				else if (c.m.Balenar == 3)
				{
					t = t + "%SPEECH_ON%And Forsend?%SPEECH_OFF%Nobody answers quickly enough. Valsin looks from one face to the next, and then writes something down, and does not ask again.";
				}
				else if (c.m.Balenar == 4)
				{
					t = t + "%SPEECH_ON%And Forsend?%SPEECH_OFF%He is told. He sits for a long time with his pen above the page.%SPEECH_ON%You left him in the chains.%SPEECH_OFF%It is not a question, and nobody treats it as one.";
				}
				if (c.countNethysSymbols() > 0 && !c.hasHanded(0x02))
				{
					t = c.para(t, "His eye falls on the silver masks among the company's things.%SPEECH_ON%Those belong to the Temple of Nethys in Absalom. The priests would buy them back, and they would remember who returned them.%SPEECH_OFF%");
				}
				this.Text = t + "}";

				this.Options = [];
				if (c.m.Balenar == 2)
				{
					if (c.rosterHasRoom())
					{
						this.Options.push({
							Text = "{Take him on. (Balenar Forsend joins the company)}",
							function getResult() { return this.Contract.hireBalenar(); }
						});
					}
					else
					{
						this.Options.push({
							Text = "{Make room for him. (open roster - dismiss a man, then come back)}",
							function getResult()
							{
								::World.State.showLoadoutFromContract();
								return "Report";
							}
						});
					}
					this.Options.push({
						Text = "{Send him home. (Valsin pays for his rescue)}",
						function getResult()
						{
							this.Contract.m.Balenar = 6;
							return "Report";
						}
					});
				}
				if (c.countNethysSymbols() > 0 && !c.hasHanded(0x02))
				{
					local n = c.countNethysSymbols();
					this.Options.push({
						Text = "{Give the temple its holy symbols back. (" + n + " symbol" + (n == 1 ? "" : "s") + ", " + c.symbolPrice() + " crowns, reputation +5)}",
						function getResult() { return this.Contract.handSymbols(); }
					});
				}
				this.Options.push({
					Text = "{Our money, Venture-Captain.}",
					function getResult() { return this.Contract.settle(); }
				});
			}

		});

		this.m.Screens.push({
			ID = "Paid",
			Title = "The Lodge",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/skv_grandlodge.png[/img]{" + c.m.SayText + "}";
				this.List = c.m.SayRows == null ? [] : c.m.SayRows;
				this.Options = [
					{
						Text = "{Until the next one.}",
						function getResult()
						{
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}

		});

		this.m.Screens.push({
			ID = "Abandon",
			Title = "Away",
			Text = "{Nobody says much. It is a long way back and the tower does not get smaller behind you for most of it.%SPEECH_ON%He knew what he was walking into. That is worth something, and it is not worth us.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We are done here.}",
						function getResult()
						{
							this.Contract.m.Aborted = 1;
							this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail);
							this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Abandoned the Fallen Fortress");
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					},
					{
						Text = "{No. We came out here for a reason.}",
						function getResult() { return this.Contract.hubScreen(); }
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
				local c = this.Contract;
				this.Title = c.m.SayTitle;
				this.Text = (c.m.SayImage == "" ? "" : "[img]" + c.m.SayImage + "[/img]") + c.m.SayText;
				this.List = c.m.SayRows == null ? [] : c.m.SayRows;
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

		::Skv.Once.release("Fortress");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Fortress");
			if (!::MSU.isNull(this.m.Destination))
			{
				this.m.Destination.getSprite("selection").Visible = false;
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

		_out.writeU16(this.m.Rooms);
		_out.writeU16(this.m.Found);
		_out.writeU16(this.m.Access);
		_out.writeU8(this.m.Balenar);
		_out.writeU8(this.m.Handed);
		_out.writeU8(this.m.Outcome);
		_out.writeU8(this.m.Concluded);
		_out.writeU8(this.m.Aborted);

		_out.writeU8(this.m.Alert);
		_out.writeU16(this.m.Res16);
		_out.writeU32(this.m.Res32);
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

		this.m.Rooms = _in.readU16();
		this.m.Found = _in.readU16();
		this.m.Access = _in.readU16();
		this.m.Balenar = _in.readU8();
		this.m.Handed = _in.readU8();
		this.m.Outcome = _in.readU8();
		this.m.Concluded = _in.readU8();
		this.m.Aborted = _in.readU8();

		this.m.Alert = _in.readU8();
		this.m.Res16 = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.m.ResStr = _in.readString();

		this.contract.onDeserialize(_in);
	}

});
