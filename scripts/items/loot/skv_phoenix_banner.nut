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
