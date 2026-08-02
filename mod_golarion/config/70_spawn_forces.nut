::Const.Strings.SkvCultNames  <- [
	"Yannic", "Ysandra", "Corvin", "Delenah", "Ostarian", "Vibia",
	"Ureste", "Piousa", "Marduzi", "Aswaithe", "Zoresk", "Iomestria"
];
::Const.Strings.SkvCultTitles <- [
	"the Tender", "Mouth of the Pool", "the Hollow", "the Silent",
	"of the Depths", "the Drowned Voice", "who does not speak"
];

::Const.World.Spawn.Troops.SkvCultChampion <- {
	ID        = ::Const.EntityType.Cultist,
	Variant   = 200,
	Strength  = 30,
	Cost      = 30,
	Row       = 0,
	Script    = "scripts/entity/tactical/humans/skv_cult_champion",
	NameList  = ::Const.Strings.SkvCultNames,
	TitleList = ::Const.Strings.SkvCultTitles
};

::Const.World.Spawn.GolarionCult <- {
	Name = "GolarionCult",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_civilian_03",
	MaxR = 600,
	MinR = 80,
	Fixed = [
		{
			Type = ::Const.World.Spawn.Troops.SkvCultChampion,
			Cost = 30,
			Weight = 0,
			MinGuards = 1,
			MaxGuards = 4,
			MaxGuardsWeight = 40,
			Guards = [
				{
					Type = ::Const.World.Spawn.Troops.Militia,
					MaxR = 250, Cost = 10,
					function Weight( scale ) { return this.Math.max(0, 100 - scale * 100); }
				},
				{
					Type = ::Const.World.Spawn.Troops.MilitiaVeteran,
					MinR = 150, Cost = 12,
					function Weight( scale ) { return this.Math.max(0, 100 - scale * 100); }
				},
				{
					Type = ::Const.World.Spawn.Troops.Mercenary,
					MinR = 300, Cost = 25,
					function Weight( scale ) { return this.Math.min(100, scale * 100); }
				},
				{
					Type = ::Const.World.Spawn.Troops.HedgeKnight,
					MinR = 450, Cost = 40,
					function Weight( scale ) { return this.Math.min(100, this.Math.max(0, (scale - 0.5) * 200)); }
				}
			]
		}
	],
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.CultistAmbush, Cost = 15 }
			]
		}
	]
};
