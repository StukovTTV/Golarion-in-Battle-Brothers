this.skv_troglodyte_sorcerer <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteSorcerer;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_troglodyte_caster_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteSorcerer);

		try
		{

			this.m.Skills.add(this.new("scripts/skills/actives/wither_skill"));
			this.m.Skills.update();
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Sorcerer could not take wither (it still fights): " + e);
		}

		foreach( spell in [ ::Legends.Active.LegendRust, ::Legends.Active.LegendHorrify ] )
		{
			try
			{
				::Legends.Actives.grant(this, spell);
			}
			catch (e)
			{
				::logError("Skv.Troglodyte: the Sorcerer could not take one of its spells (it still fights with wither and a club): " + e);
			}
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{
		this.skvArmWith("barbarians/claw_club", 0);
	}

});
