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
