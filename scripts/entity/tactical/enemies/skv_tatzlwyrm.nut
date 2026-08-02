this.skv_tatzlwyrm <- this.inherit("scripts/entity/tactical/enemies/serpent", {
	m = {},

	function create()
	{
		this.serpent.create();

		this.m.Type = ::Const.EntityType.SkvTatzlwyrm;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{

		this.serpent.onInit();

		local b = this.m.BaseProperties;
		b.setValues(::Const.Tactical.Actor.SkvTatzlwyrm);
		b.IsAffectedByNight = false;
		b.IsImmuneToDisarm = true;

		this.m.XP = ::Const.Tactical.Actor.SkvTatzlwyrm.XP;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		local body = this.getSprite("body");
		body.Color = this.createColor("#9db07a");
		body.Saturation = 0.9;

		this.getSkills().removeByID("actives.serpent_bite");
		this.m.Skills.add(::new("scripts/skills/actives/skv_tatzlwyrm_bite_skill"));
	}

});
