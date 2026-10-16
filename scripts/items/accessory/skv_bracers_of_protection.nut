this.skv_bracers_of_protection <- this.inherit("scripts/items/accessory/accessory", {
	m = {},

	function create()
	{
		this.accessory.create();

		this.m.ID = "accessory.skv_bracers_of_protection";
		this.m.Name = "Bracers of Protection";
		this.m.Description = "A pair of plain bronze bracers, green with age, cut with a pattern of small linked shields. They weigh almost nothing. Whoever wears them finds that blows aimed at him miss more often.";
		this.m.SlotType = ::Const.ItemSlot.Accessory;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;
		this.m.Icon = "misc/skv_bracers_of_protection.png";

		this.m.Value = 900;
		this.m.IsDroppedAsLoot = true;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.ShowOnCharacter = false;
		this.m.IsChangeableInBattle = false;
	}

	function onUpdateProperties( _properties )
	{
		this.accessory.onUpdateProperties(_properties);
		_properties.MeleeDefense += 5;
		_properties.RangedDefense += 5;
	}

	function getTooltip()
	{
		local result = this.item.getTooltip();
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/melee_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Melee Defense"
		});
		result.push({
			id = 21,
			type = "text",
			icon = "ui/icons/ranged_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Ranged Defense"
		});
		return result;
	}

});
