this.skv_troglodyte_scale_rider <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteScaleRider;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_troglodyte_skirmisher_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteScaleRider);

		try
		{
			::Legends.Perks.grant(this, ::Legends.Perk.LegendPointBlank);
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Scale-Rider could not take Point Blank (it still throws): " + e);
		}

		try
		{
			if (::Legends.isLegendaryDifficulty())
			{
				::Legends.Perks.grant(this, ::Legends.Perk.Bullseye);
			}
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Scale-Rider could not take Bullseye (it still throws): " + e);
		}

		try
		{
			this.m.Skills.add(this.new("scripts/skills/perks/perk_quick_hands"));
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Scale-Rider could not take quick hands (it still fights): " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{
		this.skvArmWith("bludgeon", 15, 100);
	}

});
