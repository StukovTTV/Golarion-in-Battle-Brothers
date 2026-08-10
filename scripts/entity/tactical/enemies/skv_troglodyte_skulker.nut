this.skv_troglodyte_skulker <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteSkulker;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteSkulker);

		try
		{
			::Legends.Perks.grant(this, ::Legends.Perk.LegendBlendIn);
			this.m.Skills.update();
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Skulker could not take Blend In (it still fights): " + e);
		}
	}

	function assignRandomEquipment()
	{

		local clubs = ["bludgeon", "barbarians/claw_club"];
		this.skvArmWith(clubs[this.Math.rand(0, clubs.len() - 1)], 4, 80);

	}

});
