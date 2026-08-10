this.skv_march_fatigue_effect <- this.inherit("scripts/skills/skill", {
	m = {},

	function create()
	{
		this.m.ID = "effects.skv_march_fatigue";
		this.m.Name = "Footsore";

		this.m.Description = "Too many hours under a pack and too few hours asleep. The men will still fight, but there is less strength in them than there was.";

		this.m.Icon = "ui/icons/fatigue.png";

		this.m.Type = this.Const.SkillType.Special | this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.Last;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = false;
	}

	function getTooltip()
	{
		local pct = 0;
		local vigour = 100;
		local camping = false;
		local nearTown = false;

		try
		{
			pct = ::Math.floor(::Skv.March.pct()).tointeger();
			vigour = ::Skv.March.vigour();
			nearTown = ::Skv.March.nearTown();
			camping = ::World.Assets.isCamping();
		}
		catch (e) {}

		local ret = [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			},
			{
				id = 3,
				type = "text",
				icon = "ui/icons/fatigue.png",
				text = "[color=" + ::Const.UI.Color.NegativeValue + "]-" + pct + "%[/color] maximum Fatigue"
			}
		];

		if (camping)
		{
			ret.push({
				id = 4,
				type = "text",
				icon = "ui/icons/special.png",
				text = nearTown
					? "The camp is pitched close to a friendly settlement. Hot food, a fire somebody else built, and a roof for any man who wants one. They are recovering faster here than they would in open country."
					: "The camp is pitched and the men are recovering."
			});
		}
		else
		{
			ret.push({
				id = 4,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Rest is the only real cure. Make camp, and pitch it within three tiles of a friendly settlement if you can, because the men recover faster there."
			});
		}

		return ret;
	}

	function onUpdate( _properties )
	{
		this.skill.onUpdate(_properties);

		local m = 1.0;
		try { m = ::Skv.March.mult(); } catch (e) { return; }

		if (m >= 1.0) return;

		_properties.StaminaMult *= m;
	}

});
