::mods_hookExactClass("skills/actives/legend_prayer_of_faith_skill", function ( o )
{
	local onUse = o.onUse;
	o.onUse = function ( _user, _targetTile )
	{

		local reached = 0;

		try
		{
			local tile = _user.getTile();

			for( local i = 0; i != 6; i = ++i )
			{
				if (!tile.hasNextTile(i)) continue;

				local next = tile.getNextTile(i);
				if (!next.IsOccupiedByActor) continue;

				local other = next.getEntity();
				if (other == null || !other.isAlive()) continue;

				local flags = other.getFlags();

				if (flags.has("cultist") || (flags.has("undead") && !flags.has("ghoul")))
				{
					reached = reached + 1;
				}
				else if (other.getFaction() == _user.getFaction())
				{
					reached = reached + 1;
				}
			}
		}
		catch (e)
		{
			::logError("Skv.Prayer: could not count who the chant reached (it still lands): " + e);
		}

		local ret = onUse(_user, _targetTile);

		try
		{
			if (!_user.isHiddenToPlayer())
			{
				this.Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user)
					+ " chants a prayer of faith, and "
					+ (reached == 0 ? "no one is close enough to hear it"
					 : reached == 1 ? "the one beside it stands a little straighter"
					 : ("the " + reached + " beside it stand a little straighter")));
			}
		}
		catch (e)
		{
			::logError("Skv.Prayer: could not write the chant to the combat log (it still landed): " + e);
		}

		return ret;
	}
});
