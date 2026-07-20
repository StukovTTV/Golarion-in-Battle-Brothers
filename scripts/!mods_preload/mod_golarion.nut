// ============================================================================
//  Golarion Localization  --  name overlay for Battle Brothers Legends.
//  Names overlay + hand-authored contracts (Phase 4). Each generated world = one
//  post-cataclysm Inner Sea; geography is evocative, not accurate.
// ============================================================================

local modID = "mod_golarion";
local modVersion = "0.91.22";   // STRING semver (X.Y.Z), not a float: MSU's registry cross-checks
                               // the ::MSU.Class.Mod version against the one mod_hooks recorded here
                               // and throws if they differ (registry_system.nut). Same value both places.
local modName = "Golarion Localization";
::mods_registerMod(modID, modVersion, modName);

::mods_queue(modID, "mod_msu, mod_legends", function()
{
	// One shared MSU settings dial for how often the mod's hand-authored contracts
	// appear (the faction-action m.Score, 0 = off .. 10 = common). Lives in ::Skv.Cfg
	// (skv_engine.nut); every *_action.nut reads it via ::Skv.Cfg.score().
	::Skv.Cfg.register(modID, modVersion, modName);

	::GolarionNames <- {
		SteppeVillage = [
			[
				"Djeneg", "Kalit", "Khurbresh", "Posdam", "Safani", "Ziloth",
				"Ibhir", "Mekhum", "Eserowaan", "Frowiseth", "Ulemsaleth", "Qadlus Mavari",
				"Jezonna Oasis", "Kihirat", "Tafiq", "Tar Kuata", "Adhaarm", "Banukmaud",
				"Abjit", "Acisazi", "Iqaliat", "Ker Sharic", "Satravah", "Udayasankar",
				"Thricehill", "Tiven's Reed", "Yavipho"
			], [
				"Al-Hiraf", "Anuli", "Botosani", "Gazbilah", "Heger", "Husanah",
				"Ihalar", "Ipeq", "Izzet", "Kharif", "Nirfan", "Omash",
				"Rashiz", "Sadiyeh", "Salav", "Tekeh", "Tephu", "Zimar",
				"El-Shelad", "Eto", "Gurat", "Naamat", "Shiman-Sekh", "Ushumgal",
				"An-Alak", "Chiron", "Djefet", "El-Fatar", "Finderplain", "Haldun",
				"Hanpa", "Hapkani", "Hatavit", "Khoka", "Oe-Tet", "Crystalcrag",
				"Dimayen", "Erekrus", "Isa", "Merishai", "Rikhist", "Solku",
			], [
				"Al-Varish", "Avilan", "Ayesh", "Butraf", "Delenah", "Demirah",
				"Hawah", "Ishad", "Jawafeeq", "Katheer", "Kerim", "Khundurai",
				"Lopul", "Manaket", "Merev", "Qaharid", "Sanmeshul", "Sedeq",
				"Shamara", "Shileh", "Sukri", "Totra", "Azir", "Urglin"
			]
		],
		SteppeFort = [
			[
				"Fort Fang", "Fort Longjaw", "Fort Kalabuto", "Fort Bandu", "Fort Scourbone", "Fort Kragang",
				"Fort Feilong"
			], [
				"Cloudreaver Keep", "Castle Clarion", "Daigaki Castle"
			], [
				"Citadel of Flame", "Citadel of the Alchemist", "Citadel of the Weary Sky", "Fortress Taufoon"
			]
		],
		MountainsFort = [
			[
				"Fort Dagh", "Fort Durak", "Fort Paskis", "Kravenkus", "Fort Rannick", "Rookwarden Fells",
				"Eagle Garrison Fort", "Flameford", "Piren's Bluff"
			], [
				"Ironhearth Foundry", "Dongun Hold", "Kraggodan", "Janderhoff", "Urgir", "Crownhold",
				"Cloudspire", "Fortress of Haldun", "Castle Everstand", "Ciricskree"
			], [
				"Highhelm", "Deepgate", "Scarwall", "Citadel Vraid", "House of the Beast"
			]
		],
		CoastFort = [
			[
				"Fort Benbem", "Fort Holiday", "Fort Hazard", "Fort Constance", "Fort Indros", "Fort Scurvy",
				"Fort Tempest", "Fort Hailcourse", "Fort Sea Dragon", "Fort Greenwatch"
			], [
				"Azlanti Keep", "Starwatch Keep", "Castle Golbanze", "Castle Borgoffi", "Beacon Promontory", "Castle of Knives",
				"Fort Stormunder", "Veldraine", "Palin's Cove"
			], [
				"Citadel Krane", "Skyreach", "Caer Syllan", "Citadel Ghastenhall", "Citadel Varynth"
			]
		],
		FishingVillage = [
			[
				"Bronze Hook", "Bug Harbor", "Driftwood", "Chimera Cove", "Biston", "Erages",
				"Bieralei", "Downpour", "Cypress Point", "Shoreline", "Almhult", "Souston",
				"East Rikkan", "Westpool", "Quent", "Ilsurian", "Galduria",
				"Turtleback Ferry", "Iceferry", "Halgrim", "Trollheim", "Jol", "Bildt",
				"Port Ice", "Niswan", "Padiskar", "Xao", "Enganoka", "Kasai",
				"Songbai", "Eleder", "Pendaka", "Blackcove", "Hangman's Harbor"
			], [
				"Otari", "Roderic's Cove", "Thrushmoor", "Yanmass", "Corentyn", "Ostenso",
				"Kintargo", "Vyre", "Kalabuto", "Kibwe", "Riddleport", "Kerse",
				"Restov", "Ilizmagorti", "Augustana", "Almas", "Rivercroft", "Sandpoint",
				"Ridonport", "Pezzack"
			], [
				"Mivon", "Cassomir", "Oppara", "Korvosa", "Magnimar", "Port Peril",
				"Whitethrone", "Kalsgard", "Sothis", "Katapesh"
			]
		],
		MiningVillage = [
			[
				"Aphet East", "Baslwief", "Brunderton", "Feigrvidr", "Shinnerman's Fortune", "Redburrow",
				"Kusker Farm", "Crackspike", "Deepmar", "Kellmouth", "Oremont", "Stom's Claim", "Ash Hollow"
			], [
				"Hallein Town", "Diamond Lake", "Whiterock", "Kopparberget", "Godsarm", "Chalk Harbor",
				"Radya's Hollow", "Hyannis"
			], [
				"Maheto", "Skelt", "Oregent", "Blisterwell", "Taggun Hold"
			]
		],
		ForestFort = [
			[
				"Fort Trevalay", "Fort Ozem", "Fort Drejas", "Fort Faelon", "Fort Machema", "Fort Nunder",
				"Fort Ristin", "Fort Ursoss", "Fort Thorn", "Fort Ramgate", "Fort Wildwood",
				"Isle of Arenway"
			], [
				"Fangwood Keep", "Broken Shield Castle", "Castle Pfalzgraf", "Thornkeep", "Castle Andachi", "Castle Firrine", "Castle of the Captive Sun"
			], [
				"Thornwall Castle", "Huntergate Fortress", "Citadel Ordeial"
			]
		],
		LumberVillage = [
			[
				"Avennara", "Bloomwreath", "Coralesian", "Lasinavel", "Omesta", "Shevaroth",
				"Siavenian", "Valanyne", "Doommark", "Eranmas", "Gillet", "Halidon",
				"Tradecross", "Tripolne", "Westsher", "Acorn's Rest", "Cavlinor", "Compost Watch",
				"Crowstump", "Ecru", "Folarth", "Graybanks", "Greenglade", "Kassen",
				"Lawson", "Old Rugged", "Purt", "Red Stem", "Scallion's Wrap", "Bellis",
				"Wildwood Lodge", "Thornhearth", "Arsmeril", "Whistledown", "Wolf's Ear", "Sipplerose",
				"Wispil"
			], [
				"Tamran", "Phaendar", "Longshadow", "Crystalhurst", "Braganza", "Cettigne",
				"Korholm", "Riverspire", "Glimmerhold", "Bluestone", "Crying Leaf", "Falcon's Hollow",
				"Olfden", "Nybor"
			], [
				"Canorate", "Greengold", "Iadara", "City of Thorns", "Wyvernsting", "Pangolais"
			]
		],
		SwampFort = [
			[
				"Fort Inevitable", "Fort Tanveh", "Fort Liberthane", "Fort Drelev", "Fort Riverwatch", "Fort Serenko",
				"Stag Lord's Fort", "Fort Morrine", "Marsh Tower"
			], [
				"Dhaenhold", "Castle Urion", "Castle Kronquist", "Castle Odranto", "Schloss Caromarc", "Zagorstra Keep",
				"Castle Balatz", "Castellany of the Fever Sea"
			], [
				"Onyx Citadel", "Thorn's End", "Throne of Flies", "Fortress of Sorrow"
			]
		],
		SwampVillage = [
			[
				"Alvren", "Bacul Gruii", "Deadbridge", "Farhaven", "Jovvox", "Kelbran",
				"Lockridge", "Maashinelle", "Mimere", "Orthult", "Outsea", "Saad",
				"Sarain", "Scrawny Crossing", "Seredain", "Sezgin", "Shimmerford", "Solanas",
				"Troxell", "Voluse", "Wilkesmont", "Blackpipe", "Chitterhome", "Dravod Knock",
				"Lackthroat", "Sunder Horn", "Szamrak's Haven", "Aaramor", "Ardagh", "Aton's Field",
				"Berus", "Bladswell", "Cesca", "Chateau Douleurs", "Corvischior", "Courtaud",
				"Dunhob", "Eran's Rest", "Feldgrau", "Grayce", "Marian Leigh", "Morast",
				"Morcei", "Rookhill", "Ruwido", "Sen's Pass", "Sturnidae", "Tolbau",
				"Vauntil", "Vische", "Wait's Span", "Crossfen", "Wartle", "Bitter Hollow", "Ravenmoor"
			], [
				"Artume", "Avendale", "Novoboro", "Riverton", "Tatzlford", "Varnhold",
				"Uringen", "Mormouth", "Tamrivena", "Rozenport", "Ravengro", "Illmarsh",
				"Thom", "Hajoth Hakados", "Graymoor", "Chesed", "Marstol", "Kuratown",
				"Carrion Hill", "Anactoria", "Chastel", "Redleaf"
			], [
				"Caliphas", "Pitax", "Daggermark", "Gralton", "Tymon", "Karcau",
				"Lepidstadt", "Ardis", "Kavapesta", "Sevenarches", "Iadenveigh"
			]
		],
		SnowVillage = [
			[
				"Atvan", "Badelund", "Baldachin", "Belila", "Bosorka", "Czarny Las",
				"Dalun", "Dammartorp", "Dobrova", "Gojko", "Hagby", "Harvest's End",
				"Helkgen", "Iarna", "Kerad", "Lachka", "Lod", "Ludovny",
				"Nadzieja Lato", "Riba", "Saarbotten", "Saraby", "Sascha", "Skrata",
				"Soduras", "Sosulka", "Three-Troll", "Trezira", "Veshtak", "Yensa",
				"Zaplava", "Zekrotska", "Zelen", "Ullerskad", "Tomgruv", "Whiterook",
				"Losthome", "Sojourner's Rest", "Asleifar", "Frembrudd", "Delmon's Glen", "Hellirinn",
				"Alstone", "Glacier's Rest", "Nithveil", "Seer's Home", "Skjoldmur"
			], [
				"Coldwater", "Waldsby", "Ledenica", "Riekamesto", "Ytterjorna", "Vasterborg",
				"Zlatomesto", "Zharchovsk", "Kizobran", "Isseld", "Eldentre", "Averaka",
				"Solskinn", "Turvik", "Frostbreach"
			], [
				"Algidheart", "Chillblight", "Hoarwood", "Morozny", "Redtooth"
			]
		],
		SnowFort = [
			[
				"Frost Giant's Fist", "Stormspear Keep", "Volfast's Tower", "Throne of the Troll King"
			], [
				"Haeringar's Keep", "Jotungard", "Thunderhold", "Keep of the Hound", "Cathedral of Obalas"
			], [
				"Holvirgang", "Ysborg", "Zar Kragnaral", "Palace of the Brumal Lords", "Veil of Frozen Tears"
			]
		],
		TundraVillage = [
			[
				"Haven", "Icestair", "Tolguth", "Ayin Lun", "Bulviss", "Dawnton",
				"Dubrov", "Krega", "Neathholm", "Timal", "Valas's Gift", "Zharech",
				"Golushkin", "Stoneclimb", "Winterbreak", "Zmeyka", "Arl", "Tuvar",
				"Skirgaard"
			], [
				"Grayhaven", "Visheksrad", "Hillcross", "Shatterglass", "Monastery of Tala", "Highdelve"
			], [
				"Egede", "Kenabres", "Bovodport"
			]
		],
		TundraFort = [
			[
				"Star Keep", "Eagle's Watch", "Zunderwal Hold", "Threshold"
			], [
				"Clydwell Keep", "Silverhall", "Blackraven Hall"
			], [
				"Nerosyan", "Drezen", "Skywatch"
			]
		],
		FarmingVillage = [
			[
				"Alvis", "Caldamin", "Claes", "Elesomare", "Fusil", "Lavieton",
				"Occarin", "Rippleden", "Riverford", "Sauerton", "Steyr", "Triela",
				"Whiterush", "Wittleshine", "Barleybridge", "Belde", "Blackridge", "Canorus",
				"Halmyris", "Hinji", "Khari", "Macini", "Misarias", "Nyshire",
				"Whisper Creek", "Senara", "Angen", "Belhaim", "Braughleigh's Hollow", "Breezy Creek",
				"Bronze Bridge", "Cydonus", "Dalaston", "Demgazi", "Disaren Village", "Dunholme",
				"Eagle's Head", "Elbistan", "Elsekulp", "Evondemor", "Faldamont", "Heldren",
				"Hope's Hollow", "Hyden", "Jambis", "Kozan", "Mistholme", "Moost",
				"Mut", "New Towne", "Old Sehir", "Ortalaca", "Pastorling", "Pensaris",
				"Pol", "Railford", "Sardis Township", "Skathen", "Solscrene", "Sotto",
				"Stachys", "Torcova", "Tregan", "Tribulation", "Tskikha", "Vigil's Rest",
				"Voinaris"
			], [
				"Cyremium", "Dekarium", "Kantaria", "Carpenden", "Anthusis", "Cascina",
				"Golsifar", "Talamir", "Remesiana", "Karakuru", "Lotheedar", "Brastlewark"
			], [
				"Egorian", "Westcrown", "Longacre", "Kazuhn City"
			]
		],
		FarmFort = [
			[
				"Bastion Ferox", "Bastion Dominus", "Bastion Tyrannous", "Lionsguard"
			], [
				"Castle Belverio", "Castle Issono", "Stavian's Hold", "Laekastel", "Grayguard Castle", "Monastery of the Seven Forms"
			], [
				"Citadel Rivad", "Citadel Demain", "Citadel Enferac", "Citadel Dinyar", "Citadel Vaull", "Citadel of the Supreme Elect"
			]
		]
	};

	::Const.Strings.CityStateNames = [
		"Absalom", "Kaer Maga", "Okeno", "Wati", "Goka", "Senghor",
		"Vaktai", "Aspenthar", "Ezida", "Lamasara", "Tanadesh", "Alkenstar",
		"Yenchabur", "Bloodcove", "Ular Kel", "Ecanus", "Quantium", "Arudrellisiir"
	];

	// ---- Noble houses as legacy claims on the runelords of Thassilon ----
	// Every name here is an ABSENT MASTER: dead, entombed, or sealed outside time during
	// our 4710-4715 AR window. A house does not hold its founder's seat because he is
	// there -- it holds it because he is not. That is what makes it a legacy and not a
	// staff position, and it is why "von <name>" finally parses: von means "of the house
	// of", and the object is a person, as the preposition intends. (A nation never was.)
	//
	// All 36 named runelords across Thassilon's millennium, plus First King Xin. These are
	// the LINES, not just the seven who held the seats at Earthfall -- Karzoug was the
	// eighth Runelord of Greed, not the only one. Grouped by realm for readability; the
	// game draws at random with a do/while dedup, so order is cosmetic.
	//
	// Aethusa appears in BOTH the Greed and Gluttony tables (overlapping reigns, per
	// PathfinderWiki) -- listed once here, since this is a name pool.
	// Lust and Pride have no formers: Sorshen and Xanderghul each ruled 1,187 years and
	// were the only originals to survive the betrayal of Xin. Every other line is a chain
	// of usurpations, and at least two (Karzoug over Haphrama, Zutha over Goparlis) were
	// the apprentice murdering his master.
	::Const.Strings.NobleHouseNames = [
		// Greed -- Shalast; ends with Karzoug, killed 4707 AR, his soul now the weight
		// of sin against which the Boneyard judges all others.
		"Kaladurnae", "Fethryr", "Gimmel", "Ligniya", "Mazmiranna", "Aethusa",
		"Haphrama", "Karzoug",
		// Gluttony -- Gastash; ends with Zutha, whose phylactery was reunited in 4715 AR.
		"Kaliphesta", "Atharend", "Goparlis", "Zutha",
		// Envy -- Edasseril; ends with Belimarius, sealed in Crystilan outside time.
		"Naaft", "Tannaris", "Ivamura", "Jurah", "Chalsardra", "Esedrea",
		"Zarve", "Desamelia", "Phirandi", "Belimarius",
		// Sloth -- Haruka; ends with Krune, Lissala's highest cleric, woken 4713 AR.
		"Xirie", "Ilthyrius", "Azeradni", "Zalelet", "Krenlith", "Ivarinna", "Krune",
		// Wrath -- Bakrakhan; Alderpash the first is a lich in Baphomet's labyrinth,
		// and Alaznist took his skull. She does not wake until 4716 AR.
		"Alderpash", "Angothane", "Xiren", "Thybidos", "Alaznist",
		// Lust -- Eurythnia. Pride -- Cyrusian. Both ruled from -6480 to Earthfall.
		"Sorshen", "Xanderghul",
		// The First King, murdered -6420 AR by the governors he appointed.
		"Xin"
	];

	// ---- City-state titles. Rendered as "<Title> of <Name>" -- faction_manager's
	// createCityStates does f.setTitle(CityStateTitles[rand(...)]) alongside the name draw.
	// Vanilla had seven; these are seven, all real Inner Sea polities, and every one says
	// something about the city instead of just classifying it. Dropped: "City State" and
	// "City" (categories, not names) and "Metropolis" (redundant with both).
	//
	// Holy City earns its slot: the DLC6 Holy War sets the noble houses against the
	// city-states, and every southern power in CityStateArchetypes below is a fiend rather
	// than a god -- so a Holy City ruled by Charon or Prihasta is the crisis explaining
	// itself. Republic pairs the same way with Prihasta, whose whole doctrine is that the
	// city is not ruled but persuaded.
	//
	// EXISTING Const key -> assign with `=`, not `<-`.
	//
	// The " of" IS PART OF THE TITLE STRING. The UI concatenates title + " " + name, so
	// "Holy City" renders as "Holy City Alkenstar". Vanilla's English entries are
	// "Free City of", "Realm of", etc. -- invisible in the zh decompile, whose 城邦 / 自由城
	// carry no preposition because Chinese does not need one. Verified in-game v0.78.
	::Const.Strings.CityStateTitles = [
		"Free City of", "Protectorate of", "Realm of", "Holy City of",
		"Kingdom of", "Republic of", "Hegemony of"
	];

	// ---- Region labels: Const.Strings.TerrainRegionNames, indexed by terrain type ----
	// Real Golarion regions per terrain. Only touch the terrains we localize; the rest stay vanilla.
	::Const.Strings.TerrainRegionNames[1] = [   // ocean
		"The Inner Sea", "The Steaming Sea", "The Arcadian Ocean", "The Obari Ocean",
		"The Fever Sea", "The Ivory Sea", "The Embaral Ocean", "The Sea of Ghosts",
		"The Cerulean Sea", "The Shining Sea", "The Sightless Sea", "Sapphire Sound",
		"The Varisian Gulf", "Gemcrown Bay", "Conqueror's Bay", "The Castrovin Sea"
	];
	::Const.Strings.TerrainRegionNames[2] = [   // plains
		"Fields of Chelam", "Rostland Plains", "Carpenden Plains", "Nesmian Plains",
		"Sirmium Plains", "The Dunsward", "Plains of Molthune", "The Swardlands",
		"Whistling Plains", "Field of Maidens", "Sovereign's Reach", "The Kamelands",
		"The Nolands", "Porthmos Gap", "Weeping Fields", "Blood Plains",
		"Plains of Conflict", "Fields of Serenity", "The Felldales", "Windhome"
	];
	::Const.Strings.TerrainRegionNames[3] = [   // swamp
		"The Mushfens", "The Dhaenfens", "Ghostlight Marsh", "Hooktongue Slough",
		"Brinestump Marsh", "The Shimmerglens", "Dunmire", "Moonbog",
		"Whitewillow", "Frostmire Fen", "Dragonfen", "Barrowmoor", "Plaguemere", "Murkfen",
		"Blackwood Swamp", "Dippelmere Swamp", "Graidmere Swamp", "Deiphovan Slough",
		"Wrythe", "Evergrowth", "Bridespool Fen", "Sclerain Swamp"
	];
	::Const.Strings.TerrainRegionNames[4] = [   // hills
		"Curchain Hills", "Hollow Hills", "Sellen Hills", "Salt Hills",
		"Riven Hills", "Keening Hills", "Seething Hills", "Shy Hills",
		"Hills of Nomen", "Juviler Hills", "Velashu Uplands", "Wolfrun Hills",
		"Bandu Hills", "Turanian Hills", "Uvall Hills", "Wolfcrags",
		"Karggat Hills", "Skala Foothills"
	];
	::Const.Strings.TerrainRegionNames[5] = [   // forest (dark)
		"The Shudderwood", "Gronzi Forest", "The Lurkwood", "The Churlwood",
		"The Whisperwood", "The Uskwood", "Duskshroud Forest", "Shroudwood",
		"Specterwood", "Hagwood", "Witchgate Forest", "Nettlewood",
		"Darkblight", "Gloaming Wood", "Shrikewood", "Witherbark Forest"
	];
	::Const.Strings.TerrainRegionNames[7] = [   // forest (green)
		"Verduran Forest", "Mierani Forest", "Fierani Forest", "Sanos Forest",
		"The Fangwood", "Ravounel Forest", "Exalted Wood", "Vale of Green Spears",
		"Evergrove", "Highforest", "Glitterglen", "Elderwoods",
		"Enchanted Wood", "Immenwood", "Winding Wood", "Mosswood"
	];
	::Const.Strings.TerrainRegionNames[8] = [   // forest (fiery/autumn)
		"Arthfell Forest", "Estrovian Forest", "Echo Wood", "The Border Wood",
		"Emberbough Forest", "Forest of Embers", "The Smoldering Forests", "Smokewood",
		"Ashwood", "Kreegwood", "Boarwood", "Backar Forest", "Coreth Wood"
	];
	::Const.Strings.TerrainRegionNames[9] = [   // mountains
		"Mindspin Mountains", "Kodar Mountains", "Menador Mountains", "Aspodell Mountains",
		"Five Kings Mountains", "The Barrier Wall", "Hungry Mountains", "Iron Peaks",
		"Napsune Mountains", "World's Edge Mountains", "Wyvern Mountains", "Fenwall Mountains",
		"Fogscar Mountains", "Malgorian Mountains", "Tors of Levenies", "Calphiak Mountains",
		"Fog Peaks", "Red Mountains", "Stony Mountains", "Golushkin Mountains",
		"Kortos Mounts", "Emperor's Peak", "Droskar's Crag", "Hook Mountain",
		"Devil's Perch", "Pale Mountain", "Zho Mountains", "Shattered Range", "Diremark"
	];
	::Const.Strings.TerrainRegionNames[12] = [  // snow
		"Winterwall Glacier", "The Icerime Peaks", "Stormspear Mountains", "Rimethirst Mountains",
		"The Algid Wastes", "Hoarwood Forest", "Frozen Pines", "Grungir Forest",
		"Monolith Glacier", "Rimeskull", "The Frozen Fog"
	];
	::Const.Strings.TerrainRegionNames[14] = [  // tundra
		"The Thunder Steppes", "The Ice Steppes", "The Cold Waste", "The Boreal Expanse",
		"Numerian Plains", "Dvezda Marches", "Sarkoris Scar", "The Furrows"
	];
	::Const.Strings.TerrainRegionNames[15] = [  // steppe
		"The Storval Plateau", "The Cinderlands", "The Sarkorian Steppe", "The Uthori Steppes",
		"The Grass Sea", "Osogen Grasslands", "Korir Plains", "M'neri Plains"
	];
	::Const.Strings.TerrainRegionNames[17] = [  // desert
		"Footprints of Rovagug", "The Glazen Sheets", "Coast of Graves", "The Mana Wastes",
		"The Spellscar Desert", "The Meraz Desert", "The Alamein Peninsula", "The Parched Dunes",
		"Sea of Whispering Sands", "The Empty Quarter", "The Dustbeds", "Trackless Dearth"
	];

	// ---- Reflavor noble-house archetype prose: keep Traits, swap Description + Mottos ----
	// Matched by a distinctive phrase in each vanilla description. Guarded so a structure
	// change can never crash the load; if nothing matches it simply does nothing.
	local golarionArch = {
		"history of conquest": {
			d = "House %noblehousename% remembers when Aroden walked the earth and the Inner Sea answered to one throne. Since the god's death broke that promise, they have sworn to Gorum that the sword will decide what prophecy no longer can. From %factionfortressname% they ride to reforge the old dominion in iron and blood, and their feud with house %othernoblehouse% has fed Our Lord in Iron for generations.",
			m = ["Won back by the sword", "Gorum cares not whose blood", "No throne but the taken one", "The blade outlived prophecy", "Iron decides all", "Boldly and rightly", "He conquers who endures"]
		},
		"Disdained for their ruthlessness": {
			d = "In the lawless years since Aroden's fall, house %noblehousename% learned that a full granary is only as safe as the swords around it. From %factionfortressname% their reavers strip caravans, farms, and any village too weak to hold, and a life is worth less than the salt it is traded for. Some whisper they have made peace with the Rough Beast; most are too dead to whisper anything.",
			m = ["Mercy died with the god", "Rovagug's teeth, our blades", "The strong eat", "What you cannot hold is ours", "Beg or bleed", "Lawless years, good years"]
		},
		"eyes on the horizon": {
			d = "House %noblehousename% keeps its gaze past the horizon, on the fortunes of Absalom, the plunder of the Shackles, every coast the shattering left unguarded. From %factionfortressname% they launch expedition after expedition to seize a world they hold rightfully theirs, for in an age of broken prophecy a realm belongs to whoever is bold enough to take it.",
			m = ["The world is unclaimed", "Bold hands built Absalom", "Past the horizon, everything", "A bold hand takes the world", "Sail, seize, return", "Fortune favors the bold"]
		},
		"history of total control": {
			d = "House %noblehousename% rules %factionfortressname% by a compact as old and binding as the Prince of Darkness himself: obedience for order, tithe for protection. What Aroden's death took in certainty, they return in the cold comfort of law absolute, and a frightened people, remembering the chaos beyond the walls, learn to love the chain that steadies them.",
			m = ["Order is mercy", "Asmodeus keeps his bargains", "The chain steadies the hand", "Obedience for peace", "Better a cruel law than none", "Chaos is the only tyrant"]
		},
		"works in the dark": {
			d = "House %noblehousename% keeps its borders not with walls but with whispers. Its agents, blessed some say by Norgorber himself, have eyes in every shadowed doorway from %factionfortressname% to the courts of its rivals. Peace holds in their lands, for a knife finds every plotting throat before the plot is even spoken aloud.",
			m = ["We are always listening", "Norgorber keeps our ledger", "Every wall has our ear", "The knife before the plot", "Peace, bought in whispers", "Silence is our watchword"]
		},
		"jealously guarded": {
			d = "The vaults beneath %factionfortressname% are said to rival Druma's own, yet house %noblehousename% never counts itself rich enough. Where Abadar's faithful build with their gold, this house only buries it deeper, and the whispered tally of their hoard grows with every year the world outside grows poorer.",
			m = ["It all comes home", "Gold outlasts gods", "Never rich enough", "Bury it deeper", "The vault is the truest faith", "Druma's envy is our pride"]
		},
		"subtly manipulates": {
			d = "When Aroden died, most of his faithful despaired, but house %noblehousename% turned to Iomedae and kept the old promise in quieter ways. From %factionfortressname% they work unseen: a coin to the starving, a word in the right ear, a blade drawn only in the deepest dark. In a shattered Inner Sea, they are a stubborn ember of the world that was promised.",
			m = ["Lost Omens, not the last age", "Aroden's promise, unbroken", "A light against the long dusk", "For the folk, not the gods", "We keep the old faith quietly", "The dawn was only delayed"]
		},
		"Lauded as providers": {
			d = "House %noblehousename% answers to its own people first and the wider world not at all. From %factionfortressname% its warbands strip the caravans and farms of the soft southern realms, and every wagon comes home to fill their own bowls. Cruel to strangers and generous to kin, they call it not banditry but providing, and their well-fed folk, while others starve, name it the same.",
			m = ["Bringing it home", "Kin before crown", "Hard abroad, true to kin", "The soft south feeds us", "Our people eat first", "A full bowl, a hard name"]
		},
		"master of cunning bargains": {
			d = "House %noblehousename% holds that a ledger conquers what a legion cannot. From the counting-houses of %factionfortressname% they broker deals across the broken Inner Sea, some blessed by Abadar, many more built on bribery and quiet threat. For all their fabled riches they are famously close-fisted; a coin that enters their vaults is not seen again.",
			m = ["Every man has his price", "Wealth is our sword", "The ledger conquers all", "A deal is a quieter war", "Abadar blesses the shrewd", "Coin in, coin never out"]
		},
		"when man first claimed this land": {
			d = "House %noblehousename% claims a bloodline older than Aroden's empire, back to when the first kings raised their halls upon the bones of Azlant. One house among many now, coffers thinning and name fading, from %factionfortressname% they fund doomed expeditions into sunken Thassilonian ruins and drowned Azlanti vaults, chasing the glory of an age the sea swallowed.",
			m = ["Our roots run to Azlant", "Kings when kings were young", "The old glory sleeps, not dead", "Down into the drowned vaults", "Blood older than empire", "Thassilon remembers"]
		},
		"secluded behind thick doors": {
			d = "The doors of %factionfortressname% have stayed barred for a generation. Rumor names the blood of house %noblehousename% cursed, touched by Zon-Kuthon's long shadow, or by something older that crept in when the gods stopped watching. Other houses keep their distance, for a guest here is as likely met with open arms as a crossbow bolt from a darkened window.",
			m = ["The blood remembers", "Shadows keep our counsel", "Knock, and pray no one answers", "The doors stay barred", "What crept in, stayed", "Madness is a kind of sight"]
		}
	};
	try {
		foreach (group in ::Const.FactionArchetypes) {
			if (typeof group != "array") continue;
			foreach (arch in group) {
				if (typeof arch != "table" || !("Description" in arch)) continue;
				foreach (key, repl in golarionArch) {
					if (arch.Description.find(key) != null) {
						arch.Description = repl.d;
						arch.Mottos = repl.m;
						break;
					}
				}
			}
		}
	} catch (e) { ::logInfo("Golarion archetype reflavor skipped: " + e); }

	// ==================== The pantheon: gods AS archetypes ====================
	// Houses are named for RUNELORDS (absent masters, NobleHouseNames above); the
	// ARCHETYPE is the god that house serves, and its Description carries that god's
	// lore. Legends' createNobleHouses draws archetypes WITHOUT replacement
	// (houses.remove(rand(...)) over GetFactionArchetypesList()), so every campaign
	// deals N distinct gods -- 4-6 per world, a different slice each time. Anyone who
	// reads the Factions panel learns them. That is the whole point of the mod.
	//
	// This REPLACES the table rather than extending it: 100% coverage by construction,
	// and it retires the phrase-matching above (which reflavored only 11 of 21 and
	// breaks the day Legends re-words a sentence). The block above is now inert -- it
	// matches nothing here -- and is kept only so this change is easy to revert.
	//
	// !! ENTRY COUNT MUST BE >= the Legends "Factions" mod setting !! createNobleHouses
	// loops that many times doing houses.remove(rand(0, len-1)); run out of archetypes
	// and it indexes an empty array. With 4 entries, set Factions = 4.
	//
	// Traits are DOCUMENTATION ONLY. Verified: nothing in vanilla or Legends ever reads
	// Warmonger/Tyrant/Marauder/Schemer/Sheriff/Collector/ManOfThePeople -- only
	// NobleHouse does work (it grants the 35-action deck every house shares), and
	// hasTrait() is called in exactly two places, both checking OrientalCityState. They
	// are written to fit the god anyway: free, honest, and correct on the day anything
	// ever wires them up. Pairs are chosen from the 16 combinations vanilla actually
	// uses -- it never pairs Sheriff with Warmonger/Tyrant/Marauder (the lawman is not
	// a thug), so Iomedae takes Sheriff+ManOfThePeople rather than Sheriff+Warmonger.
	//
	// Voice: ~55-65 words. [the world's wound] -> [what this god teaches] ->
	// [From %factionfortressname% ...] -> [a closing image]. Aroden is named ONLY where
	// he is load-bearing (Iomedae was his herald) -- elsewhere use the shattering, the
	// long dusk, the lawless years, broken prophecy, or no catastrophe at all.
	// NO COLOUR TAGS. Tested in-game v0.71: the Factions & Relations panel does NOT run
	// its Description through the tag parser -- [color=#9dbccb]Sarenrae[/color] rendered
	// as literal text on screen. Contract/event screens DO parse tags; this one does not.
	// Placeholders: %noblehousename% %factionfortressname% %othernoblehouse% are live.
	// %regionname% resolves to an EMPTY STRING (faction_manager stubs it) -- never use it.
	::Const.FactionArchetypes = [
		[
			{	// ERASTIL -- Old Deadeye. LG. Longbow. Family, farming, hunting, trade.
				// Symbol: bow and arrow. Stag; brown and green. Ulfen.
				// Obedience: plant five seeds in fertile earth in the shape of an arrow --
				// they need not thrive there, only have a chance at survival. If there is no
				// earth, leave seed, preserved food or a quiver where a passerby will find it,
				// marked with his sign, and pray for the safety of the communities nearby.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.ManOfThePeople,
					::Const.FactionTrait.Collector
				],
				Description = "When the prophecies broke the cities went mad with it, and House %noblehousename% went out to the fields as it had the year before. Erastil promised no age, so no age of his has ended -- Old Deadeye asks only what a village can give. His people still plant five seeds in the shape of an arrow, asking only that each has a chance, and still leave bread on the road where a stranger will find it.",
				Mottos = [
					"The hearth outlasts the throne",
					"Old Deadeye asks nothing of you",
					"A full barn needs no prophecy",
					"We were farming before the gods",
					"Bow, hearth, harvest",
					"Let it burn. We have seed."
				]
			},
			{	// IOMEDAE -- The Inheritor. LG. Longsword. Honor, justice, rulership, valor.
				// Symbol: sword and sun. Lion; red and white. Chelaxian.
				// Obedience: hold your weapon before you with her symbol hung from it, kneel,
				// pray for guidance, and swear to follow her teachings.
				// Aroden kept: she was his herald and took up his work when he fell.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% swore to Iomedae in the year the god died, and has not unsworn. The Inheritor was Aroden's herald; when he fell she took up the work instead of mourning it. Their knights kneel with the sword held upright and her symbol hung from it, swear what she swore, then ride out from %factionfortressname% to judgements nobody asked for.",
				Mottos = [
					"Aroden fell. The work did not.",
					"The Inheritor took up the sword",
					"We do not mourn. We march.",
					"Valor is a habit, not a mood",
					"Judgement rides out",
					"Someone must"
				]
			},
			{	// TORAG -- Father of Creation. LG. Warhammer. Forges, protection, strategy.
				// Symbol: iron hammer. Badger; gold and grey. Dwarf.
				// Obedience: work a forge, or strike an anvil or flat stone with a hammer for
				// ten minutes. If the sound draws a creature near, invite it to join the
				// worship; if it comes to blows, leap in with a battle shout. Then tend your
				// weapon, or give what you made to the next fair and honourable person you meet.
				// Probe answered (v0.70): the panel SCROLLS -- chain-and-ring on the right, no
				// clipping. So length is free and each god gets what it earns. Trimmed back
				// anyway; this one had two clauses that were padding.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps Torag's forges, and the Father of Creation teaches that anything worth having is worth building twice -- once in iron, and once in stone around the iron. Their smiths beat the anvil ten minutes at a stretch for the sound of it, and whoever the noise draws in is asked to join the work, or, if it comes to that, the fight. Since the shattering proved the world could break they have done little but thicken the walls of %factionfortressname%. They will sell you a hammer, a plan, or a siege you cannot win.",
				Mottos = [
					"Build it twice",
					"The wall is the prayer",
					"Iron first, then stone around it",
					"Torag measured before he struck",
					"We do not lose ground",
					"Strategy is patience with a hammer"
				]
			},
			{	// SARENRAE -- The Dawnflower. NG. Scimitar. Healing, honesty, redemption, the sun.
				// Symbol: angelic ankh. Dove; blue and gold. Keleshite.
				// Obedience: offer to heal a stranger, and tell him it is by her will. If no one
				// will accept, stand under the open sky, blindfold yourself with a red-and-gold
				// scarf, and try to find the sun through the layers of fabric.
				// ManOfThePeople + Warmonger is her actual doctrinal schism: mercy, then fire.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.ManOfThePeople,
					::Const.FactionTrait.Warmonger
				],
				Description = "House %noblehousename% opens %factionfortressname% to anyone who comes to it broken, because Sarenrae teaches that no soul is past redeeming. The Dawnflower's clerics will feed a murderer, nurse him, and hear him out. On the days nobody will accept their help they walk out beyond the walls, bind their eyes with a red-and-gold scarf, and stand trying to find the sun through the cloth.",
				Mottos = [
					"No soul past redeeming",
					"The Dawnflower offers twice",
					"Mercy first. Fire after.",
					"Come broken. Leave whole.",
					"The scimitar is also the sun",
					"There is no third chance"
				]
			}
,
			{	// SHELYN -- The Eternal Rose. NG. Glaive. Art, beauty, love, music.
				// Symbol: multicoloured songbird. Songbird; every colour. Taldan.
				// Obedience: make a small work of art -- picture, poem, song, dance -- heartfelt
				// and the best you can manage, whispering praise to her grace. Give it to a
				// stranger with a sincere compliment. If nobody is there to take it, leave it
				// somewhere obvious with a note asking the finder to keep it.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.ManOfThePeople,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% serves Shelyn, and the Eternal Rose asks nothing of her faithful except that they make something. A picture, a song, a few lines of verse -- it need not be large or clever, only honest and the best that was in them -- and then they must give it away to a stranger and say something kind while doing it. Where nobody will take it, they leave it on a bench with a note asking whoever finds it to keep it. From %factionfortressname% they have done this through two famines and a war, and no one has worked out how to make them stop.",
				Mottos = [
					"Make something. Give it away.",
					"The Eternal Rose asks only your best",
					"Beauty is not a luxury",
					"A kind word with the gift",
					"Two famines and a war, and still we paint",
					"Nobody has made us stop"
				]
			},
			{	// CAYDEN CAILEAN -- The Drunken Hero. CG. Rapier. Ale, bravery, freedom, wine.
				// Symbol: tankard. Hound; silver and tan. Taldan. Ascended (was mortal).
				// Obedience: sing a song praising freedom, bravery and his glory (and good
				// looks), audible to everyone nearby -- friend or foe -- pausing between stanzas
				// to drink. If someone is drawn in, argue his merits at them. If it comes to a
				// fight, leap in without hesitation.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.ManOfThePeople,
					::Const.FactionTrait.Warmonger
				],
				Description = "House %noblehousename% drinks to Cayden Cailean, who was mortal before he was a god and by every account not a careful one. His worship is a song about freedom and bravery and how well he wore both, sung loud enough that everyone nearby hears it -- friend or foe, no exceptions -- with a pull from the mug between stanzas. If the noise brings someone over, they are talked at about the Drunken Hero until they agree. If it brings a fight instead, that is also acceptable. From %factionfortressname% they have freed more slaves than they have won battles, which they consider the correct ratio.",
				Mottos = [
					"Sung loud enough for the enemy",
					"Freedom, bravery, and a full mug",
					"He was one of us first",
					"More slaves freed than battles won",
					"Leap in. Ask after.",
					"The correct ratio"
				]
			},
			{	// DESNA -- Song of the Spheres. CG. Starknife. Dreams, luck, stars, travelers.
				// Symbol: butterfly. Butterfly; blue and white. Varisian.
				// Obedience: dance in a random pattern beneath the stars, trusting destiny --
				// turn your thoughts from where your feet land and let them fall where chance
				// wills. If no stars are visible, sing the names of every star you know. When
				// it feels complete, stop, and read the portents in your steps and where you
				// came to rest.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% keeps Desna, and the Song of the Spheres is worshipped by dancing beneath the stars in no pattern at all -- you are meant to stop thinking about where your feet are going and let them fall where chance wants them. When the dance ends you study where you stopped, and the steps behind you, and read what they meant. If there are no stars, you sing the names of the ones you know instead. From %factionfortressname% they have chosen wars, marriages and harvests this way for six generations, and are no worse off than House %othernoblehouse%, which uses maps.",
				Mottos = [
					"Let the steps fall where they will",
					"Song of the Spheres knows the way",
					"We danced for this",
					"No worse off than the ones with maps",
					"Read where you stopped",
					"Chance is not the same as nothing"
				]
			},
			{	// ABADAR -- Master of the First Vault. LN. Light crossbow. Cities, laws,
				// merchants, wealth. Symbol: golden key. Monkey; gold and silver. Taldan.
				// Obedience: take a handful of mixed gems, coins and keys -- coins from three
				// or more currencies, at least three keys, one of them to a vault. Kneel before
				// a scale and balance them as perfectly as you can. Randomize the handful each
				// time so the obedience never becomes routine. Meditate on The Order of Numbers.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% serves Abadar, Master of the First Vault, whose worship is bookkeeping. Each morning a handful of gems, coins and keys -- coins from three kingdoms at least, and three keys, one of them to a vault -- is balanced on a scale until it sits level, and the handful must be different every day so that it never becomes a habit. From %factionfortressname% they hold that a city is only a very large scale, and that everything on it, laws included, can be brought level by someone patient enough to keep the ledger honest.",
				Mottos = [
					"Bring it level",
					"The ledger is the prayer",
					"A city is a very large scale",
					"Never the same handful twice",
					"Patience, and an honest ledger",
					"Master of the First Vault keeps count"
				]
			},
			{	// IRORI -- Master of Masters. LN. Unarmed strike. History, knowledge,
				// self-perfection. Symbol: blue hand. Snail; blue and white. Vudrani. Ascended.
				// Obedience: over one hour, in equal parts -- practise with a weapon or your
				// unarmed strikes, read a text you have never read before, and braid a length
				// of hair while contemplating the mysteries of the multiverse. Wear the braid
				// around your neck for the rest of the day.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Sheriff
				],
				Description = "House %noblehousename% follows Irori, who was a man before he was a god and arrived by not stopping. The Master of Masters is a title he was given rather than took, which his faithful consider the only honest way to get one. His hour divides into three equal parts: strike something, read something you have never read before, and braid a length of hair while considering the shape of the universe. The braid is worn around the neck until nightfall. From %factionfortressname% they field no army worth the name and hold no ambition anyone else can identify, and every one of them can kill you with their hands.",
				Mottos = [
					"He was a man before he was a god",
					"Strike, read, braid",
					"Perfection is only not stopping",
					"We have no ambitions you would notice",
					"Master of Masters was mortal once",
					"The hands are enough"
				]
			},
			{	// GOZREH -- The Wind and the Waves. N. Trident. Nature, the sea, weather.
				// Symbol: dripping leaf. All animals; blue and green. Mwangi.
				// Obedience: hang chimes where wind or water will stir them (or hold and shake
				// them). Chant from Hymns to the Wind and the Waves until you are attuned to the
				// sound, then drink a mouthful of pure water and pour a handful over your head.
				// Marauder + ManOfThePeople is the dual nature: shelter, and salvage.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% hangs chimes for Gozreh where the wind or the water will find them, and chants until the sound stops, then drinks a mouthful of clean water and pours a handful over the head. The Wind and the Waves is two things at once and neither is interested in you: the sea that carries the grain drowns the fleet, and the clerics of %factionfortressname% will tell you that is not cruelty, it is weather. They shelter whoever the storm sends them and take whatever it leaves on the rocks.",
				Mottos = [
					"It is not cruelty. It is weather.",
					"The Wind and the Waves owes you nothing",
					"Shelter what comes, take what stays",
					"The same sea does both",
					"Hang the chimes",
					"Grain or wreckage, as it falls"
				]
			}
