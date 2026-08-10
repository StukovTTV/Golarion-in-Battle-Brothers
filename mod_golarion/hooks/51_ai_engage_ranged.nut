::mods_hookExactClass("ai/tactical/behaviors/ai_engage_ranged", function ( o )
{
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.ThrowFireBomb));
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.LegendRust));
});
