::mods_hookExactClass("factions/actions/send_beast_roamers_action", function ( o )
{
	local create = o.create;

	o.create = function ()
	{

		create();

		local trog = function ( _action, _nearTile = null )
		{
			if (this.World.getTime().Days < 10 && _nearTile == null)
			{
				return false;
			}

			local disallowedTerrain = [];

			for( local i = 0; i < this.Const.World.TerrainType.COUNT; i = ++i )
			{
				if (i == this.Const.World.TerrainType.Swamp)
				{
				}
				else
				{
					disallowedTerrain.push(i);
				}
			}

			local tile = _action.getTileToSpawnLocation(10, disallowedTerrain, 10 - (_nearTile == null ? 0 : 2), 100, 1000, 3, 0, _nearTile);

			if (tile == null)
			{
				return false;
			}

			if (_action.getDistanceToNextAlly(tile) <= 10 / (_nearTile == null ? 1 : 2))
			{
				return false;
			}

			local distanceToNextSettlement = _action.getDistanceToSettlements(tile);
			local party = _action.getFaction().spawnEntity(tile, "Troglodytes", false, ::Const.World.Spawn.GolarionTroglodyteRoamers, this.Math.rand(80, 120) * _action.getScaledDifficultyMult() * this.Math.maxf(0.7, this.Math.minf(1.5, distanceToNextSettlement / 14.0)));

			party.getSprite("banner").setBrush("banner_beasts_01");
			party.setDescription("Scaled things out of the bog, and you smell them long before you see them.");
			party.setFootprintType(this.Const.World.FootprintsType.Ghouls);
			party.setSlowerAtNight(false);
			party.setUsingGlobalVision(false);
			party.setLooting(false);

			party.getFlags().set("IsSkvTroglodyteBand", true);

			local roam = this.new("scripts/ai/world/orders/roam_order");
			roam.setNoTerrainAvailable();
			roam.setTerrain(this.Const.World.TerrainType.Swamp, true);
			party.getController().addOrder(roam);

			return true;
		};

		this.m.Options.push(trog);
	}
});
