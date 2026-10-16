this.skv_giant_rat <- this.inherit("scripts/entity/tactical/enemies/direwolf", {
	m = {
		SkvStats = null,
		SkvDire = false,
		SkvScale = 1.0,
		SkvCorpseName = "A Giant Rat"
	},

	function create()
	{
		this.direwolf.create();
		this.m.Type = ::Const.EntityType.SkvGiantRat;

		if (this.m.SkvStats == null)
		{
			this.m.SkvStats = ::Const.Tactical.Actor.SkvGiantRat;
		}

		this.m.XP = this.m.SkvStats.XP;
		this.m.SoundPitch = ::Math.rand(125, 140) * 0.01;
	}

	function onInit()
	{
		this.actor.onInit();

		local R = ::Const.Skv.Rats;
		local S = this.m.SkvStats;

		this.m.Name = ::Const.Strings.EntityName[this.m.Type];

		local b = this.m.BaseProperties;
		b.setValues(S);

		b.Armor[this.Const.BodyPart.Body] = S.Armor[this.Const.BodyPart.Body];
		b.Armor[this.Const.BodyPart.Head] = S.Armor[this.Const.BodyPart.Head];
		b.ArmorMax[this.Const.BodyPart.Body] = S.Armor[this.Const.BodyPart.Body];
		b.ArmorMax[this.Const.BodyPart.Head] = S.Armor[this.Const.BodyPart.Head];
		b.IsAffectedByNight = false;
		b.IsImmuneToDisarm = true;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;
		this.m.ActionPointCosts = this.Const.DefaultMovementAPCost;
		this.m.FatigueCosts = this.Const.DefaultMovementFatigueCost;

		local bodyN = this.m.SkvDire ? R.DireVariant : ::Math.rand(1, R.CommonVariants);
		local headN = this.m.SkvDire ? R.DireVariant : ::Math.rand(1, R.CommonVariants);

		this.addSprite("socket").setBrush("bust_base_beasts");
		local body = this.addSprite("body");
		body.setBrush("bust_rat_body_0" + bodyN);
		local head = this.addSprite("head");
		head.setBrush("bust_rat_head_0" + headN);
		local head_frenzy = this.addSprite("head_frenzy");
		local injury = this.addSprite("injury");
		injury.Visible = false;
		injury.setBrush("bust_rat_0" + bodyN + "_injured");
		local body_blood = this.addSprite("body_blood");
		body_blood.Visible = false;
		this.addDefaultStatusSprites();

		try
		{
			this.m.Items.getAppearance().Body = "bust_rat_body_0" + bodyN;
		}
		catch (e)
		{
			::logError("Skv.Rat: could not set the appearance body (the sprite is set regardless): " + e);
		}

		local v = ::Math.rand(-::Math.floor(R.ScaleVary * 100), ::Math.floor(R.ScaleVary * 100)) * 0.01;
		local s = (this.m.SkvDire ? R.DireScale : R.Scale) * (1.0 + v);
		this.m.SkvScale = s;
		body.Scale = s;
		head.Scale = s;
		injury.Scale = s;
		body_blood.Scale = s;
		this.getSprite("socket").Scale = R.SocketScale;
		this.getSprite("status_rooted").Scale = 0.54 * s;
		this.setSpriteOffset("status_rooted", this.createVec(0, 0));

		if (::Math.rand(0, 100) < R.SatVaryChance)
		{
			body.varySaturation(R.SatVary);
		}

		if (::Math.rand(0, 100) < R.ColorVaryChance)
		{
			body.varyColor(R.ColorVary, R.ColorVary, R.ColorVary);
		}

		head.Color = body.Color;
		head.Saturation = body.Saturation;
		injury.Color = body.Color;
		injury.Saturation = body.Saturation;

		this.addRatKit();

		this.m.Skills.update();
		::Skv.dbg("Skv.Rat: in. " + this.m.Name + " body=" + bodyN + " head=" + headN
			+ " scale=" + s + " (roll " + v + ") HP " + this.getHitpoints() + "/" + this.getHitpointsMax()
			+ " armour " + b.ArmorMax[this.Const.BodyPart.Body]
			+ " bite=" + this.m.Skills.hasSkill("actives.skv_rat_bite")
			+ " claws=" + this.m.Skills.hasSkill("actives.skv_rat_claws")
			+ " poison=" + this.m.Skills.hasSkill("racial.spider")
			+ " vermin=" + this.m.Skills.hasSkill("racial.skv_vermin"));
	}

	function addRatKit()
	{
		try { this.m.Skills.add(this.new("scripts/skills/actives/skv_rat_bite")); }
		catch (e) { ::logError("Skv.Rat: no bite - it will stand there: " + e); }

		if (this.m.SkvDire)
		{
			try { this.m.Skills.add(this.new("scripts/skills/actives/skv_rat_claws")); }
			catch (e) { ::logError("Skv.Rat: the Dire Rat has no claws: " + e); }
		}

		try { ::Legends.Traits.grant(this, ::Legends.Trait.RacialSpider); }
		catch (e) { ::logError("Skv.Rat: no spider racial (no poison, no pack courage): " + e); }

		try { this.m.Skills.add(this.new("scripts/skills/racial/skv_vermin")); }
		catch (e) { ::logError("Skv.Rat: no Vermin racial (a Ratcatcher hits it no harder): " + e); }

		try { ::Legends.Perks.grant(this, ::Legends.Perk.Backstabber); }
		catch (e) { ::logError("Skv.Rat: keeps no Backstabber: " + e); }

		if (this.m.SkvDire)
		{
			try { ::Legends.Perks.grant(this, ::Legends.Perk.CoupDeGrace); }
			catch (e) { ::logError("Skv.Rat: keeps no Coup de Grace: " + e); }
			try { ::Legends.Perks.grant(this, ::Legends.Perk.NineLives); }
			catch (e) { ::logError("Skv.Rat: keeps no Nine Lives: " + e); }
		}

		if (::Legends.isLegendaryDifficulty())
		{
			try { ::Legends.Perks.grant(this, ::Legends.Perk.LegendTumble); }
			catch (e) { ::logError("Skv.Rat: no Tumble on Legendary: " + e); }
		}
	}

	function onFactionChanged()
	{
		this.actor.onFactionChanged();
		local flip = this.isAlliedWithPlayer();
		foreach (layer in ["body", "head", "head_frenzy", "injury", "body_blood"])
		{
			try
			{
				local sp = this.getSprite(layer);
				if (sp != null) sp.setHorizontalFlipping(flip);
			}
			catch (e)
			{
				::Skv.dbg("Skv.Rat: facing failed on '" + layer + "' - " + e);
			}
		}
	}

	function onDeath( _killer, _skill, _tile, _fatalityType )
	{
		local flip = ::Math.rand(0, 100) < 50;
		local s = this.m.SkvScale * 0.95;

		if (_tile != null)
		{
			local decal;
			this.m.IsCorpseFlipped = flip;
			local body = this.getSprite("body");
			local head = this.getSprite("head");
			decal = _tile.spawnDetail(body.getBrush().Name + "_dead", this.Const.Tactical.DetailFlag.Corpse, flip);
			decal.Color = body.Color;
			decal.Saturation = body.Saturation;
			decal.Scale = s;

			if (_fatalityType != this.Const.FatalityType.Decapitated)
			{
				decal = _tile.spawnDetail(head.getBrush().Name + "_dead", this.Const.Tactical.DetailFlag.Corpse, flip);
				decal.Color = head.Color;
				decal.Saturation = head.Saturation;
				decal.Scale = s;
			}
			else
			{
				local layers = [
					head.getBrush().Name + "_dead"
				];
				local decap = this.Tactical.spawnHeadEffect(this.getTile(), layers, this.createVec(0, 0), 0.0, "bust_direwolf_head_bloodpool");
				decap[0].Color = head.Color;
				decap[0].Saturation = head.Saturation;
				decap[0].Scale = s;
			}

			this.spawnTerrainDropdownEffect(_tile);
			this.spawnFlies(_tile);
		}

		local deathLoot = this.getItems().getDroppableLoot(_killer);
		local tileLoot = this.getLootForTile(_killer, deathLoot);
		this.dropLoot(_tile, tileLoot, !flip);
		local corpse = this.generateCorpse(_tile, _fatalityType, _killer);

		if (_tile == null)
		{
			this.Tactical.Entities.addUnplacedCorpse(corpse);
		}
		else
		{
			_tile.Properties.set("Corpse", corpse);
			this.Tactical.Entities.addCorpse(_tile);
		}

		this.actor.onDeath(_killer, _skill, _tile, _fatalityType);
	}

	function getLootForTile( _killer, _loot )
	{
		if (_killer == null || _killer.getFaction() == this.Const.Faction.Player || _killer.getFaction() == this.Const.Faction.PlayerAnimals)
		{
			if (::Math.rand(1, 100) <= ::Const.Skv.Rats.MeatChance)
			{
				_loot.push(this.new("scripts/items/supplies/strange_meat_item"));
			}
		}

		return this.actor.getLootForTile(_killer, _loot);
	}

	function generateCorpse( _tile, _fatalityType, _killer )
	{
		local corpse = clone this.Const.Corpse;
		corpse.CorpseName = this.m.SkvCorpseName;
		corpse.Items = this.getItems().prepareItemsForCorpse(_killer);
		corpse.IsHeadAttached = _fatalityType != this.Const.FatalityType.Decapitated;

		if (_tile != null)
		{
			corpse.Tile = _tile;
		}

		return corpse;
	}

});
