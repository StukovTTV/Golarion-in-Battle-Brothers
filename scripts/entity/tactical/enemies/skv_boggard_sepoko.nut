this.skv_boggard_sepoko <- this.inherit("scripts/entity/tactical/enemies/skv_boggard_swampseer", {
	m = {},

	function onInit()
	{
		this.skv_boggard_swampseer.onInit();
		local P = ::Legends.Perk;
		local perks = [P.Pathfinder, P.Colossus, P.FortifiedMind];

		if (::Legends.isLegendaryDifficulty())
		{
			perks.push(P.LegendValaPremonition);
			perks.push(P.NineLives);
		}

		local got = 0;

		foreach (p in perks)
		{
			try
			{
				::Legends.Perks.grant(this, p);
				++got;
			}
			catch (e)
			{
				::logError("Skv.Boggard.Sepoko: a perk would not take (he still fights): " + e);
			}
		}

		this.m.Skills.update();
		this.m.Hitpoints = this.getHitpointsMax();
		::Skv.dbg("Skv.Boggard.Sepoko: " + got + " of " + perks.len() + " perks, hitpoints " + this.m.Hitpoints + ".");
	}
});
