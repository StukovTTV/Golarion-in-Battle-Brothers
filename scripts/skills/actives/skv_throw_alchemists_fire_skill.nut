this.skv_throw_alchemists_fire_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_throw_alchemists_fire";
		this.m.Name = "Throw Alchemist's Fire";
		this.m.Description = "Throw the vial. It shatters and the sticky stuff inside bursts into flame, burning whoever stands where it lands, friend or foe.";
		this.m.Icon = "skills/active_209.png";
		this.m.IconDisabled = "skills/active_209_sw.png";
		this.m.Overlay = "active_209";
		this.m.SoundOnUse = [
			"sounds/combat/throw_ball_01.wav",
			"sounds/combat/throw_ball_02.wav",
			"sounds/combat/throw_ball_03.wav"
		];
		this.m.SoundOnHit = [
			"sounds/combat/dlc6/fire_pot_01.wav",
			"sounds/combat/dlc6/fire_pot_02.wav",
			"sounds/combat/dlc6/fire_pot_03.wav",
			"sounds/combat/dlc6/fire_pot_04.wav"
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
		this.m.ProjectileType = ::Const.ProjectileType.Bomb1;
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
			text = "Sets one tile on fire until the end of the round. Water and snow can not burn."
		});
		ret.push({
			id = 7,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Is destroyed on use"
		});
		return ret;
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

	function onTargetSelected( _targetTile )
	{
		this.Tactical.getHighlighter().addOverlayIcon(::Const.Tactical.Settings.AreaOfEffectIcon, _targetTile, _targetTile.Pos.X, _targetTile.Pos.Y);
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
		if (off != null && off.getID() == "weapon.skv_alchemists_fire")
		{
			items.unequip(off);
		}
		else
		{
			::logError("Skv.AlchFire: " + _user.getName() + "'s offhand holds " + (off == null ? "nothing" : off.getID())
				+ ", not the vial; nothing was removed (the fire still lands).");
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
		this.Sound.play(this.m.SoundOnHit[this.Math.rand(0, this.m.SoundOnHit.len() - 1)], 1.0, tile.Pos);

		local who = tile.IsOccupiedByActor ? tile.getEntity() : null;
		local hpBefore = who == null ? 0 : who.getHitpoints();
		local round = "?";
		try { round = this.Time.getRound(); }
		catch (e) { ::logError("Skv.AlchFire: the round could not be read for the log - " + e); }

		this.Tactical.State.spawnFireOnTile(tile, _data.User.isPlayerControlled(), true, 1);

		::logInfo("Skv.AlchFire: fire laid on " + tile.Coords.X + "," + tile.Coords.Y + " in round " + round
			+ (who == null ? "; the tile was empty"
				: "; " + who.getName() + " stood there, HP " + hpBefore + " -> " + (who.isAlive() ? who.getHitpoints() : "dead")));
	}

});
