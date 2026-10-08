::Skv.RumourSites.add(::Skv.Mbotuu);

::mods_hookExactClass("entity/world/settlements/buildings/tavern_building", function ( o )
{
	local getRumor = o.getRumor;
	o.getRumor = function ( _isPaidFor = false )
	{
		local cachedBefore = this.m.LastRumor;
		local result = getRumor.call(this, _isPaidFor);

		if (result == null) return result;
		if (this.m.RumorsGiven > 3) return result;
		if (!_isPaidFor && cachedBefore != "") return result;

		try
		{
			local ours = ::Skv.RumourSites.offer(this, _isPaidFor, result);
			if (ours != null) return ours;
		}
		catch (e)
		{
			::logError("Skv.RumourSites: the tavern hook failed, so the tavern keeps its own rumour: " + e);
		}

		return result;
	}
});
