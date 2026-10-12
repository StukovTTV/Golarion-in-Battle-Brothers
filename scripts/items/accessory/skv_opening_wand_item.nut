this.skv_opening_wand_item <- this.inherit("scripts/items/accessory/accessory", {
	m = {
		Charges = 11,
		ChargesMax = 11
	},

	function create()
	{
		this.accessory.create();

		this.m.ID = "accessory.skv_opening_wand";
		this.m.Name = "Wand of Opening";
		this.m.Description = "A short rod of dark wood banded in brass, warm to the touch. Pressed to a lock and spoken to, it makes the lock forget it was ever shut. Every use leaves it a little lighter, and one day there will be nothing left of it.";

		this.m.SlotType = ::Const.ItemSlot.Bag;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;
		this.m.Icon = "misc/skv_opening_wand.png";

		this.m.Value = 600;
		this.m.IsDroppedAsLoot = true;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.ShowOnCharacter = false;

	}

	function getCharges()
	{
		return this.m.Charges;
	}

	function spendCharge()
	{
		this.m.Charges = ::Math.max(0, this.m.Charges - 1);
		return this.m.Charges;
	}

	function isAmountShown()
	{
		return true;
	}

	function getAmount()
	{
		return this.m.Charges;
	}

	function getAmountMax()
	{
		return this.m.ChargesMax;
	}

	function getAmountString()
	{
		return this.m.Charges + "/" + this.m.ChargesMax;
	}

	function onEquip()
	{
		this.accessory.onEquip();

		try
		{
			this.addSkill(this.new("scripts/skills/effects/skv_opening_wand_effect"));
		}
		catch (e)
		{
			::logError("Skv.Wand: the carrier did not get the lockpick marker; the wand gives no bonus: " + e);
		}
	}

	function onPutIntoBag()
	{
		this.onEquip();
	}

	function getTooltip()
	{

		local result = this.item.getTooltip();
		result.push({
			id = 64,
			type = "text",
			text = "Carried in Bag"
		});
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/special.png",
			text = "[color=" + ::Const.UI.Color.PositiveValue + "]+20[/color] to the chance to open a lock for the one who carries it"
		});
		result.push({
			id = 21,
			type = "text",
			icon = "ui/icons/special.png",
			text = this.m.Charges + " of " + this.m.ChargesMax + " charges left. Each lock it is used on spends one, and it crumbles when the last is gone."
		});
		return result;
	}

	function onSerialize( _out )
	{
		this.accessory.onSerialize(_out);
		_out.writeU16(this.m.Charges);
	}

	function onDeserialize( _in )
	{
		this.accessory.onDeserialize(_in);
		this.m.Charges = _in.readU16();
	}

});
