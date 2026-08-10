this.skv_troglodyte_champion <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteChampion;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteChampion);

		try
		{
			if (::Legends.isLegendaryDifficulty())
			{
				::Legends.Perks.grant(this, ::Legends.Perk.LegendThrustMaster);
			}
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Champion could not take weapon training (it still fights): " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{

		local roll = this.Math.rand(1, 100);
		local arms = roll <= 50 ? "greenskins/goblin_pike"
		           : roll <= 85 ? "pike"
		           :              "spetum";

		this.skvArmWith(arms, 7, 50);
	}

});
