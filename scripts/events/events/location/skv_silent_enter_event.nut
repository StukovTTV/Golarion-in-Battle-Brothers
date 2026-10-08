this.skv_silent_enter_event <- this.inherit("scripts/events/event", {
	m = {

		Rows = []
	},

	function create()
	{
		this.m.ID = "event.location.skv_silent_enter";
		this.m.Title = "The Silent Nation";

		this.m.Cooldown = 999999.0 * this.World.getTime().SecondsPerDay;
		this.m.IsSpecial = true;
		local img = "[img]gfx/ui/events/event_143.png[/img]";

		this.m.Screens.push({
			ID = "A",
			Text = img + "{The glacier fills the valley from one wall to the other, grey and old, and the wind off it smells of nothing at all. Where the ice has worn thin you can see the dead inside it: men frozen upright in rows, long past saving, the nearest close enough that you could count the rivets on his helm.\n\nAs the company watches, one of the dead turns its head.\n\nThen the ice cracks all around the company at once, a sound like a frozen river breaking up in spring. The ground under the men's boots is ice too, and the dead are pulling free on every side. Deeper in, older shapes stand waiting their turn.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Form up. Put them back in the ice.",
					function getResult( _event )
					{
						return _event.attack();
					}
				},
				{
					Text = "Not today. Back off the ice.",
					function getResult( _event )
					{
						::Skv.Silent.markSeen();
						return 0;
					}
				}
			],
			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Return",
			Text = "",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Form up. Finish what we started.",
					function getResult( _event )
					{
						return _event.attack();
					}
				},
				{
					Text = "Not today. Back off the ice.",
					function getResult( _event )
					{
						return 0;
					}
				}
			],
			function start( _event )
			{

				local S = ::Skv.Silent;
				local n = S.battle();
				local who = n <= 1 ? "The undead stand at the edge of the ice where the company last saw them."
					: n == 2 ? "The bones stand in their ranks on the old blue ice."
					: "At the heart of the glacier the oldest of the dead are waiting, as if they had never moved at all.";
				local more = S.LastBought > 0 ? " More have come loose since the company was last here." : "";
				this.Text = "[img]gfx/ui/events/event_143.png[/img]{The glacier is as the company left it, or nearly. " + who + more + "\n\nEvery day the company stays away, the ice gives up a few more.}";
			}
		});

		this.m.Screens.push({
			ID = "Won1",
			Text = img + "{The last of the risen dead goes down in the snow and stays there. For a moment there is only the sound of the company breathing.\n\nThen the ice cracks again, all around the company, deeper this time. Where the glacier is old and blue, something is pulling free, and what comes out of it is bone. These did not die last winter. These have been dead a very long time.\n\nThere is no time to see to the wounded, and no time to change a blade. Falling back now would leave the rest of them to the thaw.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Onward. Hold the line.",
					function getResult( _event )
					{
						return _event.onward();
					}
				},
				{
					Text = "Fall back while we still can.",
					function getResult( _event )
					{
						return _event.fallBack();
					}
				}
			],
			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Won2",
			Text = img + "{The skeletons break apart on the ice, and the pieces lie where they fall. The company stands among them, breathing hard, bleeding, counting heads.\n\nFrom the heart of the glacier comes a sound like a great door opening. What walks out of it wears the remains of rank: a crown of rust, a banner of rags, armour no smith alive could name. The ice gives way on every side, and out of it come its chosen, the oldest and the worst of everything the glacier was holding.\n\nIf the company means to finish this, it is now. Falling back would leave them to the thaw.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Onward. End it.",
					function getResult( _event )
					{
						return _event.onward();
					}
				},
				{
					Text = "Fall back while we still can.",
					function getResult( _event )
					{
						return _event.fallBack();
					}
				}
			],
			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Won3",
			Text = img + "{It is over. The last of them falls, and this time the ice does not answer. The quiet that follows is a different kind of quiet, the kind that belongs to a field after a battle and not before one.\n\nThe men stand among the dead and do not quite believe it.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Let them rest.",
					function getResult( _event )
					{
						::Skv.Silent.commitGear();
						_event.m.Rows = ::Skv.Silent.claim();
						return "Rest";
					}
				}
			],
			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Quiet",
			Text = img + "{The field is as the company left it. The dead lie still on the ice, and nothing new has come out of it.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Send for a priest.",
					function getResult( _event )
					{
						_event.m.Rows = ::Skv.Silent.claim();
						return "Rest";
					}
				}
			],
			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Rest",
			Text = img + "{By the next morning a cleric of Pharasma has come up from the nearest town: a grey woman with a staff and a spiral at her throat, and two boys with shovels who will not look at the ice. She walks the length of the field without a word. Then she kneels and speaks the rites, and the wind drops while she does it.\n\nWhen she rises she says the ground is consecrated, and that what lies here will stay where it lies. She takes nothing for it. The company takes what the dead were carrying, which they will not be needing, and the story, which every tavern from here to the sea will want to hear.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Leave the dead to her.",
					function getResult( _event )
					{
						return 0;
					}
				}
			],
			function start( _event )
			{
				this.List = _event.m.Rows;
			}
		});

		this.m.Screens.push({
			ID = "Fled",
			Text = img + "{The company gives ground, then gives more, and then it is simply running, back off the ice and into the snow. The dead do not follow past the edge of the glacier. They stand there in a line and watch the company go.\n\nThe ones the company put down stay down. But behind the line the ice is groaning, and now it will give up the rest of them faster than before.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Get clear.",
					function getResult( _event )
					{
						return _event.fled();
					}
				}
			],
			function start( _event )
			{
			}
		});
	}

	function attack()
	{
		local site = ::Skv.Silent.findSite();

		if (site == null)
		{
			::logError("Skv.Silent: Attack with no site on the map.");
			return 0;
		}

		::Skv.Silent.markSeen();
		::Skv.Silent.fight(this, site);
		return 0;
	}

	function onward()
	{
		local site = ::Skv.Silent.findSite();

		if (site == null)
		{
			::logError("Skv.Silent: Onward with no site on the map.");
			return 0;
		}

		::Skv.Silent.commitGear();
		::Skv.Silent.nextHost(site);
		::Skv.Silent.fight(this, site);
		return 0;
	}

	function fallBack()
	{
		::Skv.Silent.commitGear();
		local site = ::Skv.Silent.findSite();
		if (site != null) ::Skv.Silent.nextHost(site);
		::Skv.Silent.recordRetreat();
		return 0;
	}

	function fled()
	{
		local S = ::Skv.Silent;
		local site = S.findSite();

		S.Pending = [];
		S.Held = {};

		if (site != null && site.getTroops().len() == 0)
		{
			::logInfo("Skv.Silent: the company fled, but every one of host " + S.battle() + "'s own dead was already down; the host counts as beaten.");
			if (S.battle() < 3) S.nextHost(site);
		}

		S.recordRetreat();
		return 0;
	}

	function onUpdateScore()
	{
	}

	function onPrepare()
	{
	}

	function onPrepareVariables( _vars )
	{
	}

	function onDetermineStartScreen()
	{
		local S = ::Skv.Silent;
		local site = S.findSite();
		if (site == null) return "A";
		if (S.isBeaten(site)) return "Quiet";
		if (!S.seen()) return "A";
		return "Return";
	}

	function onClear()
	{
		this.m.Rows = [];
	}
});
