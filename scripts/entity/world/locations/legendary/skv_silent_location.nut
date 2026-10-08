this.skv_silent_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	function getDescription()
	{
		return "A glacier fills the valley from wall to wall. Where the ice has worn thin there are shapes in it, standing upright.";
	}

	function create()
	{
		this.location.create();
		this.m.TypeID = "location.skv_silent";
		this.m.LocationType = this.Const.World.LocationType.Unique;
		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;

		this.m.IsShowingStrength = false;
		this.m.IsAttackable = false;
		this.m.IsDestructible = false;
		this.m.VisibilityMult = 0.9;
		this.m.OnEnter = "event.location.skv_silent_enter";
	}

	function onSpawned()
	{
		this.m.Name = ::Skv.Silent.Name;
		this.location.onSpawned();
	}

	function onEnter()
	{
		if (this.isDiscovered() && this.m.OnEnter != null)
		{
			try
			{
				::Skv.Silent.prepare(this);
			}
			catch (e)
			{
				::logError("Skv.Silent: prepare() threw on entering the site; the screen shows anyway: " + e);
			}

			if (!this.World.Events.fire(this.m.OnEnter))
			{
				::logError("Skv.Silent: the site's screen did not open (another event queued, or the event is missing).");
			}

			return false;
		}

		return this.location.onEnter();
	}

	function onInit()
	{
		this.location.onInit();
		local body = this.addSprite("body");

		body.setBrush("skv_world_silent");
	}
});
