this.skv_boggard_warrior_agent <- this.inherit("scripts/ai/tactical/agents/skv_boggard_agent", {
	m = {},

	function create()
	{
		this.skv_boggard_agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvBoggardWarrior;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.SwitchToRanged] = 0.2;
	}

	function onUpdate()
	{
		this.m.Properties.EngageRangeMin = 1;
		this.m.Properties.EngageRangeMax = 1;
		this.m.Properties.EngageRangeIdeal = 1;
	}

});
