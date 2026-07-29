// ============================================================================
//  skv_kobold_trapper -- the snare-setter (Golarion Localization).
//
//  A thin reskin of goblin_ambusher_low: same art, sounds, AI and equipment
//  tables, its own EntityType so nothing calls it a goblin, a rust-red hide, and
//  the shared kobold de-tune applied AFTER the parent has finished initialising.
//
//  ⚠ The parent is the class Legends has already hooked, so on Legendary this
//  still inherits every perk Legends grants goblins at onInit. That is the point:
//  a kobold is a smaller goblin, not a different game.
//
//  Scaling the parent's OWN BaseProperties (rather than pasting a stat table)
//  means a Legends rebalance of goblins flows straight through, and we never have
//  to know what the goblin table is called or how its day-scaling works.
// ============================================================================
this.skv_kobold_trapper <- this.inherit("scripts/entity/tactical/enemies/goblin_ambusher_low", {
	m = {},

	function create()
	{
		this.goblin_ambusher_low.create();
		this.m.Type = ::Const.EntityType.SkvKoboldTrapper;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.goblin_ambusher_low.onInit();

		local s = ::Const.Skv.KoboldScale;
		local b = this.m.BaseProperties;

		b.Hitpoints  = ::Math.max(1, ::Math.floor(b.Hitpoints * s.HealthMult));
		b.MeleeSkill  = b.MeleeSkill + s.MeleeSkill;
		b.RangedSkill = b.RangedSkill + s.RangedSkill;
		b.Bravery     = b.Bravery + s.Resolve;

		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		// Rust-red hide and the kobold's smaller frame. Both live in
		// config/76_kobolds.nut so all six reskins change together -- but the COLOUR
		// has to be built here: createColor() only exists on the entity's own `this`.
		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

});
