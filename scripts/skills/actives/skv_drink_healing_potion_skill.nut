this.skv_drink_healing_potion_skill <- this.inherit("scripts/skills/skill", {
	m = {
		Item = null
	},

	function create()
	{
		this.m.ID = "actives.skv_drink_healing_potion";
		this.m.Name = "Drink the Potion";
		this.m.Description = "Drink the potion, or pour it into a man beside you. It will close a cut and take the ache out of him. It will not give him his week back.";

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

	function setItem( _i )
	{
		this.m.Item = _i == null ? null : this.WeakTableRef(_i);
	}

	function getItem()
	{
		return this.m.Item;
	}

	function healRange()
	{
		local lo = 8;
		local hi = 14;
		try
		{
			if (this.m.Item != null && !this.m.Item.isNull())
			{
				lo = this.m.Item.getHealMin();
				hi = this.m.Item.getHealMax();
			}
		}
		catch (e)
		{
			lo = 8;
			hi = 14;
		}
		if (hi < lo) hi = lo;
		return [lo, hi];
	}

	function getDescription()
	{
		local r = this.healRange();
		return this.m.Description + "\n\nHeals [color=" + ::Const.UI.Color.PositiveValue + "]"
			+ r[0] + "[/color] - [color=" + ::Const.UI.Color.PositiveValue + "]" + r[1] + "[/color] hitpoints.";
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

		return target.getHitpoints() < target.getHitpointsMax();
	}

	function onUse( _user, _targetTile )
	{
		if (!_targetTile.IsOccupiedByActor)
		{
			return false;
		}

		local target = _targetTile.getEntity();
		local max = target.getHitpointsMax();
		local before = target.getHitpoints();

		local r = this.healRange();
		local gain = ::Math.min(max - before, ::Math.rand(r[0], r[1]));
		if (gain <= 0)
		{
			return false;
		}

		target.setHitpoints(before + gain);

		if (this.Tactical.EventLog != null)
		{
			this.Tactical.EventLog.log(::Const.UI.getColorizedEntityName(target)
				+ " recovers " + gain + " Hitpoints");
		}

		if (this.m.Item != null && !this.m.Item.isNull())
		{
			this.m.Item.removeSelf();
		}

		return true;
	}

});
