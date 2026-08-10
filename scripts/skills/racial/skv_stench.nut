this.skv_stench <- this.inherit("scripts/skills/skill", {
	m = {

		Amplified = false
	},

	function create()
	{
		this.m.ID = "racial.skv_stench";
		this.m.Name = "Stench";
		this.m.Description = "Troglodytes secrete an oil that turns the air around them foul enough to make a man's eyes stream. They do not notice it in each other.";
		this.m.Icon = "ui/icons/special.png";

		this.m.Type = this.Const.SkillType.Racial | this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = false;
	}

	function amplify()
	{
		this.m.Amplified = true;
		this.m.Name = "Amplified Stench";
		return true;
	}

	function getName()
	{
		return this.m.Amplified ? "Amplified Stench" : "Stench";
	}

	function getTooltip()
	{

		local melee   = this.m.Amplified ? ::Const.Skv.StenchMeleeSkillAmplified  : ::Const.Skv.StenchMeleeSkill;
		local ranged  = this.m.Amplified ? ::Const.Skv.StenchRangedSkillAmplified : ::Const.Skv.StenchRangedSkill;
		local fatigue = this.m.Amplified ? ::Const.Skv.StenchFatigueAmplified     : ::Const.Skv.StenchFatigue;

		return [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.m.Amplified
					? "This one reeks far worse than the rest, and does it on purpose. The oil is thick enough to see, and it comes off her in a haze."
					: this.getDescription()
			},
			{
				id = 3,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Anyone who [b]ends their turn[/b] in a tile next to this creature starts retching: [color=" + ::Const.UI.Color.NegativeValue + "]-" + melee + "[/color] Melee Skill, [color=" + ::Const.UI.Color.NegativeValue + "]-" + ranged + "[/color] Ranged Skill, and " + fatigue + " Fatigue for the gasp."
			},
			{
				id = 4,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Striking one and stepping away costs nothing. Standing and trading blows with it is what costs."
			},
			{
				id = 5,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Other troglodytes are unaffected."
			}
		];
	}

});
