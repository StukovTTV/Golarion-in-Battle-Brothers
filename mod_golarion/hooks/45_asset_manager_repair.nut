::mods_hookExactClass("states/world/asset_manager", function (o)
{
	local update = o.update;
	o.update = function ( _worldState )
	{

		if (!this.m.IsConsumingAssets
			|| ::World.getTime().Hours == this.m.LastHourUpdated
			|| this.isCamping())
		{
			return update(_worldState);
		}

		local held = [];

		foreach ( bro in ::World.getPlayerRoster().getAll() )
		{
			foreach ( item in bro.getItems().getAllItems() )
			{
				if (item != null && ::GolarionEnchant.get(item) > 0
					&& item.getConditionMax() > 1 && item.getCondition() < item.getConditionMax())
					held.push({ Item = item, Condition = item.getCondition() });
			}
		}

		foreach ( item in this.getStash().getItems() )
		{
			if (item != null && ::GolarionEnchant.get(item) > 0
				&& item.getConditionMax() > 1 && item.getCondition() < item.getConditionMax())
				held.push({ Item = item, Condition = item.getCondition() });
		}

		if (held.len() == 0)
		{
			return update(_worldState);
		}

		foreach ( h in held )
			h.Item.setCondition(h.Item.getConditionMax());

		try
		{
			update(_worldState);
		}
		catch (e)
		{
			foreach ( h in held )
				h.Item.setCondition(h.Condition);
			throw e;
		}

		foreach ( h in held )
			h.Item.setCondition(h.Condition);
	}
});
