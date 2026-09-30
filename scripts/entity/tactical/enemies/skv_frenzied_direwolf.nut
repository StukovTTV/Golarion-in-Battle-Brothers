this.skv_frenzied_direwolf <- this.inherit("scripts/entity/tactical/enemies/direwolf_high", {
	m = {},
	function getName()
	{
		if (this.m.Name == "") return this.direwolf_high.getName();
		return this.m.Name;
	}

	function create()
	{
		this.direwolf_high.create();
	}
});
