// ============================================================================
//  skv_tatzlwyrm_bite_skill -- the whelp's bite.
//
//  The stock serpent bite is a very big set of jaws: its onUpdate adds a flat
//  +50 / +70 to the wielder's regular damage, keeps 0.75 armour effectiveness
//  and 0.3 direct damage, and costs 5 AP / 5 fatigue. On a beast that is meant
//  to swallow a man whole, fair enough. On a tatzlwyrm it is too much: the
//  module's is a CR 2 dragon whelp that bites for 1d6+3 and would rather grab
//  you and breathe in your face, and our version is already de-tuned everywhere
//  else (95 HP behind 20/20 against the serpent's 130 behind 40/40).
//
//  So: the same bite, a third smaller. This overrides onUpdate rather than
//  restating the numbers, so anything else the base skill does -- the armour
//  multiplier, the direct-damage share, the injury tables -- keeps flowing
//  through untouched, and a vanilla patch to the serpent's bite flows through
//  with it.
//
//  It is fitted in skv_tatzlwyrm.onInit(), which removes "actives.serpent_bite"
//  and adds this in its place.
// ============================================================================
this.skv_tatzlwyrm_bite_skill <- this.inherit("scripts/skills/actives/serpent_bite_skill", {
	m = {},

	function create()
	{
		this.serpent_bite_skill.create();
		this.m.Name = "Bite";
		this.m.Description = "Snap at an adjacent target. A tatzlwyrm is a small dragon with a small dragon's jaws -- less than a great serpent brings, and quite enough for an unarmoured throat.";
	}

	function onUpdate( _properties )
	{
		this.serpent_bite_skill.onUpdate(_properties);

		// -17 / -24 against the base skill's +50 / +70 -> 33-46 instead of 50-70,
		// about a third off the top end. Subtracted rather than assigned so the
		// wielder's own damage properties still count for whatever they are worth.
		_properties.DamageRegularMin -= 17;
		_properties.DamageRegularMax -= 24;
	}

});
