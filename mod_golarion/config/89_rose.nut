::Const.Skv.Rose <- {
	OnceKey = "Rose",

	MoralMax   = 60,
	RenownGate = 400,
	DiffLo     = 70,
	DiffHi     = 120,
	Rarity     = 15,

	HostName = "Absalom",

	SiteRadius  = 10,
	SiteMinDist = 4,
	SitePathMax = 20,
	SiteEdge    = 3,
	SiteSpacing = 5,
	SiteCount   = 3,

	NearRadius  = 7,
	NearPathMax = 12,

	KindDocks    = 0,
	KindDrain    = 1,
	KindQuarter  = 2,
	KindSinkhole = 3,
	Sites = [
		{ Name = "The Shanty Docks",   Bit = 1, Latch = "AtDocks",    Script = "scripts/entity/world/locations/skv_rose_docks_location" },
		{ Name = "The Drain Outfall",  Bit = 2, Latch = "AtDrain",    Script = "scripts/entity/world/locations/skv_rose_drain_location" },
		{ Name = "The Drowned Quarter",Bit = 4, Latch = "AtQuarter",  Script = "scripts/entity/world/locations/skv_rose_quarter_location" },
		{ Name = "The Sinkhole",       Bit = 0, Latch = "AtSinkhole", Script = "scripts/entity/world/locations/skv_rose_sinkhole_location" }
	],
	LeadBits = 7,

	LeadCoinBrush      = "skv_rose_coin_silver",
	QuarterSpriteScale = 0.77,

	FallbackTries = 10,

	RepairTries = 3,

	PayBase     = 250,
	PoorPayMult = 0.5,

	RumourMult  = 0.05,
	WardMult    = 0.10,
	BountyMult  = 0.10,
	PurseMult   = 0.15,
	LawMult     = 0.10,
	BrokerBase  = 0.10,
	BrokerPerT  = 0.20,

	MoralSnips    = -2,
	MoralWard     = 2,
	MoralFaithful = 3,
	MoralLaw      = 2,
	MoralBroker   = -6,

	GrantRumours     = 0x0001,
	GrantWard        = 0x0002,
	GrantBounty      = 0x0004,
	GrantPurse       = 0x0008,
	GrantFee         = 0x0010,
	GrantRenown      = 0x0020,
	GrantRelation    = 0x0040,
	GrantXP          = 0x0080,
	GrantEvidencePay = 0x0100,
	GrantEvidenceRel = 0x0200,
	GrantPotions     = 0x0400,
	GrantMoralSnips  = 0x0800,
	GrantMoralWard   = 0x1000,
	GrantMoralProof  = 0x2000,

	AlleyBase   = 80,
	AlleyWarned = 15,

	SewerBase        = 120,
	SewerCasterSplit = 0.90,
	SewerBlades      = 2,
	SewerFillMin     = 15,
	SharkName        = "Skarrith",

	FazgynEnabled    = true,
	FazgynName       = "Fazgyn",
	FazgynKobolds    = 2,

	FinaleBase   = 130,
	FinaleMin    = 72,
	FinaleFixed  = 72,
	FinaleZombies = 2,

	WennelName   = "Wennel Ardonay",
	RemnaName    = "Remna",

	RemnaWeapon  = "scripts/items/weapons/dagger",

	WennelWeapon = "scripts/items/weapons/morning_star",

	EdgeGuildDefense = 10,
	EdgeSymbolSkill  = 15,
	EdgeSymbolResolve = 15,

	WennelReportMs = 1500,

	PartyNeed      = 0.5,
	RumourCharmBase = 50,
	RumourGuileBase = 50,
	SnipsBase      = 50,
	DisarmBase     = 50,
	PitBase        = 50,
	ZirayaBase     = 50,
	StairsBase     = 50,
	WallBase       = 45,
	WarnedEdge     = 15,
	FireBase       = 50,
	StillBase      = 50,
	DescentBase    = 55,
	SideDoorBase   = 50,
	SideDoorEdge   = 15,
	VinesBase      = 45,

	HurtMin      = 4,
	HurtMax      = 10,
	BladeHurtMin = 8,
	BladeHurtMax = 15,
	BiteHurtMin  = 3,
	BiteHurtMax  = 8,

	BountyRelation = 2,
	LawRelation    = 5,
	ItemPotion     = "scripts/items/misc/skv_potion_of_cure_light_wounds",
	PotionsMax     = 3,

	ImgLodge     = "skv_grandlodge",
	ImgDocks     = "event_51",
	ImgAlley     = "event_59",
	ImgOutfall   = "skv_rose_lookout",
	ImgFazgyn    = "skv_rose_tunnels",
	ImgSharks    = "skv_rose_sharks",
	ImgStash     = "skv_rose_fazgyn",
	ImgQuarter   = "skv_bygones_docks",
	ImgManor     = "event_71",
	ImgAttic     = "event_87",
	ImgHouseFled = "event_115",
	ImgSinkhole  = "skv_rose_sinkhole",
	ImgInnDoor   = "event_74",
	ImgWennel    = "skv_rose_wennel",
	ImgRescue    = "skv_rose_sinkhole",
	ImgEvidence  = "skv_rose_milani",
	ImgFaithful  = "skv_rose_milani",
	ImgLaw       = "event_137",
	ImgBroker    = "event_62"
};
