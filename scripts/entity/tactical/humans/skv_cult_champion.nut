// ============================================================================
//  skv_cult_champion  --  the cult leader actor (Golarion Localization).
//
//  Thin subclass of the vanilla (Legends-hooked) cultist. Changes only a leader
//  loadout and a morale-anchor aura. Its Troops def (Variant 200) makes the
//  spawner call makeMiniboss() -> champion_racial + a rolled name+title.
// ============================================================================
this.skv_cult_champion <- this.inherit("scripts/entity/tactical/humans/cultist", {
	function onInit()
	{
		this.cultist.onInit();   // base + Legends cultist onInit (stats, perks, AI)

		// Leader signature: Captain is a PASSIVE (captain_effect on human.nut), so it
		// needs no AI behaviour -- it grants nearby allies Resolve while he lives and
		// collapses when he dies. Do NOT use legend_inspire_skill here: it is an ACTIVE
		// and no AI behaviour selects it, so it sits inert. grant() handles the skill
		// update, so no Skills.update() call is needed.
		::Legends.Perks.grant(this, ::Legends.Perk.Captain);
	}

	// setupEntity() calls this AFTER makeMiniboss(), so it wins over the base
	// cultist's random flails/robes -- a fixed, recognisable leader kit.
	//
	// IMPORTANT: ARMOUR AND HELMETS MUST COME FROM THE LEGENDS OUTFIT REGISTRY
	// (pickArmor/pickHelmet), never this.new("scripts/items/armor/<vanilla path>").
	// The inherited cultist LegendSpecCultArmor/LegendSpecCultHood perks do an
	// unguarded foreach over item.m.Upgrades, which exists only on legend_armor/
	// legend_helmet -- a vanilla-path robe throws "the index 'Upgrades' does not
	// exist". (Weapons are exempt: the cult weapon perk doesn't read Upgrades.)
	function assignRandomEquipment()
	{
		// Top-tier flail (the Legends cultist is IsSpecializedInFlails).
		this.m.Items.equip(this.new("scripts/items/weapons/three_headed_flail"));

		// Always the cult robe -- keeps the LegendSpecCultArmor resolve bonus live.
		local armor = ::Const.World.Common.pickArmor([
			[1, ::Legends.Armor.Standard.cultist_leather_robe]
		]);
		if (armor != null)
		{
			this.m.Items.equip(armor);
		}

		local helmet = ::Const.World.Common.pickHelmet([
			[1, ::Legends.Helmet.Standard.cultist_hood]
		]);
		if (helmet != null)
		{
			this.m.Items.equip(helmet);
		}
	}

	// No makeMiniboss override for a "crown" bust: the cultist sprite set may lack
	// a "miniboss" slot and a missing-slot setBrush can throw. Name+title marks him.
});
