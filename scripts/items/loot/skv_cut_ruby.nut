this.skv_cut_ruby <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_cut_ruby";
		this.m.Name = "Cut Ruby";
		this.m.Description = "A single red stone the size of a thumbnail, cut in a great many small flat faces by somebody who knew exactly what he was doing. One side of it is not a face but a flat, and the flat has a mark on it, worn almost out. It was found wrapped in a rag and kept apart from the coin it was buried in - which means the thing that hoarded it knew it was different, and did not know why, and kept it anyway.";

		this.m.Icon = "loot/inventory_loot_05.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;

		this.m.Value = 500;
	}

	function playInventorySound( _eventType )
	{
		this.Sound.play("sounds/bottle_01.wav", ::Const.Sound.Volume.Inventory);
	}

});
