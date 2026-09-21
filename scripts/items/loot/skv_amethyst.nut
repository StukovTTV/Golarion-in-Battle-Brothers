this.skv_amethyst <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_amethyst";
		this.m.Name = "Amethyst";
		this.m.Description = "A purple stone the size of a thumbnail, cut by somebody who knew how, and kept in a troglodyte's chest by somebody who did not. Any jeweller would buy it.";

		this.m.Icon = "loot/skv_amethyst.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 300;
	}

});
