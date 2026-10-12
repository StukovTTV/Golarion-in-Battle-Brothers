this.skv_rat_bite <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		local B = ::Const.Skv.Rats.Bite;
		this.m.ID = "actives.skv_rat_bite";
		this.m.Name = "Bite";
		this.m.Description = "Yellow teeth that go for the face and leave filth in the wound.";
		this.m.KilledString = "Gnawed to death";
		this.m.Icon = "skills/active_71.png";
		this.m.Overlay = "active_71";
		this.m.SoundOnUse = [
			"sounds/enemies/wolf_bite_01.wav",
			"sounds/enemies/wolf_bite_02.wav",
			"sounds/enemies/wolf_bite_03.wav",
			"sounds/enemies/wolf_bite_04.wav"
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
		this.m.InjuriesOnBody = this.Const.Injury.CuttingAndPiercingBody;
		this.m.InjuriesOnHead = this.Const.Injury.CuttingAndPiercingHead;
		this.m.DirectDamageMult = 0.2;
		this.m.ActionPointCost = B.ActionPoints;
		this.m.FatigueCost = B.Fatigue;
		this.m.MinRange = 1;
		this.m.MaxRange = 1;
		this.m.ChanceDecapitate = 0;
		this.m.ChanceDisembowel = 0;
		this.m.ChanceSmash = 0;
	}

	function onAnySkillUsed( _skill, _targetEntity, _properties )
	{
		if (_skill == this)
		{
			local B = ::Const.Skv.Rats.Bite;
			_properties.DamageRegularMin += B.Min;
			_properties.DamageRegularMax += B.Max;
			_properties.HitChance[this.Const.BodyPart.Head] += B.HeadBonus;
		}
	}

	function onUse( _user, _targetTile )
	{
		return this.attackEntity(_user, _targetTile.getEntity());
	}

});
