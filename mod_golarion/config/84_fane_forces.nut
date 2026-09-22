::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.Fane <- {

	RenownGate = 500,

	MercBase = 70.0,
	MercMin  = 45.0,

	WolfBase     = 97.0,
	DaemonCharge = 60.0,
	WolfMin      = 40.0,
	DaemonName   = "Ceustodaemon",
	DaemonTint   = "#b0705a",
	WolfTint     = "#f0583c",
	WolfSaturation = 1.35,

	RitualDaemonHP = 0.70,
	RitualWolfHP   = 0.80,

	BreathCooldown = 3,
	BreathAccuracy = 20,

	TracksBase  = 55,
	StatuesBase = 50,
	MossBase    = 45,
	TalkBase    = 50,
	CallOutBase = 10,
	CallOutPerClue = 20,
	RitualBase  = 55,
	RitualForced = 25,
	VerdictBase = 40,
	VerdictSymbols = 15,
	VerdictPerClue = 5,
	VerdictUnmasked = 15,
	ClockLimit  = 3,

	PayBase     = 200,
	PayWealthLo = 0.6,
	PayWealthHi = 1.1,
	SpearPath   = "scripts/items/weapons/boar_spear",
	SpearTier   = 1,
	SymbolPath  = "scripts/items/loot/skv_erastil_symbol",
	MoralPass   = 3,
	MoralFail   = -3,

	ClueTracks = 0x01,
	ClueFangs  = 0x02,
	ClueBlood  = 0x04,
	ClueTalk   = 0x08,
	MarkPools    = 0x01,
	MarkSymbols  = 0x02,
	MarkForced   = 0x04,
	MarkRitualTried = 0x08,
	MarkRitualHeld  = 0x10,
	MarkVerdict  = 0x20,
	MarkTracksTried  = 0x40,
	MarkStatuesTried = 0x80,
	MarkMossTried    = 0x100,
	MarkTalkTried    = 0x200,
	MarkVerdictDone  = 0x400
};

::Const.Skv.Fane.forestTypes <- function ()
{
	local T = ::Const.World.TerrainType;
	return [T.Forest, T.LeaveForest, T.AutumnForest, T.SnowyForest];
};

::Const.Tactical.Actor.SkvCeustodaemon <- {
	XP = 200,
	ActionPoints = 9,
	Hitpoints = 80,
	Bravery = 50,
	Stamina = 130,
	MeleeSkill = 45,
	RangedSkill = 45,
	MeleeDefense = 10,
	RangedDefense = 15,
	Initiative = 125,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		0,
		0
	]
};

::Const.AI.Agent.ID.SkvCeustodaemon <- "agent.skv_ceustodaemon";

::Const.EntityType.SkvCeustodaemon <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Ceustodaemon", "Ceustodaemons", ::Const.FactionType.Beasts);

::Const.World.Spawn.GolarionFaneMercs <- {
	Name = "GolarionFaneMercs",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_bandit_01",
	MaxR = 600,
	Troops = [
		{
			Weight = 45,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.MercenaryLOW, Cost = 18 }
			]
		},
		{
			Weight = 40,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Mercenary, Cost = 25 }
			]
		},
		{
			Weight = 15,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.MercenaryRanged, Cost = 25 }
			]
		}
	]
};

::Const.World.Spawn.GolarionFaneWolves <- {
	Name = "GolarionFaneWolves",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_werewolf_01",
	MaxR = 600,
	Troops = [
		{
			Weight = 70,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Direwolf, Cost = 20 }
			]
		},
		{
			Weight = 30,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.DirewolfHIGH, Cost = 25 }
			]
		}
	]
};

::logInfo("Golarion: Fane of Fangs forces loaded (2 lists, the daemon's table)");
