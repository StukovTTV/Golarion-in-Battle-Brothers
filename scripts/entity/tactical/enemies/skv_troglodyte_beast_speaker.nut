this.skv_troglodyte_beast_speaker <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteBeastSpeaker;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_troglodyte_caster_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteBeastSpeaker);

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/root_skill"));
			this.m.Skills.add(this.new("scripts/skills/actives/insects_skill"));
			this.m.Skills.update();
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Beast-Speaker could not take its spells (it still fights): " + e);
		}
	}

	function assignRandomEquipment()
	{
		this.skvArmWith("barbarians/claw_club", 3, 40);
	}

});
