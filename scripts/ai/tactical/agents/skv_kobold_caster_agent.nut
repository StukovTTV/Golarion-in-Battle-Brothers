this.skv_kobold_caster_agent <- this.inherit("scripts/ai/tactical/agents/goblin_shaman_agent", {
	m = {},

	function create()
	{
		this.goblin_shaman_agent.create();
		this.m.ID = this.Const.AI.Agent.ID.SkvKoboldCaster;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.AttackBow] = 2.0;
	}

	function onAddBehaviors()
	{
		this.goblin_shaman_agent.onAddBehaviors();
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_bow"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_mirror_image"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_raise_undead"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_horror"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_throw_net"));
	}

});
