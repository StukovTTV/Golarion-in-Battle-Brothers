::mods_hookExactClass("ui/screens/tooltip/tooltip_events", function ( o )
{
	local onQueryTileTooltipData = o.onQueryTileTooltipData;

	o.onQueryTileTooltipData = function ()
	{
		local ret = onQueryTileTooltipData();

		try
		{
			if (ret == null) return ret;
			if (!("Tactical" in ::getroottable()) || ::Tactical == null || ::Tactical.State == null) return ret;

			local tile = ::Tactical.State.getLastTileHovered();
			if (tile == null) return ret;

			local worst = ::Skv.Stench.worstSourceAdjacentToTile(tile, null);
			if (worst == 0) return ret;

			local amplified = worst == 2;

			local melee   = amplified ? ::Const.Skv.StenchMeleeSkillAmplified  : ::Const.Skv.StenchMeleeSkill;
			local ranged  = amplified ? ::Const.Skv.StenchRangedSkillAmplified : ::Const.Skv.StenchRangedSkill;
			local fatigue = amplified ? ::Const.Skv.StenchFatigueAmplified     : ::Const.Skv.StenchFatigue;

			ret.push({
				id = 90,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = (amplified
					? "[color=" + ::Const.UI.Color.NegativeValue + "]The air here is thick enough to see.[/color] "
					: "[color=" + ::Const.UI.Color.NegativeValue + "]The stink here is unbearable.[/color] ")
					+ "Ending a turn in this tile costs [color=" + ::Const.UI.Color.NegativeValue + "]-" + melee
					+ "[/color] Melee Skill, [color=" + ::Const.UI.Color.NegativeValue + "]-" + ranged
					+ "[/color] Ranged Skill and " + fatigue + " Fatigue."
			});
		}
		catch (e)
		{

			::logError("Skv.Stench: could not add the tile warning to the tooltip (the stench is unaffected): " + e);
		}

		return ret;
	}
});
