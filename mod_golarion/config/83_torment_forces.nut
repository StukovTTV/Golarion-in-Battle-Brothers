::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Torment <- {

	BandBase    = 90.0,
	BandMin     = 24.0,
	OgreCharge  = 35.0,
	OgreName    = "Drunk Ogre",

	OgreHitpoints    = 0.70,
	OgreMeleeSkill   = 0.85,
	OgreMeleeDefense = 0.50,
	OgreInitiative   = 0.60,

	OgreChampionBudget = 300.0,

	WolfBase      = 55.0,
	HaanarCharge  = 35.0,
	HaanarName    = "Haanar",

	SneakBase = 50,

	TalkBase  = 45,

	PayBase   = 250,
	PayWealthLo = 0.6,
	PayWealthHi = 1.1,
	CaveCoin  = 60,
	TalkXP    = 30,

	MarkFight1Lost = 0x01
};

::Const.Tactical.Actor.SkvHaanar <- {
	XP = 250,
	ActionPoints = 9,
	Hitpoints = 80,
	Bravery = 70,
	Stamina = 110,
	MeleeSkill = 55,
	RangedSkill = 45,
	MeleeDefense = 10,
	RangedDefense = 10,
	Initiative = 110,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		0,
		0
	],
	FatigueRecoveryRate = 15
};

::Const.Skv.Torment.CavePaths <- [
	"scripts/items/loot/bone_figurines_item",
	"scripts/items/accessory/legend_sighthound_item",
	"scripts/items/trade/legend_gem_shards_item",
	"scripts/items/loot/jade_broche_item"
];

::Const.World.Spawn.GolarionTormentBand <- {
	Name = "GolarionTormentBand",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_ghoul_02",
	MaxR = 400,
	Troops = [
		{
			Weight = 70,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyte, Cost = 12 }
			]
		},
		{
			Weight = 30,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteSkulker, Cost = 18 }
			]
		}
	]
};

::Const.World.Spawn.GolarionTormentWolves <- {
	Name = "GolarionTormentWolves",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_werewolf_01",
	MaxR = 400,
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Direwolf, Cost = 20 }
			]
		}
	]
};

::logInfo("Golarion: Torment and Legacy forces loaded (2 lists)");
