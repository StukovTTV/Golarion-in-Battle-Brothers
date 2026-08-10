this.skv_send_kobold_roamers_action <- this.inherit("scripts/factions/faction_action", {
	m = {},

	function create()
	{
		this.m.ID = "skv_send_kobold_roamers_action";
		this.m.Cooldown = 30.0;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	function skvCountBands( _faction )
	{
		local n = 0;

		foreach( u in _faction.getUnits() )
		{
			if (u == null || !u.isAlive())
			{
				continue;
			}

			local isOurs = false;
			try { isOurs = u.getFlags().get("IsSkvKoboldBand") == true; }
			catch (e) { isOurs = false; }

			if (isOurs)
			{
				n = n + 1;
			}
		}

		return n;
	}

	function skvEligibleWarrens( _faction )
	{
		local out = [];

		foreach( s in _faction.getSettlements() )
		{
			if (s == null || !s.isAlive())
			{
				continue;
			}

			if (s.getTypeID() != "location.skv_kobold_warren")
			{
				continue;
			}

			if (s.getLastSpawnTime() + 300.0 > this.Time.getVirtualTimeF())
			{
				continue;
			}

			out.push({
				D = s,
				P = 10
			});
		}

		return out;
	}

	function onUpdate( _faction )
	{
		if (this.skvCountBands(_faction) >= 2)
		{
			return;
		}

		if (this.skvEligibleWarrens(_faction).len() == 0)
		{
			return;
		}

		this.m.Score = 10;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		if (this.skvCountBands(_faction) >= 2)
		{
			return;
		}

		local candidates = this.skvEligibleWarrens(_faction);

		if (candidates.len() == 0)
		{
			return;
		}

		local warren = this.pickWeightedRandom(candidates);
		warren.setLastSpawnTimeToNow();

		local budget = this.Math.rand(50, 110);

		local distanceToNextSettlement = this.getDistanceToSettlements(warren.getTile());

		try
		{
			if (::Legends.Mod.ModSettings.getSetting("DistanceScaling").getValue() && distanceToNextSettlement > 14)
			{
				budget = budget * (distanceToNextSettlement / 14.0);
			}
		}
		catch (e) {}

		budget = budget * this.getReputationToDifficultyLightMult();

		local party = this.getFaction().spawnEntity(warren.getTile(), "Kobold Warband", false, warren.getRoamerSpawnList(), budget);

		if (party == null)
		{
			return;
		}

		party.getSprite("banner").setBrush(warren.getBanner());
		party.setDescription("A pack of small scaled things with slings and sharpened sticks, a long way from whatever hole they came out of.");
		party.setFootprintType(this.Const.World.FootprintsType.Goblins);
		party.getFlags().set("IsRandomlySpawned", true);

		party.getFlags().set("IsSkvKoboldBand", true);

		party.getLoot().ArmorParts = this.Math.rand(0, 5);
		party.getLoot().Medicine = this.Math.rand(0, 3);
		party.getLoot().Ammo = this.Math.rand(10, 30);

		local numFood = this.Math.rand(1, 2);

		for( local i = 0; i != numFood; i = i + 1 )
		{
			if (this.Math.rand(1, 100) <= 50)
			{
				party.addToInventory("supplies/strange_meat_item");
			}
			else
			{
				party.addToInventory("supplies/roots_and_berries_item");
			}
		}

		local c = party.getController();
		local roam = this.new("scripts/ai/world/orders/roam_order");
		roam.setAllTerrainAvailable();
		roam.setTerrain(this.Const.World.TerrainType.Ocean, false);
		roam.setTerrain(this.Const.World.TerrainType.Mountains, false);
		roam.setPivot(warren);
		roam.setAvoidHeat(true);
		roam.setTime(this.World.getTime().SecondsPerDay * 2);
		local move = this.new("scripts/ai/world/orders/move_order");
		move.setDestination(warren.getTile());
		local despawn = this.new("scripts/ai/world/orders/despawn_order");
		c.addOrder(roam);
		c.addOrder(move);
		c.addOrder(despawn);
	}

});
