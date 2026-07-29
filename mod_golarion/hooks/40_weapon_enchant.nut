// Enhancement storage and presentation for WEAPONS. Everything lives in
// ::GolarionEnchant.installOn (config/78_enchant.nut) so blades and quivers can
// never drift apart.
::mods_hookExactClass("items/weapons/weapon", function (o)
{
	::GolarionEnchant.installOn(o);
});
