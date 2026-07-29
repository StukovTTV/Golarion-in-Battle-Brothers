// Enchanted ammunition and thrown weapons don't restock from the party's supply.
// A quiver of +2 bolts is finite: what you shoot away and can't pick up is gone.
// That scarcity IS the balance on magic ammunition -- it is why a +5 quiver can
// carry a +10 to hit without being a free upgrade -- so the gate has to be tight.
//
// ⚠ SET THEM FULL BEFORE THE REFILL, DON'T ROLL THEM BACK AFTER IT. The first
// version snapshotted the counts, let Legends' refillAmmo top the quiver up, then
// put the counts back -- but refillAmmo PAYS for what it adds out of
// ::World.Assets.m.Ammo, and rolling the item back does not refund the supply. The
// player was quietly charged for ammunition every time they camped with an enchanted
// quiver that wasn't full, and got nothing for it.
//
// Setting each item to its own maximum FIRST makes Legends' loop skip it outright
// (its test is `getAmmo() < getAmmoMax()`), so nothing is bought and nothing needs
// refunding. The true count goes back afterwards -- including on the throw path,
// because an item left sitting at full would be a free refill, which is the exact
// thing this file exists to prevent.
//
// ⚠ THE STASH COUNTS TOO. Legends' refillAmmo walks the roster and then makes a
// second pass over the stash for throwing nets. Covering only the roster left a way
// to launder an enchanted net: drop it in the stash, camp, take it back mended.
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
