this.skv_potion_of_blur <- this.inherit("scripts/items/accessory/accessory", {
	m = {},

	function create()
	{
		this.accessory.create();

		this.m.ID = "misc.skv_potion_of_blur";
		this.m.Name = "Potion of Blur";
		this.m.Description = "A thin grey liquid that seems to shift in the bottle when nobody is looking at it. A man who drinks it looks blurred and hard to follow, and the quicker he moves the harder he is to hit. It lasts until the fighting is done.";
		this.m.Icon = "misc/skv_potion_blur.png";

		this.m.SlotType = ::Const.ItemSlot.Bag;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.IsChangeableInBattle = true;
		this.m.IsDroppedAsLoot = true;
		this.m.ShowOnCharacter = false;
		this.m.Value = 300;
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
			icon = "ui/icons/special.png",
			text = "Grants Melee and Ranged Defense equal to 15% of current Initiative until the battle ends"
		});
		result.push({
			id = 21,
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
			this.addSkill(this.new("scripts/skills/actives/skv_drink_blur_potion_skill"));
		}
		catch (e)
		{
			::logError("Skv.potion: the Blur drink skill was not attached; the bottle cannot be drunk: " + e);
		}
	}

	function onPutIntoBag()
	{
		this.onEquip();
	}

});
