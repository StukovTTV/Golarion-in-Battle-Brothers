::mods_hookExactClass("entity/world/camp/buildings/repair_building", function (o)
{
	local getListOfItemsNeedingRepair = o.getListOfItemsNeedingRepair;

	local stripEnchanted = function ( _arr ) {
		if (typeof _arr != "array")
			return _arr;
		local out = [];
		foreach ( e in _arr ) {
			local item = (typeof e == "table" && ("Item" in e)) ? e.Item : e;
			if (::GolarionEnchant.get(item) > 0)
				continue;
			out.push(e);
		}
		return out;
	}

	o.getListOfItemsNeedingRepair = function () {
		local list = getListOfItemsNeedingRepair();
		if (typeof list == "table") {
			if ("Items" in list) list.Items = stripEnchanted(list.Items);
			if ("Stash" in list) list.Stash = stripEnchanted(list.Stash);
			return list;
		}
		return stripEnchanted(list);
	}
});
