this.skv_opening_wand_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effect.skv_opening_wand";
		this.m.Name = "Wand of Opening";
		this.m.Description = "Carries a wand that opens locks.";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsHidden = true;
		this.m.IsSerialized = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = false;
	}

});
