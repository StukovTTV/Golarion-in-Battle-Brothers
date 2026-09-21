this.skv_nethys_symbol <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_nethys_symbol";
		this.m.Name = "Holy Symbol of Nethys";
		this.m.Description = "A silver mask the size of a palm, one half blackened and one half polished bright: Nethys, the All-Seeing Eye, god of magic, who protects with one hand and destroys with the other. It came off an altar in a sealed temple, and his priests would pay well to have it back.";

		this.m.Icon = "loot/skv_nethys_symbol.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 300;
	}

});
