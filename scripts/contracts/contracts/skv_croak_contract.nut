this.skv_croak_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Destination = null,
		Act       = 0,
		Route     = 0,
		Arrival   = 0,

		Bodies    = 0,
		Outcome   = 0,
		Concluded = 0,
		Res8      = 0,
		Huts      = 0,
		Res16     = 0,
		Res32     = 0,

		Speaker   = "",

		ActorName  = "",
		RouteRows  = null,
		SayTitle   = "",
		SayText    = "",
		SayRows    = null,
		SayNext    = "",
		SayImage   = "",
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

	function hasHut( _bit ) { return (this.m.Huts & _bit) != 0; }
	function setHut( _bit ) { this.m.Huts = this.m.Huts | _bit; }

	function arrivedLate()
	{
		return this.m.Arrival != 1;
	}

	function hubScreen()
	{
		if (this.m.Outcome == 3) return "DrivenOff";

		if (this.m.Act == 0) return "Approach";
		if (this.m.Act == 1) return "Approach";
		return "Huts";
	}

	function fightBudget()
	{
		local C = ::Const.Skv.Croak;
		return this.Math.maxf(C.FightMin, C.FightBase * this.getDifficultyMult() * this.getScaledDifficultyMult());
	}

	function finalPay()
	{
		local pay = this.m.Payment.getOnCompletion();
		if (this.m.Outcome == 3) pay = ::Math.floor(pay * ::Const.Skv.Croak.PoorPayMult);
		return pay;
	}

	function bodyPay()
	{
		return this.m.Bodies * ::Const.Skv.Croak.BodyBounty;
	}

	function moralFor()
	{
		return ::Math.min(3, this.m.Bodies * ::Const.Skv.Croak.MoralPerBody);
	}

	function actorName( _r )
	{
		return (_r.actor != null) ? _r.actor.getName() : "%randombrother%";
	}

	function badRow( _text )
	{
		return { id = 1, icon = "ui/icons/regular_damage.png", text = _text };
	}

	function goodRow( _text )
	{
		return { id = 1, icon = "ui/icons/special.png", text = _text };
	}

	function resolveRoute()
	{

		if (this.m.Arrival != 0) return;
		local C = ::Const.Skv.Croak;
		local rows = [];

		local text;
		local title;
		local img;

		if (this.m.Route == 3)
		{

			this.m.Arrival = 1;
			::World.Assets.addMoney(-C.AskCost);
			title = "What Wrotch Let Slip";
			img = C.ImgTavern;
			text = "{It takes an afternoon and a good deal of somebody else's money. %randombrother% buys drinks for three men who play dice badly and listens to all of it, and somewhere in the middle of the second evening one of them remembers the red-haired dwarf from the post, who could not hold his ale and could not stop talking about the way out there: the cut behind the willow stand, then the poles, then the left-hand channel where the water goes still.\n\nNobody at the post is expecting company. Nobody at the post is expecting anything.}";
			rows.push({ id = 1, icon = "ui/icons/asset_money.png",
				text = "[color=" + ::Const.UI.Color.NegativeEventValue + "]You pay " + C.AskCost + " Crowns[/color]" });
			rows.push(this.goodRow("You know the way, and you will not be expected"));
		}
		else if (this.m.Route == 2)
		{

			local r = ::Skv.Check.brawn(this, ::Skv.Check.scaledBase(this, C.BoatBase), 0.5);
			title = "Up the Channel";
			img = C.ImgChannel;
			if (r.ok)
			{
				this.m.Arrival = 1;
				text = "{The village finds you three flat-bottomed boats and a boy to point at things. The company poles up the channels all morning, through willow and standing water and a smell like a wet cellar, and comes in out of the sun with the poles muffled.\n\nThe huts on their stilts sit quiet ahead. Nothing on the bridges has looked up.}";
				rows.push(this.goodRow("You come in quietly, and early"));
				rows.extend(::Skv.XP.check(r));
			}
			else
			{
				this.m.Arrival = 2;
				text = "{The channels wander. Twice the company poles up a cut that closes into reed and has to back out of it stern-first, and once a boat goes over on a sunken root and everything in it has to be fished up off the bottom.\n\nIt is late afternoon before the post comes in sight, and by then anything out there has had a whole day to hear you coming.}";
				rows.push(this.badRow("Hours lost in the reeds -- you arrive late"));
			}
		}
		else
		{

			this.m.Route = 1;
			local r = ::Skv.Check.tracking(this, ::Skv.Check.scaledBase(this, C.TrailBase));
			local who = this.actorName(r);
			title = "The Sentries' Trail";
			img = C.ImgTrail;
			if (r.ok)
			{
				this.m.Arrival = 1;
				text = "{" + who + " picks the trail up behind the last house in the village and does not lose it once. Four men walked out this way every week for a year, and men who walk the same ground for a year wear it whether they mean to or not: a bent reed here, a flat place there, a plank laid over a soft spot and left.\n\nThe company comes up on the post from the landward side, in the early part of the day, with the sun behind it.}";
				rows.push(this.goodRow("The trail runs straight to the post -- you arrive early"));
				rows.extend(::Skv.XP.check(r));
			}
			else
			{
				this.m.Arrival = 2;
				text = "{" + who + " finds the trail easily enough and loses it just as easily, twice, where the ground goes to water and the reeds have grown back over a year of boots. Each time the company has to cast about for the far side of the gap, and each time it costs the better part of an hour.\n\nThe post comes in sight with the light already going.}";
				rows.push(this.badRow("The trail goes to water twice -- you arrive late"));
			}
		}

		this.m.RouteRows = rows;
		::Skv.dbg("Skv.Croak: ROUTE " + this.m.Route + " -> arrival=" + this.m.Arrival

			+ (this.arrivedLate() ? " (LATE: the warrior will be a champion, enemy Circle)" : " (early: enemy Line)"));

		return;
	}

	function resolveHut( _which )
	{
		local C = ::Const.Skv.Croak;
		local bit;
		local title;
		local text;
		local img;
		if (_which == "north")
		{
			bit = C.HutN;
			img = C.ImgHutN;
			title = "The North Hut";
			text = "{Four bunks, a cold stove, and a line of tally marks scratched into the door frame -- a week of them, then nothing. Somebody kept a fishing float on a nail above his bed and a letter under the mattress, three lines long, unfinished.}";
		}
		else if (_which == "east")
		{
			bit = C.HutE;
			img = C.ImgHutE;
			title = "The East Hut";
			text = "{The bead curtain is torn down and trodden into the boards. Inside, the table is on its side and there is a long smear across the floor to the doorway, gone brown days ago. Whoever was in here did not go quietly and did not go far.}";
		}
		else if (_which == "west")
		{
			bit = C.HutW;
			img = C.ImgHutW;
			title = "The West Hut";
			text = "{The watch hut, facing out over the water: a shuttered window a man can stand at, a stool worn smooth, and a horn on a peg by the sill that was never blown.}";
		}
		else
		{
			bit = C.HutStore;
			img = C.ImgHutS;
			title = "The Store Hut";
			text = "{Rope, tar, spare poles, a barrel of meal with the lid off and something living in it now. The boggards have been through here: everything at head height is untouched and everything low down has been turned over and chewed.}";
		}

		if (this.hasHut(bit)) return "Huts";
		this.setHut(bit);
		::Skv.dbg("Skv.Croak: hut '" + _which + "' looked into. huts=" + this.m.Huts);
		return this.say(title, text, [], "Huts", img);
	}

	function resolveCadmus()
	{
		local C = ::Const.Skv.Croak;
		if (this.hasHut(C.HutSouth)) return "Huts";
		this.setHut(C.HutSouth);
		this.setHut(C.HutCadmusRead);

		local r = ::Skv.Check.perception(this, ::Skv.Check.scaledBase(this, C.CadmusBase));
		local who = this.actorName(r);
		local rows = [];
		local text;
		if (r.ok)
		{
			text = "[img]gfx/ui/events/" + C.ImgGogunta + ".png[/img]{The southernmost hut has had its floor cleared and its walls marked: a wet, looping sign daubed twice on the boards in swamp mud, a thing with a wide mouth and too many limbs. Something has been spending a lot of time deciding.\n\nIn the middle of it a young man lies on his side, wrists bound behind him, mud dried grey all over his face and arms. " + who + " gets a hand flat on his back before anyone cuts anything, and feels it rise. He is breathing. He is only breathing very slowly.}";
			rows.push(this.goodRow("The boy is alive -- and nobody drew steel over a body"));
			rows.extend(::Skv.XP.check(r));
		}
		else
		{
			text = "[img]gfx/ui/events/" + C.ImgGogunta + ".png[/img]{The southernmost hut has had its floor cleared and its walls marked: a wet, looping sign daubed twice on the boards in swamp mud, a thing with a wide mouth and too many limbs. Something has been spending a lot of time deciding.\n\nIn the middle of it a young man lies on his side, wrists bound behind him, mud dried grey all over his face and arms, and for a long moment the whole company takes him for the fourth body. Then he comes awake all at once under " + who + "'s hands, and it takes three men to keep him from going off the boards into the water.}";
			rows.push(this.badRow("You took him for dead, and he woke badly"));
		}

		rows.push({ id = 2, icon = "ui/icons/special.png", text = "Cadmus is cut loose" });
		::Skv.dbg("Skv.Croak: CADMUS found, read=" + (r.ok ? "PASSED" : "failed") + " (he is rescued either way)");
		return this.say("The Southern Hut", text, rows, "Huts", "");
	}

	function resolveGear()
	{
		local C = ::Const.Skv.Croak;
		if (this.hasHut(C.HutGear)) return "Huts";
		this.setHut(C.HutGear);
		local rows = ::Skv.Loot.haul(::Skv.Loot.make(C.GearPaths));
		if (rows.len() == 0) ::logError("Skv.Croak: the sentries' gear did not reach the stash - check the paths in 86_boggard_forces.nut.");
		local text = "{The post's kit is where the post kept it, in a chest under the west hut's window: four sets of leather, patched and re-patched; a crossbow with its cord off and a quiver of bolts beside it; three short swords; and a good axe with a village smith's mark on the head.\n\nCadmus will not hear of leaving any of it. He says the four of them signed for the lot and three of them are not going to be asked about it.}";
		::Skv.dbg("Skv.Croak: gear hauled, " + rows.len() + " row(s)");
		return this.say("The Sentries' Kit", text, rows, "Huts", C.ImgGear);
	}

	function bodiesFromRate( _passed, _total )
	{
		local C = ::Const.Skv.Croak;
		if (_total <= 0) return 0;
		local rate = _passed * 1.0 / _total;
		if (rate >= C.BodiesTier3) return 3;
		if (rate >= C.BodiesTier2) return 2;
		if (rate >= C.BodiesTier1) return 1;
		return 0;
	}

	function resolveBodies()
	{
		local C = ::Const.Skv.Croak;
		if (this.hasHut(C.HutBodies)) return "Huts";
		this.setHut(C.HutBodies);

		local r = ::Skv.Check.brawn(this, ::Skv.Check.scaledBase(this, C.BodiesBase), 0.5);
		this.m.Bodies = this.bodiesFromRate(r.passed, r.total);
		local rows = [];
		local text;

		if (this.m.Bodies == 3)
		{
			text = "{Cadmus walks the bank with a pole and stops three times, and each time he is right. They are deep, and they have been down a while, and getting them up takes every man who can stand in water to his chest and a rope doubled back to the stilts.\n\nArni. Serelle. Wrotch. The company lays all three on the boards, and Cadmus sits down beside them and does not get up for a while.}";
			rows.push(this.goodRow("All three sentries are brought up"));
		}
		else if (this.m.Bodies == 2)
		{
			text = "{Cadmus walks the bank with a pole and stops three times, and each time he is right. Two of them come up between them, slowly, with a rope doubled back to the stilts and half the company standing in water to the chest.\n\nThe third is somewhere under a fallen willow with the weed wrapped through it, and after the second hour nobody can say he is going in there again and mean it.}";
			rows.push(this.goodRow("Two sentries are brought up; one stays in the channel"));
		}
		else if (this.m.Bodies == 1)
		{
			text = "{Cadmus walks the bank with a pole and stops three times, and each time he is right. But the channel bottom is soft as porridge and the weed is wrapped around everything down there, and after the first one comes up the second will not, and the third is somewhere under a fallen willow that nobody is going in after.\n\nOne of them comes home. The company does not settle on which of the other two it would rather have found.}";
			rows.push(this.badRow("One sentry is brought up; two stay in the channel"));
		}
		else
		{
			text = "{Cadmus walks the bank with a pole and stops three times, and each time he is right, and it makes no difference at all. The channel bottom is soft as porridge and the weed has had a fortnight to grow through everything in it. Men go down and come up with handfuls of it and nothing else, over and over, until the light starts to go and somebody says out loud what everyone has been thinking.\n\nCadmus stands on the bank for a long time after the company has stopped. Then he tells them the names again, in case anybody has forgotten which three they were.}";
			rows.push(this.badRow("The channel keeps all three"));
		}

		if (r.ok) rows.extend(::Skv.XP.check(r));

		if (this.m.Bodies > 0)
		{
			rows.push({ id = 3, icon = "ui/icons/asset_money.png",
				text = "The village pays " + C.BodyBounty + " Crowns a man for a burial" });
		}
		::Skv.dbg("Skv.Croak: BODIES " + r.passed + "/" + r.total + " waded through (rate "
			+ (r.total > 0 ? (r.passed * 100 / r.total) : 0) + "%, tiers "
			+ C.BodiesTier1 + "/" + C.BodiesTier2 + "/" + C.BodiesTier3 + ") -> Bodies=" + this.m.Bodies
			+ " bounty=" + this.bodyPay() + " moral=" + this.moralFor() + " checkOk=" + r.ok);
		return this.say("What the Channel Held", text, rows, "Huts", C.ImgBodies);
	}

	function onWarriorPlaced( _e, _tag )
	{
		if (_e == null)
		{
			::logError("Skv.Croak: onWarriorPlaced got a null entity - the warrior is rank and file.");
			return;
		}
		local champ = false;
		try { champ = _e.makeMiniboss(); }
		catch (e) { ::logError("Skv.Croak: makeMiniboss threw on the warrior: " + e); }
		try
		{
			_e.getSkills().update();

			_e.setHitpoints(_e.getHitpointsMax());
		}
		catch (e) { ::logError("Skv.Croak: could not fill the warrior's HP: " + e); }
		::Skv.dbg("Skv.Croak: the blessed warrior is in. champion=" + champ
			+ " HP " + _e.getHitpoints() + "/" + _e.getHitpointsMax());
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_croak";
		this.m.Name = "The Last Croak";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Hunt;
		this.m.DescriptionTemplates = [
			"A watch post out in the marsh has sent no word in two weeks, and the village herbalist wants to know what became of the four who manned it.",
			"Four sentries watched the marsh for two villages. Nobody has heard from them since the moon before last."
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
		local C = ::Const.Skv.Croak;

		this.m.DifficultyMult = this.Math.rand(C.DiffLo, C.DiffHi) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, C.PayBase, C.PayWealthLo, C.PayWealthHi);

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
					"Find the watch post out in the marsh",
					"Bring back word of the four sentries"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				local home = this.Contract.m.Home.getTile();
				local C = ::Const.Skv.Croak;
				local tiles = this.Contract.m.Home.getSurroundingTilesOfType(C.swampTypes(), C.SwampRadius);
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
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_croak_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);
				::Skv.dbg("Skv.Croak: the post is at " + tile.Coords.X + "," + tile.Coords.Y + " terrain=" + tile.Type
					+ " pay=" + this.Contract.finalPay() + " diff=" + this.Contract.getDifficultyMult()
					+ " budget=" + this.Contract.fightBudget());

				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{

				this.Contract.m.BulletpointsObjectives = this.Contract.m.Arrival == 0
					? [
						"Decide how to reach the watch post",
						"Bring back word of the four sentries"
					]
					: [
						"Find the watch post out in the marsh",
						"Bring back word of the four sentries"
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

				local f = this.Flags.get("F17");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V17") == f;
					local fled = this.Flags.get("R17") == f;
					this.Flags.set("F17", "");
					this.Flags.set("V17", "");
					this.Flags.set("R17", "");
					local c = this.Contract;

					if (!won && !fled)
					{
						::Skv.dbg("Skv.Croak: " + f + " was launched but never resolved - no state change.");
					}
					else if (won)
					{
						c.m.Act = 2;
						::Skv.dbg("Skv.Croak: the warren is DEAD -> Act 2 (the huts)");
					}
					else
					{

						c.m.Outcome = 3;
						::Skv.dbg("Skv.Croak: driven off the stilts -> Outcome 3 (POOR, not failed)");
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

			function onCombatPost()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				local tile = c.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv17Post";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) {}

				local late = c.arrivedLate();
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;

				p.EnemyDeploymentType = late
					? ::Const.Tactical.DeploymentType.Circle
					: ::Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];

				p.Entities.push({
					ID = ::Const.EntityType.SkvBoggardWarrior,
					Variant = 0,
					Row = 0,
					Script = "scripts/entity/tactical/enemies/skv_boggard_warrior",
					Faction = fac
				});

				if (late)
				{
					p.Entities[p.Entities.len() - 1].Callback <- c.onWarriorPlaced.bindenv(c);
				}

				local budget = c.fightBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionBoggards, budget,
					fac, "Croak/Warren", ::Const.World.Spawn.GolarionBoggards);
				::Skv.dbg("Skv.Croak: the fight. budget=" + budget
					+ " (" + C.FightBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ ", floor " + C.FightMin + ") units=" + p.Entities.len()
					+ " arrival=" + c.m.Arrival + " route=" + c.m.Route
					+ " deploy=" + (late ? "AMBUSH (Circle) + a CHAMPION warrior" : "Line"));

				this.Flags.set("F17", "Skv17Post");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv17") return;
				this.Flags.set("V17", _combatID);
				::Skv.dbg("Skv.Croak: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F17");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R17", f);
				::Skv.dbg("Skv.Croak: retreated from " + f + " (id=" + _combatID + ")");
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
					catch (e) { ::Skv.dbg("Skv.Croak: getCurrentTown threw - " + e); }
				}
				if (!arrived) return;
				c.setScreen(c.m.Outcome == 3 ? "PoorReport" : "Report");
				this.World.Contracts.showActiveContract();
			}
		});
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);

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
			Title = "The Last Croak",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				if (c.m.Speaker == "") c.m.Speaker = "Ladrusa";
				this.Text = "[img]gfx/ui/events/" + C.ImgGozreh + ".png[/img]{The woman who sends for you is the village's herbalist, %SKVNAME%" + c.m.Speaker + "%SKVNAME_OFF%, and she has the look of somebody who has already counted.%SPEECH_ON%People have been going into the marsh and not coming back out of it all season, and everyone here has decided that is what marshes are for. It is not. Four men watch the water for us and for the big village downstream, a week on and a week off, three out and one home. %SKVNAME%Arni%SKVNAME_OFF%, %SKVNAME%Cadmus%SKVNAME_OFF%, %SKVNAME%Serelle%SKVNAME_OFF%, %SKVNAME%Wrotch%SKVNAME_OFF%. I have stitched every one of them at this table.\n\nNobody has come off that post in a fortnight. I am not asking you to bring them back. I am asking you to go out there, find out what happened to them, and come back and tell me, and I will pay you for the telling.%SPEECH_OFF%She does not ask whether you will go, and she does not ask how you mean to reach the place. That part, she says, is what the money is for.}";

				this.Options = [
					{
						Text = "{We'll find out what became of them.}",
						function getResult() { return "Negotiation"; }
					}
				];
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{What do the men know about that marsh?}",
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
					Text = "{Back to the herbalist.}",
					function getResult() { return "Task"; }
				}
			],
			function start()
			{
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Croak.ImgMarsh + ".png[/img]{%randombrother% has worked marsh country before and is not enthusiastic about it.%SPEECH_ON%Everything out there is on stilts or under the water, and the ground between is neither. You'll be fighting on planks a man wide, and anything that lives there will be walking over the soft parts like they're a road.%SPEECH_OFF%%randombrother2% is thinking about the four names instead.%SPEECH_ON%Three on the post and one at home, she said. So if it went bad, it went bad for three of them. The fourth was in a bed somewhere, and the fourth walked back out there afterwards not knowing.%SPEECH_OFF%}";
			}
		});

		this.m.Screens.push({
			ID = "SettingOut",
			Title = "Which Way In",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				this.Text = "[img]gfx/ui/events/" + C.ImgRoute + ".png[/img]{The company gets out of the herbalist's doorway and stands in the lane with the marsh somewhere off past the last fence, flat and green and further away than it looks.\n\n%randombrother% says the obvious thing: four men walked out to that post every week for a year, and men who walk the same ground for a year leave it behind them whether they mean to or not. %randombrother2% is looking at the water instead, and at the flat-bottomed boats pulled up along it.\n\nAnd there is a third way, which is that %SKVNAME%Wrotch%SKVNAME_OFF% drank in this village on his weeks off, and a dwarf who gambles badly does not stop talking.}";
				this.List = [];
				this.Options = [
					{
						Text = "{Follow the trail they wore walking out.}",
						function getResult()
						{
							this.Contract.m.Route = 1;
							this.Contract.resolveRoute();
							return 0;
						}
					},
					{
						Text = "{Take boats up the channels.}",
						function getResult()
						{
							this.Contract.m.Route = 2;
							this.Contract.resolveRoute();
							return 0;
						}
					},
					{
						Text = "{Buy drinks for whoever played dice with the dwarf. (" + C.AskCost + " Crowns)}",
						function getResult()
						{
							this.Contract.m.Route = 3;
							this.Contract.resolveRoute();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Approach",
			Title = "The Watch Post",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				c.m.Act = 1;

				local late = c.arrivedLate();

				local opening = "The post is six huts perched on legs over the muck, strung together by plank walkways with a rope to hold on to. Nobody out here bothered with doors: strings of beads hang in the doorways instead, and one string lies in the water.\n\nThere are figures out on the bridges, and they are not men. They are squat and wide and wet-looking, the colour of the water, and they move over the planks the way a man moves across his own kitchen.";
				local tail = late
					? "\n\nOne of them is already up on the highest bridge with its head turned this way, and it has been there a while. It fills its throat and lets out a sound like a wet drum, and the rest come up out of the reeds on both sides of you at once.\n\nThe big one in the middle carries a club with something written on it in mud, and the marks are still wet."
					: "\n\nNone of them has looked up yet. The big one in the middle is arguing with a smaller one about something, in a language of grunts and long wet notes, and the company is over the first bridge before either of them turns round.";
				this.Text = "[img]gfx/ui/events/" + ::Const.Skv.Croak.ImgPost + ".png[/img]{" + opening + tail + "}";

				this.List = c.m.RouteRows == null ? [] : clone c.m.RouteRows;
				this.List.push(late
					? { id = 9, icon = "ui/icons/regular_damage.png", text = "They were ready for you, and their champion is blessed" }
					: { id = 9, icon = "ui/icons/special.png", text = "They have not seen you yet" });
				this.Options = [
					{
						Text = late ? "{Back to back. Hold the bridge.}" : "{Take them before they gather.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatPost();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Huts",
			Title = "The Watch Post",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				this.Text = "[img]gfx/ui/events/" + C.ImgHuts + ".png[/img]{The bodies of the frogs lie where they fell, on the planks and half in the water. The post is quiet except for the water moving under it.\n\nSix huts, and nobody has been through any of them in a fortnight.}";
				this.List = [];
				if (c.hasHut(C.HutSouth))
				{
					this.List.push({ id = 1, icon = "ui/icons/special.png", text = "Cadmus is alive and with you" });
				}
				if (c.hasHut(C.HutBodies))
				{

					this.List.push({
						id = 2,
						icon = c.m.Bodies > 0 ? "ui/icons/special.png" : "ui/icons/regular_damage.png",
						text = c.m.Bodies == 3 ? "All three sentries recovered"
							: (c.m.Bodies == 0 ? "The channel kept all three" : c.m.Bodies + " of 3 sentries recovered") });
				}

				this.Options = [];
				if (!c.hasHut(C.HutSouth))
				{
					this.Options.push({
						Text = "{The southern hut. Someone has cleared its floor.}",
						function getResult() { return this.Contract.resolveCadmus(); }
					});
				}
				if (!c.hasHut(C.HutN))
				{
					this.Options.push({
						Text = "{The north hut -- the bunks.}",
						function getResult() { return this.Contract.resolveHut("north"); }
					});
				}
				if (!c.hasHut(C.HutE))
				{
					this.Options.push({
						Text = "{The east hut. Its curtain is torn down.}",
						function getResult() { return this.Contract.resolveHut("east"); }
					});
				}
				if (!c.hasHut(C.HutW))
				{
					this.Options.push({
						Text = "{The west hut, facing the water.}",
						function getResult() { return this.Contract.resolveHut("west"); }
					});
				}
				if (!c.hasHut(C.HutStore))
				{
					this.Options.push({
						Text = "{The store hut.}",
						function getResult() { return this.Contract.resolveHut("store"); }
					});
				}
				if (!c.hasHut(C.HutGear))
				{
					this.Options.push({
						Text = "{Take the post's kit. They signed for it; three of them cannot be asked.}",
						function getResult() { return this.Contract.resolveGear(); }
					});
				}

				if (c.hasHut(C.HutSouth) && !c.hasHut(C.HutBodies))
				{
					this.Options.push({
						Text = "{Let the boy show you where the other three went in.}",
						function getResult() { return this.Contract.resolveBodies(); }
					});
				}
				this.Options.push({
					Text = "{We have what we came for. Back to " + c.m.Home.getName() + ".}",
					function getResult()
					{
						this.Contract.m.Act = 3;
						this.Contract.setState("Return");
						return 0;
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "DrivenOff",
			Title = "Off the Stilts",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				this.Text = "[img]gfx/ui/events/" + C.ImgMarsh + ".png[/img]{The planks are a bad place to lose a fight. The company goes back over the bridges the way it came, with the water on both sides and that wet drumming sound following it out, and does not stop until the reeds are between it and the post.\n\nNobody is going back for the boy. Nobody is going into that channel after the other three.\n\nBut the company has seen the post, and it has seen what is living on it, and that is what " + c.m.Speaker + " sent it out here to find out.}";
				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png", text = "Cadmus is lost, and the three stay in the water" },
					{ id = 2, icon = "ui/icons/special.png", text = "You can still tell her what happened out here" }
				];
				this.Options = [
					{
						Text = "{Back to " + c.m.Home.getName() + ". She'll want to hear it from us.}",
						function getResult()
						{
							this.Contract.m.Act = 3;
							this.Contract.setState("Return");
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "What Became of Them",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				local first = "%SKVNAME%" + c.m.Speaker + "%SKVNAME_OFF% comes out to the lane before the company has stopped walking, and she looks at the faces first and the count second.";
				local second = c.hasHut(C.HutSouth)
					? "Cadmus is on his feet, more or less, with somebody's cloak round him and the mud still in his hair. She takes his head in both hands and turns it to the light like a woman checking a cut, and then she puts her forehead against it and stays there."
					: "She hears the whole of it standing in the lane, and she does not interrupt once.";
				local third = c.m.Bodies > 0
					? "The " + (c.m.Bodies == 1 ? "one they brought back is" : "three they brought back are") + " laid out behind the shrine that evening, and the village buries " + (c.m.Bodies == 1 ? "him" : "them") + " properly, with names."
					: "There is nothing to bury. She says that out loud, once, and then she does not say it again.";
				this.Text = "[img]gfx/ui/events/" + C.ImgGozreh + ".png[/img]{" + first + "\n\n" + second + "\n\n" + third + "}";

				local rows = [];
				rows.push({ id = 1, icon = "ui/icons/asset_money.png",
					text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.finalPay()) + " Crowns" });
				if (c.m.Bodies > 0)
				{
					rows.push({ id = 2, icon = "ui/icons/asset_money.png",
						text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.bodyPay())
							+ " Crowns for " + c.m.Bodies + (c.m.Bodies == 1 ? " burial" : " burials") });
					rows.push({ id = 3, icon = "ui/icons/asset_moral_reputation.png",
						text = "[color=" + ::Const.UI.Color.PositiveEventValue + "]The village buries its own (+" + c.moralFor() + ")[/color]" });
				}
				this.List = rows;

				this.Options = [
					{
						Text = "{We're sorry it wasn't better news.}",
						function getResult()
						{
							local c = this.Contract;
							local C = ::Const.Skv.Croak;
							if (c.m.Concluded == 0)
							{
								c.m.Concluded = 1;
								c.m.Act = 3;
								c.m.Outcome = c.hasHut(C.HutSouth) ? 1 : 2;
								local pay = c.finalPay() + c.bodyPay();
								::World.Assets.addMoney(pay);
								::World.Assets.addBusinessReputation(::Const.World.Assets.ReputationOnContractSuccess);
								local moral = c.moralFor();
								if (moral > 0) ::World.Assets.addMoralReputation(moral);
								local f = ::World.FactionManager.getFaction(c.getFaction());
								if (f != null)
								{
									f.addPlayerRelation(::Const.World.Assets.RelationCivilianContractSuccess,
										"Found out what became of the sentries in the marsh");
								}
								::Skv.dbg("Skv.Croak: ENDING pay=" + pay + " (fee " + c.finalPay() + " + bounty " + c.bodyPay()
									+ ") bodies=" + c.m.Bodies + " moral=" + moral + " cadmus=" + c.hasHut(C.HutSouth)
									+ " huts=" + c.m.Huts + " outcome=" + c.m.Outcome);
							}
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "PoorReport",
			Title = "Word, and Nothing Else",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local C = ::Const.Skv.Croak;
				this.Text = "[img]gfx/ui/events/" + C.ImgGozreh + ".png[/img]{%SKVNAME%" + c.m.Speaker + "%SKVNAME_OFF% listens to all of it in her own doorway: the six huts on their stilts, the torn curtain, the thing squatting on the high bridge that filled its throat and called the others up out of the water. She asks twice how many there were and once whether any of them were men.\n\nThen she pays what she said she would pay, counted out of a cup on the shelf, and it is less than the company hoped and exactly what was agreed for the telling.%SPEECH_ON%You found the post and you came back. That is what I asked for, and I will not pretend otherwise in front of the village.%SPEECH_OFF%She does not say the rest of it. She does not have to: three names are still out there in the water, and the fourth is out there alive.}";
				this.List = [
					{ id = 1, icon = "ui/icons/asset_money.png",
						text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.finalPay()) + " Crowns for the news" },
					{ id = 2, icon = "ui/icons/regular_damage.png", text = "The village got word, and nothing it wanted" }
				];
				this.Options = [
					{
						Text = "{We'd have brought them back if we could.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Concluded == 0)
							{
								c.m.Concluded = 1;
								c.m.Act = 3;
								local pay = c.finalPay();
								::World.Assets.addMoney(pay);
								local A = ::Const.World.Assets;
								::World.Assets.addBusinessReputation(A.ReputationOnContractPoor);
								local f = ::World.FactionManager.getFaction(c.getFaction());
								if (f != null)
								{
									f.addPlayerRelation(A.RelationCivilianContractPoor,
										"Came back from the marsh with word and no one else");
								}
								::Skv.dbg("Skv.Croak: POOR ENDING pay=" + pay + " (x" + ::Const.Skv.Croak.PoorPayMult
									+ ") renown=" + A.ReputationOnContractPoor + " -- a poor result, NOT a failure");
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
		::Skv.Once.release("Croak");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Croak");

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
		_out.writeU8(this.m.Route);
		_out.writeU8(this.m.Arrival);
		_out.writeU8(this.m.Bodies);
		_out.writeU8(this.m.Outcome);
		_out.writeU8(this.m.Concluded);
		_out.writeU8(this.m.Res8);
		_out.writeU16(this.m.Huts);
		_out.writeU16(this.m.Res16);
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
		this.m.Route = _in.readU8();
		this.m.Arrival = _in.readU8();
		this.m.Bodies = _in.readU8();
		this.m.Outcome = _in.readU8();
		this.m.Concluded = _in.readU8();
		this.m.Res8 = _in.readU8();
		this.m.Huts = _in.readU16();
		this.m.Res16 = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.m.Speaker = _in.readString();
		this.contract.onDeserialize(_in);
	}
});
