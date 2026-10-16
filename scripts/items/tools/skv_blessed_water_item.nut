this.skv_blessed_water_item <- this.inherit("scripts/items/weapons/weapon", {
	m = {},

	function create()
	{
		this.weapon.create();
		this.m.ID = "weapon.skv_blessed_water";
		this.m.Name = "Vial of Blessed Water";
		this.m.Description = "A small glass vial of water blessed at a temple. It burns the undead where it splashes, and does nothing to the living.";
		this.m.IconLarge = "misc/skv_blessed_water.png";
		this.m.Icon = "misc/skv_blessed_water_70x70.png";
		this.m.SlotType = ::Const.ItemSlot.Offhand;
		this.m.ItemType = ::Const.Items.ItemType.Tool;
		this.m.AddGenericSkill = true;
		this.m.ShowArmamentIcon = true;
		this.m.ArmamentIcon = "icon_skv_blessed_water";
		this.m.Value = 230;
		this.m.RangeMax = 3;
		this.m.StaminaModifier = 0;
		this.m.IsDroppedAsLoot = true;
	}

	function getTooltip()
	{
		local result = [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			}
		];

		if (this.getIconLarge() != null)
		{
			result.push({
				id = 3,
				type = "image",
				image = this.getIconLarge(),
				isLarge = true
			});
		}
		else
		{
			result.push({
				id = 3,
				type = "image",
				image = this.getIcon()
			});
		}

		result.push({
			id = 66,
			type = "text",
			text = this.getValueString()
		});
		result.push({
			id = 64,
			type = "text",
			text = "Worn in Offhand"
		});
		result.push({
			id = 7,
			type = "text",
			icon = "ui/icons/vision.png",
			text = "Range of [color=" + ::Const.UI.Color.PositiveValue + "]" + this.m.RangeMax + "[/color] tiles"
		});
		result.push({
			id = 5,
			type = "text",
			icon = "ui/icons/regular_damage.png",
			text = "Inflicts [color=" + ::Const.UI.Color.DamageValue + "]20[/color] damage to hitpoints for [color=" + ::Const.UI.Color.DamageValue + "]3[/color] turns, all of which ignores armor"
		});
		result.push({
			id = 8,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Only affects undead targets, and only the target is splashed"
		});
		result.push({
			id = 6,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Is destroyed on use"
		});
		return result;
	}

	function playInventorySound( _eventType )
	{
		this.Sound.play("sounds/bottle_01.wav", ::Const.Sound.Volume.Inventory);
	}

	function onEquip()
	{
		this.weapon.onEquip();
		try
		{
			this.addSkill(this.new("scripts/skills/actives/skv_throw_blessed_water_skill"));
		}
		catch (e)
		{
			::logError("Skv.BlessedWater: the throw skill was not attached; the vial cannot be thrown: " + e);
		}
	}

});
