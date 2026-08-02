this.legend_watchtower_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Destination = null,

		CultistBudget = 60,

		GhostThreshold = 1.15,

	},

	function cultistBudget()
	{
		local b = (this.m.CultistBudget * this.getScaledDifficultyMult()).tointeger();
		return b < 15 ? 15 : b;
	}

	function cultistCount()
	{
		local b = this.cultistBudget();
		local n = b / 15;
		if (n * 15 < b) n = n + 1;
		return n;
	}

	function ghostCount()
	{
		return this.getScaledDifficultyMult() >= this.m.GhostThreshold ? 2 : 1;
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.legend_watchtower";
		this.m.Name = "Shadows on the Frontier";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 12.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A hard-pressed frontier town needs its abandoned landward watchtower cleared. Lights and chanting have been seen in the ruin, and shapes moving with them - winged, and not among the living. Someone has come to that broken place, and they are stirring what died there.",
			"The old tower that once warded the town against the winged raiders of the mountains was abandoned years ago. Now robed figures keep a fire burning in its ruins, and cold shapes swarm the stones around them. The town's militia can spare no one to see it stopped.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(90, 105) * 0.01;

		this.m.Payment.Pool = 400 * (this.Math.rand(60, 110) * 0.01) * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();

		if (this.Math.rand(1, 100) <= 33)
		{
			this.m.Payment.Completion = 0.75;
			this.m.Payment.Advance = 0.25;
		}
		else
		{
			this.m.Payment.Completion = 1.0;
		}

		this.contract.start();
	}

	function pickTowerTile()
	{
		local candidates = this.m.Home.getSurroundingTilesOfType([this.Const.World.TerrainType.Hills], 3);
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
					"Clear the haunted watchtower near " + this.Contract.m.Home.getName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());

				local tile = this.Contract.pickTowerTile();
				if (tile == null)
				{
					local excluded = this.Const.World.getAllTerrainTypesExcept([this.Const.World.TerrainType.Hills]);
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 1, 3, excluded, false);
				}

				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/undead_ruins_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setName("The Abandoned Watchtower");

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
					this.Contract.m.Destination.setOnCombatWithPlayerCallback(this.onTowerAttacked.bindenv(this));
				}
			}

			function update()
			{
				if (::MSU.isNull(this.Contract.m.Destination))
				{
					this.Contract.setScreen("Cleared");
					this.World.Contracts.showActiveContract();
					return;
				}

				if (this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (!this.TempFlags.get("AtTower"))
					{
						this.TempFlags.set("AtTower", true);
						this.Contract.setScreen("Approach");
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtTower", false);
				}
			}

			function onTowerAttacked( _dest, _isPlayerAttacking = true )
			{
				local tile = this.Contract.m.Destination.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.Music = ::Const.Music.UndeadTracks;
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Watchtower";

				p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.Walls;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.Cultists, this.Contract.cultistBudget(), fac);

				local ghosts = this.Contract.ghostCount();
				for (local i = 0; i < ghosts; i = i + 1)
				{
					local g = clone ::Const.World.Spawn.Troops.Ghost;
					g.Faction <- fac;
					p.Entities.push(g);
				}

				p.BeforeDeploymentCallback = function ()
				{
					local tile = null;
					for (local tries = 0; tries < 60 && tile == null; tries = tries + 1)
					{
						local cand = this.Tactical.getTileSquare(this.Math.rand(10, 28), this.Math.rand(6, 26));
						if (cand.IsEmpty)
						{
							tile = cand;
						}
					}
					if (tile == null)
					{
						return;
					}

					local names = ["Kaakriik", "Vazaraak", "Cirnatha", "Issketh", "Draaviin", "Ghurnaak"];
					local boss = this.Tactical.spawnEntity("scripts/entity/tactical/enemies/legend_bandit_raider", tile.Coords);
					boss.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID());
					boss.setName(names[this.Math.rand(0, names.len() - 1)]);
					boss.getBaseProperties().Hitpoints = 105;
					boss.getBaseProperties().Bravery = 55;
					boss.getItems().equip(this.new("scripts/items/weapons/two_handed_mace"));
					boss.getSkills().add(this.new("scripts/skills/actives/legend_inspire_skill"));
					boss.getSkills().update();
					boss.setHitpoints(105);
				};

				::World.Contracts.startScriptedCombat(p, false, false, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == "Watchtower")
				{
					if (!::MSU.isNull(this.Contract.m.Destination))
					{
						this.Contract.m.Destination.die();
						this.Contract.m.Destination = null;
					}
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
			Title = "Shadows on the Frontier",
			Text = "[img]gfx/ui/events/event_62.png[/img]{%employer% keeps their voice low. %SPEECH_ON%We gave up the old watchtower on the mountain side years back - the winged raiders came down and burned it, and a fool's powder finished the walls. It sat quiet until this season. Now there is a fire in the ruin at night, and chanting, and folk swear they see shapes swarming the stones - winged, and cold, and wrong. Strangers came to that broken place, and they are calling something up out of it. We have not the hands to spare, and we cannot leave that at our back. Go up there and put an end to it.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{Cults and cold things. It will cost you. | We will see it done, for the right price.}",
					function getResult()
					{
						return "Negotiation";
					}

				},
				{
					Text = "{This is not for us.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}

				}
			],
			function start()
			{
			}

		});

		this.m.Screens.push({
			ID = "Approach",
			Title = "The Abandoned Watchtower",
			Text = "[img]gfx/ui/events/event_108.png[/img]{You climb the last of the slope to the broken tower, the black peaks looming above it. A fire burns among the fallen stones, and around it robed figures stand at some patient, droning work - and above them the air is wrong. At the center of it a hard-faced man in dull mail directs the work, a great two-handed mace across his back. Something pale and half-seen drifts between the blocks around them, winged and cold, thickening as the chant goes on. Whatever he came here to raise, it is most of the way through the door.\n\nYou are close enough to count them, and far enough to turn around.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Break the ritual. | To arms!}",
					function getResult()
					{
						this.Contract.getActiveState().onTowerAttacked(this.Contract.m.Destination);
						return 0;
					}

				},
				{
					Text = "{Hold back for now - we can come back to this.}",
					function getResult()
					{
						return 0;
					}

				},
				{
					Text = "{This is beyond us. We go back and say so.}",
					function getResult()
					{

						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Turned back from the abandoned watchtower");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}

				}
			],

			function start()
			{
				this.List = [];

				local c = this.Contract.cultistCount();
				this.List.push({
					id = 1,
					icon = "ui/icons/special.png",
					text = c == 1 ? "One robed figure at the fire" : c + " robed figures at the fire"
				});

				local g = this.Contract.ghostCount();
				this.List.push({
					id = 2,
					icon = "ui/icons/special.png",
					text = g == 1 ? "A pale winged shape among the stones - one of the restless dead" : g + " pale winged shapes among the stones - the restless dead"
				});

				this.List.push({
					id = 3,
					icon = "ui/icons/special.png",
					text = "Their leader, mailed, with a two-handed mace - he will not break easily"
				});
			}

		});

		this.m.Screens.push({
			ID = "Cleared",
			Title = "The Tower Falls Silent",
			Text = "[img]gfx/ui/events/event_123.png[/img]{The chant is broken, the fire scattered, and the cold shapes unravel into nothing among the stones with the last of those who called them. A stillness settles over the ruin that has not been felt in years. Among the scattered ritual gear you find what they came for - small carvings of rare bone the strangers had hauled up here and hidden in the broken stones. The town's landward flank is quiet again. You gather your company and what you found, and turn back down the slope.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Let us collect our due.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());

						::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/loot/bone_figurines_item"]), 0);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Cleared the haunted watchtower");
						this.World.Contracts.finishActiveContract();
						return 0;
					}

				}
			],
			function start()
			{

				this.List = [];
				foreach (r in ::Skv.Loot.previewRows(["scripts/items/loot/bone_figurines_item"])) this.List.push(r);
			}

		});
	}

	function onClear()
	{
		::Skv.Once.release("Watchtower");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Watchtower");
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

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local destination = _in.readU32();

		if (destination != 0)
		{
			this.m.Destination = this.WeakTableRef(::World.getEntityByID(destination));
		}

		this.contract.onDeserialize(_in);
	}

});
