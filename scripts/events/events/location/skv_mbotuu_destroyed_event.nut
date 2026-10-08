this.skv_mbotuu_destroyed_event <- this.inherit("scripts/events/event", {
	m = {
		Rows = []
	},

	function create()
	{
		this.m.ID = "event.location.skv_mbotuu_destroyed";
		this.m.Title = "M'botuu";
		this.m.Cooldown = 999999.0 * this.World.getTime().SecondsPerDay;
		this.m.IsSpecial = true;
		local img = "[img]gfx/ui/events/event_09.png[/img]";

		this.m.Screens.push({
			ID = "A",
			Text = img + "{When it is over, M'botuu is quiet in a way a village should never be. The huts burn low over the water and the smoke lies flat across the reeds. Whatever was small enough to run has already gone into the marsh, and the black water closes over everything else.\n\nSepoko's staff lies snapped in the mud. Nobody picks it up. The men do not talk much on the way out.}",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Count what it cost.",
					function getResult( _event )
					{
						_event.m.Rows = ::Skv.Mbotuu.LastRows;
						return "B";
					}
				}
			],
			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "B",
			Text = "",
			Image = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Leave the marsh behind.",
					function getResult( _event )
					{
						return 0;
					}
				}
			],

			function start( _event )
			{
				this.List = _event.m.Rows;
				local tumbled = false;

				foreach (r in _event.m.Rows)
				{
					if (("icon" in r) && r.icon == "ui/perks/tumble_circle.png") tumbled = true;
				}

				local learned = tumbled ?" But not all of what it brought out of the swamp was plunder. The frog-folk fought like nothing the men had faced: down and aside and back again before a blow could land, and one of the brothers watched closely enough to learn the trick of it." : "";
				this.Text = "[img]gfx/ui/events/event_09.png[/img]{Word of M'botuu will travel, and nobody will tell it kindly." + learned + "}";
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
	}

	function onDetermineStartScreen()
	{
		return "A";
	}

	function onClear()
	{
		this.m.Rows = [];
	}
});
