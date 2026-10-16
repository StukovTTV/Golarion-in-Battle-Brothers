local skvTempleKey = "SkvTempleStock";
local skvTempleId = "building.temple";
local skvShopOwnerStash = "world-town-screen-shop-dialog-module.stash";
local skvShopOwnerShop = "world-town-screen-shop-dialog-module.shop";

local skvTempleGodKey = "SkvTempleGod";

local skvTagKind = function ( _class, _kind )
{
	::mods_hookExactClass("entity/world/settlements/" + _class, function ( o )
	{
		o.getSkvTempleKind <- function ()
		{
			return _kind;
		}
	});
};
foreach (cls, kind in ::Const.Skv.Temples.Classes) skvTagKind(cls, kind);

local skvTempleKind = function ( _town )
{
	local kind = null;
	try { kind = _town.getSkvTempleKind(); }
	catch (e)
	{

		kind = _town.hasBuilding("building.alchemist") ? "South" : "Farming";
		::logInfo("Skv.TempleShop: " + _town.getName() + " has no tagged kind (" + e + "); its temple uses the " + kind + " gods.");
	}
	return kind;
};

local skvTempleGod = function ( _town )
{
	local flags = _town.getFlags();
	if (flags.has(skvTempleGodKey)) return flags.get(skvTempleGodKey);

	local T = ::Const.Skv.Temples;
	local kind = skvTempleKind(_town);
	local pool = (kind in T.Pools) ? T.Pools[kind] : T.Pools.Farming;
	local align = ["Good", "Neutral", "Evil"][::Math.rand(0, 2)];
	local gods = pool[align];
	local god = gods[::Math.rand(0, gods.len() - 1)];
	flags.set(skvTempleGodKey, god);
	::logInfo("Skv.TempleShop: " + _town.getName() + "'s temple is dedicated to " + god + " (" + align + ", " + kind + ").");
	return god;
};

local skvTempleFavours = function ( _god )
{
	local T = ::Const.Skv.Temples;
	local align = (_god in T.Alignment) ? T.Alignment[_god] : null;
	if (align == null)
	{
		::logError("Skv.TempleShop: " + _god + " has no alignment in 95_temples.nut; no discount.");
		return false;
	}
	local moral = ::World.Assets.getMoralReputation();
	if (align == "Good") return moral > T.GoodAbove;
	if (align == "Evil") return moral < T.EvilBelow;
	return moral >= T.EvilBelow && moral <= T.GoodAbove;
};

local skvTempleLine = function ( _s )
{
	foreach (l in ::Const.Skv.Shops.Temple)
	{
		if (l.S == _s) return l;
	}
	return null;
};

local skvTempleSave = function ( _temple )
{
	try
	{
		if (!("SkvShelfReady" in _temple.m) || _temple.getStash() == null) return;
		local counts = {};
		local order = [];
		foreach (it in _temple.getStash().getItems())
		{
			if (it == null) continue;
			local s = ::IO.scriptFilenameByHash(it.ClassNameHash);
			if (s.find("scripts/items/") == 0) s = s.slice(14);
			if (!(s in counts))
			{
				counts[s] <- 0;
				order.push(s);
			}
			counts[s] = counts[s] + 1;
		}
		local text = "";
		foreach (s in order) text = text + (text == "" ? "" : "|") + s + "*" + counts[s];
		_temple.getSettlement().getFlags().set(skvTempleKey, text);
	}
	catch (e)
	{
		::logError("Skv.TempleShop: the temple's shelf could not be recorded; a reload may show a different one - " + e);
	}
};

local skvTempleRestore = function ( _temple )
{
	local text = _temple.getSettlement().getFlags().get(skvTempleKey);
	local origin = false;
	try { origin = ::Legends.Mod.ModSettings.getSetting("WorldEconomy").getValue(); }
	catch (e) { ::logError("Skv.TempleShop: Legends' WorldEconomy setting could not be read; restored potions get no origin town - " + e); }

	local n = 0;
	local start = 0;
	while (typeof text == "string" && text != "" && start <= text.len())
	{
		local bar = text.find("|", start);
		local pair = bar == null ? text.slice(start) : text.slice(start, bar);
		start = bar == null ? text.len() + 1 : bar + 1;

		local star = pair.find("*");
		local s = star == null ? pair : pair.slice(0, star);
		local count = star == null ? 1 : pair.slice(star + 1).tointeger();
		local line = skvTempleLine(s);
		if (line == null)
		{
			::logInfo("Skv.TempleShop: " + s + " is no longer a temple line; left off the shelf.");
			continue;
		}
		for (local k = 0; k < count; k++)
		{
			local it = ::new("scripts/items/" + s);
			it.setPriceMult(line.P * _temple.getPriceMult());
			if (origin) it.setOriginSettlement(_temple.getSettlement());
			_temple.getStash().add(it);
			n = n + 1;
		}
	}
	_temple.getStash().sort();
	return n;
};

