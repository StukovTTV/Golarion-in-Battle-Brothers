this.skv_daemon_breath <- this.inherit("scripts/skills/actives/legend_magic_burning_hands", {
	m = {
		Cooldown = 0
	},

	function create()
	{
		this.legend_magic_burning_hands.create();
		this.m.AdditionalAccuracy = ::Const.Skv.Fane.BreathAccuracy;
		this.m.Description = "A cone of fire breathed out of a daemon's maw. It needs a few breaths before it can do it again.";
	}

	function isUsable()
	{
		if (this.m.Cooldown > 0) return false;
		return this.legend_magic_burning_hands.isUsable();
	}

	function onUse( _user, _targetTile )
	{
		local ret = this.legend_magic_burning_hands.onUse(_user, _targetTile);
		this.m.Cooldown = ::Const.Skv.Fane.BreathCooldown;
		::Skv.dbg("Skv.Daemon: BREATH used -> cooldown " + this.m.Cooldown);
		return ret;
	}

	function onTurnEnd()
	{
		if (this.m.Cooldown > 0) this.m.Cooldown = this.m.Cooldown - 1;
	}

});
