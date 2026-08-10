::mods_hookExactClass("entity/world/settlements/buildings/tavern_building", function ( o )
{
	local getDrinkResult = o.getDrinkResult;
	o.getDrinkResult = function ()
	{
		local result = getDrinkResult.call(this);

		if (result == null)
		{
			return result;
		}

		try
		{
			if (::Skv.March.drinkRound() > 0)
			{
				result.Intro = result.Intro + "\n\nFor an hour or two the road is forgotten, and the men are the better for it.";
			}
		}
		catch (e)
		{
			::logError("Skv.March: could not credit the tavern round (the round itself was still bought): " + e);
		}

		return result;
	}
});
