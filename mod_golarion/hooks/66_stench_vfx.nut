::Skv.StenchFX <- {

	LastRound = -1,

	LastSources = 0,
	LastTiles = 0,
	LastEmitters = 0,
	LastBreathed = false,

	function repaint()
	{
		if (!("Tactical" in ::getroottable()) || ::Tactical == null) return;

		::Skv.FX.unstainAll();

		local round = -1;
		try { round = ::Tactical.TurnSequenceBar.getCurrentRound(); } catch (e) {}

		local breathe = round != this.LastRound;
		if (breathe) this.LastRound = round;

		this.LastSources = 0;
		this.LastTiles = 0;
		this.LastEmitters = 0;
		this.LastBreathed = breathe;
		::Skv.FX.LastStainDecals = 0;

		local factions = null;
		try { factions = ::Tactical.Entities.m.Instances; } catch (e) { return; }
		if (factions == null) return;

		local aura = {};

		for( local f = 0; f < factions.len(); f = f + 1 )
		{
			foreach (actor in factions[f])
			{
				if (actor == null) continue;

				try
				{
					if (!actor.isAlive() || !actor.isPlacedOnMap()) continue;

					local racial = actor.getSkills().getSkillByID(::Skv.Stench.RacialID);
					if (racial == null) continue;

					local amplified = false;
					try { amplified = racial.m.Amplified; } catch (e) {}

					this.LastSources = this.LastSources + 1;

					local tile = actor.getTile();

					for( local i = 0; i != 6; i = ++i )
					{
						if (!tile.hasNextTile(i)) continue;

						local next = tile.getNextTile(i);

						if (!next.IsVisibleForPlayer) continue;

						local key = next.ID;

						if (key in aura)
						{
							if (amplified) aura[key].Amplified = true;
						}
						else
						{
							aura[key] <- { Tile = next, Amplified = amplified };
						}
					}
				}
				catch (e)
				{
					::logError("Skv.StenchFX: could not gather a source's ring (the stench is unaffected): " + e);
				}
			}
		}

		foreach (entry in aura)
		{
			this.LastTiles = this.LastTiles + 1;

			try
			{
				local amplified = entry.Amplified;

				::Skv.FX.stain(entry.Tile,
					amplified ? ::Const.Skv.FXAmplifiedStainColor : ::Const.Skv.FXStenchStainColor,
					amplified ? ::Const.Skv.FXAmplifiedStainScale : ::Const.Skv.FXStenchStainScale,
					amplified ? ::Const.Skv.FXAmplifiedStainCount : ::Const.Skv.FXStenchStainCount);

				if (breathe)
				{
					this.LastEmitters = this.LastEmitters + ::Skv.FX.burst("Miasma", entry.Tile, {
						Entries   = [0],
						TintMin   = amplified ? ::Const.Skv.FXAmplifiedTintMin   : ::Const.Skv.FXStenchTintMin,
						TintMax   = amplified ? ::Const.Skv.FXAmplifiedTintMax   : ::Const.Skv.FXStenchTintMax,
						Scale     = amplified ? ::Const.Skv.FXAmplifiedScale     : ::Const.Skv.FXStenchScale,
						SpawnRate = amplified ? ::Const.Skv.FXAmplifiedSpawnRate : ::Const.Skv.FXStenchSpawnRate,
						Budget    = amplified ? ::Const.Skv.FXAmplifiedBudget    : ::Const.Skv.FXStenchBudget,
						LifeCap   = amplified ? ::Const.Skv.FXAmplifiedLifeCap   : ::Const.Skv.FXStenchLifeCap
					});
				}
			}
			catch (e)
			{
				::logError("Skv.StenchFX: could not paint an aura tile (the stench is unaffected): " + e);
			}
		}
	}

};

::mods_hookExactClass("entity/tactical/actor", function ( o )
{
	local onTurnStart = o.onTurnStart;

	o.onTurnStart = function ()
	{
		onTurnStart.call(this);

		try
		{
			::Skv.StenchFX.repaint();
		}
		catch (e)
		{
			::logError("Skv.StenchFX: failed at the start of a turn (the turn still started): " + e);
		}
	}
});

::mods_hookExactClass("states/tactical_state", function ( o )
{
	local onInit = o.onInit;
	o.onInit = function ()
	{
		try { ::Skv.FX.forgetStains(); ::Skv.StenchFX.LastRound = -1; }
		catch (e) { ::logError("Skv.StenchFX: could not reset at battle start: " + e); }
		return onInit.call(this);
	}

	local onFinish = o.onFinish;
	o.onFinish = function ()
	{
		try { ::Skv.FX.forgetStains(); ::Skv.StenchFX.LastRound = -1; }
		catch (e) { ::logError("Skv.StenchFX: could not reset at battle end: " + e); }
		return onFinish.call(this);
	}
});
