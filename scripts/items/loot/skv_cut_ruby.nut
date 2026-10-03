this.skv_cut_ruby <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_cut_ruby";
		this.m.Name = "Cut Ruby";
		this.m.Description = "A single red stone the size of a thumbnail, cut in a great many small flat faces by somebody who knew exactly what he was doing. One side of it is not a face but a flat, and the flat has a mark on it, worn almost out. Whoever owned it last kept it wrapped and apart from everything else, as if they knew it mattered and could no longer say why.";

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

	function getBuyPrice()
	{
		if (this.m.IsSold) return this.getSellPrice();
		if (("State" in ::World) && ::World.State != null && ::World.State.getCurrentTown() != null)
			return ::Math.max(this.getSellPrice(), ::Math.ceil(this.getValue() * 1.5 * ::World.State.getCurrentTown().getBuyPriceMult()));
		return ::Math.ceil(this.getValue());
	}

	function getSellPrice()
	{
		if (this.m.IsBought) return this.getBuyPrice();
		if (("State" in ::World) && ::World.State != null && ::World.State.getCurrentTown() != null)
			return ::Math.floor(this.getValue() * ::Const.World.Assets.BaseLootSellPrice * ::World.State.getCurrentTown().getSellPriceMult() * ::Const.Difficulty.SellPriceMult[::World.Assets.getEconomicDifficulty()]);
		return ::Math.floor(this.getValue());
	}

});
