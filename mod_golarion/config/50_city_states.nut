// ==================== The southern powers: city-state archetypes ====================
// SEPARATE table from FactionArchetypes: createCityStates does a foreach, NOT a random
// draw, so the LENGTH OF THIS ARRAY IS THE NUMBER OF CITY-STATES ON THE MAP (three here).
// Names still rotate via CityStateNames (do/while dedup); all three powers always appear.
//
// Traits MUST keep OrientalCityState -- unlike noble personality traits, this one IS read
// (escort_caravan_contract.nut:1108, send_caravan_action.nut:74). Do not add/remove traits.
// %citystatename% is the live placeholder here (NOT %noblehousename%). No colour tags.
::Const.CityStateArchetypes = [
	{	// PRIHASTA -- The General Between Heaven and Hell. LE. Kukri. Rakshasa Immortal.
		Traits = [
			::Const.FactionTrait.OrientalCityState
		],
		Description = "The ministers of %citystatename% answer to Prihasta, who is not a god and has never bothered to claim otherwise. The General Between Heaven and Hell was a rakshasa that made itself immortal by being patiently, thoroughly evil, and its power now approaches that of the gods it says it already outranks. It holds no portfolio and teaches no doctrine. Its worship is to find someone good and talk to them -- praise first, then sympathy, then a reasonable suggestion, and another, until the virtue has gone out of them and they cannot recall having agreed to anything. The city is not ruled. It is persuaded.",
		Mottos = [
			"The city is not ruled. It is persuaded.",
			"A reasonable suggestion, and then another",
			"Prihasta outranks what it has not yet met",
			"We only ever talked to you",
			"Honeyed words, patiently applied",
			"You agreed to this"
		]
	},
	{	// HATAAM -- The River Eater. CE. Net. Sahkil Tormentor.
		Traits = [
			::Const.FactionTrait.OrientalCityState
		],
		Description = "%citystatename% keeps Hataam, the River Eater, who is no god but a sahkil -- a thing that eats fear, and found that thirst is the most patient fear there is. His worship is a dam. Any dam, any stream, the smaller the better, built for no reason except that afterwards the water has stopped. The city sits above the water and sells it back down, and its engineers walk out each spring with rope and sluice-gate to make the argument again. Upstream they call it a tithe. Downstream, where the wells went dry and the herds died standing up, they call it what it is.",
		Mottos = [
			"All water is borrowed",
			"Thirst is a patient argument",
			"The River Eater is never full",
			"We hold the water. We do not take it.",
			"Upstream calls it a tithe",
			"Every valley drinks, or learns"
		]
	},
	{	// THE FOUR HORSEMEN (APOCALYPSE RIDERS) -- NE archdaemons of Abaddon, not gods.
		// %regionname% resolves EMPTY in-game (all resolve sites pass ""); never use it.
		Traits = [
			::Const.FactionTrait.OrientalCityState
		],
		Description = "%citystatename% is not ruled by one hand but by four, and none of them living. Its masters serve the Apocalypse Riders whole -- the Four Horsemen of Abaddon, archdaemons who are no gods but divide between them every way a world can end -- and the city is governed as they are, as a tetrarchy of endings. Four ministries sit above all others, and each answers to a different Rider. The ledgers and the granaries answer to Trelmarixian the Black, Rider of Famine, who teaches that a city is ruled most cheaply through what it is permitted to eat. The armouries and the levies answer to Szuriel, Rider of War, whose furnace never cools. The physicians and the quarantines -- and, quietly, the wells -- answer to Apollyon, Rider of Pestilence, who decides which sickness is allowed in and which is kept out. And over all of them, first among the four as he is the eldest Rider and the only one to hold his title since daemonkind began, stands the ministry of Charon, the Boatman, Rider of Death, whose black river takes a toll from everyone and whose ferry is never refused. The four do not love one another and are not required to; the city works precisely because famine, war, plague and death are, in the end, one business with four desks. Its officers learn their masters' patience early -- some study decay in black water until the dark comes up behind the eyes -- and its gates take a coin from everyone, living or dead, in or out. They fly four pale horses on a black field, and speak, when they are drunk and unwise, of a fifth Rider bound and buried somewhere beneath the city, greater than the four, whose ministry has no desk because his ending has not yet been permitted to arrive.",
		Mottos = [
			"One business, four desks",
			"Every ending has its ministry",
			"A coin from everyone, in or out",
			"Famine, war, plague, and the Boatman last",
			"The four need not love one another",
			"The fifth has no desk -- yet"
		]
	}
];
::logInfo("Golarion: city-state powers loaded, " + ::Const.CityStateArchetypes.len() + " (== the number of city-states on the map)");
