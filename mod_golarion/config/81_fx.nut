::Const.Skv.FXStenchTintMin      <- "6f7a3c66";
::Const.Skv.FXStenchTintMax      <- "8a944872";
::Const.Skv.FXStenchScale        <- 0.7;
::Const.Skv.FXStenchSpawnRate    <- 3;
::Const.Skv.FXStenchBudget       <- 60;
::Const.Skv.FXStenchLifeCap      <- 3.5;
::Const.Skv.FXStenchStainColor   <- null;
::Const.Skv.FXStenchStainScale   <- 1.4;

::Const.Skv.FXAmplifiedTintMin   <- "5a6a2880";
::Const.Skv.FXAmplifiedTintMax   <- "7d8f3490";
::Const.Skv.FXAmplifiedScale     <- 0.95;
::Const.Skv.FXAmplifiedSpawnRate <- 4;
::Const.Skv.FXAmplifiedBudget    <- 80;
::Const.Skv.FXAmplifiedLifeCap   <- 4.0;
::Const.Skv.FXAmplifiedStainColor <- null;
::Const.Skv.FXAmplifiedStainScale <- 2.0;

::Const.Skv.FXStenchStainCount   <- 4;
::Const.Skv.FXAmplifiedStainCount <- 6;

::Const.Skv.FXMaxStainedTiles    <- 60;

::Const.Skv.FXBurstLifetime      <- 14;

::Skv.FX <- {

	Stained = [],

	Reported = {},

	LastStainDecals = 0,

	function detailFlag()
	{
		try { return ::Const.Tactical.DetailFlag.SpecialOverlay; } catch (e) { return 128; }
	}

	function pool( _name )
	{
		try
		{
			local key = _name + "Particles";
			if (!(key in ::Const.Tactical)) return null;
			return ::Const.Tactical[key];
		}
		catch (e)
		{
			return null;
		}
	}

	function reportOnce( _name, _pool )
	{
		if (_name in this.Reported) return;
		this.Reported[_name] <- true;

		try
		{
			local out = "Skv.FX: pool " + _name + " has " + _pool.len() + " entr(y/ies).";

			foreach (i, entry in _pool)
			{
				local stages = ("Stages" in entry) ? entry.Stages : null;
				out = out + " [" + i + "] brushes=" + (("Brushes" in entry) ? entry.Brushes.len() : "?")
					+ " stages=" + (stages == null ? "none" : stages.len().tostring());

				if (stages != null && stages.len() != 0)
				{
					local keys = "";
					foreach (k, v in stages[0]) keys = keys + (keys == "" ? "" : ",") + k;
					out = out + " stage0keys={" + keys + "}";
				}
			}

			::logInfo(out);
		}
		catch (e)
		{
			::logError("Skv.FX: could not describe the pool " + _name + " (effects still fire): " + e);
		}
	}

	function tintedStages( _stages, _opt )
	{
		if (_stages == null) return null;

		local tintMin = ("TintMin" in _opt) ? _opt.TintMin : null;
		local tintMax = ("TintMax" in _opt) ? _opt.TintMax : null;
		local scale   = ("Scale" in _opt) ? _opt.Scale : 1.0;
		local lifeCap = ("LifeCap" in _opt) ? _opt.LifeCap : null;

		local out = [];

		foreach (stage in _stages)
		{
			local copy = clone stage;

			try
			{
				if (tintMin != null) copy.ColorMin <- ::createColor(tintMin);
				if (tintMax != null) copy.ColorMax <- ::createColor(tintMax);

				if (scale != 1.0)
				{
					if ("ScaleMin" in copy) copy.ScaleMin = copy.ScaleMin * scale;
					if ("ScaleMax" in copy) copy.ScaleMax = copy.ScaleMax * scale;
				}

				if (lifeCap != null)
				{
					if ("LifeTimeMin" in copy) copy.LifeTimeMin = ::Math.minf(copy.LifeTimeMin, lifeCap);
					if ("LifeTimeMax" in copy) copy.LifeTimeMax = ::Math.minf(copy.LifeTimeMax, lifeCap);
				}
			}
			catch (e)
			{

			}

			out.push(copy);
		}

		return out;
	}

	function burst( _name, _tile, _opt = null )
	{
		if (_tile == null) return 0;

		local p = this.pool(_name);
		if (p == null) return 0;

		if (_opt == null) _opt = {};

		this.reportOnce(_name, p);

		local entries = ("Entries" in _opt) ? _opt.Entries : null;
		local n = 0;

		foreach (i, entry in p)
		{
			if (entries != null && entries.find(i) == null) continue;

			try
			{

				local budget = ("Budget" in _opt) ? _opt.Budget : entry.LifeTimeQuantity;
				if (budget == null || budget == 0) budget = ::Const.Skv.FXBurstLifetime;

				local rate = ("SpawnRate" in _opt) ? _opt.SpawnRate : entry.SpawnRate;

				::Tactical.spawnParticleEffect(
					false,
					entry.Brushes,
					_tile,
					entry.Delay,
					entry.Quantity,
					budget,
					rate,
					this.tintedStages(entry.Stages, _opt)
				);
				n = n + 1;
			}
			catch (e)
			{
				::logError("Skv.FX: " + _name + " particles refused a tile (the mechanic is unaffected): " + e);
			}
		}

		return n;
	}

	function stain( _tile, _color, _scale, _count = null )
	{
		if (_tile == null) return false;
		if (this.Stained.len() >= ::Const.Skv.FXMaxStainedTiles) return false;

		try
		{
			if (!("FliesDecals" in ::Const)) return false;
			if (::Const.FliesDecals.len() == 0) return false;

			local painted = 0;

			if (_count == null) _count = ::Const.Skv.FXStenchStainCount;

			for( local k = 0; k < _count; k = k + 1 )
			{
				local brush = ::Const.FliesDecals[::Math.rand(0, ::Const.FliesDecals.len() - 1)];
				local d = _tile.spawnDetail(brush, this.detailFlag(), ::Math.rand(0, 1) == 0);

				if (d == null)
				{

					if (!("stain" in this.Reported))
					{
						this.Reported["stain"] <- true;
						::logError("Skv.FX: spawnDetail returned null for '" + brush + "' -- the stench stain will not appear. Probe the brush with ::skvbrush.");
					}
					continue;
				}

				if (_color != null) { try { d.Color = ::createColor(_color); } catch (e) {} }
				try { d.Scale = _scale; } catch (e) {}
				painted = painted + 1;
			}

			this.Stained.push(_tile);
			this.LastStainDecals = this.LastStainDecals + painted;
			return painted != 0;
		}
		catch (e)
		{
			::logError("Skv.FX: could not stain a tile (the stench still works): " + e);
			return false;
		}
	}

	function unstainAll()
	{
		local flag = this.detailFlag();

		foreach (t in this.Stained)
		{
			try { t.clear(flag); } catch (e) {}
		}

		this.Stained = [];
	}

};