,
			{	// NETHYS -- The All-Seeing Eye. N. Quarterstaff. Magic (that is the whole entry).
				// Symbol: two-toned mask. Zebra; black and white. Garundi. Ascended.
				// Obedience: inscribe blessings, arcane formulae and prayer on blank parchment --
				// but NEVER a complete spell, only enough to tempt a reader into studying magic
				// to finish the incantation. Then cast anything, or trigger a magic item.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Warmonger,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% serves Nethys, the All-Seeing Eye, who saw everything there is and came back wearing a mask that is white down one side and black down the other. Magic is his only concern and he holds no opinion whatever about what is done with it. His rite is to write a formula out on clean parchment and stop halfway -- never a whole spell, only enough of one that whoever finds it might be tempted to finish the working themselves. From %factionfortressname% they have been leaving these lying about for years.",
				Mottos = [
					"Never the whole spell",
					"The All-Seeing Eye has no opinion",
					"Finish it yourself",
					"White on one side, black on the other",
					"We only left it lying there",
					"Magic does not care either"
				]
			},
			{	// PHARASMA -- Lady of Graves. N. Dagger. Birth, death, fate, prophecy.
				// Symbol: spiralling comet. Whippoorwill; blue and white. Garundi.
				// Obedience: collect small bones respectfully; lay them in a spiral with a slip
				// naming someone newly born at one end and someone newly dead at the other;
				// chant from The Bones Land in a Spiral while walking it solemnly, trailing a
				// black scarf on the ground behind you.
				// The broken-prophecy wound is hers without naming Aroden -- do not add him.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% keeps Pharasma, the Lady of Graves, who is owed every soul eventually and has never once hurried. Her people gather small bones as they come across them, lay them in a spiral, and set a slip of parchment at either end -- one named for somebody born that week, one for somebody dead -- then walk the coil chanting, trailing a black scarf along the ground behind them. She was the goddess of prophecy as well, once. From %factionfortressname% nobody has raised the subject in a hundred years.",
				Mottos = [
					"The bones land in a spiral",
					"She is owed, and she can wait",
					"Born at one end, dead at the other",
					"We do not discuss the prophecy",
					"The Lady of Graves keeps the roll",
					"Everyone arrives on her books"
				]
			},
			{	// CALISTRIA -- The Savored Sting. CN. Whip. Lust, revenge, trickery.
				// Symbol: three daggers. Wasp; black and yellow. Elf.
				// Obedience: sex traded for money, information or another valuable resource,
				// willing on both sides, with prayer aloud before and after. Failing a partner:
				// wrap yourself in yellow silk, hold the symbol to your chest, and fantasize in
				// detail about taking vengeance on someone who wronged you.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.Schemer
				],
				Description = "House %noblehousename% serves Calistria, the Savored Sting, who takes three daggers and a wasp for her sigil and holds that lust and revenge are one appetite aimed two ways. When there is nobody to take to bed, her faithful wrap themselves in yellow silk, hold the symbol against the chest, and spend the hour thinking in careful detail about a person who wronged them. From %factionfortressname% they forgive nothing and forget less, and they are extremely good company.",
				Mottos = [
					"Three daggers, and time",
					"We forgive nothing and forget less",
					"The Savored Sting remembers you",
					"One appetite, aimed two ways",
					"Yellow silk and a long memory",
					"It was always going to be us"
				]
			},
			{	// GORUM -- Our Lord in Iron. CN. Greatsword. Battle, strength, weapons.
				// Symbol: sword in mountain. Rhinoceros; grey and red. Kellid.
				// Obedience: in your heaviest metal armour, shout your oath at the top of your
				// lungs, smashing your weapon on shield or armour at every pause for breath.
				// Then kneel on one knee, weapon on shoulder, and recite your victories aloud.
				// If attacked mid-rite, slay the interrupter -- allies may help, but YOU must
				// strike the killing blow.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Warmonger,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% shouts for Gorum, Our Lord in Iron, and the worship is done in the heaviest armour you own: bellow the oath until the breath goes, beating your weapon on shield or breastplate at every pause, then kneel with the blade on your shoulder and recite your victories aloud until the hour is out. Anyone who interrupts is to be killed -- your men may help, but the last blow must be yours. From %factionfortressname% they have never once had to be asked twice.",
				Mottos = [
					"The last blow must be yours",
					"Our Lord in Iron cares not whose blood",
					"Say it louder",
					"Recite them until the hour is out",
					"Never asked twice",
					"The sword is in the mountain"
				]
			},
			{	// ASMODEUS -- Prince of Darkness. LE. Mace. Contracts, pride, slavery, tyranny.
				// Symbol: red pentagram. Serpent; black and red. Devil.
				// Obedience: with a ruby-bladed knife, cut symmetrical marks into a creature you
				// own or hold dominion over. Drain its blood into a bowl made from a sentient
				// humanoid's skull -- but only so much: never enough to weaken it or leave it
				// too useless to serve. Draw a pentagram with the blood and kneel inside it.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Tyrant,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% holds its contract with Asmodeus, the Prince of Darkness, and pays it in blood: symmetrical cuts opened with a ruby blade in something that belongs to you, drained into a bowl cut from a human skull, the blood used to draw the pentagram they then kneel inside. The doctrine is precise about the quantity -- never so much that the creature is weakened, or left too useless to go on serving. From %factionfortressname% they will remind you the terms were written down, and that you signed.",
				Mottos = [
					"The terms were written down",
					"You signed",
					"Asmodeus keeps his bargains",
					"Never more than the asset can bear",
					"Order is mercy, at a price",
					"Read it again"
				]
			},
			{	// ZON-KUTHON -- The Midnight Lord. LE. Spiked chain. Darkness, envy, loss, pain.
				// Symbol: chained skull. Bat; dark grey and red. Alien.
				// CANON: was DOU-BRAL, good god of beauty/art/light, son of spirit-wolf Thron,
				// half-brother of SHELYN (Core pantheon -> sibling-faction rivalry). Grew envious,
				// went into the outer dark, was possessed/unmade, came back as Zon-Kuthon. Shelyn
				// keeps their shared glaive, the WHISPERER OF SOULS, still believing him redeemable.
				// Obedience: PERSUADE a creature to let you hurt it -- needles under the skin,
				// or the lash, whatever it agrees to. Consent is the sacrament (a purchased
				// subject counts where slavery is legal). Failing that: coil a spiked chain
				// into a nest, kneel on it until your weight drives it in, and whip your own
				// back chanting praise.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Tyrant,
					::Const.FactionTrait.Schemer
				],
				Description = "House %noblehousename% belongs to Zon-Kuthon, the Midnight Lord -- but he was not always that, and the house knows the older name. In the first age he was Dou-Bral, son of the spirit-wolf Thron, a god of beauty and art and light, and he shared both a love of lovely things and a single golden glaive with his half-sister Shelyn. Then he grew envious of her, and went out into the dark places beyond and between the planes, and something out there in the truly outer dark unmade him and put him back together wrong. What came home was not Dou-Bral. When Shelyn saw what her brother had become she fought him -- and won from his fingers the glaive they had shared, the Whisperer of Souls, which she keeps to this day because she alone has never accepted that he is gone for good, and believes, still, that the brother can be called back out of the thing wearing him. The house exists, in a way, to prove her wrong. Their worship is pain, but pain asked for: the rite needs a creature persuaded to permit it -- the needle, the lash, the hook, whatever is agreed -- and the agreeing is the sacrament, for consent given is the sweeter to spoil. Where none will consent, they coil a spiked chain into a nest and kneel until their own weight drives it home, and flog their own backs in praise. From %factionfortressname% they are unfailingly gentle, unfailingly polite, and they will explain to you, patiently and at length, exactly why you want this -- because their god was talked out of the light once, in the dark, by something patient, and they have learned from him how it is done.",
				Mottos = [
					"He was Dou-Bral once",
					"We exist to prove his sister wrong",
					"The agreeing is the sacrament",
					"He was talked out of the light, patiently",
					"We always ask first",
					"Say yes"
				]
			},
			{	// NORGORBER -- The Reaper of Reputation. NE. Short sword. Greed, murder, poison,
				// secrets. Symbol: one-eyed mask. Spider; black and grey. Taldan. Ascended.
				// Obedience: move through a crowd of six or more whispering a prayer so quietly
				// nobody hears; if you suspect someone did, follow them and prick them with a
				// poisoned needle. No crowd? Dig a hole six inches deep, whisper into it, and
				// bury the sound. End by leaving a poisoned needle where a passerby will
				// inadvertently prick herself.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% does not discuss Norgorber, the Reaper of Reputation, which is the point of him. The rite is a prayer said inside a crowd, so quietly that nobody hears it -- and if you suspect somebody did, you follow them out and prick them with a poisoned needle. Where there is no crowd you dig a hole six inches deep, whisper into it, and bury the sound. It finishes the same way every time: a needle dipped and left where a stranger will find it with their hand.",
				Mottos = [
					"Bury the sound",
					"We do not discuss him",
					"Quietly enough that nobody hears",
					"Somebody heard",
					"A needle, and a windowsill",
					"The Reaper keeps his own ledger"
				]
			},
			{	// URGATHOA -- The Pallid Princess. NE. Scythe. Disease, gluttony, undeath.
				// Symbol: skull-decorated fly. Fly; red and green. Varisian.
				// Obedience: black velvet on a table, the best feast you can assemble, eat to
				// painful fullness with wine between dishes and prayer throughout. At the end,
				// eat one piece of something spoiled -- rotten fruit, rancid meat, mouldy
				// cheese -- and trust her to keep the sickness off you.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Tyrant,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% feasts for Urgathoa, the Pallid Princess, whose concerns are disease, gluttony and undeath, and who has never seen much difference between them. Black velvet on the table, the best of everything laid on the cloth, and you eat past full and go on eating, wine between the courses and prayers between the mouthfuls. Then, at the end, one bite of something spoiled -- rotten fruit, rancid meat, cheese gone green -- swallowed on the understanding that she will not let it hurt you. From %factionfortressname% they are always hungry and never ill.",
				Mottos = [
					"Always hungry, never ill",
					"Eat past full, and go on",
					"The last bite is the prayer",
					"The Pallid Princess does not stop",
					"Black velvet, and everything on it",
					"She will not let it hurt us"
				]
			},
			{	// LAMASHTU -- Mother of Monsters. CE. Falchion. Madness, monsters, nightmares.
				// Symbol: three-eyed jackal. Jackal; red and yellow. Demon.
				// Obedience (Deific): sacrifice an unwilling creature, drawn out to maximise
				// terror -- no clean death. Take a bone from the corpse, sharpen it, and cut
				// yourself deeply enough to scar. Leave the body in the open for scavengers or
				// travellers, so her power is known.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% belongs to Lamashtu, the Mother of Monsters, and her rite is a killing done slowly, because the terror is the offering and a clean death is a wasted one. When it is finished you take a bone out of what remains, sharpen it, and open your own skin with it deep enough to scar. The body stays where it fell, in the open, for the scavengers or for whoever comes along the road. From %factionfortressname% every one of them is marked, and every mark was somebody, and they will show you if you ask.",
				Mottos = [
					"Every mark was somebody",
					"The Mother takes what is hers",
					"A clean death is a wasted one",
					"Left where the road can see it",
					"She keeps her children",
					"Ask, and they will show you"
				]
			},
			{	// ROVAGUG -- The Rough Beast. CE. Greataxe. Destruction, disaster, wrath.
				// Symbol: fanged spider. Scorpion; brown and red. Monster.
				// Obedience: smash at least 10gp of goods -- fragile, beautiful, or holy to a
				// good deity by preference, PARTICULARLY Sarenrae. The devout hoard expensive
				// and rare things specifically to break them. Roll in the shards howling praise
				// and curses until they draw blood and your lungs ache.
				// Exact inverse of Shelyn: she makes small things and gives them away.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Warmonger,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% is sworn to Rovagug, the Rough Beast, who is not at liberty and whose faithful regard that as a temporary condition. They buy beautiful things -- good wine, fine glass, old carving, anything holy to Sarenrae by preference -- and they buy them specifically in order to break them, then roll in the pieces howling praise and curses until the shards draw blood and the lungs give out. From %factionfortressname% they keep a treasury that exists to be destroyed, and about the rest of it they are patient.",
				Mottos = [
					"A treasury that exists to be destroyed",
					"Not at liberty. For now.",
					"Buy it beautiful. Break it anyway.",
					"The Rough Beast is only waiting",
					"Roll in the pieces",
					"Sarenrae's, by preference"
				]
			}
