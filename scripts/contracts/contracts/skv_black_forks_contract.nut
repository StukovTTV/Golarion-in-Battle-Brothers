this.skv_black_forks_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Destination = null,
		WasNight    = false,
		SiteCleared = false,

		DayBudget   = 80,
		NightBudget = 120,

	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_black_forks";
		this.m.Name = "The Fires at Black Forks";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 12.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"Travellers speak of fires burning again in the old monastery of Black Forks, deep in the wood, and of cowled figures moving through its halls by night. The druids who once kept the place have not been seen. A nearby village wants someone to go and see what has taken root there.",
			"Something has woken in the ruined monastery in the forest - lights in the windows, chanting carried on the wind, and folk gone missing on the paths nearby. The village asks that the company go and put a stop to whatever is calling out there.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(90, 120) * 0.01;

		this.m.Payment.Pool = ::Skv.Econ.pool(this, 300, 0.5, 1.5);

		this.m.Payment.Completion = 1.0;
		this.m.Payment.Advance = 0.0;

		this.contract.start();
	}

	function pickSiteTile()
	{
		local candidates = this.m.Home.getSurroundingTilesOfType([
			this.Const.World.TerrainType.Forest,
			this.Const.World.TerrainType.LeaveForest,
			this.Const.World.TerrainType.AutumnForest
		], 3);
		local valid = [];
		foreach (t in candidates)
		{
			if (!t.IsOccupied)
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

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Investigate the fires at the old monastery near " + this.Contract.m.Home.getName()
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
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 1, 3, excluded, false);
				}

				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/undead_ruins_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setName("Black Forks");

				this.Contract.m.Destination.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID());
				this.Contract.m.Destination.setBanner(this.World.FactionManager.getFaction(this.Const.FactionType.Bandits).getPartyBanner());
				this.Contract.m.Destination.setDiscovered(true);
				this.Contract.m.Destination.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Destination.getTile().Pos, 500.0);

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
			}

			function update()
			{

				if (this.Contract.m.SiteCleared)
				{
					if (this.Contract.isPlayerAt(this.Contract.m.Home))
					{
						if (!this.TempFlags.get("AtHome"))
						{
							this.TempFlags.set("AtHome", true);
							this.Contract.setScreen(this.Contract.m.WasNight ? "ReportNight" : "ReportDay");
							this.World.Contracts.showActiveContract();
						}
					}
					else
					{
						this.TempFlags.set("AtHome", false);
					}
					return;
				}

				if (this.Flags.get("IsVictory"))
				{
					this.Flags.set("IsVictory", false);
					this.Contract.m.SiteCleared = true;
					if (!::MSU.isNull(this.Contract.m.Destination))
					{
						this.Contract.m.Destination.die();
						this.Contract.m.Destination = null;
					}
					this.Contract.m.BulletpointsObjectives = [
						"Report back to " + this.Contract.m.Home.getName()
					];
					if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
					{
						this.Contract.m.Home.getSprite("selection").Visible = true;
					}
					return;
				}

				if (this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					local isDay = this.World.getTime().IsDaytime;

					if (!this.TempFlags.get("AtSite") || this.TempFlags.get("AtSiteWasDay") != isDay)
					{
						this.TempFlags.set("AtSite", true);
						this.TempFlags.set("AtSiteWasDay", isDay);
						this.Contract.setScreen(isDay ? "ApproachDay" : "ApproachNight");
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtSite", false);
				}
			}

			function onCombat()
			{
				local tile = this.Contract.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.Music = ::Const.Music.UndeadTracks;
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "BlackForks";

				p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.Walls;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				local mult = this.Contract.getScaledDifficultyMult();

				this.Contract.m.WasNight = !this.World.getTime().IsDaytime;

				if (this.Contract.m.WasNight)
				{

					::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.GolarionCult, this.Contract.m.NightBudget * mult, fac);
				}
				else
				{

					::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.Cultists, this.Contract.m.DayBudget * mult, fac);
				}

				::World.Contracts.startScriptedCombat(p, false, false, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == "BlackForks")
				{
					this.Flags.set("IsVictory", true);
				}
			}

			function onRetreatedFromCombat( _combatID )
			{
			}

		});
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "The Fires at Black Forks",
			Text = "[img]gfx/ui/events/event_76.png[/img]{%employer% speaks quietly of the old place in the wood. %SPEECH_ON%There is a ruin out past the treeline - %SKVLOC%Black Forks%SKVLOC_OFF%, an old monastery, older than anyone here. Folk left it well alone. But there are fires in it again now, at night, and voices, and the wise-folk who used to walk its roof have not come back down. Two of ours went to look and did not return. We do not know what is out there. Go and see. Put an end to it if you can, and we will pay you when you bring us word.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [],

			function start()
			{
				this.Options = [
					{
						Text = "{We will look into your fires.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{%SKVLOC%Black Forks%SKVLOC_OFF%. Does that name mean anything to anyone?}",
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
			Title = "Black Forks",
			Text = "[img]gfx/ui/events/event_02.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% does not look up. %SPEECH_ON%It means forks. Two-headed ones. That is all the name ever meant. The order that kept that place used them on themselves - that was the whole of their worship. They hung from the ceiling of that hall on hooks and ropes, over the water, and they called it devotion.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% waits for more, and does not get it, so he fills it in himself. %SPEECH_ON%The pool was there first. Long before the walls, long before the hooks. There were tablets in that place, old clay, and every one of them had the same thing scratched on it - a great slick round thing down in the dark, sleeping. The Dreamer in the Depths, they wrote. Nobody has ever laid eyes on it. That did not stop the monks hanging over it night after night waiting to be spoken to. The ones who came down again never spoke another word as long as they lived. That was the point, apparently. That was the reward.%SPEECH_OFF%%SPEECH_ON%Then the goblins came through the wood, thousands of them, running from something worse. Found a hall full of holy men strung up over a pool, helpless as hams. Cut them all down and threw them in the water.%SPEECH_OFF% He shrugs. %SPEECH_ON%And the water answered. Whatever was down there came up and went through the farms in that country like a scythe. Took soldiers with a rune-blade on a spear to drive it back under - and not one of those soldiers walked home, and nobody has ever found the spear. Nor heard from the thing since.%SPEECH_OFF%%SKVNAME%%randombrother%%SKVNAME_OFF% finally looks up. %SPEECH_ON%And now somebody has lit fires in it.%SPEECH_OFF%}",
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
			ID = "ApproachDay",
			Title = "Black Forks",
			Text = "[img]gfx/ui/events/event_115.png[/img]{The trees give way to a low, strange building of bestial stone, grown around a still pool of black water. Cowled figures step from the shadow of the eaves - not the cult, but the druids who tend this place, their hands raised. %SPEECH_ON%You have come at the right hour. They keep to the dark, and they sleep it off by day - the one who leads them with them. There is only the watch awake in there now. It will never be easier than this.%SPEECH_OFF% Past the doorway the halls are quiet, the fires burned down to ash, and a few hooded shapes move slowly between the pillars.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Then we go in.}",
					function getResult()
					{
						this.Contract.getActiveState().onCombat();
						return 0;
					}

				},
				{
					Text = "{Hold back for now.}",
					function getResult()
					{
						return 0;
					}

				}
			],
			function start()
			{
			}

		});

		this.m.Screens.push({
			ID = "ApproachNight",
			Title = "Black Forks",
			Text = "[img]gfx/ui/events/event_140.png[/img]{The trees give way to a low, strange building of bestial stone, grown around a still pool of black water. Cowled figures step from the shadow of the eaves - not the cult, but the druids who tend this place, their hands raised. %SPEECH_ON%Not now. Not tonight. They are all awake and all of them are in there, and the one who leads them walks the hall - and he is not what he was when he came. Wait for the sun and take them sleeping. Go in now and we will be pulling your men out of that water.%SPEECH_OFF% Beyond them the fires are high, and the cowled Tenders move around the pool in slow silence, and something in the middle of them is speaking in a voice that does not carry.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{They are all in one place. We go in now.}",
					function getResult()
					{
						this.Contract.getActiveState().onCombat();
						return 0;
					}

				},
				{
					Text = "{Then we wait for the sun.}",
					function getResult()
					{
						return 0;
					}

				}
			],
			function start()
			{
			}

		});

		this.m.Screens.push({
			ID = "ReportDay",
			Title = "Word From the Wood",
			Text = "[img]gfx/ui/events/event_16.png[/img]{You bring word back to %SKVLOC%%townname%%SKVLOC_OFF%: the monastery is cleared, the cult driven from the halls, the fires put out. The druids have their strange place back. The elder counts out your pay with visible relief - whatever was gathering out there, it will not gather now.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Our due, then.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Drove the cult from Black Forks");
						this.World.Contracts.finishActiveContract();
						return 0;
					}

				}
			],
			function start()
			{
			}

		});

		this.m.Screens.push({
			ID = "ReportNight",
			Title = "What Was Loosed in the Wood",
			Text = "[img]gfx/ui/events/event_43.png[/img]{You reached %SKVLOC%Black Forks%SKVLOC_OFF% with the fires at their height and broke the rite mid-chant, cutting down the one who led it before the pool could answer. But you saw enough in that black water to know this was no lone band of madmen - the cult is spreading, and %SKVLOC%Black Forks%SKVLOC_OFF% was only where they gathered. You carry that word back to %SKVLOC%%townname%%SKVLOC_OFF%. The elder pays what was promised, and presses more into your hands for the warning - but the news travels faster than the coin, and by the time you leave, the village has drawn its shutters against the wood.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{They should be afraid.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);

						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.Assets.addMoney(this.Contract.m.Payment.Pool);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Broke the cult of Black Forks mid-rite");

						if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
						{
							this.Contract.m.Home.addSituation(this.new("scripts/entity/world/settlements/situations/terrified_villagers_situation"));
						}
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
		::Skv.Once.release("BlackForks");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("BlackForks");
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
		if (!::MSU.isNull(this.m.Destination))
		{
			_out.writeU32(this.m.Destination.getID());
		}
		else
		{
			_out.writeU32(0);
		}
		_out.writeU8(this.m.WasNight ? 1 : 0);
		_out.writeU8(this.m.SiteCleared ? 1 : 0);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local destination = _in.readU32();
		if (destination != 0)
		{
			this.m.Destination = this.WeakTableRef(::World.getEntityByID(destination));
		}
		this.m.WasNight    = _in.readU8() == 1;
		this.m.SiteCleared = _in.readU8() == 1;

		this.contract.onDeserialize(_in);
	}

});
