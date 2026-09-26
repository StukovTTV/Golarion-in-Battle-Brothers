this.skv_boggard_swampseer <- this.inherit("scripts/entity/tactical/enemies/skv_boggard", {
	m = {},

	function create()
	{
		this.m.SkvStats = ::Const.Tactical.Actor.SkvBoggardSwampseer;
		this.m.SkvKind = "Swampseer";
		this.skv_boggard.create();
		this.m.Type = ::Const.EntityType.SkvBoggardSwampseer;
		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_boggard_caster_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.skv_boggard.onInit();

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/skv_boggard_croak"));
			this.m.Skills.add(this.new("scripts/skills/actives/skv_boggard_tongue"));
		}
		catch (e)
		{
			::logError("Skv.Boggard.Swampseer: could not take croak/tongue - it still fights: " + e);
		}

		try
		{
			::Legends.Actives.grant(this, ::Legends.Active.LegendRust);
		}
		catch (e)
		{
			::logError("Skv.Boggard.Swampseer: NO ACID - it is a frog with a stick: " + e);
		}

		this.m.Skills.update();
		::Skv.dbg("Skv.Boggard.Swampseer: acid=" + this.m.Skills.hasSkill(::Legends.Actives.getID(::Legends.Active.LegendRust)));
	}

	function assignRandomEquipment()
	{
		this.m.Items.equip(this.new("scripts/items/weapons/legend_mystic_staff"));
	}

});
