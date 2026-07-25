::mods_hookExactClass("entity/world/settlements/legends_steppe_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.SteppeVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_steppe_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.SteppeFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_mountains_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.MountainsFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_coast_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.CoastFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_fishing_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.FishingVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_mining_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.MiningVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_forest_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.ForestFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_lumber_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.LumberVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_swamp_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.SwampFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_swamp_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.SwampVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_snow_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.SnowVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_snow_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.SnowFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_tundra_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.TundraVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_tundra_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.TundraFort; }
});
::mods_hookExactClass("entity/world/settlements/legends_farming_village", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.FarmingVillage; }
});
::mods_hookExactClass("entity/world/settlements/legends_farm_fort", function(o) {
	local create = o.create;
	o.create = function() { create(); this.m.Names = clone ::GolarionNames.FarmFort; }
});
