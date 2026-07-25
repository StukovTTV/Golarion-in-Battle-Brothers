// ============================================================================
//  THE AZARI PALACE -- CONTRACT (state machine)   [MILESTONE SKELETON]
//
//  >>> LOADABLE SKELETON. <<< Spine complete and proven in-game. STUBBED: the crawl
//  interior (lore-mood rooms, moral-cost loot table, the Ancient Dead crypt with the
//  trophy + 2500 buy-back) is a single "find the Tome" screen. The four endings are
//  wired and show an ICONED reward list on the Outcome screen. See azari_palace_contracts.md.
//
//  Structure: Offer -> Running. The report leg is a flag inside Running.
// ============================================================================
this.skv_azari_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Site        = null,    // the Azari Palace marker
		HasTome     = false,   // the objective is in hand
		SiteCleared = false,   // flips Running from "go to the palace" to "report home"
		Decided     = false,   // an ending was chosen -> show Outcome, not Decision, on re-arrival
		OutcomeText = "",      // narrative shown on the Outcome screen (not serialized)
		OutcomeRows = null,    // iconed reward rows shown on the Outcome screen (not serialized)
		CryptTrophy = "",      // "" | "bardiche" | "plate" -- set by the crypt; drives the exit buy-back
		CryptWon     = false,  // combat won -> update() shows CryptResult (transient, not serialized)
		CryptFled    = false,  // retreated from the crypt -> skip it (transient)
		CryptResolved = false, // guard so the crypt result/skip fires exactly once (transient)
		CryptForced  = false,  // forced the crypt door -> a bigger fight (transient)
		CryptPickFailed = false, // the lockpick failed -> only force/leave remain (transient)
		ActorName    = "",     // whoever last acted on a check -> ::Skv.Check %actor% (transient)
		Fee         = 620,     // the steward's admission fee, paid at the door (a real out-of-pocket gamble)
		// -- crawl state --
		Deck        = null,    // array of room-card keys, assembled when you pay the door
		CrawlIndex  = 0,       // which card you are on
		RoomRows    = null,    // a room's result rows (mood / loot) for the RoomResult screen (not serialized)
		RoomText    = "",      // a room's result narrative (not serialized)
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_azari";
		this.m.Name = "The Azari Commission";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 12.0;
		this.m.Category = this.Const.Contracts.Categories.Economy;
		this.m.DescriptionTemplates = [
			"A soft-spoken stranger is asking quietly after a company that can be discreet. There is an old family in a far city -- the Azari, keepers of a temple to a god no one prays to any more -- and among their dusty relics is one particular book he means to have. He pays well, and most of it up front. He does not say why.",
			"Word goes round, low and careful, that someone is hiring for a matter of antiquities: a brass-bound tome to be lifted without fuss from the relic-halls of a forlorn noble house. The coin is good and the questions are few.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		// ~1 skull: the board reads an easy errand because the only combat is the
		// OPT-IN crypt. The danger (the fee gamble, the fork) lives inside the job.
		this.m.DifficultyMult = this.Math.rand(75, 85) * 0.01;

		// Flat base (a smuggler's set fee -- no town-wealth factor). The 1-skull
		// DIFF^POW heavily damps the pool, so the base runs high to land a pay worth
		// the door fee. (Real reward is the plunder -- loot + crypt trophy + buy-back; retune
		// the fee-vs-pool then.)
		this.m.Payment.Pool = 1000 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		// 35% up front, 65% on delivery. The advance covers only part of the fee.
		this.m.Payment.Completion = 0.65;
		this.m.Payment.Advance = 0.35;

		this.contract.start();
	}

	// Any free land tile 3-8 from home (no terrain theme). Water/shore/mountains out.
	function pickSiteTile()
	{
		local excluded = [
			this.Const.World.TerrainType.Ocean,
			this.Const.World.TerrainType.Shore,
			this.Const.World.TerrainType.Mountains
		];
		return this.getTileToSpawnLocation(this.m.Home.getTile(), 3, 8, excluded, false);
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Retrieve the Tome of Memory from the Azari Palace"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				local tile = this.Contract.pickSiteTile();
				if (tile == null)
				{
					local excluded = [
						this.Const.World.TerrainType.Ocean,
						this.Const.World.TerrainType.Shore,
						this.Const.World.TerrainType.Mountains
					];
					tile = this.Contract.getTileToSpawnLocation(this.Contract.m.Home.getTile(), 2, 10, excluded, false);
				}

				tile.clear();
				this.Contract.m.Site = this.WeakTableRef(this.World.spawnLocation("scripts/entity/world/locations/skv_azari_location", tile.Coords));
				this.Contract.m.Site.onSpawned();
				this.Contract.m.Site.setName("Azari Palace");
				this.Contract.m.Site.setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID());
				this.Contract.m.Site.setBanner(this.World.FactionManager.getFaction(this.Const.FactionType.Bandits).getPartyBanner());
				this.Contract.m.Site.setDiscovered(true);
				this.Contract.m.Site.setAttackable(false);   // a marker we resolve via screens, not a garrison
				this.World.uncoverFogOfWar(this.Contract.m.Site.getTile().Pos, 500.0);

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}

		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull())
				{
					this.Contract.m.Site.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				// --- CRYPT resolved: grant the trophy (won) or skip it (fled), consume the crypt
				// card, and show the result BEFORE the crawl-resume logic below can re-fire.
				if (this.Contract.m.CryptWon && !this.Contract.m.CryptResolved)
				{
					this.Contract.m.CryptResolved = true;
					this.Contract.m.CrawlIndex = this.Contract.m.CrawlIndex + 1;
					this.TempFlags.set("AtSite", true);
					this.Contract.setScreen("CryptResult");
					this.World.Contracts.showActiveContract();
					return;
				}
				if (this.Contract.m.CryptFled && !this.Contract.m.CryptResolved)
				{
					this.Contract.m.CryptResolved = true;
					this.Contract.m.CrawlIndex = this.Contract.m.CrawlIndex + 1;
					this.TempFlags.set("AtSite", true);
					this.Contract.setScreen(this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]));
					this.World.Contracts.showActiveContract();
					return;
				}

				// --- REPORT LEG: Tome in hand, walk back home to decide -----------
				if (this.Contract.m.SiteCleared)
				{
					if (this.Contract.isPlayerAt(this.Contract.m.Home))
					{
						if (!this.TempFlags.get("AtHome"))
						{
							this.TempFlags.set("AtHome", true);
							// Once decided, re-arrival re-shows the reward summary, never
							// the choice again (no double-apply).
							this.Contract.setScreen(this.Contract.m.Decided ? "Outcome" : "Decision");
							this.World.Contracts.showActiveContract();
						}
					}
					else
					{
						this.TempFlags.set("AtHome", false);
					}
					return;
				}

				// --- Arrival at the palace: the steward's door (pay or leave) -----
				if (this.Contract.m.Site != null && !this.Contract.m.Site.isNull() && this.Contract.isPlayerAt(this.Contract.m.Site))
				{
					if (!this.TempFlags.get("AtSite"))
					{
						this.TempFlags.set("AtSite", true);
						// Resume-aware: paid & mid-crawl -> current room; Tome in hand -> reveal;
						// otherwise -> the door. (So closing a room and re-entering never re-pays.)
						local scr = "Door";
						if (this.Contract.m.HasTome) scr = "Reveal";
						else if (this.Contract.m.Deck != null) scr = this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]);
						this.Contract.setScreen(scr);
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
				if (_combatID == "AzariCrypt")
				{
					this.Contract.grantCryptTrophy();
					this.Contract.m.CryptWon = true;
				}
			}

			function onRetreatedFromCombat( _combatID )
			{
				if (_combatID == "AzariCrypt")
				{
					this.Contract.m.CryptFled = true;
				}
			}

		});
	}

	// One iconed reward row for the moral-reputation meter (no Legends helper for it;
	// coin and renown use ::Legends.EventList.change*). Applies the change and returns
	// the row for the Outcome List.
	function moralRow( _amount, _label )
	{
		this.World.Assets.addMoralReputation(_amount);
		local col = _amount >= 0 ? this.Const.UI.Color.PositiveEventValue : this.Const.UI.Color.NegativeEventValue;
		local sign = _amount >= 0 ? "+" : "";
		return {
			id = 10,
			icon = "ui/icons/asset_moral_reputation.png",
			text = "[color=" + col + "]" + _label + " (" + sign + _amount + ")[/color]"
		};
	}

	// Mood rows for the PIOUS men (religious backgrounds) -- a dead god's relic stirs
	// them where it leaves others cold. +amount gladdens, -amount troubles. Applies the
	// shift AND returns the "<name> gets eager/troubled" rows (::Legends.EventList.changeMood
	// builds them with the mood-state face icon) to show on the Outcome screen.
	function piousMoodShift( _amount, _reason )
	{
		local rows = [];
		local pious = [
			"background.monk", "background.flagellant", "background.monk_turned_flagellant",
			"background.pacified_flagellant", "background.cultist", "background.converted_cultist",
			"background.legend_pilgrim", "background.legend_battle_sister"
		];
		foreach (bro in this.World.getPlayerRoster().getAll())
		{
			local id = bro.getBackground().getID();
			local isPious = false;
			foreach (p in pious) if (p == id) { isPious = true; break; }
			if (!isPious) continue;
			rows.push(::Legends.EventList.changeMood(bro, _amount, _reason));
		}
		return rows;
	}

	// Mood rows for the CROOKED men -- thieves, killers, grave-robbers and the like.
	// Where the pious are troubled by fencing a god's book, these are quietly pleased by a
	// clean, profitable score with no names attached. Applies the shift AND returns the rows.
	function criminalMoodShift( _amount, _reason )
	{
		local rows = [];
		local crooked = [
			"background.thief", "background.assassin", "background.assassin_southern",
			"background.killer_on_the_run", "background.graverobber", "background.raider",
			"background.poacher"
		];
		foreach (bro in this.World.getPlayerRoster().getAll())
		{
			local id = bro.getBackground().getID();
			local isCrooked = false;
			foreach (c in crooked) if (c == id) { isCrooked = true; break; }
			if (!isCrooked) continue;
			rows.push(::Legends.EventList.changeMood(bro, _amount, _reason));
		}
		return rows;
	}

	// ---- CRAWL (pass 1: lore rooms) --------------------------------------------
	function isPious( _bro )
	{
		local pious = [
			"background.monk", "background.flagellant", "background.monk_turned_flagellant",
			"background.pacified_flagellant", "background.cultist", "background.converted_cultist",
			"background.legend_pilgrim", "background.legend_battle_sister"
		];
		local id = _bro.getBackground().getID();
		foreach (p in pious) if (p == id) return true;
		return false;
	}

	// A random brother reacts to a lore beat. Direction starts from the passage's TONE
	// (+1 uplifting / -1 grim), but TEMPERAMENT overrides: the superstitious / undead-fearing
	// are unsettled regardless; the brave / devout take heart regardless. Returns the mood row.
	function loreMoodRows( _tone, _reason )
	{
		local roster = this.World.getPlayerRoster().getAll();
		if (roster.len() == 0) return [];
		local bro = roster[this.Math.rand(0, roster.len() - 1)];   // a random man reacts (may repeat -- fine)

		// The devout and the brave SHRUG OFF the grim beats -- steadied, not saddened. That
		// only REMOVES the shift; it never turns a bleak reading into a cheerful one. An
		// uplifting beat lifts anyone.
		local dir = _tone;
		local sk = bro.getSkills();
		if (dir < 0 && (this.isPious(bro) || sk.hasSkill("trait.brave") || sk.hasSkill("trait.fearless")))
		{
			return [];   // unmoved -- no shift, no row
		}
		return [ ::Legends.EventList.changeMood(bro, dir, _reason) ];
	}

	// Assemble the run: 3 lore rooms + 2 loot rooms, each drawn from its pool, shuffled
	// together, then the Tome anchor last. (The crypt joins the draw in the next pass.)
	function assembleDeck()
	{
		local lorePool = ["guises", "homily", "roses", "solian", "iomedae", "prophecy"];
		local lootPool = ["shelf", "reliquary", "offering"];
		::MSU.Array.shuffle(lorePool);   // in place -- returns nothing, so do NOT reassign
		::MSU.Array.shuffle(lootPool);
		local deck = [];
		for (local i = 0; i < 3 && i < lorePool.len(); i = i + 1) deck.push(lorePool[i]);
		for (local i = 0; i < 2 && i < lootPool.len(); i = i + 1) deck.push(lootPool[i]);
		::MSU.Array.shuffle(deck);        // in place -- lore and loot interleave
		deck.push("crypt");   // the Ancient Dead crypt -- deepest chamber, just before the Tome
		deck.push("tome");
		return deck;
	}

	// ---- CRYPT (pass 3: the Ancient Dead) --------------------------------------
	// OUR OWN pure-skeleton "spawn list" as a budget menu -- the stock UndeadArmy list leaks
	// vampires and a demon hound, so we roll our own. Costs are the game's own values
	// (spawnlist_master: light 13, medium 20, medium-polearm 25, heavy 35). Row 1 = the back
	// line (polearms reach over the front). rollCryptFight spends a budget across this menu, so
	// the COUNT and the light/medium/heavy MIX scale with the budget -- exactly the native
	// addUnitsToCombat behaviour, but guaranteed skeletons-only.
	function cryptSkeletonMenu()
	{
		return [
			{ Cost = 13, Row = 0, ID = this.Const.EntityType.SkeletonLight,  Script = "scripts/entity/tactical/enemies/skeleton_light" },
			{ Cost = 20, Row = 0, ID = this.Const.EntityType.SkeletonMedium, Script = "scripts/entity/tactical/enemies/skeleton_medium" },
			{ Cost = 25, Row = 1, ID = this.Const.EntityType.SkeletonMedium, Script = "scripts/entity/tactical/enemies/skeleton_medium_polearm" },
			{ Cost = 35, Row = 0, ID = this.Const.EntityType.SkeletonHeavy,  Script = "scripts/entity/tactical/enemies/skeleton_heavy" },
			{ Cost = 40, Row = 1, ID = this.Const.EntityType.SkeletonHeavy,  Script = "scripts/entity/tactical/enemies/skeleton_heavy_polearm" },
		];
	}

	// Spend _budget across the skeleton menu, pushing entity descriptors into _properties.Entities.
	// Draws a random affordable unit each step until the budget can no longer afford the cheapest.
	function rollCryptFight( _properties, _budget )
	{
		local menu = this.cryptSkeletonMenu();
		local faction = this.World.FactionManager.getFactionOfType(this.Const.FactionType.Undead).getID();
		local spent = 0;
		local guard = 0;
		while (spent < _budget && guard < 60)
		{
			guard = guard + 1;
			local pool = [];
			foreach (e in menu) if (e.Cost <= _budget - spent) pool.push(e);
			if (pool.len() == 0) break;
			local e = pool[this.Math.rand(0, pool.len() - 1)];
			_properties.Entities.push({
				ID = e.ID,
				Variant = 0,
				Row = e.Row,
				Script = e.Script,
				Faction = faction
			});
			spent = spent + e.Cost;
		}

		// A SMALL chance of an Ancient Dead CHAMPION on top -- a barrow-lord heavy skeleton
		// (makeMiniboss: champion_racial buff, a NAMED undead weapon that can drop, the champion
		// bust). A rare, nastier fight and a loot hook. makeMiniboss no-ops without the Wildmen DLC.
		if (this.Math.rand(1, 100) <= 15)
		{
			_properties.Entities.push({
				ID = this.Const.EntityType.SkeletonHeavy,
				Variant = 0,
				Row = 0,
				Script = "scripts/entity/tactical/enemies/skeleton_heavy",
				Faction = faction,
				Callback = this.onCryptChampionPlaced.bindenv(this)
			});
		}
	}

	// Placement callback for the crypt champion: promote it to a miniboss and give it an
	// Ancient Dead name. Runs when the entity is placed on the tactical map.
	function onCryptChampionPlaced( _entity, _tag )
	{
		_entity.makeMiniboss();
		local names = this.Const.Strings.AncientDeadNames;
		_entity.setName(names[this.Math.rand(0, names.len() - 1)]);
	}

	// Lockpick ladder for the crypt door -- criminals and grave-robbers do best; anyone else fumbles.
	function pickLockLadder()
	{
		return [
			["background.thief", 75], ["background.graverobber", 65],
			["background.assassin", 55], ["background.assassin_southern", 55],
			["background.killer_on_the_run", 50], ["background.poacher", 45],
			["background.vagabond", 42], ["background.sellsword", 35]
		];
	}

	// The company's blessed water, if any -- for the rite. Handles the vanilla ID ("weapon.holy Water")
	// and the Legends ID ("weapon.holy_water"). Returns the stash item or null.
	function findHolyWater()
	{
		foreach (it in ::World.Assets.getStash().getItems())
		{
			if (it == null) continue;
			local id = it.getID();
			if (id == "weapon.holy Water" || id == "weapon.holy_water") return it;
		}
		return null;
	}

	// Build + start the crypt fight. TEST CONFIG: a LOW budget base (easy) rolled over our own
	// skeleton menu. A screen getResult MAY start a scripted combat and return 0
	// (legend_hunting_stollwurms does exactly this). Victory -> Running.onCombatVictory.
	function startCryptFight()
	{
		local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
		p.CombatID = "AzariCrypt";
		// Force a ruined-stone tactical map (a crypt vault), not the palace's surface terrain
		// (which read as a snowfield in testing). LocationTemplate = the built structure placed
		// on a neutral ground; recipe from slave_uprising / conquer_holy_site.
		p.Tile = this.World.State.getPlayer().getTile();
		p.TerrainTemplate = "tactical.plains";
		p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
		p.LocationTemplate.Template[0] = "tactical.ruins";
		p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.None;
		// Budget-based skeleton mix from OUR OWN menu (rollCryptFight). Budget scales with company
		// strength (getScaledDifficultyMult), so the fight stays proportionate; a LOW base keeps this
		// TEST easy. For the real fight, raise BASE (and multiply by getDifficultyMult too).
		local budgetBase = 117;   // "medium+" tier (game standard fight is 100-110); tune here.
		local budget = (budgetBase * this.getScaledDifficultyMult()).tointeger();
		if (this.m.CryptForced) budget = (budget * 1.3).tointeger();   // forced the door -> the din rouses more dead
		if (budget < 26) budget = 26;   // never an empty crypt
		this.rollCryptFight(p, budget);
		this.World.Contracts.startScriptedCombat(p, true, true, true);
	}

	// Grant the crypt trophy -- ONE of {bardiche (weapon stand), plate-chest layer (armour stand)}
	// at random, NO moral hit (the dead's own arms, not the shrine's silver). Records m.CryptTrophy
	// for the exit buy-back and builds the CryptResult rows/text. Called from onCombatVictory so the
	// grant is atomic with the win.
	function grantCryptTrophy()
	{
		local path; local line;
		if (this.Math.rand(0, 1) == 0)
		{
			this.m.CryptTrophy = "bardiche";
			path = "scripts/items/weapons/bardiche";
			line = "Among the fallen, a bardiche still stands on its rack -- a two-handed axe-blade on a long haft, the honour-arm of some ancient guard, and the edge has not so much as dulled.";
		}
		else
		{
			this.m.CryptTrophy = "plate";
			path = "scripts/items/legend_armor/plate/legend_armor_plate_chest";
			line = "Among the fallen, a breastplate rests on a stand -- a heavy plated cuirass, the honour-armour of some ancient guard, and still sound under the dust.";
		}
		this.m.RoomRows = ::Skv.Loot.haul(::Skv.Loot.make([path]), 0);
		this.m.RoomText = "[img]gfx/ui/events/event_98.png[/img]{The dead lie still again. " + line + " You take it, and turn back for the halls above.}";
	}

	function roomScreenFor( _key )
	{
		if (_key == "tome") return "TomeRoom";
		if (_key == "crypt") return "CryptDoor";
		local d = this.roomData(_key);
		return d.type == "loot" ? "LootRoom" : "LoreRoom";
	}

	function advance()
	{
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return this.roomScreenFor(this.m.Deck[this.m.CrawlIndex]);
	}

	// Resolve the current room: stash its result rows + narrative, ADVANCE THE INDEX (so the
	// card can never be re-run on a re-enter or reload -- no double loot, no re-read), and route
	// to RoomResult, whose "continue" then shows whatever card the index now points at.
	function resolveRoom( _rows, _text )
	{
		this.m.RoomRows = _rows;
		this.m.RoomText = _text;
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return "RoomResult";
	}

	// The moral cost of robbing a shrine: applies -1..-10 moral reputation and returns the iconed
	// row. A contract method so the RNG runs on the contract's `this` (not a screen handler's).
	function robMoralRow( _reason )
	{
		return this.moralRow(-this.Math.rand(1, 6), _reason);
	}

	// The palace's small wealth, by tier. T1 = a devotional shelf / offering table; T2 = the
	// reliquary / sacristy. (T3 -- the crypt chest -- lands with the crypt.) Entry shapes:
	// { W=weight, T=tier, Path="..." } | { W, T, Gold=[min,max] } | add Stack=n for a bundle.
	function azariLoot()
	{
		return [
			// pilgrims' coin and the small silver of a temple that stopped counting it (T1)
			{ W = 24, T = 1, Gold = [50, 150] },
			{ W = 16, T = 1, Path = "scripts/items/loot/bead_necklace_item" },   // 250
			{ W = 14, T = 1, Path = "scripts/items/loot/signet_ring_item" },     // 245
			{ W = 14, T = 1, Path = "scripts/items/loot/silverware_item" },      // 350
			{ W = 12, T = 1, Path = "scripts/items/loot/silver_bowl_item" },     // 490
			{ W = 8,  T = 1, Path = "scripts/items/trade/legend_wax_item", Stack = 5 }, // votive wax, a bundle (~165)
			// the reliquary's better offerings (T2)
			{ W = 14, T = 2, Gold = [150, 400] },
			{ W = 12, T = 2, Path = "scripts/items/loot/jade_broche_item" },     // 400
			{ W = 11, T = 2, Path = "scripts/items/trade/incense_item" },        // 380
			{ W = 10, T = 2, Path = "scripts/items/loot/ancient_amber_item" },   // 500
			{ W = 9,  T = 2, Path = "scripts/items/loot/ornate_tome_item" },     // lesser liturgy, NOT the objective (595)
			{ W = 8,  T = 2, Path = "scripts/items/loot/marble_bust_item" },     // 600
		];
	}

	// Roll _n entries (tier <= _maxTier) and RETURN { paths, coin } for ::Skv.Loot to grant +
	// render as iconed reward rows. No guaranteed base coin -- palace loot is optional theft, not
	// the core reward. A Stack entry pushes its path n times (haul() groups it as "Nx").
	function rollAzariLoot( _n, _maxTier )
	{
		local paths = [];
		local coin = 0;
		local table = this.azariLoot();
		for (local i = 0; i < _n; i = i + 1)
		{
			local pool = [];
			local total = 0;
			foreach (e in table) if (e.T <= _maxTier) { pool.push(e); total = total + e.W; }
			if (total <= 0) break;
			local r = this.Math.rand(1, total);
			local pick = null;
			foreach (e in pool) { r = r - e.W; if (r <= 0) { pick = e; break; } }
			if (pick == null) continue;
			if ("Gold" in pick) coin = coin + this.Math.rand(pick.Gold[0], pick.Gold[1]);
			else { local q = ("Stack" in pick) ? pick.Stack : 1; for (local k = 0; k < q; k = k + 1) paths.push(pick.Path); }
		}
		return { paths = paths, coin = coin };
	}

	// Room content cards. `desc` = the neutral first-page description (what you SEE -- no tone
	// tell). `readText` = the second-page reveal (what you READ), which carries the tone.
	// `tone` +1 uplifting / -1 grim. Loot cards carry `tier`/`draws` and a `take`/`takeText`
	// instead, and are robbed for an iconed haul at a moral cost (see the LootRoom screen).
	function roomData( _key )
	{
		switch (_key)
		{
			case "guises":
				return { type = "lore", tone = 1.0, image = "event_15", title = "The Fresco",
					desc = "A fresco covers one wall, half its plaster fallen away -- a dozen figures in a dozen kinds of dress, and a line of old Taldane script running beneath them.",
					read = "{Read the inscription.}",
					readText = "The figures are one man in twelve forms -- beggar, smith, thief, scholar, shepherd, soldier, and six more worn past knowing. They are all %SKVNAME%Aroden%SKVNAME_OFF%, the script says: the god who was born a mortal man and made himself divine, and who walked the world in each of these guises in turn, to learn what men were by being one of them. He raised the first cities and set down the first letters -- and he did it having been hungry, having been cold, having been afraid. There is more god in that, someone murmurs, than in most temples the company has stood in.",
					reason = "The god who walked as one of us" };
			case "homily":
				return { type = "lore", tone = 1.0, image = "event_15", title = "A Leaf of Brass",
					desc = "A single leaf of brass has been prised from some book and nailed to the wall at chest height, kept long after whatever it came from was lost.",
					read = "{Read the leaf.}",
					readText = "It is a line %SKVNAME%Aroden%SKVNAME_OFF% is said to have spoken with his own mouth, in the years before he was any god at all: that even gods can die -- that his own gods had died before him -- and that men go on regardless, building and mending and burying their dead, and that the going-on is itself the holy thing. Whoever prised this one leaf loose and nailed it to the wall wanted that single line to outlast all the brass it came from. On this wall, at least, it has.",
					reason = "Gods can die; men endure" };
			case "roses":
				return { type = "lore", tone = 1.0, image = "event_16", title = "A Faded Mural",
					desc = "A mural, its colours gone soft with age: a field of flowers, and a robed figure walking through them. The paint is old, but oddly clean in places.",
					read = "{Look closer.}",
					readText = "The flowers are roses -- red, but fully half of them gone white, and the white paint has never once cracked or yellowed while all the rest has faded. Where %SKVNAME%Aroden%SKVNAME_OFF% walked, the tale beneath it runs, the red roses turned pale as he passed, and stayed so after. Whether a painter's trick or something older, someone has kept this one mural dusted clean while the whole hall around it goes to grey -- a small tended wonder, on a wall that no one comes to see.",
					reason = "A small wonder the god left behind" };
			case "solian":
				return { type = "lore", tone = -1.0, image = "event_57", title = "A Niche in the Wall",
					desc = "A niche in the stone holds an effigy, its hands folded on its breast, a name cut worn into the base.",
					read = "{Read the name.}",
					readText = "The name is %SKVNAME%Solian%SKVNAME_OFF% -- a saint, and of the %SKVLOC%Azari%SKVLOC_OFF%'s own blood, raised to sainthood in the days when this house led the god's church and three of its sons wore the halo. The dust on his folded stone hands lies a full inch deep; the little iron cup at his feet holds nothing but grey. No flame has burned in this niche in a very long time, and no one now living remembers to light one. A saint of the house -- and not a soul left to mourn him.",
					reason = "A saint no one comes to mourn" };
			case "iomedae":
				return { type = "lore", tone = -1.0, image = "event_63", title = "An Open Ledger",
					desc = "A great ledger lies open on a lectern, page after page of names set down in a careful, practised hand.",
					read = "{Read the ledger.}",
					readText = "They are the clergy of this temple, name under name, back and back through the centuries -- and most are struck through, each with the same two words inked beside it in a later hand: gone to %SKVNAME%the Inheritor%SKVNAME_OFF%. When %SKVNAME%Aroden%SKVNAME_OFF% died his priests did not merely scatter; they crossed to %SKVNAME%Iomedae%SKVNAME_OFF%, the knight-goddess who took up his work, and walked out of this house and into hers. The faith rose and left, all but bodily, and set the ledgers down on its way out. What stayed behind was the dust -- and the few who could not bring themselves to go.",
					reason = "A faith that emptied into another's" };
			case "prophecy":
				return { type = "lore", tone = -1.0, image = "event_178", title = "Carved Above the Door",
					desc = "Words are cut into the lintel above a doorway in tall old letters -- and beneath them, smaller, something added by a later hand.",
					read = "{Read it through.}",
					readText = "The tall words are old and sure: they promise an Age of Glory to dawn on the day of %SKVNAME%Aroden%SKVNAME_OFF%'s foretold return. The small ones, cut by some later hand that had lived to see it, give the date he died on instead -- the very day he was prophesied to come back in triumph. He never came. The prophecy broke, and they say every oracle and every omen in the world went dark in that same hour and has stayed dark since. Someone stood here with a chisel and made certain the two lines would forever have to be read together.",
					reason = "The day the omens died" };
			case "shelf":
				return { type = "loot", tier = 1, draws = 2, image = "event_01", title = "A Devotional Shelf",
					desc = "A long shelf runs the length of the wall, crowded with the small wealth of a temple that long ago stopped spending it -- votive silver, a censer or two, rings left by pilgrims, all of it furred grey with dust. No one has counted it in years.",
					take = "{Take what will fit in a pack.}",
					takeText = "You sweep what you can carry into your packs. It is the offering-silver of a shrine, and you are leaving no offering in its place -- and every man here knows the difference, whatever the coin turns out to be worth.",
					reason = "Robbed a shrine" };
			case "reliquary":
				return { type = "loot", tier = 2, draws = 2, image = "event_182", title = "The Reliquary",
					desc = "A side-chapel, its aumbry standing open: the reliquary of the house. Gilt boxes, an amber lamp, a bust in old marble, a book of lesser liturgy -- the kept offerings of centuries, set out for a faith that no longer comes to look at them.",
					take = "{Help yourselves to the reliquary.}",
					takeText = "You lift the best of it out of the open aumbry -- the gilt, the amber, the old marble. Relics of a dead god's house, going now into a sellsword's pack. Not a thing any of you will say aloud on the road home.",
					reason = "Stripped a reliquary" };
			case "offering":
				return { type = "loot", tier = 1, draws = 2, image = "event_62", title = "The Offering Table",
					desc = "An offering table stands before a worn image of the god, its bowl heaped with the coin of the last of the faithful -- crowns gone green, a few brighter pieces among them, left for a god who will never spend them.",
					take = "{Empty the offering bowl.}",
					takeText = "You tip the offering bowl into a purse. The god it was left for is a long time dead and past minding -- which is the sort of thing a man tells himself while his hands are busy.",
					reason = "Took the offerings" };
		}
		return null;
	}

	// Leave the palace and head home to decide the Tome's fate -- shared by the Reveal and the crypt
	// buy-back. Flips the report leg on, removes the site, repoints the objective home.
	function departForHome()
	{
		this.m.SiteCleared = true;
		if (!::MSU.isNull(this.m.Site)) this.m.Site.die();
		this.m.Site = null;
		this.m.BulletpointsObjectives = [
			"Return to " + this.m.Home.getName() + " and decide the Tome's fate"
		];
		if (this.m.Home != null && !this.m.Home.isNull())
		{
			this.m.Home.getSprite("selection").Visible = true;
		}
	}

	// The buy-back item: the COUNTERPART of the trophy taken in the crypt. { path, label } or null.
	function cryptCounterpart()
	{
		if (this.m.CryptTrophy == "bardiche")
			return { path = "scripts/items/legend_armor/plate/legend_armor_plate_chest", label = "a heavy plated cuirass" };
		if (this.m.CryptTrophy == "plate")
			return { path = "scripts/items/weapons/bardiche", label = "a long bardiche" };
		return null;
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		// --- TASK: the smuggler's plea. Employer hidden; a hand-named stranger owns
		// the screen. Note the PLANTED DETAIL (the pale scar) -- the reveal echoes it.
		this.m.Screens.push({
			ID = "Task",
			Title = "The Azari Commission",
			Text = "[img]gfx/ui/events/event_76.png[/img]{A hooded man finds you where the light is poor. A pale scar splits one eyebrow; he keeps that side to the wall. %SPEECH_ON%There is a house called the Azari -- old blood, no coin, keepers of a temple to a god who died and took their fortune with him. They let paying folk walk their relic-halls now; it is the only trade they have left. Somewhere in that dust is a book. Brass covers. A Tome of Memory, the priests called it. I want it. Pay the door like any other visitor, take it quietly, bring it to me. Half now, the rest when I have it in my hands.%SPEECH_OFF% He does not say why, and you do not ask.}",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We can be discreet. We will bring you your book.}",
						function getResult() { return "Negotiation"; }
					}
				];

				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{A Tome of Memory. Does that mean anything to anyone?}",
						function getResult() { return "Lore"; }
					});
				}

				this.Options.push({
					Text = "{Find another company.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);   // pre-accept decline -> not retired
						return 0;
					}
				});
			}
		});

		// --- LORE: two brothers on the Tome of Memory and the dead god Aroden.
		this.m.Screens.push({
			ID = "Lore",
			Title = "A Tome of Memory",
			Text = "[img]gfx/ui/events/event_15.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% turns the name over. %SPEECH_ON%Tomes of Memory. The old church of %SKVNAME%Aroden%SKVNAME_OFF% kept them -- brass on the covers, the god's own sayings inside, every temple with at least the one. And on the blank leaves at the back the priests wrote down their own house: its history, its dead, whatever the place was hiding. When the god died the churches emptied and the Tomes walked off with them. Most were never seen again.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% frowns. %SPEECH_ON%A god died?%SPEECH_OFF%%SKVNAME%%randombrother%%SKVNAME_OFF% nods. %SPEECH_ON%%SKVNAME%Aroden%SKVNAME_OFF%. God of men -- cities, letters, the whole notion of getting better at things. Dropped dead on the day he was prophesied to return, and nobody has ever said why. The families that carried his church went down with him. This %SKVLOC%Azari%SKVLOC_OFF% lot are the last of one of them, sweeping a temple nobody comes to.%SPEECH_OFF% He shrugs. %SPEECH_ON%And now a scarred man in a hood wants their book, and will not say why. Make of that what you will.%SPEECH_OFF%}",
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

		// --- DOOR: the steward. Pay the fee or turn back. (No back door.)
		this.m.Screens.push({
			ID = "Door",
			Title = "The Steward's Door",
			Text = "[img]gfx/ui/events/event_183.png[/img]{The %SKVLOC%Azari Palace%SKVLOC_OFF% is a temple gone grey -- a beautiful thing, dust an inch thick on its beauty. An old steward keeps the door with a ledger and a strongbox. %SPEECH_ON%The house welcomes visitors. There is a fee. His lordship must keep the roof on somehow.%SPEECH_OFF% He names a figure -- steep, for a look at some old relics -- and waits, unbothered, for your answer.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [];
				if (this.World.Assets.getMoney() >= this.Contract.m.Fee)
				{
					this.Options.push({
						Text = "{Pay the steward his fee. (620 crowns)}",
						function getResult()
						{
							this.World.Assets.addMoney(-this.Contract.m.Fee);
							this.Contract.m.Deck = this.Contract.assembleDeck();
							this.Contract.m.CrawlIndex = 0;
							return this.Contract.roomScreenFor(this.Contract.m.Deck[0]);
						}
					});
				}
				else
				{
					this.Options.push({
						Text = "{[We cannot spare the fee just now.]}",
						function getResult() { return 0; }
					});
				}
				this.Options.push({
					Text = "{Not yet.}",
					function getResult() { return 0; }
				});
			}
		});

		// --- LORE ROOM: read a beat of the temple's history -> a brother's mood moves.
		// One screen, driven by the current card's data (roomData). Read -> RoomResult;
		// press on -> next card.
		this.m.Screens.push({
			ID = "LoreRoom",
			Title = "The Relic-Halls",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local d = this.Contract.roomData(this.Contract.m.Deck[this.Contract.m.CrawlIndex]);
				this.Title = d.title;
				this.Text = "[img]gfx/ui/events/" + d.image + ".png[/img]{" + d.desc + "}";
				this.Options = [
					{
						Text = d.read,
						function getResult()
						{
							// SECOND PAGE (RoomResult): the reveal itself -- what you read --
							// carries the tone, and the mood row (if any) shows the effect.
							local dd = this.Contract.roomData(this.Contract.m.Deck[this.Contract.m.CrawlIndex]);
							local rows = this.Contract.loreMoodRows(dd.tone, dd.reason);
							return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/" + dd.image + ".png[/img]{" + dd.readText + "}");
						}
					},
					{
						Text = "{Leave it, and press on into the dark.}",
						function getResult() { return this.Contract.advance(); }
					}
				];
			}
		});

		// --- LOOT ROOM: rob a shelf / reliquary / offering table for an iconed haul at a moral
		// cost. Two-page like the lore rooms: page 1 = what is here (a neutral description + the
		// telegraph that this is a shrine); take -> roll the haul + a random moral hit, resolve to
		// RoomResult; leave -> press on, nothing taken.
		this.m.Screens.push({
			ID = "LootRoom",
			Title = "The Relic-Halls",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local d = this.Contract.roomData(this.Contract.m.Deck[this.Contract.m.CrawlIndex]);
				this.Title = d.title;
				this.Text = "[img]gfx/ui/events/" + d.image + ".png[/img]{" + d.desc + "}";
				this.Options = [
					{
						Text = d.take,
						function getResult()
						{
							// Grant the haul (items to stash + coin) as iconed rows, then bundle in the
							// shrine-robbing moral hit (rand 1-10). resolveRoom advances the index so this
							// room can never be looted twice on a re-enter.
							local dd = this.Contract.roomData(this.Contract.m.Deck[this.Contract.m.CrawlIndex]);
							local roll = this.Contract.rollAzariLoot(dd.draws, dd.tier);
							local rows = ::Skv.Loot.haul(::Skv.Loot.make(roll.paths), roll.coin);
							rows.push(this.Contract.robMoralRow(dd.reason));
							return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/" + dd.image + ".png[/img]{" + dd.takeText + "}");
						}
					},
					{
						Text = "{Leave it. We came for one thing.}",
						function getResult() { return this.Contract.advance(); }
					}
				];
			}
		});

		// --- ROOM RESULT: shows what a room's action did (a mood row now; a loot haul once
		// loot rooms land), then continues the crawl.
		this.m.Screens.push({
			ID = "RoomResult",
			Title = "The Relic-Halls",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On, then.}",
					// The room that led here ALREADY advanced the index (resolveRoom); just show whatever
					// card the index now points at. Never advance() here, or we would skip a room.
					function getResult() { return this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]); }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You move on.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		// --- CRYPT PICKED: the quiet way in. A short story beat that shows the pick's XP (set on
		// m.RoomRows/RoomText by the CryptDoor pick success), then descends to the crypt fight.
		this.m.Screens.push({
			ID = "CryptPicked",
			Title = "The Gate Gives",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Down, then -- quietly.}",
					function getResult() { return "CryptFight"; }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{The gate gives.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		// --- CRYPT DOOR: a way down is found, but the door is LOCKED. Pick it (a check -- criminals /
		// grave-robbers best; quiet -> normal fight), FORCE it (always works, but the din rouses more
		// dead -> a bigger fight, m.CryptForced), or leave it sealed. A failed pick leaves only force/leave.
		this.m.Screens.push({
			ID = "CryptDoor",
			Title = "The Locked Door",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				if (this.Contract.m.CryptPickFailed)
					this.Text = "[img]gfx/ui/events/event_89.png[/img]{The lock has beaten you -- too old, too rusted, or too clever by half. The iron door holds. There is the hard way now, or there is the book you came for.}";
				else
					this.Text = "[img]gfx/ui/events/event_89.png[/img]{A cold draught crosses the hall from a blank stretch of wall, and %SKVNAME%%randombrother%%SKVNAME_OFF% finds the seam of a hidden door. It gives inward on a low iron gate -- and beyond it, steps going down into the dark, and the dry, sweetish smell of a crypt long shut. The %SKVLOC%Azari%SKVLOC_OFF% laid their honoured dead below, the ledgers said, and their arms beside them. The gate is locked.}";

				this.Options = [];
				if (!this.Contract.m.CryptPickFailed)
				{
					this.Options.push({
						Text = "{Pick the lock. Quietly.}",
						function getResult()
						{
							local r = ::Skv.Check.lockpick(this.Contract, ::Skv.Check.scaledBase(this.Contract, 40));
							if (r.ok)
							{
								// A clean, quiet pick -> a short story beat (CryptPicked) that carries
								// the XP for the man who worked the lock, then down into the crypt.
								this.Contract.m.RoomRows = (r.actor != null && ("XP" in ::Skv)) ? ::Skv.XP.grant(r.actor, 200) : [];
								this.Contract.m.RoomText = "[img]gfx/ui/events/event_89.png[/img]{%SKVNAME%" + this.Contract.m.ActorName + "%SKVNAME_OFF% kneels to the old iron and works it the way a good thief works anything -- patient, listening, feeling for the give. The %SKVLOC%Azari%SKVLOC_OFF% built even the locks on their tombs to outlast the men who made them, and this one argues back through a dozen dead men's rust. Then something deep in it turns over, soft as a sigh, and the gate swings inward without a sound. Whatever keeps the dead down here will not hear you come. He rocks back on his heels, quietly pleased, and a shade the wiser for it.}";
								return "CryptPicked";
							}
							this.Contract.m.CryptPickFailed = true;
							return "CryptDoor";
						}
					});
				}
				this.Options.push({
					Text = "{Force it. Shoulders and a pry-bar.}",
					function getResult()
					{
						this.Contract.m.CryptForced = true;
						return "CryptFight";
					}
				});
				this.Options.push({
					Text = "{Leave it sealed. We came for the book, not the dead.}",
					function getResult() { return this.Contract.advance(); }
				});
			}
		});

		// --- CRYPT FIGHT: the two-brother argument, then descend -> scripted combat. TEST CONFIG:
		// startCryptFight spawns three light skeletons (very easy). Victory -> onCombatVictory ->
		// CryptResult; retreat -> the crypt is skipped (no trophy).
		this.m.Screens.push({
			ID = "CryptFight",
			Title = "The Ancient Dead",
			Text = "[img]gfx/ui/events/event_73.png[/img]{The stair gives onto a low vault of niches and dust -- and racks of old arms that ought to be red rust by now, and are not. %SKVNAME%%randombrother%%SKVNAME_OFF% is down them first, reaching. %SPEECH_ON%Would you look at that. Good steel, every rack of it, and not a soul to say no. We could carry a fortune up those steps.%SPEECH_OFF% %SKVNAME%%randombrother2%%SKVNAME_OFF% catches his wrist. %SPEECH_ON%Leave it. Nobody keeps a dead man's blade bright for three hundred years -- so ask yourself who has been down here tending them, and step careful.%SPEECH_OFF% %SKVNAME%%randombrother%%SKVNAME_OFF% only laughs, and lifts a sword from its hook. In the dark of the niche behind him, something that has lain still a very long time turns its head.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Blades out. Put them back down.}",
						function getResult()
						{
							this.Contract.startCryptFight();
							return 0;
						}
					},
					{
						Text = "{Grab him and back up the stair -- this is not our fight.}",
						function getResult() { return this.Contract.advance(); }
					}
				];
			}
		});

		// --- CRYPT RESULT: the trophy (bardiche | plate-chest), shown after victory. Continue
		// resumes the crawl at whatever card the index now points at (the crypt was consumed).
		this.m.Screens.push({
			ID = "CryptResult",
			Title = "The Ancient Dead",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Take it, and back to the halls above.}",
					function getResult()
					{
						// If the company carries blessed water, offer the rite; otherwise on to the next card.
						if (this.Contract.findHolyWater() != null) return "CryptRite";
						return this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]);
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{The dead lie still, and you take what they no longer need.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		// --- CRYPT RITE (only reached if the company carries blessed water): OPTIONAL. Lay the ancient
		// dead to rest -> +moral + pious mood, consume one flask; or keep the water. Routes on via RoomResult.
		this.m.Screens.push({
			ID = "CryptRite",
			Title = "The Ancient Dead",
			Text = "[img]gfx/ui/events/event_116.png[/img]{The vault is still again, the dead scattered where they fell. %SKVNAME%%randombrother%%SKVNAME_OFF% turns a flask of blessed water over in his hand. A few words said over them, a sprinkle, and these old servants might lie easier -- and so might the men who had to put them down a second time. But blessed water is dear, and hard come by.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Say the words, and lay them to rest. (uses a Flask of Blessed Water)}",
						function getResult()
						{
							local water = this.Contract.findHolyWater();
							if (water != null) this.World.Assets.getStash().remove(water);
							local rows = [];
							rows.push(this.Contract.moralRow(3, "Laid the ancient dead to rest"));
							rows.extend(this.Contract.piousMoodShift(1.0, "We gave the old dead their rest"));
							this.Contract.m.RoomRows = rows;
							this.Contract.m.RoomText = "[img]gfx/ui/events/event_116.png[/img]{The water is said over them and scattered, and something in the close air of the vault eases. Whatever these were, they were somebody's honoured dead once. The company climbs back toward the light a little quieter than it came down.}";
							return "RoomResult";
						}
					},
					{
						Text = "{Keep the water. They are past our caring now.}",
						function getResult() { return this.Contract.roomScreenFor(this.Contract.m.Deck[this.Contract.m.CrawlIndex]); }
					}
				];
			}
		});

		// --- TOME ROOM: the final anchor -- find the Tome, then out to the reveal.
		this.m.Screens.push({
			ID = "TomeRoom",
			Title = "The Innermost Room",
			Text = "[img]gfx/ui/events/event_98.png[/img]{Chamber gives onto chamber, and the dust deepens with each. At the last, on a lectern in a deep and silent room, a book waits under a skin of grey: brass covers, clasps gone green. The %SKVLOC%Tome of Memory%SKVLOC_OFF% of %SKVLOC%Saint Solian Temple%SKVLOC_OFF% -- its back leaves close-written in a dead clergy's hand with the history and the secrets of a house that is nearly gone. You take it, and it is lighter than it looks.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Take it, and out the way we came.}",
					function getResult()
					{
						this.Contract.m.HasTome = true;
						return "Reveal";
					}
				}
			],
			function start()
			{
			}

		});

		// --- REVEAL: the steward, on the way out, unknowingly names the employer.
		this.m.Screens.push({
			ID = "Reveal",
			Title = "The Second Buyer",
			Text = "[img]gfx/ui/events/event_184.png[/img]{The steward lets you out with a nod, and a word. %SPEECH_ON%You are the second this season to come asking after our old books. The first offered coin -- a great deal of it -- but his lordship would not sell to him, and would not say why. A hooded sort. Scar through the eyebrow, kept the bad side to the wall. Odd man.%SPEECH_OFF% Behind you %SKVNAME%%randombrother%%SKVNAME_OFF% goes very still. %SPEECH_ON%That is the man who hired us. Word for word. The scar and all.%SPEECH_OFF% So the house already refused your employer -- and you have just carried out the door what he could not buy.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{So that is who we work for. Home, then -- we have a choice to make.}",
					function getResult()
					{
						// A crypt trophy in the pack -> the steward hawks its counterpart heirloom; else straight home.
						if (this.Contract.m.CryptTrophy != "") return "CryptBuyback";
						this.Contract.departForHome();
						return 0;
					}
				}
			],
			function start()
			{
			}

		});

		// --- CRYPT BUY-BACK (only if a crypt trophy was taken): the steward makes his last sale, offering
		// the house's matching honour-guard heirloom -- the counterpart of what you looted below -- for 2500.
		// A fair retail markup (worth equipping, a loss to flip). Buy or decline, then home.
		this.m.Screens.push({
			ID = "CryptBuyback",
			Title = "The Steward's Last Sale",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local cp = this.Contract.cryptCounterpart();
				this.Text = "[img]gfx/ui/events/event_183.png[/img]{As you turn to go, the old steward clears his throat. %SPEECH_ON%A moment. The house has little left to sell, but what it has is good -- honour-guard pieces, from when the %SKVLOC%Azari%SKVLOC_OFF% kept a guard worth the name.%SPEECH_OFF% He brings out " + cp.label + ", oiled and sound despite the years, and names his price: two thousand five hundred crowns. Steep -- but its like is not made any more, and he will not haggle.}";
				this.Options = [];
				if (this.World.Assets.getMoney() >= 2500)
				{
					this.Options.push({
						Text = "{Buy it. (2500 crowns)}",
						function getResult()
						{
							local cp = this.Contract.cryptCounterpart();
							local items = ::Skv.Loot.make([cp.path]);
							if (items.len() > 0)   // only charge if the item actually created
							{
								this.World.Assets.addMoney(-2500);
								::Skv.Loot.haul(items, 0);   // to the stash (expands if needed)
							}
							this.Contract.departForHome();
							return 0;
						}
					});
				}
				this.Options.push({
					Text = "{No. The one we already have will do.}",
					function getResult()
					{
						this.Contract.departForHome();
						return 0;
					}
				});
			}
		});

		// --- DECISION: the four endings. Each applies its outcome via the Legends
		// reward helpers (which return an iconed row), records the row list + a short
		// narrative, marks Decided, and routes to Outcome. Fence is black-market-gated.
		this.m.Screens.push({
			ID = "Decision",
			Title = "The Tome's Fate",
			Text = "[img]gfx/ui/events/event_62.png[/img]{Back in %SKVLOC%%townname%%SKVLOC_OFF%, the brass-bound Tome sits on the table between you. Somewhere a scarred man in a hood is waiting for it -- a man the %SKVLOC%Azari%SKVLOC_OFF% would not sell to, for a reason he would not give. The pay is real either way. The question is what leaves this room, and in whose hands.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [];

				// 1. Hand it to the agent -- full pay, but you feed a dead god's book
				//    to whatever he serves.
				this.Options.push({
					Text = "{Give the man his book. Take the rest of the pay.}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeMoney(this.Contract.m.Payment.getOnCompletion()));
						rows.push(this.Contract.moralRow(-8, "A darker name"));
						rows.extend(this.Contract.piousMoodShift(-1.0, "We gave a relic of Aroden to worse men"));
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_62.png[/img]{You set the Tome in the scarred man's hands. He counts out the balance and is gone into the dark. Coin spends the same, whatever the book was worth to a temple -- but carrying a dead god's relic to men like him is not the sort of work that goes unremembered.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});

				// 2. Donate to a local temple -- half the fee, but renown and standing.
				this.Options.push({
					Text = "{This belongs in a temple, not a smuggler's crate.}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeMoney((this.Contract.m.Payment.getOnCompletion() * 0.5).tointeger()));
						rows.push(::Legends.EventList.changeRenown(30));
						rows.push(this.Contract.moralRow(8, "A name for honour"));
						rows.extend(this.Contract.piousMoodShift(1.0, "A relic of Aroden left in holy hands"));
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Gave the Azari Tome to a temple");
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_85.png[/img]{You carry the Tome to a temple in %SKVLOC%%townname%%SKVLOC_OFF% and leave it with the clergy, who thank you and press what little coin they can spare into your hands. It is less than the smuggler would have paid -- but word of the deed travels well, and the town thinks the better of you.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});

				// 3. Fence it -- only where there is a black market to fence it in.
				if (this.Contract.m.Home != null && !this.Contract.m.Home.isNull() && this.Contract.m.Home.hasBuilding("building.blackmarket"))
				{
					this.Options.push({
						Text = "{Sell it on the quiet market. No names, no god.}",
						function getResult()
						{
							local rows = [];
							rows.push(::Legends.EventList.changeMoney(1200));
							rows.push(this.Contract.moralRow(-3, "A shade on your name"));
							rows.extend(this.Contract.piousMoodShift(-1.0, "A god's book, sold like stolen tin"));
							rows.extend(this.Contract.criminalMoodShift(1.0, "A clean, quiet sale -- no names, no god"));
							this.Contract.m.OutcomeRows = rows;
							this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_04.png[/img]{The quiet market asks no questions and pays in clipped coin. The Tome vanishes into a crate bound for nowhere you will hear of again -- though a dead god's book, sold like stolen tin, sits a little heavy.}";
							this.Contract.m.Decided = true;
							return "Outcome";
						}
					});
				}

				// 4. Refuse the agent -- courier it back to the Azari where it belongs.
				this.Options.push({
					Text = "{He lied to us. Send it back to the Azari by courier.}",
					function getResult()
					{
						local rows = [];
						rows.push(::Legends.EventList.changeRenown(15));
						rows.push(this.Contract.moralRow(10, "A name for honour"));
						rows.extend(this.Contract.piousMoodShift(1.0, "A relic of Aroden sent home to its keepers"));
						this.Contract.m.OutcomeRows = rows;
						this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_183.png[/img]{You hire a courier and send the Tome back the way it came, to the house that would not sell it. No coin comes of it beyond the advance already in your purse -- but a company that returns a dead god's relic to its keepers is a company men speak well of. The scarred man will not thank you.}";
						this.Contract.m.Decided = true;
						return "Outcome";
					}
				});
			}
		});

		// --- OUTCOME: narrative + the iconed reward list, then finishes.
		this.m.Screens.push({
			ID = "Outcome",
			Title = "The Tome's Fate",
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
				// Rebuilt each show; falls back if a mid-Outcome save dropped the data.
				this.Text = this.Contract.m.OutcomeText != "" ? this.Contract.m.OutcomeText : "{The thing is done, and what was given cannot be called back.}";
				this.List = this.Contract.m.OutcomeRows != null ? this.Contract.m.OutcomeRows : [];
			}
		});
	}

	function onClear()
	{
		::Skv.Once.release("Azari");   // always free the live-offer slot (any removal)
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Azari");   // accepted then concluded -> retire for the campaign
			if (!::MSU.isNull(this.m.Site))
			{
				this.m.Site.getSprite("selection").Visible = false;
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
		if (!::MSU.isNull(this.m.Site))
		{
			_out.writeU32(this.m.Site.getID());
		}
		else
		{
			_out.writeU32(0);
		}
		_out.writeU8(this.m.HasTome ? 1 : 0);
		_out.writeU8(this.m.SiteCleared ? 1 : 0);
		_out.writeU8(this.m.Decided ? 1 : 0);

		// crawl deck + position
		if (this.m.Deck == null)
		{
			_out.writeU8(0);
		}
		else
		{
			_out.writeU8(this.m.Deck.len());
			foreach (k in this.m.Deck) _out.writeString(k);
		}
		_out.writeU8(this.m.CrawlIndex);
		_out.writeString(this.m.CryptTrophy);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local site = _in.readU32();
		if (site != 0)
		{
			this.m.Site = this.WeakTableRef(::World.getEntityByID(site));
		}
		this.m.HasTome     = _in.readU8() == 1;
		this.m.SiteCleared = _in.readU8() == 1;
		this.m.Decided     = _in.readU8() == 1;

		local dn = _in.readU8();
		if (dn > 0)
		{
			this.m.Deck = [];
			for (local i = 0; i < dn; i = i + 1) this.m.Deck.push(_in.readString());
		}
		this.m.CrawlIndex = _in.readU8();
		this.m.CryptTrophy = _in.readString();

		this.contract.onDeserialize(_in);
	}

});
