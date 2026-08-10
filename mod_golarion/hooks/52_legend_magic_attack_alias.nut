foreach (className in [
	"skills/actives/legend_magic_burning_hands",
	"skills/actives/legend_magic_chain_lightning_skill"
])
{
	::mods_hookExactClass(className, function ( o )
	{
		if (!("legend_magic_attack" in o) && ("legend_magic_attack_skill" in o))
		{
			o.legend_magic_attack <- o.legend_magic_attack_skill;
		}
	});
}