,
			{	// ---- EXOTIC PANTHEON: gods a house REACHES for, past the Core 20. The pairing with
				// a runelord name carries more weight here -- these are chosen, not inherited.
				// Exotics MAY use the 5 trait pairs vanilla forbids (Sheriff+Warmonger,
				// Sheriff+Tyrant, Marauder+Sheriff, Schemer+Warmonger, Collector+Marauder): the
				// broken rule is the fingerprint of the off-map god. Documentation only, as ever.
				//
				// ACHAEKEK -- He Who Walks in Blood. LE. Sawtooth sabre. Assassinations, divine
				// punishment, the red mantis. Symbol: crossed mantis claws. Crimson mantis; red.
				// CANON FIX: he protects RIGHTFUL rulers (can't kill true gods -> won't kill anointed
				// kings) and slays those REACHING for ungranted power. Red Mantis of Mediogalti.
				// (Godsrain / Gorum-kill is 4724 AR, AFTER the ~4710-4715 setting window -- omitted.)
				// Obedience: meditate before a trophy taken from a contracted target, anointed
				// with a drop of your blood off a sawtooth sabre, then destroy it. No contract
				// yet? Cut your own right arm with the sabre (1d6, unhealed through the hour).
				// TRAITS: Sheriff+Warmonger -- a VANILLA-FORBIDDEN pair. Law delivered by the blade.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Warmonger
				],
				Description = "House %noblehousename% belongs to Achaekek, He Who Walks in Blood, the Mantis God -- and to understand the house you must first understand exactly what he is for. The other gods made him, in the first age, as an impartial judge to stand sentinel over creation; and when Rovagug went rampaging through the young world Achaekek consumed his own impartiality and came out the far side a red thing, all claw and appetite. What they kept him for was one task above all: to kill anyone reaching for a divinity they were not granted. He can slay a demigod or a risen sorcerer-king or any mortal climbing toward godhood -- but the gods, cunningly, built him unable to touch a true deity, so that the blade they forged could never be turned on them. From this comes the one law his people will not break: they never kill a rightful ruler. A crowned and anointed king is, to them, the gods' own agent and untouchable; it is the graspers, the usurpers, the ones reaching past their station for power that was never given, on whom the sentence falls. His faithful are the Red Mantis of far Mediogalti, and their work is not called murder but sentence, carried out with the sawtooth sabre and a professional detachment that takes no joy and offers no mercy. The rite is done over a trophy cut from a marked target, anointed with a drop of the killer's own blood off the blade, then destroyed; lacking a contract, the killer opens their own right arm with the sabre and lets it bleed the hour through. From %factionfortressname% they take their contracts the way a court takes its cases, and in a shattered age crowded with sorcerer-kings and half-made powers all reaching for what they have not earned, a house that serves the god who kills the ambitious has picked, of everything it could fly, the flag the climbers fear most.",
				Mottos = [
					"Not murder. Sentence.",
					"We do not touch a rightful crown",
					"The blade falls on those who reach too high",
					"He was made to kill the ambitious",
					"A trophy, and a drop of blood",
					"The climbers fear us most"
				]
			},
			{	// ARAZNI -- The Harlot Queen. NE. Rapier. Command of undeath, lichdom. Symbol:
				// rapier and lotus. Scarab; grey and red. Aroden's herald, killed by Tar-Baphon
				// in front of the crusade, raised a lich against her will, enslaved by Geb ~400y.
				// Obedience: spend an hour reliving terrible things done to you -- 1d6 nonlethal --
				// and let NO ONE know; speaking of it or showing distress negates it.
				// TRAITS: Sheriff+Tyrant -- VANILLA-FORBIDDEN. She has the Nobility domain: she RULES
				// the dead. Aroden is load-bearing here (his herald) -- one of the ~3 allowed uses.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% serves Arazni, the Harlot Queen, who was a herald of the age of prophecy before she was killed in front of the army that worshipped her, and raised again against her will, and passed hand to hand as a chattel for four hundred years. She rules the dead now and hates the living with a patience the living cannot imagine. Her rite is to sit for an hour and relive every wrong ever done to her, and to let no one see it. From %factionfortressname% they are courteous, immaculate, and keeping a list.",
				Mottos = [
					"Courteous, immaculate, and keeping a list",
					"She was a herald once",
					"Let no one see it",
					"Raised against her will, and remembering",
					"The Harlot Queen rules the dead now",
					"Every wrong, in order"
				]
			},
			{	// ZYPHUS -- The Grim Harvestman. NE. Heavy pick. Accidental death, graveyards,
				// tragedy. Symbol: pick-axe of bones. Vulture; ivory and red.
				// Obedience: sit an hour on the grave of one accidentally killed and vocally
				// reject the gods who let it happen. No grave? Sabotage a path, bridge, or tool
				// so it is dangerous for the next to use it.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% keeps Zyphus, the Grim Harvestman, god of the death that nobody intended -- the stair that gives way, the rope that parts, the ford that drowns a man on a calm day. Nobody is ever murdered in the lands of %factionfortressname%. There are only a great many accidents, more than the country roads elsewhere seem to suffer, and the faithful spend their devotions making certain of it: a sawn joist here, a loosened stone there, left for whoever comes next.",
				Mottos = [
					"Only a great many accidents",
					"Nobody is ever murdered here",
					"The stair that gives way",
					"Left for whoever comes next",
					"Chance wronged us first",
					"The Grim Harvestman takes the calm days too"
				]
			},
			{	// GROETUS -- God of the End Times. CN. Heavy flail. Empty places, oblivion, ruins.
				// Symbol: skull-faced moon. Hangs over Pharasma's Boneyard awaiting the last soul.
				// Obedience: preach the end to an unbeliever a full hour (find another if they
				// leave). No one to preach at? Sit an hour in a place no living thing has entered
				// in a month and deface the walls with a skull-like moon.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% waits with Groetus, the God of the End Times, the skull-faced moon that hangs over the Boneyard with nothing to do until the last soul has been judged and creation can finally be ground quiet. His faithful preach that ending to strangers, an hour a day, and where there is no one to preach at they sit in some emptied place no living thing has entered in a month and draw the moon on the walls. From %factionfortressname% they are calm, and unhurried, and certain, because they are the only ones who already know how it comes out.",
				Mottos = [
					"They already know how it comes out",
					"The moon is waiting",
					"Calm, unhurried, certain",
					"An hour a day, to anyone",
					"Nothing lives here now",
					"The End Times are not in a hurry"
				]
			},
			{	// APSU -- The Waybringer. LG. Bite or quarterstaff. Good dragons, leadership, peace.
				// Symbol: silver dragon above a pool. Metallic colours. Dragon. The ONLY LG exotic.
				// Obedience: walk 30 min one way cataloguing terrain and tactical advantage; then
				// retrace it, seeing only the beauty, praising him that any of it exists.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% keeps Apsu, the Waybringer, the first of the good dragons, who made the roads and the peace to travel them on. Twice a day the faithful walk out in a straight line: once studying the ground for every advantage a fight might turn on, and once back over the same country seeing only how beautiful it is, and thanking him that any of it exists at all. From %factionfortressname% they are the rarest thing the shattering left -- a house that means you no harm and can prove it.",
				Mottos = [
					"Once for the fight, once for the beauty",
					"The Waybringer made the roads",
					"We mean you no harm, and can prove it",
					"Every advantage, and every grace",
					"The rarest thing the shattering left",
					"Walk it twice"
				]
			},
			{	// GRUHASTHA -- The Keeper. LG. Shortbow. The Vudrani holy book (the Vudra scripture).
				// Symbol: mandala of four open books at the compass points. Vudrani.
				// Obedience: spend an hour teaching someone to read or improving their learning;
				// or study under a better teacher; or, failing both, make an educational text to
				// donate to a school or library.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% follows Gruhastha, the Keeper, who lived inside a book until he understood every word of it and then became a god of the reading itself. His rite is an hour spent teaching someone their letters, and where there is no student, an hour making a primer to leave at a school. While the other houses answered the broken age with walls and knives, %factionfortressname% answered it with a schoolroom, and holds -- against most of the evidence -- that a world that can still read can still be argued out of the dark.",
				Mottos = [
					"A world that can still read",
					"The Keeper lived inside the book",
					"We answered it with a schoolroom",
					"Letters, against the dark",
					"Teach one, then another",
					"Against most of the evidence"
				]
			},
			{	// SIVANAH -- The Seventh Veil. N. Bladed scarf. Illusions, mystery, reflections.
				// Symbol: veils tied in a circle. Coyote; grey. Nationality unknown (fittingly).
				// Obedience: walk a settlement openly, greet someone; at its edge veil your face
				// and speak to them again; if recognised, DENY it and give a false name.
				// TRAITS: Schemer+Schemer collapses -- use Schemer+Marauder (envoys who are not
				// the envoys who left).
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% is said to serve Sivanah, the Seventh Veil, goddess of illusion and reflection and the secret worth keeping -- though nobody outside its walls is entirely certain the house is there at all, or ever was. She wears seven veils, and the first six are each a different ancestry -- human, elf, halfling, and stranger things beneath -- while the seventh and last hides a face no worshipper has seen and lives; her true shape is that seventh, unknown thing, and she lets no one confirm it. She does not speak to her faithful in words but through mirrors, still water, and a person's own shadow, so that an instruction is never quite something anyone can prove was given. The rite honours this: veil the face, work an illusion beautiful enough to be believed, and then -- for her law forbids leaving a soul deceived forever -- let it fall, so the trick is known for a trick. From %factionfortressname%, if it is even called that, envoys arrive who are not quite the envoys who left, and treaties are signed that afterward no one can produce, and it is all, they assure you, exactly as it appears. They loathe Zon-Kuthon, who took the honest dark and made it a place of pain, and they alone keep faith with mad Razmir of Razmiran, the false god down the road -- for the Seventh Veil may be the only power in the world who looks at his imposture and sees, under the seventh veil of it, something real.",
				Mottos = [
					"Exactly as it appears",
					"You must be mistaking us",
					"The Seventh Veil is never lifted",
					"We were never the first one",
					"Treaties nobody can find",
					"It is all a reflection"
				]
			},
			{	// BESMARA -- The Pirate Queen. CN. Rapier. Piracy, sea monsters, strife.
				// Symbol: skull and crossbones. Parrot; black and white. Kellid.
				// Obedience: steal a gold coin or a drink by force or trick; toast Besmara loudly
				// enough for the loser to hear; throw the prize into water at least 4 feet deep.
				// TRAITS: Collector+Marauder -- VANILLA-FORBIDDEN. A house that breaks her land-
				// anathema by existing. Anathema: settle on land / betray crew / forsake piracy.
				// History: ascended by devouring rival spirits; still preys on minor gods.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Collector,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% flies Besmara's colours, the Pirate Queen, the Sea Banshee, Sailor's Doom -- and lives every day in breach of her first and plainest law. She commands her own to never settle on land, to keep faith with captain and crew above all, and to take whatever is not lashed down; and here the house sits, behind stone walls, holding ground, apostate from the hour it laid the first foundation. They square it the only way the creed leaves open. They do not govern the land so much as raid it from a fortress that might as well have run aground -- loyal absolutely to their own, faithless to everyone else, keeping no treaty one hour past the moment it stops paying. Her rite is small and exact: take a coin or a cup by force or by trick, toast her name loud enough that the one you took it from can hear, and drop the prize into deep water as her share, since everything is finally hers. What should trouble the neighbours is not the raiding but the goddess behind it. Besmara was no god once, only a spirit of the water that could call the sea's monsters up from below; she climbed to divinity by making war on the spirits of battle and gold and wood and swallowing them whole, and she has never stopped being hungry -- she hunts smaller gods still, looking for the next to absorb. In a shattered age crowded with half-made and nascent powers, that is no idle flag to fly, and the house that flies it has picked, knowingly, the side of the thing that eats the others.",
				Mottos = [
					"Never settle on land -- and yet",
					"Faith to captain and crew, first and last",
					"We do not hold the land, only bleed it",
					"Apostates since the first foundation stone",
					"Her share goes over the side",
					"The Pirate Queen eats smaller gods"
				]
			},
			{	// NOCTICULA -- The Redeemer Queen. CN. Dagger. Artists, exiles, midnight. Symbol:
				// moon with smirking lips and a seven-pointed crown. Bat; blue and white. A demon
				// lord of murder who redeemed HERSELF and ascended -- the only one who ever has.
				// Obedience: spend an hour alone at or around midnight making a work of art.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% keeps Nocticula, the Redeemer Queen, who was a demon lord of murder and assassins for an age of the world and then did the thing no demon had ever done -- put it down, and walked out, and took up the exiles and the artists instead. Her rite is an hour making something beautiful, alone, at midnight. From %factionfortressname% they take in whoever the other houses have cast out, and they do not talk about what any of them were before, because she of all powers has earned the right not to ask.",
				Mottos = [
					"She put it down and walked out",
					"The Redeemer Queen does not ask what you were",
					"Made beautiful, alone, at midnight",
					"Whoever the others cast out",
					"No demon had ever done it",
					"Come as you are now"
				]
			},
			{	// GHLAUNDER -- The Gossamer King. CE. Spear. Infection, parasites, stagnation.
				// Symbol: mosquito in profile. Mosquito; light grey and red. Hatched from a wound
				// a healer should have left closed. Urgathoa's crueller cousin.
				// Obedience: make a poppet of a biting insect from straw, blood and filth; dry it
				// an hour applying leeches and reciting affliction; burn poppet and leeches and
				// inhale the smoke.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% carries Ghlaunder, the Gossamer King, hatched from a wound that a kind healer should have left alone, god of the infection and the stagnant pool and the thing that gets into the blood. His rite mixes blood and filth into a poppet shaped like a biting insect, dries it while the leeches feed, and burns it to breathe the smoke. From %factionfortressname% they open their gates wide to the sick and the fevered, tend them with real tenderness, and send them home again carrying what they came in with, and more.",
				Mottos = [
					"Sent home with more than they came in with",
					"The Gossamer King got into the blood",
					"We tend them tenderly",
					"A wound the healer should have left alone",
					"Open the gates to the sick",
					"And more"
				]
			},
			{	// GYRONNA -- The Angry Hag. CE. Dagger. Extortion, hatred, spite. Symbol: bloodshot
				// eye. Black cat; pink and white. Kellid. Worshipped at an eye scratched on a stone.
				// Obedience: spend 30 min making one creature's life measurably worse (ruin
				// property, foul medicine, steal loan money); the victim must survive and must
				// know it was you; name a price to make it stop, which need not be fair.
				// TRAITS: Schemer+Warmonger -- VANILLA-FORBIDDEN. Spite that escalates to open ruin.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Warmonger
				],
				Description = "House %noblehousename% serves Gyronna, the Angry Hag, goddess of the grudge that never cools, worshipped by scorned women and bitter men at a single bloodshot eye scratched into a standing stone. Her rite is to spend an hour making one chosen life measurably worse -- ruin the crop, foul the medicine, lose the loan money -- then make sure the victim knows exactly who did it, and name a price to make it stop that does not have to be fair. From %factionfortressname% everything is for sale, especially mercy, and the rate is whatever hurts most.",
				Mottos = [
					"Especially mercy",
					"The price need not be fair",
					"She knows exactly who did it",
					"The grudge that never cools",
					"One bloodshot eye on the stone",
					"Pay, or it gets worse"
				]
			}
