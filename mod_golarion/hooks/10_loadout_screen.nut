::mods_hookExactClass("states/world_state", function ( o )
{
	o.showLoadoutFromContract <- function ()
	{
		if (this.m.CharacterScreen == null || this.isInCharacterScreen()) return false;
		if (this.m.EventScreen == null || !this.m.EventScreen.isVisible() || this.m.EventScreen.isAnimating()) return false;
		if (this.World.Contracts.getActiveContract() == null) return false;

		this.World.Assets.updateFormation();
		this.m.EventScreen.hide();
		this.m.CharacterScreen.show();

		this.m.MenuStack.push(function ()
		{
			this.m.CharacterScreen.hide();
			this.World.Assets.refillAmmo();

			local c = this.World.Contracts.getActiveContract();
			if (c != null)
			{

				this.m.EventScreen.setIsContract(true);

				try
				{
					local cur = c.m.ActiveScreen;
					if (cur != null) c.setScreen(cur.ID);
				}
				catch (e) { ::logError("loadout restore: could not rebuild the contract screen: " + e); }
				this.m.EventScreen.show(c, false);
			}
		},
		function ()
		{

			return !this.m.CharacterScreen.isAnimating();
		});

		return true;
	}
});
