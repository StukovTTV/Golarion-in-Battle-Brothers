this.skv_vermin <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "racial.skv_vermin";
		this.m.Name = "Vermin";
		this.m.Description = "Rats have plagued cellars, granaries and sewers for as long as there have been any, and some folk make a living of killing them. A ratcatcher knows where a rat is soft and which way it will twist.";
		this.m.Icon = "ui/icons/regular_damage.png";
		this.m.Type = this.Const.SkillType.Racial | this.Const.SkillType.Perk;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function getTooltip()
	{
		local pct = this.Math.round((::Const.Skv.Rats.RatcatcherDamageMult - 1.0) * 100);

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
				icon = "ui/icons/regular_damage.png",
				text = "Takes [color=" + this.Const.UI.Color.NegativeValue + "]" + pct + "%[/color] more damage from a Ratcatcher"
			}
		];

		return ret;
	}

	function onBeforeDamageReceived( _attacker, _skill, _hitInfo, _properties )
	{
		if (_attacker == null) return;

		local isRatcatcher = false;
		try
		{
			isRatcatcher = _attacker.getSkills().hasSkill(::Const.Skv.Lore.RatcatcherBg);
		}
		catch (e)
		{
			::logError("Skv.Rat: Vermin could not read the attacker's background - " + e);
			return;
		}

		if (!isRatcatcher) return;

		_properties.DamageReceivedTotalMult *= ::Const.Skv.Rats.RatcatcherDamageMult;
		::Skv.dbg("Skv.Rat: Vermin. " + _attacker.getName() + " is a Ratcatcher: "
			+ this.getContainer().getActor().getName() + " takes x" + ::Const.Skv.Rats.RatcatcherDamageMult
			+ " (" + (_skill != null ? _skill.getID() : "no skill") + ")");
	}

});