,
			{	// MAMMON -- The Argent Prince. LE. Shortspear. Avarice, watchfulness, wealth.
				// Symbol: devil-faced coin. Rat; gold and silver. Archdevil. Once Asmodeus's
				// champion; now his own hollow corpse in a diamond coffin in a vault of 13,001
				// gem-chests. Obedience: shake a purse of >=6 coins reciting exactly how you got
				// each, declare it all for Mammon's glory, then lay them in a pentagram on a mirror.
				// The archdevil the pool was waiting for -- deal him House Karzoug (Runelord of Greed).
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Collector,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% serves Mammon, the Argent Prince, who was a champion of Hell before avarice ate him hollow and left him a beautiful corpse in a diamond coffin at the centre of a vault nobody is permitted to spend. His rite is to shake a purse and account aloud for every coin in it -- earned, stolen, however it came -- then lay the coins in a pentagram on a mirror. From %factionfortressname% they keep the most exacting books in the world, and they will remind you that the Argent Prince watches his wealth even in death, and never once blinks.",
				Mottos = [
					"He watches it even in death",
					"Account for every coin",
					"A beautiful corpse in a diamond coffin",
					"The Argent Prince never blinks",
					"Nobody is permitted to spend it",
					"The books are exact"
				]
			},
			{	// BELIAL -- The Pale Kiss / Duke of Many Forms / Lord of the Fourth. LE archdevil,
				// Phlegethon. Ranseur. Adultery, deception, desire. Symbol: two-toned devil mask.
				// CANON: Asmodeus's creation -- 1st attempt (subjective shapeshift) a locked-away
				// horror; 2nd (controls own shape + persuasive tongue) = Belial. Becomes whatever
				// the viewer desires; shifts form/species/gender; leaves half-fiends everywhere.
				// Default form split angelic/hideous. Obedience: 13 drops of the body in water.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% belongs to Belial, the Pale Kiss, the Duke of Many Forms, Lord of the Fourth -- and to know the house you must know how he was made. Before the great betrayal Asmodeus set out to build the most desirable being in all creation, and his first attempt, a thing that reshaped itself into the deepest wish of everyone who looked at it, came out a heaving insane horror he keeps locked away to this day. He tried again, and gave the second the power to command its own shape and a tongue that could talk anyone into anything, and named that success Belial. So the Duke of Many Forms is desire itself given control of its own face: he shifts form and species and gender to become whatever the one before him most wants, and leaves half-fiend children of every description behind him wherever he has been. His true shape no one but Asmodeus has seen; the face he wears among the other archdevils is split down the middle, one half shining and angelic, the other scarred and malformed as the ugliest thing in Hell. His rite fouls clean water with thirteen drops of the body, holds in the mind the single most desirable thing imaginable, and drinks the ruined cup to the bottom. From %factionfortressname% the envoys are charming, and beautiful, and never once the same face twice -- because that is precisely what their master is -- and every arrangement they offer is generous, and every one of them costs you something you did not know you had agreed to put on the table, for the house serves the god who becomes your wish in order to own you by it.",
				Mottos = [
					"He becomes your wish, then owns you by it",
					"Never the same face twice",
					"Asmodeus made him to be desired",
					"Every generous offer has a hidden line",
					"The Duke of Many Forms is what you want",
					"You agreed to more than you knew"
				]
			},
			{	// MAEHA -- The Father of False Words. LE. Net. Abduction, isolation, propaganda.
				// Domains Darkness/Evil/Law/Void. Asura Rana. Exact inverse of Gruhastha.
				// Obedience: don the guise of a NONEVIL priest and spend an hour proselytizing
				// while handing out POISONED food to the poor.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% follows Maeha, the Father of False Words, an asura of abduction and isolation and the lie told at scale. His worship is the cruellest small thing in the pool: put on the robes of a kindly priest of some gentle god, go among the poor, and spend the hour preaching comfort and handing out food you have poisoned. From %factionfortressname% the grain arrives in hard winters and the sermons are gentle and the missing are never quite accounted for, and the people love them, which is the entire point.",
				Mottos = [
					"The people love them. That is the point.",
					"The grain arrives in hard winters",
					"A kindly priest of some gentle god",
					"The missing are never quite accounted for",
					"The lie told at scale",
					"Comfort, and poison"
				]
			},
			{	// CHUGARRA -- The Guru of Butchers. LE. Handaxe. Blood, butchers, leather.
				// Domains Death/Evil/Law/War. Asura Rana -- ground up through a hundred lifetimes
				// of the trade. Gluttony-adjacent: appetite rationalised into calm industry.
				// Obedience: butcher an animal, OR work at crafting a leather garment. That is all.
				// TRAITS: Collector+Marauder -- VANILLA-FORBIDDEN. Provision and slaughter, one trade.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Collector,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% keeps Chugarra, the Guru of Butchers, an asura that ground its way up through a hundred lifetimes of the trade until it came out the other side a demigod of blood and meat and leather. There is nothing dramatic about the worship. You butcher an animal, cleanly, the way you were taught, or you work a hide until it is soft, and that is the whole of it. From %factionfortressname% they supply the tables of half the region and the tanneries of all of it, and they will tell you a thing only becomes useful once it has stopped being alive.",
				Mottos = [
					"Useful once it has stopped being alive",
					"Nothing dramatic about it",
					"Cleanly, the way you were taught",
					"We supply half the region",
					"Blood, meat, and leather",
					"A hundred lifetimes of the trade"
				]
			}
