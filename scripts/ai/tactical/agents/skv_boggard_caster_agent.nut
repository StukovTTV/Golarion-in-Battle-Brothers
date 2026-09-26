this.skv_boggard_caster_agent <- this.inherit("scripts/ai/tactical/agents/skv_boggard_agent", {
	m = {},

	function create()
	{
		this.skv_boggard_agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvBoggardCaster;

		this.m.Properties.OverallDefensivenessMult = 0.7;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.CrushArmor] = 4.0;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.KnockBack] = 0.5;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.Terror] = 2.0;
	}

	function onAddBehaviors()
	{
		this.skv_boggard_agent.onAddBehaviors();
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_crush_armor"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_engage_ranged"));
	}

});
