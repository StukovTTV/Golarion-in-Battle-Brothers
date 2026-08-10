::Skv.InnateCasterRacials <- [
	"racial.skv_stench",
	"racial.skv_light_sensitivity"
];

::mods_hookExactClass("entity/tactical/actor", function ( o )
{

	if (!("isArmedWithMagicStaff" in o))
	{
		::logError("Skv.Staff: Legends no longer defines isArmedWithMagicStaff -- the exemption is not installed, and our casters will hold their spells.");
		return;
	}

	local isArmedWithMagicStaff = o.isArmedWithMagicStaff;

	o.isArmedWithMagicStaff = function ()
	{

		if (isArmedWithMagicStaff()) return true;

		try
		{
			local skills = this.getSkills();
			if (skills == null) return false;

			foreach (id in ::Skv.InnateCasterRacials)
			{
				if (skills.hasSkill(id)) return true;
			}
		}
		catch (e)
		{

			::logError("Skv.Staff: could not test for an innate caster (the spell stays gated): " + e);
		}

		return false;
	}
});
