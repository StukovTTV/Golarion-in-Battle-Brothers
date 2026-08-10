this.skv_kobold_blade <- this.inherit("scripts/entity/tactical/enemies/goblin_fighter", {
	m = {},

	function create()
	{
		this.goblin_fighter.create();
		this.m.Type = ::Const.EntityType.SkvKoboldBlade;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.goblin_fighter.onInit();

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

		local blades = [
			"weapons/greenskins/goblin_falchion",
			"weapons/scramasax",
			"weapons/fencing_sword"
		];
		this.m.Items.equip(this.new("scripts/items/" + blades[this.Math.rand(0, blades.len() - 1)]));

		if (this.m.Items.hasEmptySlot(this.Const.ItemSlot.Offhand) && this.Math.rand(1, 100) <= 40)
		{
			this.m.Items.equip(this.new("scripts/items/tools/throwing_net"));
		}

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_heavy_armor]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		local helmet = this.Const.World.Common.pickHelmet([
			[1, ::Legends.Helmet.Greenskin.goblin_heavy_helmet]
		]);
		if (helmet != null)
		{
			this.m.Items.equip(helmet);
		}
	}

});
