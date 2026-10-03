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
