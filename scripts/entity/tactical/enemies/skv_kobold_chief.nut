this.skv_kobold_chief <- this.inherit("scripts/entity/tactical/enemies/goblin_leader", {
	m = {},

	function create()
	{
		this.goblin_leader.create();
		this.m.Type = ::Const.EntityType.SkvKoboldChief;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.goblin_leader.onInit();

		local s = ::Const.Skv.KoboldScale;
		local b = this.m.BaseProperties;

		b.Hitpoints  = ::Math.max(1, ::Math.floor(b.Hitpoints * s.CasterHealthMult));
		b.MeleeSkill  = b.MeleeSkill + s.MeleeSkill;
		b.RangedSkill = b.RangedSkill + s.RangedSkill;
		b.Bravery     = b.Bravery + s.Resolve;

		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

});
