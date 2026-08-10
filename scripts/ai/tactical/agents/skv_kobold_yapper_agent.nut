this.skv_kobold_yapper_agent <- this.inherit("scripts/ai/tactical/agents/goblin_ranged_agent", {
	m = {},

	function create()
	{
		this.goblin_ranged_agent.create();
		this.m.ID = this.Const.AI.Agent.ID.SkvKoboldYapper;
	}

	function onAddBehaviors()
	{
		this.goblin_ranged_agent.onAddBehaviors();
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_rally"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_terror"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_mirror_image"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_sleep"));
	}

});
