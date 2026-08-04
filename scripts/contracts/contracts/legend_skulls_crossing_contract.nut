this.legend_skulls_crossing_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Destination = null,
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.legend_skulls_crossing";
		this.m.Name = "Skull's Crossing";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Economy;
		this.m.DescriptionTemplates = [
			"A parched town begs for someone to reach the old dam and turn the river back to their fields.",
			"They say the ancient dam has stolen their water. They will pay half now for anyone willing to try setting it right."
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		this.m.DifficultyMult = this.Math.rand(90, 105) * 0.01;

		this.m.Payment.Pool = 600 * (this.Math.rand(60, 110) * 0.01) * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		this.m.Payment.Advance = 0.5;
		this.m.Payment.Completion = 0.5;
		this.contract.start();
	}

	function pickSpawnTile()
	{
		local candidates = this.m.Home.getSurroundingTilesOfType([this.Const.World.TerrainType.Shore], 12);
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

	function resolveMechanism()
	{
		local hasSpecialist = false;
		foreach (bro in this.World.getPlayerRoster().getAll())
		{
			if (bro.getBackground().getID() == "background.legend_inventor"
				|| bro.getSkills().hasPerk(::Legends.Perk.LegendScholar))
			{
				hasSpecialist = true;
				break;
			}
		}

		local wWorks  = hasSpecialist ? 60 : 45;
		local wAmbush = 20;
		local wBreak  = hasSpecialist ? 20 : 35;

		local roll = this.Math.rand(1, wWorks + wAmbush + wBreak);
		local outcome = roll <= wWorks ? "works" : (roll <= wWorks + wAmbush ? "ambush" : "break");

		if (outcome == "works")
		{
			return "Works";
		}
		else if (outcome == "break")
		{
			return "Broken";
		}
		else
		{
			this.getActiveState().onCombat();
			return "";
		}
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Reach the ancient dam near " + this.Contract.m.Home.getName(),
					"Work its mechanism to return the river"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());

				local tile = this.Contract.pickSpawnTile();
				if (tile == null)
				{
					local excluded = this.Const.World.getAllTerrainTypesExcept([this.Const.World.TerrainType.Shore]);
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 1, 12, excluded, false);
				}

				tile.clear();
				this.Contract.m.Destination = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/undead_ruins_location", tile.Coords));
				this.Contract.m.Destination.onSpawned();
				this.Contract.m.Destination.setName("Skull's Crossing");
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
				if (::MSU.isNull(this.Contract.m.Destination))
				{
					return;
				}

				if (this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (this.Flags.get("AmbushWon"))
					{
						this.Flags.set("AmbushWon", false);
						this.Contract.setScreen("TooLate");
						this.World.Contracts.showActiveContract();
						return;
					}
					else if (this.Flags.get("AmbushFled"))
					{
						this.Flags.set("AmbushFled", false);
						this.Contract.setScreen("Fled");
						this.World.Contracts.showActiveContract();
						return;
					}

					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						this.Contract.setScreen("Approach");
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
				p.Music = ::Const.Music.BanditTracks;
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "SkullsCrossing";
				p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
				::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.BanditScouts, 90 * this.Contract.getDifficultyMult() * this.Contract.getScaledDifficultyMult(), fac);

				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == "SkullsCrossing")
				{
					this.Flags.set("AmbushWon", true);
				}
			}

			function onRetreatedFromCombat( _combatID )
			{
				if (_combatID == "SkullsCrossing")
				{
					this.Flags.set("AmbushFled", true);
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
			Title = "Skull's Crossing",
			Text = "[img]gfx/ui/events/event_20.png[/img]{%employer% speaks with the flat calm of the desperate. %SPEECH_ON%Our river runs to nothing. Downstream, where it meets the sea, stands an old dam of black stone carved all over with skulls. Men say the giant-slaves of a sorcerer-king raised it in the elder days, before any kingdom you'd know. Its jaws once ruled the water, but they have hung open so long the river drains straight past us to the ocean, and our fields die of thirst.%SPEECH_OFF%He slides a heavy purse across the table. %SPEECH_ON%The machinery has slept a hundred lifetimes. No one living has made it stir, and I'll not pretend it will answer you either, for a thing left that long may simply be dead. But close those jaws and the water backs up to us again. Half now, for the attempt. Do it, and there's as much again waiting. It likely won't work. Try anyway.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [],

			function start()
			{
				this.Options = [
					{
						Text = "{We will try. Half now, half when it flows.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{Hold. Does anyone know what this dam is?}",
						function getResult()
						{
							return "Lore";
						}
					});
				}

				this.Options.push({
					Text = "{Ancient machinery is no work for us.}",
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
			Title = "Skull's Crossing",
			Text = "[img]gfx/ui/events/event_23.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% speaks up from the back of the room. %SPEECH_ON%%SKVLOC%Skull's Crossing%SKVLOC_OFF%. I've seen it, from a long way off, and that was close enough. That's Thassilonian work. There was an empire here ten thousand years before us, sorcerer-kings and slave-armies, and it went into the sea in a single day when the sky came down. Most of what's left is buried. That thing isn't.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% snorts. %SPEECH_ON%He's got the half of it. The plateau was one great quarry once, and every tower and monument those kings ever raised came up out of that pit. It belonged to %SKVNAME%Karzoug%SKVNAME_OFF%. The Runelord of Greed, they named him, and by all accounts he answered to it gladly.%SPEECH_OFF%%SPEECH_ON%When the stone finally ran out, he wouldn't suffer the ugliness of the hole he'd made. So he set his giants to wall the river and drowned the whole quarry under a lake, and called that beautiful. The skulls are his mark, carved a hundred times over, so no man could drink without knowing whose water it was.%SPEECH_OFF%He shrugs. %SPEECH_ON%The jaws open and close. There's machinery in the stone to work them. Or there was. %SKVNAME%Karzoug%SKVNAME_OFF%'s been dust a hundred centuries, and nobody's asked anything of that dam since.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Back to the matter at hand.}",
					function getResult()
					{
						return "Task";
					}
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "Approach",
			Title = "Skull's Crossing",
			Text = "[img]gfx/ui/events/skv_skullcrossing_open.png[/img]{The dam rises impossibly vast, a wall of black stone carved with a thousand grinning skulls, each jaw a valve the size of a gate. Beyond them lies the machinery that once moved those jaws: cogs and chains and counterweights bedded in the stone, cold and motionless for a hundred lifetimes. Rust has fused what rot has not seized. Somewhere in that dead mechanism is the lever that turns the river home, if it can be made to turn at all. It may be that nothing here will ever move again.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Work the mechanism.}",
					function getResult()
					{
						return this.Contract.resolveMechanism();
					}
				},
				{
					Text = "{Not yet.}",
					function getResult() { return 0; }
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "Works",
			Title = "The River Turns",
			Text = "[img]gfx/ui/events/skv_skullcrossing_closed.png[/img]{Cogs the size of millstones groan, catch, and turn. Deep in the dam the great skull-jaws grind closed one by one, and with a sound like the world exhaling the river swings back toward the parched hinterland. It will reach the fields by morning.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Let us collect our due.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess * 2);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Reopened Skull's Crossing");
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "TooLate",
			Title = "Too Late",
			Text = "[img]gfx/ui/events/event_22.png[/img]{The last of them falls, but one look at the mechanism tells the tale: someone reached it before you and put crowbars to the ancient valves, smashing in a few hours what stood ten thousand years. The river cannot be turned now. You are too late, but the rivals who beat you here will carry nothing away, and what they pried loose from the old stone is yours.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Take what we can and go.}",
					function getResult()
					{

						if (this.World.Assets.getStash().hasEmptySlot())
						{
							this.World.Assets.getStash().add(this.new("scripts/items/loot/ancient_gold_coins_item"));
						}
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail * 2);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Arrived too late at Skull's Crossing");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "Fled",
			Title = "Driven Off",
			Text = "[img]gfx/ui/events/event_75.png[/img]{The ambush breaks your nerve before it breaks the dam. You pull the company back from the great stone span, leaving the ancient mechanism untouched and the river still lost. The town's water will not come by your hand. At least the coin they paid for the attempt is yours.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{We live to earn another day.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail * 2);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Abandoned Skull's Crossing");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "Broken",
			Title = "The Mechanism Dies",
			Text = "[img]gfx/ui/events/event_57.png[/img]{You force the ancient lever. For a moment the cogs shudder and strain against ten thousand years of silence, and then something deep within the dam snaps. The mechanism grinds, seizes, and falls still for the last time. The jaws will never move again. The river stays lost. You keep the coin they paid for the attempt, but the town will hear how their dam finally died in your hands.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Nothing more to be done.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail * 2);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Broke Skull's Crossing");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}
				}
			],
			function start() {}
		});
	}

	function onClear()
	{
		::Skv.Once.release("SkullsCrossing");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("SkullsCrossing");
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
