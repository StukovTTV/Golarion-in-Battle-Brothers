::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Boggard.Croak <- {

	Checks = 2,
	ActionPoints = 6,
	Fatigue = 20,
	MaxRange = 3,

	Cooldown = 2
};

::Const.Skv.Boggard.Tongue <- {

	ActionPoints = 6,
	Fatigue = 20,
	MaxRange = 3
};

::Const.Tactical.Actor.SkvBoggardScout <- {
	XP = 35,
	ActionPoints = 9,
	Hitpoints = 50,
	Bravery = 40,
	Stamina = 110,
	MeleeSkill = 50,
	RangedSkill = 50,
	MeleeDefense = 8,
	RangedDefense = 8,
	Initiative = 105,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		0,
		0
	]
};

::Const.Tactical.Actor.SkvBoggardWarrior <- {
	XP = 50,
	ActionPoints = 9,
	Hitpoints = 70,
	Bravery = 50,
	Stamina = 120,
	MeleeSkill = 60,
	RangedSkill = 40,
	MeleeDefense = 12,
	RangedDefense = 5,
	Initiative = 95,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		40,
		0
	]
};

::Const.Tactical.Actor.SkvBoggardSwampseer <- {
	XP = 80,
	ActionPoints = 9,
	Hitpoints = 60,
	Bravery = 60,
	Stamina = 120,
	MeleeSkill = 45,
	RangedSkill = 55,
	MeleeDefense = 10,
	RangedDefense = 10,
	Initiative = 100,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		15,
		0
	]
};

::Const.Skv.Boggard.Types <- {
	Scout = {
		Head = "bust_unhold_head_05",
		Scale = 0.66,
		Cost = 20
	},
	Warrior = {
		Head = "bust_unhold_head_03",
		Scale = 0.74,
		Cost = 30
	},
	Swampseer = {

		Head = "bust_unhold_head_04",
		Scale = 0.72,
		Cost = 45
	}
};

::Const.AI.Agent.ID.SkvBoggard <- "agent.skv_boggard";
::Const.AI.Agent.ID.SkvBoggardCaster <- "agent.skv_boggard_caster";

::Const.AI.Agent.ID.SkvBoggardWarrior <- "agent.skv_boggard_warrior";

::Const.EntityType.SkvBoggardScout <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Unhold], "Boggard Scout", "Boggard Scouts", ::Const.FactionType.Beasts);
::Const.EntityType.SkvBoggardWarrior <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Unhold], "Boggard Warrior", "Boggard Warriors", ::Const.FactionType.Beasts);
::Const.EntityType.SkvBoggardSwampseer <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Unhold], "Boggard Swampseer", "Boggard Swampseers", ::Const.FactionType.Beasts);

::Const.World.Spawn.Troops.SkvBoggardScout <- {
	ID = ::Const.EntityType.SkvBoggardScout,
	Script = "scripts/entity/tactical/enemies/skv_boggard_scout",
	Variant = 0,
	Strength = 20,
	Cost = 20,
	Row = 1
};

::Const.World.Spawn.Troops.SkvBoggardWarrior <- {
	ID = ::Const.EntityType.SkvBoggardWarrior,
	Script = "scripts/entity/tactical/enemies/skv_boggard_warrior",
	Variant = 0,
	Strength = 30,
	Cost = 30,
	Row = 0
};

::Const.World.Spawn.Troops.SkvBoggardSwampseer <- {
	ID = ::Const.EntityType.SkvBoggardSwampseer,
	Script = "scripts/entity/tactical/enemies/skv_boggard_swampseer",
	Variant = 0,
	Strength = 45,
	Cost = 45,
	Row = 2
};

::Const.World.Spawn.GolarionBoggards <- {
	Name = "GolarionBoggards",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_werewolf_01",
	MaxR = 600,

	Fixed = [
		{
			Type = ::Const.World.Spawn.Troops.SkvBoggardSwampseer,
			Cost = 45,
			Weight = 0,
			MinGuards = 1,
			MaxGuards = 1,

			Guards = [
				{
					Type = ::Const.World.Spawn.Troops.SkvBoggardWarrior,
					Cost = 30,

					function Weight( _scale ) { return 100; }
				}
			]
		},
		{

			Type = ::Const.World.Spawn.Troops.SkvBoggardScout,
			Cost = 20,
			Weight = 0
		}
	],

	Troops = [
		{
			Weight = 40,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvBoggardScout, Cost = 20, Roll = true }
			]
		},
		{
			Weight = 60,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvBoggardWarrior, Cost = 30 }
			]
		}
	]
};

::Const.Skv.Croak <- {

	RenownGate  = 300,
	SwampRadius = 5,

	Situation   = "situation.disappearing_villagers",

	PayBase     = 200.0,
	PayWealthLo = 0.6,
	PayWealthHi = 1.1,

	BodyBounty  = 30,
	MoralPerBody = 1,
	PoorPayMult = 0.35,

	TrailBase = 55,
	BoatBase  = 50,
	AskCost   = 50,

	FightBase = 115.0,
	FightMin  = 95.0,

	CadmusBase = 45,
	BodiesBase = 50,

	BodiesTier1 = 0.35,
	BodiesTier2 = 0.62,
	BodiesTier3 = 0.82,

	DiffLo = 70,
	DiffHi = 105,

	ImgGozreh  = "skv_gozreh",
	ImgGogunta = "skv_gogunta",

	ImgPost    = "event_109",
	ImgHuts    = "event_94",
	ImgBodies  = "event_103",
	ImgGear    = "event_98",
	ImgMarsh   = "event_09",
	ImgRoute   = "event_45",
	ImgTrail   = "event_16",
	ImgChannel = "event_123",
	ImgTavern  = "event_24",
	ImgHutN    = "event_63",
	ImgHutE    = "event_19",
	ImgHutW    = "event_36",
	ImgHutS    = "event_55",

	GearPaths = [
		"scripts/items/legend_armor/plate/legend_armor_leather_jacket",
		"scripts/items/legend_armor/plate/legend_armor_leather_jacket_simple",
		"scripts/items/legend_armor/plate/legend_armor_leather_jacket_simple",
		"scripts/items/legend_armor/plate/legend_armor_leather_jacket_simple",
		"scripts/items/weapons/crossbow",
		"scripts/items/ammo/quiver_of_bolts",
		"scripts/items/weapons/shortsword",
		"scripts/items/weapons/shortsword",
		"scripts/items/weapons/shortsword",
		"scripts/items/weapons/fighting_axe"
	],

	HutN      = 1,
	HutE      = 2,
	HutW      = 4,
	HutStore  = 8,
	HutSouth  = 16,
	HutGear   = 32,
	HutBodies = 64,
	HutCadmusRead = 128
};

::Const.Skv.Croak.swampTypes <- function ()
{
	local T = ::Const.World.TerrainType;
	return [T.Swamp, T.SwampGreen, T.SwampForest];
};

::logInfo("Golarion: boggard roster loaded (3 units, the croak and the tongue)");
