::Const.World.Spawn.GolarionFortressDogs <- {
	Name = "GolarionFortressDogs",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_werewolf_01",
	MaxR = 400,
	MinR = 0,
	Troops = [
		{
			Weight = 1000,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Wardog, Cost = 8 }
			]
		}
	]
};

::Const.World.Spawn.GolarionFortressSpiders <- {
	Name = "GolarionFortressSpiders",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_spider_01",
	MaxR = 400,
	MinR = 0,
	Troops = [
		{
			Weight = 1000,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Spider, Cost = 15 }
			]
		}
	]
};

::Const.World.Spawn.GolarionFortressHyenas <- {
	Name = "GolarionFortressHyenas",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_hyena_01",
	MaxR = 400,
	MinR = 0,
	Troops = [
		{
			Weight = 1000,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Hyena, Cost = 15 }
			]
		}
	]
};

::Const.World.Spawn.GolarionFortressSerpents <- {
	Name = "GolarionFortressSerpents",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_serpent_01",
	MaxR = 400,
	MinR = 0,
	Troops = [
		{
			Weight = 1000,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Serpent, Cost = 25 }
			]
		}
	]
};

::Const.World.Spawn.GolarionFortressSkeletons <- {
	Name = "GolarionFortressSkeletons",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_skeleton_01",
	MaxR = 400,
	MinR = 0,
	Troops = [
		{
			Weight = 700,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkeletonLight, Cost = 13 }
			]
		},
		{
			Weight = 300,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkeletonMedium, Cost = 20 }
			]
		}
	]
};

::Const.World.Spawn.GolarionFallenFortress <- {
	Name = "GolarionFallenFortress",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_ghoul_02",
	MaxR = 400,
	MinR = 0,
	Troops = [
		{

			Weight = 650,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyte, Cost = 12 }
			]
		},
		{

			Weight = 280,
			MinR = 20,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteSkulker, Cost = 18 }
			]
		},
		{

			Weight = 70,
			MinR = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteChampion, Cost = 32 }
			]
		}
	]
};

::logInfo("Golarion: Fallen Fortress forces loaded (6 lists)");
