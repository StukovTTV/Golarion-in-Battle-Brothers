this.skv_drink_protection_potion_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_drink_protection_potion";
		this.m.Name = "Drink Protection from Evil";
		this.m.Description = "Drink the potion, or pour it into a man beside you. He stands steadier and harder to hit until the fighting is done.";
		this.m.Icon = "skills/active_96.png";
		this.m.IconDisabled = "skills/active_96_sw.png";
		this.m.Overlay = "active_96";
		this.m.SoundOnUse = [
			"sounds/combat/drink_01.wav",
			"sounds/combat/drink_02.wav",
			"sounds/combat/drink_03.wav"
		];
		this.m.Type = ::Const.SkillType.Active;
		this.m.Order = ::Const.SkillOrder.Any;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsStacking = true;
		this.m.ActionPointCost = 4;
		this.m.FatigueCost = 5;
		this.m.MinRange = 0;
		this.m.MaxRange = 1;
	}

	function getTooltip()
	{
		local ret = this.getDefaultUtilityTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/bravery.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+10[/color] Resolve"
		});
		ret.push({
			id = 11,
			type = "text",
			icon = "ui/icons/melee_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Melee Defense"
		});
		ret.push({
			id = 12,
			type = "text",
			icon = "ui/icons/ranged_defense.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+5[/color] Ranged Defense"
		});
		ret.push({
			id = 13,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Lasts until the battle ends. Not on a man who has already drunk one"
		});
		return ret;
	}

	function isUsable()
	{
		if (!this.Tactical.isActive())
		{
			return false;
		}

		local actor = this.getContainer().getActor();
		local tile = actor.getTile();
		return this.skill.isUsable() && !tile.hasZoneOfControlOtherThan(actor.getAlliedFactions());
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!this.skill.onVerifyTarget(_originTile, _targetTile))
		{
			return false;
		}

		local target = _targetTile.getEntity();
		if (target == null)
		{
			return false;
		}
		if (!this.m.Container.getActor().isAlliedWith(target))
		{
			return false;
		}

		return !target.getSkills().hasSkill("effects.skv_protection_from_evil");
	}

	function onUse( _user, _targetTile )
	{
		if (!_targetTile.IsOccupiedByActor)
		{
			return false;
		}

		local target = _targetTile.getEntity();
		if (target.getSkills().hasSkill("effects.skv_protection_from_evil"))
		{
			return false;
		}

		target.getSkills().add(this.new("scripts/skills/effects/skv_protection_from_evil_effect"));

		if (this.Tactical.EventLog != null)
		{
			this.Tactical.EventLog.log(::Const.UI.getColorizedEntityName(target) + " drinks a Potion of Protection from Evil");
		}
		::logInfo("Skv.potion: " + target.getName() + " drank Protection from Evil (from " + _user.getName() + "'s bag).");

		if (this.m.Item != null && !this.m.Item.isNull())
		{
			this.m.Item.removeSelf();
		}
		else
		{
			::logError("Skv.potion: the Protection from Evil drink had no bottle to empty; the effect was given anyway.");
		}

		return true;
	}

});
