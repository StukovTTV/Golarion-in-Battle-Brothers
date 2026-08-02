this.skv_den_hunt_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_den_hunt_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
		this.m.Den <- null;
	}

	function onClear()
	{
		this.m.Den = null;
	}

	function findDen()
	{
		foreach( v in this.World.EntityManager.getLocations() )
		{
			if (v.getTypeID() != "location.skv_den")
			{
				continue;
			}

			if (!v.isAlive())
			{
				continue;
			}

			if (v.getFlags().get("IsEventLocation"))
			{
				continue;
			}

			return v;
		}

		return null;
	}

	function onUpdate( _faction )
	{

		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		if (!_faction.isReadyForContract())
		{
			return;
		}

		if (this.World.Assets.getBusinessReputation() < 990)
		{
			return;
		}

		local seat = _faction.getSettlements()[0];

		if (seat.isIsolated())
		{
			return;
		}

		local den = this.findDen();

		if (den == null)
		{
			return;
		}

		if (seat.getTile().getDistanceTo(den.getTile()) > 40)
		{
			return;
		}

		this.m.Den = den;

		this.m.Score = sc;
	}

	function onExecute( _faction )
	{
		local contract = this.new("scripts/contracts/contracts/skv_den_hunt_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		contract.setDen(this.m.Den);
		this.World.Contracts.addContract(contract);
	}

});
