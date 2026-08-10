this.skv_troglodyte_caster_agent <- this.inherit("scripts/ai/tactical/agents/goblin_shaman_agent", {
	m = {},

	function create()
	{
		this.goblin_shaman_agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvTroglodyteCaster;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.CrushArmor] = 13.0;
	}

	function onAddBehaviors()
	{
		this.goblin_shaman_agent.onAddBehaviors();

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_switchto_melee"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_switchto_ranged"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_bow"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_crush_armor"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_horror"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_rally"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_wither"));
	}

});
