this.skv_troglodyte_chieftain <- this.inherit("scripts/entity/tactical/enemies/skv_troglodyte_base", {
	m = {},

	function create()
	{
		this.skv_troglodyte_base.create();
		this.m.Type = ::Const.EntityType.SkvTroglodyteChieftain;
		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

	}

	function onInit()
	{
		this.ghoul.onInit();
		this.skvBecomeTroglodyte(::Const.Tactical.Actor.SkvTroglodyteChieftain);

		try
		{
			::Legends.Actives.grant(this, ::Legends.Active.LegendMagicBurningHands, function ( _skill )
			{
				_skill.m.AdditionalAccuracy = 20;
			});
		}
		catch (e)
		{
			::logError("Skv.Troglodyte: the Chieftain could not take burning hands (it still charges): " + e);
		}

		this.m.Skills.update();
	}

	function assignRandomEquipment()
	{
		this.skvArmWith("greataxe", 5, 0);
	}

});