,
			{	// ---- DAEMON HARBINGERS: Abaddon's advisor-daemons. Not archdevils (bargains) nor
				// demon lords (appetite) -- daemons are ENTROPY that wants you specifically dead,
				// made intimate. All NE. This tier tilts the pool grim; counterweight later with
				// good exotics (Lissala LN, Aroden, good Empyreal Lords) if rebalancing.
				//
				// AESDURATH -- The Pale Dowager. NE. Dagger. Immortality, liches, magical
				// catastrophes. Symbol: crystal skull. Crow; crystal and white. The god of the
				// specifically-Thassilonian death: killed when the magic went wrong.
				// Obedience: eat a portion of a being killed by magic.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% serves Aesdurath, the Pale Dowager, a daemon of Abaddon who took immortality, liches and the deaths that magic causes as her portfolio and her pride. Her rite is the simplest kind of communion: eat a portion of something killed by a spell, and take a little of that unmaking into yourself. From %factionfortressname% they have outlived their own founders and most of their heirs, and they will tell you, patiently, that everything the shattering broke was only ever going to break, and that the trick is to be the thing that does not.",
				Mottos = [
					"Be the thing that does not break",
					"The Pale Dowager outlived her own cult",
					"It was always going to break",
					"Eat a little of the unmaking",
					"We buried our founders long ago",
					"Patiently, and forever"
				]
			},
			{	// LAIVATINIEL -- The Chains and the Cradle. NE. Light crossbow. Anxiety, coddling,
				// unhealthy parental love. Symbol: rattle wrapped in chains. Bear; black and brown.
				// The most domestic horror in the pool: love that smothers, that will not let go.
				// Obedience: spend an hour making a detailed portrait of your mother or father,
				// then eat it.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% belongs to Laivatiniel, the Chains and the Cradle, whose sign is a child's rattle bound in iron and whose concern is the love that does not let go. Her rite is to spend an hour making a careful likeness of your mother or your father, and then to eat it. In %factionfortressname% the children are cherished past all reason and never permitted to leave, the doors are kind and locked, and every heir is loved so completely and so close that by the time they might have ruled there is nothing left of them to do it.",
				Mottos = [
					"The doors are kind, and locked",
					"Loved past all reason",
					"The Chains and the Cradle never let go",
					"No heir of ours need ever leave",
					"Cherished until there is nothing left",
					"Stay. Stay. Stay."
				]
			},
			{	// SLANDRAIS -- The Watcher in the Walls. NE. Shortbow. Lechery, love potions,
				// obsession. Symbol: smoking pink potion. Goat; brown and pink. The stalker-god;
				// obsession that does not stop at death.
				// Obedience: sleep on the grave, or beside the corpse, of someone you knew alive.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps Slandrais, the Watcher in the Walls, daemon of lechery and love-philtres and the wanting that curdles into obsession. His rite is to sleep the night on the grave, or beside the corpse, of someone you knew while they lived. From %factionfortressname% they do not forget a face they have once wanted, in life or after it, and they are watching more of the region than the region suspects, and the thing they feel while they watch is not quite love and has never once been mistaken for kindness.",
				Mottos = [
					"Not quite love, and never kindness",
					"The Watcher forgets no face",
					"Wanted, in life or after it",
					"We are watching more than you think",
					"It does not stop at the grave",
					"Sleep beside what you wanted"
				]
			}
,
			{	// ---- DEMON LORDS: the Abyssal aristocracy. All CE -- appetite and ruin as rulership.
				// BAPHOMET -- Lord of the Minotaurs. CE. Glaive. Beasts, labyrinths, minotaurs.
				// Symbol: brass minotaur head. Aurochs; gold and red. He holds ALDERPASH's lich
				// in the Ivory Labyrinth -- deal him a Wrath house (Alderpash/Angothane/etc) and
				// jailer and jailed share a banner.
				// Obedience: sit motionless 55 min, then speak 50 observations of your
				// surroundings into a hollowed bull's horn.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% keeps Baphomet, Lord of the Minotaurs, demon of beasts and labyrinths and the mind that loses its own thread. His rite is to sit without moving for the better part of an hour and then speak fifty separate observations of the room around you into a hollowed bull's horn, so that the walls are numbered and cannot close on you. In %factionfortressname% the corridors do not go where you expect, the plan of the place is known to nobody living, and guests who wander are not always seen again -- which the house calls the god keeping what is his.",
				Mottos = [
					"The god keeps what is his",
					"Number the walls before they close",
					"No living soul holds the plan",
					"The corridors do not go where you expect",
					"Lord of the Minotaurs owns the maze",
					"Some guests wander"
				]
			},
			{	// DESKARI -- Lord of the Locust Host. CE. Scythe. Chasms, infestations, locusts.
				// Symbol: bloody locust wings. Locust; green and red. Tore open the Worldwound.
				// Obedience: meditate letting vermin crawl on you; lacking any, lie facedown in
				// a dug trench mouthing prayers into the dirt while scratching yourself with bone.
				// TRAITS: Marauder+Sheriff -- VANILLA-FORBIDDEN. The swarm that patrols a border.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.Sheriff
				],
				Description = "House %noblehousename% belongs to Deskari, Lord of the Locust Host, the demon who opens the ground and lets the swarm pour through. His worship is to lie still and let the vermin walk on you, or, lacking them, to lie facedown in a dug trench and pray into the soil while you score your own skin with bone. From %factionfortressname% they treat the land itself as a thing to be hollowed and eaten, and where their border has stood a while the fields go strange, and the wells taste of something, and the neighbours have started counting their children at dusk.",
				Mottos = [
					"Counting their children at dusk",
					"The ground opens where he wills",
					"The land is a thing to be eaten",
					"Let the vermin walk on you",
					"Lord of the Locust Host is hungry",
					"The wells taste of something now"
				]
			},
			{	// MESTAMA -- The Mother of Witches. CE. Punching dagger. Cruelty, deception, hags.
				// Symbol: eye on three sharp stones. Black widow; black and red.
				// Obedience: observe a nonbeliever for an hour, unseen if you can, then perform an
				// act of cruelty on them sufficient to incite tears or anger.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% serves Mestama, the Mother of Witches, demon of cruelty and deception and the covens that traffic in both. Her rite is patient: watch someone who does not follow her, unseen, for a full hour, and then do the one small exact thing that will break them into tears or fury. From %factionfortressname% the house knows the private wound of everyone who matters for a hundred miles, offers each of them nothing but sympathy to their faces, and picks, very precisely, when to press.",
				Mottos = [
					"The one small exact thing",
					"She knows your private wound",
					"Sympathy to your face",
					"The Mother of Witches watches first",
					"Very precisely, when to press",
					"Every coven, one purpose"
				]
			},
			{	// NOCTICULA (ELDER) -- Our Lady in Shadow. CE. Hand crossbow. Assassins, darkness,
				// lust. Symbol: thorny pointed crown. Bat; black and pink. This is the DEMON LORD
				// she was BEFORE ascending -- the CN 'Redeemer Queen' in the exotic block is the
				// same being after. The setting's cleanest self-rivalry: deal both to one map.
				// Obedience: psychedelics + acts of the body during which >=1 pint of blood is shed.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% keeps Nocticula as she was before she climbed out of it -- Our Lady in Shadow, demon of assassins and darkness and appetite, and every murder done unseen. Her rite mixes drugged visions, the acts of the body, and a pint of shed blood into one long dark hour. From %factionfortressname% the killers go out quiet and come back quieter, and somewhere on the same map, if the world has dealt it so, another house keeps the queen she managed to become -- and neither the Lady in Shadow nor the Redeemer will say which of them is the lie.",
				Mottos = [
					"Which of them is the lie",
					"Our Lady in Shadow was here first",
					"The killers come back quieter",
					"Before she climbed out of it",
					"Every murder done unseen",
					"She became something. This is what she left."
				]
			},
			{	// ORCUS -- Prince of Undeath. CE. Heavy mace. Death, necromancy, wrath. Symbol:
				// four-horned goat head. Goat; ivory and red.
				// Obedience: grind half a pound of bone from a sentient skeleton, mix to grey
				// paste with water, eat it at the end of an hour's prayer.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Tyrant,
					::Const.FactionTrait.Warmonger
				],
				Description = "House %noblehousename% is sworn to Orcus, Prince of Undeath, demon of death and necromancy and the wrath that outlives the body. His rite grinds half a pound of bone from a thinking creature's skeleton, stirs it to grey paste with water, and eats it at the end of an hour's prayer. From %factionfortressname% the dead do not stay down and are not meant to -- they hold the walls, work the fields, and fill the ranks, and the living of the house are outnumbered by their own ancestors, which they consider only proper.",
				Mottos = [
					"Outnumbered by their own ancestors",
					"The dead do not stay down",
					"The Prince of Undeath fills the ranks",
					"They hold the walls and work the fields",
					"Wrath outlives the body",
					"Which they consider only proper"
				]
			},
			{	// XOVERON -- The Horned Prince. CE. Ranseur. Gargoyles, gluttony, ruins. Symbol:
				// five-horned gargoyle skull. Boar; black and brown.
				// Obedience: perch on a high outcrop and hold still an hour; in an inhabited place,
				// anyone who realises you are alive must be slain before the hour is out.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% keeps Xoveron, the Horned Prince, demon of gargoyles and gluttony and the slow patience of ruins. His rite is to perch high over the land and hold perfectly still for an hour -- and in a town, where a watcher might be noticed, anyone who realises the gargoyle is alive must be dead before the hour is out. From %factionfortressname% they hold the high broken places nobody else wants, they wait without any sign of impatience, and they are always, always looking down at you.",
				Mottos = [
					"Always looking down at you",
					"The Horned Prince does not hurry",
					"Hold still until the hour is out",
					"We keep the high broken places",
					"Anyone who notices does not last",
					"Patience, and stone"
				]
			}
,
			{	// ---- THE ELDEST: archfey lords of the First World. Fairy-tale logic, not Abyssal
				// appetite -- and the pool's counterweight after 15 evil exotics/fiends: N, CN, CN.
				// THE LOST PRINCE -- The Melancholy Lord. N. Quarterstaff. Forgotten things,
				// sadness, solitude. Symbol: crumbling black tower. Raven; black and grey.
				// Inverse of Pharasma (keeps every soul) and Aesdurath (eats to remember).
				// Obedience: write down a memory you have never used for this and never told
				// anyone, then burn it.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps the Lost Prince, the Melancholy Lord, an Eldest of the First World whose realm is a black tower falling slowly to pieces and whose concern is everything anyone has ever let themselves forget. His rite is quiet and costs something real: write down a memory you have never told a soul and have never burned before, and burn it now. In %factionfortressname% the archives are vast and full of gaps, the family keeps no grudges because it keeps no history, and there are rooms in the house that even the eldest of them cannot quite remember the purpose of.",
				Mottos = [
					"It keeps no grudges, and no history",
					"Write it down. Burn it.",
					"The Melancholy Lord forgets you kindly",
					"Rooms nobody remembers the purpose of",
					"The tower falls slowly to pieces",
					"Every memory, and then none"
				]
			},
			{	// COUNT RANALC -- The Traitor. CN. Rapier. Betrayal, exiles, shadows. Symbol: eye
				// with crescent-moon pupil weeping one black tear. Bat; black and grey. An Eldest
				// exiled from the First World's court. Rhymes with Nocticula (exiles), Calistria
				// (the grudge). Obedience: sit in shadow, whisper the name of one you mean to
				// betray or who betrayed you, and what you intend to do about it.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% serves Count Ranalc, the Traitor, an Eldest cast out of the First World's court for a betrayal nobody now agrees the shape of, whose sign is an eye weeping a single black tear. His rite is to sit in shadow and whisper the name of one you mean to betray, or who betrayed you, and precisely what you intend to do about it. From %factionfortressname% they gather every exile and turncoat the other houses have cast off, keep each one's grievance filed and sharpened, and are loyal, absolutely, right up until the hour it stops being worth it.",
				Mottos = [
					"Loyal until it stops being worth it",
					"The Traitor was cast out first",
					"Every exile has a use",
					"Filed, and sharpened",
					"Whisper it to the shadow",
					"Nobody agrees the shape of it"
				]
			},
			{	// THE LANTERN KING -- The Laughing Lie. CN. Dagger. Laughter, mischief,
				// transformation. Symbol: golden lantern of coloured lights. Firefly; black and
				// gold. Mightiest and least trustworthy of the Eldest -- treats world-ending as a
				// punchline. Obedience: light a small lantern and tell it a joke or the story of a
				// prank you played -- a DIFFERENT one every time.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% follows the Lantern King, the Laughing Lie, mightiest and least trustworthy of the Eldest, who finds the whole of creation funny and reserves the right to rearrange any part of it for a better joke. His rite is to light a small lantern and tell it a jest, or the tale of a prank you once played -- a new one every time, for he has heard the old ones. From %factionfortressname% the laughter carries a long way after dark, the envoys arrive wearing faces that are not their own, and nobody who has dealt with the house is entirely sure the deal has finished being funny.",
				Mottos = [
					"Not sure the deal has finished being funny",
					"A new joke every time",
					"The Laughing Lie has heard the old ones",
					"Faces that are not their own",
					"The laughter carries after dark",
					"He rearranges it for a better joke"
				]
			}
