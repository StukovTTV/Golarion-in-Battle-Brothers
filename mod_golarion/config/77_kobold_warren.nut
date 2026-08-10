::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.Skv.WarrenNames <- [
	"The Sootscale Warren",
	"The Ashvein Warren",
	"The Cindertooth Dig",
	"The Greenscale Warren",
	"The Rockskitter Dig",
	"The Mudbelly Warren",
	"The Sharpfang Dig",
	"The Bonepick Warren",
	"The Emberclaw Warren",
	"The Ratsnest Dig",
	"The Dragonsbreath Warren",
	"The Deeprot Dig"
];

::Const.World.Spawn.GolarionKoboldRoamers <- {
	Name = "GolarionKoboldRoamers",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 400,
	MinR = 40,
	Troops = [
		{
			Weight = 550,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 13 }
			]
		},
		{
			Weight = 250,
			MinR = 13,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldSniper, Cost = 17 }
			]
		},
		{
			Weight = 120,
			MinR = 75,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldBlade, Cost = 18 }
			]
		},
		{
			Weight = 50,
			MinR = 25,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldBomber, Cost = 26 }
			]
		},
		{
			Weight = 60,
			MinR = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldMasterTrapper, Cost = 24 }
			]
		},
		{
			Weight = 60,
			MinR = 13,
			MinGuards = 1,
			MaxGuards = 1,
			Guards = [
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 13, Weight = 100 }
			],
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldScalecaster, Cost = 30, Roll = true }
			]
		}
	]
};

foreach (scriptPath in [
	"scripts/factions/actions/skv_build_kobold_warren_action",
	"scripts/factions/actions/skv_send_kobold_roamers_action"
])
{
	local already = false;

	foreach (existing in ::Const.FactionTrait.Actions[::Const.FactionTrait.Goblin])
	{
		if (existing == scriptPath)
		{
			already = true;
			break;
		}
	}

	if (!already)
	{
		::Const.FactionTrait.Actions[::Const.FactionTrait.Goblin].push(scriptPath);
	}
}
