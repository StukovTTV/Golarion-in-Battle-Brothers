::mods_hookExactClass("states/world_state", function ( o )
{
	local enterLocation = o.enterLocation;
	o.enterLocation = function ( _location )
	{
		local entered = enterLocation.call(this, _location);

		try
		{
			if (entered && _location != null && _location.isEnterable())
			{
				::Skv.Town.enter(_location.getID());
			}
		}
		catch (e)
		{
			::logError("Skv.Town: could not record a settlement visit (entering the town still worked): " + e);
		}

		return entered;
	};
});
