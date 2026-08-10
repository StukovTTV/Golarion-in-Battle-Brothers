this.skv_troglodyte_warren_guard <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteWarrenGuard;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteWarrenGuard, true);

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/warcry"));
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Warren Guard could not take its howl (it still fights): " + e);
		}

		try
		{
			::Legends.Perks.grant(this, ::Legends.Perk.LegendTerrifyingVisage);
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Warren Guard could not take its glare (it still howls): " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{
		this.skvArmWith(null, 0);
	}

});
