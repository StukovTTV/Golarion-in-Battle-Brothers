this.skv_throw_blessed_water_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_throw_blessed_water";
		this.m.Name = "Throw Blessed Water";
		this.m.Description = "Throw the vial at one of the walking dead. It breaks, and the blessed water burns into them for a few turns. It does nothing to anything else.";
		this.m.Icon = "skills/active_97.png";
		this.m.IconDisabled = "skills/active_97_sw.png";
		this.m.Overlay = "active_97";
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
		this.m.ProjectileType = ::Const.ProjectileType.Flask2;
		this.m.ProjectileTimeScale = 1.5;
		this.m.IsProjectileRotated = false;
	}

	function getTooltip()
	{
		local ret = this.getDefaultUtilityTooltip();
		ret.push({
			id = 6,
			type = "text",
			icon = "ui/icons/regular_damage.png",
			text = "Inflicts [color=" + ::Const.UI.Color.DamageValue + "]20[/color] damage to hitpoints for [color=" + ::Const.UI.Color.DamageValue + "]3[/color] turns, all of which ignores armor"
		});
		ret.push({
			id = 7,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Only affects undead targets, and only the target is splashed"
		});
		ret.push({
			id = 8,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Is destroyed on use"
		});
		return ret;
	}

	function applyEffect( _target )
	{
		if (!_target.getFlags().has("undead"))
		{
			return;
		}

		local poison = _target.getSkills().getSkillByID("effects.holy_water");

		if (poison == null)
		{
			_target.getSkills().add(this.new("scripts/skills/effects/holy_water_effect"));
		}
		else
		{
			poison.resetTime();
		}
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
		if (off != null && off.getID() == "weapon.skv_blessed_water")
		{
			items.unequip(off);
		}
		else
		{
			::logError("Skv.BlessedWater: " + _user.getName() + "'s offhand holds " + (off == null ? "nothing" : off.getID())
				+ ", not the vial; nothing was removed (the water still lands).");
		}

		this.Time.scheduleEvent(this.TimeUnit.Real, 200, this.onApplyEffect.bindenv(this), {
			Skill = this,
			TargetTile = _targetTile
		});
		return true;
	}

	function onApplyEffect( _data )
	{
		local tile = _data.TargetTile;
		if (!tile.IsOccupiedByActor)
		{
			::logInfo("Skv.BlessedWater: the vial landed on " + tile.Coords.X + "," + tile.Coords.Y + ", and nobody stood there any more");
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

		local name = target.getName();
		local had = target.getSkills().hasSkill("effects.holy_water");
		_data.Skill.applyEffect(target);

		local alive = target.isAlive();
		local burns = !alive || target.getSkills().hasSkill("effects.holy_water");
		::logInfo("Skv.BlessedWater: " + name + " splashed; " + (had ? "already burning (clock reset)" : (burns ? "it burns" : "nothing (not undead)"))
			+ (alive ? ", hitpoints " + target.getHitpoints() : ", and it died"));
	}

});
