this.skv_potion_of_protection_from_evil <- this.inherit("scripts/items/accessory/accessory", {
	m = {},

	function create()
	{
		this.accessory.create();

		this.m.ID = "misc.skv_potion_of_protection_from_evil";
		this.m.Name = "Potion of Protection from Evil";
		this.m.Description = "A small round bottle of pale blue water, stoppered with a cut crystal, with a sliver of silver lying at the bottom. A man who drinks it before a fight stands steadier, and the blows aimed at him seem to slide off just a little. It lasts until the fighting is done.";
		this.m.Icon = "misc/skv_potion_protection_from_evil.png";

		this.m.SlotType = ::Const.ItemSlot.Bag;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.IsChangeableInBattle = true;
		this.m.IsDroppedAsLoot = true;
		this.m.ShowOnCharacter = false;
		this.m.Value = 250;
	}

	function playInventorySound( _eventType )
	{
		this.Sound.play("sounds/bottle_01.wav", ::Const.Sound.Volume.Inventory);
	}

	function getTooltip()
	{
		local result = this.accessory.getTooltip();
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/bravery.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+10[/color] Resolve"
		});
		result.push({
			id = 21,
			type = "text",
			icon = "ui/icons/melee_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Melee Defense"
		});
		result.push({
			id = 22,
			type = "text",
			icon = "ui/icons/ranged_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Ranged Defense"
		});
		result.push({
			id = 23,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Lasts until the battle ends"
		});
		result.push({
			id = 24,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Can be drunk in battle by whoever carries it, or given to the man beside him"
		});
		return result;
	}

	function onEquip()
	{
		this.accessory.onEquip();
		try
		{
			this.addSkill(this.new("scripts/skills/actives/skv_drink_protection_potion_skill"));
		}
		catch (e)
		{
			::logError("Skv.potion: the Protection from Evil drink skill was not attached; the bottle cannot be drunk: " + e);
		}
	}

	function onPutIntoBag()
	{
		this.onEquip();
	}

});
