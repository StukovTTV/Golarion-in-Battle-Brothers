/*
 *  Golarion Localization -- march fatigue readout in the world assets bar.
 *
 *  Adds a sixth figure, to the right of the medicines, showing how much the company has
 *  left in it. The Squirrel half is mod_golarion/hooks/57_topbar_march.nut, which puts
 *  the number into the topbar payload as GolarionVigour and registers the tooltip. The
 *  stylesheet beside this file re-spaces all six slots so they fit inside the frame.
 *
 *  ⚠⚠⚠ PATCHING onAssetsInformation ON THE PROTOTYPE DOES NOTHING. THIS COST TWO BUILDS.
 *  The base module binds its own listener IN ITS CONSTRUCTOR:
 *
 *      WorldScreenTopbarAssetsModule.prototype.registerDatasourceListener = function() {
 *          this.mDataSource.addListener(..., jQuery.proxy(this.onAssetsInformation, this));
 *      };
 *
 *  jQuery.proxy resolves this.onAssetsInformation THERE AND THEN and keeps that exact
 *  function object forever. The world screen and its modules are constructed by
 *  registerScreens() on $(document).ready, while mod_hooks does not inject mod scripts
 *  until MainMenuScreen.onConnection, which is later. So by the time we can patch the
 *  prototype the listener already holds the ORIGINAL function and a replacement on the
 *  prototype is never called again.
 *
 *  That is precisely the shape of the bug we shipped: createDIV and bindTooltips are
 *  called later still, when the world screen shows itself, so the patched versions of
 *  THOSE do run. Icon present, tooltip working, number never updating. If a topbar patch
 *  ever half-works like that again, this is the first thing to suspect.
 *
 *  So we add a listener of our own instead, from inside createDIV, and touch only our own
 *  label. The vanilla five keep their original listener and are not disturbed.
 *
 *  ⚠ ES5 ONLY. The game's browser is an old Coherent build: no let, no const, no arrows,
 *  no template strings.
 */
"use strict";

(function ()
{
	if (typeof WorldScreenTopbarAssetsModule === 'undefined')
	{
		console.error('Golarion: WorldScreenTopbarAssetsModule not found, march fatigue readout disabled.');
		return;
	}

	var proto = WorldScreenTopbarAssetsModule.prototype;

	/*
	 *  Paint our label. Called from our own datasource listener and once directly when
	 *  the DIV is built, so the figure is correct the moment the bar appears rather than
	 *  blank until the next refresh.
	 *
	 *  We do not reuse the base updateAssetValue. It is built for a stock counter: it
	 *  flashes the difference and turns red only at zero or below. Neither fits a figure
	 *  that starts at its best value and falls.
	 */
	proto.updateGolarionMarch = function (_data)
	{
		if (this.mGolarionMarchButton === undefined || this.mGolarionMarchButton === null)
		{
			return;
		}

		if (_data === undefined || _data === null || typeof(_data) !== 'object')
		{
			return;
		}

		var current = _data.current;

		if (current === undefined || current === null)
		{
			return;
		}

		var label = this.mGolarionMarchButton.find('.label:first');

		if (label.length === 0)
		{
			return;
		}

		/*
		 *  A VISIBLE PLACEHOLDER RATHER THAN A SILENT RETURN. Three things can go wrong
		 *  here and two of them look identical on screen: the key never reached the UI, or
		 *  the label is not being drawn at all. "--" means the data did not arrive.
		 *  Nothing at all means this function is not running.
		 */
		if (!('GolarionVigour' in current) || current.GolarionVigour === null)
		{
			label.html('--');
			return;
		}

		var value = current.GolarionVigour;
		label.html(value + '%');

		/*
		 *  FOUR BANDS, NOT TWO. The stock pair of asset colours is amber for "fine" and
		 *  red for "at or below zero", which suits a stock of arrows and not a figure that
		 *  slides from best to worst: 99 came out as red as 20, so the bar shouted before
		 *  there was anything to shout about and had nothing left to say later.
		 *
		 *  We strip BOTH vanilla classes every time. createImageButton puts
		 *  font-color-assets-positive-value on the label when it builds it, and those rules
		 *  carry !important, so leaving one attached would beat anything we add.
		 */
		label.removeClass('font-color-assets-positive-value font-color-assets-negative-value');
		label.removeClass('golarion-march-good golarion-march-fair golarion-march-poor golarion-march-bad');

		if (value >= 95)
		{
			label.addClass('golarion-march-good');
		}
		else if (value >= 85)
		{
			label.addClass('golarion-march-fair');
		}
		else if (value >= 70)
		{
			label.addClass('golarion-march-poor');
		}
		else
		{
			label.addClass('golarion-march-bad');
		}
	};

	var createDIV = proto.createDIV;
	proto.createDIV = function (_parentDiv)
	{
		createDIV.call(this, _parentDiv);

		var assetContainer = $('<div class="asset-container is-golarion-march has-frame"></div>');
		this.mContainer.append(assetContainer);
		this.mGolarionMarchButton = this.createImageButton(assetContainer, Path.GFX + 'ui/icons/fatigue.png');

		/*
		 *  ⚠ ONCE PER MODULE, NOT ONCE PER createDIV. The module instance outlives the
		 *  DIVs: createDIV and destroyDIV run every time the world screen is shown and
		 *  hidden, while the datasource and its listener list persist for the session.
		 *  Without this flag every trip to a town screen and back would add another
		 *  listener.
		 */
		if (this.mGolarionMarchListenerBound !== true)
		{
			var self = this;

			this.mDataSource.addListener(
				WorldScreenTopbarDatasourceIdentifier.AssetsInformation.Updated,
				function (_datasource, _data)
				{
					self.updateGolarionMarch(_data);
				});

			this.mGolarionMarchListenerBound = true;
		}

		// Paint immediately from whatever the datasource already holds, so the number is
		// there on the first frame instead of after the next hourly refresh.
		try
		{
			this.updateGolarionMarch({ current: this.mDataSource.getAssetsInformation(), previous: null });
		}
		catch (e)
		{
		}
	};

	var destroyDIV = proto.destroyDIV;
	proto.destroyDIV = function ()
	{
		if (this.mGolarionMarchButton !== undefined && this.mGolarionMarchButton !== null)
		{
			this.mGolarionMarchButton.remove();
			this.mGolarionMarchButton = null;
		}

		// ⚠ OURS COMES OFF FIRST. The original empties and removes mContainer, so a button
		// still parented to it would be torn away and left dangling in this object.
		destroyDIV.call(this);
	};

	var bindTooltips = proto.bindTooltips;
	proto.bindTooltips = function ()
	{
		bindTooltips.call(this);

		if (this.mGolarionMarchButton !== undefined && this.mGolarionMarchButton !== null)
		{
			this.mGolarionMarchButton.bindTooltip({
				contentType: 'msu-generic',
				modId: 'mod_golarion',
				elementId: 'World.March'
			});
		}
	};

	var unbindTooltips = proto.unbindTooltips;
	proto.unbindTooltips = function ()
	{
		if (this.mGolarionMarchButton !== undefined && this.mGolarionMarchButton !== null)
		{
			this.mGolarionMarchButton.unbindTooltip();
		}

		unbindTooltips.call(this);
	};
})();
