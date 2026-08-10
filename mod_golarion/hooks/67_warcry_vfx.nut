::mods_hookExactClass("skills/actives/warcry", function ( o )
{
	local onUse = o.onUse;

	o.onUse = function ( _user, _targetTile )
	{
		local ret = onUse(_user, _targetTile);

		try
		{
			local tile = _user.getTile();

			if (tile.IsVisibleForPlayer)
			{
				::Skv.FX.burst("Dust", tile, { Scale = 1.4 });
			}

			for( local i = 0; i != 6; i = ++i )
			{
				if (!tile.hasNextTile(i)) continue;

				local next = tile.getNextTile(i);
				if (!next.IsVisibleForPlayer) continue;

				::Skv.FX.burst("Dust", next);
			}
		}
		catch (e)
		{
			::logError("Skv.WarcryFX: could not raise the dust (the howl still landed): " + e);
		}

		return ret;
	}
});
