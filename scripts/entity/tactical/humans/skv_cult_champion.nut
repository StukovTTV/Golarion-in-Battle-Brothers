// ============================================================================
//  skv_cult_champion  --  the cult leader actor (Golarion Localization).
//
//  A thin subclass of the vanilla cultist. It reuses everything the (Legends-
//  hooked) cultist already is -- stats, perks, blood, AI -- and only changes
//  two things: a distinct leader loadout, and a morale-anchor aura.
//
//  It does NOT need to do anything to "become a champion": its Troops def
//  (Const.World.Spawn.Troops.SkvCultChampion, Variant 200) makes the spawner
//  call makeMiniboss() on it, which grants champion_racial (the stat buff) and
//  a rolled name+title. Legends requires Warriors of the North, so that path is
//  always available. Strength therefore comes from champion_racial + the gear
//  below; identity comes from the name/title (in the Troops def) + this aura.
// ============================================================================
this.skv_cult_champion <- this.inherit("scripts/entity/tactical/humans/cultist", {
	function onInit()
	{
		this.cultist.onInit();   // base + Legends cultist onInit (stats, perks, AI)

		// Leader signature: Captain is a PASSIVE (perk_captain: IsActive = false), so it
		// needs no AI behaviour -- captain_effect lives on human.nut, meaning every
		// cultist already carries the receiving half. Each turn it scans allies within 5
		// tiles; any ally holding perk.captain with HIGHER Bravery grants them
		// min(captainBravery * 0.15, difference) Resolve. Our champion's Bravery is ~121
		// (base ~81 x 1.5 from champion_racial) vs a cultist's ~81, so the cult gets
		// roughly +18 Resolve while he lives -- and it collapses when he dies. That is
		// the boss doing real work with zero code.
		//
		// Do NOT use legend_inspire_skill here: it is an ACTIVE and NO ai behaviour in
		// the game selects it (ai_rally binds rally_the_troops; Legends' ai_boost_stamina
		// hook extends PossibleSkills with the drums/push-forward/hold-the-line family
		// only). It is a player-tree skill -- Legends grants it to legend_peasant_monk
		// where it sits inert, exactly as it would here.
		// This is also the idiom Legends uses for its own bosses (legend_robber_baron,
		// bandit_leader, orc_warlord all grant Perk.Captain); grant() handles the skill
		// update itself, so no Skills.update() call is needed.
		::Legends.Perks.grant(this, ::Legends.Perk.Captain);
	}

	// setupEntity() calls this AFTER makeMiniboss(), so it wins over the base
	// cultist's random flails/robes -- a fixed, recognisable leader kit.
	//
	// IMPORTANT: ARMOUR AND HELMETS MUST COME FROM THE LEGENDS OUTFIT REGISTRY, never from
	// this.new("scripts/items/armor/<vanilla path>"). The base cultist onInit (which
	// we inherit) grants Legends.Perk.LegendSpecCultArmor and LegendSpecCultHood, and
	// BOTH perks do an UNGUARDED `foreach (upgrade in item.m.Upgrades)` on the Body /
	// Head item. `m.Upgrades` is declared only on scripts/items/legend_armor/legend_armor
	// and .../legend_helmets/legend_helmet -- NOT on the vanilla armor/helmet base
	// classes. So a vanilla-path robe throws "the index 'Upgrades' does not exist" the
	// moment the perk updates. pickArmor/pickHelmet resolve a Legends layers object and
	// build the proper legend_armor/legend_helmet instance. (Weapons are exempt: the
	// cult weapon perk doesn't read Upgrades, and the Legends cultist hook itself uses
	// this.new(...) for weapons.)
	function assignRandomEquipment()
	{
		// Top-tier flail: the Legends cultist is IsSpecializedInFlails, so the leader
		// carries the best flail rather than the rank-and-file's wooden ones.
		this.m.Items.equip(this.new("scripts/items/weapons/three_headed_flail"));

		// Always the cult robe (the body rolls a cheaper sackcloth/hide) -- and it keeps
		// the LegendSpecCultArmor resolve bonus live, which is the leader's whole point.
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

	// OPTIONAL (left out on purpose): to give him the visible miniboss "crown"
	// bust, override makeMiniboss to call the base then set a bust brush. Skipped
	// here because the cultist sprite set may not carry a "miniboss" slot, and a
	// missing-slot setBrush can throw. The rolled name+title already marks him.
});
