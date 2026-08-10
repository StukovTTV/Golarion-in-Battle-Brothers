this.skv_troglodyte_skirmisher_agent <- this.inherit("scripts/ai/tactical/agent", {
	m = {},

	function create()
	{
		this.agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvTroglodyteSkirmisher;

		this.m.Properties.IsRangedUnit = true;

		this.m.Properties.OverallDefensivenessMult = 2.0;
		this.m.Properties.OverallFormationMult = 1.5;

		this.m.Properties.TargetPriorityHitchanceMult = 1.0;
		this.m.Properties.TargetPriorityHitpointsMult = 0.5;
		this.m.Properties.TargetPriorityFinishOpponentMult = 2.0;
		this.m.Properties.TargetPriorityRandomMult = 0.0;

		this.m.Properties.TargetPriorityFleeingMult = 1.5;
		this.m.Properties.TargetPriorityMoraleMult = 1.5;
	}

	function onAddBehaviors()
	{
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_flee"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_retreat"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_break_free"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_engage_ranged"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_engage_melee"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_bow"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_switchto_melee"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_switchto_ranged"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_default"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_swing"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_reap"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_split"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_puncture"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_decapitate"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_defend"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_wake_up_ally"));
	}

	function onUpdate()
	{

		this.setEngageRangeBasedOnWeapon();
	}

});
