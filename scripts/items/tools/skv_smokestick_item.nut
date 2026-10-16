this.skv_smokestick_item <- this.inherit("scripts/items/weapons/weapon", {
	m = {},

	function create()
	{
		this.weapon.create();
		this.m.ID = "weapon.skv_smokestick";
		this.m.Name = "Smokestick";
		this.m.Description = "A slim glass tube on a cord, full of something dark. Snap it and throw it, and it pours out thick grey smoke where it lands.";
		this.m.IconLarge = "misc/skv_smokestick.png";
		this.m.Icon = "misc/skv_smokestick_70x70.png";
		this.m.SlotType = ::Const.ItemSlot.Offhand;
		this.m.ItemType = ::Const.Items.ItemType.Tool;
		this.m.AddGenericSkill = true;
		this.m.ShowArmamentIcon = true;
		this.m.ArmamentIcon = "icon_skv_smokestick";
		this.m.Value = 220;
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
			icon = "ui/icons/special.png",
			text = "Covers [color=" + ::Const.UI.Color.DamageValue + "]1[/color] tile in smoke for one round"
		});
		result.push({
			id = 8,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Whoever stands in it takes half damage from ranged attacks, has half the Ranged Skill, ignores zones of control and is hidden"
		});
		result.push({
			id = 9,
			type = "text",
			icon = "ui/icons/vision.png",
			text = "Whoever stands in it has [color=" + ::Const.UI.Color.NegativeValue + "]-10[/color] Vision"
		});
		result.push({
			id = 10,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Puts out fire or miasma on that tile"
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
			this.addSkill(this.new("scripts/skills/actives/skv_throw_smokestick_skill"));
		}
		catch (e)
		{
			::logError("Skv.Smokestick: the throw skill was not attached; the stick cannot be thrown: " + e);
		}
	}

});
