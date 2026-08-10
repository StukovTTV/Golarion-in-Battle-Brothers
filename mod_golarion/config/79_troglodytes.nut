::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};

::Const.EntityType.SkvTroglodyte <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte", "Troglodytes", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteSkulker <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Skulker", "Troglodyte Skulkers", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteBeastSpeaker <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Beast-Speaker", "Troglodyte Beast-Speakers", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodytePriest <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Priest", "Troglodyte Priests", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteSorcerer <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Sorcerer", "Troglodyte Sorcerers", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteScaleRider <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Scale-Rider", "Troglodyte Scale-Riders", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteChampion <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Champion", "Troglodyte Champions", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteChieftain <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Chieftain", "Troglodyte Chieftains", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteWarrenGuard <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Warren Guard", "Troglodyte Warren Guards", ::Const.FactionType.Beasts);

::Const.EntityType.SkvTroglodyteTyrant <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Ghoul],
	"Troglodyte Tyrant", "Troglodyte Tyrants", ::Const.FactionType.Beasts);

::Const.Tactical.Actor.SkvTroglodyte <- {
	XP = 60,
	ActionPoints = 9,
	Hitpoints = 50,
	Bravery = 55,
	Stamina = 120,
	MeleeSkill = 55,
	RangedSkill = 30,
	MeleeDefense = 0,
	RangedDefense = 5,
	Initiative = 90,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 25, 15 ]
};

::Const.Tactical.Actor.SkvTroglodyteSkulker <- {
	XP = 100,
	ActionPoints = 9,
	Hitpoints = 68,
	Bravery = 55,
	Stamina = 120,
	MeleeSkill = 60,
	RangedSkill = 40,
	MeleeDefense = 10,
	RangedDefense = 10,
	Initiative = 120,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 25, 15 ]
};

::Const.Tactical.Actor.SkvTroglodyteChampion <- {
	XP = 250,
	ActionPoints = 9,
	Hitpoints = 113,
	Bravery = 75,
	Stamina = 150,
	MeleeSkill = 72,
	RangedSkill = 45,
	MeleeDefense = 0,
	RangedDefense = 5,
	Initiative = 95,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 90, 45 ]
};

::Const.Tactical.Actor.SkvTroglodyteWarrenGuard <- {
	XP = 350,
	ActionPoints = 10,
	Hitpoints = 139,
	Bravery = 100,
	Stamina = 180,
	MeleeSkill = 78,
	RangedSkill = 0,
	MeleeDefense = -5,
	RangedDefense = 0,
	Initiative = 105,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 45, 25 ]
};

::Const.Tactical.Actor.SkvTroglodyteBeastSpeaker <- {
	XP = 200,
	ActionPoints = 9,
	Hitpoints = 72,
	Bravery = 60,
	Stamina = 120,
	MeleeSkill = 55,
	RangedSkill = 35,
	MeleeDefense = 5,
	RangedDefense = 10,
	Initiative = 115,

	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 25, 15 ]
};

::Const.Tactical.Actor.SkvTroglodytePriest <- {
	XP = 220,
	ActionPoints = 8,

	Hitpoints = 70,
	Bravery = 80,

	Stamina = 110,
	MeleeSkill = 68,

	RangedSkill = 30,
	MeleeDefense = 0,
	RangedDefense = 5,
	Initiative = 80,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 55, 30 ]
};

::Const.Tactical.Actor.SkvTroglodyteSorcerer <- {
	XP = 260,
	ActionPoints = 9,
	Hitpoints = 65,

	Bravery = 65,
	Stamina = 110,
	MeleeSkill = 50,
	RangedSkill = 40,
	MeleeDefense = 10,
	RangedDefense = 10,
	Initiative = 105,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 25, 15 ]
};

::Const.Tactical.Actor.SkvTroglodyteScaleRider <- {
	XP = 200,
	ActionPoints = 9,
	Hitpoints = 95,

	Bravery = 65,
	Stamina = 140,
	MeleeSkill = 62,
	RangedSkill = 70,
	MeleeDefense = 10,
	RangedDefense = 20,

	Initiative = 125,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 25, 15 ]
};

::Const.Tactical.Actor.SkvTroglodyteChieftain <- {
	XP = 400,
	ActionPoints = 11,

	Hitpoints = 150,

	Bravery = 90,
	Stamina = 170,
	MeleeSkill = 82,

	RangedSkill = 40,
	MeleeDefense = 5,
	RangedDefense = 5,
	Initiative = 110,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 65, 35 ],

	DamageTotalMult = 1.15
};

::Const.Tactical.Actor.SkvTroglodyteTyrant <- {
	XP = 550,
	ActionPoints = 8,

	Hitpoints = 175,
	Bravery = 100,

	Stamina = 150,
	MeleeSkill = 88,

	RangedSkill = 35,

	MeleeDefense = 5,
	RangedDefense = 10,
	Initiative = 85,
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [ 120, 60 ],

	DamageTotalMult = 1.1
};

::Const.Skv.TroglodyteScheme <- {
	Color          = "#8a9468",
	Saturation     = 0.85,
	SaturationVary = 0.25,
	ColorVary      = [0.16, 0.16, 0.15],
	Brightness     = 0.85,

	ScaleVary      = 0.07
};

