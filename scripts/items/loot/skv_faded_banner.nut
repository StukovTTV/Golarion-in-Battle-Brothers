this.skv_faded_banner <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_faded_banner";
		this.m.Name = "Faded Banner";
		this.m.Description = "An old banner of heavy cloth, gone grey with age, with a bird made of flame on it. Whose it was, nobody can say. Old cloth with good work in it still sells.";

		this.m.Icon = "loot/skv_phoenix_banner.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 200;
	}

});
