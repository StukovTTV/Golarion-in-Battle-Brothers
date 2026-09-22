this.skv_erastil_symbol <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_erastil_symbol";
		this.m.Name = "Holy Symbols of Erastil";
		this.m.Description = "Two little bows of antler, each with an arrow nocked across it: the mark of Erastil, Old Deadeye, god of the hunt and of every village that keeps its own. They hung around the necks of two priests who went to a temple in the forest to keep a promise, and did not come back.";

		this.m.Icon = "loot/skv_erastil_symbol.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 150;
	}

});
