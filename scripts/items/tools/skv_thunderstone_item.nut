this.skv_thunderstone_item <- this.inherit("scripts/items/weapons/weapon", {
	m = {},

	function create()
	{
		this.weapon.create();
		this.m.ID = "weapon.skv_thunderstone";
		this.m.Name = "Thunderstone";
		this.m.Description = "A heavy stone ball, carved all over with deep grooves and a few lines of blue glaze, that hums faintly when shaken. Thrown hard against the ground it bursts with a crack like a lightning stroke, and leaves whoever stands there dazed.";
		this.m.IconLarge = "misc/skv_thunderstone.png";
		this.m.Icon = "misc/skv_thunderstone_70x70.png";
		this.m.SlotType = ::Const.ItemSlot.Offhand;
		this.m.ItemType = ::Const.Items.ItemType.Tool;
		this.m.AddGenericSkill = true;
		this.m.ShowArmamentIcon = true;
		this.m.ArmamentIcon = "icon_skv_thunderstone";
		this.m.Value = 300;
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
			text = "Gives [color=" + ::Const.UI.Color.DamageValue + "]1[/color] target the Dazed status effect for 2 turns"
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
		this.Sound.play("sounds/move_pot_clay_01.wav", ::Const.Sound.Volume.Inventory);
	}

	function onEquip()
	{
		this.weapon.onEquip();
		try
		{
			this.addSkill(this.new("scripts/skills/actives/skv_throw_thunderstone_skill"));
		}
		catch (e)
		{
			::logError("Skv.Thunderstone: the throw skill was not attached; the stone cannot be thrown: " + e);
		}
	}

});
