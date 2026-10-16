local skvShopSeen = {};

local skvShopLines = function ( _building, _key )
{
	local size = 3;
	try { size = _building.m.Settlement.getSize(); }
	catch (e) { ::logError("Skv.Shops: " + _key + ": the settlement's size could not be read; its size-gated lines are offered as at size 3 - " + e); }

	local out = [];
	foreach (l in ::Const.Skv.Shops[_key])
	{
		if (("MinSize" in l) && size < l.MinSize) continue;
		local e = clone l;
		if ("MinSize" in e) delete e.MinSize;
		out.push(e);
	}
	return out;
};

local skvHookShop = function ( _class, _key )
{
	::mods_hookExactClass("entity/world/settlements/buildings/" + _class, function ( o )
	{
		local getDefaultShopList = o.getDefaultShopList;
		o.getDefaultShopList = function ()
		{
			local list = getDefaultShopList.call(this);
			try
			{
				local ours = skvShopLines(this, _key);
				list.extend(ours);
				if (!(_class in skvShopSeen))
				{
					skvShopSeen[_class] <- true;
					::logInfo("Skv.Shops: " + _class + " stocks our " + _key + " lines (" + ours.len() + " here); first restock this session.");
				}
			}
			catch (e)
			{
				::logError("Skv.Shops: " + _class + ": our lines were not added; the game's own list goes out unchanged - " + e);
			}
			return list;
		}
	});
};

skvHookShop("marketplace_building", "Marketplace");
skvHookShop("marketplace_oriental_building", "Marketplace");
skvHookShop("alchemist_building", "Alchemist");
skvHookShop("blackmarket_building", "Blackmarket");

::skvshop <- function ( _restock = true )
{
	local town = null;
	try { town = ::World.State.getCurrentTown(); }
	catch (e) { ::logError("Skv.Shops: could not ask which town the company is in - " + e); return null; }
	if (town == null)
	{
		::logInfo("Skv.Shops: not in a town; enter one first.");
		return null;
	}
	if (_restock) town.updateShop(true);

	local total = 0;
	foreach (b in town.m.Buildings)
	{
		if (b == null || b.getStash() == null) continue;
		local counts = {};
		foreach (it in b.getStash().getItems())
		{
			if (it == null || it.getID().find("skv_") == null) continue;
			local n = it.getName();
			counts[n] <- (n in counts) ? counts[n] + 1 : 1;
			total = total + 1;
		}
		local text = "";
		foreach (n, c in counts) text = text + (text == "" ? "" : ", ") + c + " " + n;
		::logInfo("Skv.Shops: " + town.getName() + " (size " + town.getSize() + ") " + b.getID() + ": " + (text == "" ? "none of ours" : text));
	}
	::logInfo("Skv.Shops: " + total + " of our items in " + town.getName() + (_restock ? " after a forced restock." : "."));
	return total;
};
