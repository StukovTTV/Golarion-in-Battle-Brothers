this.skv_boggard_croak <- this.inherit("scripts/skills/actives/horrific_scream", {
	m = {
		Cooldown = 0
	},

	function create()
	{
		this.horrific_scream.create();

		local C = ::Const.Skv.Boggard.Croak;
		this.m.Name = "Terrifying Croak";
		this.m.Description = "A wet, swelling bellow that carries across open water. Men who have heard it once do not care to hear it twice.";
		this.m.ActionPointCost = C.ActionPoints;
		this.m.FatigueCost = C.Fatigue;
		this.m.MaxRange = C.MaxRange;

	}

	function isUsable()
	{
		if (this.m.Cooldown > 0)
		{
			return false;
		}

		return this.horrific_scream.isUsable();
	}

	function onUse( _user, _targetTile )
	{

		local target = _targetTile.getEntity();

		if (target == null)
		{
			return false;
		}

		if (!_user.isHiddenToPlayer() || _targetTile.IsVisibleForPlayer)
		{
			this.Tactical.EventLog.log(this.Const.UI.getColorizedEntityName(_user) + " lets out a terrifying croak");
		}

		local C = ::Const.Skv.Boggard.Croak;

		for( local i = 0; i < C.Checks; i = i + 1 )
		{
			target.checkMorale(-1, 0, this.Const.MoraleCheckType.MentalAttack);
		}

		this.m.Cooldown = C.Cooldown;
		::Skv.dbg("Skv.Boggard: CROAK at " + target.getName() + " (" + C.Checks + " checks) -> cooldown " + this.m.Cooldown);
		return true;
	}

	function onTurnEnd()
	{
		if (this.m.Cooldown > 0)
		{
			this.m.Cooldown = this.m.Cooldown - 1;
		}
	}

});
