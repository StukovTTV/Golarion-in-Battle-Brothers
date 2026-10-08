::Const.Skv.Silent <- {

	Hosts = [

		[
			{ Type = ::Const.World.Spawn.Troops.Zombie,          Num = 14 },
			{ Type = ::Const.World.Spawn.Troops.ZombieYeoman,    Num = 10 },
			{ Type = ::Const.World.Spawn.Troops.ZombieKnight,    Num = 6 },
			{ Type = ::Const.World.Spawn.Troops.ZombieBetrayer,  Num = 2 }
		],

		[
			{ Type = ::Const.World.Spawn.Troops.SkeletonLight,          Num = 6 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonMedium,         Num = 8 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonMediumPolearm,  Num = 4 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavy,          Num = 6 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavyPolearm,   Num = 3 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonPriest,         Num = 2 }
		],

		[
			{ Type = ::Const.World.Spawn.Troops.SkeletonBoss,            Num = 1 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavy,           Num = 4, Champion = true },
			{ Type = ::Const.World.Spawn.Troops.ZombieKnight,            Num = 2, Champion = true },
			{ Type = ::Const.World.Spawn.Troops.ZombieBetrayer,          Num = 1, Champion = true },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavyBodyguard,  Num = 4 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonPriest,          Num = 2 }
		]
	],

	Pools = [
		[
			{ Type = ::Const.World.Spawn.Troops.Zombie,        Weight = 3 },
			{ Type = ::Const.World.Spawn.Troops.ZombieYeoman,  Weight = 2 },
			{ Type = ::Const.World.Spawn.Troops.ZombieKnight,  Weight = 1 }
		],
		[
			{ Type = ::Const.World.Spawn.Troops.SkeletonLight,          Weight = 2 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonMedium,         Weight = 3 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonMediumPolearm,  Weight = 1 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavy,          Weight = 1 }
		],
		[
			{ Type = ::Const.World.Spawn.Troops.SkeletonMedium,        Weight = 2 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavy,         Weight = 2 },
			{ Type = ::Const.World.Spawn.Troops.SkeletonHeavyPolearm,  Weight = 1 },
			{ Type = ::Const.World.Spawn.Troops.ZombieKnight,          Weight = 1 }
		]
	],

	Treasure = [
		"scripts/items/loot/ancient_gold_coins_item",
		"scripts/items/loot/ancient_gold_coins_item",
		"scripts/items/loot/jade_broche_item",
		"scripts/items/loot/bone_figurines_item",
		"scripts/items/loot/white_pearls_item"
	],
	TreasureNum = 3
};
