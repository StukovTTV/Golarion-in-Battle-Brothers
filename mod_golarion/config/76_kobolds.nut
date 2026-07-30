::Const.EntityType.SkvKobold <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinFighter],
	"Kobold", "Kobolds", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldTrapper <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinAmbusher],
	"Kobold Trapper", "Kobold Trappers", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldWarrior <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinFighter],
	"Kobold Warrior", "Kobold Warriors", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldChief <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinLeader],
	"Kobold Chief", "Kobold Chiefs", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldShaman <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinShaman],
	"Kobold Shaman", "Kobold Shamans", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldDragonPriest <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.LegendGoblinWitchDoctor],
	"Kobold Dragon-Priest", "Kobold Dragon-Priests", ::Const.FactionType.Goblins);

::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};
::Const.Skv.KoboldScale <- {
	HealthMult   = 0.80,
	MeleeSkill   = -5,
	RangedSkill  = -5,
	Resolve      = -5,
	CasterHealthMult = 0.85
};

::Const.Skv.KoboldTint <- "#d94a3a";

::Const.Skv.KoboldSpriteScale <- 0.90;

::Const.Skv.KoboldSpriteLayers <- ["quiver", "body", "injury_body", "armor",
                                   "head", "injury", "helmet", "helmet_damage", "body_blood"];

::Const.Skv.dressKobold <- function ( _e, _tint )
{

	if (::Const.Skv.KoboldSpriteScale != 1.0)
	{
		foreach (layer in ::Const.Skv.KoboldSpriteLayers)
		{
			try
			{
				local sp = _e.getSprite(layer);
				if (sp != null)
				{
					sp.Scale = ::Const.Skv.KoboldSpriteScale;
				}
			}
			catch (e)
			{
				::Skv.dbg("Skv.kobold: scale failed on '" + layer + "' - " + e);
			}
		}
	}

	local tint = _tint;
	if (tint == null)
	{
		::Skv.dbg("Skv.kobold: no tint was passed in - the caller could not make one");
	}

	foreach (layer in ["body", "head"])
	{
		try
		{
			local sp = _e.getSprite(layer);
			if (sp == null)
			{
				::Skv.dbg("Skv.kobold: no '" + layer + "' sprite to tint");
			}
			else if (tint != null)
			{
				sp.Color = tint;
				sp.Saturation = 0.95;
				::Skv.dbg("Skv.kobold: tinted '" + layer + "'");
			}
		}
		catch (e)
		{
			::Skv.dbg("Skv.kobold: tint failed on '" + layer + "' - " + e);
		}
	}
};

::Const.World.Spawn.Troops.SkvKobold <- {
	ID = ::Const.EntityType.SkvKobold,
	Variant = 0,
	Strength = 8,
	Cost = 8,
	Row = 0,
	Script = "scripts/entity/tactical/enemies/skv_kobold",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldTrapper <- {
	ID = ::Const.EntityType.SkvKoboldTrapper,
	Variant = 0,
	Strength = 12,
	Cost = 12,
	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_kobold_trapper",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldShaman <- {
	ID = ::Const.EntityType.SkvKoboldShaman,
	Variant = 0,
	Strength = 20,
	Cost = 20,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_kobold_shaman",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldDragonPriest <- {
	ID = ::Const.EntityType.SkvKoboldDragonPriest,
	Variant = 1,
	Strength = 42,
	Cost = 42,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_kobold_dragon_priest",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

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
		{
			Weight = 60,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 8 }
			]
		},
		{
			Weight = 40,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldTrapper, Cost = 12 }
			]
		}
	]
};

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
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 8 }
			]
		},
		{
			Weight = 35,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldTrapper, Cost = 12 }
			]
		},
		{

			Weight = 10,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldShaman, Cost = 20 },
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldDragonPriest, MinR = 300, Cost = 42 }
			]
		}
	]
};
