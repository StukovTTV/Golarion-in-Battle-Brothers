// ============================================================================
//  THE CHOKING TOWER -- ACTION (offer gate)
//
//  Posts the Choking Tower job from a non-military frontier settlement that sits
//  in Numeria-appropriate country: temperate, wooded, and with a stretch of deep
//  wood 6-12 tiles out for the tower to hide in. The contract spawns and owns its
//  own site (see the contract's Offer.end), so this action only decides WHERE and
//  WHETHER the job appears -- it does not touch any world fixture.
//
//  WHY SETTLEMENTS, NOT CITY-STATES. Registered on Const.FactionTrait.Actions[
//  Settlement] -- the northern civilian pool. City-states draw from their OWN
//  list (OrientalCityState), a separate pool, so the desert/tropical south never
//  sees this contract at all. That is not a guard we add; it is a list we are
//  simply not on.
//
//  WHY THE TERRAIN GATE CARRIES THE "IS THIS NUMERIA?" CHECK. A *temperate*
//  forest (Forest / LeaveForest / AutumnForest, never SnowyForest) in the 6-12
//  ring means a temperate, wooded locale by construction -- it rules out ice and
//  sand without a single biome name. The explicit snow/tundra exclusion below is
//  belt-and-suspenders on top of that, mirroring the shipped roaming-beast idiom.
//
//  NOTHING HERE MAY THROW. This runs every tick for every settlement on the list;
//  a throw kills the whole faction-action loop and the settlement silently stops
//  offering ANY contract (see skv_den_hunt_action's header). isKindOf on an
//  unknown class name merely returns false -- it does not throw -- so the arctic
//  check is safe.
// ============================================================================
this.skv_choking_tower_action <- this.inherit("scripts/factions/faction_action", {
	m = {},
	function create()
	{
		this.m.ID = "skv_choking_tower_action";
		this.m.Cooldown = this.World.getTime().SecondsPerDay * 14;
		this.m.IsStartingOnCooldown = false;
		this.m.IsSettlementsRequired = true;
		this.faction_action.create();
	}

	// The arctic exclusion: the full snow/tundra class set (base + size variants),
	// matched with the shipped ::MSU.isKindOf idiom (z_mods_legend_roaming_beast).
	function isArctic( _v )
	{
		return ::MSU.isKindOf(_v, "legends_snow_village")   || ::MSU.isKindOf(_v, "small_snow_village")   || ::MSU.isKindOf(_v, "medium_snow_village")   || ::MSU.isKindOf(_v, "large_snow_village")
			|| ::MSU.isKindOf(_v, "legends_tundra_village") || ::MSU.isKindOf(_v, "small_tundra_village") || ::MSU.isKindOf(_v, "medium_tundra_village") || ::MSU.isKindOf(_v, "large_tundra_village");
	}

	// At least one free temperate-forest tile in the 6-12 ring -- the deep
	// Smokewood band the tower spawns in. Gate ring == spawn ring, so if this
	// passes the contract's pickSiteTile will find a home.
	function hasDeepWood( _v )
	{
		local ring = _v.getSurroundingTilesOfType([
			this.Const.World.TerrainType.Forest,
			this.Const.World.TerrainType.LeaveForest,
			this.Const.World.TerrainType.AutumnForest
		], 12);
		foreach( t in ring )
		{
			if (!t.IsOccupied && _v.getTile().getDistanceTo(t) >= 6)
			{
				return true;
			}
		}
		return false;
	}

	function onUpdate( _faction )
	{
		// Shared frequency dial (::Skv.Cfg): 0 = all Golarion contracts off.
		local sc = ::Skv.Cfg.score();
		if (sc <= 0)
		{
			return;
		}

		// Once per campaign -- it is THE Choking Tower. The whole gate is ::Skv.Once
		// (skv_engine.nut): one live offer at a time, released if it expires unseen,
		// retired for good only when actually finished. Comment out to re-test.
		if (::Skv.Once.isLocked("ChokingTower"))
		{
			return;
		}

		if (!_faction.isReadyForContract(this.Const.Contracts.ContractCategoryMap.skv_choking_tower_contract))
		{
			return;
		}

		local v = _faction.getSettlements()[0];

		if (v.isIsolated())
		{
			return;
		}

		// Any NON-MILITARY settlement (village, town or city). Forts are military
		// and drop out here. City-states are on their own list, not this one.
		if (v.isMilitary())
		{
			return;
		}

		// Temperate, not arctic (redundant with the temperate-forest gate below,
		// kept as an explicit belt-and-suspenders).
		if (this.isArctic(v))
		{
			return;
		}

		// Deep temperate wood 6-12 tiles out -- marks Numeria-country AND
		// guarantees the tower a spawnable tile.
		if (!this.hasDeepWood(v))
		{
			return;
		}

		if (_faction.hasContractExclusion("contract.skv_choking_tower"))
		{
			return;
		}

		// Rarity dial. `rand(1,100) > N` DECLINES above N, so it PASSES ~N% of
		// eligible ticks: 15 => ~15%. (Testing value was 99 = near-guaranteed.)
		if (::Math.rand(1, 100) > 15)
		{
			return;
		}

		// Score is a WEIGHT in the weighted pick, not a boolean. The shared dial's
		// default of 2 keeps a contract already made rare by the roll above from ALSO
		// having to win a coin flip against every build/upgrade action. Stamp it.
		this.m.Score = sc;
	}

	function onClear()
	{
	}

	function onExecute( _faction )
	{
		// Claim the one live-offer slot as this town posts it (::Skv.Once handles the
		// release-on-expiry and the permanent done-flag).
		::Skv.Once.claim("ChokingTower");

		local contract = this.new("scripts/contracts/contracts/skv_choking_tower_contract");
		contract.setFaction(_faction.getID());
		contract.setHome(_faction.getSettlements()[0]);
		contract.setEmployerID(_faction.getRandomCharacter().getID());
		this.World.Contracts.addContract(contract);
	}

});
