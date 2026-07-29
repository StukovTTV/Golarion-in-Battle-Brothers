// ============================================================================
//  skv_tatzlwyrm -- the dragonkin whelp of Darkmoon Vale (Golarion Localization).
//
//  A thin subclass of the vanilla serpent. It keeps everything that made the
//  serpent the right BASE -- serpent_hook_skill ("Drag", range 1-3, hauls a man
//  out of your line = the module's improved grab / pounce), the ambush-predator
//  racial, the sprites and sounds -- and replaces only the stat table, because
//  the stock serpent's 130 HP behind 40/40 armour is a grind, not an ambush.
//
//  Its table (Const.Tactical.Actor.SkvTatzlwyrm) lives in
//  mod_golarion/config/75_vale_forces.nut, which loads before this ever runs.
//
//  Its NAME comes from its own EntityType, registered with Legends'
//  Const.EntityType.addNew in config/75_vale_forces.nut. The troop def's Name
//  field does NOT work here: that is applied on the world-party spawner path,
//  and a contract's addUnitsToCombat does not go through it.
// ============================================================================
this.skv_tatzlwyrm <- this.inherit("scripts/entity/tactical/enemies/serpent", {
	m = {},

	function create()
	{
		this.serpent.create();

		// Its own type -- this is what makes the scout report say "A few Tatzlwyrms"
		// and the tooltip say Tatzlwyrm, because both read the TYPE, not the entity.
		this.m.Type = ::Const.EntityType.SkvTatzlwyrm;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		// Base serpent onInit first: sprites, sounds, skills, AI agent. It also
		// applies the serpent's own day-based scaling to BaseProperties -- which we
		// then overwrite wholesale, deliberately. This beast does not get tougher
		// because the campaign is old; the contract's budget scaling handles that.
		this.serpent.onInit();

		local b = this.m.BaseProperties;
		b.setValues(::Const.Tactical.Actor.SkvTatzlwyrm);
		b.IsAffectedByNight = false;
		b.IsImmuneToDisarm = true;

		this.m.XP = ::Const.Tactical.Actor.SkvTatzlwyrm.XP;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		// CAMOUFLAGE. Bestiary 3: "A tatzlwyrm's scales give the creature limited
		// camouflage, ranging through various shades of green, brown, and gray."
		// The serpent art is a sandy desert snake and randomises its own tint in
		// onInit; we overwrite that with a forest olive so a tatzlwyrm and a plain
		// serpent are never mistaken for each other on the same field. Color is a
		// multiply over the sprite, so this darkens as well as greens it -- which
		// suits something that waits in a canopy. The serpent's onDeath copies
		// body.Color onto the corpse decals, so the dead one matches.
		local body = this.getSprite("body");
		body.Color = this.createColor("#9db07a");
		body.Saturation = 0.9;

		// SMALLER JAWS. The stock serpent bite adds a flat +50/+70 damage, which is
		// a great serpent's mouthful and not a whelp's -- swap it for our own, which
		// subclasses the same skill and takes about a third off. Done AFTER
		// serpent.onInit(), because that is what put the original on him.
		this.getSkills().removeByID("actives.serpent_bite");
		this.m.Skills.add(::new("scripts/skills/actives/skv_tatzlwyrm_bite_skill"));
	}

});
