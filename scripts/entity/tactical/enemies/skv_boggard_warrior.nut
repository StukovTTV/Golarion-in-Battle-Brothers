this.skv_boggard_warrior <- this.inherit("scripts/entity/tactical/enemies/skv_boggard", {
	m = {},

	function create()
	{
		this.m.SkvStats = ::Const.Tactical.Actor.SkvBoggardWarrior;
		this.m.SkvKind = "Warrior";
		this.skv_boggard.create();
		this.m.Type = ::Const.EntityType.SkvBoggardWarrior;

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_boggard_warrior_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.skv_boggard.onInit();

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/skv_boggard_croak"));
			this.m.Skills.add(this.new("scripts/skills/actives/skv_boggard_tongue"));
		}
		catch (e)
		{
			::logError("Skv.Boggard.Warrior: could not take croak/tongue - it still fights: " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{

		this.m.Items.equip(this.new("scripts/items/weapons/bludgeon"));
		this.m.Items.addToBag(this.new("scripts/items/weapons/javelin"));
	}

});
