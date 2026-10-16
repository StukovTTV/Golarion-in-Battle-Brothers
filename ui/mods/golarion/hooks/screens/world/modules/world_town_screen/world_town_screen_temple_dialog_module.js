/*
 *  Golarion Localization -- a "Buy" button on the temple's screen (the item pass, step 5,
 *  1.8.28; docs/item_pass_plan.md §6.4, §6.5). It opens the temple's own shelf of potions in
 *  the game's shop dialog. The Squirrel half is mod_golarion/hooks/74_temple_shop.nut: the
 *  temple's stash, its stock, the buy-only rule, and onGolarionBuy, which this button calls.
 *  The stylesheet beside this file places the button in the footer, left of Leave.
 *
 *  ⭐ WHY createDIV CAN BE PATCHED HERE (and the topbar's listener could not, see
 *  world_screen_topbar_assets_module.js): the temple module binds nothing to its prototype in
 *  its constructor, and its createDIV runs only when the town screen registers its modules
 *  (WorldTownScreen.onConnection -> register -> create -> registerModules, world_town_screen.js
 *  :44-48, :128-139, :154-158). That connection is made by the Squirrel town screen's create()
 *  (UI.connect, world_town_screen.nut:126), once a campaign is loaded, well after mod_hooks has
 *  injected this file at the main menu.
 *
 *  ⚠ ES5 ONLY. The game's browser is an old Coherent build: no let, no const, no arrows,
 *  no template strings.
 */
"use strict";

(function ()
{
	if (typeof WorldTownScreenTempleDialogModule === 'undefined')
	{
		console.error('Golarion: WorldTownScreenTempleDialogModule not found, the temple Buy button is disabled.');
		return;
	}

	var proto = WorldTownScreenTempleDialogModule.prototype;

	var createDIV = proto.createDIV;
	proto.createDIV = function (_parentDiv)
	{
		createDIV.call(this, _parentDiv);

		var self = this;
		var layout = $('<div class="golarion-temple-buy-button"/>');
		this.mDialogContainer.findDialogFooterContainer().append(layout);
		this.mGolarionBuyButton = layout.createTextButton('Buy', function ()
		{
			SQ.call(self.mSQHandle, 'onGolarionBuy');
		}, '', 1);
	};

	var destroyDIV = proto.destroyDIV;
	proto.destroyDIV = function ()
	{
		// ⚠ OURS COMES OFF FIRST: the original empties and removes the dialog container.
		if (this.mGolarionBuyButton !== undefined && this.mGolarionBuyButton !== null)
		{
			this.mGolarionBuyButton.remove();
			this.mGolarionBuyButton = null;
		}

		destroyDIV.call(this);
	};
})();
