this.skv_kobold_guilecaster <- this.inherit("scripts/entity/tactical/enemies/legend_goblin_witch_doctor", {
	m = {},

	function create()
	{
		this.legend_goblin_witch_doctor.create();
		this.m.Type = ::Const.EntityType.SkvKoboldGuilecaster;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_caster_agent");
		this.m.AIAgent.setActor(this);

		this.m.OnDeathLootTable.push([1.0, "scripts/items/misc/legend_masterwork_tools"]);
	}

	function onInit()
	{
		this.legend_goblin_witch_doctor.onInit();

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

		try { ::Legends.Actives.remove(this, ::Legends.Active.Insects); } catch (e) {}
		try { ::Legends.Actives.remove(this, ::Legends.Active.GrantNightVision); } catch (e) {}

		::Legends.Actives.grant(this, ::Legends.Active.LegendMagicMissile);
		::Legends.Actives.grant(this, ::Legends.Active.MirrorImage);

		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

	function assignRandomEquipment()
	{

		local staves = [
			"weapons/legend_staff",
			"weapons/greenskins/goblin_staff"
		];
		this.m.Items.equip(this.new("scripts/items/" + staves[this.Math.rand(0, staves.len() - 1)]));

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_shaman_armor]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		local helmet = this.Const.World.Common.pickHelmet([
			[1, ::Legends.Helmet.Greenskin.goblin_shaman_helmet]
		]);
		if (helmet != null)
		{
			this.m.Items.equip(helmet);
		}
	}

});
