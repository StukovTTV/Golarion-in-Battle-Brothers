::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Boggard <- {

	Body   = "bust_unhold_body_03",

	Heads  = [
		"bust_unhold_head_05",
		"bust_unhold_head_03"
	],
	Injury = "bust_unhold_03_injured",

	Scale = 0.70,

	ScaleVary = 0.07,
	ColorVary = 0.05,

	SocketScale = 0.92,

	Tint = "#9cb87a",
	Saturation = 1.15,

	Cost = 22
};

::Const.Tactical.Actor.SkvBoggard <- {
	XP = 40,
	ActionPoints = 9,
	Hitpoints = 55,
	Bravery = 40,
	Stamina = 110,
	MeleeSkill = 55,
	RangedSkill = 40,
	MeleeDefense = 8,
	RangedDefense = 5,
	Initiative = 100,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		0,
		0
	]
};

::logInfo("Golarion: boggard sighting probe loaded (not a roster -- see 85_boggard.nut)");