local skvTempleFill = function ( _temple )
{
	local list = _temple.onUpdateShopList();
	_temple.getSettlement().onUpdateShopList(_temple.getID(), list);
	_temple.fillStash(list, _temple.getStash(), _temple.getPriceMult(), _temple.getAllowDamaged());
};

::mods_hookExactClass("entity/world/settlements/buildings/temple_building", function ( o )
{

	local create = o.create;
	o.create = function ()
	{
		create.call(this);
		local stash = ::new("scripts/items/stash_container");
		stash.setID("shop");
		stash.setResizable(true);
		this.m.SkvStash <- stash;
	}

	o.getStash <- function ()
	{
		return ("SkvStash" in this.m) ? this.m.SkvStash : null;
	}

	o.getDefaultShopList <- function ()
	{
		local out = [];
		foreach (l in ::Const.Skv.Shops.Temple) out.push(clone l);
		return out;
	}

	o.fillStash <- function ( _list, _stash, _priceMult, _allowDamagedEquipment = false )
	{
		this.building.fillStash(_list, _stash, _priceMult, _allowDamagedEquipment);
		this.m.SkvShelfReady <- true;
	}

	local onSettlementEntered = o.onSettlementEntered;
	o.onSettlementEntered = function ()
	{
		onSettlementEntered.call(this);
		local stash = this.getStash();
		if (stash == null)
		{
			::logError("Skv.TempleShop: this temple has no shelf (its create() was not ours); nothing to sell.");
			return;
		}
		try { skvTempleGod(this.getSettlement()); }
		catch (e) { ::logError("Skv.TempleShop: the temple's god could not be drawn - " + e); }
		if ("SkvShelfReady" in this.m) return;
		try
		{
			local town = this.getSettlement();
			if (stash.getNumberOfFilledSlots() == 0)
			{
				if (town.getFlags().has(skvTempleKey))
				{
					local n = skvTempleRestore(this);
					::logInfo("Skv.TempleShop: " + town.getName() + "'s temple shelf rebuilt from the town's record (" + n + " items).");
				}
				else
				{
					skvTempleFill(this);
					::logInfo("Skv.TempleShop: " + town.getName() + "'s temple stocked for the first time (" + stash.getNumberOfFilledSlots() + " items).");
				}
			}
			this.m.SkvShelfReady <- true;
			foreach (it in stash.getItems())
			{
				if (it != null) it.setSold(false);
			}
		}
		catch (e)
		{
			::logError("Skv.TempleShop: the temple's shelf could not be laid out; it stays as it was - " + e);
		}
	}
});

::mods_hookExactClass("entity/world/settlement", function ( o )
{
	local onSerialize = o.onSerialize;
	o.onSerialize = function ( _out )
	{
		try
		{
			local temple = this.getBuilding(skvTempleId);
			if (temple != null) skvTempleSave(temple);
		}
		catch (e)
		{
			::logError("Skv.TempleShop: " + this.getName() + "'s temple shelf was not recorded before the save - " + e);
		}
		onSerialize.call(this, _out);
	}
});

local skvTempleSale = function ( _module, _data )
{
	return _module.m.Shop != null && _module.m.Shop.getID() == skvTempleId
		&& _data[1] == skvShopOwnerStash && _data[3] == skvShopOwnerShop;
};

