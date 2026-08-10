::Const.Skv <- ("Skv" in ::Const) ? ::Const.Skv : {};
if (!("Skv" in ::getroottable())) ::Skv <- {};

::Const.Skv.StenchMeleeSkill  <- 10;
::Const.Skv.StenchRangedSkill <- 10;

::Const.Skv.StenchMeleeSkillAmplified  <- 20;
::Const.Skv.StenchRangedSkillAmplified <- 20;

::Const.Skv.StenchFatigue <- 8;
::Const.Skv.StenchFatigueAmplified <- 16;

::Skv.Stench <- {

	EffectID   = "effects.skv_stench",
	EffectPath = "scripts/skills/effects/skv_stench_effect",
	RacialID   = "racial.skv_stench",

	function worstSourceAdjacentTo( _actor )
	{
		return this.worstSourceAdjacentToTile(_actor.getTile(), _actor);
	}

	function worstSourceAdjacentToTile( _tile, _actor = null )
	{
		local tile = _tile;
		local found = 0;

		for( local i = 0; i != 6; i = ++i )
		{
			if (!tile.hasNextTile(i)) continue;

			local next = tile.getNextTile(i);
			if (!next.IsOccupiedByActor) continue;

			local other = next.getEntity();
			if (other == null) continue;
			if (!other.isAlive()) continue;
			if (_actor != null && other.isAlliedWith(_actor)) continue;

			local racial = other.getSkills().getSkillByID(this.RacialID);
			if (racial == null) continue;

			local amplified = false;
			try { amplified = racial.m.Amplified; } catch (e) {}

			if (amplified) return 2;
			found = 1;
		}

		return found;
	}

	function onActorTurnEnd( _actor )
	{
		if (_actor == null || !_actor.isAlive() || !_actor.isPlacedOnMap()) return;

		local skills = _actor.getSkills();

		if (skills.hasSkill(this.RacialID)) return;

		try
		{
			if (_actor.getCurrentProperties().IsImmuneToPoison) return;
		}
		catch (e)
		{
			::logError("Skv.Stench: could not read poison immunity (it chokes anyway): " + e);
		}

		local worst = this.worstSourceAdjacentTo(_actor);
		if (worst == 0) return;
		local amplified = worst == 2;

		local existing = skills.getSkillByID(this.EffectID);

		if (existing != null)
		{

			existing.m.TurnsLeft = 2;
			existing.m.Amplified = amplified;
			return;
		}

		local effect = ::new(this.EffectPath);
		effect.m.Amplified = amplified;
		skills.add(effect);

		local cost = amplified ? ::Const.Skv.StenchFatigueAmplified : ::Const.Skv.StenchFatigue;
		try { _actor.setFatigue(_actor.getFatigue() + cost); } catch (e) {}
	}
};

::mods_hookExactClass("entity/tactical/actor", function ( o )
{
	local onTurnEnd = o.onTurnEnd;
	o.onTurnEnd = function ()
	{
		onTurnEnd.call(this);

		try
		{
			::Skv.Stench.onActorTurnEnd(this);
		}
		catch (e)
		{
			::logError("Skv.Stench: failed at the end of a turn (the turn still ended): " + e);
		}
	}
});
