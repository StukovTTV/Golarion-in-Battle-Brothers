// ==========================================================================
//  Darkmoon Vale forces (Hollow's Last Hope, contract #10)
// ==========================================================================
// Enemy base stat tables live in the ENGINE, not in any script -- but they are
// writable from script, which is how Legends adds LegendWhiteDirewolf. So a new
// beast gets its own table here rather than a patched-up copy of someone else's.

// --------------------------------------------------------------------------
//  TATZLWYRM -- the dragonkin whelp in the elder darkwood.
// --------------------------------------------------------------------------
// A REAL entity type of its own, so the scout report reads "A few Tatzlwyrms"
// and the tooltip says Tatzlwyrm. Reusing EntityType.Serpent gave it the serpent's
// name everywhere, because the name is looked up from the TYPE, not from the
// troop def (the troop def's Name field is only applied on the spawner path that
// world parties take -- addUnitsToCombat does not go through it).
//
// ::Const.EntityType.addNew(_icon, _name, _plural, _faction) is Legends' own API
// (mod_legends/!!config/_global.nut): it pushes onto EntityIcon / EntityName /
// EntityNamePlural / EntityFaction and returns the new id. It is how Legends adds
// Bears, Halberdiers and the rest.
//
// The icon is READ FROM THE SERPENT rather than guessed -- EntityIcon is indexed
// by type, so this is always the right asset name without hardcoding it.
//
// ⚠ ids are assigned by array length at load, so they shift if the player's mod
// set changes. That is true of every addNew user including Legends; do not persist
// a raw EntityType id anywhere.
::Const.EntityType.SkvTatzlwyrm <- ::Const.EntityType.addNew(
	::Const.EntityIcon[::Const.EntityType.Serpent],
	"Tatzlwyrm",
	"Tatzlwyrms",
	::Const.FactionType.Beasts
);
// Built on the SERPENT, whose serpent_hook_skill is literally "Drag" (range 1-3,
// pulls the target in) = the module's improved grab / pounce. What made the stock
// serpent wrong for a tree lurker was ARMOUR: 130 HP behind 40/40 plus a racial
// -34% while not engaged is a grind, not an ambush.
//
// Reference (engine values, dumped in-game; identical on Beginner and Legendary):
//   Serpent  HP 130  MSk 65  MDef 10  RDef 25  Init  50  Arm 40/40  XP 200
//   Spider   HP  50  MSk 60  MDef 10  RDef 20  Init 150  Arm 10/10  XP 100
//   Wolf     HP  40  MSk 65  MDef 15  RDef 10  Init 140  Arm  0/0   XP 100
::Const.Tactical.Actor.SkvTatzlwyrm <- {
	XP = 150,
	ActionPoints = 9,
	Hitpoints = 95,          // vs serpent 130
	Bravery = 90,
	Stamina = 90,            // NOT 130 -- see the Dodge note below
	MeleeSkill = 65,
	RangedSkill = 0,
	MeleeDefense = 15,       // a lithe climber, harder to pin than a fat snake
	RangedDefense = 15,      // vs serpent 25
	Initiative = 110,        // vs serpent 50 -- it POUNCES, it does not slither
	FatigueEffectMult = 1.0,
	MoraleEffectMult = 1.0,
	Armor = [
		20,                  // vs serpent 40/40 -- the decisive change
		20
	]
};
// ⚠ STAMINA IS SECRETLY A DEFENSIVE STAT ON LEGENDARY. Legends grants the serpent
// (and so this) the Dodge perk at Legendary difficulty, and Dodge converts REMAINING
// FATIGUE into melee and ranged defence. At the first build's Stamina 130 the field
// tooltip read MDef 34 / RDef 34 against the 15 written above -- a de-tuned lurker
// defending better than the stock serpent it was supposed to be weaker than. 90 both
// suits a whelp and trims the Legendary bonus, and changes nothing at all below it.

// Name comes from the troop def: the spawner does setName(_t.Name) for any entity.
::Const.World.Spawn.Troops.SkvTatzlwyrm <- {
	ID       = ::Const.EntityType.SkvTatzlwyrm,
	Variant  = 0,            // NOT a champion (Variant != 0 would call makeMiniboss)
	Strength = 14,
	Cost     = 14,
	Row      = -1,
	Script   = "scripts/entity/tactical/enemies/skv_tatzlwyrm"
};

// A NEST, not a lone beast -- and that is canon: the module's own monster entry
// reads "Organization: Solitary or nest (2-5)". It is also what explains three
// hunters hanging in the high limbs of one tree.
// Body is never rendered for this list: the contract runs its own scripted combat
// via addUnitsToCombat and spawns no world party.
::Const.World.Spawn.GolarionTatzlwyrms <- {
	Name = "GolarionTatzlwyrms",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 200,
	MinR = 14,
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.SkvTatzlwyrm, Cost = 14 }
			]
		}
	]
};

// --------------------------------------------------------------------------
//  WOLVES -- the module's ordinary wolves, not direwolves.
// --------------------------------------------------------------------------
// We define NO wolf troop of our own: Legends already ships one in
// mod_legends/!config/spawnlist_master.nut --
//     Troops.Wolf { ID = EntityType.Wolf, Strength = 15, Cost = 20,
//                   Script = "scripts/entity/tactical/enemies/wolf" }
// -- and it loads before this file (our config runs inside the post-mod_legends
// queue). Using theirs means any Legends rebalance of wolves flows through to us
// instead of us quietly drifting from it.
//
// Cost 20 looks steep for a 40 HP unarmoured animal (a Direwolf is 130 HP behind
// 30/30 for the same 20) -- but it is their balance call, and it happens to land
// the source exactly: a 40 budget buys the TWO wolves the module says patrol "the
// far reaches of their master's claimed territory", and 60 buys the three-ish of
// the den, both growing with company strength from there.

// Graypelt's patrols. Plain wolves only -- his personal pack tiers up in Phase 3,
// this one does not.
::Const.World.Spawn.GolarionValeWolves <- {
	Name = "GolarionValeWolves",
	IsDynamic = true,
	MovementSpeedMult = 1.0,
	VisibilityMult = 1.0,
	VisionMult = 1.0,
	Body = "figure_goblin_02",
	MaxR = 200,
	MinR = 20,
	Troops = [
		{
			Weight = 100,
			Types = [
				{ Type = ::Const.World.Spawn.Troops.Wolf, Cost = 20 }
			]
		}
	]
};
