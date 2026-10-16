::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Temples <- {
	Discount = 0.8,
	GoodAbove = 60,
	EvilBelow = 40,
	DiscountText = "For following the doctrine of our god we offer you a considerable discount",

	Classes = {
		legends_steppe_village   = "Steppe",   legends_steppe_fort    = "Steppe",
		legends_coast_fort       = "Coast",    legends_fishing_village = "Coast",
		legends_mountains_fort   = "Mountains", legends_mining_village = "Mountains",
		legends_forest_fort      = "Forest",   legends_lumber_village = "Forest",
		legends_swamp_fort       = "Swamp",    legends_swamp_village  = "Swamp",
		legends_snow_fort        = "Snow",     legends_snow_village   = "Snow",
		legends_tundra_fort      = "Snow",     legends_tundra_village = "Snow",
		legends_farm_fort        = "Farming",  legends_farming_village = "Farming",
		city_state               = "South"
	},

	Pools = {
		Steppe    = { Good = ["Sarenrae", "Apsu"],               Neutral = ["Nethys", "Abadar", "Sivanah"],     Evil = ["Norgorber", "Achaekek", "Rovagug"] },
		South     = { Good = ["Sarenrae", "Shelyn"],             Neutral = ["Nethys", "Abadar", "Pharasma"],    Evil = ["Asmodeus", "Norgorber", "Mammon"] },
		Coast     = { Good = ["Desna", "Cayden Cailean"],        Neutral = ["Gozreh", "Besmara", "Abadar"],     Evil = ["Norgorber", "Lamashtu"] },
		Mountains = { Good = ["Torag", "Iomedae"],               Neutral = ["Abadar", "Irori", "Kerkamoth"],    Evil = ["Rovagug", "Asmodeus", "Mammon"] },
		Forest    = { Good = ["Erastil", "Desna"],               Neutral = ["Gozreh", "Calistria", "Count Ranalc"], Evil = ["Treerazer", "Lamashtu", "Ghlaunder"] },
		Swamp     = { Good = ["Desna", "Erastil"],               Neutral = ["Pharasma", "Gozreh"],              Evil = ["Gyronna", "Ghlaunder", "Urgathoa"] },
		Snow      = { Good = ["Erastil", "Torag"],               Neutral = ["Gorum", "Pharasma"],               Evil = ["Zon-Kuthon", "Rovagug", "Lamashtu"] },
		Farming   = { Good = ["Erastil", "Iomedae", "Shelyn", "Cayden Cailean"], Neutral = ["Abadar", "Pharasma"], Evil = ["Urgathoa", "Norgorber"] }
	},

	Alignment = {
		["Sarenrae"] = "Good", ["Apsu"] = "Good", ["Shelyn"] = "Good", ["Desna"] = "Good",
		["Cayden Cailean"] = "Good", ["Torag"] = "Good", ["Iomedae"] = "Good", ["Erastil"] = "Good",
		["Nethys"] = "Neutral", ["Abadar"] = "Neutral", ["Sivanah"] = "Neutral", ["Pharasma"] = "Neutral",
		["Gozreh"] = "Neutral", ["Besmara"] = "Neutral", ["Irori"] = "Neutral", ["Kerkamoth"] = "Neutral",
		["Calistria"] = "Neutral", ["Count Ranalc"] = "Neutral", ["Gorum"] = "Neutral",
		["Norgorber"] = "Evil", ["Achaekek"] = "Evil", ["Rovagug"] = "Evil", ["Asmodeus"] = "Evil",
		["Mammon"] = "Evil", ["Lamashtu"] = "Evil", ["Treerazer"] = "Evil", ["Ghlaunder"] = "Evil",
		["Gyronna"] = "Evil", ["Urgathoa"] = "Evil", ["Zon-Kuthon"] = "Evil"
	}
};
