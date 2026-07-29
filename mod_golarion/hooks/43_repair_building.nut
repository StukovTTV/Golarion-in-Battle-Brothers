// Keep enchanted weapons out of the repair list entirely, so they don't appear
// as entries that silently refuse to queue.
::mods_hookExactClass("entity/world/camp/buildings/repair_building", function (o)
{
	local getListOfItemsNeedingRepair = o.getListOfItemsNeedingRepair;
	o.getListOfItemsNeedingRepair = function () {
		local list = getListOfItemsNeedingRepair();
		for ( local i = list.len() - 1; i >= 0; i = --i ) {
			if (list[i].Item != null && ::GolarionEnchant.get(list[i].Item) > 0)
				list.remove(i);
		}
		return list;
	}
});
