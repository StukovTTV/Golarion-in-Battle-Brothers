local modID = "mod_golarion";
local modVersion = "0.96.37";

local modName = "Golarion Localization";
::mods_registerMod(modID, modVersion, modName);

::mods_queue(modID, "mod_msu, mod_legends", function()
{

	::Skv.Cfg.register(modID, modVersion, modName);

	foreach (dir in [
		"mod_golarion/config",
		"mod_golarion/hooks"
	]) {
		foreach (file in ::IO.enumerateFiles(dir))
			::include(file);
	}
});
