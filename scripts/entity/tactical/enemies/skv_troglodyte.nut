this.skv_troglodyte <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyte;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];
	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyte);
	}

	function assignRandomEquipment()
	{

		local clubs = ["wooden_stick", "bludgeon"];
		this.skvArmWith(clubs[this.Math.rand(0, clubs.len() - 1)], 3, 65);
	}

});
