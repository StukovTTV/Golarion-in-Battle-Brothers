this.skv_alchemists_acid_item <- this.inherit("scripts/items/weapons/weapon", {
	m = {},

	function create()
	{
		this.weapon.create();
		this.m.ID = "weapon.skv_alchemists_acid";
		this.m.Name = "Alchemist's Acid";
		this.m.Description = "A round glass flask with an iron snake coiled about its neck, holding a thin green liquid that smokes wherever it touches. Thrown, it eats into the armour of whoever it splashes.";
		this.m.IconLarge = "misc/skv_alchemists_acid.png";
		this.m.Icon = "misc/skv_alchemists_acid_70x70.png";
		this.m.SlotType = ::Const.ItemSlot.Offhand;
		this.m.ItemType = ::Const.Items.ItemType.Tool;
		this.m.AddGenericSkill = true;
		this.m.ShowArmamentIcon = true;
		this.m.ArmamentIcon = "icon_skv_alchemists_acid";
		this.m.Value = 200;
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
			text = "Reduces the target's armour by [color=" + ::Const.UI.Color.DamageValue + "]20%[/color] each turn for 3 turns"
		});
		result.push({
			id = 8,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Only the target is splashed"
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
			this.addSkill(this.new("scripts/skills/actives/skv_throw_alchemists_acid_skill"));
		}
		catch (e)
		{
			::logError("Skv.AlchAcid: the throw skill was not attached; the flask cannot be thrown: " + e);
		}
	}

});
