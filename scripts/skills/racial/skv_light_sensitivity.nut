this.skv_light_sensitivity <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "racial.skv_light_sensitivity";
		this.m.Name = "Light Sensitivity";
		this.m.Description = "This creature was hatched underground and has never made peace with the sun. It sees further than any surface-dweller once the light fails, and rather less than one while it lasts.";
		this.m.Icon = "ui/icons/vision.png";
		this.m.Type = this.Const.SkillType.Racial | this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function getTooltip()
	{
		local isDay = this.World.getTime().IsDaytime;

		local ret = [
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
				id = 3,
				type = "text",
				icon = "ui/icons/vision.png",
				text = isDay
					? "[color=" + this.Const.UI.Color.NegativeValue + "]-1[/color] Vision in daylight"
					: "[color=" + this.Const.UI.Color.PositiveValue + "]+1[/color] Vision in darkness"
			},
			{
				id = 4,
				type = "text",
				icon = "ui/icons/vision.png",
				text = "Does not suffer the penalties of fighting at night"
			}
		];

		return ret;
	}

	function onUpdate( _properties )
	{
		_properties.IsAffectedByNight = false;

		if (this.World.getTime().IsDaytime)
		{
			_properties.Vision = _properties.Vision - 1;
		}
		else
		{
			_properties.Vision = _properties.Vision + 1;
		}
	}

});
