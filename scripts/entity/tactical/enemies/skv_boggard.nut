this.skv_boggard <- this.inherit("scripts/entity/tactical/enemies/unhold", {
	m = {

		SkvStats = null,
		SkvKind = null
	},

	function create()
	{
		this.unhold.create();

		if (this.m.SkvStats == null)
		{
			this.m.SkvStats = ::Const.Tactical.Actor.SkvBoggard;
		}

		this.m.XP = this.m.SkvStats.XP;
		this.m.SoundPitch = 1.35;
	}

	function onInit()
	{
		this.unhold.onInit();

		local B = ::Const.Skv.Boggard;

		local kind = null;
		if (this.m.SkvKind != null && (this.m.SkvKind in B.Types))
		{
			kind = B.Types[this.m.SkvKind];
		}

		if (this.m.Type != ::Const.EntityType.Unhold)
		{
			this.m.Name = ::Const.Strings.EntityName[this.m.Type];
		}

		local b = this.m.BaseProperties;
		b.setValues(this.m.SkvStats);

		b.ArmorMax[this.Const.BodyPart.Body] = this.m.SkvStats.Armor[this.Const.BodyPart.Body];
		b.ArmorMax[this.Const.BodyPart.Head] = this.m.SkvStats.Armor[this.Const.BodyPart.Head];
		b.IsImmuneToDisarm = false;
		b.IsImmuneToRotation = false;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		try
		{
			this.m.Items.getAppearance().Body = B.Body;

			local body = this.getSprite("body");
			body.setBrush(B.Body);

			local head = this.getSprite("head");
			head.setBrush(kind != null ? kind.Head : B.Heads[::Math.rand(0, B.Heads.len() - 1)]);
			local injury = this.getSprite("injury");
			injury.setBrush(B.Injury);

			local v = ::Math.rand(-::Math.floor(B.ScaleVary * 100), ::Math.floor(B.ScaleVary * 100)) * 0.01;
			local s = (kind != null ? kind.Scale : B.Scale) * (1.0 + v);
			body.Scale = s;
			head.Scale = s;
			injury.Scale = s;

			this.getSprite("socket").Scale = B.SocketScale;

			body.Color = this.createColor(B.Tint);
			body.Saturation = B.Saturation;
			body.varyColor(B.ColorVary, B.ColorVary, B.ColorVary);
			head.Color = body.Color;
			head.Saturation = body.Saturation;
			injury.Color = body.Color;
			injury.Saturation = body.Saturation;

			this.getSprite("status_rooted").Scale = 0.65 * s;
			this.setSpriteOffset("status_rooted", this.createVec(-10 * s, 16 * s));
			this.setSpriteOffset("status_stunned", this.createVec(0, 10 * s));
			this.setSpriteOffset("arrow", this.createVec(0, 10 * s));

			::Skv.dbg("Skv.Boggard: art set. kind=" + (this.m.SkvKind == null ? "(base)" : this.m.SkvKind)
				+ " head=" + head.getBrush().Name + " scale=" + s + " (roll " + v + ") tint=" + B.Tint);
		}
		catch (e)
		{
			::logError("Skv.Boggard: the art step threw and it will look like an unhold: " + e);
		}

		try { ::Legends.Actives.remove(this, ::Legends.Active.Sweep); }
		catch (e) { ::logError("Skv.Boggard: keeps Sweep: " + e); }
		try { ::Legends.Actives.remove(this, ::Legends.Active.SweepZoc); }
		catch (e) { ::logError("Skv.Boggard: keeps SweepZoc: " + e); }
		try { ::Legends.Actives.remove(this, ::Legends.Active.FlingBack); }
		catch (e) { ::logError("Skv.Boggard: keeps FlingBack: " + e); }
		try { ::Legends.Actives.remove(this, ::Legends.Active.UnstoppableCharge); }
		catch (e) { ::logError("Skv.Boggard: keeps UnstoppableCharge: " + e); }

		try { ::Legends.Perks.remove(this, ::Legends.Perk.CripplingStrikes); }
		catch (e) { ::logError("Skv.Boggard: keeps CripplingStrikes: " + e); }
		try { ::Legends.Perks.remove(this, ::Legends.Perk.BatteringRam); }
		catch (e) { ::logError("Skv.Boggard: keeps BatteringRam: " + e); }
		try { ::Legends.Perks.remove(this, ::Legends.Perk.Stalwart); }
		catch (e) { ::logError("Skv.Boggard: keeps Stalwart: " + e); }
		try { ::Legends.Perks.remove(this, ::Legends.Perk.SteelBrow); }
		catch (e) { ::logError("Skv.Boggard: keeps SteelBrow: " + e); }
		try { ::Legends.Perks.remove(this, ::Legends.Perk.HoldOut); }
		catch (e) { ::logError("Skv.Boggard: keeps HoldOut: " + e); }

		try { this.m.Skills.removeByID("racial.unhold"); } catch (e) {}

		this.m.Skills.update();
		::Skv.dbg("Skv.Boggard: in. kind=" + (this.m.SkvKind == null ? "(base)" : this.m.SkvKind)
			+ " HP " + this.getHitpoints() + "/" + this.getHitpointsMax()
			+ " melee " + b.MeleeSkill + " armour " + b.ArmorMax[this.Const.BodyPart.Body]
			+ " sweep=" + this.m.Skills.hasSkill(::Legends.Actives.getID(::Legends.Active.Sweep))
			+ " charge=" + this.m.Skills.hasSkill(::Legends.Actives.getID(::Legends.Active.UnstoppableCharge)));
	}

	function getLootForTile( _killer, _loot )
	{
		return this.actor.getLootForTile(_killer, _loot);
	}

});
