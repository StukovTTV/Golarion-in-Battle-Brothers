::mods_hookExactClass("ai/tactical/behaviors/ai_attack_bow", function ( o )
{
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.LegendMagicBurningHands));
});
