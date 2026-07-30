this.skv_ambush_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Site        = null,
		Destination = null,
		DestName    = "",
		HasPackage  = false,
		SiteCleared = false,
		Decided     = false,
		Betrayed    = false,
		OutcomeText = "",
		OutcomeRows = null,
		RoomRows    = null,
		RoomText    = "",
		ActorName   = "",
		Deck        = null,
		CrawlIndex  = 0,
		FightWon    = false,
		FightFled   = false,
	},

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_ambush";
		this.m.Name = "An Ambush";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A Pathfinder Society venture-captain is short an agent. The lad took a sealed parcel down into the city drains to save a few streets and never came up the other side - and there is a contact in the next town still waiting on it. The venture-captain wants his agent found, the parcel recovered, and the thing carried the rest of the way, sealed. He is paying outside hands to do quietly what the Society cannot be seen to do.",
			"Word from the local lodge: a Pathfinder's agent lost in the undercity, a sealed package gone with him, and something down in the drains that folk have started crossing the street to avoid. The pay is fair for a fetch, better for a fight - and there may be both.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(65, 80) * 0.01;

		this.m.Payment.Pool = 900 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();

		this.m.Payment.Completion = 0.67;
		this.m.Payment.Advance = 0.33;

		this.contract.start();
	}

	function pickSiteTile()
	{
		local excluded = [
			this.Const.World.TerrainType.Ocean,
			this.Const.World.TerrainType.Shore,
			this.Const.World.TerrainType.Mountains
		];
		return this.getTileToSpawnLocation(this.m.Home.getTile(), 1, 2, excluded, false);
	}

	function pickDestination()
	{
		local best = null;     local bestD = 99999;
		local fallback = null; local fbD = 99999;
		foreach (s in this.World.EntityManager.getSettlements())
		{
			if (s == null) continue;
			if (s.getID() == this.m.Home.getID()) continue;
			if (!s.isDiscovered()) continue;
			if (s.isMilitary()) continue;
			if (s.isIsolated()) continue;
			local d = this.m.Home.getTile().getDistanceTo(s.getTile());
			if (d < fbD) { fbD = d; fallback = s; }
			if (this.m.Home.isConnectedToByRoads(s) && d < bestD) { bestD = d; best = s; }
		}
		return best != null ? best : fallback;
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{

				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull())
				{
					this.Contract.m.Name = "Ambush in " + this.Contract.m.Home.getName();
				}
				this.Contract.m.BulletpointsObjectives = [
					"Follow the courier's trail into the undercity drains"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				local dest = this.Contract.pickDestination();
				if (dest == null) dest = this.Contract.m.Home;
				this.Contract.m.Destination = this.WeakTableRef(dest);
				this.Contract.m.DestName = dest.getName();

				local tile = this.Contract.pickSiteTile();
				if (tile == null)
				{
					local excluded = [
						this.Const.World.TerrainType.Ocean,
						this.Const.World.TerrainType.Shore,
						this.Const.World.TerrainType.Mountains
					];
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 1, 5, excluded, false);
				}
				tile.clear();
				this.Contract.m.Site = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_ambush_location", tile.Coords));
				this.Contract.m.Site.onSpawned();
				this.Contract.m.Site.setName("The Undercity Drains");
				this.Contract.m.Site.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Goblins).getID());
				this.Contract.m.Site.setDiscovered(true);
				this.Contract.m.Site.setAttackable(false);
				this.World.uncoverFogOfWar(this.Contract.m.Site.getTile().Pos, 500.0);

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{

				if (this.Contract.m.SiteCleared || this.Contract.m.HasPackage)
				{
					this.Contract.m.BulletpointsObjectives = [
						"Deliver the sealed package to " + this.Contract.m.DestName
					];
					if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull())
					{
						this.Contract.m.Destination.getSprite("selection").Visible = true;
					}
				}
				else
				{
					this.Contract.m.BulletpointsObjectives = [
						"Follow the courier's trail into the undercity drains"
					];
					if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull())
					{
						this.Contract.m.Site.getSprite("selection").Visible = true;
					}
				}
			}

			function update()
			{

				if (this.Contract.m.FightWon)
				{
					this.Contract.m.FightWon = false;
					local justFought = this.Contract.m.Deck[this.Contract.m.CrawlIndex];
					this.Contract.m.CrawlIndex = this.Contract.m.CrawlIndex + 1;
					this.TempFlags.set("AtSite", true);
					if (justFought == "escort")
					{
						this.Contract.recoverPackage();
						this.Contract.setScreen("RecoverRoom");
					}
					else
					{
						this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
					}
					this.World.Contracts.showActiveContract();
					return;
				}

				if (this.Contract.m.FightFled)
				{
					this.Contract.m.FightFled = false;
					this.TempFlags.set("AtSite", true);
					this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
					this.World.Contracts.showActiveContract();
					return;
				}

				if (this.Contract.m.SiteCleared)
				{
					this.Contract.setState("Deliver");
					return;
				}

				if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull() && this.Contract.isPlayerAt(this.Contract.m.Site))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						if (this.Contract.m.Deck == null)
						{
							this.Contract.m.Deck = this.Contract.assembleDeck();
							this.Contract.m.CrawlIndex = 0;
						}
						this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
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
				if (_combatID == "AmbushFight")
				{
					this.Contract.m.FightWon = true;
				}
			}

			function onRetreatedFromCombat( _combatID )
			{
				if (_combatID == "AmbushFight")
				{
					this.Contract.m.FightFled = true;
				}
			}
		});

		this.m.States.push({
			ID = "Deliver",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Deliver the sealed package to " + this.Contract.m.DestName
				];

				if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull())
				{
					this.Contract.m.Destination.getSprite("selection").Visible = true;
				}
			}

			function update()
			{

				if (this.Contract.m.Destination != null && !this.Contract.m.Destination.isNull() && this.Contract.isPlayerAt(this.Contract.m.Destination))
				{
					if (!this.TempFlags.get("AtDest"))
					{
						this.TempFlags.set("AtDest", true);
						this.Contract.setScreen(this.Contract.m.Decided ? "Outcome" : "Delivery");
						this.World.Contracts.showActiveContract();
					}
				}
				else
				{
					this.TempFlags.set("AtDest", false);
				}
			}
		});
	}

	function assembleDeck()
	{

		return ["trail", "trap", "patrol", "rest", "track", "escort"];
	}

	function roomScreenFor( _key )
	{
		if (_key == "trail")  return "TrailRoom";
		if (_key == "trap")   return "TrapRoom";
		if (_key == "patrol") return "PatrolFight";
		if (_key == "rest")   return "RestRoom";
		if (_key == "track")  return "TrackRoom";
		if (_key == "escort") return "EscortFight";
		return "TrailRoom";
	}

	function advance()
	{
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return this.roomScreenFor(this.m.Deck[this.m.CrawlIndex]);
	}

	function resolveRoom( _rows, _text )
	{
		this.m.RoomRows = _rows;
		this.m.RoomText = _text;
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return "RoomResult";
	}

	function newFightProperties()
	{
		local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
		p.CombatID = "AmbushFight";
		p.Tile = this.World.State.getPlayer().getTile();
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;
		p.TerrainTemplate = "tactical.plains";
		p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
		p.LocationTemplate.Template[0] = "tactical.ruins";
		p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.None;
		return p;
	}

	function goblinFactionID()
	{
		return this.World.FactionManager.getFactionOfType(this.Const.FactionType.Goblins).getID();
	}

	function startPatrolFight()
	{
		this.m.FightWon = false;
		this.m.FightFled = false;
		local p = this.newFightProperties();
		local fac = this.goblinFactionID();
		local budget = 50 * this.getDifficultyMult() * this.getScaledDifficultyMult();

		this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn.GolarionKobolds, budget, fac);
		::Skv.dbg("Skv.Ambush patrol budget=" + budget);
		this.World.Contracts.startScriptedCombat(p, false, true, true);
	}

	function escortBossTier()
	{
		local mult = this.getScaledDifficultyMult();
		if (mult < 1.3) return 0;
		if (mult < 2.5) return 1;
		return 2;
	}

	function startEscortFight()
	{
		this.m.FightWon = false;
		this.m.FightFled = false;
		local p = this.newFightProperties();
		local fac = this.goblinFactionID();
		local budget = 70 * this.getDifficultyMult() * this.getScaledDifficultyMult();

		this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn.GolarionKoboldsCasters, budget, fac);

		local tier = this.escortBossTier();
		if (tier == 0)
		{

			p.Entities.push({
				ID = ::Const.EntityType.SkvKobold, Variant = 0, Row = 0,
				Script = "scripts/entity/tactical/enemies/skv_kobold",
				Faction = fac, Callback = this.onCappedChampionPlaced.bindenv(this)
			});
		}
		else if (tier == 1)
		{

			p.Entities.push({
				ID = ::Const.EntityType.SkvKoboldWarrior, Variant = 0, Row = 0,
				Script = "scripts/entity/tactical/enemies/skv_kobold_warrior",
				Faction = fac, Callback = this.onCappedChampionPlaced.bindenv(this)
			});
		}
		else
		{

			p.Entities.push({
				ID = ::Const.EntityType.SkvKoboldChief, Variant = 0, Row = 0,
				Script = "scripts/entity/tactical/enemies/skv_kobold_chief",
				Faction = fac, Callback = this.onChampionChiefPlaced.bindenv(this)
			});
		}
		::Skv.dbg("Skv.Ambush escort budget=" + budget + " bossTier=" + tier);
		this.World.Contracts.startScriptedCombat(p, false, true, true);
	}

	function onCappedChampionPlaced( _entity, _tag )
	{
		_entity.makeMiniboss();
		local items = _entity.getItems();
		local slots = [this.Const.ItemSlot.Mainhand, this.Const.ItemSlot.Offhand];
		foreach (slot in slots)
		{
			local it = items.getItemAtSlot(slot);
			if (it != null && it.isItemType(this.Const.Items.ItemType.Named))
			{
				items.unequip(it);
				items.removeFromBag(it);
			}
		}
		_entity.assignRandomEquipment();
		local names = ["Grukk Blackfang", "Snagga the Chief", "Vharrok", "Old Skabb", "Gnashjaw", "Rukka Warlord"];
		_entity.setName(names[this.Math.rand(0, names.len() - 1)]);
	}

	function onChampionChiefPlaced( _entity, _tag )
	{
		_entity.makeMiniboss();
		local names = ["Grukk Blackfang", "Snagga the Chief", "Vharrok", "Old Skabb", "Gnashjaw", "Rukka Warlord"];
		_entity.setName(names[this.Math.rand(0, names.len() - 1)]);
	}

	function recoverPackage()
	{
		this.m.HasPackage = true;
		local coin = this.Math.rand(90, 170);
		local paths = ["scripts/items/loot/signet_ring_item"];
		this.m.RoomRows = ::Skv.Loot.haul(::Skv.Loot.make(paths), coin);
		this.m.RoomText = "[img]gfx/ui/events/event_98.png[/img]{The chief's guard lie where they fell. Among their filched trophies is a Pathfinder's-worth of a poor lad's life: a battered ring, a few coins, and - wrapped in oilcloth and still sealed with a wax stamp none of the goblins could read - the parcel the courier died carrying. You take it up. It is light, and it is whole. The rest of the way is yours to walk.}";

		this.m.BulletpointsObjectives = [
			"Deliver the sealed package to " + this.m.DestName
		];
		if (this.m.Destination != null && !this.m.Destination.isNull())
		{
			this.m.Destination.getSprite("selection").Visible = true;
		}
	}

	function departForDelivery()
	{
		this.m.SiteCleared = true;
		if (!::MSU.isNull(this.m.Site)) this.m.Site.die();
		this.m.Site = null;
		this.m.BulletpointsObjectives = [
			"Deliver the sealed package to " + this.m.DestName
		];
		if (this.m.Destination != null && !this.m.Destination.isNull())
		{
			this.m.Destination.getSprite("selection").Visible = true;
		}

	}

	function destFaction()
	{
		if (this.m.Destination == null || this.m.Destination.isNull()) return null;
		try { return this.World.FactionManager.getFaction(this.m.Destination.getFaction()); }
		catch (e) { return null; }
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "The Missing Courier",
			Text = "[img]gfx/ui/events/event_76.png[/img]{%SKVNAME%Venture-Captain Ambrus Valsin%SKVNAME_OFF% of the Pathfinder Society catches you at the lodge, worry under the courtesy. %SPEECH_ON%I sent one of my agents two days past - a green lad, all eagerness and no sense - with a sealed parcel for a contact of mine in %SKVLOC%%destinationname%%SKVLOC_OFF%. He took the drains under the city to spare himself the streets, and he has not come up. There is something down in those tunnels now; folk have started going the long way round. This is Society business, and I would sooner not feed more of my own to it. Find him. If he lives, send him home with his ears ringing. If he does not - bring the parcel up sealed, and carry it the rest of the way to my contact yourself. Part of your pay now, the rest when it is in his hands. And mind the seal: it is my contact's to break, not ours.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We will find your courier and see the parcel through.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{The drains, you say. What is down there?}",
						function getResult() { return "Lore"; }
					});
				}

				this.Options.push({
					Text = "{Find another company.}",
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
			Title = "The Undercity",
			Text = "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% has walked drains like these before. %SPEECH_ON%Every old city is built on its own gut - sewers, cisterns, the tunnels nobody maps. Warm, dark, out of the rain. Good place to move unseen; good place for things that would rather not be seen.%SPEECH_OFF% %SKVNAME%%randombrother2%%SKVNAME_OFF% grunts. %SPEECH_ON%Goblins, most like. They den in the undercity and string the runs with tripwires and pits - and they set MORE of them when they are expecting company. If the little wretches are fortifying, some bigger goblin is coming to call.%SPEECH_OFF% The first man nods. %SPEECH_ON%So we go in careful, and we do not go in blind. A lost boy is one thing. A trapped warren with a chief on the way is another.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Enough. The terms again.}",
					function getResult() { return "Task"; }
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "TrailRoom",
			Title = "The Courier's Trail",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The drain mouth breathes cold, wet air. Just inside, in the silt along a trickle of runoff, a set of muddy bootprints leads in - a young man's stride, hurried, careless. They wind deeper into the dark, following the water. So does the company.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On, then - quiet and careful.}",
					function getResult() { return this.Contract.advance(); }
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "TrapRoom",
			Title = "A Trapped Passage",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The tunnel narrows to a low, muddy junction. The floor ahead may be wrong - a stretch of packed muck that could be laid a shade too smooth, too level, or could be nothing at all. Goblins dig covered pits here, a full stride deep and floored with filed stakes, and lid them over so well the first you know is the drop. There is no wire to find, no catch to cut: someone has to read the ground with a sharp eye, and someone light-footed has to lead the company across it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Sharp eyes to find it, light feet to cross it.}",
						function getResult()
						{

							local spot = ::Skv.Check.perception(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local spotter = spot.actor;
							local spotterName = (spotter != null) ? spotter.getName() : "the point man";

							local cross = ::Skv.Check.agility(this.Contract, spot.ok ? 50 : 25);
							local crosserName = (cross.actor != null) ? cross.actor.getName() : this.Contract.m.ActorName;

							if (cross.ok)
							{

								local actors = [];
								if (cross.actor != null) actors.push(cross.actor);
								if (spot.ok && spotter != null) actors.push(spotter);
								local rows = (actors.len() > 0 && ("XP" in ::Skv)) ? ::Skv.XP.grant(actors, 200) : [];
								local text = spot.ok
									? "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + spotterName + "%SKVNAME_OFF% catches the seam of the false floor before a boot ever finds it, and on his word %SKVNAME%" + crosserName + "%SKVNAME_OFF% threads the company past the covered pit one man at a time - each boot set where his was. No sound, no fall. Whoever dug it will not know a soul crossed.}"
									: "[img]gfx/ui/events/event_89.png[/img]{No one marks the floor for what it is - but %SKVNAME%" + crosserName + "%SKVNAME_OFF% feels it give a hair too easy underfoot, freezes the whole line with a hiss, and picks the way across the covered pit on instinct alone. Quick feet and quicker luck, and the company is over dry.}";
								return this.Contract.resolveRoom(rows, text);
							}
							return this.Contract.resolveRoom([this.Contract.trapFall(crosserName)], "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + crosserName + "%SKVNAME_OFF% leads off and gets it wrong. The lid gives under him and he drops a full stride into the pit, twisting as he falls to keep off the stakes - and comes up on a leg that will not take his weight. The men haul him out. He can walk, after a fashion; the warren, no doubt, heard him land.}");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "PatrolFight",
			Title = "The Picket",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The passage opens into a flooded junction - and the dark is full of eyes. Goblins, a picket of them, crouched in the drain-mouths with slings and jagged spears, watching the very ground the trap defended. Between two of them, sprawled half in the water, is the boy: a courier's satchel-strap still crossing his chest, empty, and his throat a ruin. He found this picket the hard way. Now it has found you.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Blades. Put them down before they scatter and warn the rest.}",
						function getResult()
						{
							this.Contract.startPatrolFight();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "RestRoom",
			Title = "A Breather",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The picket is down and the water goes quiet again. Before pressing deeper the company takes what rest the dark allows - a few minutes to bind the worst of it, cinch a loose strap, put an edge back on a notched blade, drink. %SKVNAME%%randombrother%%SKVNAME_OFF% works a whetstone down his blade and does not look up. %SPEECH_ON%Those were the doorkeepers. Whatever they were minding is deeper in, and it will be bigger. Set your gear right the once - there'll be no asking for it down there.%SPEECH_OFF% Past the running water, somewhere ahead, a great many voices are on the move.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [

					{
						Text = "{Set our gear right the once - there'll be no asking down there. (open loadout)}",
						function getResult()
						{
							::World.State.showLoadoutFromContract();
							return "RestRoom";
						}
					},
					{
						Text = "{Buckled and ready. On, deeper.}",
						function getResult() { return this.Contract.advance(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "TrackRoom",
			Title = "The Lost Trail",
			Text = "[img]gfx/ui/events/event_89.png[/img]{Past the picket the boy's tracks are gone - churned away under a hundred small clawed feet coming and going. The satchel is not on his body; the goblins have carried it deeper. For a while the company casts about the muck in the dark, until someone picks out the freshest of the goblin runs - broad, well-worn, heading toward a wider tunnel where the sound of a good many voices echoes up. The chief's road. The parcel went that way.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Follow it. Toward the voices.}",
					function getResult() { return this.Contract.advance(); }
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "EscortFight",
			Title = "The Chief's Escort",
			Text = "[img]gfx/ui/events/event_89.png[/img]{The tunnel widens into a vaulted trunk-drain, and there - coming the other way, torches and tusked helms - is the chief's own escort: the warband's best, spears and shields, and at their head a goblin bigger than any you have seen, hung with the trophies of a dozen fights and the satchel of a dead courier tied at his belt like one more. He was expecting an ambush on his road. He has decided you are it. There is no talking past this.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Then give him one. Take the chief.}",
						function getResult()
						{
							this.Contract.startEscortFight();
							return 0;
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "RecoverRoom",
			Title = "Off the Chief's Guard",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Out of the drains - we have a parcel to deliver.}",
					function getResult()
					{

						this.Contract.departForDelivery();
						this.Contract.setState("Deliver");
						return 0;
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You take up the sealed parcel and turn for the surface.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		this.m.Screens.push({
			ID = "RoomResult",
			Title = "The Drains",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On.}",

					function getResult() { return this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]); }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You press on.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		this.m.Screens.push({
			ID = "Delivery",
			Title = "The Sealed Parcel",
			Text = "[img]gfx/ui/events/event_15.png[/img]{In %SKVLOC%%destinationname%%SKVLOC_OFF% the contact keeps a counter in the back of a low tavern: %SKVNAME%Guaril Karela%SKVNAME_OFF%, a thin, mustachioed man who goes still at the sight of the wax seal, then eases when he sees it whole. %SPEECH_ON%Valsin's parcel - and unopened. Good. You have no notion how rare that is in this trade.%SPEECH_OFF% He reaches for it across the counter. The thing is a hand-span of oilcloth and a lump of wax, and a green lad carried it down into the dark and never came out. Whatever is under that seal, Karela means to be the one to read it.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [];

				this.Options.push({
					Text = "{Hand it over. Sealed, as promised.}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeMoney(this.Contract.m.Payment.getOnCompletion()));
						rows.push(::Legends.EventList.changeRenown(20));
						local f = this.Contract.destFaction();
						if (f != null) f.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Delivered a sealed parcel, unopened");
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_15.png[/img]{Karela slits the wax with a thumbnail and folds back the oilcloth - and what lies inside stops the whole company short. A cookery book. A fat, dog-eared book of Varisian recipes, the sort that sits on any tavern shelf. He thumbs to a recipe near the back, reads it through once with his lips moving, then closes it and holds it out to you. %SPEECH_ON%My thanks to the venture-captain - tell him it is read. The book itself I have already; keep it, or leave it.%SPEECH_OFF% He counts out the balance all the same, and a little over for the seal kept whole. Somewhere between two recipes was a single line meant only for him - and a green lad died in the dark, and good men bled in the warren, to carry a cookbook the man already owned. You take the coin. The book you leave on the counter.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});

				this.Options.push({
					Text = "{A dead boy died for this. We should know what it is. (break the seal)}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeRenown(-15));
						local f = this.Contract.destFaction();
						if (f != null) f.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Pried open a sealed parcel entrusted to them");
						this.Contract.m.Betrayed = true;
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_15.png[/img]{Somewhere on the road the temptation wins, and you work the wax loose. Inside is - a cookery book. A dog-eared book of Varisian recipes, and for a breath the whole company just stares at it: this is what the lad died carrying, this is what you bled in the warren for. Only later, turning the pages, does someone catch a recipe near the back that reads a shade wrong - names where the measures should be, a road folded into the method. A Sczarni cipher, and by now the seal is broken and it is too late to matter. In %SKVLOC%%destinationname%%SKVLOC_OFF% %SKVNAME%Guaril Karela%SKVNAME_OFF% takes one look at the broken wax and will not touch it. %SPEECH_ON%You have opened what was not yours to open. Take your cookbook and go - and pray Venture-Captain Valsin does not hear you were prying into his affairs.%SPEECH_OFF% You keep the advance, and nothing more, and word of a company that pries travels on ahead of you.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "Outcome",
			Title = "The Seal",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{So it is done.}",
					function getResult()
					{
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.OutcomeText != "" ? this.Contract.m.OutcomeText : "{The parcel is delivered, one way or another, and the road goes on.}";
				this.List = this.Contract.m.OutcomeRows != null ? this.Contract.m.OutcomeRows : [];
			}
		});
	}

	function trapFall( _name )
	{
		local injured = null;
		foreach (bro in this.World.getPlayerRoster().getAll())
		{
			if (bro.getName() == _name) { injured = bro; break; }
		}
		if (injured == null)
		{
			local roster = this.World.getPlayerRoster().getAll();
			if (roster.len() > 0) injured = roster[this.Math.rand(0, roster.len() - 1)];
		}
		if (injured == null)
		{
			return { id = 10, icon = "ui/icons/health.png", text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]Someone takes a bad fall[/color]" };
		}

		local inj = injured.addInjury(this.Const.Injury.Mountains);
		local label = injured.getName() + (inj != null ? " - " + inj.getNameOnly() : " takes a bad fall");
		return {
			id = 10,
			icon = (inj != null ? inj.getIcon() : "ui/icons/health.png"),
			text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + label + "[/color]"
		};
	}

	function onClear()
	{
		::Skv.Once.release("Ambush");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Ambush");
			if (!::MSU.isNull(this.m.Site))
			{
				this.m.Site.getSprite("selection").Visible = false;
			}
			if (this.m.Destination != null && !this.m.Destination.isNull())
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

		_vars.push(["destinationname", this.m.DestName != "" ? this.m.DestName : "the next town"]);
	}

	function onSerialize( _out )
	{
		if (!::MSU.isNull(this.m.Site)) _out.writeU32(this.m.Site.getID());
		else _out.writeU32(0);

		if (this.m.Destination != null && !this.m.Destination.isNull()) _out.writeU32(this.m.Destination.getID());
		else _out.writeU32(0);
		_out.writeString(this.m.DestName);

		_out.writeU8(this.m.HasPackage ? 1 : 0);
		_out.writeU8(this.m.SiteCleared ? 1 : 0);
		_out.writeU8(this.m.Decided ? 1 : 0);
		_out.writeU8(this.m.Betrayed ? 1 : 0);

		if (this.m.Deck == null) _out.writeU8(0);
		else
		{
			_out.writeU8(this.m.Deck.len());
			foreach (k in this.m.Deck) _out.writeString(k);
		}
		_out.writeU8(this.m.CrawlIndex);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local site = _in.readU32();
		if (site != 0) this.m.Site = this.WeakTableRef(::World.getEntityByID(site));

		local dest = _in.readU32();
		if (dest != 0) this.m.Destination = this.WeakTableRef(::World.getEntityByID(dest));
		this.m.DestName = _in.readString();

		this.m.HasPackage  = _in.readU8() == 1;
		this.m.SiteCleared = _in.readU8() == 1;
		this.m.Decided     = _in.readU8() == 1;
		this.m.Betrayed    = _in.readU8() == 1;

		local dn = _in.readU8();
		if (dn > 0)
		{
			this.m.Deck = [];
			for (local i = 0; i < dn; i = i + 1) this.m.Deck.push(_in.readString());
		}
		this.m.CrawlIndex = _in.readU8();

		this.contract.onDeserialize(_in);
	}

});
