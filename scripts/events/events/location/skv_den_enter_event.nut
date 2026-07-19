// ============================================================================
//  skv_den_enter_event  --  the warning at the granary door.
//
//  NO REGISTRATION NEEDED. event_manager.nut:63 does
//  IO.enumerateFiles("scripts/events/events/") and instantiates every script it
//  finds, recursively. Drop the file at this path with a unique m.ID and
//  World.Events.fire(m.OnEnter) resolves it by ID. Legends does the same with
//  its own net-new events under scripts/events/events/legends/.
//
//  WHY THERE IS NO REPEAT SCREEN -- the good part. location.nut:319:
//      function onEnter() {
//          if (!this.m.IsVisited && this.m.OnEnter != null) {
//              this.m.IsVisited = true;
//              this.World.Events.fire(this.m.OnEnter);
//              return false;                      // <-- suppresses the combat dialog
//          } ...
//          this.m.IsVisited = true; return true;  // <-- lets it through
//      }
//  and world_state.nut:1212 `if (_location.onEnter()) { ... else if
//  (_location.isAttackable() && !isAlliedWithPlayer()) showCombatDialog(); }`.
//
//  So: visit 1, not visited -> event fires, returns false, NO combat dialog. You
//  get the warning. IsVisited is now true AND IS SERIALIZED (location.nut:710,
//  writeBool/readBool), so it survives save/load. Visit 2, whatever happened --
//  you left, you lost, you fled -- onEnter() falls through, returns true,
//  isAttackable() is true, and you go STRAIGHT TO THE FIGHT.
//
//  "No more warning" therefore costs zero code and needs no flag. Doing nothing
//  IS the feature. Do NOT call setVisited(false) anywhere in this file: that is
//  the abandoned village's idiom for re-arming its event, and re-arming is
//  exactly what we do not want. It has told you once. It said it would not say it
//  twice. The engine keeps its word for us.
// ============================================================================
this.skv_den_enter_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.location.skv_den_enter";
		this.m.Title = "As you approach...";
		// Keeps it out of the random event pool entirely; fire() reaches it by ID
		// regardless of cooldown. Both vanilla location enter events do this.
		this.m.Cooldown = 999999.0 * this.World.getTime().SecondsPerDay;
		this.m.IsSpecial = true;

		// --- A: the warning -------------------------------------------------
		// %randombrother% / %randombrother2% ARE available in events, not just
		// contracts -- Legends' own hook on abandoned_village_enter_event writes
		// %randombrother%, %randombrother2% and %their_randombrother% into its
		// Victory text.
		//
		// The "both render 'unknown' under a roster of 2" caveat is the CONTRACT
		// path and does NOT apply here. The EVENT path (legends hook
		// events/event.nut:89-110) picks bro1, removes it from the pool, then falls
		// back bro2 = a slave, else the player character, else bro1 itself. A roster
		// of 1 therefore renders the SAME name twice -- a man talking to himself,
		// not the string "unknown". Still worth avoiding, which is why the Lore
		// option is gated on len() >= 2 in start() below.
		//
		// AND NOTE: the placeholders are re-rolled on EVERY render -- setScreen
		// clones the screen and runs buildText on the clone (events/event.nut:126,
		// 153). No screen may reference another screen's cast. The archer named
		// here is NOT the man named on the Lore screen.
		//
		// IMAGE: event_115 is what witchhut_enter uses for "you stop in a forest
		// clearing, a structure ahead" -- tonally the closest shipped frame I can
		// point at. NOT VERIFIED against this scene. Eyeball it in game.
		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_115.png[/img]{The track ends at a fence, and the fence has been down a long time. Beyond it a dozen houses stand among the trees with their doors open, gardens gone to seed and nothing at all eating the seed. At the far end of the green squats a granary built of stone, windowless, and the ground before its door is packed flat and bare.\n\nNothing moves. Then everything does. They come out from under the houses and around the ends of them, unhurried, spreading as they come until the green is full of them and the company has halted without being told to. They are enormous. %SKVNAME%%randombrother%%SKVNAME_OFF% has an arrow on the string and has not drawn it.\n\nOne walks out from the rest, sits down in front of the granary door, and looks at you, and speaks.\n\nThe sound is words. Not barking shaped like words. Words, in a tongue not one of you has ever heard, spoken with the ease of a man asking after your health. It goes on a while. Then it stops, and it waits.\n\n%OOC%You do not have the language. You understand it anyway; there is no mistaking it. It has told you to leave, and it is waiting to see whether it must say so twice.%OOC_OFF%}",
			Image = "",
			List = [],
			Characters = [],
			Options = [],

			// REBUILT WHOLESALE FROM EMPTY. start() re-runs every time the screen
			// is shown -- including when Lore returns "A" -- so a naive push
			// stacks a duplicate button on re-entry. Declare Options = [] above
			// and rebuild here. This is the same idempotency rule the contract
			// screens live under; vanilla's abandoned village does the identical
			// wholesale reassign in its own repeat-screen start().
			function start( _event )
			{
				this.Options = [];

				// The knowledge exists in the world, held by specific men, and it
				// is there if you ask. Nobody hands it to you for being the
				// protagonist. Two voices, not one, because the knowledge SPLITS:
				// one man has the frame, the other the count, and they disagree
				// about the third thing. Needs two live brothers or both
				// placeholders render "unknown".
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
						// Renown, not moral reputation. This story is nerve and
						// competence; mercy has nothing to do with it, and the
						// moral meter would be a stake the fiction does not have.
						//
						// The engine already pays the positive half by itself --
						// tactical_state.nut:1874 fires
						// addBusinessReputation(Const.World.Assets.ReputationOnVictoryVSLocation)
						// on beating a location, with ReputationOnLoss at :1988.
						// Winning and losing are priced; DECLINING is not. This is
						// the missing third case, and no location enter event in
						// the game -- vanilla or Legends -- touches renown. First
						// use. Small, but net-new.
						//
						// !! UNPRICED !! Const.World.Assets is in neither the
						// Legends repo nor the decompile, so ReputationOnVictoryVSLocation's
						// value is unknown and this number cannot be balanced
						// against it on paper. 40 is a guess against the guide's
						// renown tiers (~350 early / ~800 mid / ~1200 high).
						// Read the real constant in game and retune.
						::World.Assets.addBusinessReputation(-40);

						// !! LOAD-BEARING. Without this the Den is inert forever. !!
						//
						// world_entity.nut:158-161:
						//     function isAlliedWithPlayer() {
						//         return this.getFaction() == 0 || ... }
						// FACTION 0 COUNTS AS ALLIED. The location never sets a
						// faction at spawn, so until something does, getFaction() is 0.
						//
						// world_state.nut:1212 is the only door in:
						//     if (_location.onEnter()) {
						//         if (isEnterable()) showTownScreen();
						//         else if (isAttackable() && !isAlliedWithPlayer())
						//             showCombatDialog();
						//     }
						// Visit 2: onEnter() falls through and returns true,
						// IsAttackable is true -- but isAlliedWithPlayer() is ALSO
						// true on faction 0, so the guard fails and NOTHING HAPPENS.
						// You walk onto the Den and it does not exist. Reported in
						// game, and correctly.
						//
						// So the WARNING is what arms it, and that is exactly right:
						// the Den is not hostile until it has told you to leave.
						// Both exits from screen A set the faction -- "Form up" does
						// it below, and this does it here.
						//
						// It must NOT be set at spawn. m.AutoAttack (world_state.nut:774)
						// is a SEPARATE path that never calls onEnter(), so a hostile-
						// at-spawn Den could be right-clicked and attacked with the
						// warning never firing. Neutral-until-warned closes that door:
						// with no hostile faction there is no attack order to give.
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
						// witchhut_enter_event screen "E", verbatim in shape. This
						// is how an enter event hands off to the NORMAL location
						// attack against the location's own addTroop garrison --
						// NOT startScriptedCombat, NOT custom combat properties.
						// (buildEventCombatProperties is not an engine API at all;
						// it is a local helper inside abandoned_village_enter_event,
						// which needs it precisely because that location has no
						// garrison to fight.)
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
		// Canon gives a Population of 20 and says the survivors moved north. So
		// there is an answer to who counted: the people who ran. "About twenty"
		// is a refugee's number -- approximate because the man giving it did not
		// stay to be sure. The imprecision is characterisation, not a gap.
		//
		// The refusal at the end is the reason to use two voices instead of one.
		// The player has ALREADY heard the thing speak on screen A, so the denial
		// is not information being withheld -- it is a frightened man refusing
		// what is in front of him, and it is silent, which is better than an
		// argument. It also makes the count credible by contrast: he will take the
		// number and not the story.
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
						// Returns the ID; screen A's start() re-runs and rebuilds
						// its Options from empty, so no duplicate buttons. The
						// offer is untouched -- leave and fight both still work.
						return "A";
					}
				}
			],
			function start( _event )
			{
			}
		});

		// --- Leave: what the renown loss actually is -------------------------
		// The cost is not "you did not fight". It is that you walked all that way
		// and your own twenty men watched you turn around, and renown is exactly
		// what men say about you in taverns. The loss is applied in the option's
		// getResult above rather than here, so it can never double-fire if this
		// screen is somehow re-entered.
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
		// Name highlighting. Legends' %OOC% is nothing but a var that expands to a
		// colour tag (mod_legends/hooks/events/event.nut:230-236, "OOC" ->
		// "[color=#f6eedb]"), and THIS is the shipped seam for adding your own: it
		// runs on every buildText, immediately before buildTextFromTemplate (same
		// file, :282-291).
		//
		// Delivering the tag BY SUBSTITUTION also sidesteps the inline-hex caveat in
		// the authoring guide -- what lands in the final string is character-for-
		// character the tag SPEECH_ON injects, and that one demonstrably renders.
		//
		// Why a name gets a COOL colour: every colour the game already spends is a
		// warm earth tone -- body #bd9d71, speech #bcad8c, OOC #f6eedb (all sampled
		// from a real screenshot). Speech sits only ~12/255 luminance off the body
		// text, so the engine's own dialogue cue barely reads. A blue separates by
		// HUE instead of brightness, which is the one axis nothing else is using.
		//
		// SKV-prefixed so it can never collide with a vanilla or Legends var name.
		//
		// >>> ONE PLACE TO CHANGE THE NAME COLOUR. <<<
		//     #4cc5f0  XCOM cyan, unmuted
		//     #7fc0de  tempered
		//     #9dbccb  muted steel, closest to BB's own register  <- current
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
