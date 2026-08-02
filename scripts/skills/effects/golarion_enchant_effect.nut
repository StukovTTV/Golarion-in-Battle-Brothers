this.golarion_enchant_effect <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "effects.golarion_enchant";
		this.m.Name = "Enhancement";
		this.m.Description = "This weapon carries an enhancement.";
		this.m.Icon = "ui/icons/special.png";
		this.m.Type = this.Const.SkillType.Special | this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.VeryLast;
		this.m.IsActive = false;
		this.m.IsStacking = true;
		this.m.IsHidden = true;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = false;
	}

	function onAnySkillUsed( _skill, _targetEntity, _properties )
	{
		local item = this.getItem();
		if (!_skill.isAttack() || item == null)
			return;

		if (item.getSlotType() == this.Const.ItemSlot.Ammo)
		{
			if (!_skill.isRanged())
				return;
		}
		else
		{
			if (_skill.getItem() == null)
				return;
			if (_skill.getItem().getInstanceID() != item.getInstanceID())
				return;
		}

		local acc = item.getEnchantAccuracy();
		if (acc != 0)
		{
			_properties.MeleeSkill  += acc;
			_properties.RangedSkill += acc;
		}

		if (item.getEnchant() > 0)
		{
			local add = ("RegularDamage" in item.m) && item.m.RegularDamage > 0
				? item.getEnchantDamageBonus(item.m.RegularDamage, item.m.RegularDamageMax)
				: item.getEnchantDamageBonus();

			_properties.DamageRegularMin += add[0];
			_properties.DamageRegularMax += add[1];
		}
	}
});
