::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Rats <- {

	CommonVariants = 4,
	DireVariant    = 5,

	Scale       = 0.70,
	DireScale   = 0.85,
	ScaleVary   = 0.07,
	SocketScale = 0.92,

	SatVaryChance   = 90,
	SatVary         = 0.2,
	ColorVaryChance = 90,
	ColorVary       = 0.05,

	Bite  = { Min = 15, Max = 35, HeadBonus = 15, ActionPoints = 4, Fatigue = 8 },
	Claws = { Min = 25, Max = 45, ArmorMult = 0.7, ActionPoints = 4, Fatigue = 10 },

	MeatChance = 33
};

::Const.Tactical.Actor.SkvGiantRat <- {
	XP = 60,
	ActionPoints = 11,
	Hitpoints = 55,
	Bravery = 35,
	Stamina = 120,
	MeleeSkill = 55,
	RangedSkill = 0,
	MeleeDefense = 10,
	RangedDefense = 15,
	Initiative = 120,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		0,
		0
	]
};

::Const.Tactical.Actor.SkvDireRat <- {
	XP = 150,
	ActionPoints = 11,
	Hitpoints = 110,
	Bravery = 60,
	Stamina = 160,
	MeleeSkill = 62,
	RangedSkill = 0,
	MeleeDefense = 10,
	RangedDefense = 10,
	Initiative = 125,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		15,
		15
	]
};

::Const.EntityType.SkvGiantRat <- ::Const.EntityType.addNew(
	"skv_giant_rat_orientation", "Giant Rat", "Giant Rats", ::Const.FactionType.Beasts);
::Const.EntityType.SkvDireRat <- ::Const.EntityType.addNew(
	"skv_dire_rat_orientation", "Dire Rat", "Dire Rats", ::Const.FactionType.Beasts);

::Const.World.Spawn.Troops.SkvGiantRat <- {
	ID = ::Const.EntityType.SkvGiantRat,
	Script = "scripts/entity/tactical/enemies/skv_giant_rat",
	Variant = 0,
	Strength = 7,
	Cost = 7,
	Row = 0
};

::Const.World.Spawn.Troops.SkvDireRat <- {
	ID = ::Const.EntityType.SkvDireRat,
	Script = "scripts/entity/tactical/enemies/skv_dire_rat",
	Variant = 0,
	Strength = 14,
	Cost = 14,
	Row = 0
};

::Const.World.Spawn.GolarionRats <- {
	Name = "GolarionRats",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_werewolf_01",
	MaxR = 600,
	Troops = [
		{
			Weight = 80,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvGiantRat, Cost = 7 }
			]
		},
		{
			Weight = 20,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvDireRat, Cost = 14, Roll = true }
			]
		}
	]
};

::logInfo("Golarion: #21 In Service to Lore -- the rats loaded (Giant Rat, Dire Rat)");

