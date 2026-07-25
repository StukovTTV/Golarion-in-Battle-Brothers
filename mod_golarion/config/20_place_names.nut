::Const.Strings.CityStateNames = [
	"Absalom", "Kaer Maga", "Okeno", "Wati", "Goka", "Senghor",
	"Vaktai", "Aspenthar", "Ezida", "Lamasara", "Tanadesh", "Alkenstar",
	"Yenchabur", "Bloodcove", "Ular Kel", "Ecanus", "Quantium", "Arudrellisiir"
];

// ---- Noble houses as legacy claims on the runelords of Thassilon ----
// Runelord name pool; grouped by realm for readability, drawn at random (do/while dedup),
// so order is cosmetic.
::Const.Strings.NobleHouseNames = [
	// Greed -- Shalast
	"Kaladurnae", "Fethryr", "Gimmel", "Ligniya", "Mazmiranna", "Aethusa",
	"Haphrama", "Karzoug",
	// Gluttony -- Gastash
	"Kaliphesta", "Atharend", "Goparlis", "Zutha",
	// Envy -- Edasseril
	"Naaft", "Tannaris", "Ivamura", "Jurah", "Chalsardra", "Esedrea",
	"Zarve", "Desamelia", "Phirandi", "Belimarius",
	// Sloth -- Haruka
	"Xirie", "Ilthyrius", "Azeradni", "Zalelet", "Krenlith", "Ivarinna", "Krune",
	// Wrath -- Bakrakhan
	"Alderpash", "Angothane", "Xiren", "Thybidos", "Alaznist",
	// Lust -- Eurythnia. Pride -- Cyrusian.
	"Sorshen", "Xanderghul",
	// The First King
	"Xin"
];

// ---- City-state titles. Rendered as "<Title> of <Name>" ----
// EXISTING Const key -> assign with `=`, not `<-`.
// The " of" IS PART OF THE TITLE STRING (UI concatenates title + " " + name). Verified in-game v0.78.
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
