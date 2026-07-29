// ============================================================================
//  skv_ring_of_torag -- the ring on the hand of the one dwarf who did not convert.
//
//  Module (D0, area 14 sidebar): "This simple golden ring has a large red gemstone
//  set into it that sparkles with an inner fire. The wearer of the ring gains fire
//  resistance 10 against the first fire attack that hits him that day... In
//  addition, the wearer receives a +1 resistance bonus on saves made against fire
//  spells and effects."
//
//  BB has no per-day charge and no saving throws, so the once-a-day resistance and
//  the save bonus collapse into the one thing the engine actually models: a flat
//  cut to fire damage taken. 10% is deliberately small. This is a keepsake off a
//  dead man's finger in a starter contract, not a piece of endgame kit -- and the
//  reason to wear it is that it is TORAG'S, carried out of the one room in that
//  building his worship survived in.
//
//  ⚠ NOT legend_named_accessory -- that is the random-NAMING decorator for
//  generated loot and carries no stats of its own.
// ============================================================================
this.skv_ring_of_torag <- this.inherit("scripts/items/accessory/accessory", {
	m = {},

	function create()
	{
		this.accessory.create();

		this.m.ID = "accessory.skv_ring_of_torag";
		this.m.Name = "Ring of Torag";
		this.m.Description = "A simple golden ring with a large red stone set into it, and something moving in the stone that is not a reflection. It was cut for a dwarf, which is to say it is a tight fit and an honest weight. The man it was taken from had been dead four hundred years and was still wearing it.";

		this.m.SlotType = ::Const.ItemSlot.Accessory;
		this.m.ItemType = ::Const.Items.ItemType.Accessory;

		// Icon borrowed from the signet ring's loot art -- the same small gold ring,
		// and a real path that ships with the base game.
		this.m.Icon = "loot/inventory_loot_09.png";

		this.m.Value = 1200;
		this.m.IsDroppedAsLoot = true;
		this.m.IsUsable = false;
		this.m.IsAllowedInBag = true;
		this.m.ShowOnCharacter = false;
		this.m.IsChangeableInBattle = false;
	}

	function onUpdateProperties( _properties )
	{
		// The engine's only fire lever: tactical_entity_common multiplies incoming
		// fire damage by DamageReceivedFireMult, so the ring simply lowers it.
		_properties.DamageReceivedFireMult *= 0.9;
	}

	function getTooltip()
	{
		// ⚠ ONE row, and it is the mechanical one. A second row of flavour under an
		// icon reads as a second EFFECT -- "Torag's own" sat there looking like it did
		// something. The story belongs in the description, where the player expects it.
		local result = this.item.getTooltip();
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/regular_damage.png",
			text = "Takes [color=" + ::Const.UI.Color.PositiveValue + "]10%[/color] less damage from fire"
		});
		return result;
	}

});
