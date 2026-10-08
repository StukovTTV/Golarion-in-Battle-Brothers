foreach (path in ["items/weapons/weapon", "items/shields/shield"])
{
	::mods_hookExactClass(path, function ( o )
	{
		local isDroppedAsLoot = o.isDroppedAsLoot;
		o.isDroppedAsLoot = function ()
		{
			if (::Skv.Silent.isHeld(this)) return false;
			return isDroppedAsLoot.call(this);
		}
	});
}
