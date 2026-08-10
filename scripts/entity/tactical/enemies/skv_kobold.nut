this.skv_kobold <- this.inherit("scripts/entity/tactical/enemies/goblin_fighter_low", {
	m = {

		SkvSpear = false
	},

	function create()
	{
		this.goblin_fighter_low.create();
		this.m.Type = ::Const.EntityType.SkvKobold;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.SkvSpear = this.Math.rand(1, 100) <= 40;

		if (!this.m.SkvSpear)
		{

			this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_skirmisher_agent");
			this.m.AIAgent.setActor(this);
		}
	}

	function onInit()
	{
		this.goblin_fighter_low.onInit();

		local s = ::Const.Skv.KoboldScale;
		local b = this.m.BaseProperties;

		b.Hitpoints   = ::Math.max(1, ::Math.floor(b.Hitpoints * s.HealthMult));
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
		if (this.m.SkvSpear)
		{

			if (this.Math.rand(1, 100) <= 25)
			{
				this.m.Items.equip(this.new("scripts/items/weapons/greenskins/goblin_spear"));
			}
			else
			{
				this.m.Items.equip(this.new("scripts/items/weapons/legend_wooden_spear"));
			}

			if (this.m.Items.hasEmptySlot(this.Const.ItemSlot.Offhand) && this.Math.rand(1, 100) <= 40)
			{
				this.m.Items.equip(this.new("scripts/items/tools/throwing_net"));
			}
		}
		else
		{
			this.m.Items.equip(this.new("scripts/items/weapons/legend_dilapitated_sling"));
			this.m.Items.addToBag(this.new("scripts/items/weapons/legend_wooden_spear"));
		}

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_skirmisher_armor]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		if (this.Math.rand(1, 100) <= 50)
		{
			local helmet = this.Const.World.Common.pickHelmet([
				[1, ::Legends.Helmet.Greenskin.goblin_light_helmet]
			]);
			if (helmet != null)
			{
				this.m.Items.equip(helmet);
			}
		}
	}

});