::Const.Skv.TroglodyteSpriteLayers <- ["body", "head", "injury"];

::Const.Skv.TroglodyteBustTier1 <- {
	Body    = "bust_ghoul_body_01",
	Head    = "bust_ghoul_head_01",
	Injury  = "bust_ghoul_01_injured",
	RootScale = 0.45,
	RootOffset = [-4, 7]
};

::Const.Skv.TroglodyteBustTier2 <- {
	Body    = "bust_ghoul_body_02",
	Head    = "bust_ghoul_02_head_01",
	Injury  = "bust_ghoul_02_injured",
	SplatterOffset = [33, -26],
	SplatterAmount = 1.0,
	BloodPoolScale = 1.0,
	RootScale = 0.5,
	RootOffset = [-4, 10]
};

::Const.Skv.TroglodyteBust <- {};
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyte] <- ::Const.Skv.TroglodyteBustTier1;

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteSkulker] <- clone ::Const.Skv.TroglodyteBustTier2;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteSkulker].Head = "bust_ghoul_02_head_01";

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteChampion] <- clone ::Const.Skv.TroglodyteBustTier2;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteChampion].Head = "bust_ghoul_02_head_02";

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteWarrenGuard] <- clone ::Const.Skv.TroglodyteBustTier2;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteWarrenGuard].Head = "bust_ghoul_02_head_03";

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteBeastSpeaker] <- ::Const.Skv.TroglodyteBustTier1;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodytePriest] <- ::Const.Skv.TroglodyteBustTier1;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteSorcerer] <- ::Const.Skv.TroglodyteBustTier1;

::Const.Skv.TroglodyteBustTier3 <- {
	Body    = "bust_ghoul_body_03",
	Head    = "bust_ghoul_03_head_01",
	Injury  = "bust_ghoul_03_injured",
	SplatterOffset = [33, -26],
	SplatterAmount = 1.0,
	BloodPoolScale = 1.0,
	RootScale = 0.6,
	RootOffset = [-4, 14]
};

::Const.Skv.TroglodyteBustTier4 <- {
	Body    = "bust_ghoul_body_04",
	Head    = "bust_ghoul_04_head_01",
	Injury  = "bust_ghoul_04_injured",
	SplatterOffset = [33, -26],
	SplatterAmount = 1.0,
	BloodPoolScale = 1.0,
	RootScale = 0.65,
	RootOffset = [-4, 16]
};

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteScaleRider] <- clone ::Const.Skv.TroglodyteBustTier3;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteScaleRider].Head = "bust_ghoul_03_head_01";

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteChieftain] <- clone ::Const.Skv.TroglodyteBustTier3;
::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteChieftain].Head = "bust_ghoul_03_head_02";

::Const.Skv.TroglodyteBust[::Const.EntityType.SkvTroglodyteTyrant] <- ::Const.Skv.TroglodyteBustTier4;

