::Const.World.Spawn.GolarionCaveBears <- {
	Name = "GolarionCaveBears",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,

	Body = "figure_werewolf_01",
	MaxR = 10000,
	MinR = 0,
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.LegendBear, Cost = 30 }
			]
		}
	]
};

::Const.Skv.ZikritraxName <- "Zikritrax";

::Const.Skv.ZikritraxTint <- "#6c7480";
::Const.Skv.ZikritraxSaturation <- 0.10;
::Const.Skv.ZikritraxLayers <- ["body", "head", "injury"];

::Const.Skv.ZikritraxTailName <- "Zikritrax";

::Const.Skv.ZikritraxChampionBudget <- 400;
