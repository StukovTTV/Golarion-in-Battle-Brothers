::mods_hookExactClass("ai/tactical/behaviors/ai_attack_default", function ( o )
{
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.ThrowFireBomb));
	o.m.PossibleSkills.push("actives.skv_rat_bite");
	o.m.PossibleSkills.push("actives.skv_rat_claws");
});
