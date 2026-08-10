this.skv_kobold_devilspeaker <- this.inherit("scripts/entity/tactical/enemies/legend_goblin_witch_doctor", {
	m = {},

	function create()
	{
		this.legend_goblin_witch_doctor.create();
		this.m.Type = ::Const.EntityType.SkvKoboldDevilspeaker;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_caster_agent");
		this.m.AIAgent.setActor(this);

		this.m.OnDeathLootTable.push([1.0, "scripts/items/supplies/medicine_item"]);
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

		::Legends.Actives.grant(this, ::Legends.Active.RaiseUndead);
		::Legends.Actives.grant(this, ::Legends.Active.Horror);

		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

	function assignRandomEquipment()
	{

		local arms = [
			"weapons/battle_whip",
			"weapons/legend_staff"
		];
		this.m.Items.equip(this.new("scripts/items/" + arms[this.Math.rand(0, arms.len() - 1)]));

		if (this.m.Items.hasEmptySlot(this.Const.ItemSlot.Offhand))
		{
			this.m.Items.equip(this.new("scripts/items/shields/buckler_shield"));
		}

		this.m.Items.addToBag(this.new("scripts/items/weapons/rondel_dagger"));

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_light_armor]
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
