::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Shops <- {

	Marketplace = [],

	Alchemist = [
		{ R = 0,  P = 1.0, S = "tools/skv_alchemists_fire_item" },
		{ R = 10, P = 1.0, S = "tools/skv_alchemists_acid_item" },
		{ R = 20, P = 1.0, S = "tools/skv_thunderstone_item" },
		{ R = 20, P = 1.0, S = "tools/skv_smokestick_item" },
		{ R = 30, P = 2.0, S = "misc/skv_potion_of_protection_from_evil" },
		{ R = 50, P = 2.0, S = "misc/skv_potion_of_blur" }
	],

	Blackmarket = [
		{ R = 50, P = 2.0, S = "accessory/skv_bracers_of_protection" },
		{ R = 40, P = 2.0, S = "tools/skv_alchemists_fire_item" },
		{ R = 50, P = 2.0, S = "tools/skv_alchemists_acid_item" },
		{ R = 60, P = 2.0, S = "tools/skv_thunderstone_item" },
		{ R = 60, P = 2.0, S = "tools/skv_smokestick_item" },
		{ R = 60, P = 2.0, S = "tools/skv_blessed_water_item" },
		{ R = 50, P = 2.0, S = "misc/skv_potion_of_cure_light_wounds" },
		{ R = 60, P = 2.0, S = "misc/skv_potion_of_protection_from_evil" },
		{ R = 70, P = 2.0, S = "misc/skv_potion_of_cure_moderate_wounds" },
		{ R = 80, P = 2.0, S = "misc/skv_potion_of_blur" }
	],

	Temple = [
		{ R = 20, P = 2.0, S = "misc/skv_potion_of_cure_light_wounds" },
		{ R = 20, P = 2.0, S = "tools/skv_blessed_water_item" },
		{ R = 30, P = 2.0, S = "misc/skv_potion_of_protection_from_evil" },
		{ R = 50, P = 2.0, S = "misc/skv_potion_of_cure_moderate_wounds" }
	]
};
