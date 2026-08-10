::mods_hookExactClass("skills/actives/throw_fire_bomb_skill", function ( o )
{
	local onVerifyTarget = o.onVerifyTarget;

	o.onVerifyTarget = function ( _originTile, _targetTile )
	{
		if (!onVerifyTarget.call(this, _originTile, _targetTile))
		{
			return false;
		}

		if (_originTile.getDistanceTo(_targetTile) >= 2)
		{
			return true;
		}

		local actor = this.m.Container == null ? null : this.m.Container.getActor();
		local agent = actor == null ? null : actor.getAIAgent();

		if (agent != null && agent.getID() != ::Const.AI.Agent.ID.Player)
		{
			return false;
		}

		return true;
	}
});
