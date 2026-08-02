this.skv_ring_of_torag <- this.inherit("scripts/items/accessory/accessory", {
	m = {},

	function create()
	{
		this.accessory.create();

		this.m.ID = "accessory.skv_ring_of_torag";
		this.m.Name = "Ring of Torag";
		this.m.Description = "A simple golden ring with a large red stone set into it, and something moving in the stone that is not a reflection. It was cut for a dwarf, which is to say it is a tight fit and an honest weight. The man it was taken from had been dead four hundred years and was still wearing it.";

		this.m.SlotType = ::Const.ItemSlot.Accessory;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;

		this.m.Icon = "loot/inventory_loot_09.png";

		this.m.Value = 1200;
		this.m.IsDroppedAsLoot = true;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.ShowOnCharacter = false;
		this.m.IsChangeableInBattle = false;
	}

	function onUpdateProperties( _properties )
	{

		_properties.DamageReceivedFireMult *= 0.9;
	}

	function getTooltip()
	{

		local result = this.item.getTooltip();
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/regular_damage.png",
			text = "Takes [color=" + ::Const.UI.Color.PositiveValue + "]10%[/color] less damage from fire"
		});
		return result;
	}

});
