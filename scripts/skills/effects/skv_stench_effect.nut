this.skv_stench_effect <- this.inherit("scripts/skills/skill", {
	m = {
		TurnsLeft = 2,

		Amplified = false
	},

	function create()
	{
		this.m.ID = "effects.skv_stench";
		this.m.Name = "Retching";
		this.m.Description = "The stink coming off these things is beyond bearing. Hard to breathe, harder to aim, and impossible to think about anything else.";
		this.m.Icon = "skills/status_effect_85.png";
		this.m.Type = this.Const.SkillType.Special | this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = true;
	}

	function getMeleePenalty()
	{
		return this.m.Amplified ? ::Const.Skv.StenchMeleeSkillAmplified : ::Const.Skv.StenchMeleeSkill;
	}

	function getRangedPenalty()
	{
		return this.m.Amplified ? ::Const.Skv.StenchRangedSkillAmplified : ::Const.Skv.StenchRangedSkill;
	}

	function getName()
	{
		return this.m.Amplified ? "Retching Violently" : "Retching";
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
				id = 3,
				type = "text",
				icon = "ui/icons/melee_skill.png",
				text = "[color=" + ::Const.UI.Color.NegativeValue + "]-" + this.getMeleePenalty() + "[/color] Melee Skill"
			},
			{
				id = 4,
				type = "text",
				icon = "ui/icons/ranged_skill.png",
				text = "[color=" + ::Const.UI.Color.NegativeValue + "]-" + this.getRangedPenalty() + "[/color] Ranged Skill"
			},
			{
				id = 5,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Ends one turn after you are no longer standing next to a troglodyte. You can hold your breath long enough for a swing, but not to stand and fight."
			}
		];
	}

	function onUpdate( _properties )
	{
		this.skill.onUpdate(_properties);
		_properties.MeleeSkill  -= this.getMeleePenalty();
		_properties.RangedSkill -= this.getRangedPenalty();
	}

	function onTurnStart()
	{
		this.m.TurnsLeft = this.m.TurnsLeft - 1;

		if (this.m.TurnsLeft <= 0)
		{
			this.removeSelf();
		}
	}

});
