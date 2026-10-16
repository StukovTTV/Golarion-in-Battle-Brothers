::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Kinds <- {

	Fire = [
		{ ID = "weapon.skv_alchemists_fire", Name = "Alchemist's Fire", Phrase = "a flask of alchemist's fire", Ammo = false },
		{ ID = "weapon.fire_bomb",           Name = "Fire Pot",         Phrase = "a fire pot",                  Ammo = true  }
	],

	Holy = [
		{ ID = "weapon.skv_blessed_water",   Name = "Vial of Blessed Water", Phrase = "a vial of blessed water", Ammo = false },
		{ ID = "weapon.holy_water",          Name = "Holy Water",       Phrase = "a flask of holy water",       Ammo = true  }
	]
};
