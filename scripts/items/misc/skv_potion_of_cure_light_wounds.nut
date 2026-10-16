this.skv_potion_of_cure_light_wounds <- this.inherit("scripts/items/accessory/accessory", {

	m = {
		HealMin = 8,
		HealMax = 14
	},

	function create()
	{
		this.accessory.create();

		this.m.ID = "misc.skv_potion_of_cure_light_wounds";
		this.m.Name = "Potion of Cure Light Wounds";

		this.m.Description = "A slender glass vial, its cork sealed over with wax, and most of a finger's depth of something red left in the bottom of it. It has sat in the dark long enough that nobody can say who brewed it, or what the mark pressed into the wax once meant. Whatever is left in it will close a cut and take the ache out of a man. It will not give him his week back.";

		this.m.Icon = "misc/skv_potion_cure_light_vial.png";

		this.m.SlotType = ::Const.ItemSlot.Bag;

		this.m.ItemType = ::Const.Items.ItemType.Accessory;
		this.m.IsUsable = true;
		this.m.IsAllowedInBag = true;

		this.m.IsChangeableInBattle = true;
		this.m.IsDroppedAsLoot = true;
		this.m.ShowOnCharacter = false;

		this.m.Value = 150;
	}

	function getHealMin()
	{
		return this.m.HealMin;
	}

	function getHealMax()
	{
		return this.m.HealMax;
	}

	function playInventorySound( _eventType )
	{
		this.Sound.play("sounds/bottle_01.wav", ::Const.Sound.Volume.Inventory);
	}

	function getTooltip()
	{
		local result = this.accessory.getTooltip();
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/health.png",
			text = "Heals [color=" + ::Const.UI.Color.PositiveValue + "]" + this.m.HealMin + "[/color] - [color=" + ::Const.UI.Color.PositiveValue + "]" + this.m.HealMax + "[/color] hitpoints"
		});
		result.push({
			id = 21,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Can be drunk in battle by whoever carries it, or given to the man beside him"
		});
		result.push({
			id = 22,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Right-click or drag onto a character to use it up"
		});
		return result;
	}

	function onEquip()
	{
		this.accessory.onEquip();
		this.addSkill(this.new("scripts/skills/actives/skv_drink_healing_potion_skill"));
		::Skv.dbg("Skv.potion: drink skill attached");
	}

	function onPutIntoBag()
	{
		this.onEquip();
	}

	function onUse( _actor, _item = null )
	{
		if (_actor == null)
		{
			return false;
		}

		local max = null;
		try { max = _actor.getHitpointsMax(); }
		catch (e) { return false; }

		local now = _actor.getHitpoints();
		if (now >= max)
		{

			return false;
		}

		this.Sound.play("sounds/bottle_01.wav", ::Const.Sound.Volume.Inventory);
		_actor.setHitpoints(::Math.min(max, now + ::Math.rand(this.m.HealMin, this.m.HealMax)));
		return true;
	}

});
