this.skv_kita_collar <- this.inherit("scripts/items/item", {
	m = {},

	function create()
	{
		this.item.create();

		this.m.ID = "misc.skv_kita_collar";
		this.m.Name = "Kita's Collar";
		this.m.Description = "A leather dog collar, stiff with age, studded with a row of blue lapis stones. A small silver tag hangs from the buckle, and someone has scratched a name into it with more care than skill: Kita. It came off a dog that walked into a spider's web in the dark and did not walk out, and whoever loved it enough to put stones on its collar is not coming back for it either.";

		this.m.Icon = "loot/wildmen_02.png";
		this.m.SlotType = ::Const.ItemSlot.None;
		this.m.ItemType = ::Const.Items.ItemType.Misc | ::Const.Items.ItemType.Loot;
		this.m.IsDroppedAsLoot = true;
		this.m.Value = 270;
	}

	function playInventorySound( _eventType )
	{
		this.Sound.play("sounds/combat/armor_leather_impact_03.wav", ::Const.Sound.Volume.Inventory);
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
