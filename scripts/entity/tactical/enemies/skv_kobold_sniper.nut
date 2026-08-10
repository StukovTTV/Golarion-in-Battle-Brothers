this.skv_kobold_sniper <- this.inherit("scripts/entity/tactical/enemies/goblin_ambusher_low", {
	m = {},

	function create()
	{
		this.goblin_ambusher_low.create();
		this.m.Type = ::Const.EntityType.SkvKoboldSniper;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_skirmisher_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.goblin_ambusher_low.onInit();

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
		this.m.Items.equip(this.new("scripts/items/ammo/quiver_of_bolts"));

		if (this.Math.rand(1, 100) <= 10)
		{
			this.m.Items.equip(this.new("scripts/items/weapons/legend_hand_crossbow"));
		}
		else
		{
			this.m.Items.equip(this.new("scripts/items/weapons/light_crossbow"));
		}
		this.m.Items.addToBag(this.new("scripts/items/weapons/shortsword"));

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_light_armor]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		local helmet = this.Const.World.Common.pickHelmet([
			[1, ::Legends.Helmet.Greenskin.goblin_skirmisher_helmet]
		]);
		if (helmet != null)
		{
			this.m.Items.equip(helmet);
		}
	}

});
