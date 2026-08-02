::mods_hookExactClass("states/world/asset_manager", function (o)
{
	local refillAmmo = o.refillAmmo;
	o.refillAmmo = function () {
		local held = [];

		foreach ( bro in ::World.getPlayerRoster().getAll() ) {
			foreach ( item in bro.getItems().getAllItems() ) {
				if (item != null && ::GolarionEnchant.get(item) > 0 && item.getAmmoMax() > 0)
					held.push({ Item = item, Ammo = item.getAmmo() });
			}
		}

		foreach ( item in this.getStash().getItems() ) {
			if (item != null && ::GolarionEnchant.get(item) > 0 && item.getAmmoMax() > 0)
				held.push({ Item = item, Ammo = item.getAmmo() });
		}

		foreach ( h in held )
			h.Item.setAmmo(h.Item.getAmmoMax());

		try
		{
			refillAmmo();
		}
		catch (e)
		{
			foreach ( h in held )
				h.Item.setAmmo(h.Ammo);
			throw e;
		}

		foreach ( h in held )
			h.Item.setAmmo(h.Ammo);
	}
});