::Const.Skv.dressTroglodyteBust <- function ( _entity )
{

	local type = _entity.getType();
	if (!(type in ::Const.Skv.TroglodyteBust)) return;
	local set = ::Const.Skv.TroglodyteBust[type];
	if (set == null) return;

	foreach( pair in [ ["body", set.Body], ["head", set.Head], ["injury", set.Injury] ] )
	{
		local layer = pair[0];
		local brush = pair[1];

		try
		{
			if (!_entity.hasSprite(layer)) continue;
			if (!::doesBrushExist(brush))
			{
				::logError("Skv.Troglodyte: brush '" + brush + "' does not exist, keeping the stock ghoul layer '" + layer + "'");
				continue;
			}
			_entity.getSprite(layer).setBrush(brush);
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: could not set the '" + layer + "' brush (it keeps the ghoul's): " + e);
		}
	}

	try
	{
		if ("SplatterOffset" in set) _entity.m.DecapitateSplatterOffset = ::createVec(set.SplatterOffset[0], set.SplatterOffset[1]);
		if ("SplatterAmount" in set) _entity.m.DecapitateBloodAmount = set.SplatterAmount;
		if ("BloodPoolScale" in set) _entity.m.BloodPoolScale = set.BloodPoolScale;

		foreach( name in ["status_rooted", "status_rooted_back"] )
		{
			if (!_entity.hasSprite(name)) continue;
			if ("RootScale" in set) _entity.getSprite(name).Scale = set.RootScale;
			if ("RootOffset" in set) _entity.setSpriteOffset(name, ::createVec(set.RootOffset[0], set.RootOffset[1]));
		}
	}
	catch (e)
	{
		::logError("Skv.Troglodyte: could not adjust the blood and root offsets for the bust (cosmetic only): " + e);
	}
};

::Const.Skv.dressTroglodyte <- function ( _entity )
{
	local s = ::Const.Skv.TroglodyteScheme;
	local source = null;

	foreach( layer in ::Const.Skv.TroglodyteSpriteLayers )
	{
		try
		{
			if (!_entity.hasSprite(layer)) continue;
			local spr = _entity.getSprite(layer);
			if (spr == null) continue;

			if (source != null)
			{

				spr.Color = source.Color;
				spr.Saturation = source.Saturation;
				continue;
			}

			spr.Saturation = s.Saturation;
			if (s.SaturationVary > 0) spr.varySaturation(s.SaturationVary);
			spr.Color = ::createColor(s.Color);

			try { if (s.Brightness != null) spr.setBrightness(s.Brightness); } catch (e) {}

			if (s.ColorVary != null) spr.varyColor(s.ColorVary[0], s.ColorVary[1], s.ColorVary[2]);

			source = spr;
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: could not tint layer '" + layer + "' (the creature still spawns): " + e);
		}
	}

	try
	{
		if ("ScaleVary" in s && s.ScaleVary > 0)
		{
			local scale = 1.0 + (::Math.rand(0, 2000) / 1000.0 - 1.0) * s.ScaleVary;

			foreach( layer in ::Const.Skv.TroglodyteSpriteLayers )
			{
				if (!_entity.hasSprite(layer)) continue;
				_entity.getSprite(layer).Scale = scale;
			}
		}
	}
	catch (e)
	{
		::logError("Skv.Troglodyte: could not vary the bust scale (they are all the same size): " + e);
	}

	try { _entity.m.BloodColor = _entity.getSprite("body").Color; } catch (e) {}
};

::Const.AI.Agent.ID.SkvTroglodyte <- "agent.skv_troglodyte";

::Const.AI.Agent.ID.SkvTroglodyteCaster <- "agent.skv_troglodyte_caster";

::Const.AI.Agent.ID.SkvTroglodyteSkirmisher <- "agent.skv_troglodyte_skirmisher";

::Const.World.Spawn.Troops.SkvTroglodyte <- {
	ID = ::Const.EntityType.SkvTroglodyte,
	Variant = 0,
	Strength = 12,
	Cost = 12,
	Row = 0,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteSkulker <- {
	ID = ::Const.EntityType.SkvTroglodyteSkulker,
	Variant = 0,
	Strength = 18,
	Cost = 18,

	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_skulker",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteChampion <- {
	ID = ::Const.EntityType.SkvTroglodyteChampion,
	Variant = 0,
	Strength = 32,
	Cost = 32,

	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_champion",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteWarrenGuard <- {
	ID = ::Const.EntityType.SkvTroglodyteWarrenGuard,
	Variant = 0,
	Strength = 45,
	Cost = 45,

	Row = 0,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_warren_guard",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteBeastSpeaker <- {
	ID = ::Const.EntityType.SkvTroglodyteBeastSpeaker,
	Variant = 0,
	Strength = 30,
	Cost = 30,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_beast_speaker",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodytePriest <- {
	ID = ::Const.EntityType.SkvTroglodytePriest,
	Variant = 0,
	Strength = 34,
	Cost = 34,

	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_priest",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteSorcerer <- {
	ID = ::Const.EntityType.SkvTroglodyteSorcerer,
	Variant = 0,
	Strength = 38,
	Cost = 38,
	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_sorcerer",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteScaleRider <- {
	ID = ::Const.EntityType.SkvTroglodyteScaleRider,
	Variant = 0,
	Strength = 28,
	Cost = 28,

	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_scale_rider",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteChieftain <- {
	ID = ::Const.EntityType.SkvTroglodyteChieftain,
	Variant = 0,
	Strength = 55,
	Cost = 55,

	Row = 1,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_chieftain",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.Troops.SkvTroglodyteTyrant <- {
	ID = ::Const.EntityType.SkvTroglodyteTyrant,
	Variant = 0,
	Strength = 70,
	Cost = 70,

	Row = 2,
	Script = "scripts/entity/tactical/enemies/skv_troglodyte_tyrant",
	NameList = ::Const.Strings.GoblinNames,
	TitleList = ::Const.Strings.GoblinTitles
};

::Const.World.Spawn.GolarionTroglodyteRoamers <- {
	Name = "GolarionTroglodyteRoamers",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_ghoul_02",
	MaxR = 400,
	MinR = 40,
	Troops = [
		{
			Weight = 550,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyte, Cost = 12 }
			]
		},
		{
			Weight = 250,
			MinR = 20,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteSkulker, Cost = 18 }
			]
		},
		{
			Weight = 110,
			MinR = 55,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteScaleRider, Cost = 28 }
			]
		},
		{
			Weight = 90,
			MinR = 70,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteBeastSpeaker, Cost = 30 }
			]
		},
		{
			Weight = 80,
			MinR = 85,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteChampion, Cost = 32 }
			]
		},
		{
			Weight = 60,
			MinR = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteSorcerer, Cost = 38 }
			]
		},
		{
			Weight = 60,
			MinR = 110,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodytePriest, Cost = 34 }
			]
		},
		{
			Weight = 50,
			MinR = 130,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteWarrenGuard, Cost = 45 }
			]
		},
		{
			Weight = 30,
			MinR = 170,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteChieftain, Cost = 55 }
			]
		},
		{
			Weight = 20,
			MinR = 220,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTroglodyteTyrant, Cost = 70 }
			]
		}
	]
};
