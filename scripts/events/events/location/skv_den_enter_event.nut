// ============================================================================
//  skv_den_enter_event  --  the warning at the granary door.
//
//  NO REGISTRATION NEEDED: event_manager.nut:63 enumerates scripts/events/events/
//  recursively and instantiates each; fire(m.OnEnter) resolves by m.ID.
//
//  NO REPEAT SCREEN by design. location.nut:319 onEnter() returns false on the
//  first (unvisited) enter -> suppresses the combat dialog, you get the warning;
//  IsVisited (serialized) is now true, so visit 2 falls through, returns true,
//  and goes straight to the fight. Do NOT call setVisited(false) anywhere here:
//  that re-arms the event, which is exactly what we do not want.
// ============================================================================
this.skv_den_enter_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.location.skv_den_enter";
		this.m.Title = "As you approach...";
		// Keeps it out of the random event pool; fire() reaches it by ID regardless.
		this.m.Cooldown = 999999.0 * this.World.getTime().SecondsPerDay;
		this.m.IsSpecial = true;

		// --- A: the warning -------------------------------------------------
		// %randombrother% / %randombrother2% are available in events (Legends event
		// hook, events/event.nut:89-110). GOTCHA: placeholders are re-rolled on
		// EVERY render, so no screen may reference another screen's cast -- the
		// archer named here is NOT the man named on the Lore screen. A roster of 1
		// renders the same name twice, so the Lore option is gated on len() >= 2 below.
		// IMAGE: event_115 NOT VERIFIED against this scene; eyeball it in game.
		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_115.png[/img]{The track ends at a fence, and the fence has been down a long time. Beyond it a dozen houses stand among the trees with their doors open, gardens gone to seed and nothing at all eating the seed. At the far end of the green squats a granary built of stone, windowless, and the ground before its door is packed flat and bare.\n\nNothing moves. Then everything does. They come out from under the houses and around the ends of them, unhurried, spreading as they come until the green is full of them and the company has halted without being told to. They are enormous. %SKVNAME%%randombrother%%SKVNAME_OFF% has an arrow on the string and has not drawn it.\n\nOne walks out from the rest, sits down in front of the granary door, and looks at you, and speaks.\n\nThe sound is words. Not barking shaped like words. Words, in a tongue not one of you has ever heard, spoken with the ease of a man asking after your health. It goes on a while. Then it stops, and it waits.\n\n%OOC%You do not have the language. You understand it anyway; there is no mistaking it. It has told you to leave, and it is waiting to see whether it must say so twice.%OOC_OFF%}",
			Image = "",
			List = [],
			Characters = [],
			Options = [],

			// start() re-runs every time the screen is shown (incl. when Lore
			// returns "A"), so rebuild Options wholesale from empty to avoid
			// stacking duplicate buttons on re-entry.
			function start( _event )
			{
				this.Options = [];

				// Lore uses two voices; needs two live brothers or placeholders
				// collapse (see the re-roll note on screen A).
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "What do we know about this place?",
						function getResult( _event )
						{
							return "Lore";
						}
					});
				}

				this.Options.push({
					Text = "Fall back. Slowly.",
					function getResult( _event )
					{
						// Renown loss for declining (business reputation, not moral).
						// UNPRICED: 40 is a guess against the guide's renown tiers;
						// read the real ReputationOnVictoryVSLocation in game and retune.
						::World.Assets.addBusinessReputation(-40);

						// !! LOAD-BEARING: faction 0 counts as allied (isAlliedWithPlayer),
						// so an unwarned Den at faction 0 can't be attacked -- the warning
						// is what arms it by setting a hostile faction here. Must NOT be
						// set at spawn: m.AutoAttack (world_state.nut:774) bypasses onEnter,
						// so a hostile-at-spawn Den could be attacked without the warning firing.
						if (this.World.State.getLastLocation() != null)
						{
							this.World.State.getLastLocation().setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID());
						}

						return "Leave";
					}
				});

				this.Options.push({
					Text = "Form up. It only gets to say it once.",
					function getResult( _event )
					{
						// witchhut_enter_event screen "E", verbatim in shape: hand off
						// to the NORMAL location attack against the addTroop garrison
						// (setFaction + showCombatDialog), not startScriptedCombat.
						if (this.World.State.getLastLocation() != null)
						{
							this.World.State.getLastLocation().setAttackable(true);
							this.World.State.getLastLocation().setFaction(this.World.FactionManager.getFactionOfType(this.Const.FactionType.Beasts).getID());
							this.World.Events.showCombatDialog(true, true, true);
						}

						return 0;
					}
				});
			}
		});

		// --- Lore: the count, and the argument about it ----------------------
		this.m.Screens.push({
			ID = "Lore",
			Text = "[img]gfx/ui/events/event_115.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% keeps his eyes on the green while he talks.%SPEECH_ON%This was a village. It had a name. Folk here went north -- all of them, all at once, walked off and left the doors standing. That was years back.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% has not looked away either.%SPEECH_ON%A score of the wolves, near enough. That is the tally the folk carried north with them when they left. My wife's kin had it off a man who ran -- twenty, he said, or thereabouts, and he was not stopping to be sure of it.%SPEECH_OFF%%SKVNAME%%randombrother%%SKVNAME_OFF% does not turn his head.%SPEECH_ON%And did he tell you they talk, this man of yours?%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% looks at him for the first time.%SPEECH_ON%You just heard it.%SPEECH_OFF%Neither of them has looked away from the green.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Enough. Back to it.",
					function getResult( _event )
					{
						// Screen A's start() re-runs and rebuilds Options, so no duplicates.
						return "A";
					}
				}
			],
			function start( _event )
			{
			}
		});

		// --- Leave ------------------------------------------------------------
		// Renown loss is applied in the option's getResult above, not here, so it
		// can never double-fire if this screen is re-entered.
		this.m.Screens.push({
			ID = "Leave",
			Text = "[img]gfx/ui/events/event_115.png[/img]{You give the order and the company gives ground, and the wolves do not follow. They watch you to the fence. They are still watching when the trees close.\n\nIt is a long walk and nobody talks for the first hour of it. By the second, one or two have found a way of telling it that has them in a better light, and by the time you make camp there is a version going round in which the company was never in any danger at all and the thing at the granary door was only a wolf.\n\nThey will tell it in taverns. They will tell it the way men tell a thing they are ashamed of, which is to say often, and badly.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Move out.",
					function getResult( _event )
					{
						return 0;
					}
				}
			],
			function start( _event )
			{
			}
		});
	}

	function onUpdateScore()
	{
	}

	function onPrepare()
	{
	}

	function onPrepareVariables( _vars )
	{
		// Name highlighting: onPrepareVariables is the shipped seam for adding a var,
		// same as Legends' %OOC%; delivering the colour tag by substitution sidesteps
		// the inline-hex caveat. SKV-prefixed to avoid colliding with vanilla/Legends.
		// >>> ONE PLACE TO CHANGE THE NAME COLOUR. <<<
		local nameColor = "#9dbccb";

		_vars.push(["SKVNAME", "[color=" + nameColor + "]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);
	}

	function onDetermineStartScreen()
	{
		return "A";
	}

	function onClear()
	{
	}
});
