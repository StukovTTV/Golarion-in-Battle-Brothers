this.skv_jade_angel <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_jade_angel";
		this.m.Name = "Jade Figurine";
		this.m.Description = "A figure no taller than a hand, carved in green jade and flecked with old red paint. The carving is very old and very fine, and the base has been cut away from something larger with a crude blade. It was stolen from a temple long ago, and it has been stolen again since.";

		this.m.Icon = "loot/skv_jade_figurine.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 600;
	}

});
