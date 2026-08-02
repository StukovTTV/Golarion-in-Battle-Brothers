this.skv_cult_champion <- this.inherit("scripts/entity/tactical/humans/cultist", {
	function onInit()
	{
		this.cultist.onInit();

		::Legends.Perks.grant(this, ::Legends.Perk.Captain);
	}

	function assignRandomEquipment()
	{

		this.m.Items.equip(this.new("scripts/items/weapons/three_headed_flail"));

		local armor = ::Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Standard.cultist_leather_robe]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		local helmet = ::Const.World.Common.pickHelmet([
			[1, ::Legends.Helmet.Standard.cultist_hood]
		]);
		if (helmet != null)
		{
			this.m.Items.equip(helmet);
		}
	}

});
