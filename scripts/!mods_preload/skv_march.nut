if (!("Skv" in getroottable())) ::Skv <- {};

::Skv.March <- {

	Flag = "SkvMarch.Pct",

	TimeFlag = "SkvMarch.At",

	AppliedFlag = "SkvMarch.Applied",

	TavernFlag = "SkvMarch.TavernDay",

	EffectID   = "effects.skv_march_fatigue",
	EffectPath = "scripts/skills/effects/skv_march_fatigue_effect",

	MaxStepHours = 24.0,

	Verified = false,
	Broken = false,

	function pct()
	{
		try
		{
			local cap = this.cap();
			if (cap <= 0) return 0.0;
			if (!::World.Flags.has(this.Flag)) return 0.0;
			local v = ::World.Flags.get(this.Flag);
			if (v == null) return 0.0;
			if (v < 0.0) return 0.0;
			if (v > cap) return cap * 1.0;
			return v * 1.0;
		}
		catch (e)
		{
			return 0.0;
		}
	}

	function vigour()
	{
		local v = 100.0 - ::Math.floor(this.pct());
		return v.tointeger();
	}

	function mult()
	{
		local m = 1.0 - this.pct() / 100.0;
		if (m < 0.1) m = 0.1;
		return m;
	}

	function drain()    { try { return ::Skv.Cfg.marchDrain();     } catch (e) { return 0.75; } }
	function recover()  { try { return ::Skv.Cfg.marchRecover();   } catch (e) { return 3.0;  } }
	function townMult() { try { return ::Skv.Cfg.marchTownBonus(); } catch (e) { return 1.5;  } }
	function cap()      { try { return ::Skv.Cfg.marchCap();       } catch (e) { return 75;   } }
	function tavern()   { try { return ::Skv.Cfg.marchTavern();    } catch (e) { return 1;    } }

	function shift( _delta )
	{
		local cap = this.cap();
		local v = this.pct() + _delta;
		if (v < 0.0) v = 0.0;
		if (v > cap) v = cap * 1.0;
		::World.Flags.set(this.Flag, v);
		return v;
	}

	function nearTown()
	{
		try
		{
			local player = ::World.State.getPlayer();
			if (player == null) return false;
			local tile = player.getTile();

			foreach( s in ::World.EntityManager.getSettlements() )
			{
				if (s == null || !s.isAlive()) continue;
				if (!s.isAlliedWithPlayer()) continue;
				if (s.getTile().getDistanceTo(tile) <= 3) return true;
			}
		}
		catch (e)
		{
			::logError("Skv.March.nearTown failed (treated as open country): " + e);
		}

		return false;
	}

	function effectOK()
	{
		if (this.Broken) return false;
		if (this.Verified) return true;

		local probe = null;
		try { probe = ::new(this.EffectPath); } catch (e) { probe = null; }

		local id = null;
		if (probe != null) { try { id = probe.getID(); } catch (e) { id = null; } }

		if (id != this.EffectID)
		{
			this.Broken = true;
			::logError("Skv.March: the march fatigue effect did not construct properly (got ID '" + (id == null ? "null" : id) + "', wanted '" + this.EffectID + "'). March fatigue is DISABLED for this session rather than put broken effects on the roster.");
			return false;
		}

		this.Verified = true;
		return true;
	}

	function reconcile()
	{
		local live = ::Math.floor(this.pct()).tointeger();
		local want = live >= 1;

		if (want && !this.effectOK()) want = false;

		local applied = -1;
		try { if (::World.Flags.has(this.AppliedFlag)) applied = ::World.Flags.get(this.AppliedFlag); } catch (e) {}

		local changed = applied != live;

		foreach( bro in ::World.getPlayerRoster().getAll() )
		{
			if (bro == null) continue;

			try
			{
				local skills = bro.getSkills();
				local has = skills.hasSkill(this.EffectID);

				if (want && !has)
				{

					skills.add(::new(this.EffectPath));
				}
				else if (!want && has)
				{
					skills.removeByID(this.EffectID);
				}
				else if (changed && has)
				{

					skills.update();
				}

				if (bro.getFatigue() > bro.getFatigueMax())
				{
					bro.setFatigue(bro.getFatigueMax());
				}
			}
			catch (e)
			{
				::logError("Skv.March: could not apply march fatigue to a brother (the rest still update): " + e);
			}
		}

		if (changed)
		{
			try { ::World.Flags.set(this.AppliedFlag, live); } catch (e) {}

			try { ::World.State.updateTopbarAssets(); } catch (e) {}
		}
	}

	function tick()
	{
		local now = ::Time.getVirtualTimeF();
		local last = now;

		try { if (::World.Flags.has(this.TimeFlag)) last = ::World.Flags.get(this.TimeFlag); } catch (e) {}

		try { ::World.Flags.set(this.TimeFlag, now); } catch (e) {}

		if (this.cap() <= 0)
		{

			try { ::World.Flags.set(this.Flag, 0.0); } catch (e) {}
			this.reconcile();
			return;
		}

		local secondsPerHour = ::World.getTime().SecondsPerDay / 24.0;
		if (secondsPerHour <= 0) return;

		local hours = (now - last) / secondsPerHour;

		if (hours < 0.0) hours = 0.0;
		if (hours > this.MaxStepHours) hours = this.MaxStepHours;

		if (hours > 0.0)
		{
			local camping = false;
			try { camping = ::World.Assets.isCamping(); } catch (e) {}

			if (camping)
			{
				local rate = this.recover();
				if (this.nearTown()) rate = rate * this.townMult();
				this.shift(-rate * hours);
			}
			else
			{
				this.shift(this.drain() * hours);
			}
		}

		this.reconcile();
	}

	function drinkRound()
	{
		try
		{
			local give = this.tavern();
			if (give <= 0) return 0;
			if (this.pct() <= 0.0) return 0;

			local today = ::World.getTime().Days;
			local lastDay = -1;
			if (::World.Flags.has(this.TavernFlag)) lastDay = ::World.Flags.get(this.TavernFlag);
			if (lastDay == today) return 0;

			local before = this.pct();
			this.shift(-give * 1.0);
			::World.Flags.set(this.TavernFlag, today);
			this.reconcile();

			local actual = before - this.pct();
			return actual <= 0.0 ? 0 : actual;
		}
		catch (e)
		{
			::logError("Skv.March.drinkRound failed (the round was still bought): " + e);
			return 0;
		}
	}

	function report()
	{
		::logInfo(">> Skv.March: " + ::Math.floor(this.pct()) + "% lost, vigour " + this.vigour() + "%, StaminaMult x" + this.mult());
		local camping = false;
		try { camping = ::World.Assets.isCamping(); } catch (e) {}
		::logInfo("   camping=" + camping + " nearTown=" + this.nearTown()
			+ " drain=" + this.drain() + "%/h recover=" + this.recover() + "%/h townMult=" + this.townMult()
			+ " cap=" + this.cap() + "% tavern=" + this.tavern() + "%");

		try
		{
			local t = ::World.getTime();
			local elapsedHours = t.SecondsPerDay <= 0 ? 0.0 : (::Time.getVirtualTimeF() * 24.0 / t.SecondsPerDay);
			::logInfo("   world: day " + t.Days + ", hour " + t.Hours + ", " + ::Math.floor(elapsedHours)
				+ " game hours since the campaign began (effect " + (this.Broken ? "BROKEN, disabled" : (this.Verified ? "verified" : "not built yet")) + ")");
		}
		catch (e) {}

		local n = 0;
		foreach( bro in ::World.getPlayerRoster().getAll() )
		{
			if (bro == null) continue;
			if (n >= 5) break;
			::logInfo("   " + bro.getName() + ": fatigue " + bro.getFatigue() + "/" + bro.getFatigueMax()
				+ (bro.getSkills().hasSkill(this.EffectID) ? " [effect]" : " [no effect]"));
			n = n + 1;
		}
	}
};

::skvmarch <- function () { ::Skv.March.report(); };
