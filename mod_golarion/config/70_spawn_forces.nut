// ==========================================================================
//  Cult forces (for the Black Forks contract, and reusable for any cult site)
// ==========================================================================
// NOTE: `<-` (create NEW slot), NOT `=` -- these are new keys, so `=` throws
// "the index does not exist" at load. (CityStateNames/NobleHouseNames above use `=`: existing keys.)
::Const.Strings.SkvCultNames  <- [
	"Yannic", "Ysandra", "Corvin", "Delenah", "Ostarian", "Vibia",
	"Ureste", "Piousa", "Marduzi", "Aswaithe", "Zoresk", "Iomestria"
];
::Const.Strings.SkvCultTitles <- [
	"the Tender", "Mouth of the Pool", "the Hollow", "the Silent",
	"of the Depths", "the Drowned Voice", "who does not speak"
];

// Champion-capable cultist troop: Variant 200 -> makeMiniboss() always fires
// (champion buff + rolled name+title). A NEW type, so ordinary cultists are untouched.
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

// Night cult: guaranteed champion leader (Fixed) + auto-scaling militia->mercenary
// retinue (Guards) + cultist body (Troops). scale = budget / MaxR, climbs with company strength.
::Const.World.Spawn.GolarionCult <- {
	Name = "GolarionCult",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_civilian_03",
	MaxR = 600,   // budget at "fully escalated" (scale -> 1.0)
	MinR = 80,    // floor: even a weak company faces a small escort
	Fixed = [
		{
			Type = ::Const.World.Spawn.Troops.SkvCultChampion,
			Cost = 30,
			Weight = 0,                 // guaranteed leader, deduped from the pool
			MinGuards = 1,
			MaxGuards = 4,
			MaxGuardsWeight = 40,       // 1 guaranteed guard + up to 3 more @40% each
			Guards = [
				{   // TIER 1 - Militia: common when weak, gone when strong
					Type = ::Const.World.Spawn.Troops.Militia,
					MaxR = 250, Cost = 10,
					function Weight( scale ) { return this.Math.max(0, 100 - scale * 100); }
				},
				{   // TIER 2 - Militia Veteran: the mid bridge
					Type = ::Const.World.Spawn.Troops.MilitiaVeteran,
					MinR = 150, Cost = 12,
					function Weight( scale ) { return this.Math.max(0, 100 - scale * 100); }
				},
				{   // TIER 3 - Mercenary: rises with strength
					Type = ::Const.World.Spawn.Troops.Mercenary,
					MinR = 300, Cost = 25,
					function Weight( scale ) { return this.Math.min(100, scale * 100); }
				},
				{   // TIER 4 - Hedge Knight: elite, only for strong companies
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

// ---- Golarion KOBOLDS: reusable "reads-as-kobold" goblin lists ----
// Stock small foot-goblins only (skirmisher + ambusher), no greenskin cavalry, so a "kobold"
// fight never escalates into heavy cavalry. MinR 15 (vs stock 55/75) lets budget govern size.

// (1) Warriors only -- the clean warm-up / no-caster variant.
::Const.World.Spawn.GolarionKobolds <- {
	Name = "GolarionKobolds",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 600,
	MinR = 15,
	Troops = [
		{   // Skirmisher line: goblin_fighter_low -> goblin_fighter at MinR 120.
			Weight = 55,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.GoblinSkirmisherLOW, Cost = 10 },
				{ Type = ::Const.World.Spawn.Troops.GoblinSkirmisher, MinR = 99, Cost = 15 }
			]
		},
		{   // Ambusher/trapper line: goblin_ambusher_low -> goblin_ambusher at MinR 180. No MaxR.
			Weight = 45,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.GoblinAmbusherLOW, Cost = 15 },
				{ Type = ::Const.World.Spawn.Troops.GoblinAmbusher, MinR = 139, Cost = 20 }
			]
		}
	]
};

// (2) With casters -- same warriors PLUS a rare dragon-priest caster tier (shaman ungated
// at low weight; LegendGoblinWitchDoctor the rare elite).
::Const.World.Spawn.GolarionKoboldsCasters <- {
	Name = "GolarionKoboldsCasters",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 600,
	MinR = 15,
	Troops = [
		{
			Weight = 55,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.GoblinSkirmisherLOW, Cost = 10 },
				{ Type = ::Const.World.Spawn.Troops.GoblinSkirmisher, MinR = 99, Cost = 15 }
			]
		},
		{
			Weight = 45,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.GoblinAmbusherLOW, Cost = 15 },
				{ Type = ::Const.World.Spawn.Troops.GoblinAmbusher, MinR = 139, Cost = 20 }
			]
		},
		{   // Caster tier: shaman -> witch-doctor. MinR calibrated to this contract's
			// reachable budget (~460), so the witch-doctor upgrade actually appears.
			Weight = 2,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.GoblinShaman, Cost = 35 },
				{ Type = ::Const.World.Spawn.Troops.LegendGoblinWitchDoctor, MinR = 299, Cost = 50 }
			]
		}
	]
};
