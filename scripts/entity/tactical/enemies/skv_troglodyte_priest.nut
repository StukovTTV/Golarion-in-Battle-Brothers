this.skv_troglodyte_priest <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodytePriest;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodytePriest);

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/root_skill"));
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Priest could not take hold person (it still fights): " + e);
		}

		try
		{
			::Legends.Actives.grant(this, ::Legends.Active.LegendPrayerOfFaith);
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Priest could not take Prayer of Faith (it still roots and punches): " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{
		this.skvArmWith("barbarians/claw_club", 3, 55);
	}

});
