::mods_hookExactClass("skills/actives/root_skill", function ( o )
{

	o.onTurnEnd <- function ()
	{

		if (!("Cooldown" in this.m)) return;

		if (this.m.Cooldown > 0)
		{
			this.m.Cooldown -= 1;
		}
	}
});
