::mods_hookExactClass("skills/actives/legend_magic_burning_hands", function ( o )
{

	local create = o.create;

	o.create = function ()
	{
		create();

		try
		{
			this.m.Overlay = "active_209";
		}
		catch (e)
		{
			::logError("Skv.Overlay: could not replace burning hands' missing overlay (it still burns): " + e);
		}
	}
});
