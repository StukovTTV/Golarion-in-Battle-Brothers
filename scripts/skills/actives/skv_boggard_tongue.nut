this.skv_boggard_tongue <- this.inherit("scripts/skills/actives/serpent_hook_skill", {
	m = {},

	function create()
	{
		this.serpent_hook_skill.create();

		local T = ::Const.Skv.Boggard.Tongue;
		this.m.Name = "Tongue";
		this.m.Description = "A tongue like a wet rope, out and back before the eye follows it. Whoever it finds is not standing where he chose to stand.";
		this.m.ActionPointCost = T.ActionPoints;
		this.m.FatigueCost = T.Fatigue;
		this.m.MaxRange = T.MaxRange;

	}

	function onUse( _user, _targetTile )
	{
		local target = _targetTile.getEntity();
		local pullToTile;

		if (this.m.DestinationTile != null)
		{
			pullToTile = this.m.DestinationTile;
			this.m.DestinationTile = null;
		}
		else
		{
			pullToTile = this.getPulledToTile(_user.getTile(), _targetTile);
		}

		if (pullToTile == null)
		{
			return false;
		}

		if (target.getCurrentProperties().IsImmuneToKnockBackAndGrab)
		{
			return false;
		}

		if (!_user.isHiddenToPlayer() && pullToTile.IsVisibleForPlayer)
		{
			this.Tactical.EventLog.log(this.Const.UI.getColorizedEntityName(_user) + " drags in " + this.Const.UI.getColorizedEntityName(target));
		}

		local skills = target.getSkills();
		skills.removeByID("effects.shieldwall");
		skills.removeByID("effects.spearwall");
		skills.removeByID("effects.riposte");
		this.Tactical.State.handleInvoluntaryMovement(target, _user, _targetTile, pullToTile, this, null, null);

		local stagger = this.new("scripts/skills/effects/staggered_effect");
		target.getSkills().add(stagger);

		if (!_user.isHiddenToPlayer() && _targetTile.IsVisibleForPlayer)
		{
			this.Tactical.EventLog.log(stagger.getLogEntryOnAdded(this.Const.UI.getColorizedEntityName(_user), this.Const.UI.getColorizedEntityName(target)));
		}

		::Skv.dbg("Skv.Boggard: TONGUE " + _user.getName() + " drags " + target.getName()
			+ " to " + pullToTile.Coords.X + "," + pullToTile.Coords.Y);
		return true;
	}

});
