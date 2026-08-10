this.skv_kobold_yapper <- this.inherit("scripts/entity/tactical/enemies/goblin_fighter_low", {
	m = {},

	function create()
	{
		this.goblin_fighter_low.create();
		this.m.Type = ::Const.EntityType.SkvKoboldYapper;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_kobold_yapper_agent");
		this.m.AIAgent.setActor(this);
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

		::Legends.Actives.grant(this, ::Legends.Active.RallyTheTroops);
		::Legends.Actives.grant(this, ::Legends.Active.HorrificScream);
		::Legends.Actives.grant(this, ::Legends.Active.MirrorImage);
		::Legends.Actives.grant(this, ::Legends.Active.Sleep);

		local tint = null;
		try { tint = this.createColor(::Const.Skv.KoboldTint); } catch (e) {}
		::Const.Skv.dressKobold(this, tint);
	}

	function assignRandomEquipment()
	{
		this.m.Items.equip(this.new("scripts/items/ammo/quiver_of_arrows"));

		local bows = [
			"weapons/greenskins/goblin_bow",
			"weapons/short_bow",
			"weapons/hunting_bow"
		];
		this.m.Items.equip(this.new("scripts/items/" + bows[this.Math.rand(0, bows.len() - 1)]));
		this.m.Items.addToBag(this.new("scripts/items/weapons/shortsword"));

		local armor = this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Greenskin.goblin_medium_armor]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		local helmet = this.Const.World.Common.pickHelmet([
			[1, ::Legends.Helmet.Greenskin.goblin_light_helmet]
		]);
		if (helmet != null)
		{
			this.m.Items.equip(helmet);
		}
	}

});
