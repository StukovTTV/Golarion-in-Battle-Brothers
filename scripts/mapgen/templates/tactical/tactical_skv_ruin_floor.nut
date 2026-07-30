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
				::logError("skv_ruin_floor: patch failed, skipped - " + e);
			}
		}

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
