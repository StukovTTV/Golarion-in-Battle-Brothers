this.skv_ceustodaemon_agent <- this.inherit("scripts/ai/tactical/agents/ghoul_agent", {
	m = {},

	function create()
	{
		this.ghoul_agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvCeustodaemon;
		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.SwallowWhole] = 0.0;
		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.Sleep] = 1.25;
	}

	function onAddBehaviors()
	{
		this.ghoul_agent.onAddBehaviors();
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_bow"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_sleep"));
	}

	function onUpdate()
	{
		this.ghoul_agent.onUpdate();

		if (this.Time.getRound() > 1)
		{
			this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.EngageMelee] = 1.0;
			this.m.Properties.PreferWait = false;
		}
	}

});
