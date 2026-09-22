this.skv_daemon_sleep <- this.inherit("scripts/skills/actives/sleep_skill", {
	m = {
		Used = false
	},

	function create()
	{
		this.sleep_skill.create();
		this.m.Description = "A breath of grave-cold stillness. Whoever it catches stops where he stands, and does not move again until someone shakes him or the daemon's teeth do.";
	}

	function isUsable()
	{
		if (this.m.Used) return false;
		return this.skill.isUsable();
	}

	function onUse( _user, _targetTile )
	{
		local ret = this.sleep_skill.onUse(_user, _targetTile);
		this.m.Used = true;
		::Skv.dbg("Skv.Daemon: SLEEP used (once per fight)");
		return ret;
	}

});
