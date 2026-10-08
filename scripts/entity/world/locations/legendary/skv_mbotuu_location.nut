this.skv_mbotuu_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	function getDescription()
	{
		return "Huts of reed and hide hang from dead trees above the black water. Smoke rises, something croaks, and small shapes scatter into the reeds. This is no war camp. It is where the frog-folk live.";
	}

	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_mbotuu";
		this.m.LocationType = this.Const.World.LocationType.Unique;
		this.m.IsShowingDefenders = true;
		this.m.IsShowingBanner = false;
		this.m.IsAttackable = true;
		this.m.VisibilityMult = 0.9;
		this.m.OnDestroyed = "event.location.skv_mbotuu_destroyed";
	}

	function onSpawned()
	{
		this.m.Name = ::Skv.Mbotuu.Name;
		this.location.onSpawned();
	}

	function onCombatLost()
	{
		try
		{
			::Skv.Mbotuu.claim();
		}
		catch (e)
		{
			::logError("Skv.Mbotuu: paying for the village threw; it falls anyway: " + e);
		}

		return this.location.onCombatLost();
	}

	function onInit()
	{
		this.location.onInit();
		local body = this.addSprite("body");

		body.setBrush("skv_world_mbotuu");
	}
});
