this.skv_rat_claws <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		local C = ::Const.Skv.Rats.Claws;
		this.m.ID = "actives.skv_rat_claws";
		this.m.Name = "Claws";
		this.m.Description = "Long, filthy claws that rake flesh and cloth alike.";
		this.m.KilledString = "Ripped to shreds";
		this.m.Icon = "skills/active_21.png";
		this.m.Overlay = "active_21";
		this.m.SoundOnUse = [
			"sounds/enemies/ghoul_claws_01.wav",
			"sounds/enemies/ghoul_claws_02.wav",
			"sounds/enemies/ghoul_claws_03.wav",
			"sounds/enemies/ghoul_claws_04.wav",
			"sounds/enemies/ghoul_claws_05.wav",
			"sounds/enemies/ghoul_claws_06.wav"
		];
		this.m.SoundOnHitHitpoints = [
			"sounds/enemies/werewolf_claw_hit_01.wav",
			"sounds/enemies/werewolf_claw_hit_02.wav",
			"sounds/enemies/werewolf_claw_hit_03.wav"
		];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = this.Const.SkillOrder.OffensiveTargeted;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsStacking = false;
		this.m.IsAttack = true;
		this.m.InjuriesOnBody = this.Const.Injury.CuttingBody;
		this.m.InjuriesOnHead = this.Const.Injury.CuttingHead;
		this.m.DirectDamageMult = 0.1;
		this.m.ActionPointCost = C.ActionPoints;
		this.m.FatigueCost = C.Fatigue;
		this.m.MinRange = 1;
		this.m.MaxRange = 1;
		this.m.ChanceDecapitate = 0;
		this.m.ChanceDisembowel = 33;
		this.m.ChanceSmash = 0;
	}

	function onAnySkillUsed( _skill, _targetEntity, _properties )
	{
		if (_skill == this)
		{
			local C = ::Const.Skv.Rats.Claws;
			_properties.DamageRegularMin += C.Min;
			_properties.DamageRegularMax += C.Max;
			_properties.DamageArmorMult *= C.ArmorMult;
		}
	}

	function onUse( _user, _targetTile )
	{
		return this.attackEntity(_user, _targetTile.getEntity());
	}

});
