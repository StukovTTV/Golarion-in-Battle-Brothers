// Enhancement for AMMO -- the module's "+1 flaming bolts" are a quiver.
//
// ammo inherits items/item, NOT items/weapons/weapon (its create() calls
// this.item.create()), so it needs its own hook: the weapon hook would never
// reach it and getEnchant() would not exist on a quiver.
//
// ⚠ ENCHANTED AMMO DOES NOT RESTOCK. states/world/asset_manager.refillAmmo is
// already rolled back for any enchanted item with getAmmoMax() > 0 (see
// hooks/42_asset_manager_ammo.nut), which now catches quivers as well as thrown
// weapons: what you shoot away and cannot pick up is gone for good. That is the
// price of carrying magic ammunition, and it is why a +1 quiver is a decision
// rather than a free upgrade.
::mods_hookExactClass("items/ammo/ammo", function (o)
{
	::GolarionEnchant.installOn(o);
});
