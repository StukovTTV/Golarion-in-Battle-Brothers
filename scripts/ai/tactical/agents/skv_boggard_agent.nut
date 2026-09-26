this.skv_boggard_agent <- this.inherit("scripts/ai/tactical/agent", {
	m = {},

	function create()
	{
		this.agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvBoggard;

		this.m.Properties.OverallDefensivenessMult = 0.4;
		this.m.Properties.OverallFormationMult = 0.75;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.KnockBack] = 3.0;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.Terror] = 1.25;

		this.m.Properties.TargetPriorityFleeingMult = 1.5;
		this.m.Properties.TargetPriorityMoraleMult = 1.5;
	}

	function onAddBehaviors()
	{
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_flee"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_retreat"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_break_free"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_engage_melee"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_bow"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_switchto_melee"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_switchto_ranged"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_default"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_swing"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_terror"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_defend_knock_back"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_defend"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_wake_up_ally"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_rally"));
	}

	function onUpdate()
	{
		this.setEngageRangeBasedOnWeapon();
	}

});
