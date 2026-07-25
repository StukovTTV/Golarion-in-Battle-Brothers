// ---- Loadout-from-contract -------------------------------------------------
// Open the character/gear screen from inside a contract crawl screen (Ambush RestRoom)
// and return to the SAME screen on close. Re-pointed from the loadout_from_event prototype.
//
// A contract dialog is shown by contract_manager (EventScreen.show(contract)), not
// World.Events, so we require a live CONTRACT + visible event screen. Restore CANNOT go
// through showEventScreen (it refuses while the MenuStack has backsteps, always true
// mid-contract), so re-show via EventScreen.show(contract) directly (setIsContract first).
//
// Call from a "stay here" option whose getResult returns the SAME screen ID (never 0 --
// 0 closes the screen and the restore then re-shows a null screen and crashes).
::mods_hookExactClass("states/world_state", function ( o )
{
	o.showLoadoutFromContract <- function ()
	{
		if (this.m.CharacterScreen == null || this.isInCharacterScreen()) return false;
		if (this.m.EventScreen == null || !this.m.EventScreen.isVisible() || this.m.EventScreen.isAnimating()) return false;
		if (this.World.Contracts.getActiveContract() == null) return false;

		this.World.Assets.updateFormation();   // sync the equipment/formation view
		this.m.EventScreen.hide();             // hide underneath for clean layering
		this.m.CharacterScreen.show();

		// MenuStack backstep pushed ON TOP of the contract's own: restores the contract screen first.
		this.m.MenuStack.push(function ()
		{
			this.m.CharacterScreen.hide();
			this.World.Assets.refillAmmo();    // spends the Ammunition stockpile (intended)

			local c = this.World.Contracts.getActiveContract();
			if (c != null)
			{
				// Direct EventScreen.show -- bypasses the showEventScreen backstep guard.
				this.m.EventScreen.setIsContract(true);
				this.m.EventScreen.show(c, false);   // false = no slide; re-renders current screen
			}
		},
		function ()
		{
			// Only restore once the close animation has finished.
			return !this.m.CharacterScreen.isAnimating();
		});

		return true;
	}
});
