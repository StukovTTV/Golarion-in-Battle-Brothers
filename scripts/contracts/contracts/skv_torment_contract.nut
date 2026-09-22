this.skv_torment_contract <- this.inherit("scripts/contracts/contract", {
	m = {

		Destination = null,
		Act       = 0,

		Approach  = 0,
		Outcome   = 0,

		Searched  = 0,
		Concluded = 0,
		Res8      = 0,
		Marks     = 0,

		Res32     = 0,
		Speaker   = "",

		ActorName   = "",
		ApproachRows = null,
		TalkRows     = null,
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

	function fight1Lost()
	{
		return (this.m.Marks & ::Const.Skv.Torment.MarkFight1Lost) != 0;
	}

	function hubScreen()
	{
		if (this.m.Act == 0) return "Trail";
		if (this.m.Act == 1)
		{
			if (this.m.Approach == 0) return "Trail";
			if (this.fight1Lost())   return "BackUp";
			return this.m.Approach == 1 ? "Caught" : "CampUp";
		}
		if (this.m.Act == 2) return "Cave";
		if (this.m.Act == 3)
		{
			if (this.m.Outcome == 2) return "WrongWords";
			if (this.m.Outcome == 3) return "Protest";
			return "Stones";
		}

		if (this.m.Outcome == 1) return "Homecoming";
		if (this.m.Outcome == 4) return "ThroughStones";
		return "Aftermath";
	}

	function onOgrePlaced( _entity, _tag )
	{
		if (_entity == null)
		{
			::logError("Skv.Torment: onOgrePlaced got a null entity - the ogre is SOBER (stock stats).");
			return;
		}

		try
		{
			local T = ::Const.Skv.Torment;
			local b = _entity.getBaseProperties();
			local hp0 = b.Hitpoints, ms0 = b.MeleeSkill, md0 = b.MeleeDefense, in0 = b.Initiative;

			b.Hitpoints    = this.Math.floor(hp0 * T.OgreHitpoints);
			b.MeleeSkill   = this.Math.floor(ms0 * T.OgreMeleeSkill);
			b.MeleeDefense = this.Math.floor(md0 * T.OgreMeleeDefense);
			b.Initiative   = this.Math.floor(in0 * T.OgreInitiative);
			_entity.getSkills().update();

			local champ = false;
			if (this.ogreIsChampion())
			{
				try
				{
					champ = _entity.makeMiniboss();
					_entity.getSkills().update();
				}
				catch (e)
				{
					::logError("Skv.Torment: makeMiniboss threw - the ogre fights as a plain drunk: " + e);
				}
			}
			::Skv.dbg("Skv.Torment: ogre champion=" + champ + " (raw budget " + this.ogreBudget()
				+ (this.ogreIsChampion() ? " >= " : " < ") + T.OgreChampionBudget + ")");

			_entity.setHitpoints(_entity.getHitpointsMax());

			::Skv.dbg("Skv.Torment: the ogre is drunk. HP " + hp0 + " -> " + b.Hitpoints
				+ ", Melee " + ms0 + " -> " + b.MeleeSkill
				+ ", MDef " + md0 + " -> " + b.MeleeDefense
				+ ", Init " + in0 + " -> " + b.Initiative
				+ ", current HP " + _entity.getHitpoints() + "/" + _entity.getHitpointsMax());
		}
		catch (e)
		{
			::logError("Skv.Torment: could not make the ogre drunk (he fights sober): " + e);
		}
	}

	function ogreBudget()
	{
		return ::Const.Skv.Torment.BandBase * this.getDifficultyMult() * this.getScaledDifficultyMult();
	}

	function ogreIsChampion()
	{
		return this.ogreBudget() >= ::Const.Skv.Torment.OgreChampionBudget;
	}

	function bandBudget()
	{
		local T = ::Const.Skv.Torment;
		return this.Math.maxf(T.BandMin, T.BandBase * this.getDifficultyMult() * this.getScaledDifficultyMult() - T.OgreCharge);
	}

	function wolfBudget()
	{
		local T = ::Const.Skv.Torment;
		return this.Math.maxf(1.0, T.WolfBase * this.getDifficultyMult() * this.getScaledDifficultyMult() - T.HaanarCharge);
	}

	function finalPay()
	{
		return this.m.Payment.getOnCompletion();
	}

	function relationFor( _outcome )
	{
		local A = ::Const.World.Assets;
		if (_outcome == 1) return A.RelationCivilianContractSuccess * 2.0;
		return A.RelationCivilianContractPoor;
	}

	function renownFor( _outcome )
	{
		local A = ::Const.World.Assets;
		if (_outcome == 1) return A.ReputationOnContractSuccess;
		if (_outcome == 2 || _outcome == 3) return A.ReputationOnContractPoor;
		return 0;
	}

	function moralFor( _outcome )
	{
		if (_outcome == 1) return 3;
		if (_outcome == 2) return -3;
		if (_outcome == 3) return -6;
		return 0;
	}

	function applyMoral( _outcome )
	{
		local n = this.moralFor(_outcome);
		if (n != 0) ::World.Assets.addMoralReputation(n);
		::Skv.dbg("Skv.Torment: moral reputation " + (n > 0 ? "+" : "") + n + " (outcome " + _outcome + ")");
	}

	function moralRow( _outcome )
	{
		local n = this.moralFor(_outcome);
		if (n == 0) return null;
		local text = _outcome == 1 ? "A village boy brought home"
			: _outcome == 2 ? "Haanar, cut down after the words failed"
			: "Haanar, killed without a word";
		local col = n > 0 ? ::Const.UI.Color.PositiveEventValue : ::Const.UI.Color.NegativeEventValue;
		return { id = 10, icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + col + "]" + text + " (" + (n > 0 ? "+" : "") + n + ")[/color]" };
	}

	function setFate( _n )
	{
		::World.Flags.set("SkvHaanarFate", _n);
		::Skv.dbg("Skv.Torment: SkvHaanarFate = " + _n);
	}

	function resolveSneak()
	{
		local T = ::Const.Skv.Torment;
		local r = ::Skv.Check.stealth(this, ::Skv.Check.scaledBase(this, T.SneakBase), 0.5);
		local rows = [];
		if (r.ok)
		{
			this.m.Approach = 1;
			rows.push({ id = 1, icon = "ui/icons/special.png", text = "The camp is caught around its fire" });
		}
		else
		{
			this.m.Approach = 2;
			rows.push({ id = 1, icon = "ui/icons/regular_damage.png",
				text = "The camp saw you coming, and you are surrounded" });
		}
		rows.push({ id = 2, icon = "ui/icons/special.png",
			text = r.passed + " of " + r.total + " made it up quietly" });

		rows.extend(::Skv.XP.checkEach(r));
		this.m.ApproachRows = rows;
		::Skv.dbg("Skv.Torment: sneak " + (r.ok ? "PASSED" : "FAILED") + " " + r.passed + "/" + r.total
			+ " (needed " + r.needed + ") -> Approach=" + this.m.Approach);
		return this.m.Approach == 1 ? "Caught" : "CampUp";
	}

	function resolveTalk()
	{
		local T = ::Const.Skv.Torment;
		local r = ::Skv.Check.charm(this, ::Skv.Check.scaledBase(this, T.TalkBase));
		local name = r.actor != null ? r.actor.getName() : "Your man";
		this.m.Speaker = name;
		local rows = [];
		if (r.ok)
		{
			this.m.Outcome = 1;
			this.m.Act = 4;
			this.setFate(1);
			rows.push({ id = 1, icon = "ui/icons/special.png", text = "Haanar walks home with you" });
			this.applyMoral(1);
			rows.push(this.moralRow(1));
			rows.extend(::Skv.XP.check(r));
			rows.extend(::Skv.XP.partyEach(T.TalkXP));
			this.m.TalkRows = rows;
			::Skv.dbg("Skv.Torment: TALKED DOWN by " + name + " -> Outcome 1, no second fight");
			return "Homecoming";
		}

		this.m.Outcome = 2;
		rows.push({ id = 1, icon = "ui/icons/regular_damage.png", text = "Haanar will not be talked down" });
		this.m.TalkRows = rows;
		::Skv.dbg("Skv.Torment: the talk FAILED (" + name + ") -> Outcome 2, fight 2");
		return "WrongWords";
	}

	function resolveSearch()
	{
		if (this.m.Searched != 0) return "Cave";
		this.m.Searched = 1;
		local T = ::Const.Skv.Torment;
		local items = ::Skv.Loot.make(T.CavePaths);
		local rows = ::Skv.Loot.haul(items, T.CaveCoin);
		::Skv.dbg("Skv.Torment: cave searched - " + items.len() + " items + " + T.CaveCoin + " crowns");
		local text = "{It takes a strong stomach and a long stick. Under the bones and the filth: a carved ivory chess piece, a clouded crystal that hums faintly when you hold it, a jade brooch carved with a weeping angel, and a handful of mixed coin.\n\nAnd a little onyx dog no longer than a finger. When %randombrother% sets it on the floor to get a better look, it shakes itself, sneezes, and is a dog: lean, grey, and already wagging.}";
		return this.say("The Ogre's Cave", text, rows, "Cave", "event_154");
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_torment";
		this.m.Name = "Torment and Legacy";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Hunt;
		this.m.DescriptionTemplates = [
			"An ogre walked into the village in broad daylight, stuffed the old sage into a sack and ran for the hills, laughing. He shouted a name as he went.",
			"The village sage has been carried off into the hills by an ogre. His granddaughter is offering everything she has to see him home."
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
		local T = ::Const.Skv.Torment;

		this.m.DifficultyMult = this.Math.rand(65, 105) * 0.01;
		this.m.Payment.Pool = ::Skv.Econ.pool(this, T.PayBase, T.PayWealthLo, T.PayWealthHi);

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
					"Follow the ogre into the hills",
					"Bring the sage Lazino home to " + this.Contract.m.Home.getName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				local home = this.Contract.m.Home.getTile();
				local tiles = this.Contract.m.Home.getSurroundingTilesOfType([this.Const.World.TerrainType.Hills], 3);
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
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_torment_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);
				::Skv.dbg("Skv.Torment: hill at " + tile.Coords.X + "," + tile.Coords.Y
					+ " terrain=" + tile.Type
					+ (tile.Type == this.Const.World.TerrainType.Hills ? " (Hills)" : " (NOT Hills -- fallback ran)")
					+ " pay=" + this.Contract.finalPay());
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Follow the ogre's trail into the hills",
					"Bring Lazino home"
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

				local f = this.Flags.get("F15");
				if (f != null && f != false && f != "")
				{
					local won = this.Flags.get("V15") == f;
					local fled = this.Flags.get("R15") == f;
					this.Flags.set("F15", "");
					this.Flags.set("V15", "");
					this.Flags.set("R15", "");
					local c = this.Contract;

					if (!won && !fled)
					{
						::Skv.dbg("Skv.Torment: " + f + " was launched but never resolved - no state change.");
					}
					else if (f == "Skv15Ogre")
					{
						if (won)
						{
							c.m.Act = 2;
							::Skv.dbg("Skv.Torment: the ogre's camp TAKEN -> Act 2");
						}
						else
						{
							c.m.Marks = c.m.Marks | ::Const.Skv.Torment.MarkFight1Lost;
							::Skv.dbg("Skv.Torment: driven off the hill -> Marks=" + c.m.Marks
								+ " (1 fight-1-lost); every re-attack is an ambush");
						}
					}
					else if (f == "Skv15Haanar")
					{
						c.m.Act = 4;
						if (won)
						{
							c.setFate(c.m.Outcome == 2 ? 2 : 3);
							c.applyMoral(c.m.Outcome);
							::Skv.dbg("Skv.Torment: Haanar KILLED, Outcome " + c.m.Outcome);
						}
						else
						{
							c.m.Outcome = 4;
							c.setFate(4);
							::Skv.dbg("Skv.Torment: driven off by Haanar -> Outcome 4, he is gone east");
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

			function onCombatOgre()
			{
				local c = this.Contract;
				local T = ::Const.Skv.Torment;
				local tile = c.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv15Ogre";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) {}

				local ambush = c.m.Approach == 2 || c.fight1Lost();
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
				p.EnemyDeploymentType = ambush
					? ::Const.Tactical.DeploymentType.Circle
					: ::Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];
				p.Entities.push({
					ID = ::Const.EntityType.Unhold,
					Variant = 0,
					Row = 0,
					Script = "scripts/entity/tactical/enemies/unhold",
					Faction = fac,
					Name = T.OgreName,
					Callback = c.onOgrePlaced.bindenv(c)
				});

				local budget = c.bandBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionTormentBand, budget,
					fac, "Torment/Band", ::Const.World.Spawn.GolarionTormentBand);
				::Skv.dbg("Skv.Torment: fight 1 band budget=" + budget
					+ " (" + T.BandBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ " - ogre " + T.OgreCharge + ") units=" + p.Entities.len()
					+ " champion=" + c.ogreIsChampion()
					+ " deploy=" + (ambush ? "AMBUSH (Circle)" : "Line")
					+ " approach=" + c.m.Approach + " lostBefore=" + c.fight1Lost());

				this.Flags.set("F15", "Skv15Ogre");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatHaanar()
			{
				local c = this.Contract;
				local T = ::Const.Skv.Torment;
				local tile = c.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Skv15Haanar";
				try { p.Music = ::Const.Music.BeastsTracks; } catch (e) {}
				p.PlayerDeploymentType = ::Const.Tactical.DeploymentType.LineBack;
				p.EnemyDeploymentType = ::Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID();
				p.Entities = [];
				p.Entities.push({
					ID = ::Const.EntityType.Wildman,
					Variant = 0,
					Row = 2,
					Script = "scripts/entity/tactical/enemies/skv_haanar",
					Faction = fac,
					Name = T.HaanarName
				});

				local budget = c.wolfBudget();
				::Skv.Spawn.fill(p.Entities, ::Const.World.Spawn.GolarionTormentWolves, budget,
					fac, "Torment/Wolves", ::Const.World.Spawn.GolarionTormentWolves);
				::Skv.dbg("Skv.Torment: fight 2 wolf budget=" + budget
					+ " (" + T.WolfBase + " x diff " + c.getDifficultyMult() + " x scaled " + c.getScaledDifficultyMult()
					+ " - Haanar " + T.HaanarCharge + ") units=" + p.Entities.len()
					+ " outcome=" + c.m.Outcome);

				this.Flags.set("F15", "Skv15Haanar");
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == null || typeof _combatID != "string") return;
				if (_combatID.len() < 5 || _combatID.slice(0, 5) != "Skv15") return;
				this.Flags.set("V15", _combatID);
				::Skv.dbg("Skv.Torment: victory id=" + _combatID);
			}

			function onRetreatedFromCombat( _combatID )
			{
				local f = this.Flags.get("F15");
				if (f == null || f == false || f == "") return;
				this.Flags.set("R15", f);
				::Skv.dbg("Skv.Torment: retreated from " + f + " (id=" + _combatID + ")");
			}
		});

		this.m.States.push({
			ID = "Return",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Bring Lazino home to " + this.Contract.m.Home.getName()
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
					catch (e) { ::Skv.dbg("Skv.Torment: getCurrentTown threw - " + e); }
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
			Title = "Torment and Legacy",
			Text = "[img]gfx/ui/events/event_97.png[/img]{%employer% is not alone. A girl stands at his elbow, holding a purse so small it hardly bends her fingers.%SPEECH_ON%An ogre walked into %townname% this morning, bold as noon. He picked up old %SKVNAME%Lazino%SKVNAME_OFF%, our sage, the man who set half the bones in this village and taught the other half their letters. He stuffed him into a grain sack and bellowed that %SKVNAME%Haanar%SKVNAME_OFF% wants to speak with him. Then he ran for the hills, laughing.%SPEECH_OFF%The girl steps forward before he can go on.%SPEECH_ON%I'm %SKVNAME%Leyla%SKVNAME_OFF%. He's my grandfather. This is everything I have. I know it isn't much. Please bring him home.%SPEECH_OFF%%employer% lays a hand on her shoulder.%SPEECH_ON%Haanar is an exile. We drove him out some winters back, after he took to dabbling in things decent folk leave alone. What he wants with an old man, I couldn't tell you. The village will add what it can scrape together to the girl's purse. As for the trail, an ogre does not walk softly.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We'll bring him home.}",
						function getResult() { return "Negotiation"; }
					}
				];
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{What do the men know about ogres?}",
						function getResult() { return "Lore"; }
					});
				}
				this.Options.push({
					Text = "{We can't help you.}",
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
			Text = "[img]gfx/ui/events/event_97.png[/img]{%randombrother% speaks up.%SPEECH_ON%Ogres sell their fists to whoever pays in meat, and they drink whatever they steal. Catch one after sunset and he'll have emptied a barrel. Loud, slow, and still strong enough to pull your arm off.%SPEECH_OFF%%randombrother2% nods toward the hills.%SPEECH_ON%They don't sit alone, either. Something smaller always squats at an ogre's fire, living off his scraps. Count on more than one of them up there.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. Back to the girl.}",
					function getResult() { return "Task"; }
				}
			]
		});

		this.m.Screens.push({
			ID = "Trail",
			Title = "The Ogre's Trail",
			Text = "[img]gfx/ui/events/event_42.png[/img]{The trail is no trouble at all. Deep prints sunk in the rain-soft ground, then a shaggy cow torn open and left for the crows, and on from there. As the sun sets, a fire flickers on a hilltop ahead. The smell of roasting meat drifts down, and then a man's scream, and then a laugh like a rockslide.%SPEECH_ON%Stop your crying, or I'll put you on my hook and cook you all crispy!%SPEECH_OFF%%randombrother% squints up the slope.%SPEECH_ON%He's been at a barrel, that one. Listen to him. And he isn't alone. There's shapes round that fire, low ones, squatting.%SPEECH_OFF%The trail climbs straight up through the mud, between boulders. If the whole company keeps quiet, it could reach the fire before anyone up there looks round. It only takes one man's clumsy step to spoil it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Contract.m.Act = this.Contract.m.Act < 1 ? 1 : this.Contract.m.Act;
				this.Options = [
					{
						Text = "{Up the trail, quietly.}",
						function getResult() { return this.Contract.resolveSneak(); }
					},
					{
						Text = "{Not yet. Pull back and rest.}",
						function getResult() { return 0; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Caught",
			Title = "Caught at the Fire",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{

				local big = this.Contract.ogreIsChampion()
					? " He is the biggest ogre anyone here has ever seen, and the old scars across his chest were left by things that lost."
					: "";
				this.Text = "[img]gfx/ui/events/legend_cannibal_recruitment.png[/img]{Nobody looks up until your front rank is already among the boulders. The ogre sprawls against his barrel, a hook the size of a scythe blade across his knees, singing something tuneless and slurring half the words." + big + " The cave folk crouch around the cow, tearing at it.\n\nAnd over the fire's edge, trussed like a goose and hanging from a spit-pole, is an old man who has stopped screaming and started praying.}";
				this.List = this.Contract.m.ApproachRows == null ? [] : this.Contract.m.ApproachRows;
				this.Options = [
					{
						Text = "{Now!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatOgre();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CampUp",
			Title = "The Camp Is Up",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local big = this.Contract.ogreIsChampion()
					? " Standing, he is the biggest ogre anyone here has ever seen, and the old scars across his chest were left by things that lost."
					: "";
				this.Text = "[img]gfx/ui/events/event_29.png[/img]{Halfway up, a boot turns a stone and it goes clattering down the slope. The fire goes quiet.\n\nThen the hissing starts: not from the fire, but from the boulders all around you, where the squatting shapes have already slipped into the dark. A wave of stink rolls in from every side. Up the hill the ogre heaves himself to his feet, sways, and catches himself on the barrel. Drunk, but not that drunk." + big + "%SPEECH_ON%More meat! Come up, come up!%SPEECH_OFF%}";
				this.List = this.Contract.m.ApproachRows == null ? [] : this.Contract.m.ApproachRows;
				this.Options = [
					{
						Text = "{Up and at them.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatOgre();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "BackUp",
			Title = "Back Up the Hill",
			Text = "[img]gfx/ui/events/event_44.png[/img]{The fire is still burning on the hilltop, but nobody is sitting around it now. The ogre's bellowing carries down the slope, thick with drink, and there's no sign of the cave folk at all, which is worse.\n\nThey know you're coming back.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png", text = "The camp is waiting for you in the rocks" }
				];
				this.Options = [
					{
						Text = "{Up the hill.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatOgre();
							return 0;
						}
					},
					{
						Text = "{Not yet. Pull back and lick our wounds.}",
						function getResult() { return 0; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Cave",
			Title = "The Ogre's Cave",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.Text = "[img]gfx/ui/events/event_154.png[/img]{The ogre goes down like a felled oak and doesn't get up. You cut %SKVNAME%Lazino%SKVNAME_OFF% down from the pole. He's bruised, singed along one sleeve, and furious the way only an old man who's just been called crispy can be.%SPEECH_ON%Haanar? I haven't the faintest notion what the boy wants with me. The brute said a strange man promised them gold and meat. Gold and meat! For me!%SPEECH_OFF%Behind the fire a low cave mouth breathes out mushroom rot and worse. The ogre has been living in there, and sleeping on whatever he took off the people he ate.\n\nOnce you head down the far side of this hill, you won't be climbing it again.}";
				this.List = [];
				this.Options = [];
				if (c.m.Searched == 0)
				{
					this.Options.push({
						Text = "{Search the cave.}",
						function getResult() { return this.Contract.resolveSearch(); }
					});
				}
				this.Options.push({
					Text = "{Take Lazino home.}",
					function getResult()
					{
						this.Contract.m.Act = 3;
						return "Stones";
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "Stones",
			Title = "The Standing Stones",
			Text = "[img]gfx/ui/events/event_101.png[/img]{The path down the far side runs through a ring of standing stones, one of them toppled. As you pass between them, they begin to glow a deep emerald. The air fills with the smell of wet leaves, and a young man steps out of the light as though through a doorway.\n\nHe is almost human. His fingers are too long, and one eye is green and the other grey. He's angry to the roots of his teeth. A crystal-headed staff is in his hand and a wolf pads at his heel.%SPEECH_ON%Lazino. You will tell me the truth of my birth.%SPEECH_OFF%The old man goes white. Then, to everyone's surprise, he pushes past your shield line.%SPEECH_ON%Twenty years ago a woman came to Ragir Grenvill's farm. Stayed a fortnight and was gone. Nine months later there was a baby on his step. You, lad. I knew what she was, Haanar. A hag. I said nothing, because I hoped Ragir's love would raise you right, and he died never telling you, and I let him. I was wrong. But it isn't too late. You could still find a place with us!%SPEECH_OFF%The staff dips an inch. The wolf stops growling. Haanar isn't calm, but for the moment he's listening, and he won't listen for long. One of you has to find the right words while he still hears them. If they're the wrong words, he'll fight.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Talk him down.}",
						function getResult() { return this.Contract.resolveTalk(); }
					},
					{
						Text = "{Draw steel.}",
						function getResult()
						{
							this.Contract.m.Outcome = 3;
							::Skv.dbg("Skv.Torment: DRAW STEEL -> Outcome 3, fight 2");
							return "Protest";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Homecoming",
			Title = "Homecoming",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local who = c.m.Speaker == "" ? "One of your men" : c.m.Speaker;
				this.Text = "[img]gfx/ui/events/event_17.png[/img]{" + who + " sets down his weapon and walks forward with empty hands. He doesn't talk about hags. He talks about a farmer who fed a foundling every day for twenty years, knowing nothing and never once asking.\n\nFor a long moment Haanar says nothing. Then the light in the stones gutters out.%SPEECH_ON%For years something has been pulling at me. East, into the hills. I thought I was going mad. Now I think it's her.%SPEECH_OFF%He looks at Lazino for a long time.%SPEECH_ON%I'll come home. I'll try. I don't know if I can be what my father wanted.%SPEECH_OFF%Lazino puts a hand on his arm, the way you would steady a colt.%SPEECH_ON%Nobody can, lad. You try anyway.%SPEECH_OFF%}";
				this.List = c.m.TalkRows != null ? c.m.TalkRows
					: [{ id = 1, icon = "ui/icons/special.png", text = "Haanar walks home with you" }];
				this.Options = [
					{
						Text = "{Home, then. All of us.}",
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
			ID = "WrongWords",
			Title = "The Wrong Words",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local who = c.m.Speaker == "" ? "Your man" : c.m.Speaker;
				this.Text = "[img]gfx/ui/events/event_118.png[/img]{" + who + " speaks, and every word is true, and the one that lands is \"pity\". Haanar's eyes flare the same green as the stones. The wolf lunges before its master has finished shouting.}";
				this.List = c.m.TalkRows != null ? c.m.TalkRows
					: [{ id = 1, icon = "ui/icons/regular_damage.png", text = "Haanar will not be talked down" }];
				this.Options = [
					{
						Text = "{Here he comes!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatHaanar();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Protest",
			Title = "Steel Drawn",
			Text = "[img]gfx/ui/events/event_118.png[/img]{%SPEECH_ON%No! Wait, he's only a boy, he's...%SPEECH_OFF%The rest is lost as the wolf comes on and Haanar raises his staff.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Here he comes!}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatHaanar();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Aftermath",
			Title = "At the Stones",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				if (c.m.Outcome == 2)
				{
					this.Text = "[img]gfx/ui/events/event_28.png[/img]{Lazino kneels beside the body for a long while. When he finally stands, he takes your hand.%SPEECH_ON%You tried. I'll remember that you tried.%SPEECH_OFF%}";
				}
				else
				{
					this.Text = "[img]gfx/ui/events/event_28.png[/img]{Lazino says nothing at all on the walk down. Once, at the foot of the hill, he stops.%SPEECH_ON%I held him when he was a day old. Did you know that?%SPEECH_OFF%He doesn't wait for an answer.}";
				}
				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png", text = "Haanar is dead" }
				];
				local mr = c.moralRow(c.m.Outcome);
				if (mr != null) this.List.push(mr);
				this.Options = [
					{
						Text = "{Home.}",
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
			ID = "ThroughStones",
			Title = "Through the Stones",
			Text = "[img]gfx/ui/events/event_101.png[/img]{You pull back with the old man between your shields. Haanar doesn't follow. He stands in the ring as the stones flare up again, looks once at Lazino, and turns east. The light swallows him.\n\nLazino watches the stones go dark before he speaks, and when he does it is very quiet.%SPEECH_ON%He's gone to find her. Gods help him. Gods help whoever's in between.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/special.png", text = "Lazino is safe" },
					{ id = 2, icon = "ui/icons/regular_damage.png", text = "Haanar has gone to find his mother" }
				];
				this.Options = [
					{
						Text = "{Home.}",
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
			ID = "Report",
			Title = "Home to the Village",
			Text = "",
			Image = "",
			List = [],
			ShowEmployer = false,
			Options = [],
			function start()
			{
				local c = this.Contract;
				local o = c.m.Outcome;
				local first = "Leyla sees you coming from the far end of the lane and runs the whole way. She pays you from the little purse and from a heavier one the village filled behind her back, and %townname% empties its larders for a feast that lasts well past dark.";
				local second;
				if (o == 1)
					second = "Haanar sits at the edge of the firelight, where he can leave if he needs to. Nobody quite looks at him. By the end of the night, a few people have. It's a long road. It's a start.";
				else if (o == 4)
					second = "Lazino keeps looking east over the hills, long after the fires have burned down.";
				else
					second = "Word of what happened at the stones has come down the hill ahead of you. The feast goes on, but people step aside when the company passes, and more than one table goes quiet. Lazino drinks a toast to Ragir Grenvill and doesn't say why.";
				this.Text = "[img]gfx/ui/events/" + (o == 1 ? "event_85" : "event_24") + ".png[/img]{" + first + "\n\n" + second + "}";

				local rows = [];
				rows.push({ id = 1, icon = "ui/icons/asset_money.png",
					text = "You gain " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, c.finalPay()) + " Crowns" });
				if (o == 1)
					rows.push({ id = 2, icon = "ui/icons/special.png", text = "Haanar has come home" });
				else if (o == 4)
					rows.push({ id = 2, icon = "ui/icons/regular_damage.png", text = "Haanar is gone east" });
				else
					rows.push({ id = 2, icon = "ui/icons/regular_damage.png", text = "The village pays, but it will not speak well of the company" });

				this.List = rows;

				this.Options = [
					{
						Text = "{To the feast, then.}",
						function getResult()
						{
							local c = this.Contract;
							if (c.m.Concluded == 0)
							{
								c.m.Concluded = 1;
								c.m.Act = 5;
								local pay = c.finalPay();
								::World.Assets.addMoney(pay);
								local renown = c.renownFor(c.m.Outcome);
								if (renown != 0) ::World.Assets.addBusinessReputation(renown);
								local f = ::World.FactionManager.getFaction(c.getFaction());
								if (f != null)
								{
									f.addPlayerRelation(c.relationFor(c.m.Outcome),
										c.m.Outcome == 1 ? "Brought Lazino home, and Haanar with him" : "Brought Lazino home");
								}
								::Skv.dbg("Skv.Torment: ENDING outcome=" + c.m.Outcome + " pay=" + pay
									+ " renown=" + renown + " relation=" + c.relationFor(c.m.Outcome)
									+ " searched=" + c.m.Searched + " marks=" + c.m.Marks);
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
		::Skv.Once.release("Torment");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Torment");

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
		_out.writeU8(this.m.Approach);
		_out.writeU8(this.m.Outcome);
		_out.writeU8(this.m.Searched);
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
		this.m.Approach = _in.readU8();
		this.m.Outcome = _in.readU8();
		this.m.Searched = _in.readU8();
		this.m.Concluded = _in.readU8();
		this.m.Res8 = _in.readU8();
		this.m.Marks = _in.readU16();
		this.m.Res32 = _in.readU32();
		this.m.Speaker = _in.readString();
		this.contract.onDeserialize(_in);
	}
});
