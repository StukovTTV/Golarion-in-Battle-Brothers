::Const.EntityType.SkvTatzlwyrm <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Serpent],
	"Tatzlwyrm",
	"Tatzlwyrms",
	::Const.FactionType.Beasts
);

::Const.Tactical.Actor.SkvTatzlwyrm <- {
	XP = 150,
	ActionPoints = 9,
	Hitpoints = 95,
	Bravery = 90,
	Stamina = 90,
	MeleeSkill = 65,
	RangedSkill = 0,
	MeleeDefense = 15,
	RangedDefense = 15,
	Initiative = 110,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		20,
		20
	]
};

::Const.World.Spawn.Troops.SkvTatzlwyrm <- {
	ID       = ::Const.EntityType.SkvTatzlwyrm,
	Variant  = 0,
	Strength = 14,
	Cost     = 14,
	Row      = -1,
	Script   = "scripts/entity/tactical/enemies/skv_tatzlwyrm"
};

::Const.World.Spawn.GolarionTatzlwyrms <- {
	Name = "GolarionTatzlwyrms",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 200,
	MinR = 14,
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTatzlwyrm, Cost = 14 }
			]
		}
	]
};

::Const.World.Spawn.GolarionValeWolves <- {
	Name = "GolarionValeWolves",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 200,
	MinR = 20,
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Wolf, Cost = 20 }
			]
		}
	]
};
