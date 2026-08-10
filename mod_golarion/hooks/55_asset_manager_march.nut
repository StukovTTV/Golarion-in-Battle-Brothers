::mods_hookExactClass("states/world/asset_manager", function ( o )
{
	o.m.SkvMarchHour <- -1;

	local update = o.update;
	o.update = function ( _worldState )
	{
		local result = update.call(this, _worldState);

		try
		{
			local h = ::World.getTime().Hours;

			if (h != this.m.SkvMarchHour)
			{
				this.m.SkvMarchHour = h;
				::Skv.March.tick();
			}
		}
		catch (e)
		{
			::logError("Skv.March: the hourly tick failed (the world carried on regardless): " + e);
		}

		return result;
	}

	local onDeserialize = o.onDeserialize;
	o.onDeserialize = function ( _in )
	{
		onDeserialize.call(this, _in);
		this.m.SkvMarchHour = -1;
	}
});
