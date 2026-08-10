this.skv_troglodyte_tyrant <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteTyrant;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteTyrant);

		try
		{
			local racial = this.m.Skills.getSkillByID(::Skv.Stench.RacialID);

			if (racial == null)
			{
				::logError("Skv.Troglodyte: the Tyrant has no stench racial to amplify -- she smells normally.");
			}
			else
			{

				racial.amplify();

				::logInfo("Skv.Troglodyte: the Tyrant's stench is amplified -- Melee and Ranged -"
					+ ::Const.Skv.StenchMeleeSkillAmplified + ", " + ::Const.Skv.StenchFatigueAmplified + " fatigue.");
			}
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: could not amplify the Tyrant's stench (she smells normally): " + e);
		}

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/root_skill"));
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Tyrant could not take hold person (she still fights): " + e);
		}

		try
		{
			::Legends.Actives.grant(this, ::Legends.Active.LegendPrayerOfFaith);
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Tyrant could not take bless (she still roots and swings): " + e);
		}

		try
		{
			this.m.Skills.add(this.new("scripts/skills/perks/perk_quick_hands"));
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Tyrant could not take quick draw (she still fights): " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{
		this.skvArmWith("fighting_axe", 6, 0);
	}

});
