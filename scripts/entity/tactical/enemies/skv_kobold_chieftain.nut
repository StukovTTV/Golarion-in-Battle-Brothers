this.skv_kobold_chieftain <- this.inherit("scripts/entity/tactical/enemies/goblin_leader", {
	m = {},

	function create()
	{
		this.goblin_leader.create();
		this.m.Type = ::Const.EntityType.SkvKoboldChieftain;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.goblin_leader.onInit();

		local s = ::Const.Skv.KoboldScale;
		local b = this.m.BaseProperties;

		b.Hitpoints   = ::Math.max(1, ::Math.floor(b.Hitpoints * s.CasterHealthMult));
		b.MeleeSkill  = b.MeleeSkill + s.MeleeSkill;
		b.RangedSkill = b.RangedSkill + s.RangedSkill;
		b.Bravery     = b.Bravery + s.Resolve;

		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		this.m.Skills.add(this.new("scripts/skills/racial/skv_light_sensitivity"));
		this.m.Skills.update();

		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

	function assignRandomEquipment()
	{

		if (this.m.Items.getItemAtSlot(this.Const.ItemSlot.Mainhand) == null)
		{
			local arms = [
				"weapons/fencing_sword",
				"weapons/greenskins/goblin_pike",
				"weapons/barbarians/skull_hammer"
			];
			this.m.Items.equip(this.new("scripts/items/" + arms[this.Math.rand(0, arms.len() - 1)]));
		}

		if (this.m.Items.hasEmptySlot(this.Const.ItemSlot.Offhand))
		{
			this.m.Items.equip(this.new("scripts/items/shields/wooden_shield"));
		}

		if (this.m.Items.getItemAtSlot(this.Const.ItemSlot.Body) == null)
		{
			local armor = this.Const.World.Common.pickArmor([
				[1, ::Legends.Armor.Greenskin.goblin_leader_armor]
			]);
			if (armor != null)
			{
				this.m.Items.equip(armor);
			}
		}

		if (this.m.Items.getItemAtSlot(this.Const.ItemSlot.Head) == null)
		{
			local helmet = this.Const.World.Common.pickHelmet([
				[1, ::Legends.Helmet.Greenskin.goblin_leader_helmet]
			]);
			if (helmet != null)
			{
				this.m.Items.equip(helmet);
			}
		}
	}

	function makeMiniboss()
	{
		if (!this.goblin_leader.makeMiniboss())
		{
			return false;
		}

		local items = this.getItems();
		foreach (slot in [this.Const.ItemSlot.Mainhand, this.Const.ItemSlot.Offhand])
		{
			local it = items.getItemAtSlot(slot);
			if (it != null && it.isItemType(this.Const.Items.ItemType.Named))
			{
				items.unequip(it);
				items.removeFromBag(it);
			}
		}

		this.assignRandomEquipment();
		return true;
	}

});
