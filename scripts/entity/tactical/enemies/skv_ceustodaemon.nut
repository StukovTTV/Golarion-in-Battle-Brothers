this.skv_ceustodaemon <- this.inherit("scripts/entity/tactical/enemies/ghoul", {
	m = {},

	function create()
	{
		this.ghoul.create();
		this.m.Type = ::Const.EntityType.SkvCeustodaemon;
		this.m.XP = ::Const.Tactical.Actor.SkvCeustodaemon.XP;

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_ceustodaemon_agent");
		this.m.AIAgent.setActor(this);
		this.m.SoundPitch = 0.85;
	}

	function onInit()
	{
		this.ghoul.onInit();

		local b = this.m.BaseProperties;
		b.setValues(::Const.Tactical.Actor.SkvCeustodaemon);
		b.ArmorMax[this.Const.BodyPart.Body] = ::Const.Tactical.Actor.SkvCeustodaemon.Armor[this.Const.BodyPart.Body];
		b.ArmorMax[this.Const.BodyPart.Head] = ::Const.Tactical.Actor.SkvCeustodaemon.Armor[this.Const.BodyPart.Head];
		b.IsAffectedByNight = false;
		b.IsImmuneToDisarm = true;
		this.m.XP = ::Const.Tactical.Actor.SkvCeustodaemon.XP;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		this.grow(true);
		this.grow(true);

		this.getFlags().set("SkvInnateCaster", true);

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/skv_daemon_breath"));
		}
		catch (e)
		{
			::logError("Skv.Daemon: could not take the breath (burning hands) - it still fights: " + e);
		}

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/skv_daemon_sleep"));
		}
		catch (e)
		{
			::logError("Skv.Daemon: could not take the hold (sleep) - it still fights: " + e);
		}

		this.m.Skills.update();
		::Skv.dbg("Skv.Daemon: in. size=" + this.m.Size + " HP " + this.getHitpoints() + "/" + this.getHitpointsMax()
			+ " base Melee " + b.MeleeSkill + " Ranged " + b.RangedSkill
			+ " breath=" + this.m.Skills.hasSkill(::Legends.Actives.getID(::Legends.Active.LegendMagicBurningHands))
			+ " sleep=" + this.m.Skills.hasSkill("actives.sleep")
			+ " swallow(kept, AI off)=" + this.m.Skills.hasSkill("actives.swallow_whole"));
	}

	function getLootForTile( _killer, _loot )
	{
		return this.actor.getLootForTile(_killer, _loot);
	}

});
