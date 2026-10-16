this.skv_protection_from_evil_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.skv_protection_from_evil";
		this.m.Name = "Protection from Evil";
		this.m.Icon = "skills/status_effect_90.png";
		this.m.IconMini = "status_effect_90_mini";
		this.m.Overlay = "status_effect_90";
		this.m.Type = ::Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = true;
	}

	function getDescription()
	{
		return "This character drank a Potion of Protection from Evil. He stands steadier, and blows aimed at him seem to slide off a little.";
	}

	function getTooltip()
	{
		return [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/bravery.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]+10[/color] Resolve"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/melee_defense.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Melee Defense"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/icons/ranged_defense.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Ranged Defense"
			},
			{
				id = 13,
				type = "hint",
				icon = "ui/icons/special.png",
				text = "Lasts until the battle ends"
			}
		];
	}

	function onUpdate( _properties )
	{
		_properties.Bravery += 10;
		_properties.MeleeDefense += 5;
		_properties.RangedDefense += 5;
	}

});
