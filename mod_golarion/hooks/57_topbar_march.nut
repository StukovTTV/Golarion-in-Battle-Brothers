if ("mods_registerJS" in getroottable())
{
	::mods_registerJS("golarion/hooks/screens/world/modules/world_screen_topbar/world_screen_topbar_assets_module.js");
}
else
{
	::logError("Skv.March: mods_registerJS is missing, so the topbar readout cannot be loaded. The fatigue system itself is unaffected.");
}

if ("mods_registerCSS" in getroottable())
{
	::mods_registerCSS("golarion/hooks/screens/world/modules/world_screen_topbar/world_screen_topbar_assets_module.css");
}

::mods_hookExactClass("ui/screens/world/modules/topbar/world_screen_topbar_datasource_module", function ( o )
{
	o.updateAssetsInformation = function ()
	{
		local data = this.UIDataHelper.convertAssetsInformationToUIData();

		try
		{
			data.GolarionVigour <- ::Skv.March.vigour();
		}
		catch (e)
		{
			data.GolarionVigour <- 100;
		}

		this.m.JSHandle.asyncCall("loadAssetsInformation", data);
	}
});

try
{
	::Skv.Cfg.Mod.Tooltips.setTooltips({
		World = {
			March = ::MSU.Class.BasicTooltip(

				function ()
				{
					return "Marching Vigour";
				},

				function ()
				{
					local vigour = 100;
					local lost = 0;
					local camping = false;
					local nearTown = false;
					local drain = 0.75;
					local recover = 3.0;
					local townMult = 1.5;

					try
					{
						vigour   = ::Skv.March.vigour();
						lost     = ::Math.floor(::Skv.March.pct()).tointeger();
						camping  = ::World.Assets.isCamping();
						nearTown = ::Skv.March.nearTown();
						drain    = ::Skv.March.drain();
						recover  = ::Skv.March.recover();
						townMult = ::Skv.March.townMult();
					}
					catch (e) {}

					local text = "What the company has left in it. Every hour on the march lowers the MAXIMUM fatigue of every man. Nothing else is touched: not their health, not their resolve, not their skill at arms.\n\n";

					if (lost <= 0)
					{
						text = text + "The company is rested. Every man has his full fatigue.\n\n";
					}
					else
					{
						text = text + "Every man is fighting with [color=" + ::Const.UI.Color.NegativeValue + "]" + vigour + "%[/color] of his usual fatigue.\n\n";
					}

					if (camping)
					{
						text = text + "[b]The camp is pitched.[/b] The men are recovering [color=" + ::Const.UI.Color.PositiveValue + "]" + (nearTown ? recover * townMult : recover) + "%[/color] each hour";
						text = text + (nearTown
							? ", and faster than usual: there is a friendly settlement close by, with hot food, a fire somebody else built, and a roof for any man who wants one."
							: ", out in open country.");
						text = text + "\n\n";
					}
					else
					{
						text = text + "[b]On the march.[/b] Losing [color=" + ::Const.UI.Color.NegativeValue + "]" + drain + "%[/color] each hour.\n\nRest is the only real cure. Making camp returns " + recover + "% each hour, or " + (recover * townMult) + "% if the camp is within three tiles of a friendly settlement. A round of drinks in a tavern gives a little back as well, once a day.\n\n";
					}

					text = text + "Time does not pass while you are inside a settlement, so trading and hiring cost nothing.";

					return text;
				}
			)
		}
	});
}
catch (e)
{
	::logError("Skv.March: could not register the topbar tooltip (the readout still works, it just will not explain itself): " + e);
}
