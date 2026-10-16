this.skv_throw_alchemists_acid_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_throw_alchemists_acid";
		this.m.Name = "Throw Alchemist's Acid";
		this.m.Description = "Throw the flask at someone. It bursts on them, and the acid eats into their armour for a few turns.";
		this.m.Icon = "skills/active_106.png";
		this.m.IconDisabled = "skills/active_106_sw.png";
		this.m.Overlay = "active_106";
		this.m.SoundOnUse = [
			"sounds/combat/throw_ball_01.wav",
			"sounds/combat/throw_ball_02.wav",
			"sounds/combat/throw_ball_03.wav"
		];
		this.m.SoundOnHit = [
			"sounds/combat/acid_flask_impact_01.wav",
			"sounds/combat/acid_flask_impact_02.wav",
			"sounds/combat/acid_flask_impact_03.wav",
			"sounds/combat/acid_flask_impact_04.wav"
		];
		this.m.SoundOnHitDelay = 0;
		this.m.Type = ::Const.SkillType.Active;
		this.m.Order = ::Const.SkillOrder.UtilityTargeted;
		this.m.Delay = 0;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsStacking = false;
		this.m.IsAttack = true;
		this.m.IsOffensiveToolSkill = true;
		this.m.IsRanged = false;
		this.m.IsIgnoredAsAOO = true;
		this.m.IsShowingProjectile = true;
		this.m.IsUsingHitchance = false;
		this.m.IsDoingForwardMove = true;
		this.m.ActionPointCost = 5;
		this.m.FatigueCost = 20;
		this.m.MinRange = 1;
		this.m.MaxRange = 3;
		this.m.MaxLevelDifference = 3;
		this.m.ProjectileType = ::Const.ProjectileType.Flask;
		this.m.ProjectileTimeScale = 1.5;
		this.m.IsProjectileRotated = false;
	}

	function getTooltip()
	{
		local ret = this.getDefaultUtilityTooltip();
		ret.push({
			id = 6,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Reduces the target's armour by [color=" + ::Const.UI.Color.DamageValue + "]20%[/color] each turn for 3 turns"
		});
		ret.push({
			id = 7,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Only the target is splashed"
		});
		ret.push({
			id = 8,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Is destroyed on use"
		});
		return ret;
	}

	function applyAcid( _target )
	{
		if (_target.getFlags().has("lindwurm"))
		{
			return;
		}

		if ((_target.getFlags().has("body_immune_to_acid") || _target.getArmor(::Const.BodyPart.Body) <= 0) && (_target.getFlags().has("head_immune_to_acid") || _target.getArmor(::Const.BodyPart.Head) <= 0))
		{
			return;
		}

		local poison = _target.getSkills().getSkillByID("effects.acid");

		if (poison == null)
		{
			_target.getSkills().add(this.new("scripts/skills/effects/acid_effect"));
		}
		else
		{
			poison.resetTime();
		}

		this.spawnIcon("status_effect_78", _target.getTile());
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!this.skill.onVerifyTarget(_originTile, _targetTile))
		{
			return false;
		}

		if (_originTile.Level + 1 < _targetTile.Level)
		{
			return false;
		}

		return true;
	}

	function onAfterUpdate( _properties )
	{
		this.m.FatigueCostMult = _properties.IsSpecializedInThrowing ? ::Const.Combat.WeaponSpecFatigueMult : 1.0;
	}

	function onUse( _user, _targetTile )
	{
		local targetEntity = _targetTile.getEntity();

		if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
		{
			local flip = !this.m.IsProjectileRotated && targetEntity.getPos().X > _user.getPos().X;

			if (_user.getTile().getDistanceTo(targetEntity.getTile()) >= ::Const.Combat.SpawnProjectileMinDist)
			{
				this.Tactical.spawnProjectileEffect(::Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), targetEntity.getTile(), 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
			}
		}

		local items = _user.getItems();
		local off = items.getItemAtSlot(::Const.ItemSlot.Offhand);
		if (off != null && off.getID() == "weapon.skv_alchemists_acid")
		{
			items.unequip(off);
		}
		else
		{
			::logError("Skv.AlchAcid: " + _user.getName() + "'s offhand holds " + (off == null ? "nothing" : off.getID())
				+ ", not the flask; nothing was removed (the acid still lands).");
		}

		this.Time.scheduleEvent(this.TimeUnit.Real, 200, this.onApplyAcid.bindenv(this), {
			Skill = this,
			TargetTile = _targetTile
		});
		return true;
	}

	function onApplyAcid( _data )
	{
		local tile = _data.TargetTile;
		if (!tile.IsOccupiedByActor)
		{
			::logInfo("Skv.AlchAcid: the flask landed on " + tile.Coords.X + "," + tile.Coords.Y + ", and nobody stood there any more");
			return;
		}

		local target = tile.getEntity();
		if (_data.Skill.m.SoundOnHit.len() != 0)
		{
			this.Sound.play(_data.Skill.m.SoundOnHit[this.Math.rand(0, _data.Skill.m.SoundOnHit.len() - 1)], ::Const.Sound.Volume.Skill, target.getPos());
		}

		if (!target.isAlive())
		{
			return;
		}

		local had = target.getSkills().hasSkill("effects.acid");
		_data.Skill.applyAcid(target);
		::logInfo("Skv.AlchAcid: " + target.getName() + " splashed; acid " + (had ? "already on (clock reset)" : (target.getSkills().hasSkill("effects.acid") ? "applied" : "not applied (immune, no armour or a lindwurm)"))
			+ ", armour head " + target.getArmor(::Const.BodyPart.Head) + " body " + target.getArmor(::Const.BodyPart.Body));
	}

});
