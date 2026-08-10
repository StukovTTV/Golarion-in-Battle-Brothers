this.skv_kobold_scalecaster <- this.inherit("scripts/entity/tactical/enemies/goblin_shaman", {
	m = {},

	function create()
	{
		this.goblin_shaman.create();
		this.m.Type = ::Const.EntityType.SkvKoboldScalecaster;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_caster_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.goblin_shaman.onInit();

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

		::Legends.Actives.grant(this, ::Legends.Active.LegendMagicBurningHands, function ( _skill )
		{
			_skill.m.BaseDamageRegularMin = _skill.m.BaseDamageRegularMin + 1;
			_skill.m.BaseDamageRegularMax = _skill.m.BaseDamageRegularMax + 1;
		});

		::Legends.Actives.grant(this, ::Legends.Active.LegendDaze);

		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

	function assignRandomEquipment()
	{
		this.m.Items.equip(this.new("scripts/items/ammo/quiver_of_bolts"));

		if (this.Math.rand(1, 100) <= 10)
		{
			this.m.Items.equip(this.new("scripts/items/weapons/greenskins/goblin_crossbow"));
		}
		else
		{
			this.m.Items.equip(this.new("scripts/items/weapons/light_crossbow"));
		}

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
