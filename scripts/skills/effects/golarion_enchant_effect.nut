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

	// A WEAPON's bonus is scoped by instance ID to attacks made with that weapon
	// rather than every swing the wielder takes -- it matters under Legends dual
	// wield, where two enchanted blades would otherwise both apply.
	//
	// AMMO cannot be scoped that way: the skill being used belongs to the BOW, not
	// to the quiver, so the instance IDs never match. Enchanted ammo instead applies
	// to any ranged attack the wielder makes while it is in his ammo slot -- which
	// is exactly what "+1 bolts" means, and it cannot leak onto his melee swings.
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

		// Damage is added in POINTS to the attack's own band -- the same field
		// weapon.onUpdateProperties adds the weapon's damage to -- rather than applied
		// as a multiplier. The bonus is a percentage of the base band WITH A FLOOR of
		// one point per tier, and a floor cannot be expressed as a multiplier.
		//
		// ⚠ AMMO GETS THE FLAT FLOOR, and it gets it by having no band to pass. A bolt
		// has no damage of its own, so getEnchantDamageBonus falls through to one point
		// per tier -- deliberately, not as a degenerate case: the crossbow behind the
		// shot is already a big number and may carry an enhancement of its own, so a
		// percentage here would compound one percentage onto another.
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
