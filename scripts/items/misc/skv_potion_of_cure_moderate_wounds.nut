this.skv_potion_of_cure_moderate_wounds <- this.inherit("scripts/items/misc/skv_potion_of_cure_light_wounds", {
	m = {},

	function create()
	{
		this.skv_potion_of_cure_light_wounds.create();

		this.m.ID = "misc.skv_potion_of_cure_moderate_wounds";
		this.m.Name = "Potion of Cure Moderate Wounds";
		this.m.Description = "A heavier bottle than most, stoppered and sealed, with a priest's mark pressed into the wax that nobody in the company can read. The stuff inside is dark and smells of iron and honey. It will close a deep wound on one man and put him back on his feet. It will not give him his week back either.";
		this.m.HealMin = 16;
		this.m.HealMax = 28;
		this.m.Value = 300;
	}

});
