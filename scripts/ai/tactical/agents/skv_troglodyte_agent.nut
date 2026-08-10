this.skv_troglodyte_agent <- this.inherit("scripts/ai/tactical/agent", {
	m = {},

	function create()
	{
		this.agent.create();
		this.m.ID = ::Const.AI.Agent.ID.SkvTroglodyte;

		this.m.Properties.OverallDefensivenessMult = 0.4;
		this.m.Properties.EngageWhenAlreadyEngagedMult = 0.8;
		this.m.Properties.EngageTargetAlreadyBeingEngagedMult = 2.0;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.SwitchToRanged] = 0.25;

		this.m.Properties.BehaviorMult[::Const.AI.Behavior.ID.AttackBow] = 1.5;

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
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_reap"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_split"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_puncture"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_attack_decapitate"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_defend"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_defend_knock_back"));
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_wake_up_ally"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_warcry"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_root"));

		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_rally"));
	}

	function onUpdate()
	{

		this.setEngageRangeBasedOnWeapon();

		try
		{

			local main = this.m.Actor.getItems().getItemAtSlot(this.Const.ItemSlot.Mainhand);

			if (main != null && main.isItemType(this.Const.Items.ItemType.RangedWeapon))
			{
				this.m.Properties.EngageRangeMin   = 1;
				this.m.Properties.EngageRangeMax   = 1;
				this.m.Properties.EngageRangeIdeal = 1;
			}
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: could not clamp engage range (it may hang back and throw): " + e);
		}
	}

});
