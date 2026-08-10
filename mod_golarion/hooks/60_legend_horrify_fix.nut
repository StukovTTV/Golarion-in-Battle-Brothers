::mods_hookExactClass("skills/actives/legend_horrify_old_skill", function ( o )
{
	local create = o.create;
	o.create = function ()
	{
		create();

		this.m.IsVisibleTileNeeded = false;
	}

	o.onUse = function ( _user, _targetTile )
	{
		local target = _targetTile.getEntity();
		this.spawnAttackEffect(_targetTile, this.Const.Tactical.AttackEffectBash);

		if (target != null && target.isAlive())
		{
			::Legends.Effects.grant(target, ::Legends.Effect.Horrified);

			if (!_user.isHiddenToPlayer() && _targetTile.IsVisibleForPlayer)
			{
				this.Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user) + " struck a blow that leaves " + ::Const.UI.getColorizedEntityName(target) + " horrified");
			}
		}

		return true;
	}
});
