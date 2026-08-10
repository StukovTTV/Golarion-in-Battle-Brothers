this.skv_kobold_skirmisher_agent <- this.inherit("scripts/ai/tactical/agents/goblin_ranged_agent", {
	m = {},

	function create()
	{

		this.goblin_ranged_agent.create();
		this.m.ID = this.Const.AI.Agent.ID.SkvKoboldSkirmisher;
	}

	function onAddBehaviors()
	{
		this.goblin_ranged_agent.onAddBehaviors();
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_throw_net"));
	}

});
