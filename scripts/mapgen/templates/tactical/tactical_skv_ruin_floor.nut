// ============================================================================
//  tactical.skv_ruin_floor -- a stone floor to fight on indoors.
//
//  WHY THIS EXISTS. Legends' "tactical.legend_cave" is the right LOOK for a fight
//  inside a building -- dark stone, rubble, bones -- but it walls its arena by
//  brute force:
//
//      if (d > 8 && x > (_rect.X / 4)) tile.Level = 4;
//
//  Every tile more than eight from the centre is raised to level FOUR, which is a
//  cliff. In a cave that is the cave. In a monastery cell it is a thirty-foot
//  escarpment through the middle of the wolf den, and it hands whichever side
//  starts on top a height advantage nobody chose.
//
//  So: the same floor, the same patches, no cliff. Impassable borders still close
//  the arena (that is what walls are), and the ground inside stays level, which is
//  what a flagged floor is.
//
//  ⚠ "tactical.ruins" is NOT a terrain template -- it lives under
//  mapgen/templates/tactical/locations/ and expects _properties.ShiftX, so passing
//  it as TerrainTemplate throws "the index 'ShiftX' does not exist" in
//  tactical_ruins.fill and takes the whole battle down with it. Locations go in
//  LocationTemplate.Template[0]; only real terrain goes in TerrainTemplate.
// ============================================================================
this.tactical_skv_ruin_floor <- this.inherit("scripts/mapgen/tactical_template", {
	m = {},

	function init()
	{
		this.m.Name = "tactical.skv_ruin_floor";
		this.m.MinX = 32;
		this.m.MinY = 32;
	}

	function fill( _rect, _properties, _pass = 1 )
	{
		local stoneTile1 = this.MapGen.get("tactical.tile.stone1");
		local stoneTile2 = this.MapGen.get("tactical.tile.stone2");
		local earthTile1 = this.MapGen.get("tactical.tile.legend_cave1");

		this.addRoads(_rect, _properties);

		// A ruin should be FULL of what fell off it -- but MORE patches means more
		// chances to hit the one failure mode this whole family of templates has:
		//
		//   ⚠ A PATCH CAN DRAW OUTSIDE THE RECT IT IS GIVEN. patch_stone_circle lays a
		//   ring by offsetting from its own centre, and near an edge those offsets run
		//   off the map -- getTileSquare returns null and the fill throws "trying to
		//   set 'null'", taking the battle down during initMap. Legends' cave template
		//   has the same hole; it only survives because it rolls that patch at 10%.
		//
		// So: a margin of four tiles on every side, kept clear of the border, and the
		// ring patch dropped entirely -- stone_sea and the cave patch give the same
		// rubble without reaching outside themselves. And each fill is wrapped, because
		// no cosmetic is worth a crash on the loading screen.
		local templates = [];
		local mainPatch = this.MapGen.get("tactical.patch.legend_cave");
		local clearingPatch = this.MapGen.get("tactical.patch.bones");
		local stoneSea = this.MapGen.get("tactical.patch.stone_sea");

		templates.push(mainPatch);
		templates.push(mainPatch);
		templates.push(mainPatch);
		templates.push(stoneSea);
		templates.push(stoneSea);
		templates.push(clearingPatch);
		templates.push(clearingPatch);

		if (this.Math.rand(1, 100) <= 40)
		{
			templates.push(this.MapGen.get("tactical.patch.dry"));
		}

		local margin = 4;
		local patches = 9;
		while (patches != 0)
		{
			patches = --patches;
			local selectedTemplate = templates[this.Math.rand(0, templates.len() - 1)];
			local sizeX = this.Math.rand(this.Math.min(selectedTemplate.getMinX(), 6), this.Math.min(selectedTemplate.getMaxX(), 14));
			local sizeY = this.Math.rand(this.Math.min(selectedTemplate.getMinY(), 6), this.Math.min(selectedTemplate.getMaxY(), 14));

			local maxX = _rect.X + _rect.W - sizeX - margin;
			local maxY = _rect.Y + _rect.H - sizeY - margin;
			if (maxX <= _rect.X + margin || maxY <= _rect.Y + margin)
			{
				continue;
			}

			local rect = {
				X = this.Math.rand(_rect.X + margin, maxX),
				Y = this.Math.rand(_rect.Y + margin, maxY),
				W = sizeX,
				H = sizeY,
				IsEmpty = this.Math.rand(0, 2) != 2
			};

			try
			{
				selectedTemplate.fill(rect, _properties);
			}
			catch (e)
			{
				::logError("skv_ruin_floor: patch failed, skipped -- " + e);
			}
		}

		// The floor. NO tile.Level is touched anywhere in here -- that is the whole
		// point of the file.
		for( local x = _rect.X; x < _rect.X + _rect.W; x = ++x )
		{
			for( local y = _rect.Y; y < _rect.Y + _rect.H; y = ++y )
			{
				local tile = this.Tactical.getTileSquare(x, y);
				if (tile.Type != 0)
				{
					continue;
				}

				local n = this.Math.rand(1, 100);
				if (n < 50)
				{
					stoneTile1.fill({ X = x, Y = y, W = 1, H = 1, IsEmpty = this.Math.rand(1, 5) != 1 }, _properties);
				}
				else if (n < 90)
				{
					stoneTile2.fill({ X = x, Y = y, W = 1, H = 1, IsEmpty = this.Math.rand(1, 5) != 1 }, _properties);
				}
				else
				{
					earthTile1.fill({ X = x, Y = y, W = 1, H = 1, IsEmpty = this.Math.rand(1, 5) != 1 }, _properties);
				}
			}
		}

		this.makeBordersImpassable(_rect);
	}

});
