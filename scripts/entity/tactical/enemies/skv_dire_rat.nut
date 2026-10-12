this.skv_dire_rat <- this.inherit("scripts/entity/tactical/enemies/skv_giant_rat", {
	m = {},

	function create()
	{
		this.m.SkvStats = ::Const.Tactical.Actor.SkvDireRat;
		this.m.SkvDire = true;
		this.m.SkvCorpseName = "A Dire Rat";
		this.skv_giant_rat.create();
		this.m.Type = ::Const.EntityType.SkvDireRat;
		this.m.XP = this.m.SkvStats.XP;
	}

});
