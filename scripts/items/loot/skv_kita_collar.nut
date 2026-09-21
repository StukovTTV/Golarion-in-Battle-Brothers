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

});
