this.skv_tatzlwyrm_bite_skill <- this.inherit("scripts/skills/actives/serpent_bite_skill", {
	m = {},

	function create()
	{
		this.serpent_bite_skill.create();
		this.m.Name = "Bite";
		this.m.Description = "Snap at an adjacent target. A tatzlwyrm is a small dragon with a small dragon's jaws - less than a great serpent brings, and quite enough for an unarmoured throat.";
	}

	function onUpdate( _properties )
	{
		this.serpent_bite_skill.onUpdate(_properties);

		_properties.DamageRegularMin -= 17;
		_properties.DamageRegularMax -= 24;
	}

});
