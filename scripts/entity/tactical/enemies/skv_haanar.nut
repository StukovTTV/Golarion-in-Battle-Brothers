this.skv_haanar <- this.inherit("scripts/entity/tactical/human", {
	m = {},
	function create()
	{
		this.m.Type = this.Const.EntityType.Wildman;
		this.m.BloodType = this.Const.BloodType.Red;
		this.m.XP = ::Const.Tactical.Actor.SkvHaanar.XP;
		this.human.create();
		this.setGender(0);
		this.m.Faces = this.Const.Faces.AllMale;
		this.m.Hairs = this.Const.Hair.AllMale;
		this.m.HairColors = this.Const.HairColors.All;
		this.m.Beards = this.Const.Beards.All;
		this.m.AIAgent = this.new("scripts/ai/tactical/agents/skv_troglodyte_caster_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.human.onInit();
		local b = this.m.BaseProperties;
		b.setValues(::Const.Tactical.Actor.SkvHaanar);
		b.IsSpecializedInPolearms = true;
		this.m.ActionPoints = b.ActionPoints;
		this.m.Hitpoints = b.Hitpoints;
		this.m.CurrentProperties = clone b;

		this.m.Faces = this.Const.Faces.AllMale;
		this.m.Hairs = this.Const.Hair.WildMale;
		this.m.HairColors = this.Const.HairColors.Young;
		this.m.Beards = this.Const.Beards.WildExtended;
		this.m.BeardChance = 80;
		this.setAppearance();
		try
		{
			this.getSprite("dirt").Visible = true;
			local body = this.getSprite("body");
			local scar = this.Math.rand(0, 1);
			local tb = this.getSprite("tattoo_body");
			local th = this.getSprite("tattoo_head");
			tb.setBrush((scar == 0 ? "warpaint_01_" : "scar_02_") + body.getBrush().Name);
			tb.Visible = true;
			th.setBrush(scar ? "scar_02_head" : "warpaint_01_head");
			th.Visible = true;
		}
		catch (e)
		{
			::logError("Skv.Haanar: the wild look did not apply (cosmetic only): " + e);
		}

		try
		{
			::Legends.Perks.grant(this, ::Legends.Perk.Dodge);
			::Legends.Perks.grant(this, ::Legends.Perk.Nimble);
		}
		catch (e)
		{
			::logError("Skv.Haanar: could not take Dodge/Nimble: " + e);
		}

		try
		{
			this.m.Skills.add(this.new("scripts/skills/actives/root_skill"));
		}
		catch (e)
		{
			::logError("Skv.Haanar: could not take entangle (root) - he still fights: " + e);
		}

		try
		{
			::Legends.Actives.grant(this, ::Legends.Active.LegendMagicBurningHands, function ( _skill )
			{
				_skill.m.AdditionalAccuracy = 20;
			});
		}
		catch (e)
		{
			::logError("Skv.Haanar: could not take burning hands - he still fights: " + e);
		}

		this.m.Skills.update();
		::Skv.dbg("Skv.Haanar: in. HP " + b.Hitpoints + ", Melee " + b.MeleeSkill + ", Ranged " + b.RangedSkill
			+ " (+20 on burning hands), gender=" + this.m.Gender + ", root + burning hands granted");
	}

	function assignRandomEquipment()
	{
		try
		{
			this.m.Items.equip(this.new("scripts/items/weapons/legend_mystic_staff"));
		}
		catch (e)
		{
			::logError("Skv.Haanar: the Mystic Staff would not equip - burning hands is now UNUSABLE (no MagicStaff): " + e);
		}

		this.m.Items.equip(this.Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Standard.leather_wraps]
		]));
	}

});
