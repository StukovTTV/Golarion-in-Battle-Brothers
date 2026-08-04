this.skv_anvil_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Home       = null,
		Site       = null,
		Fought     = false,
		Won        = false,
		Paid       = false,
		FeeQuoted  = 0,
		ItemName   = "",

		Pick       = null,

		Concluded  = false
	},

	function setHome( _s )
	{
		this.m.Home = this.WeakTableRef(_s);
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_anvil";
		this.m.Name = "Master of the Anvil";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 12.0;
		this.m.Category = this.Const.Contracts.Categories.Economy;

		this.m.DescriptionTemplates = [
			"A smith travelling with his own forge has been set upon on the road, and the town would rather he lived. He is said to work steel that other smiths will not touch.",
			"There is a dwarf on the road with an anvil in his wagon and something following him. The town wants him brought in alive, and he is the only man in the region who can mend enchanted steel."
		];
	}

	function target()
	{
		if (!("GolarionEnchant" in ::getroottable()))
		{
			return null;
		}
		try { return ::GolarionEnchant.findMostDamaged(); }
		catch (e) { ::logError("Skv.Anvil: findMostDamaged threw - " + e); return null; }
	}

	function fee( _item )
	{
		if (_item == null)
		{
			return 0;
		}

		local was = _item.getCondition();
		local max = _item.getConditionMax();
		local worth;

		if (max > 1 && was < max)
		{
			_item.setCondition(max);
			try { worth = _item.getValue(); }
			catch (e) { _item.setCondition(was); throw e; }
			_item.setCondition(was);
		}
		else
		{
			worth = _item.getValue();
		}

		return this.Math.floor(worth * 0.5);
	}

	function homeName()
	{
		return this.m.Home != null && !this.m.Home.isNull() ? this.m.Home.getName() : "the town";
	}

	function settle( _pay )
	{
		if (this.m.Paid)
		{
			return;
		}
		this.m.Paid = true;
		this.m.Concluded = true;

		::World.Assets.addMoney(this.m.Payment.getOnCompletion());

		if (_pay)
		{
			local it = this.target();
			local cost = this.fee(it);

			if (it != null && ::World.Assets.getMoney() >= cost)
			{
				::World.Assets.addMoney(-cost);
				local fixed = ::GolarionEnchant.repairMostDamaged();
				::Skv.dbg("Skv.Anvil: repaired " + (fixed != null ? fixed.getName() : "nothing") + " for " + cost);
			}
		}
		else
		{

			::World.Assets.addMoralReputation(4);
			::Skv.dbg("Skv.Anvil: work declined, +4 moral reputation");
		}

		::World.Assets.addBusinessReputation(::Const.World.Assets.ReputationOnContractSuccess);
		::World.FactionManager.getFaction(this.getFaction()).addPlayerRelation(
			::Const.World.Assets.RelationCivilianContractSuccess, "brought the smith in alive");
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(70, 85) * 0.01;

		this.m.Payment.Pool = 100 * this.getPaymentMult() * this.getReputationToPaymentMult();
		this.m.Payment.Completion = 1.0;
		this.m.Payment.Advance = 0.0;

		local it = this.target();
		this.m.ItemName = it != null ? it.getName() : "the piece you are carrying";
		this.m.FeeQuoted = this.fee(it);

		this.contract.start();
	}

	function attackers()
	{
		local roll = this.Math.rand(1, 100);
		local south = false;
		try
		{
			south = this.m.Home != null && !this.m.Home.isNull()
				&& this.m.Home.isSouthern();
		}

		catch (e)
		{
			::logError("Skv.Anvil: isSouthern threw - " + e);
			south = false;
		}

		if (roll <= 28) return { List = ::Const.World.Spawn.GolarionKobolds,       Name = "kobolds" };
		if (roll <= 36) return { List = ::Const.World.Spawn.GolarionKoboldsCasters, Name = "kobold casters" };
		if (roll <= 54) return south
			? { List = ::Const.World.Spawn.NomadRaiders,  Name = "nomad raiders" }
			: { List = ::Const.World.Spawn.BanditRaiders, Name = "bandit raiders" };
		if (roll <= 66) return { List = ::Const.World.Spawn.GoblinRaiders, Name = "goblin raiders" };
		if (roll <= 74) return { List = ::Const.World.Spawn.OrcRaiders,    Name = "orc raiders" };
		if (roll <= 86) return { List = ::Const.World.Spawn.Mercenaries,   Name = "mercenaries" };
		if (roll <= 92) return this.Math.rand(1, 2) == 1
			? { List = ::Const.World.Spawn.Direwolves, Name = "direwolves" }
			: { List = ::Const.World.Spawn.Hyenas,     Name = "hyenas" };
		if (roll <= 97) return { List = ::Const.World.Spawn.Schrats, Name = "schrats" };
		return { List = ::Const.World.Spawn.Unhold, Name = "unhold" };
	}

	function onSerialize( _out )
	{
		_out.writeU32(this.m.Home != null && !this.m.Home.isNull() ? this.m.Home.getID() : 0);
		_out.writeU32(this.m.Site != null && !this.m.Site.isNull() ? this.m.Site.getID() : 0);
		_out.writeU8(this.m.Fought ? 1 : 0);
		_out.writeU8(this.m.Won ? 1 : 0);
		_out.writeU8(this.m.Paid ? 1 : 0);
		_out.writeU32(this.m.FeeQuoted);
		_out.writeString(this.m.ItemName);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local home = _in.readU32();
		local site = _in.readU32();
		if (home != 0) this.m.Home = this.WeakTableRef(::World.getEntityByID(home));
		if (site != 0) this.m.Site = this.WeakTableRef(::World.getEntityByID(site));
		this.m.Fought    = _in.readU8() == 1;
		this.m.Won       = _in.readU8() == 1;
		this.m.Paid      = _in.readU8() == 1;
		this.m.FeeQuoted = _in.readU32();
		this.m.ItemName  = _in.readString();
		this.contract.onDeserialize(_in);
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "Master of the Anvil",
			Text = "[img]gfx/ui/events/event_98.png[/img]{%employer% is not asking for himself.%SPEECH_ON%There is a dwarf a half-day out on the west road with a wagon, an anvil in the back of it and a hearth he keeps lit while he travels. He has been followed since the Crags and this morning he stopped moving. We would rather he reached us. A town without a smith of that sort is a town that buys its steel from strangers.%SPEECH_OFF%He lets that sit, and then gets to the part he thinks you will care about.%SPEECH_ON%He works what our own forge will not. Bring him in and he will put his hammer to that piece of yours, and he will want paying for it, and you will pay it, because there is nobody else.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				this.List = [
					{ id = 1, icon = "ui/icons/special.png", text = "He would work on: [color=" + this.Const.UI.Color.PositiveEventValue + "]" + c.m.ItemName + "[/color]" },
					{ id = 2, icon = "ui/icons/asset_money.png", text = "The smith will want [color=" + this.Const.UI.Color.NegativeEventValue + "]" + c.m.FeeQuoted + " crowns[/color] for the work" }
				];

				this.Options = [
					{
						Text = "{He will reach you. Let us hear the terms.}",
						function getResult() { return "Negotiation"; }
					},
					{
						Text = "{Find someone else.}",
						function getResult()
						{
							this.World.Contracts.removeContract(this.Contract);
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Arrive",
			Title = "The Travelling Forge",
			Text = "[img]gfx/ui/events/event_25.png[/img]{The wagon is off the road with one wheel in the ditch and the mule cut loose and gone. The hearth is still lit - he has not let it go out, which tells you what he thinks of the odds.\n\nThe smith himself is behind the cart with a hammer that was never meant for this, a leather apron and the flat expression of a man who has decided where he is going to die. He does not shout for help. He watches you come and he keeps his back to the anvil.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;

				if (c.m.Pick == null)
				{
					c.m.Pick = c.attackers();
				}

				this.List = [
					{ id = 1, icon = "ui/icons/regular_damage.png",
					  text = "Coming for the wagon: [color=" + this.Const.UI.Color.NegativeEventValue + "]"
						+ c.m.Pick.Name + "[/color]" }
				];

				this.Options = [
					{
						Text = "{Get between them and the wagon.}",
						function getResult()
						{
							this.Contract.getActiveState().onCombatForge();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Work",
			Title = "The Work",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local c = this.Contract;
				local it = c.target();
				local cost = c.fee(it);
				local money = ::World.Assets.getMoney();
				local afford = it != null && money >= cost;

				local body = "[img]gfx/ui/events/event_98.png[/img]{He does not thank anybody. He comes in behind you with the wheel braced and the hearth still burning in the back of the wagon, and he asks the gate guard one question, which is where the smithy is.\n\nHe is already unhitching by the time you catch up. The town smith comes out to see who is setting up in his yard, looks at the anvil coming down off the wagon, and steps back from his own forge without a word being said about it.\n\nHe holds his hand out for the piece without being asked - he has known what you were carrying since the road.\n\n";

				if (it == null)
				{
					body += "Then he turns your steel over twice and gives it back. There is nothing wrong with it that a night's rest will not fix, and he is not a man who takes money for that.}";
				}
				else if (!afford)
				{

					body += "He names his price, and it is honest, and it is more than is in the chest. He does not haggle and he does not sneer.%SPEECH_ON%Then it waits.%SPEECH_OFF%He goes back to his wheel.%SPEECH_ON%It has waited four hundred years to be made. It can wait on you.%SPEECH_OFF%}";
				}
				else
				{

					body += "He names his price for it before you have asked, the way a man does when the number is not up for discussion, and then he waits with the piece still in your hand. Behind him the hearth is banked and breathing. He has all afternoon and he is not going to spend it persuading you.}";
				}

				this.Text = body;

				local rows = [];
				if (it != null)
				{
					rows.push({ id = 1, icon = "ui/icons/special.png",
						text = "He works on: [color=" + this.Const.UI.Color.PositiveEventValue + "]" + it.getName() + "[/color]" });

					if (c.m.ItemName != "" && it.getName() != c.m.ItemName)
					{
						rows.push({ id = 2, icon = "ui/icons/special.png",
							text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]Not " + c.m.ItemName
								+ ", quoted in " + c.homeName() + "[/color] - that is no longer the worst of it" });
					}

					rows.push({ id = 3, icon = "ui/icons/asset_money.png",
						text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + cost + " crowns[/color] to the smith"
							+ (afford ? "" : " - you have [color=" + this.Const.UI.Color.NegativeEventValue + "]" + money + "[/color]") });
				}
				rows.push({ id = 4, icon = "ui/icons/asset_money.png",
					text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]"
						+ c.m.Payment.getOnCompletion() + " crowns[/color] from " + c.homeName() + ", either way" });
				this.List = rows;

				this.Options = [];

				if (it != null && afford)
				{
					this.Options.push({
						Text = "{Pay him.}",
						function getResult()
						{
							this.Contract.settle(true);
							return "Done";
						}
					});
				}

				this.Options.push({
					Text = it != null && afford ? "{Keep your crowns. He owes you nothing.}"
						: "{Leave him to his wheel.}",
					function getResult()
					{
						this.Contract.settle(false);
						return "Declined";
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "RoadBack",
			Title = "The Road Back",
			Text = "[img]gfx/ui/events/event_25.png[/img]{He is under the wagon before the last of them has stopped moving, and comes out having braced the broken wheel with a length of timber - a repair that looks wrong and holds anyway. The anvil goes back in the wagon. The hearth never went out.%SPEECH_ON%I will walk.%SPEECH_OFF%It is not an offer of company so much as a statement about the road, and he falls in behind the column without waiting to hear whether it suits you. He does not look at the piece on your belt again. He does not need to.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Take him in.}",
					function getResult() { return 0; }
				}
			],
			function start()
			{
				this.List = [

					{ id = 1, icon = "ui/icons/special.png",
					  text = "See the smith into [color=" + this.Const.UI.Color.PositiveEventValue + "]"
						+ this.Contract.homeName() + "[/color] - he will do the work once the forge is standing" }
				];
			}
		});

		this.m.Screens.push({
			ID = "Done",
			Title = "The Work",
			Text = "[img]gfx/ui/events/event_98.png[/img]{The town smith works the bellows for him and asks nothing, which is likely the most one craftsman can say to another. Half the town finds a reason to walk past the door.\n\nWhatever the dwarf does takes most of the afternoon and none of it looks like smithing - there is a great deal of listening to the metal and very little hitting it. When he hands it back the edge is whole and the mark on the tang is still there, which he seems to think is the part worth mentioning.\n\nBy dark he is loading the wagon again. The road does not stop being the road.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Good steel.}",
					function getResult()
					{
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
				local c = this.Contract;
				local it = c.target();
				this.List = [
					{ id = 1, icon = "ui/icons/special.png",
					  text = "[color=" + this.Const.UI.Color.PositiveEventValue + "]"
						+ (it == null ? c.m.ItemName : it.getName()) + "[/color] is whole again" }
				];
			}
		});

		this.m.Screens.push({
			ID = "Declined",
			Title = "No Charge",
			Text = "[img]gfx/ui/events/event_98.png[/img]{You tell him to keep his afternoon. He looks at you for a moment longer than is comfortable, the way a man does when he is deciding whether he has been insulted, and then decides he has not.%SPEECH_ON%Then we are square.%SPEECH_OFF%He goes back to the wheel. It is not gratitude. It is a dwarf of Torag settling an account in the only currency he keeps books in, and word of it will be on that road before you are.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Ride on.}",
					function getResult()
					{
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
				this.List = [
					{ id = 1, icon = "ui/icons/asset_moral_reputation.png",
					  text = "You pulled a man off the road and did not make a customer of him" }
				];
			}
		});

		this.m.Screens.push({
			ID = "Failed",
			Title = "No Work Today",
			Text = "[img]gfx/ui/events/event_25.png[/img]{You come off that road with fewer men than you went in with, and the wagon is behind you and staying there.\n\nWord reaches %employer% before you do. The smith is alive, they say, and gone west, and he did not leave an address. Your own steel is exactly as you brought it.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Nothing to be done.}",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(-this.Const.World.Assets.ReputationOnContractFailed);
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

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.setScreen("Task");
			}

			function update()
			{
			}

			function end()
			{

				local c = this.Contract;
				if (c.m.Home != null && !c.m.Home.isNull())
				{
					local tile = c.getTileToSpawnLocation(c.m.Home.getTile(), 3, 6, [], false);
					if (tile != null)
					{
						c.m.Site = this.WeakTableRef(::World.spawnLocation("scripts/entity/world/locations/skv_anvil_location", tile.Coords));
						c.m.Site.onSpawned();
						c.m.Site.setDiscovered(true);
						c.m.Site.setAttackable(false);
						::World.uncoverFogOfWar(c.m.Site.getTile().Pos, 500.0);
						::World.getCamera().moveTo(c.m.Site);
					}
				}
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Reach the smith on the road out of " + this.Contract.homeName()
				];

				if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull())
				{
					this.Contract.m.Site.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				local c = this.Contract;

				if (c.m.Fought && !c.m.Won && !c.m.Paid)
				{
					c.m.Paid = true;
					c.m.Concluded = true;
					::Skv.dbg("Skv.Anvil: forge fight LOST -> Failed");
					c.setScreen("Failed");
					this.World.Contracts.showActiveContract();
					return;
				}

				if (c.m.Won && !c.m.Paid)
				{

					if (c.m.Site != null && !c.m.Site.isNull())
					{
						c.m.Site.getSprite("selection").Visible = false;
						c.m.Site.die();
						c.m.Site = null;
						c.m.BulletpointsObjectives = [ "See the smith into " + c.homeName() ];

						c.setScreen("RoadBack");
						this.World.Contracts.showActiveContract();
						return;
					}

					local arrived = false;
					if (c.m.Home == null || c.m.Home.isNull())
					{
						arrived = true;
					}
					else
					{
						arrived = c.isPlayerAt(c.m.Home);

						if (!arrived)
						{
							try
							{
								local t = ::World.State.getCurrentTown();
								if (t != null && t.getID() == c.m.Home.getID()) arrived = true;
							}
							catch (e) {}
						}
					}

					if (arrived)
					{
						c.setScreen("Work");
						this.World.Contracts.showActiveContract();
					}
					return;
				}

				if (c.m.Site == null || c.m.Site.isNull())
				{
					return;
				}

				c.m.Site.getSprite("selection").Visible = true;

				if (!c.m.Fought && c.isPlayerAt(c.m.Site))
				{
					c.setScreen("Arrive");
					this.World.Contracts.showActiveContract();
					return;
				}
			}

			function onCombatForge()
			{
				local c = this.Contract;
				c.m.Fought = true;

				local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
				p.CombatID = "Anvil";
				p.Tile = this.World.State.getPlayer().getTile();
				p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local budget = 77 * c.getScaledDifficultyMult();

				local pick = c.m.Pick != null ? c.m.Pick : c.attackers();
				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();

				::Skv.Spawn.fill(p.Entities, pick.List, budget, fac, "Anvil/" + pick.Name,
					::Const.World.Spawn.BanditRaiders);
				::World.Contracts.startScriptedCombat(p, false, true, true);
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == "Anvil")
				{
					this.Contract.m.Won = true;
					::Skv.dbg("Skv.Anvil: victory");
				}
			}

		});
	}

	function onCancel()
	{
		this.contract.onCancel();
		this.m.Concluded = true;
	}

	function onClear()
	{

		::Skv.Once.release("MasterOfTheAnvil");

		if (this.m.Concluded)
		{
			::World.Flags.set("SkvAnvil.NextDay", ::World.getTime().Days + ::Math.rand(7, 10));
		}

		if (this.m.Site != null && !this.m.Site.isNull())
		{
			this.m.Site.getSprite("selection").Visible = false;
			this.m.Site.die();
		}
		this.m.Site = null;
	}

});
