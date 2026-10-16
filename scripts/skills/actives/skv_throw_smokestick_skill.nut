this.skv_throw_smokestick_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_throw_smokestick";
		this.m.Name = "Throw Smokestick";
		this.m.Description = "Snap the tube and throw it. Thick smoke rises where it lands and hides whoever stands there from arrows and bolts for a round.";
		this.m.Icon = "skills/active_208.png";
		this.m.IconDisabled = "skills/active_208_sw.png";
		this.m.Overlay = "active_208";
		this.m.SoundOnUse = [
			"sounds/combat/throw_ball_01.wav",
			"sounds/combat/throw_ball_02.wav",
			"sounds/combat/throw_ball_03.wav"
		];
		this.m.SoundOnHit = [
			"sounds/combat/dlc6/smoke_bomb_01.wav",
			"sounds/combat/dlc6/smoke_bomb_02.wav",
			"sounds/combat/dlc6/smoke_bomb_03.wav"
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
		this.m.MinRange = 0;
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
			id = 5,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Covers [color=" + ::Const.UI.Color.DamageValue + "]1[/color] tile in smoke for one round"
		});
		ret.push({
			id = 6,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Whoever stands in it takes half damage from ranged attacks, has half the Ranged Skill, ignores zones of control and is hidden"
		});
		ret.push({
			id = 9,
			type = "text",
			icon = "ui/icons/vision.png",
			text = "Whoever stands in it has [color=" + ::Const.UI.Color.NegativeValue + "]-10[/color] Vision"
		});
		ret.push({
			id = 7,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Puts out fire or miasma on that tile"
		});
		ret.push({
			id = 8,
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
		if (off != null && off.getID() == "weapon.skv_smokestick")
		{
			items.unequip(off);
		}
		else
		{
			::logError("Skv.Smokestick: " + _user.getName() + "'s offhand holds " + (off == null ? "nothing" : off.getID())
				+ ", not the stick; nothing was removed (the smoke still rises).");
		}

		this.Time.scheduleEvent(this.TimeUnit.Real, 250, this.onApply.bindenv(this), {
			Skill = this,
			User = _user,
			TargetTile = _targetTile
		});
		return true;
	}

	function onApply( _data )
	{
		local tile = _data.TargetTile;

		if (_data.Skill.m.SoundOnHit.len() != 0)
		{
			this.Sound.play(_data.Skill.m.SoundOnHit[this.Math.rand(0, _data.Skill.m.SoundOnHit.len() - 1)], 1.0, tile.Pos);
		}

		this.Tactical.State.spawnSmokeOnTile(tile, _data.User.isPlayerControlled(), true);
		local fx = tile.Properties.Effect;
		::logInfo("Skv.Smokestick: smoke on " + tile.Coords.X + "," + tile.Coords.Y + ": " + (fx != null && fx.Type == "smoke" ? "yes" : "NO")
			+ (tile.IsOccupiedByActor ? ", on " + tile.getEntity().getName() : ", empty tile"));
	}

});
