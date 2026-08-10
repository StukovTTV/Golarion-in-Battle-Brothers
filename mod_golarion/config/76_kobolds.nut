::Const.AI.Agent.ID.SkvKoboldSkirmisher <- "agent.skv_kobold_skirmisher";
::Const.AI.Agent.ID.SkvKoboldCaster     <- "agent.skv_kobold_caster";
::Const.AI.Agent.ID.SkvKoboldYapper     <- "agent.skv_kobold_yapper";
::Const.AI.Agent.ID.SkvKoboldBomber     <- "agent.skv_kobold_bomber";

::Const.EntityType.SkvKobold <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinFighter],
	"Kobold", "Kobolds", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldSniper <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinAmbusher],
	"Kobold Sniper", "Kobold Snipers", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldBlade <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinFighter],
	"Kobold Blade", "Kobold Blades", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldChieftain <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinLeader],
	"Kobold Chieftain", "Kobold Chieftains", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldScalecaster <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinShaman],
	"Kobold Scalecaster", "Kobold Scalecasters", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldGuilecaster <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.LegendGoblinWitchDoctor],
	"Kobold Guilecaster", "Kobold Guilecasters", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldMasterTrapper <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinAmbusher],
	"Kobold Master Trapper", "Kobold Master Trappers", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldBomber <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinAmbusher],
	"Kobold Bomber", "Kobold Bombers", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldDevilspeaker <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.LegendGoblinWitchDoctor],
	"Kobold Devilspeaker", "Kobold Devilspeakers", ::Const.FactionType.Goblins);

::Const.EntityType.SkvKoboldYapper <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.GoblinFighter],
	"Kobold Yapper", "Kobold Yappers", ::Const.FactionType.Goblins);

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
	Strength = 13,
	Cost = 13,
	Row = 0,
	Script = "scripts/entity/tactical/enemies/skv_kobold",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldSniper <- {
	ID = ::Const.EntityType.SkvKoboldSniper,
	Variant = 0,
	Strength = 17,
	Cost = 17,
	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_kobold_sniper",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldBlade <- {
	ID = ::Const.EntityType.SkvKoboldBlade,
	Variant = 0,
	Strength = 18,
	Cost = 18,
	Row = 0,
	Script = "scripts/entity/tactical/enemies/skv_kobold_blade",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldYapper <- {

	ID = ::Const.EntityType.SkvKoboldYapper,
	Variant = 0,
	Strength = 47,
	Cost = 47,
	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_kobold_yapper",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldMasterTrapper <- {
	ID = ::Const.EntityType.SkvKoboldMasterTrapper,
	Variant = 0,
	Strength = 24,
	Cost = 24,
	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_kobold_master_trapper",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldBomber <- {
	ID = ::Const.EntityType.SkvKoboldBomber,
	Variant = 0,
	Strength = 26,
	Cost = 26,
	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_kobold_bomber",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldScalecaster <- {
	ID = ::Const.EntityType.SkvKoboldScalecaster,
	Variant = 0,
	Strength = 30,
	Cost = 30,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_kobold_scalecaster",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldChieftain <- {

	ID = ::Const.EntityType.SkvKoboldChieftain,
	Variant = 0,
	Strength = 65,
	Cost = 65,
	Row = 0,
	Script = "scripts/entity/tactical/enemies/skv_kobold_chieftain",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldGuilecaster <- {
	ID = ::Const.EntityType.SkvKoboldGuilecaster,
	Variant = 0,
	Strength = 45,
	Cost = 45,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_kobold_guilecaster",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvKoboldDevilspeaker <- {
	ID = ::Const.EntityType.SkvKoboldDevilspeaker,
	Variant = 0,
	Strength = 50,
	Cost = 50,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_kobold_devilspeaker",
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
	MaxR = 400,
	MinR = 15,

	Troops = [
		{
			Weight = 550,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 13 }
			]
		},
		{
			Weight = 300,
			MinR = 13,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldSniper, Cost = 17 }
			]
		},
		{
			Weight = 150,
			MinR = 75,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldBlade, Cost = 18 }
			]
		},
		{

			Weight = 5,
			MinR = 200,
			MinGuards = 1,
			MaxGuards = 1,
			Guards = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldGuilecaster, Cost = 45, Weight = 100 }
			],
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldChieftain, Cost = 65,
				  Roll = function ( _num ) { return _num < 1; } }
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
	MaxR = 400,
	MinR = 15,

	Troops = [
		{
			Weight = 450,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 13 }
			]
		},
		{
			Weight = 200,
			MinR = 13,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldSniper, Cost = 17 }
			]
		},
		{
			Weight = 150,
			MinR = 75,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldBlade, Cost = 18 }
			]
		},
		{
			Weight = 100,
			MinR = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldMasterTrapper, Cost = 24 }
			]
		},
		{
			Weight = 80,
			MinR = 13,
			MinGuards = 1,
			MaxGuards = 2,
			MaxGuardsWeight = 50,
			Guards = [
				{ Type = ::Const.World.Spawn.Troops.SkvKobold, Cost = 13, Weight = 100 }
			],
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldScalecaster, Cost = 30, Roll = true }
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
			Weight = 50,
			MinR = 175,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldYapper, Cost = 47 }
			]
		},
		{
			Weight = 30,
			MinR = 125,
			MinGuards = 1,
			MaxGuards = 2,
			MaxGuardsWeight = 50,
			Guards = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldBlade, Cost = 18, Weight = 100 }
			],
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldGuilecaster, Cost = 45, Roll = true }
			]
		},
		{
			Weight = 10,
			MinR = 175,
			MinGuards = 1,
			MaxGuards = 2,
			MaxGuardsWeight = 66,
			Guards = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldBlade, Cost = 18, Weight = 100 }
			],
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldDevilspeaker, Cost = 50, Roll = true }
			]
		},
		{

			Weight = 5,
			MinR = 200,
			MinGuards = 1,
			MaxGuards = 1,
			Guards = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldGuilecaster, Cost = 45, Weight = 100 }
			],
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvKoboldChieftain, Cost = 65,
				  Roll = function ( _num ) { return _num < 1; } }
			]
		}
	]
};
