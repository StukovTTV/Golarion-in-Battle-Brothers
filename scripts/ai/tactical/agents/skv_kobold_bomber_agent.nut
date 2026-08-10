this.skv_kobold_bomber_agent <- this.inherit("scripts/ai/tactical/agents/goblin_melee_agent", {
	m = {},

	function create()
	{
		this.goblin_melee_agent.create();
		this.m.ID = this.Const.AI.Agent.ID.SkvKoboldBomber;
	}

	function onAddBehaviors()
	{
		this.goblin_melee_agent.onAddBehaviors();

		local bomb = this.new("scripts/ai/tactical/behaviors/ai_throw_bomb");
		bomb.m.BombsMax = 1;
		bomb.m.IsDazeBombAvailable = false;
		this.addBehavior(bomb);

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_engage_ranged"));
	}

	function onUpdate()
	{
		this.goblin_melee_agent.onUpdate();

		local actor = this.m.Actor;

		if (actor == null)
		{
			return;
		}

		local pot = actor.getSkills().getSkillByID("actives.throw_fire_bomb");

		if (pot == null || !pot.isUsable())
		{
			return;
		}

		local vision = actor.getCurrentProperties().getVision();
		this.m.Properties.EngageRangeMin   = this.Math.min(2, vision);
		this.m.Properties.EngageRangeMax   = this.Math.min(pot.getMaxRange(), vision);
		this.m.Properties.EngageRangeIdeal = this.Math.min(pot.getMaxRange(), vision);
	}

});
