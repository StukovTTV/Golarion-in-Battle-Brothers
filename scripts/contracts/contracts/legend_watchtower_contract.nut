this.legend_watchtower_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Destination = null,
		// ---- FIGHT DIALS -----------------------------------------------------
		// Three independent resource budgets, all fixed (no campaign scaling) so the
		// fight stays predictable. The alp budget is kept LOW on purpose: the cost-105
		// DemonAlp boss (mass-sleep + nightmare summons) can never roll below ~105, so
		// a small budget always yields the ordinary, fair alp. Raise/lower each freely.
		CultistBudget = 75,   // ~8 cultists. Ghosts are a fixed 2 (pushed by hand below); no alp.
		// ---------------------------------------------------------------------
	},
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
		// A real fight (cult + swarm + an alp), so a standard difficulty rating rather
		// than the easy tier. Feeds both the payout (via DIFF^POW) and the rating.
		this.m.DifficultyMult = this.Math.rand(90, 105) * 0.01;

		// Base 500, times a village-wealth roll (0.60-1.10): a poor frontier town posts
		// less than a well-off one for the same job. Then the standard engine multipliers.
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
				// Bandits faction: cultists are bandit-faction in combat (per the native
				// cultist contract), and we run our own scripted fight regardless.
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
				// Dress the battlefield as a ruin (broken walls + rubble) instead of open field.
				p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
				p.LocationTemplate.Template[0] = "tactical.ruins";
				p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.Walls;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				// Everything on one side (Bandits), per the native cultist contract.
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.Cultists, this.Contract.m.CultistBudget, fac);

				// Ghosts as a FIXED count (2). The Ghosts spawn list has an 80-resource MinR
				// threshold that collapses any small budget to 4, so we place them by hand.
				for (local i = 0; i < 2; i = i + 1)
				{
					local g = clone ::Const.World.Spawn.Troops.Ghost;
					g.Faction <- fac;
					p.Entities.push(g);
				}

				// --- Bespoke named boss: the warrior leading the cult -------------------
				// Spawned as a single hand-built actor at deployment (the legendary-location
				// pattern). Fat HP + morale aura anchor the swarm; kill him and the cult wobbles.
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
					boss.getBaseProperties().Hitpoints = 105;   // fat HP: he is the anchor (tune here)
					boss.getBaseProperties().Bravery = 55;      // hard to rout, but not a hero
					boss.getItems().equip(this.new("scripts/items/weapons/two_handed_mace"));         // two-handed mace
					boss.getSkills().add(this.new("scripts/skills/actives/legend_inspire_skill"));  // morale-anchor aura
					boss.getSkills().update();
					boss.setHitpoints(105);
				};
				// -----------------------------------------------------------------------

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
						this.World.Contracts.removeContract(this.Contract);   // pre-accept decline -> NOT retired (can re-offer)
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
			Text = "[img]gfx/ui/events/event_108.png[/img]{You climb the last of the slope to the broken tower, the black peaks looming above it. A fire burns among the fallen stones, and around it robed figures stand at some patient, droning work - and above them the air is wrong. At the center of it a hard-faced man in dull mail directs the work, a great two-handed mace across his back. Pale, half-seen shapes drift and swarm between the blocks around them, winged and cold, thickening as the chant goes on. Whatever he came here to raise, it is most of the way through the door.}",
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
			ID = "Cleared",
			Title = "The Tower Falls Silent",
			Text = "[img]gfx/ui/events/event_123.png[/img]{The chant is broken, the fire scattered, and the cold shapes unravel into nothing among the stones with the last of those who called them. A stillness settles over the ruin that has not been felt in years. Among the scattered ritual gear you find what they came for -- small carvings of rare bone the strangers had hauled up here and hidden in the broken stones. The town's landward flank is quiet again. You gather your company and what you found, and turn back down the slope.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Let us collect our due.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						// The cult came to claim something here - you leave with it. Found in the
						// ruins on completion, not looted off the boss. Granted here on confirm; the
						// screen's start() shows it as an iconed row. Swap the item path to taste.
						::Skv.Loot.haul(::Skv.Loot.make(["scripts/items/loot/bone_figurines_item"]), 0);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Cleared the haunted watchtower");
						this.World.Contracts.finishActiveContract();
						return 0;
					}

				}
			],
			function start()
			{
				// Preview the completion reward as an iconed row (granted on confirm above).
				this.List = [];
				foreach (r in ::Skv.Loot.previewRows(["scripts/items/loot/bone_figurines_item"])) this.List.push(r);
			}

		});
	}

	function onClear()
	{
		::Skv.Once.release("Watchtower");   // always free the live-offer slot (any removal)
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Watchtower");   // accepted then concluded (completed/aborted) -> retire
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
