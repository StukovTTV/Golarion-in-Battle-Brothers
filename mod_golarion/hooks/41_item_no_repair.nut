// Enchanted weapons cannot be repaired by ordinary means. This is the
// authoritative gate — repair_building.assignAll() and the manual queue click
// both route through setToBeRepaired(), so refusing here closes every path.
//
// Note we do NOT fake getRepair(): it feeds the actual repair arithmetic
// (onRepair(getRepair() + needed)) and armour layer subtraction in
// perk_legend_small_target. Lying about it would corrupt both.
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
