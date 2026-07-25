// ============================================================================
//  METRINGER SANITARIUM -- CONTRACT (state machine)
//
//  Salindra Concilio hires you to expose Metringer Sanitarium. One accept, one
//  internal leg machine (NOT a cross-contract chain):
//    Leg 0  arrive, the clean tour, shown out -> a hooded tip
//    Leg 1  the night meeting (fight #1) -> the ledger (clue, narrative)
//    Leg 2  return, present the clue (fight #2) -> descend
//    (descent: 3 screens) -> Grummlin's bribe-or-expose fork -> loot haul
//    Leg 3  report back to Salindra (two endings)
//
//  Loot is ONE bundle haul granted at the fork (both paths), via ::Skv.Loot on
//  MSU. Full design: claude/metringer_contracts.md.  Skeleton: skv_black_forks.
// ============================================================================
this.skv_metringer_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Site        = null,   // the sanitarium marker (legs 0,2, and the descent)
		MeetSite    = null,   // the night-meeting marker (leg 1)
		Leg         = 0,      // 0 arrive · 1 meeting · 2 return-with-clue · 3 report
		InDescent   = false,  // set on fight #2 victory; the crawl chain is running
		HasClue     = false,  // set on fight #1 victory (narrative clue; no item)
		TookBribe   = false,  // set at the fork; picks the ending
		ActorName   = "",     // %actor% -- the brother who took the last skill check (::Skv.Check)
		LootRows    = null,   // iconed loot rows (::Legends.EventList) for the climb-out screen; set+shown in one modal chain, not serialized
		PickXPRows  = null,   // XP rows from a clean stair-pick, shown on the DescentCells narration; transient, not serialized
		// -- fight dials (scaled by getScaledDifficultyMult()) --
		MeetBudget  = 70,     // fight #1: Grummlin's agents (Spawn.BanditRaiders) -- lowish
		KeeperBudget= 95,     // fight #2: the keepers (Spawn.Mercenaries) + Head Keeper boss -- lowish
	},

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_metringer";
		this.m.Name = "The Madwoman of Metringer";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 16.0;
		this.m.Category = this.Const.Contracts.Categories.Battle;
		this.m.DescriptionTemplates = [
			"A ragged woman haunts the market, telling anyone who will listen that the sanitarium takes the sick 'past helping' down below and they never come up. The guards found nothing. She is looking for a company with fewer scruples about locked doors.",
			"An escaped patient of a sanitarium is begging for a company to go where the guards would not -- into the cellars of the place that held her, to bring out proof that she is not mad.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		// Lowish difficulty (two small fights + a short dungeon). The fee is a token --
		// the reward is the loot haul at the fork (md s10).
		this.m.DifficultyMult = this.Math.rand(90, 110) * 0.01;

		// NO town-economy (wealth) adjustment -- unlike the mod's other contracts, a flat
		// base here, per design. Base cut ~20% (180 -> 144): Salindra's scraped purse.
		this.m.Payment.Pool = 144 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		this.m.Payment.Completion = 1.0;
		this.m.Payment.Advance = 0.0;

		this.contract.start();
	}

	// -- Site spawning -------------------------------------------------------
	// The sanitarium is a BUILDING, not tied to a biome (nothing in the lore ties it to
	// woods) -- spawn on any reachable land tile 1-3 from home, water / mountains / shore
	// excluded. getTileToSpawnLocation guarantees a tile.
	function pickSiteTile()
	{
		return this.getTileToSpawnLocation(this.m.Home.getTile(), 1, 3, [
			this.Const.World.TerrainType.Ocean,
			this.Const.World.TerrainType.Mountains,
			this.Const.World.TerrainType.Shore
		], false);
	}

	function spawnMarker( _name, _tile = null )
	{
		local tile = _tile != null ? _tile : this.pickSiteTile();
		if (tile == null) return null;
		tile.clear();
		local m = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/undead_ruins_location", tile.Coords));
		m.onSpawned();
		m.setName(_name);
		m.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID());
		m.setBanner(this.World.FactionManager.getFaction(this.Const.FactionType.Bandits).getPartyBanner());
		m.setDiscovered(true);
		m.setAttackable(false);
		this.World.uncoverFogOfWar(m.getTile().Pos, 500.0);
		return m;
	}

	// The meeting sits a SHORT way off from the sanitarium itself (a real travel beat --
	// previously it could land on the doorstep and fire the same instant). Any reachable
	// land tile 2-5 from the Site (water / mountains / shore excluded).
	function pickMeetTile()
	{
		local origin = (!::MSU.isNull(this.m.Site)) ? this.m.Site.getTile() : this.m.Home.getTile();
		return this.getTileToSpawnLocation(origin, 2, 5, [
			this.Const.World.TerrainType.Ocean,
			this.Const.World.TerrainType.Mountains,
			this.Const.World.TerrainType.Shore
		], false);
	}

	function spawnSite() { this.m.Site = this.spawnMarker("Metringer Sanitarium"); }
	function spawnMeet() { this.m.MeetSite = this.spawnMarker("The Night Meeting", this.pickMeetTile()); }

	// Only the ACTIVE objective is lit. _which = "site" | "meet" | "home" | "none".
	function setActiveMarker( _which )
	{
		if (!::MSU.isNull(this.m.Site)) this.m.Site.getSprite("selection").Visible = (_which == "site");
		if (!::MSU.isNull(this.m.MeetSite)) this.m.MeetSite.getSprite("selection").Visible = (_which == "meet");
		if (this.m.Home != null && !this.m.Home.isNull()) this.m.Home.getSprite("selection").Visible = (_which == "home");
	}

	// -- Loot: one of four weighted bundles, granted once at the fork (md s8) --
	function metringerPools()
	{
		return {
			bundles = ::MSU.Class.WeightedContainer([
				[15, "single"], [30, "purse"], [30, "handful"], [25, "coin"]
			]),
			single = ::MSU.Class.WeightedContainer([
				[10, "scripts/items/loot/silver_bowl_item"],        // 490
				[10, "scripts/items/loot/ancient_amber_item"],      // 500
				[8,  "scripts/items/loot/ornate_tome_item"],        // 595
				[8,  "scripts/items/loot/marble_bust_item"],        // 600
				[10, "scripts/items/misc/snake_oil_item"],          // 650
				[6,  "scripts/items/loot/white_pearls_item"],       // 770
				[5,  "scripts/items/loot/ancient_gold_coins_item"], // 875
				[4,  "scripts/items/loot/golden_chalice_item"],     // 980
				[2,  "scripts/items/loot/gemstones_item"],          // 1120
				[1,  "scripts/items/loot/jeweled_crown_item"],      // 1260  luck of the draw
			]),
			mid = [
				"scripts/items/loot/signet_ring_item",          // 245
				"scripts/items/loot/silverware_item",           // 350
				"scripts/items/accessory/recovery_potion_item", // 350
				"scripts/items/loot/jade_broche_item",          // 400
				"scripts/items/misc/happy_powder_item",         // 400
				"scripts/items/misc/miracle_drug_item",         // 450
			],
			cheap = [
				"scripts/items/accessory/antidote_item",  // 150
				"scripts/items/supplies/medicine_item",   // 200
				"scripts/items/loot/growth_pearls_item",  // 200
				"scripts/items/loot/bead_necklace_item",  // 250
			],
		};
	}

	// Roll ONE bundle -> collect item paths + coin, then grant and build the iconed
	// haul rows via ::Skv.Loot.haul (Legends' ::Legends.EventList). The rows are shown
	// on the climb-out screen. No prose loot line any more -- the item icons carry it.
	function rollMetringerHaul()
	{
		local p = this.metringerPools();
		local paths = [];
		local coin = 0;
		switch (p.bundles.roll())
		{
			case "single":
				paths.push(p.single.roll());
				break;
			case "purse":
				paths.push(::MSU.Array.rand(p.mid));
				coin += this.Math.rand(150, 300);
				break;
			case "handful":
			{
				local n = this.Math.rand(2, 3);
				for (local i = 0; i < n; i = i + 1)
				{
					paths.push(::MSU.Array.rand(p.cheap));
				}
				coin += this.Math.rand(20, 80);
				break;
			}
			case "coin":
				coin += this.Math.rand(350, 650);
				break;
		}
		this.m.LootRows = ::Skv.Loot.haul(::Skv.Loot.make(paths), coin);
		this.logInfo("Metringer haul: " + paths.len() + " item(s), " + coin + " crowns");
	}

	// End of the descent -> loot, then flip to the report leg (both fork paths).
	function finishDescent()
	{
		this.rollMetringerHaul();
		this.m.InDescent = false;
		this.m.Leg = 3;
		if (!::MSU.isNull(this.m.Site)) { this.m.Site.die(); this.m.Site = null; }
		this.m.BulletpointsObjectives = ["Report back to " + this.m.Home.getName()];
		this.setActiveMarker("home");
	}

	// ========================================================================
	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Hear out Salindra, then look into Metringer Sanitarium"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				// The once-per-campaign gate is ::Skv.Once (claim in the action, release +
				// guarded-retire in onClear, isLocked in the action). Nothing to do here.
				this.Contract.spawnSite();
				this.Contract.setActiveMarker("site");
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				// Re-assert the right objective marker (also after a load).
				if (this.Contract.m.Leg == 1) this.Contract.setActiveMarker("meet");
				else if (this.Contract.m.Leg == 3) this.Contract.setActiveMarker("home");
				else this.Contract.setActiveMarker("site");
			}

			// ARRIVAL MODEL -- the proven skv_black_forks pattern. update() only runs
			// while NO event screen is open (navigating screens keeps the world paused),
			// so each arrival latches with a TempFlag, cleared when the party leaves the
			// site's 150u radius. The latch is what stops a fired screen from re-popping
			// every tick -- crucially, after the player clicks "To arms" the world ticks
			// once before combat opens, and WITHOUT the latch that tick re-showed the
			// meeting screen on top of the starting fight ("two arms won't go away").
			// The NIGHT MEETING keys off the real world clock exactly like black_forks:
			// by day the clearing is empty (a wait-for-dark beat), and the latch re-arms
			// when day flips to night so the true meeting fires when it should.
			function update()
			{
				// -- Leg 3: report home (black_forks report-leg shape) -----
				if (this.Contract.m.Leg == 3)
				{
					if (this.Contract.isPlayerAt(this.Contract.m.Home))
					{
						if (!this.TempFlags.get("AtHome"))
						{
							this.TempFlags.set("AtHome", true);
							this.Contract.setScreen(this.Contract.m.TookBribe ? "ReportBribe" : "ReportExpose");
							this.World.Contracts.showActiveContract();
						}
					}
					else this.TempFlags.set("AtHome", false);
					return;
				}

				// -- A fight just ended (flag set in onCombatVictory) ------
				if (this.Flags.get("IsVictory"))
				{
					this.Flags.set("IsVictory", false);
					if (this.Contract.m.Leg == 1)
					{
						this.Contract.m.HasClue = true;
						if (!::MSU.isNull(this.Contract.m.MeetSite)) { this.Contract.m.MeetSite.die(); this.Contract.m.MeetSite = null; }
						this.Contract.m.Leg = 2;
						this.Contract.m.BulletpointsObjectives = ["Return to Metringer with what you found"];
						this.Contract.setActiveMarker("site");
						this.Contract.setScreen("MeetingWon");
						this.World.Contracts.showActiveContract();
					}
					else if (this.Contract.m.Leg == 2)
					{
						this.Contract.m.InDescent = true;
						this.Contract.setScreen("DescentStair");
						this.World.Contracts.showActiveContract();
					}
					return;
				}

				// -- The descent runs via the screen getResult chain -------
				if (this.Contract.m.InDescent) return;

				// -- Arrivals (latched; the meeting also branches on day/night) --
				if (this.Contract.m.Leg == 0 && this.Contract.isPlayerAt(this.Contract.m.Site))
				{
					if (!this.TempFlags.get("AtSite")) { this.TempFlags.set("AtSite", true); this.Contract.setScreen("ArriveSanitarium"); this.World.Contracts.showActiveContract(); }
				}
				else if (this.Contract.m.Leg == 1 && !::MSU.isNull(this.Contract.m.MeetSite) && this.Contract.isPlayerAt(this.Contract.m.MeetSite))
				{
					// The hand-off is a NIGHT thing. By day the clearing is empty and the
					// player waits for dark; re-arm on the day->night flip so the real
					// meeting fires when night actually falls (black_forks AtSiteWasDay).
					local isDay = this.World.getTime().IsDaytime;
					if (!this.TempFlags.get("AtMeet") || this.TempFlags.get("AtMeetWasDay") != isDay)
					{
						this.TempFlags.set("AtMeet", true);
						this.TempFlags.set("AtMeetWasDay", isDay);
						this.Contract.setScreen(isDay ? "MeetingDaylight" : "ApproachMeeting");
						this.World.Contracts.showActiveContract();
					}
				}
				else if (this.Contract.m.Leg == 2 && this.Contract.isPlayerAt(this.Contract.m.Site))
				{
					if (!this.TempFlags.get("AtReturn")) { this.TempFlags.set("AtReturn", true); this.Contract.setScreen("PresentClue"); this.World.Contracts.showActiveContract(); }
				}
				else
				{
					this.TempFlags.set("AtSite", false);
					this.TempFlags.set("AtMeet", false);
					this.TempFlags.set("AtReturn", false);
				}
			}

			function onCombat()
			{
				local site = this.Contract.m.Leg == 1 ? this.Contract.m.MeetSite : this.Contract.m.Site;
				local tile = site.getTile();
				local p = ::Const.Tactical.CombatInfo.getClone();
				p.TerrainTemplate = ::Const.World.TerrainTacticalTemplate[tile.TacticalType];
				p.Tile = tile;
				p.CombatID = "Metringer";
				p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;

				local fac = ::World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();

				local mult = this.Contract.getScaledDifficultyMult();

				if (this.Contract.m.Leg == 1)
				{
					// Fight #1 -- Grummlin's agents caught in the open.
					::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.BanditRaiders, this.Contract.m.MeetBudget * mult, fac);
				}
				else
				{
					// Fight #2 -- the keepers at the sanitarium + a bespoke Head Keeper.
					p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
					p.LocationTemplate.Template[0] = "tactical.ruins";
					p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.Walls;
					::Const.World.Common.addUnitsToCombat(p.Entities, ::Const.World.Spawn.Mercenaries, this.Contract.m.KeeperBudget * mult, fac);
					p.BeforeDeploymentCallback = function ()
					{
						local t = null;
						for (local i = 0; i < 60 && t == null; i = i + 1)
						{
							local c = this.Tactical.getTileSquare(this.Math.rand(10, 28), this.Math.rand(6, 26));
							if (c.IsEmpty) t = c;
						}
						if (t == null) return;
						local boss = this.Tactical.spawnEntity("scripts/entity/tactical/enemies/legend_bandit_raider", t.Coords);
						boss.setFaction(fac);
						boss.setName("The Head Keeper");
						boss.getBaseProperties().Hitpoints = 120;
						boss.getBaseProperties().Bravery = 55;
						boss.getBaseProperties().MeleeSkill = 65;
						boss.getBaseProperties().MeleeDefense = 18;
						// A mailed sword-and-board guard captain -- distinct from the cult champion.
						boss.getItems().equip(this.new("scripts/items/legend_armor/chain/legend_armor_mail_shirt"));
						boss.getItems().equip(this.new("scripts/items/helmets/nasal_helmet"));
						boss.getItems().equip(this.new("scripts/items/shields/wooden_shield"));
						boss.getItems().equip(this.new("scripts/items/weapons/longsword"));
						boss.getSkills().update();
						boss.setHitpoints(120);
					};
				}

				::World.Contracts.startScriptedCombat(p, false, false, true);
			}

			// Flag only -- update() advances the leg next tick (deferral rule).
			function onCombatVictory( _combatID )
			{
				if (_combatID == "Metringer") this.Flags.set("IsVictory", true);
			}

			function onRetreatedFromCombat( _combatID )
			{
			}
		});
	}

	// ========================================================================
	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "The Madwoman of Metringer",
			Text = "[img]gfx/ui/events/event_97.png[/img]{A ragged young woman waits where the others will not meet her eye. %SKVNAME%Salindra Concilio%SKVNAME_OFF% was a tailor's apprentice, she says, until she was shut inside %SKVLOC%Metringer Sanitarium%SKVLOC_OFF%. %SPEECH_ON%They take the ones past helping down below, and they do not come up. I saw it. I got out. No one believes me, and the guards found nothing -- but you are not the guards. Go in. See for yourselves. I have little to pay, but I will give what I have to whoever brings the truth out.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{ Text = "{We will look into your sanitarium.}", function getResult() { return "Negotiation"; } }
				];
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({ Text = "{Metringer. Does that name mean anything to anyone?}", function getResult() { return "Lore"; } });
				}
				this.Options.push({ Text = "{This is not for us.}", function getResult() { this.World.Contracts.removeContract(this.Contract); return 0; } });
			}
		});

		this.m.Screens.push({
			ID = "Lore",
			Title = "Metringer Sanitarium",
			Text = "[img]gfx/ui/events/event_99.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% knows the city. %SPEECH_ON%Metringer? Westgate, in %SKVLOC%Absalom%SKVLOC_OFF% -- a house for the sick in the head, older than the district round it. Old Grummlin has run it for years. The Sally Guard have walked every hall more than once. Found nothing but sad souls and clean sheets.%SPEECH_OFF% %SKVNAME%%randombrother2%%SKVNAME_OFF% has heard the other half. %SPEECH_ON%Clean sheets, aye. And a girl who got out swearing they take the ones past helping down below. Everyone calls her mad. She begs at the %SKVLOC%Guiding Hand%SKVLOC_OFF%, and Grummlin's people are always a street behind her. She went to the guards. The guards found nothing.%SPEECH_OFF% %SKVNAME%%randombrother%%SKVNAME_OFF% grunts. %SPEECH_ON%The guards always find nothing. That is not the same as nothing being there. And she is done asking the guards. She is asking us.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [ { Text = "{Enough. The terms, again.}", function getResult() { return "Task"; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "ArriveSanitarium",
			Title = "Metringer Sanitarium",
			Text = "[img]gfx/ui/events/event_183.png[/img]{Director %SKVNAME%Flevvid Grummlin%SKVNAME_OFF% himself shows you the halls -- clean, quiet, every answer smooth as glass. The patients are calm, the ledgers open, the cellar door 'only stores' and locked. By the gate an orderly will not meet your eye. Then you are politely, firmly, shown out. Whatever %SKVNAME%Salindra%SKVNAME_OFF% saw, it will not be seen by daylight with the director at your elbow.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Leave -- for now.}", function getResult() { return "HoodedContact"; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "HoodedContact",
			Title = "A Word in the Dark",
			Text = "[img]gfx/ui/events/event_76.png[/img]{Barely past the gate, a hooded figure falls into step beside you. %SPEECH_ON%The front door was never the way in. Tonight, past the treeline, Grummlin's men meet someone to hand off what they cannot be caught holding. Be there, and you will have your proof.%SPEECH_OFF% They are gone before you can answer.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Then we go to the meeting.}", function getResult() { this.Contract.spawnMeet(); this.Contract.m.Leg = 1; this.Contract.m.BulletpointsObjectives = ["Crash the night meeting near " + this.Contract.m.Home.getName()]; this.Contract.setActiveMarker("meet"); return 0; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "MeetingDaylight",
			Title = "Too Early by Half",
			Text = "[img]gfx/ui/events/event_26.png[/img]{You reach the clearing past the treeline while the sun is still up, and it is empty -- trampled grass, a cold fire-ring, cart-ruts. Whatever Grummlin's men come here to trade, they do it after dark, as the hooded one said. There is nothing to do now but pull back into the trees and wait for night.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Pull back and wait for dark.}", function getResult() { return 0; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "ApproachMeeting",
			Title = "The Night Meeting",
			Text = "[img]gfx/ui/events/event_26.png[/img]{Full dark, and firelight in the clearing at last: Grummlin's men, and a stranger with a cart, trading a heavy ledger and something that does not want to be carried. They have not seen you yet.}",
			Image = "",
			List = [],
			Options = [
				{ Text = "{To arms.}", function getResult() { this.Contract.getActiveState().onCombat(); return 0; } },
				{ Text = "{Hold back.}", function getResult() { return 0; } }
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "MeetingWon",
			Title = "What They Carried",
			Text = "[img]gfx/ui/events/event_63.png[/img]{Among the dead you find it: a ledger in a careful hand, naming the ones taken 'below' at Metringer, and %SKVNAME%Grummlin%SKVNAME_OFF% at the top of every page. Proof enough to force the door. You turn back for the sanitarium.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Back to Metringer.}", function getResult() { return 0; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "PresentClue",
			Title = "At the Gate Again",
			Text = "[img]gfx/ui/events/event_137.png[/img]{This time you do not ask to be let in -- you hold up the ledger where the keepers can read their director's name. The smooth calm is gone in an instant. They cannot show you out now; you know too much. Steel comes out along the wall.}",
			Image = "",
			List = [],
			Options = [
				{ Text = "{So be it. To arms.}", function getResult() { this.Contract.getActiveState().onCombat(); return 0; } },
				{ Text = "{Hold.}", function getResult() { return 0; } }
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "DescentStair",
			Title = "The Sealed Stair",
			Text = "[img]gfx/ui/events/event_74.png[/img]{Behind the 'stores' door a stair goes down into the dark under Metringer. The lock is old and good -- pick it clean and you can go down quiet, room by room. Force it and there will be no quiet at all.}",
			Image = "",
			List = [],
			Options = [
				{ Text = "{Pick the lock.}", function getResult() {
					local c = ::Skv.Check.resolve(this.Contract,
						[["background.thief", 80], ["background.legend_lurker", 55], ["background.vagabond", 30], ["background.gambler", 30]],
						["dexterous"], ["clumsy"], [], ::Skv.Check.handInjuries(), 15);
					// XP for a clean pick -- captured and shown on the DescentCells narration below
					// (that screen already narrates %actor% working the lock, so the "+N" reads there).
					if (c.ok) this.Contract.m.PickXPRows = (c.actor != null && ("XP" in ::Skv)) ? ::Skv.XP.grant(c.actor, 200) : [];
					return c.ok ? "DescentCells" : "ForcedEntry";
				} },
				{ Text = "{Force it -- never mind quiet.}", function getResult() { return "ForcedEntry"; } }
			],
			function start() {}
		});

		// PICK SUCCESS path: the clean way down opens on the cells. Freeing the patients
		// is the honorable beat -- +6 reputation.
		this.m.Screens.push({
			ID = "DescentCells",
			Title = "The Cells",
			Text = "[img]gfx/ui/events/event_100.png[/img]{%actor% works the old lock until it gives without a sound, and the stair opens quiet onto a cellar that is a row of cells -- and the cells are not empty. These are the patients 'past helping' -- kept, not treated, for whatever is done deeper in. Some can still be led out. %SKVNAME%Salindra%SKVNAME_OFF% was telling the truth, every word of it.}",
			Image = "",
			List = [],
			Options = [
				{ Text = "{Free those we can, then press on.}", function getResult() { this.World.Assets.addMoralReputation(6); return "DescentLab"; } },
				{ Text = "{Leave them -- first we end this.}", function getResult() { return "DescentLab"; } }
			],
			function start()
			{
				// Show the XP earned for the clean pick that opened this quiet way down.
				this.List = this.Contract.m.PickXPRows != null ? this.Contract.m.PickXPRows : [];
			}
		});

		// FORCE path (pick failed, or chosen): loud, no quiet way down -- you rush past
		// the cells straight to Grummlin. The prisoners are NOT reached on this route.
		this.m.Screens.push({
			ID = "ForcedEntry",
			Title = "No Quiet Way",
			Text = "[img]gfx/ui/events/event_74.png[/img]{The lock will not give, so you take the door off with iron and shoulders -- loud enough to wake the dead, and no undoing it. There is no picking your way to the cells now, no leading anyone out quiet; only the stair, straight down and fast, before the noise brings worse. You come out in a workshop no healer keeps -- restraints, instruments, a shelf of careful notes in %SKVNAME%Grummlin%SKVNAME_OFF%'s own hand -- and at the bench, not fled, the director himself.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Face Grummlin.}", function getResult() { return "GrummlinChoice"; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "DescentLab",
			Title = "The Room Below",
			Text = "[img]gfx/ui/events/legend_inventor_general.png[/img]{The last room is a workshop no healer keeps -- restraints, instruments, and a shelf of careful notes recording exactly what was done, to whom, and how many did not survive it. The whole truth of Metringer, in %SKVNAME%Grummlin%SKVNAME_OFF%'s own hand. And at the bench, not fled, the director himself.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Face Grummlin.}", function getResult() { return "GrummlinChoice"; } } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "GrummlinChoice",
			Title = "The Director's Offer",
			Text = "[img]gfx/ui/events/event_62.png[/img]{%SKVNAME%Grummlin%SKVNAME_OFF% does not run and does not beg. He slides a heavy purse across the bench. %SPEECH_ON%The Sally Guard found nothing because there is a way these things are handled. Take this, forget the cellar, tell the madwoman her dungeon was empty. Or take nothing, and make an enemy who dines with magistrates. Choose.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{ Text = "{Take the purse. Say nothing.}", function getResult() {
					this.World.Assets.addMoney(this.Math.rand(400, 600));
					this.World.Assets.addMoralReputation(-6);
					this.Contract.m.TookBribe = true;
					this.Contract.finishDescent();
					return "ClimbOut";
				} },
				{ Text = "{Keep your coin. The truth leaves with us.}", function getResult() {
					this.World.Assets.addMoralReputation(8);
					this.World.Assets.addBusinessReputation(30);
					this.Contract.m.TookBribe = false;
					this.Contract.finishDescent();
					return "ClimbOut";
				} }
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "ClimbOut",
			Title = "Up and Out",
			Text = "[img]gfx/ui/events/event_98.png[/img]{Before you climb back into daylight you take what the place owes you -- its silver, its dispensary, whatever is worth the carrying.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Away from this place.}", function getResult() { return 0; } } ],
			function start()
			{
				// The haul was rolled at the fork (finishDescent) -- show it as Legends'
				// iconed reward rows (item pictures + quality frames + coin).
				this.List = [];
				if (this.Contract.m.LootRows != null)
				{
					foreach (r in this.Contract.m.LootRows) this.List.push(r);
				}
			}
		});

		this.m.Screens.push({
			ID = "ReportExpose",
			Title = "The Truth Out",
			Text = "[img]gfx/ui/events/event_85.png[/img]{You bring the ledger back to %SKVNAME%Salindra%SKVNAME_OFF% in %SKVLOC%%townname%%SKVLOC_OFF%. She weeps -- not grief, but the first time anyone believed her. What befalls Grummlin now is out of your hands, but it is out of the dark. She presses her few coins on you, and word of what your company did travels faster than the pay.}",
			Image = "",
			List = [],
			Options = [ { Text = "{It was owed.}", function getResult() {
				this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
				this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
				this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Exposed Metringer Sanitarium");
				this.World.Contracts.finishActiveContract();
				return 0;
			} } ],
			function start() {}
		});

		this.m.Screens.push({
			ID = "ReportBribe",
			Title = "A Kind Lie",
			Text = "[img]gfx/ui/events/event_97.png[/img]{You find %SKVNAME%Salindra%SKVNAME_OFF% in %SKVLOC%%townname%%SKVLOC_OFF% and tell her the lie you agreed to for Grummlin's coin: no dungeon, no proof, only some men conspiring, whom you put down. Her face closes. She thanks you, quietly, and pays what little she promised. She will go on being the madwoman no one believed -- and you know exactly what you left down there.}",
			Image = "",
			List = [],
			Options = [ { Text = "{Take the pay and go.}", function getResult() {
				this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
				this.World.Contracts.finishActiveContract();
				return 0;
			} } ],
			function start() {}
		});
	}

	function onClear()
	{
		::Skv.Once.release("Metringer");   // always free the live-offer slot (any removal)
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Metringer");   // accepted then concluded (completed/aborted) -> retire
			if (!::MSU.isNull(this.m.Site)) this.m.Site.getSprite("selection").Visible = false;
			if (!::MSU.isNull(this.m.MeetSite)) this.m.MeetSite.getSprite("selection").Visible = false;
			if (this.m.Home != null && !this.m.Home.isNull()) this.m.Home.getSprite("selection").Visible = false;
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onPrepareVariables( _vars )
	{
		// Person + location colour marks (as black_forks). Loot is now shown as iconed
		// rows on the climb-out screen (::Skv.Loot.haul), so there is no %loot% var.
		_vars.push(["SKVNAME", "[color=#9dbccb]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);
		_vars.push(["SKVLOC", "[color=#b39dbc]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);
		_vars.push(["actor", this.m.ActorName]);   // the brother who took the last skill check
	}

	function onSerialize( _out )
	{
		_out.writeU32(!::MSU.isNull(this.m.Site) ? this.m.Site.getID() : 0);
		_out.writeU32(!::MSU.isNull(this.m.MeetSite) ? this.m.MeetSite.getID() : 0);
		_out.writeU8(this.m.Leg);
		_out.writeU8(this.m.InDescent ? 1 : 0);
		_out.writeU8(this.m.HasClue ? 1 : 0);
		_out.writeU8(this.m.TookBribe ? 1 : 0);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local s = _in.readU32();
		if (s != 0) this.m.Site = this.WeakTableRef(::World.getEntityByID(s));
		local ms = _in.readU32();
		if (ms != 0) this.m.MeetSite = this.WeakTableRef(::World.getEntityByID(ms));
		this.m.Leg = _in.readU8();
		this.m.InDescent = _in.readU8() == 1;
		this.m.HasClue = _in.readU8() == 1;
		this.m.TookBribe = _in.readU8() == 1;
		this.contract.onDeserialize(_in);
	}

});
