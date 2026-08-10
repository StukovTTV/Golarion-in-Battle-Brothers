::mods_hookExactClass("ai/tactical/behaviors/ai_horror", function ( o )
{
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.LegendHorrify));
});

::mods_hookExactClass("ai/tactical/behaviors/ai_attack_crush_armor", function ( o )
{
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.LegendRust));
});

::mods_hookExactClass("ai/tactical/behaviors/ai_rally", function ( o )
{
	o.m.PossibleSkills.push(::Legends.Actives.getID(::Legends.Active.LegendPrayerOfFaith));

	local onEvaluate = o.onEvaluate;
	o.onEvaluate = function ( _entity )
	{
		local score = onEvaluate(_entity);

		try
		{
			if (this.m.Skill == null) return score;
			if (this.m.Skill.getID() != ::Legends.Actives.getID(::Legends.Active.LegendPrayerOfFaith)) return score;

			local tile = _entity.getTile();

			for( local i = 0; i != 6; i = ++i )
			{
				if (!tile.hasNextTile(i)) continue;

				local next = tile.getNextTile(i);
				if (!next.IsOccupiedByActor) continue;

				local other = next.getEntity();
				if (other == null || !other.isAlive()) continue;

				if (other.isAlliedWith(_entity)) return score;

				local flags = other.getFlags();
				if (flags.has("cultist")) return score;
				if (flags.has("undead") && !flags.has("ghoul")) return score;
			}
		}
		catch (e)
		{
			::logError("Skv.Rally: could not test for an adjacent ally (the chant may be wasted): " + e);
			return score;
		}

		return ::Const.AI.Behavior.Score.Zero;
	}
});
