::GolarionEnchant <- {

	MaxTier = 5,

	MinTierForNamed = 2,

	DamagePercentPerTier = 3,
	MinDamagePerTier = 1,

	AccuracyPointsPerTier = 2,

	MasterworkAccuracy = 2,

	ValueQuadraticFactor = 0.4,
	MasterworkValueMult = 1.5
};

::GolarionEnchant.apply <- function ( _item, _tier ) {
	if (!::GolarionEnchant.isEligible(_item))
		return false;

	if (_tier < 0) _tier = 0;
	if (_tier > ::GolarionEnchant.MaxTier) _tier = ::GolarionEnchant.MaxTier;

	if (_tier > 0
		&& _item.isItemType(::Const.Items.ItemType.Named)
		&& _tier < ::GolarionEnchant.MinTierForNamed) {
		return false;
	}

	_item.setEnchant(_tier);
	return true;
}

::GolarionEnchant.setMasterwork <- function ( _item, _v = true ) {
	if (!::GolarionEnchant.isEligible(_item))
		return false;
	_item.setMasterwork(_v);
	return true;
}

::GolarionEnchant.isEligible <- function ( _item ) {
	if (_item == null)
		return false;

	if (_item.isItemType(::Const.Items.ItemType.Tool))
		return false;
	if (_item.isItemType(::Const.Items.ItemType.Weapon))
		return true;
	if (_item.isItemType(::Const.Items.ItemType.Ammo))
		return true;
	return false;
}

::GolarionEnchant.get <- function ( _item ) {
	if (_item == null)
		return 0;
	try { return _item.getEnchant(); }
	catch (e) { return 0; }
}

::GolarionEnchant.findMostDamaged <- function () {
	local candidates = [];

	foreach ( bro in ::World.getPlayerRoster().getAll() ) {
		foreach ( item in bro.getItems().getAllItems() ) {
			if (item != null
				&& ::GolarionEnchant.get(item) > 0
				&& item.getConditionMax() > 1
				&& item.getCondition() < item.getConditionMax()) {
				candidates.push(item);
			}
		}
	}

	foreach ( item in ::World.Assets.getStash().getItems() ) {
		if (item != null
			&& ::GolarionEnchant.get(item) > 0
			&& item.getConditionMax() > 1
			&& item.getCondition() < item.getConditionMax()) {
			candidates.push(item);
		}
	}

	if (candidates.len() == 0)
		return null;

	local worst = candidates[0];
	local worstGap = worst.getConditionMax() - worst.getCondition();
	foreach ( item in candidates ) {
		local gap = item.getConditionMax() - item.getCondition();
		if (gap > worstGap) {
			worstGap = gap;
			worst = item;
		}
	}
	return worst;
}

::GolarionEnchant.repairMostDamaged <- function () {
	local worst = ::GolarionEnchant.findMostDamaged();
	if (worst == null)
		return null;
	worst.setCondition(worst.getConditionMax());
	return worst;
}

