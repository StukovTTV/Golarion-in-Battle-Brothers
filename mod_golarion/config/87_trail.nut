::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Trail <- {
	OnceKey = "Trail",

	DiffLo = 80,
	DiffHi = 109,

	PointsFloor = 11,
	PointsFull  = 16,
	PointsBonus = 23,

	PoorPayMult  = 0.5,
	BonusPayMult = 1.25,

	LoreBase   = 40,
	TalkBase   = 45,
	TaskBase   = 50,
	TravelBase = 50,

	TalksNeeded    = 3,
	TurnBackPoints = 3,
	GiftAmount     = 10,
	SabotageMoral  = 5,

	KarlaMedicine = 10,

	RavenHurtMin = 4,
	RavenHurtMax = 10,
	GemShards    = "scripts/items/trade/legend_gem_shards_item",

	BridgeTools = 15,

	ClimbBase     = 50,
	SnowEdge      = 10,
	ClimbNeed     = 0.5,
	MaxSlides     = 3,
	SlideHurtMin  = 6,
	SlideHurtMax  = 12,
	CleanRoped    = 3,
	CleanParties  = 1,
	ClimbRoped    = 1, ClimbParties = 2,

	DigPoints     = 3,
	LeaveMoral    = 4,

	BarkCharmBase    = 45,
	BarkPriceCharmed = 150,
	BarkPrice        = 200,

	BarkMetDig = 1, BarkMetDog = 2, BarkDrivenOff = 3, BarkMetMask = 3,
	BarkHealSlept = 0, BarkHealFree = 1, BarkHealGin = 2, BarkHealCrowns = 3, BarkHealShift = 2,
	BarkVisited = 16, BarkCharmRolled = 32,

	QuietClimbBase = 55,
	FallHurtMin    = 5,
	FallHurtMax    = 10,

	GoatBase       = 50,
	GoatsNeedCalm  = 3,
	GoatsNeedAlert = 2,
	GoatHurtMin    = 5,
	GoatHurtMax    = 10,

	GoatsQuiet = 1, GoatsPegs = 2, GoatsFell = 4, GoatsAlerted = 8, GoatsCalmed = 16, GoatsScattered = 32,

	VGoats = 0, VChart = 1, VGround = 2, VGrazing = 3, VMelt = 4, VShelter = 5, VClear = 6,

	OdvarNone = 0, OdvarFight = 1, OdvarWon = 2, OdvarFled = 3, OdvarBargain = 4,
	OdvarName        = "Odvar",
	BargainPoints    = 3,
	BargainMoral     = 5,
	OdvarFledPoints  = 7,
	OdvarPotions     = 2,
	PotionScript     = "scripts/items/misc/skv_potion_of_cure_light_wounds",

	OdvarWolfBase    = 100,
	OdvarCharge      = 30,
	OdvarWolfMin     = 40,
	OdvarSaturation  = 0.05,

	OrcsNone = 0, OrcsPeace = 1, OrcsRefused = 2, OrcsWon = 3, OrcsFled = 4,
	GrakchaName      = "Grakcha",
	OrcsFledPoints   = 3,
	OrcsWinPoints    = 3,

	ParleyBase       = 45,
	ParleyBonus      = 10,
	DrinkBase        = 50,

	PrepGin = 1, PrepDrink = 2, PrepDrinkWon = 4,

	OrcLoot = [
		"scripts/items/misc/skv_potion_of_cure_light_wounds",
		"scripts/items/misc/skv_potion_of_cure_light_wounds",
		"scripts/items/accessory/berserker_mushrooms_item"
	],

	BandBase         = 80,
	GrakchaCharge    = 30,
	BandMin          = 26,

	CaveEntrance = 1, CaveDeeper = 2, CaveAlerted = 4, CaveBedding = 8, CaveOgreDead = 16,
	CaveFled = 32, CaveLeft = 64,
	CaveKnown = 128,

	SearchBase      = 50,
	StenchBase      = 50,
	StenchNeed      = 0.5,
	PurseMin        = 60,
	PurseMax        = 120,
	OgreWinPoints   = 3,
	OgreName        = "Cave Giant",
	OgreBase        = 100,
	OgreChampionBudget = 150,
	OgreSurpriseInit = 0.6,

	GiantCharge     = 50,
	LairGuardMin    = 20,
	JadeBrooch   = "scripts/items/loot/jade_broche_item",
	HeapLoot     = [ "scripts/items/loot/deformed_valuables_item", "scripts/items/loot/silverware_item" ],

	BandFailed = 0, BandPoor = 1, BandFull = 2, BandBonus = 3,
	NoblesRelation = 10,

	TravelGood = 0.6,
	TravelBad  = 0.3,

	TalkJasper = 0, TalkSarevi = 1, TalkAmyas = 2, TalkLeonie = 3, TalkDacian = 4, TalkGift = 5,

	TaskWildlife = 0, TaskPlants = 1, TaskChart = 2, TaskFord = 3, TaskFirm = 4, TaskSite = 5, TaskBridge = 6,

	LoreRolled = 1, LoreOrc = 2, LoreSnow = 4,

	NoblesNone = 0, NoblesTurnedBack = 1, NoblesPressing = 2, NoblesDugOut = 3, NoblesLost = 4, NoblesSabotaged = 5,

	RavensNone = 0, RavensGin = 1, RavensFightPass = 2, RavensFightFail = 3, RavensCalmPass = 4, RavensCalmFail = 5,

	GinCarried = 0, GinBurned = 1, GinToBark = 2, GinToGrakcha = 3,

	GiftNone = 0, GiftTools = 1, GiftMedicine = 2,

	TravelNotRolled = 0, TravelLost = 1, TravelFair = 2, TravelGoodTime = 3,

	OrcLoreLeads = {
		["background.retired_soldier"] = 14, ["background.sellsword"] = 10,
		["background.barbarian"] = 10, ["background.hedge_knight"] = 6, ["background.militia"] = 4
	},

	MountainLeads = {
		["background.barbarian"] = 14, ["background.wildman"] = 12, ["background.legend_ranger"] = 10,
		["background.shepherd"] = 8, ["background.hunter"] = 6
	},

	SoldierLeads = {
		["background.retired_soldier"] = 16, ["background.sellsword"] = 8,
		["background.hedge_knight"] = 8, ["background.militia"] = 4
	},

	HerbLeads = {
		["background.legend_herbalist"] = 16, ["background.legend_druid"] = 12,
		["background.shepherd"] = 6, ["background.hunter"] = 4
	},

	BuildLeads = {
		["background.mason"] = 14, ["background.lumberjack"] = 8
	},

	AnimalLeads = {
		["background.legend_druid"] = 14, ["background.shepherd"] = 12, ["background.hunter"] = 8,
		["background.legend_ranger"] = 8, ["background.wildman"] = 6, ["background.houndmaster"] = 6,
		["background.poacher"] = 4
	},

	CalmBase = 38,
	AnimalPerkFalcon = 12,
	AnimalPerkDogWhisperer = 4,
	AnimalPerkDog = 2,

	WaterLeads = {
		["background.fisherman"] = 14, ["background.shepherd"] = 6
	},

	StopNames   = ["", "A Camp in the Foothills", "The Snow Line", "The Treeline", "The Cave"],
	StopBrushes = ["", "world_player_camp_01_fire", "world_player_camp_01_fire", "world_player_camp_01_fire", "world_snow_cave"],

	ImgTask       = "event_45",
	ImgLore       = "event_126",
	ImgSetOut     = "event_112",
	ImgCamp       = "event_26",
	ImgTurnedBack = "event_42",
	ImgPressOn    = "event_36",
	ImgRavens     = "event_25",
	ImgStream     = "event_126",

	ImgSnowLine   = "event_143",
	ImgPass       = "event_08",
	ImgBuried     = "event_08",
	ImgDog        = "event_27",
	ImgCabin      = "event_109",

	ImgTreeline   = "event_42",
	ImgHerd       = "event_42",
	ImgView       = "event_126",
	ImgBowl       = "legend_white_wolf",
	ImgOdvarDead  = "event_56",
	ImgBargain    = "event_09",
	ImgOrcCamp    = "event_138",
	ImgParley     = "event_39",
	ImgNoDeal     = "event_67",
	ImgOrcsDead   = "event_32",

	ImgCave       = "event_144",
	ImgHeap       = "event_46",
	ImgReport     = "event_63",
	ImgLetter     = "event_137"
};

::Const.World.Spawn.Troops.SkvOrcYoungLow <- {
	ID = ::Const.EntityType.OrcYoung,
	Script = "scripts/entity/tactical/enemies/orc_young_low",
	Variant = 0,
	Strength = 14,
	Cost = 13,
	Row = -1
};

::Const.World.Spawn.GolarionTrailOrcs <- {
	Name = "GolarionTrailOrcs",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_orc_02",
	MaxR = 400,
	Troops = [
		{
			Weight = 60,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvOrcYoungLow, Cost = 13 }
			]
		},
		{
			Weight = 40,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.OrcWarriorLOW, Cost = 30 }
			]
		}
	]
};

::Const.World.Spawn.GolarionTrailLair <- {
	Name = "GolarionTrailLair",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_hyena_01",
	MaxR = 650,
	Troops = [
		{
			Weight = 70,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Hyena, Cost = 20 }
			]
		},
		{
			Weight = 30,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.HyenaHIGH, MinR = 150, Cost = 25 }
			]
		}
	]
};
