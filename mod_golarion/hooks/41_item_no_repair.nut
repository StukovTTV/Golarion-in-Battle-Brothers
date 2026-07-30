::mods_hookExactClass("items/item", function (o)
{
	local setToBeRepaired = o.setToBeRepaired;
	o.setToBeRepaired = function ( _r, _idx = 0 ) {
		if (_r && ::GolarionEnchant.get(this) > 0) {
			this.m.IsToBeRepairedQueue = 0;
			return false;
		}
		return setToBeRepaired(_r, _idx);
	}
});
