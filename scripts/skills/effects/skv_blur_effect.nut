this.skv_blur_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.skv_blur";
		this.m.Name = "Blur";
		this.m.Icon = "ui/perks/perk_01.png";
		this.m.IconMini = "perk_01_mini";
		this.m.Type = ::Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = true;
	}

	function getDescription()
	{
		return "This character drank a Potion of Blur. He looks blurred and hard to follow, and the quicker he moves the harder he is to hit. Lasts until the battle ends.";
	}

	function bonus()
	{
		return ::Math.max(0, ::Math.floor(this.getContainer().getActor().getInitiative() * 0.15));
	}

	function getTooltip()
	{
		local b = this.bonus();
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
				icon = "ui/icons/melee_defense.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]+" + b + "[/color] Melee Defense"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/ranged_defense.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]+" + b + "[/color] Ranged Defense"
			}
		];
	}

	function onAfterUpdate( _properties )
	{
		local b = this.bonus();
		_properties.MeleeDefense += b;
		_properties.RangedDefense += b;
	}

});