,
			{	// ---- EMPYREAL LORDS: the celestial tier. The good counterweight -- LG/LG/NG/CG/CG,
				// five archons against the fiends. Each is the good-aligned answer to a dark power.
				// NESHEN -- Knight of the Steel Lash. LG. Ranseur. Penitence, repentance,
				// suffering. Symbol: coiled steel lash. Ram; iron grey and red. NO printed
				// obedience (Empyreal Lords often lack the full block) -- written from concept:
				// penance paid openly and freely, the honest reckoning. Good mirror of Zon-Kuthon.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% serves Neshen, the Knight of the Steel Lash, an angel of penitence who holds that a wrong is not undone by feeling sorry for it but by paying it back in full, in the open, where the wronged can see. His faithful keep the lash for their own backs and no one else's -- the suffering is owed, not inflicted -- and they will kneel in the square and name what they did before they ask any pardon. From %factionfortressname% they forgive freely and excuse nothing, least of all themselves.",
				Mottos = [
					"Pay it back in the open",
					"The lash is for our own backs",
					"Forgive freely, excuse nothing",
					"Name it before you ask pardon",
					"The Knight of the Steel Lash keeps the account",
					"Sorry is not enough"
				]
			},
			{	// RAGATHIEL -- General of Vengeance. LG. Bastard sword. Chivalry, duty, vengeance.
				// Symbol: sword crossed with wing. Mastiff; crimson and gold. Half-fiend son of a
				// Horseman who chose the light. Good answer to Gorum AND Calistria.
				// Obedience: slay a PROVEN wrongdoer in his name -- evil intent is not enough, the
				// deed must be done -- and never past what the crime is worth.
				// Code: 'Rage is a virtue only when focused against the deserving.'
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Warmonger
				],
				Description = "House %noblehousename% swears to Ragathiel, the General of Vengeance, half-fiend son of a Horseman who chose the light and became an angel of wrath aimed only at the guilty. His rite requires a wrongdoer proven -- not merely evil-hearted but caught in the deed -- put to death in his name, and never one drop past what the crime is worth. From %factionfortressname% they hunt the deserving with terrible patience, take no innocent with the guilty, and hold that mercy and the sword are the same duty seen from two sides.",
				Mottos = [
					"Never past what the crime is worth",
					"The guilty, and only the guilty",
					"Rage focused is a virtue",
					"He chose the light",
					"Mercy and the sword, one duty",
					"Proven, then punished"
				]
			},
			{	// SORALYON -- The Mystic Angel. NG. Heavy pick. Guardians, magic, monuments.
				// Symbol: rune-covered spire. Guard dog; grey and purple. Owns New Thassilonian
				// Magic and the Runeguard -- the angel who PRESERVES the runelords' works. The
				// single most on-setting deity for a Thassilon mod.
				// Obedience: carry a 5lb marble miniature of a real monument, trace it by touch
				// before sleep, meditate on it until you drift off.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps Soralyon, the Mystic Angel, guardian of monuments and old magic, who alone among the powers of light looks on the works the runelords left and sees not a horror to be pulled down but a wonder to be kept standing. His rite is to carry a small marble likeness of some real monument and trace its every surface by touch before sleeping. From %factionfortressname% they guard the ancient stones nobody else will go near, read the runes without flinching, and hold that a thing built to last was built for a reason worth remembering.",
				Mottos = [
					"A thing built to last was built for a reason",
					"Keep it standing",
					"The Mystic Angel does not flinch at runes",
					"We guard the stones nobody will approach",
					"Read them without fear",
					"Worth remembering"
				]
			},
			{	// ASHAVA -- True Spark. CG. Bladed scarf. Dancers, lonely spirits, moonlight.
				// Symbol: dancing woman and moon. Wolf; midnight blue and silver. She comforts
				// ghosts -- the tender inverse of every undeath god in the pool.
				// Obedience: dance alone under the moon; if moonless or witnessed, pray for the
				// lonely dead and leave a lit lantern in a dark place.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.ManOfThePeople,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps Ashava, the True Spark, an azata of moonlight who dances for the lonely dead so that no spirit need be alone in the dark. Her rite is a dance under the open moon, and where there is no moon, or where someone is watching, a prayer for the forgotten dead and a single lit lantern left in a dark place. From %factionfortressname% they tend the graves the other houses let go to weeds, sit with the dying who have no one, and leave a light burning in every window every night, for whoever is still out there.",
				Mottos = [
					"A light in every window",
					"No spirit alone in the dark",
					"She dances for the forgotten dead",
					"We sit with those who have no one",
					"Leave a lantern",
					"For whoever is still out there"
				]
			},
			{	// VALANI -- Fireshaker. CG. Club. Change, growth, primal forces. Symbol: volcano
				// with gold lava. Dinosaur; brown and gold. Destruction AS renewal -- the good
				// version of Rovagug's smashing (he breaks to make room; Rovagug just breaks).
				// Obedience: burn an item worth 50+gp, roll in the cinders to put it out, grind
				// the ash into the earth. Choose an energy type each time.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% follows Valani, the Fireshaker, an azata of change and primal growth who teaches that nothing is ever truly lost, only turned into the next thing. His rite is to burn something of real worth, then roll in the cooling cinders to put out the last of it and grind the ash into the earth, so that the fire feeds what grows after. From %factionfortressname% they welcome the storm, plant in the burn-scar, and hold -- alone among the houses, and against everything the shattering seemed to prove -- that the world ending was only the world beginning again.",
				Mottos = [
					"The world ending was the world beginning",
					"Nothing is lost, only turned",
					"Plant in the burn-scar",
					"The Fireshaker welcomes the storm",
					"Burn it, then grow it",
					"Against everything the shattering proved"
				]
			}
,
			{	// ---- Further fiends. The pool leans evil by design: this is a post-cataclysm Inner
				// Sea, and evil is what a desperate house REACHES for when the world is ending. The
				// Core good gods are always in rotation; these dark tiers are the additions.
				// (Farfarello, Lord of the Forgotten, was CUT here -- his portfolio (forgotten
				//  things / dead antiquity / mists) is covered better by the Lost Prince, Pharasma
				//  and Aesdurath, and his obedience was the one dud.)
				//
				// TREERAZER -- Lord of the Blasted Tarn. CE. Greataxe. Corruption of nature,
				// pollution. Symbol: axe in a bleeding stump. Deinonychus; black and green. CANON:
				// squats in Tanglebriar corrupting Kyonin's forest. Anti-Gozreh, anti-Erastil.
				// Obedience: eat carrion riddled with hallucinogenic/poison fungus, meditate on the visions.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Marauder,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% is sworn to Treerazer, the Lord of the Blasted Tarn, a demon squatting so long in one wood that the wood became him -- nature turned inside out, sap to poison, green to rot. His rite is to eat carrion riddled with hallucinogenic fungus and sit with the visions it brings. From %factionfortressname% the corruption spreads outward at the pace of a slow tide: the trees at the edge of their land die standing, the game comes back wrong, and the border can be found in the dark by the smell alone. They are not conquering the country. They are digesting it.",
				Mottos = [
					"They are digesting the country",
					"Sap to poison, green to rot",
					"The border can be found by smell",
					"Lord of the Blasted Tarn spreads slowly",
					"The game comes back wrong",
					"Not conquest. Digestion."
				]
			},
			{	// NIGHTRIPPER -- The Promise of Pain. CE. Bastard sword. Botched executions, pits.
				// Symbol: knife-fingered bone hand. Trap-door spider; black and red. The god of
				// the execution that FAILS -- procedural horror, distinct from all other cruelty gods.
				// Obedience: a series of cuts on the flesh while periodically auto-asphyxiating.
				// TRAITS: Sheriff+Tyrant -- VANILLA-FORBIDDEN. Law as deliberate slow cruelty.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% keeps Nightripper, the Promise of Pain, demon of the execution that goes wrong on purpose -- the drop that does not break the neck, the blade that stops halfway. Its rite is a patient series of cuts, breath held to the edge of blacking out between them. In %factionfortressname% there is a great deal of law and a great deal of sentencing, and the sentences are carried out slowly, in public, by people who are very good at making sure they take a long time, because the point was never the death.",
				Mottos = [
					"The point was never the death",
					"The drop that does not break the neck",
					"A great deal of law, slowly applied",
					"The Promise of Pain is kept",
					"They are very good at taking their time",
					"In public, and unhurried"
				]
			},
			{	// NERGAL -- The Slow Death. LE. Spiked chain. Atrocity, pestilence, war. Symbol: sun
				// rising over a battlefield. Jackal; black and tan. Infernal Duke. Cold bureaucratic
				// opposite of Gorum (the JOY of battle): war as administration.
				// Obedience: mix volatile chemicals, smash them at your feet, pray.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Warmonger,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% serves Nergal, the Slow Death, an infernal duke whose sign is the sun coming up over a field of the dead, and whose concern is atrocity done properly and filed in triplicate. War, to Nergal, is not fury -- it is administration, and plague is only a slower campaign. From %factionfortressname% they wage their wars like clerks: the burned village is a line in a ledger, the poisoned well a scheduled task, and every horror is somebody's assigned duty, discharged on time and without malice, which is the worst of it.",
				Mottos = [
					"Every horror is somebody's duty",
					"War is administration",
					"On time, and without malice",
					"The sun comes up over the dead",
					"Plague is a slower campaign",
					"Filed in triplicate"
				]
			},
			{	// FURCAS -- Knight of the Laurels. LE. Trident. Duty, flames, herbalism. Symbol:
				// flaming pitchfork. Snake; red and yellow. Infernal Duke -- a devil APOTHECARY,
				// with a Slavery subdomain. The healer whose cure indentures you.
				// Obedience: mix a herbal salve/draught, use half yourself, burn the other half.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Tyrant
				],
				Description = "House %noblehousename% keeps Furcas, the Knight of the Laurels, an infernal duke of duty and flame who is also, of all things, a healer -- and whose cures come with terms. His rite mixes a herbal draught, drinks half, and burns the rest. From %factionfortressname% the sick are genuinely made well: the physicians are skilled, the medicine works, and the price is written into the recovery, so that a man walks out cured and finds himself, by degrees he never quite agreed to, belonging to the house that saved him.",
				Mottos = [
					"Cured, and accounted for",
					"The medicine works. So do the terms.",
					"You walk out well, and ours",
					"The price is in the recovery",
					"Duty, flame, and a good salve",
					"By degrees you never quite agreed to"
				]
			},
			{	// MURNATH -- The Horned Rat. CE. Short sword. Rats, sewers. Symbol: horned rat with
				// long tail. Rat; brown and grey. Nascent Demon Lord. Fur+Metal+Caves subdomains =
				// the UNDERCITY as a power structure. The house founded by cutthroats who came up
				// from the sewers, took a fortress and noble names, and still run the tunnels.
				// (Sczarni / River-Kingdoms-bandit-throne logic.)
				// Obedience: meditate while floating in sewage or similar filth.
				// TRAITS: Collector+Marauder -- VANILLA-FORBIDDEN. The racket under the crown.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Collector,
					::Const.FactionTrait.Marauder
				],
				Description = "House %noblehousename% will not say it serves Murnath, the Horned Rat, but the oldest families of %factionfortressname% came up out of the undercity long ago, took a fortress, took names, and never once stopped running the tunnels beneath it. His rite is to float in the filth of the sewers and pray. The banner is respectable now. The knives are not, the tunnels go everywhere the walls pretend to stop, and the house was there before the city and is still, quietly, underneath all of it.",
				Mottos = [
					"Underneath all of it",
					"We were here before your walls",
					"The banner is respectable now",
					"The tunnels go everywhere",
					"The Horned Rat rules the drains",
					"Quietly, and everywhere"
				]
			}
,
			{	// ---- MONITORS: outsiders of pure alignment, neither fiend nor celestial. The pool's
				// final note -- LN/CN/N, closing the tilt back down.
				// KERKAMOTH -- The Waiting Void. LN. Warhammer. Emptiness, entropy, stillness.
				// Symbol: starry circle in an iron ring. Primal Inevitable -- lawful entropy, NOT
				// Rovagug's rage or Groetus's doom. Governs by subtraction.
				// Obedience: spend an hour clearing a cluttered space, removing at least half of
				// its contents to keep, donate, or destroy.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Sheriff,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps Kerkamoth, the Waiting Void, an inevitable of stillness and entropy who is not cruel and not in any hurry, because everything comes to him in the end regardless. His rite is to take a cluttered place and empty it -- clear out half of everything, to keep or give or destroy, until what remains can be seen whole. From %factionfortressname% they govern by subtraction: fewer laws, fewer courtiers, fewer possessions each year, on the principle that the world is quietly returning to the empty and the wise meet it halfway.",
				Mottos = [
					"Govern by subtraction",
					"Everything comes to him regardless",
					"Meet the empty halfway",
					"Fewer laws, fewer courtiers, each year",
					"The Waiting Void is not in a hurry",
					"Clear it until it can be seen whole"
				]
			},
			{	// NARRISEMINEK -- The Crownless, the Maker of Kings. CN. Handaxe. Ascendance,
				// keketars, revelations. Symbol: imentesh head wreathed in flame. Protean Lord --
				// pure chaos and transformation. Raises others to thrones, wears no crown himself.
				// Sharp irony for a mod built on noble houses.
				// Obedience: stand inside a ring of fire (>=5ft out) chanting until it burns to
				// coals or the smoke harms you.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% follows Narriseminek, the Crownless, the Maker of Kings, a protean of pure chaos and revelation who raises others to thrones and wears no crown of their own. Their rite is to stand inside a ring of fire and chant until it burns down to coals. From %factionfortressname% they crown and counsel and elevate, put other houses' heirs on other houses' seats and whisper the future in their ears, and hold nothing in their own name -- which makes them, in a shattered age hungry for a king, quietly the most dangerous house on the map.",
				Mottos = [
					"He makes kings and wears no crown",
					"We hold nothing in our own name",
					"The most dangerous house on the map",
					"Crown them, counsel them, keep nothing",
					"The Crownless whispers the future",
					"Someone must make the king"
				]
			},
			{	// PHLEGYAS -- The Consoler of Atheists. N. Longbow. Atheists, legacies,
				// reincarnation. Symbol: two circles overlapping vertically. Psychopomp Usher --
				// tends those who died believing in nothing. Opposite of the undeath gods: not
				// raising the dead, making them MEAN something to the living.
				// Obedience: spend an hour making something lasting from the dead -- jewellery
				// from hair, bone or teeth; or embalm/mummify the corpse.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.ManOfThePeople,
					::Const.FactionTrait.Collector
				],
				Description = "House %noblehousename% keeps Phlegyas, the Consoler of Atheists, an usher of the dead who tends especially to those who died believing in nothing at all, and asks only that the living make something lasting of them. His rite is an hour spent turning the dead into a thing that endures -- a ring woven from a loved one's hair, a name cut in stone, a law written to outlast its author. From %factionfortressname% they keep the memory of everyone who mattered and much of what they built, and hold that a person is not truly gone while the work still stands.",
				Mottos = [
					"Not gone while the work still stands",
					"He consoles those who believed in nothing",
					"Make something lasting of the dead",
					"A name cut in stone",
					"The Consoler asks only that they endure",
					"Hair, and stone, and law"
				]
			}
