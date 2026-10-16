this.skv_pearl_of_power <- this.inherit("scripts/items/accessory/accessory", {
	m = {
		Charges = 1,
		ChargesMax = 1,
		RechargesDaily = true
	},

	function create()
	{
		this.accessory.create();

		this.m.ID = "accessory.skv_pearl_of_power";
		this.m.Name = "Pearl of Power";
		this.m.Description = "A pearl the size of a thumbnail, faintly warm, with a light in it that comes and goes like breath. Held tight and spoken to, it gives back what a man has already spent in a fight. Once a day, no more: then it is only a pearl until the next morning.";

		this.m.SlotType = ::Const.ItemSlot.Bag;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;
		this.m.Icon = "misc/skv_pearl_of_power.png";

		this.m.Value = 1200;
		this.m.IsDroppedAsLoot = true;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.ShowOnCharacter = false;
	}

	function getCharges()
	{
		return this.m.Charges;
	}

	function spendCharge()
	{
		this.m.Charges = ::Math.max(0, this.m.Charges - 1);
		return this.m.Charges;
	}

	function isAmountShown()
	{
		return true;
	}

	function getAmount()
	{
		return this.m.Charges;
	}

	function getAmountMax()
	{
		return this.m.ChargesMax;
	}

	function getAmountString()
	{
		return this.m.Charges + "/" + this.m.ChargesMax;
	}

	function onEquip()
	{
		this.accessory.onEquip();
		try
		{
			this.addSkill(this.new("scripts/skills/actives/skv_pearl_of_power_skill"));
		}
		catch (e)
		{
			::logError("Skv.Pearl: the carrier did not get the pearl's action; it cannot be used: " + e);
		}
	}

	function onPutIntoBag()
	{
		this.onEquip();
	}

	function getTooltip()
	{
		local result = this.accessory.getTooltip();
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Once per day: restores the carrier's spent abilities"
		});
		if (this.m.Charges > 0)
		{
			result.push({
				id = 21,
				type = "text",
				icon = "ui/icons/special.png",
				text = "[color=" + ::Const.UI.Color.PositiveValue + "]Ready[/color]"
			});
		}
		else
		{
			result.push({
				id = 21,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + ::Const.UI.Color.NegativeValue + "]Spent for the day[/color]"
			});
		}
		return result;
	}

	function restoreTable()
	{
		return [

			{ Kind = "effect", ID = "effects.legend_second_wind", What = "Second Wind" },

			{ Kind = "effect", ID = "effects.legend_summoned_falcon_effect", What = "the summoned falcon" },

			{ Kind = "effect", ID = "effects.legend_threw_sand_effect", What = "thrown sand" },

			{ Kind = "effect", ID = "effects.legend_summoned_wolf_effect", What = "the summoned wolf" },

			{ Kind = "effect", ID = "effects.legend_summoned_bear_effect", What = "the summoned bear" },

			{ Kind = "effect", ID = "effects.legend_summoned_hound_effect", What = "the summoned hound" },

			{ Kind = "effect", ID = "effects.legend_summoned_sighthound_effect", What = "the sighthound" },

			{ Kind = "effect", ID = "effects.legend_summoned_catapult_effect", What = "the catapult" },

			{ Kind = "cooldown", ID = "actives.legend_hex", What = "Hex" },

			{ Kind = "cooldown", ID = "actives.web", What = "Weave Web" },

			{ Kind = "falcon", ID = "accessory.falcon", What = "the falcon" },

			{ Kind = "amphora", ID = "accessory.legend_oms_amphora", What = "the Amphora" },

			{ Kind = "warden", ID = "perk.legend_vala_warden", What = "the warden" }
		];
	}

	function isSpent( _actor, _e )
	{
		local sk = _actor.getSkills();
		if (_e.Kind == "effect")
		{
			return sk.hasSkill(_e.ID);
		}
		if (_e.Kind == "cooldown")
		{
			local s = sk.getSkillByID(_e.ID);
			return s != null && ("Cooldown" in s.m) && s.m.Cooldown > 0;
		}
		if (_e.Kind == "falcon" || _e.Kind == "amphora")
		{
			local acc = _actor.getItems().getItemAtSlot(::Const.ItemSlot.Accessory);
			if (acc == null || acc.getID() != _e.ID) return false;
			return _e.Kind == "falcon" ? acc.isReleased() : acc.isConsumed();
		}
		if (_e.Kind == "warden")
		{
			if (!this.Tactical.isActive()) return false;
			local p = sk.getSkillByID(_e.ID);
			return p != null && ("WardenEntity" in p.m) && ::MSU.isNull(p.m.WardenEntity);
		}
		throw "unknown kind '" + _e.Kind + "'";
	}

	function spentOf( _actor )
	{
		local out = { Spent = [], Failed = [] };
		foreach (e in this.restoreTable())
		{
			try
			{
				if (this.isSpent(_actor, e)) out.Spent.push(e);
			}
			catch (err)
			{
				out.Failed.push(e.What + " (" + e.ID + "): " + err);
			}
		}
		return out;
	}

	function restoreOne( _actor, _e )
	{
		local sk = _actor.getSkills();
		if (_e.Kind == "effect")
		{
			sk.removeByID(_e.ID);
			return !sk.hasSkill(_e.ID);
		}
		if (_e.Kind == "cooldown")
		{
			local s = sk.getSkillByID(_e.ID);
			if (s == null) return false;
			s.m.Cooldown = 0;
			return s.m.Cooldown == 0;
		}
		if (_e.Kind == "falcon")
		{
			local acc = _actor.getItems().getItemAtSlot(::Const.ItemSlot.Accessory);
			if (acc == null || acc.getID() != _e.ID) return false;
			acc.setReleased(false);
			return !acc.isReleased();
		}
		if (_e.Kind == "amphora")
		{
			local acc = _actor.getItems().getItemAtSlot(::Const.ItemSlot.Accessory);
			if (acc == null || acc.getID() != _e.ID) return false;
			acc.setConsumed(false);
			return !acc.isConsumed();
		}
		if (_e.Kind == "warden")
		{
			local p = sk.getSkillByID(_e.ID);
			if (p == null || !::MSU.isNull(p.m.WardenEntity)) return false;

			p.m.WardenSummonSpent = false;
			p.summonWarden();

			return !::MSU.isNull(p.m.WardenEntity);
		}
		throw "unknown kind '" + _e.Kind + "'";
	}

	function restore( _actor )
	{
		local out = { Restored = [], Failed = [] };
		local now = this.spentOf(_actor);
		out.Failed.extend(now.Failed);
		foreach (e in now.Spent)
		{
			try
			{
				if (this.restoreOne(_actor, e)) out.Restored.push(e.What);
				else out.Failed.push(e.What + " (" + e.ID + "): still spent after the restore"
					+ (e.Kind == "warden" ? " (no free tile within 3 for the warden?)" : ""));
			}
			catch (err)
			{
				out.Failed.push(e.What + " (" + e.ID + "): " + err);
			}
		}
		foreach (f in out.Failed) ::logError("Skv.Pearl: " + _actor.getName() + ": not restored: " + f);
		return out;
	}

	function onSerialize( _out )
	{
		this.accessory.onSerialize(_out);
		_out.writeU16(this.m.Charges);
	}

	function onDeserialize( _in )
	{
		this.accessory.onDeserialize(_in);
		this.m.Charges = ::Math.min(_in.readU16(), this.m.ChargesMax);
	}

});
