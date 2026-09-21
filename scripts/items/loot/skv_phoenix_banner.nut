this.skv_phoenix_banner <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_phoenix_banner";
		this.m.Name = "Banner of the Band of the Phoenix";
		this.m.Description = "A hunting banner of heavy cloth, gone grey with age, and on it a great bird made of flame with its wings raised. It is the standard of the Band of the Phoenix, a hunting lodge of Absalom in the Age of Blades, and it was old when this tower was built. A collector would pay well for it, and a historian would pay whatever he had.";

		this.m.Icon = "loot/skv_phoenix_banner.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 400;
	}

});
