this.skv_pearl_of_power_skill <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "actives.skv_pearl_of_power";
		this.m.Name = "Pearl of Power";
		this.m.Description = "Grip the pearl and call back what you have already spent in this fight. Once a day.";
		this.m.Icon = "ui/perks/perk_54_active.png";
		this.m.IconDisabled = "ui/perks/perk_54_active_sw.png";
		this.m.Overlay = "perk_54_active";
		this.m.SoundOnUse = [
			"sounds/combat/perfect_focus_01.wav"
		];
		this.m.SoundVolume = 0.5;
		this.m.Type = ::Const.SkillType.Active;
		this.m.Order = ::Const.SkillOrder.Any;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = false;

		this.m.IsStacking = true;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 3;
		this.m.FatigueCost = 0;
		this.m.MinRange = 0;
		this.m.MaxRange = 0;
	}

	function pearl()
	{
		if (this.m.Item == null || this.m.Item.isNull()) return null;
		return this.m.Item;
	}

	function getTooltip()
	{
		local ret = this.getDefaultUtilityTooltip();
		ret.push({
			id = 10,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Once per day: restores the carrier's spent abilities"
		});

		local p = this.pearl();
		local why = null;
		local names = [];
		if (p == null) why = "The pearl is not carried";
		else if (p.getCharges() <= 0) why = "Spent for the day";
		else if (this.getContainer() != null && this.Tactical.isActive())
		{
			foreach (e in p.spentOf(this.getContainer().getActor()).Spent) names.push(e.What);
			if (names.len() == 0) why = "No spent ability to restore";
		}

		if (why != null)
		{
			ret.push({
				id = 11,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + ::Const.UI.Color.NegativeValue + "]" + why + "[/color]"
			});
		}
		else if (names.len() > 0)
		{
			local s = "";
			foreach (i, n in names) s += (i == 0 ? "" : ", ") + n;
			ret.push({
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Would restore: " + s
			});
		}
		return ret;
	}

	function isUsable()
	{
		if (!this.Tactical.isActive() || !this.skill.isUsable())
		{
			return false;
		}
		local p = this.pearl();
		if (p == null || p.getCharges() <= 0)
		{
			return false;
		}
		return p.spentOf(this.getContainer().getActor()).Spent.len() > 0;
	}

	function onUse( _user, _targetTile )
	{
		local p = this.pearl();
		if (p == null)
		{
			::logError("Skv.Pearl: " + _user.getName() + " used the pearl's action with no pearl behind it; nothing restored.");
			return false;
		}
		if (p.getCharges() <= 0)
		{
			::logInfo("Skv.Pearl: " + _user.getName() + "'s pearl is spent for the day; nothing restored.");
			return false;
		}

		local r = p.restore(_user);
		if (r.Restored.len() == 0)
		{

			::logError("Skv.Pearl: " + _user.getName() + " used the pearl and nothing was restored; the charge is kept.");
			return false;
		}

		local left = p.spendCharge();
		_user.getSkills().update();

		local s = "";
		foreach (i, n in r.Restored) s += (i == 0 ? "" : ", ") + n;
		if (this.Tactical.EventLog != null)
		{
			this.Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user) + " grips a Pearl of Power and calls back " + s);
		}
		::logInfo("Skv.Pearl: " + _user.getName() + " restored " + s + "; " + left + "/" + p.m.ChargesMax + " charge left"
			+ (r.Failed.len() > 0 ? "; " + r.Failed.len() + " entry(ies) failed (logged above)" : "") + ".");
		return true;
	}

});