::Const.Skv.Lore <- {
	OnceKey = "Lore",

	RarityNorth = 2,
	RaritySouth = 6,
	RarityNoble = 4,

	HostSize = 3,
	DiffLo   = 70,
	DiffHi   = 105,

	SiteRadius  = 10,
	SiteMinDist = 4,
	SitePathMax = 20,
	SiteEdge    = 3,
	SiteSpacing = 5,
	SiteCount   = 4,
	NearRadius  = 7,
	NearPathMax = 12,
	FallbackTries = 10,
	RepairTries   = 3,

	KindKarela  = 0,
	KindBaltwin = 1,
	KindSage    = 2,
	KindEnvoy   = 3,
	Sites = [
		{ Name = "The Pickled Imp",   Who = "Karela",    Bit = 1, Latch = "AtShop",   Script = "scripts/entity/world/locations/skv_lore_shop_location" },
		{ Name = "The Shining Star",  Who = "Ollysta",   Bit = 2, Latch = "AtTemple", Script = "scripts/entity/world/locations/skv_lore_temple_location" },
		{ Name = "The Sage's House",  Who = "Amenopheus",Bit = 4, Latch = "AtSage",   Script = "scripts/entity/world/locations/skv_lore_sage_location" },
		{ Name = "The Envoy's House", Who = "Zarta",     Bit = 8, Latch = "AtEnvoy",  Script = "scripts/entity/world/locations/skv_lore_envoy_location" }
	],
	AllBits = 15,
	SageSpriteScale = 1.0,

	LawfulMin  = 60,
	LawlessMax = 40,

	PayBase       = 300,
	KarelaMult    = 0.25,
	BaltwinBase   = 0.08,
	BaltwinPerSecret = 0.04,
	MapMult       = 0.20,
	CaseMult      = 0.10,
	CaseScratchMult = 0.5,
	WageMult      = 0.25,
	PoorWageMult  = 0.5,
	FinderMult    = 0.05,

	PurseMult     = 0.20,
	SilenceMult   = 0.10,
	WatchMult     = 0.05,
	CutMult       = 0.10,
	VisitMult     = 0.20,

	TierFailed  = 0,
	TierPoor    = 1,
	TierSuccess = 2,

	VaultMoves = 5,

	GrantShopRefuse = 0x0001,
	GrantRatcatcher = 0x0002,
	GrantCrate      = 0x0004,
	GrantKarelaPay  = 0x0008,
	GrantStrip      = 0x0010,
	GrantKept       = 0x0020,
	GrantForced     = 0x0040,
	GrantSilence    = 0x0080,
	GrantReport     = 0x0100,
	GrantThanks     = 0x0200,
	GrantMapOut     = 0x0400,
	GrantAlleyAfter = 0x0800,
	GrantPay        = 0x1000,
	GrantEnvoy2     = 0x2000,

	RatBase        = 90,
	RatcatcherMult = 0.75,

	AlleyBase     = 100,
	AlleyTrimMult = 0.9,
	AlleySlowInit = 20,

	GangNames = [ "Deandre Dulay", "Halli Fosta", "Larkin Waever", "Ledford" ],

	TailMax          = 3,
	TailWatchBase    = 50,
	TailDoubleBase   = 45,
	TailPartyNeed    = 0.5,
	TailBluePenalty  = 10,
	TailBlueMax      = 30,

	PierPickBase  = 40,
	PierKeyBase   = 50,
	PierForceBase = 60,
	RatcatcherBg  = "background.ratcatcher",
	RatcatcherXP  = 75,
	CraneBase     = 40,
	BraceBase     = 50,
	BraceNeed     = 0.5,
	SkiffBase     = 50,
	DiveBase      = 50,

	SpareAmmo     = 50,
	SpareTools    = 20,

	StripCount    = 2,
	StripGoods    = [
		"scripts/items/trade/cloth_rolls_item",
		"scripts/items/trade/cloth_rolls_item",
		"scripts/items/trade/salt_item",
		"scripts/items/trade/spices_item"
	],

	GossipBase    = 50,
	GossipBonus   = 10,
	WaryPenalty   = 10,
	TeaBase       = 50,
	SearchBase    = 45,
	ChildrenBase  = 50,
	KeptMedicine  = 10,
	ForcedMedicine = 10,
	RemedyMedicine = 5,
	ForcedRelation = -5,
	WatchRelation  = 2,

	StudyBase     = 35,
	StudyLead     = 5,
	StudySteelBonus = 15,
	BasketBase    = 50,
	RuneBase      = 50,
	SteelBase     = 45,
	BlueExtraMax  = 2,
	ItemWand      = "scripts/items/accessory/skv_opening_wand_item",

	ImpTalkBase   = 45,
	ImpBladeBase  = 50,
	CaseLockBase  = 20,
	ItemOpener    = "scripts/items/weapons/dagger",

	LedfordKit    = [
		"scripts/items/weapons/woodcutters_axe",
		"scripts/items/weapons/woodcutters_axe",
		"scripts/items/weapons/hand_axe"
	],

	HurtMin      = 4,
	HurtMax      = 10,
	BiteHurtMin  = 3,
	BiteHurtMax  = 8,
	HardHurtMin  = 8,
	HardHurtMax  = 15,

	MoralRefuse  = 2,
	MoralStrip   = -1,
	MoralKept    = -3,
	MoralForced  = -2,
	MoralSilence = -3,
	MoralTruth   = 2,
	MoralSoft    = -1,
	MoralWatch   = 1,
	MoralFinish  = -2,
	MoralTell    = 2,
	MoralVisit   = -3,

	ImgLodge  = "skv_grandlodge",
	ImgErrand = "event_20",
	ImgTail   = "event_84",
	ImgStreet = "event_43",
	ImgAlley  = "event_64",
	ImgShop   = "skv_lore_shop",
	ImgPier   = "skv_bygones_docks",
	ImgRats   = "skv_lore_rats",
	ImgCrate  = "event_55",
	ImgTemple = "event_152",
	ImgHouse  = "skv_lore_baltwin",
	ImgSage   = "event_17",
	ImgVault  = "event_63",
	ImgEnvoy  = "event_106",
	ImgImp    = "skv_lore_imp",
	ImgCase   = "event_112"
};

::Const.World.Spawn.GolarionAlleyGang <- {
	Name = "GolarionAlleyGang",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_bandit_01",
	MaxR = 600,
	Troops = [
		{
			Weight = 35,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.BanditThug, Cost = 8 }
			]
		},
		{
			Weight = 25,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.BanditMarksmanLOW, Cost = 12 }
			]
		},
		{
			Weight = 25,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.BanditRaiderLOW, Cost = 16 }
			]
		},
		{
			Weight = 15,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.BanditRaider, Cost = 20 }
			]
		}
	]
};

::logInfo("Golarion: #21 In Service to Lore -- the contract's dials and the alley gang loaded");
