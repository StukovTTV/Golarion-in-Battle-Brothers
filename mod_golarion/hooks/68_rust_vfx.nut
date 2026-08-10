::mods_hookExactClass("skills/actives/legend_rust_skill", function ( o )
{
	local onUse = o.onUse;

	o.onUse = function ( _user, _targetTile )
	{
		local ret = onUse(_user, _targetTile);

		try
		{
			if (_targetTile != null && _targetTile.IsVisibleForPlayer)
			{
				::Skv.FX.burst("Acid", _targetTile);
			}
		}
		catch (e)
		{
			::logError("Skv.RustFX: could not splash the acid (the armour still went): " + e);
		}

		return ret;
	}
});
