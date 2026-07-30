this.skv_den_enter_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.location.skv_den_enter";
		this.m.Title = "As you approach...";

		this.m.Cooldown = 999999.0 * this.World.getTime().SecondsPerDay;
		this.m.IsSpecial = true;

		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_115.png[/img]{The track ends at a fence, and the fence has been down a long time. Beyond it a dozen houses stand among the trees with their doors open, gardens gone to seed and nothing at all eating the seed. At the far end of the green squats a granary built of stone, windowless, and the ground before its door is packed flat and bare.\n\nNothing moves. Then everything does. They come out from under the houses and around the ends of them, unhurried, spreading as they come until the green is full of them and the company has halted without being told to. They are enormous. %SKVNAME%%randombrother%%SKVNAME_OFF% has an arrow on the string and has not drawn it.\n\nOne walks out from the rest, sits down in front of the granary door, and looks at you, and speaks.\n\nThe sound is words. Not barking shaped like words. Words, in a tongue not one of you has ever heard, spoken with the ease of a man asking after your health. It goes on a while. Then it stops, and it waits.\n\n%OOC%You do not have the language. You understand it anyway; there is no mistaking it. It has told you to leave, and it is waiting to see whether it must say so twice.%OOC_OFF%}",
			Image = "",
			List = [],
			Characters = [],
			Options = [],

			function start( _event )
			{
				this.Options = [];

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

						::World.Assets.addBusinessReputation(-40);

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

		this.m.Screens.push({
			ID = "Lore",
			Text = "[img]gfx/ui/events/event_115.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% keeps his eyes on the green while he talks.%SPEECH_ON%This was a village. It had a name. Folk here went north - all of them, all at once, walked off and left the doors standing. That was years back.%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% has not looked away either.%SPEECH_ON%A score of the wolves, near enough. That is the tally the folk carried north with them when they left. My wife's kin had it off a man who ran - twenty, he said, or thereabouts, and he was not stopping to be sure of it.%SPEECH_OFF%%SKVNAME%%randombrother%%SKVNAME_OFF% does not turn his head.%SPEECH_ON%And did he tell you they talk, this man of yours?%SPEECH_OFF%%SKVNAME%%randombrother2%%SKVNAME_OFF% looks at him for the first time.%SPEECH_ON%You just heard it.%SPEECH_OFF%Neither of them has looked away from the green.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Enough. Back to it.",
					function getResult( _event )
					{

						return "A";
					}
				}
			],
			function start( _event )
			{
			}
		});

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