::mods_hookExactClass("ui/screens/world/modules/world_town_screen/town_shop_dialog_module", function ( o )
{

	local queryShopInformation = o.queryShopInformation;
	o.queryShopInformation = function ()
	{
		local ret = queryShopInformation.call(this);
		try
		{
			if (ret != null && this.m.Shop != null && this.m.Shop.getID() == skvTempleId)
			{
				ret.SubTitle = "Potions brewed and blessed by the priests";
				local god = skvTempleGod(this.m.Shop.getSettlement());
				ret.Title = "Temple of " + god;
				if (skvTempleFavours(god)) ret.SubTitle = ret.SubTitle + ". " + ::Const.Skv.Temples.DiscountText;
			}
		}
		catch (e)
		{
			::logError("Skv.TempleShop: the temple shelf's title or subtitle could not be set; the temple's own lines show - " + e);
		}
		return ret;
	}

	local onCanSwapItem = o.onCanSwapItem;
	o.onCanSwapItem = function ( _data )
	{
		local ret = onCanSwapItem.call(this, _data);
		try
		{
			if (ret != null && skvTempleSale(this, _data))
			{
				ret.Result = ::Const.UI.Swap.DoNotSwap;
				if (!("Item" in ret) || ret.Item == null)
				{
					local w = this.Stash.getItemAtIndex(_data[0]);
					if (w != null && w.item != null) ret.Item <- { Name = w.item.getName(), Icon = w.item.getIcon() };
				}
			}
		}
		catch (e)
		{
			::logError("Skv.TempleShop: could not check a move for the temple's buy-only rule - " + e);
		}
		return ret;
	}

	local onSwapItem = o.onSwapItem;
	o.onSwapItem = function ( _data )
	{
		local refuse = false;
		try { refuse = skvTempleSale(this, _data); }
		catch (e) { ::logError("Skv.TempleShop: could not tell whether a move is a sale to the temple - " + e); }

		if (refuse)
		{
			::logInfo("Skv.TempleShop: a sale to the temple was refused (it buys nothing).");
			return null;
		}
		return onSwapItem.call(this, _data);
	}
});

::mods_hookExactClass("ui/screens/world/modules/world_town_screen/town_temple_dialog_module", function ( o )
{
	o.onGolarionBuy <- function ()
	{
		local town = ::World.State.getCurrentTown();
		local temple = town != null ? town.getBuilding(skvTempleId) : null;
		if (temple == null || temple.getStash() == null)
		{
			::logError("Skv.TempleShop: Buy pressed and no temple shelf found in " + (town == null ? "no town" : town.getName()) + "; nothing opens.");
			return;
		}

		local god = "?";
		local favoured = false;
		try
		{
			god = skvTempleGod(town);
			favoured = skvTempleFavours(god);
			local f = favoured ? ::Const.Skv.Temples.Discount : 1.0;
			foreach (it in temple.getStash().getItems())
			{
				if (it == null) continue;
				local s = ::IO.scriptFilenameByHash(it.ClassNameHash);
				if (s.find("scripts/items/") == 0) s = s.slice(14);
				local line = skvTempleLine(s);
				if (line != null) it.setPriceMult(line.P * temple.getPriceMult() * f);
			}
		}
		catch (e)
		{
			::logError("Skv.TempleShop: the shelf could not be priced for the god's favour; it keeps its last prices - " + e);
		}
		this.m.Parent.getShopDialogModule().setShop(temple);
		this.m.Parent.showShopDialog();
		::logInfo("Skv.TempleShop: the temple's shelf opened in " + town.getName() + " (" + temple.getStash().getNumberOfFilledSlots() + " items); "
			+ god + ", moral " + ::World.Assets.getMoralReputation() + ", " + (favoured ? "DISCOUNT" : "no discount") + ".");
	}

	local queryRosterInformation = o.queryRosterInformation;
	o.queryRosterInformation = function ()
	{
		local ret = queryRosterInformation.call(this);
		try
		{
			local town = ::World.State.getCurrentTown();
			if (ret != null && town != null && town.hasBuilding(skvTempleId)) ret.Title = "Temple of " + skvTempleGod(town);
		}
		catch (e)
		{
			::logError("Skv.TempleShop: the temple's name could not be shown on its healing screen; it reads Temple - " + e);
		}
		return ret;
	}
});

if ("mods_registerJS" in getroottable())
{
	::mods_registerJS("golarion/hooks/screens/world/modules/world_town_screen/world_town_screen_temple_dialog_module.js");
}
else
{
	::logError("Skv.TempleShop: mods_registerJS is missing, so the temple's Buy button cannot be loaded.");
}

if ("mods_registerCSS" in getroottable())
{
	::mods_registerCSS("golarion/hooks/screens/world/modules/world_town_screen/world_town_screen_temple_dialog_module.css");
}
