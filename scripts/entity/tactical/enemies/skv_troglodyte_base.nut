this.skv_troglodyte_base <- this.inherit("scripts/entity/tactical/enemies/ghoul", {
	m = {},

	function create()
	{
		this.ghoul.create();

		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_troglodyte_agent");
		this.m.AIAgent.setActor(this);

		this.m.SoundPitch = this.Math.rand(85, 105) * 0.01;
	}

	function grow( _instant = false )
	{
	}

	function skvBecomeTroglodyte( _actorTable, _keepClaws = false )
	{
		local b = this.m.BaseProperties;
		b.setValues(_actorTable);

		b.ArmorMax[this.Const.BodyPart.Body] = _actorTable.Armor[this.Const.BodyPart.Body];
		b.ArmorMax[this.Const.BodyPart.Head] = _actorTable.Armor[this.Const.BodyPart.Head];

		b.IsAffectedByNight = false;

		this.m.XP = _actorTable.XP;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;
		this.m.ActionPointCosts = this.Const.DefaultMovementAPCost;
		this.m.FatigueCosts = this.Const.DefaultMovementFatigueCost;

		local toRemove = [
			"actives.gruesome_feast",
			"effects.gruesome_feast",
			"actives.swallow_whole",

			"perk.legend_poison_immunity"
		];

		if (!_keepClaws) toRemove.push("actives.ghoul_claws");

		foreach( skillID in toRemove )
		{
			try { this.m.Skills.removeByID(skillID); }
			catch (e) { ::logError("Skv.Troglodyte: could not remove " + skillID + ": " + e); }
		}

		this.m.Skills.add(this.new("scripts/skills/racial/skv_stench"));
		this.m.Skills.update();

		::Const.Skv.dressTroglodyteBust(this);
		::Const.Skv.dressTroglodyte(this);
	}

	function getLootForTile( _killer, _loot )
	{

		try { return this.actor.getLootForTile(_killer, _loot); }
		catch (e) { return _loot; }
	}

	function skvArmWith( _meleePath, _javelins = 0, _javelinFirstPct = 100 )
	{
		local melee = null;
		local javelins = null;

		if (_meleePath != null) melee = this.new("scripts/items/weapons/" + _meleePath);

		if (_javelins > 0)
		{

			javelins = this.new("scripts/items/weapons/javelin");

			try
			{
				javelins.m.AmmoMax = _javelins;
				javelins.setAmmo(_javelins);
			}
			catch (e)
			{
				::logError("Skv.Troglodyte: could not set javelin count to " + _javelins + " (it keeps the default): " + e);
			}
		}

		local javelinFirst = javelins != null && (melee == null || this.Math.rand(1, 100) <= _javelinFirstPct);

		if (javelinFirst)
		{
			this.m.Items.equip(javelins);
			if (melee != null) this.m.Items.addToBag(melee);
		}
		else
		{
			if (melee != null) this.m.Items.equip(melee);
			if (javelins != null) this.m.Items.addToBag(javelins);
		}
	}

});
