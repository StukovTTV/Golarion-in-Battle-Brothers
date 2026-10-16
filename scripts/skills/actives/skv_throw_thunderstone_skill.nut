this.skv_throw_thunderstone_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_throw_thunderstone";
		this.m.Name = "Throw Thunderstone";
		this.m.Description = "Throw the stone hard at the ground. It bursts with a crack like a lightning stroke, and whoever stands where it lands is left dazed and deaf, friend or foe.";
		this.m.Icon = "skills/active_207.png";
		this.m.IconDisabled = "skills/active_207_sw.png";
		this.m.Overlay = "active_207";
		this.m.SoundOnUse = [
			"sounds/combat/throw_ball_01.wav",
			"sounds/combat/throw_ball_02.wav",
			"sounds/combat/throw_ball_03.wav"
		];
		this.m.SoundOnHit = [
			"sounds/combat/dlc6/daze_bomb_01.wav",
			"sounds/combat/dlc6/daze_bomb_02.wav",
			"sounds/combat/dlc6/daze_bomb_03.wav",
			"sounds/combat/dlc6/daze_bomb_04.wav"
		];
		this.m.SoundOnHitDelay = 0;
		this.m.Type = ::Const.SkillType.Active;
		this.m.Order = ::Const.SkillOrder.UtilityTargeted;
		this.m.Delay = 0;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsTargetingActor = false;
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
		this.m.ProjectileType = ::Const.ProjectileType.Bomb2;
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
			text = "Gives [color=" + ::Const.UI.Color.DamageValue + "]1[/color] target the Dazed status effect for 2 turns"
		});
		ret.push({
			id = 7,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Is destroyed on use"
		});
		return ret;
	}

	function onTargetSelected( _targetTile )
	{
		this.Tactical.getHighlighter().addOverlayIcon(::Const.Tactical.Settings.AreaOfEffectIcon, _targetTile, _targetTile.Pos.X, _targetTile.Pos.Y);
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
		if (this.m.IsShowingProjectile && this.m.ProjectileType != 0)
		{
			local flip = !this.m.IsProjectileRotated && _targetTile.Pos.X > _user.getPos().X;

			if (_user.getTile().getDistanceTo(_targetTile) >= ::Const.Combat.SpawnProjectileMinDist)
			{
				this.Tactical.spawnProjectileEffect(::Const.ProjectileSprite[this.m.ProjectileType], _user.getTile(), _targetTile, 1.0, this.m.ProjectileTimeScale, this.m.IsProjectileRotated, flip);
			}
		}

		local items = _user.getItems();
		local off = items.getItemAtSlot(::Const.ItemSlot.Offhand);
		if (off != null && off.getID() == "weapon.skv_thunderstone")
		{
			items.unequip(off);
		}
		else
		{
			::logError("Skv.Thunderstone: " + _user.getName() + "'s offhand holds " + (off == null ? "nothing" : off.getID())
				+ ", not the stone; nothing was removed (the daze still lands).");
		}

		this.Time.scheduleEvent(this.TimeUnit.Real, 250, this.onApply.bindenv(this), {
			Skill = this,
			TargetTile = _targetTile
		});
		return true;
	}

	function onApply( _data )
	{
		local tile = _data.TargetTile;

		if (_data.Skill.m.SoundOnHit.len() != 0)
		{
			this.Sound.play(_data.Skill.m.SoundOnHit[this.Math.rand(0, _data.Skill.m.SoundOnHit.len() - 1)], ::Const.Sound.Volume.Skill, tile.Pos);
		}

		for( local i = 0; i < ::Const.Tactical.DazeParticles.len(); i = ++i )
		{
			this.Tactical.spawnParticleEffect(false, ::Const.Tactical.DazeParticles[i].Brushes, tile, ::Const.Tactical.DazeParticles[i].Delay, ::Const.Tactical.DazeParticles[i].Quantity, ::Const.Tactical.DazeParticles[i].LifeTimeQuantity, ::Const.Tactical.DazeParticles[i].SpawnRate, ::Const.Tactical.DazeParticles[i].Stages);
		}

		if (!tile.IsOccupiedByActor)
		{
			::logInfo("Skv.Thunderstone: it burst on an empty tile; nobody dazed.");
			return;
		}

		local target = tile.getEntity();
		if (target.getCurrentProperties().IsImmuneToDaze)
		{
			::logInfo("Skv.Thunderstone: " + target.getName() + " is immune to daze; nothing happened.");
			return;
		}

		target.getSkills().add(this.new("scripts/skills/effects/dazed_effect"));
		::logInfo("Skv.Thunderstone: " + target.getName() + " was hit; dazed now: " + target.getSkills().hasSkill("effects.dazed"));
	}

});
