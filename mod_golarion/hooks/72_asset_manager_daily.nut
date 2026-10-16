::mods_hookExactClass("states/world/asset_manager", function ( o )
{
	local update = o.update;
	o.update = function ( _worldState )
	{
		local before = this.m.LastDayPaid;
		local result = update.call(this, _worldState);

		try
		{
			local after = this.m.LastDayPaid;
			if (after != before)
			{
				if (after > before)
					::Skv.Daily.walk(after - before, "day " + after + " began (last paid day " + before + ")", false);
				else
					::logError("Skv.Daily: LastDayPaid went back from " + before + " to " + after + "; no charge returned.");
			}
		}
		catch (e)
		{
			::logError("Skv.Daily: the new day's recharge failed (the world carried on regardless): " + e);
		}

		return result;
	}
});