,
			{	// VEVELOR of the Broken Dream -- velstrac demagogue, demigod. LE. Whip. Illusion of
				// freedom, potential, transcendence. Symbol: bloody broken chain. Subdomains
				// Freedom/Revolution/Slavery/Torture -- the irony is built in. Realm Cliffgrip,
				// Netherworld, beside the Deeping Darkness where Zon-Kuthon re-emerged. THE KUTHITE
				// HERESY: preaches freedom/self-chosen exaltation where Zon-Kuthon preaches joy in
				// servitude; focused on Nidal, tolerated-but-blasphemous to the orthodox. Written as
				// the rival shadow-cult to a Zon-Kuthon house. Obedience: a wound taken willingly,
				// dwelt in, pain named as a door. TRAITS: Schemer+ManOfThePeople -- the false liberator.
				Traits = [
					::Const.FactionTrait.NobleHouse,
					::Const.FactionTrait.Schemer,
					::Const.FactionTrait.ManOfThePeople
				],
				Description = "House %noblehousename% keeps Vevelor of the Broken Dream, a velstrac demagogue older than the shadow-kind's exile from Hell, whose realm of Cliffgrip sits at the lip of the same chasm the Midnight Lord climbed out of -- for Vevelor is Zon-Kuthon's neighbour, and his heretic. Where the Midnight Lord preaches an honest joy in servitude, Vevelor preaches freedom: he was mortal once and chose to be remade, and he will show you the path to your own perfection whether or not you ever asked to see it. His symbol is a broken chain, and that is the whole trick of him, because his concern is not freedom but the illusion of it -- the convert walks in believing they are casting off every bond and walks out having chosen, freely and gratefully, a heavier one. His rite is a wound taken willingly and dwelt in, the pain named aloud as a door rather than a hurt, until the flesh agrees. From %factionfortressname% they speak the language of liberation to everyone the age has broken -- the dispossessed, the enslaved, the ruined -- and they mean by it the exact opposite of what is heard, and where their preaching runs up against a house that keeps the Midnight Lord straight, the two cults of the shadow loathe each other with the particular venom kept only for a heresy, for they use the same needles and the same dark and cannot agree what any of it is for.",
				Mottos = [
					"Freedom is the trick, not the offer",
					"You will choose a heavier chain, and thank us",
					"The Midnight Lord's neighbour, and his heretic",
					"We speak liberation and mean its opposite",
					"The broken chain is the whole of it",
					"The same needles -- a different lie"
				]
			}
		]
	];
	::logInfo("Golarion: pantheon loaded, " + ::Const.GetFactionArchetypesList().len() + " god archetypes (set the Legends 'Factions' setting to at most this many)");


	// ==================== Mercenary companies: the nations that fell ====================
	// Reuse of the 41 Inner Sea NATIONS displaced from NobleHouseNames (now runelords).
	// In a post-cataclysm Inner Sea a mercenary band named for a nation is what's LEFT
	// when that nation dies -- the company IS the country now. Two variants per nation:
	// a remnant (the people) and an outfit (the business). 82 total, all unique, no clash
	// with the runelord house names.
	//
	// LOAD-ORDER NOTE: Legends does `FreeCompanyNames <- clone MercenaryCompanyNames` in
	// !config/strings.nut BEFORE our mod runs, so the clone is already taken. We must set
	// BOTH pools explicitly, or roaming Free Companies keep the old Legends names.
	// Both are EXISTING keys by the time we run -> assign with `=`.
	::Const.Strings.MercenaryCompanyNames = [
		"The Last Legion of Cheliax",
		"Company of Cheliax",
		"Sons of Old Taldor",
		"The Taldan Blades",
		"The Last Andorans",
		"Free Company of Andoran",
		"Sons of Nidal",
		"The Nidalese Shadows",
		"The Grey Gardeners\' Orphans",
		"Free Company of Galt",
		"The Broken Swords of Brevoy",
		"Brevic Free Lances",
		"The Molthuni Levy",
		"Company of Molthune",
		"The Nirmathi Woodsmen",
		"Sons of Nirmathas",
		"The Prophets\' Guard",
		"Company of Druma",
		"The Isgeri Chain",
		"Sons of Isger",
		"Ustalav\'s Own",
		"The Ustalavic Watch",
		"The Numerian Salvagers",
		"Company of Numeria",
		"The Last Crusaders of Mendev",
		"The Mendevian Cross",
		"The Living God\'s Faithful",
		"Company of Razmiran",
		"The Kyonin Exiles",
		"The Elfgate Wardens",
		"Daughters of Irrisen",
		"The Irriseni Frost",
		"The Hold-Breakers",
		"Company of Belkzen",
		"The Varisian Wanderers",
		"Sons of Varisia",
		"The Free Ravounel",
		"Company of Ravounel",
		"The Last of the Wall",
		"Sentinels of Lastwall",
		"The Qadiran Freeriders",
		"Company of Qadira",
		"The Osirian Tomb-Guard",
		"Sons of Osirion",
		"The Thuvian Caravan",
		"Company of Thuvia",
		"The Godless of Rahadoum",
		"The Rahadoumi Free",
		"The Heirs of Nex",
		"Company of Nex",
		"The Gebbite Dead",
		"Sons of Geb",
		"The Sargavan Colonials",
		"Company of Sargava",
		"The Oprak Hobgoblins",
		"The Oprak Legion",
		"The Jalmeri Masters",
		"Company of Jalmeray",
		"The Hermean Exiles",
		"Sons of Hermea",
		"The Iobarian Riders",
		"Company of Iobaria",
		"The Red Mantis Cast-Offs",
		"The Mediogalti Blades",
		"The Heirs of Thassilon",
		"Sons of Thassilon",
		"The Sarkoris Reclaimers",
		"The Lost Sarkorians",
		"The Katapeshi Free Company",
		"Company of Katapesh",
		"The Pitax Free Blades",
		"Company of Pitax",
		"The Daggermark Poisoners",
		"Sons of Daggermark",
		"The Gralton Reclaimers",
		"Company of Gralton",
		"The Mivon Swordlords",
		"Sons of Mivon",
		"The Tymon Gladiators",
		"Company of Tymon",
		"The Masked of Vyre",
		"Company of Vyre"
	];
	::Const.Strings.FreeCompanyNames = clone ::Const.Strings.MercenaryCompanyNames;
	::logInfo("Golarion: " + ::Const.Strings.MercenaryCompanyNames.len() + " mercenary companies loaded (nations that fell)");

	// ==================== The southern powers: city-state archetypes ====================
	// SEPARATE table from FactionArchetypes, and it behaves differently: createCityStates
	// does `foreach (i, a in Const.CityStateArchetypes)` -- NOT a random draw. So the
	// LENGTH OF THIS ARRAY IS THE NUMBER OF CITY-STATES ON THE MAP. Three entries, three
	// cities, always. (Banner is i+12, indexed by position.) The NAMES still rotate via
	// CityStateNames with a do/while dedup, so which city serves which power changes every
	// campaign -- but unlike the noble houses, all three powers always appear.
	//
	// That asymmetry is the fiction, not a limitation. Up north prophecy broke and the
	// churches took the thrones, so which faith holds a fortress is a different roll in
	// every possible Inner Sea. The south is older than that and did not change.
	//
	// These three are deliberately NOT gods. A rakshasa immortal that made itself immortal
	// by being purely evil; a sahkil that eats fear; a Horseman. One LE, one CE, one NE.
	// The DLC6 Holy War crisis (GreaterEvilType.HolyWar) sets north against south -- noble
	// houses against city-states -- so with this split it stops being a war between faiths
	// and becomes a war about whether the southern powers are gods at all. That is what
	// makes it holy.
	//
	// Traits MUST keep OrientalCityState: unlike the noble personality traits, this one is
	// actually read -- escort_caravan_contract.nut:1108 and send_caravan_action.nut:74 both
	// branch on faction.hasTrait(OrientalCityState). Do not add or remove traits here.
	// %citystatename% is the live placeholder here (NOT %noblehousename%). No colour tags.
	::Const.CityStateArchetypes = [
		{	// PRIHASTA -- The General Between Heaven and Hell. LE. Kukri. Rakshasa Immortal.
			// Areas of Concern: N/a -- rakshasa immortals have no portfolio; each is
			// concerned only with its own glory. Domains Animal/Evil/Law/Trickery;
			// subdomains Deception, Fear, Fur, Tyranny.
			// Obedience: speak honeyed words into a righteous creature's ear with the
			// intent of poisoning its virtue with your evil.
			Traits = [
				::Const.FactionTrait.OrientalCityState
			],
			Description = "The ministers of %citystatename% answer to Prihasta, who is not a god and has never bothered to claim otherwise. The General Between Heaven and Hell was a rakshasa that made itself immortal by being patiently, thoroughly evil, and its power now approaches that of the gods it says it already outranks. It holds no portfolio and teaches no doctrine. Its worship is to find someone good and talk to them -- praise first, then sympathy, then a reasonable suggestion, and another, until the virtue has gone out of them and they cannot recall having agreed to anything. The city is not ruled. It is persuaded.",
			Mottos = [
				"The city is not ruled. It is persuaded.",
				"A reasonable suggestion, and then another",
				"Prihasta outranks what it has not yet met",
				"We only ever talked to you",
				"Honeyed words, patiently applied",
				"You agreed to this"
			]
		},
		{	// HATAAM -- The River Eater. CE. Net. Sahkil Tormentor.
			// Areas of Concern: drought, drowning, stagnation. Domains Evil/Travel/Water/
			// Weather; subdomains Fear, Rivers, Sahkil, Seasons, Storms.
			// Obedience: dam a small stream or another source of flowing water.
			Traits = [
				::Const.FactionTrait.OrientalCityState
			],
			Description = "%citystatename% keeps Hataam, the River Eater, who is no god but a sahkil -- a thing that eats fear, and found that thirst is the most patient fear there is. His worship is a dam. Any dam, any stream, the smaller the better, built for no reason except that afterwards the water has stopped. The city sits above the water and sells it back down, and its engineers walk out each spring with rope and sluice-gate to make the argument again. Upstream they call it a tithe. Downstream, where the wells went dry and the herds died standing up, they call it what it is.",
			Mottos = [
				"All water is borrowed",
				"Thirst is a patient argument",
				"The River Eater is never full",
				"We hold the water. We do not take it.",
				"Upstream calls it a tithe",
				"Every valley drinks, or learns"
			]
		},
		{	// THE FOUR HORSEMEN (APOCALYPSE RIDERS) -- NE archdaemons of Abaddon, not gods.
			// One city-state ruled as a TETRARCHY OF ENDINGS: four ministries, one per Rider.
			//   Trelmarixian the Black -- Famine (Wasting)   | ledgers, granaries
			//   Szuriel               -- War (Cinder Furnace) | armouries, levies
			//   Apollyon              -- Pestilence (Plaguemere)| physicians, wells
			//   Charon, the Boatman   -- Death (River Styx)   | first among them, eldest Rider,
			//                            only Rider of Death since daemonkind began. Toll/coin motif.
			// Seeded rumor: the BOUND PRINCE, the forbidden fifth Rider, buried beneath the city.
			// Symbol: four pale horses on black. (Charon's own: skull with coins on eyes, pale green.)
			// %regionname% PROVEN DEAD in-game (v0.76 probe): rendered '=><=', empty. All three
			// resolve sites pass "" -- vanilla faction_manager:472 (city-states), :569 (nobles),
			// and Legends' hook. Overhype stubbed it and never wired it. Never use it.
			// Obedience: meditate on your infirmities and the slow inevitable decay of
			// time, and mimic it -- immerse yourself or a victim in icy water until nearly
			// unconscious, or take drink or drugs that dull memory and mind.
			Traits = [
				::Const.FactionTrait.OrientalCityState
			],
			Description = "%citystatename% is not ruled by one hand but by four, and none of them living. Its masters serve the Apocalypse Riders whole -- the Four Horsemen of Abaddon, archdaemons who are no gods but divide between them every way a world can end -- and the city is governed as they are, as a tetrarchy of endings. Four ministries sit above all others, and each answers to a different Rider. The ledgers and the granaries answer to Trelmarixian the Black, Rider of Famine, who teaches that a city is ruled most cheaply through what it is permitted to eat. The armouries and the levies answer to Szuriel, Rider of War, whose furnace never cools. The physicians and the quarantines -- and, quietly, the wells -- answer to Apollyon, Rider of Pestilence, who decides which sickness is allowed in and which is kept out. And over all of them, first among the four as he is the eldest Rider and the only one to hold his title since daemonkind began, stands the ministry of Charon, the Boatman, Rider of Death, whose black river takes a toll from everyone and whose ferry is never refused. The four do not love one another and are not required to; the city works precisely because famine, war, plague and death are, in the end, one business with four desks. Its officers learn their masters' patience early -- some study decay in black water until the dark comes up behind the eyes -- and its gates take a coin from everyone, living or dead, in or out. They fly four pale horses on a black field, and speak, when they are drunk and unwise, of a fifth Rider bound and buried somewhere beneath the city, greater than the four, whose ministry has no desk because his ending has not yet been permitted to arrive.",
			Mottos = [
				"One business, four desks",
				"Every ending has its ministry",
				"A coin from everyone, in or out",
				"Famine, war, plague, and the Boatman last",
				"The four need not love one another",
				"The fifth has no desk -- yet"
			]
		}
	];
	::logInfo("Golarion: city-state powers loaded, " + ::Const.CityStateArchetypes.len() + " (== the number of city-states on the map)");

	// ==================== Personal names (Golarion, weighted) ====================
	// Names sorted by Kodi Arfer's Pathfinder compilation (Inner Sea World Guide +
	// Archives of Nethys). Humans up-weighted vs non-humans via HSHARE below.
	local gNMale = [
		"Aerodus", "Akorian", "Akrem", "Alamander", "Alexite", "Alezandaru", "Andrezi", "Arioch",
		"Barek", "Belor", "Birger", "Dines", "Dolok", "Doritian", "Dortlin", "Dron", "Eilif",
		"Ellismus", "Erodel", "Eudonius", "Eugeni", "Gabradon", "Ganef", "Gannak", "Garidan",
		"Gellius", "Grachius", "Gruckalus", "Gurog", "Hargev", "Henric", "Holg", "Hyglak",
		"Iacobus", "Illsmus", "Iogorian", "Ionacu", "Iozif", "Ixiolander", "Jokum", "Kazallin",
		"Kjell", "Kriger", "Krojun", "Kronug", "Lurconarr", "Manius", "Marcellano", "Marduzi",
		"Menas", "Morvius", "Narsius", "Nonek", "Olhas", "Olytrius", "Origen", "Ostarian",
		"Ostog", "Othollo", "Pavo", "Pellius", "Petronicus", "Ragnar", "Roga", "Rutilus",
		"Shadfrar", "Silvui", "Skender", "Solangus", "Sterk", "Stichilo", "Svalk", "Takek",
		"Tallak", "Theodric", "Tiberiu", "Udhomar", "Ureste", "Ursion", "Vachedi", "Varg",
		"Viorec", "Vors", "Xantrian", "Zandu", "Zoresk", "Zstelian"
	];
	local gNFemale = [
		"Adula", "Ahalak", "Aliandara", "Alika", "Alinza", "Amesducias", "Anca", "Annik",
		"Asmodia", "Aspexia", "Asta", "Aswaithe", "Aula", "Belende", "Belka", "Beshkee",
		"Bordana", "Boudra", "Carmelizzia", "Chammady", "Charito", "Dagny", "Dagur", "Drulia",
		"Emalliandra", "Estrude", "Eudomia", "Euphemi", "Fesha", "Gerda", "Gunda", "Hege",
		"Iaome", "Ileosa", "Ilinica", "Imenda", "Imperia", "Ingirt", "Inkit", "Iolana",
		"Iomestria", "Ionnia", "Jalket", "Jorun", "Kala", "Kale", "Komana", "Korva", "Lesit",
		"Luminita", "Mirelinda", "Nalket", "Nalmida", "Narcizia", "Nicinniana", "Noravia",
		"Novennia", "Ommarra", "Oviento", "Pasara", "Pavanna", "Piousa", "Pontia", "Quinta",
		"Rulla", "Runa", "Salvianella", "Selka", "Shelen", "Signe", "Tanjah", "Tekrakai", "Tine",
		"Udarrin", "Ulionestria", "Valeria", "Valki", "Varka", "Vibia", "Viniana", "Xemne",
		"Yala", "Yavenee", "Zeldana", "Zova", "Zriorica"
	];
	local gSMale = [
		"Aakif", "Akkuya", "Amare", "Arasmes", "Bahram", "Bala", "Barid", "Dadshi", "Dahrehn",
		"Darvan", "Hava", "Ik-Teshup", "Irizati", "Jaali", "Jawara", "Jirani", "Jiri", "Khair",
		"Kito", "Kobad", "Krama", "Manujyestha", "Melaku", "Omari", "Ormizd", "Parumartish",
		"Pratavh", "Rani", "Rubani", "Rusmanya", "Sefu", "Sumna", "Warezana", "Xoshak", "Yantur",
		"Zahur", "Zuri"
	];
	local gSFemale = [
		"Abha", "Akina", "Amara", "Amestri", "Artazostra", "Ashia", "Barezata", "Deka", "Eshe",
		"Hasina", "Hema", "Hirati", "Isa", "Iuni", "Izora", "Jayazi", "Jini", "Kahina",
		"Kamaria", "Khismia", "Kyra", "Leyli", "Malkia", "Naadhira", "Nanya", "Nigana", "Pendah",
		"Raziya", "Revhi", "Sahba", "Sajna", "Shirin", "Utana", "Vilama", "Waajida", "Xemestra",
		"Zaci", "Zalika", "Zarishu"
	];
	local gNorseF = [
		"Annik", "Asta", "Belende", "Belka", "Dagny", "Dagur", "Fesha", "Gerda", "Gunda", "Hege",
		"Ingirt", "Inkit", "Jalket", "Jorun", "Kala", "Lesit", "Nalket", "Runa", "Selka",
		"Shelen", "Signe", "Tine", "Valki", "Varka", "Yala"
	];
	local gNHMale = [
		"Abroshtor", "Adesha", "Aerel", "Agiz", "Aja", "Ak", "Akaash", "Alk", "Amarandlon",
		"Andanan", "Antal", "Aoukar", "Arasheg", "Arcavato", "Arim", "Aritian", "Arkkak",
		"Arkus", "Aronok", "Ashka", "Ashpaka", "Athraz", "Ausk", "Aven", "Bankanir", "Barashk",
		"Baru", "Bastarger", "Beltin", "Bokker", "Boram", "Bouzaglu", "Brihz", "Calondrel",
		"Carangal", "Carrug", "Carruth", "Cavathes", "Cernan", "Chichipi", "Chimon", "Chuko",
		"Crinto", "Cronwier", "Davor", "Dellisar", "Denat", "Dharak", "Djir", "Dolgra",
		"Dolgrin", "Dorduken", "Dorodara", "Dorsavnil", "Drewan", "Drosil", "Drovic", "Duardlon",
		"Dyrtrax", "Edal", "Edrukk", "Efit", "Eitsanara", "Elum", "Elun", "Encinal", "Enshuk",
		"Eomva", "Eran", "Erevel", "Espes", "Essaru", "Eydan", "Fazij", "Felaelrel", "Felzak",
		"Fentanas", "Ferrus", "Ferus", "Firyin", "Frum", "Garija", "Gerran", "Ghiv", "Gishkim",
		"Gorumax", "Gouard", "Grunyar", "Grur", "Grytnok", "Guln", "Guzmuk", "Haangeno",
		"Hagors", "Hakak", "Hakon", "Halhat", "Halungalom", "Hamako", "Hanuun", "Haohiko",
		"Harsk", "Hasa", "Hazi", "Heldalel", "Huanu", "Igmar", "Ikyamek", "Ilamin", "Inishish",
		"Iradli", "Izkrael", "Jalij", "Jamash", "Jamir", "Jaraerdrel", "Jegan", "Jekkajak",
		"Jeydavu", "Kaelmourn", "Kaidynn", "Kakkariel", "Kaleb", "Kalmant", "Kana", "Karum",
		"Kaya", "Kazmuk", "Keegyn", "Kirrok", "Kitsukou", "Kizziar", "Kon", "Kora", "Krajasik",
		"Kremernesh", "Krobby", "Krolmnite", "Kutak", "Kuwana", "Kwan-la", "Kyras", "Lanliss",
		"Lem", "Liek", "Lirtae", "Loohi", "Losk", "Lumrolur", "Maakor", "Makoa", "Maldrek",
		"Malgroar", "Maqej", "Marrak", "Maudril", "Mazmord", "Meirdrarel", "Mentys", "Meotrai",
		"Merlokrep", "Mirn", "Mirrendier", "Molos", "Morgrym", "Mossarah", "Murdut", "Nammem",
		"Narinso", "Narnel", "Narrin", "Nasha", "Nassaler", "Neeka", "Neg", "Nesteruk", "Ninnec",
		"Nulrakgrult", "Nydryn", "Nyktan", "Nyktox", "Odol", "Okrin", "Omgot", "Ondir", "Onok",
		"Oret", "Otoniel", "Padrym", "Parant", "Paravata", "Passag", "Pharnox", "Poshment",
		"Prabur", "Pularrka", "Quiray", "Quokgol", "Radid", "Ranzak", "Rarorel", "Rerdahl",
		"Rickle", "Rikkan", "Rocur", "Rogar", "Roprutu", "Rouqar", "Ruk", "Ruun", "Ryzztyl",
		"Sarvin", "Sarzuket", "Satinder", "Seldlon", "Seltyiel", "Sevastin", "Sheni",
		"Shiradahz", "Shoremoth", "Shukuris", "Shulkuru", "Siival", "Sithundan", "Skivven",
		"Slatark", "Somar", "Sorsul", "Stigmar", "Sumak", "Syrendross", "Tak-Tak", "Takasha",
		"Talaro", "Talathel", "Talogan", "Tamoq", "Tasi", "Temerith", "Tenzekil", "Tespa",
		"Thathona", "Tizkar", "Tongtokl", "Torphrex", "Troxell", "Truddig", "Tsadok",
		"Tsukotarra", "Tup", "Tural", "Turenne", "Ulu", "Unglert", "Unulu", "Urah", "Urtar",
		"Utakish", "Variel", "Varknarnost", "Varrann", "Vasaam", "Vaski", "Vivatu", "Voren",
		"Vreknog", "Wakla", "Woiak", "Wyran", "Xahndyg", "Xurshuklo", "Yetar", "Yonk", "Yonsol",
		"Yulbin", "Zaigan", "Zakkar", "Zathra", "Zatqualmie", "Zelkekek", "Zibini", "Zirul",
		"Zithembe", "Zoka", "Zokaratz", "Zordlon", "Zoren", "Zov"
	];
	local gNHFemale = [
		"Acera", "Adesha", "Afzara", "Agna", "Ahmmra", "Ak", "Alayi", "Allizsah", "Alyara",
		"Amelisce", "Amrunelara", "Anafa", "Anjaz", "Arasheg", "Arinet", "Arken", "Arkkak",
		"Arsinoe", "Ashka", "Ashpaka", "Ava", "Azzlyn", "Baarah", "Bani", "Barashk", "Bellis",
		"Belmarniss", "Besh", "Bessel", "Besthana", "Bodill", "Bokker", "Butoi", "Calah",
		"Cannan", "Cathlessra", "Cathran", "Chandira", "Chichipi", "Chuko", "Crinto",
		"Cylellinth", "Dalbra", "Dardlara", "Davina", "Dei", "Dolgra", "Dorodara", "Drinma",
		"Drogeda", "Duline", "Durra", "Eandi", "Echane", "Eireen", "Eitsanara", "Elneth",
		"Eloqi", "Emraeal", "Enga", "Enshuk", "Eomva", "Erigga", "Eskani", "Espes", "Essaru",
		"Etun", "Etwa", "Faunra", "Ferrus", "Fhar", "Fijit", "Filiu", "Frum", "Gant", "Garija",
		"Ghatiyara", "Giama", "Gishkim", "Gonild", "Goruza", "Grillgiss", "Grymwyr", "Guzmuk",
		"Gynnezz", "Haangeno", "Halhat", "Hamako", "Haohiko", "Hasa", "Hazi", "Horinnia", "Hoya",
		"Huanu", "Iandoli", "Ikyamek", "Ilvaria", "Ilyat", "Ilyin", "Imdlara", "Imesah", "Inam",
		"Indranna", "Ingra", "Inishish", "Inva", "Irice", "Iryani", "Jathal", "Jilyana", "Jix",
		"Johysis", "Jynnjun", "Kakkariel", "Kana", "Kasidra", "Kaya", "Keeya", "Kieyanna",
		"Kifah", "Kilarra", "Kitch", "Kitsukou", "Komtri", "Kon", "Kora", "Korumun", "Kregnaan",
		"Krobby", "Krugga", "Kubi", "Kutak", "Kuwana", "Kwan-la", "Leffit", "Liada", "Lim",
		"Lini", "Lirtae", "Lissa", "Lissi", "Loohi", "Lorceli", "Loscivia", "Lupp", "Lyrtrahk",
		"Maarin", "Maddeva", "Majet", "Maqan", "Maraedlara", "Marra", "Marrak", "Masozi",
		"Mazmord", "Mazon", "Mellisan", "Melrynn", "Meotrai", "Merisiel", "Mihalyi", "Milah",
		"Miniri", "Moranassa", "Mordren", "Moritla", "Morstra", "Mossarah", "Nadkarni",
		"Nahmias", "Nammem", "Nasha", "Nava", "Neeka", "Nefi", "Nehm", "Nijena", "Nimanisi",
		"Niramour", "Nisha", "Noranillim", "Nordlara", "Nylgune", "Nysene", "Olbin", "Omgot",
		"Onana", "Ondrea", "Onok", "Oparal", "Pai", "Paldna", "Pantoja", "Paravata", "Pari",
		"Pashe", "Petrahk", "Piria", "Praeldral", "Pularrka", "Qari", "Queck", "Radabeh",
		"Radaya", "Ranzak", "Rarorel", "Reda", "Renza", "Rhialla", "Rickle", "Rilla", "Rissi",
		"Roprutu", "Ruk", "Rusilka", "Ruun", "Ryzzntyg", "Rzonca", "Sami", "Saroun", "Sevastin",
		"Shalelu", "Sheni", "Shirish", "Shulkuru", "Siphelele", "Sistra", "Skyxa", "Sophone",
		"Sorsul", "Soumral", "Stinna", "Sucheta", "Suzhen", "Tak-Tak", "Takasha", "Talaro",
		"Tamarie", "Tasi", "Tena", "Tespa", "Tessarda", "Tevaga", "Thathona", "Thikka", "Tiyeri",
		"Tizkar", "Torra", "Trin", "Trisgrak", "Tsukotarra", "Tup", "Tyrrell", "Tyvorhan",
		"Ulrikka", "Ulu", "Ulumbralya", "Unulu", "Urdahna", "Urriona", "Utakish", "Vaga",
		"Valtyra", "Varaera", "Varshez", "Vaski", "Vivatu", "Volundeil", "Vortiga", "Vregma",
		"Wakla", "Yalandlara", "Yamyra", "Yangrit", "Yonk", "Yonsol", "Yulbin", "Zaitherin",
		"Zakkar", "Zarrnyl", "Zathra", "Zeljka", "Zelkekek", "Zetaya", "Zheit", "Zibini",
		"Zokaratz"
	];
	local HSHARE = 0.8;   // fraction of recruits with human names (tune this)
	local function gBlend(human, nonhuman) {
		local k = 1;
		if (human.len() > 0)
			k = (((HSHARE / (1.0 - HSHARE)) * nonhuman.len()) / human.len() + 0.5).tointeger();
		if (k < 1) k = 1;
		local a = [];
		for (local i = 0; i < k; i++) a.extend(human);
		a.extend(nonhuman);
		return a;
	}
	::Const.Strings.CharacterNames           = gBlend(gNMale,   gNHMale);
	::Const.Strings.CharacterNamesFemale     = gBlend(gNFemale, gNHFemale);
	::Const.Strings.CharacterNamesFemaleNorse= gBlend(gNorseF,  gNHFemale);
	::Const.Strings.SouthernNames            = gBlend(gSMale,   gNHMale);
	::Const.Strings.SouthernFemaleNames      = gBlend(gSFemale, gNHFemale);
	// ==========================================================================

	::mods_hookExactClass("entity/world/settlements/legends_steppe_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.SteppeVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_steppe_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.SteppeFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_mountains_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.MountainsFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_coast_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.CoastFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_fishing_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.FishingVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_mining_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.MiningVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_forest_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.ForestFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_lumber_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.LumberVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_swamp_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.SwampFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_swamp_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.SwampVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_snow_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.SnowVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_snow_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.SnowFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_tundra_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.TundraVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_tundra_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.TundraFort; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_farming_village", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.FarmingVillage; }
	});
	::mods_hookExactClass("entity/world/settlements/legends_farm_fort", function(o) {
		local create = o.create;
		o.create = function() { create(); this.m.Names = clone ::GolarionNames.FarmFort; }
	});

	// ==========================================================================
	//  Cult forces (for the Black Forks contract, and reusable for any cult site)
	// ==========================================================================
	// Names + titles the champion rolls when makeMiniboss() fires on it.
	// NOTE: `<-` (create slot), NOT `=` (assign to existing slot). These are NEW
	// keys, so `=` throws "the index 'SkvCultNames' does not exist" at load. The
	// CityStateNames/NobleHouseNames overrides above correctly use `=` because
	// those keys already exist in vanilla. Same rule Legends itself follows
	// (character_names.nut: `.TitleList <- null` for new, `.Variant = 1` for existing).
	::Const.Strings.SkvCultNames  <- [
		"Yannic", "Ysandra", "Corvin", "Delenah", "Ostarian", "Vibia",
		"Ureste", "Piousa", "Marduzi", "Aswaithe", "Zoresk", "Iomestria"
	];
	::Const.Strings.SkvCultTitles <- [
		"the Tender", "Mouth of the Pool", "the Hollow", "the Silent",
		"of the Depths", "the Drowned Voice", "who does not speak"
	];

	// A champion-capable cultist troop: same EntityType.Cultist, but pointed at
	// our leader actor and Variant 200 -> makeMiniboss() always fires -> guaranteed
	// champion_racial buff + a rolled name+title. (Non-invasive: a NEW type, so
	// ordinary cultists elsewhere are untouched.)
	::Const.World.Spawn.Troops.SkvCultChampion <- {
		ID        = ::Const.EntityType.Cultist,
		Variant   = 200,
		Strength  = 30,
		Cost      = 30,
		Row       = 0,
		Script    = "scripts/entity/tactical/humans/skv_cult_champion",
		NameList  = ::Const.Strings.SkvCultNames,
		TitleList = ::Const.Strings.SkvCultTitles
	};

	// The night cult: a GUARANTEED champion leader (Fixed) with an auto-scaling
	// militia->mercenary retinue (Guards), plus a body of cultists (Troops pool).
	// scale = budget / MaxR, and the caller scales budget by getScaledDifficultyMult(),
	// so the retinue climbs the ladder with company strength.
	::Const.World.Spawn.GolarionCult <- {
		Name = "GolarionCult",
		IsDynamic = true,
		MovementSpeedMult = 1.0,
		VisibilityMult = 1.0,
		VisionMult = 1.0,
		Body = "figure_civilian_03",
		MaxR = 600,   // budget at "fully escalated" (scale -> 1.0)
		MinR = 80,    // floor: even a weak company faces a small escort
		Fixed = [
			{
				Type = ::Const.World.Spawn.Troops.SkvCultChampion,
				Cost = 30,
				Weight = 0,                 // guaranteed leader, deduped from the pool
				MinGuards = 1,
				MaxGuards = 4,
				MaxGuardsWeight = 40,       // 1 guaranteed guard + up to 3 more @40% each
				Guards = [
					{   // TIER 1 - Militia: common when weak, gone when strong
						Type = ::Const.World.Spawn.Troops.Militia,
						MaxR = 250, Cost = 10,
						function Weight( scale ) { return this.Math.max(0, 100 - scale * 100); }
					},
					{   // TIER 2 - Militia Veteran: the mid bridge
						Type = ::Const.World.Spawn.Troops.MilitiaVeteran,
						MinR = 150, Cost = 12,
						function Weight( scale ) { return this.Math.max(0, 100 - scale * 100); }
					},
					{   // TIER 3 - Mercenary: rises with strength
						Type = ::Const.World.Spawn.Troops.Mercenary,
						MinR = 300, Cost = 25,
						function Weight( scale ) { return this.Math.min(100, scale * 100); }
					},
					{   // TIER 4 - Hedge Knight: elite, only for strong companies
						Type = ::Const.World.Spawn.Troops.HedgeKnight,
						MinR = 450, Cost = 40,
						function Weight( scale ) { return this.Math.min(100, this.Math.max(0, (scale - 0.5) * 200)); }
					}
				]
			}
		],
		Troops = [
			{
				Weight = 100,
				Types = [
					{ Type = ::Const.World.Spawn.Troops.CultistAmbush, Cost = 15 }
				]
			}
		]
	};

	// ---- Hand-authored contracts (Phase 4) -------------------------------------
	// Register each contract's category key so its action's isReadyForContract() lookup
	// resolves, then offer its action from settlement factions (village/terrain/flag
	// filtering happens inside each action's onUpdate). One pair of lines per contract.
	// NOTE: Legends' category-hook loop already ran, so each contract ALSO sets
	// m.Category directly in its own create() - this line only makes the key exist.

	// Contract 1 - the Abandoned Watchtower (haunted frontier ruin).
	::Const.Contracts.ContractCategoryMap.legend_watchtower_contract <- ::Const.Contracts.Categories.Battle;
	::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/legend_watchtower_action");

	// Contract 2 - Skull's Crossing (Economy mechanism-gamble; Thassilonian dam, draught-gated).
	::Const.Contracts.ContractCategoryMap.legend_skulls_crossing_contract <- ::Const.Contracts.Categories.Economy;
	::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/legend_skulls_crossing_action");

	// Contract 3 - Black Forks (Battle; forest village, cult in a ruined monastery; day/night branch).
	::Const.Contracts.ContractCategoryMap.skv_black_forks_contract <- ::Const.Contracts.Categories.Battle;
	::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_black_forks_action");

	::Const.Contracts.ContractCategoryMap.skv_metringer_contract <- ::Const.Contracts.Categories.Battle;
	::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_metringer_action");

	// Contract 4 - The Den Hunt (Legendary; a bounty on the PERMANENT skv_den
	// legendary location). The only contract here that does not spawn its own
	// target -- it finds a world fixture and reveals it. See the action's header.
	//
	// No ContractCategoryMap entry, and it is not an oversight. That map has exactly
	// two readers: the stamping loop in mod_legends/!config/contract_category.nut:116
	// (which iterates the map AT LEGENDS LOAD, long before this file runs, so it can
	// never see our entry -- hence m.Category is set directly in create()), and the
	// isReadyForContract(category) call in a SETTLEMENT-path action. This contract is
	// noble-only, and nobles do not use category slots, so nothing would read it.
	//
	// m.Category = Legendary still matters -- but only cosmetically here. It drives
	// the board label and getUICategoryIcon via getCategory(). Slot competition is a
	// settlement_faction concept; a noble house simply allows one contract at a time
	// (noble_faction.nut:94).
	::Const.FactionTrait.Actions[::Const.FactionTrait.NobleHouse].push("scripts/factions/contracts/skv_den_hunt_action");

	// Contract 5 - The Choking Tower (Economy; the mod's first fully NON-COMBAT
	// contract). A non-military frontier settlement in temperate, wooded country
	// pays a pittance to have the company climb the sealed technomancer's tower in
	// the Smokewood of Numeria and find out who keeps its fires lit. The ascent is
	// a randomized deck of skill-check room-cards; the reward is the plunder, not
	// the fee. Spawns and owns its own site, like contracts 2 and 3.
	::Const.Contracts.ContractCategoryMap.skv_choking_tower_contract <- ::Const.Contracts.Categories.Economy;
	::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_choking_tower_action");

	// Contract 6 - The Azari Palace (Economy; a Tome-of-Memory heist under cover of an
	// admission fee at a dead god's temple). Offered NORTH *and* SOUTH: pushed onto both
	// the Settlement pool and the OrientalCityState (southern city-state) pool.
	::Const.Contracts.ContractCategoryMap.skv_azari_contract <- ::Const.Contracts.Categories.Economy;
	::Const.FactionTrait.Actions[::Const.FactionTrait.Settlement].push("scripts/factions/contracts/skv_azari_action");
	::Const.FactionTrait.Actions[::Const.FactionTrait.OrientalCityState].push("scripts/factions/contracts/skv_azari_action");

	// ----------------------------------------------------------------------------
	//  LEGENDARY CATEGORY ICON
	//
	//  Legends ships ContractCategoryIconMap with Legendary = "" -- the ONLY one of
	//  the four without art (contract_category.nut:99-104). That is a deliberate
	//  blank, not a missing file: world_town_screen_main_dialog_module.js:480 guards
	//  with `if(_data.CategoryIcon)`, and "" is falsy in JS, so no element is created
	//  at all. Nothing is broken today; this fills a gap Legends chose to leave.
	//
	//  >>> SCOPE: THIS IS GLOBAL. <<<
	//  It is the first thing this mod changes outside its own content. The Legendary
	//  category contains ELEVEN contracts: the ten shipped noble beast hunts (bandit
	//  army, barbarian prisoner, coven leader, demon alps, greenwood schrats, redback
	//  webknechts, rock unholds, skin ghouls, stollwurms, white direwolf) and our Den
	//  hunt. All eleven get this icon. Cosmetic, save-safe, and reverted by deleting
	//  this one line.
	//
	//  Art: hand-drawn AT 30x30 rather than downscaled into it -- a crowned skull's
	//  spikes are sub-pixel if you shrink 92px art to fit. Fitted to the shipped
	//  family spec, all three of which are identical in structure:
	//      660 opaque px of 900 (an inscribed circle; the corners MUST be
	//        transparent or the badge renders as a black square)
	//      rim  #572c25 at radius > 0.80   (the copper ring that makes them a set)
	//      core luminance 29-63            (ours: 61, beside economy's 63)
	//
	//  TWO files are required, not one. The JS appends "_sw.png" for a disabled
	//  contract and ".png" otherwise -- a missing _sw is a broken image on the
	//  board, not a silent skip. (There is no _b: that suffix belongs to the
	//  contract BANNER, `_data.Icon + 'b.png'` at :496, a different system.)
	//  The ".png" itself is appended by the JS, so the value here has no extension.
	::Const.Contracts.ContractCategoryIconMap.Legendary = "ui/icons/contract_type_legendary";
	// ----------------------------------------------------------------------------
	// NOBLE-ONLY. The NobleHouse list IS the beast-hunt list (build, upgrade, and
	// ten monster hunts -- faction_traits.nut:14-27), and Legends already ships a
	// noble-commissioned direwolf hunt there. A village Settlement push existed for
	// testing and is removed: there is no venue-level renown lock to work around
	// (noble_faction.isReadyForContract is only cooldown + no-active-contract), so
	// the noble path was always testable -- the 990 gate above is the only thing
	// holding it, exactly like every other hunt on that list.
	//
	// Consequence, by settlement.nut:541 (`c.getHome().getID() == this.getID()`):
	// a contract is listed ONLY at its Home, and onExecute sets Home to
	// _faction.getSettlements()[0]. So a noble house posts this at exactly ONE
	// settlement. That is why the distance band is 40 rather than 30 -- venue
	// count, not plausibility.
	// ----------------------------------------------------------------------------

	// ----------------------------------------------------------------------------
	//  LEGENDARY LOCATIONS
	//  Different mechanism from contracts: permanent, world-gen placed, discovered
	//  by map rather than by noticeboard. Reserved for sites whose fiction is a
	//  standing FACT rather than an event -- a pack's claim on a village is a
	//  situation and situations resolve, so the bar is "is this still here in a
	//  hundred years or is it a job". The Den earns it on the fixed roster: canon's
	//  twenty dire wolves are unplayable as a contract budget and correct as a wall.
	// ----------------------------------------------------------------------------

	// Location 1 - The Den (Sevenarches, River Kingdoms; awakened dire wolves in an
	// abandoned village). Guide to the River Kingdoms pg. 48.
	//
	// Neither the location script nor the event script needs registering:
	// locations resolve by path at spawnLocation() time, and events are
	// auto-discovered by event_manager.nut:63's
	// IO.enumerateFiles("scripts/events/events/") then matched by m.ID.
	// This line is only the Legends MAP-system registration, which is what puts the
	// Den into Legends.Maps.generateLegendary() (spawned AND unvisited AND unowned)
	// so the black market can sell a map to it. That is its ONLY discovery channel:
	// tavern_building.nut's getRumor() explicitly skips LocationType.Unique, and
	// Legends hooks that file but not that function, so rumours can never name it.
	::Legends.Map.SkvDen <- ::Legends.Maps.add("location.skv_den", "The Den");

	// Worldgen placement. Same shape as Legends' own BuildMummySite /
	// BuildTournamentSite. The terrain lock IS the frequency dial - a campaign that
	// never rolls the Den is a feature, not a miss.
	::mods_hookExactClass("factions/actions/build_unique_locations_action", function(o)
	{
		o.m.SkvBuildDenSite <- true;

		local updateBuildings = o.updateBuildings;
		o.updateBuildings = function()
		{
			updateBuildings();

			// Idempotent: never build a second one (e.g. after a load).
			foreach( v in this.World.EntityManager.getLocations() )
			{
				if (v.getTypeID() == "location.skv_den")
				{
					this.m.SkvBuildDenSite = false;
				}
			}
		}

		local onExecute = o.onExecute;
		o.onExecute = function( _faction )
		{
			onExecute(_faction);

			if (!this.m.SkvBuildDenSite)
			{
				return;
			}

			// getTileToSpawnLocation takes a DISALLOWED list, so build "everything
			// except forest" the same inverted way the mummy site builds "everything
			// except desert".
			local disallowedTerrain = [];

			for( local i = 0; i < this.Const.World.TerrainType.COUNT; i = i )
			{
				if (i == this.Const.World.TerrainType.Forest || i == this.Const.World.TerrainType.AutumnForest)
				{
				}
				else
				{
					disallowedTerrain.push(i);
				}

				i = ++i;
			}

			// Verified signature (faction_action.nut:173):
			//   getTileToSpawnLocation(_maxTries, _notOnTerrain, _minDistToSettlements,
			//     _maxDistToSettlements, _maxDistanceToAllies, _minDistToEnemyLocations,
			//     _minDistToAlliedLocations, _nearTile, _minY, _maxY)
			// Shipped calls for reference:
			//   mummy      -> (tries, disallowed,  8,   25, 1001,  8,  8, null, 0.1)
			//   tournament -> (tries, disallowed, 30, 1000, 1001, 15, 15)
			//
			// Ours: 6-22 from settlements. Canon says the survivors "abandoned their
			// villages in the territory and moved north" - the Den sits in country
			// people used to live in and no longer do. Far enough that nobody stumbles
			// on it, near enough that its emptiness reads as a place that was emptied
			// rather than wilderness that was never settled.
			local tile = this.getTileToSpawnLocation(this.Const.Factions.BuildCampTries * 100, disallowedTerrain, 6, 22, 1001, 8, 8, null, 0.1);

			if (tile != null)
			{
				local camp = this.World.spawnLocation("scripts/entity/world/locations/legendary/skv_den_location", tile.Coords);

				if (camp != null)
				{
					camp.onSpawned();
					this.logInfo("Golarion: built The Den location");
				}
			}
		}
	});
	// ----------------------------------------------------------------------------
});