::GolarionEnchant.installOn <- function ( o )
{
	o.getEnchant <- function () {
		return this.getFlags().getAsInt("GolarionEnchant");
	}

	o.isMasterwork <- function () {
		return this.getFlags().getAsInt("GolarionMasterwork") != 0;
	}

	o.setEnchant <- function ( _v ) {
		this.getFlags().set("GolarionEnchant", _v);
		this.refreshEnchantSkill();
	}

	o.setMasterwork <- function ( _v ) {
		this.getFlags().set("GolarionMasterwork", _v ? 1 : 0);
		this.refreshEnchantSkill();
	}

	o.getEnchantAccuracy <- function () {
		local n = this.getEnchant();
		if (n > 0)
			return ::GolarionEnchant.AccuracyPointsPerTier * n;
		if (this.isMasterwork())
			return ::GolarionEnchant.MasterworkAccuracy;
		return 0;
	}

	o.getEnchantDamageBonus <- function ( _baseMin = null, _baseMax = null ) {
		local n = this.getEnchant();
		if (n <= 0)
			return [0, 0];

		local floorPoints = n * ::GolarionEnchant.MinDamagePerTier;
		if (_baseMin == null || _baseMin <= 0)
			return [floorPoints, floorPoints];

		local pct = ::GolarionEnchant.DamagePercentPerTier * n * 0.01;
		local addMin = this.Math.round(_baseMin * pct);
		local addMax = this.Math.round(_baseMax * pct);
		if (addMin < floorPoints) addMin = floorPoints;
		if (addMax < floorPoints) addMax = floorPoints;
		return [addMin, addMax];
	}

	o.refreshEnchantSkill <- function () {
		if (this.getContainer() == null || this.getContainer().getActor() == null)
			return;
		if (this.m.CurrentSlotType == ::Const.ItemSlot.None)
			return;
		if (this.getEnchantAccuracy() != 0 || this.getEnchant() != 0)
			this.addSkill(this.new("scripts/skills/effects/golarion_enchant_effect"));
	}

	if ("getName" in o)
	{
		local getName = o.getName;
		o.getName = function () {
			local plain = getName();
			local n = this.getEnchant();
			if (n > 0) return "+" + n + " " + plain;
			if (this.isMasterwork()) return "Masterwork " + plain;
			return plain;
		}
	}
	else
	{
		o.getName <- function () {
			local plain = this.item.getName();
			local n = this.getEnchant();
			if (n > 0) return "+" + n + " " + plain;
			if (this.isMasterwork()) return "Masterwork " + plain;
			return plain;
		}
	}

	if ("getValue" in o)
	{
		local getValue = o.getValue;
		o.getValue = function () {
			local v = getValue() * 1.0;
			local n = this.getEnchant();
			if (n > 0) return this.Math.round(v * (1.0 + ::GolarionEnchant.ValueQuadraticFactor * n * n));
			if (this.isMasterwork()) return this.Math.round(v * ::GolarionEnchant.MasterworkValueMult);
			return getValue();
		}
	}
	else
	{
		o.getValue <- function () {
			local v = this.item.getValue() * 1.0;
			local n = this.getEnchant();
			if (n > 0) return this.Math.round(v * (1.0 + ::GolarionEnchant.ValueQuadraticFactor * n * n));
			if (this.isMasterwork()) return this.Math.round(v * ::GolarionEnchant.MasterworkValueMult);
			return this.item.getValue();
		}
	}

	if ("onEquip" in o)
	{
		local onEquip = o.onEquip;
		o.onEquip = function () {
			onEquip();
			if (this.getEnchantAccuracy() != 0 || this.getEnchant() != 0)
				this.addSkill(this.new("scripts/skills/effects/golarion_enchant_effect"));
		}
	}
	else
	{
		o.onEquip <- function () {
			this.item.onEquip();
			if (this.getEnchantAccuracy() != 0 || this.getEnchant() != 0)
				this.addSkill(this.new("scripts/skills/effects/golarion_enchant_effect"));
		}
	}

	::GolarionEnchant.beginTooltip <- function ( _item ) {
		if (_item.getEnchant() <= 0)
			return null;
		if (!("RegularDamage" in _item.m) || _item.m.RegularDamage <= 0)
			return null;

		local saved = [_item.m.RegularDamage, _item.m.RegularDamageMax];
		local add = _item.getEnchantDamageBonus(saved[0], saved[1]);
		_item.m.RegularDamage = saved[0] + add[0];
		_item.m.RegularDamageMax = saved[1] + add[1];
		return saved;
	}

	::GolarionEnchant.endTooltip <- function ( _item, _saved ) {
		if (_saved == null)
			return;
		_item.m.RegularDamage = _saved[0];
		_item.m.RegularDamageMax = _saved[1];
	}

	::GolarionEnchant.decorateTooltip <- function ( _item, _result ) {
		local n = _item.getEnchant();
		local acc = _item.getEnchantAccuracy();
		if (n == 0 && acc == 0)
			return _result;

		local summary = n > 0 ? "Enhancement +" + n : "Masterwork";
		summary += ":";

		if (n > 0)
		{
			local pts = ("RegularDamage" in _item.m) && _item.m.RegularDamage > 0
				? _item.getEnchantDamageBonus(_item.m.RegularDamage, _item.m.RegularDamageMax)
				: _item.getEnchantDamageBonus();

			if (pts[0] == pts[1])
				summary += " [color=" + ::Const.UI.Color.PositiveValue + "]+"
					+ pts[0] + "[/color] damage";
			else
				summary += " [color=" + ::Const.UI.Color.PositiveValue + "]+" + pts[0]
					+ "[/color] - [color=" + ::Const.UI.Color.PositiveValue + "]+"
					+ pts[1] + "[/color] damage";
		}
		if (n > 0 && acc != 0)
			summary += ",";
		if (acc != 0)
			summary += " [color=" + ::Const.UI.Color.PositiveValue + "]+"
				+ acc + "[/color] chance to hit";

		_result.push({ id = 70, type = "text", icon = "ui/icons/special.png", text = summary });
		return _result;
	}

	if ("getTooltip" in o)
	{
		local getTooltip = o.getTooltip;
		o.getTooltip = function () {
			local saved = ::GolarionEnchant.beginTooltip(this);
			local result;
			try
			{
				result = getTooltip();
			}
			catch (e)
			{
				::GolarionEnchant.endTooltip(this, saved);
				throw e;
			}
			::GolarionEnchant.endTooltip(this, saved);
			return ::GolarionEnchant.decorateTooltip(this, result);
		}
	}
	else
	{
		o.getTooltip <- function () {
			local saved = ::GolarionEnchant.beginTooltip(this);
			local result;
			try
			{
				result = this.item.getTooltip();
			}
			catch (e)
			{
				::GolarionEnchant.endTooltip(this, saved);
				throw e;
			}
			::GolarionEnchant.endTooltip(this, saved);
			return ::GolarionEnchant.decorateTooltip(this, result);
		}
	}
};
