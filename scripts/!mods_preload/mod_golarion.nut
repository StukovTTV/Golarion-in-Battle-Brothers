// ============================================================================
//  Golarion Localization -- name overlay for Battle Brothers Legends.
//  ENTRY FILE ONLY: const/data overrides + class hooks are split into
//  mod_golarion/config (data) and mod_golarion/hooks, loaded by the foreach below.
// ============================================================================

local modID = "mod_golarion";
local modVersion = "0.93.13";  // STRING semver (X.Y.Z), not a float: MSU's registry cross-checks
                               // it against the version mod_hooks recorded and throws if they differ.
local modName = "Golarion Localization";
::mods_registerMod(modID, modVersion, modName);

::mods_queue(modID, "mod_msu, mod_legends", function()
{
	// Shared MSU dial for contract frequency (faction-action m.Score, 0..10). Lives in ::Skv.Cfg.
	::Skv.Cfg.register(modID, modVersion, modName);

	// Load split body: dir is relative to the data root; config before hooks; BB ignores
	// non-scripts dirs. ::include runs each file in this post-(mod_msu, mod_legends) context.
	foreach (dir in [
		"mod_golarion/config",
		"mod_golarion/hooks"
	]) {
		foreach (file in ::IO.enumerateFiles(dir))
			::include(file);
	}
});
