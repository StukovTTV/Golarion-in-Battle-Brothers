this.skv_kobold_master_trapper <- this.inherit("scripts/entity/tactical/enemies/goblin_ambusher", {
	m = {},

	function create()
	{
		this.goblin_ambusher.create();
		this.m.Type = ::Const.EntityType.SkvKoboldMasterTrapper;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_skirmisher_agent");
		this.m.AIAgent.setActor(this);

		this.m.OnDeathLootTable.push([1.0, "scripts/items/misc/legend_masterwork_tools"]);
	}

	function onInit()
	{
		this.goblin_ambusher.onInit();

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
			"weapons/dagger",
			"weapons/shortsword"
		];
		this.m.Items.equip(this.new("scripts/items/" + blades[this.Math.rand(0, blades.len() - 1)]));
		this.m.Items.equip(this.new("scripts/items/tools/reinforced_throwing_net"));
		this.m.Items.equip(this.new("scripts/items/ammo/quiver_of_arrows"));
		this.m.Items.addToBag(this.new("scripts/items/weapons/short_bow"));
		this.m.Items.addToBag(this.new("scripts/items/accessory/poison_item"));

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_medium_armor]
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
