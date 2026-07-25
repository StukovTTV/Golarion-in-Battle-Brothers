// ---- Reflavor noble-house archetype prose: keep Traits, swap Description + Mottos ----
// Matched by a phrase per vanilla description; guarded so a mismatch can't crash the load.
local golarionArch = {
	"history of conquest": {
		d = "House %noblehousename% remembers when Aroden walked the earth and the Inner Sea answered to one throne. Since the god's death broke that promise, they have sworn to Gorum that the sword will decide what prophecy no longer can. From %factionfortressname% they ride to reforge the old dominion in iron and blood, and their feud with house %othernoblehouse% has fed Our Lord in Iron for generations.",
		m = ["Won back by the sword", "Gorum cares not whose blood", "No throne but the taken one", "The blade outlived prophecy", "Iron decides all", "Boldly and rightly", "He conquers who endures"]
	},
	"Disdained for their ruthlessness": {
		d = "In the lawless years since Aroden's fall, house %noblehousename% learned that a full granary is only as safe as the swords around it. From %factionfortressname% their reavers strip caravans, farms, and any village too weak to hold, and a life is worth less than the salt it is traded for. Some whisper they have made peace with the Rough Beast; most are too dead to whisper anything.",
		m = ["Mercy died with the god", "Rovagug's teeth, our blades", "The strong eat", "What you cannot hold is ours", "Beg or bleed", "Lawless years, good years"]
	},
	"eyes on the horizon": {
		d = "House %noblehousename% keeps its gaze past the horizon, on the fortunes of Absalom, the plunder of the Shackles, every coast the shattering left unguarded. From %factionfortressname% they launch expedition after expedition to seize a world they hold rightfully theirs, for in an age of broken prophecy a realm belongs to whoever is bold enough to take it.",
		m = ["The world is unclaimed", "Bold hands built Absalom", "Past the horizon, everything", "A bold hand takes the world", "Sail, seize, return", "Fortune favors the bold"]
	},
	"history of total control": {
		d = "House %noblehousename% rules %factionfortressname% by a compact as old and binding as the Prince of Darkness himself: obedience for order, tithe for protection. What Aroden's death took in certainty, they return in the cold comfort of law absolute, and a frightened people, remembering the chaos beyond the walls, learn to love the chain that steadies them.",
		m = ["Order is mercy", "Asmodeus keeps his bargains", "The chain steadies the hand", "Obedience for peace", "Better a cruel law than none", "Chaos is the only tyrant"]
	},
	"works in the dark": {
		d = "House %noblehousename% keeps its borders not with walls but with whispers. Its agents, blessed some say by Norgorber himself, have eyes in every shadowed doorway from %factionfortressname% to the courts of its rivals. Peace holds in their lands, for a knife finds every plotting throat before the plot is even spoken aloud.",
		m = ["We are always listening", "Norgorber keeps our ledger", "Every wall has our ear", "The knife before the plot", "Peace, bought in whispers", "Silence is our watchword"]
	},
	"jealously guarded": {
		d = "The vaults beneath %factionfortressname% are said to rival Druma's own, yet house %noblehousename% never counts itself rich enough. Where Abadar's faithful build with their gold, this house only buries it deeper, and the whispered tally of their hoard grows with every year the world outside grows poorer.",
		m = ["It all comes home", "Gold outlasts gods", "Never rich enough", "Bury it deeper", "The vault is the truest faith", "Druma's envy is our pride"]
	},
	"subtly manipulates": {
		d = "When Aroden died, most of his faithful despaired, but house %noblehousename% turned to Iomedae and kept the old promise in quieter ways. From %factionfortressname% they work unseen: a coin to the starving, a word in the right ear, a blade drawn only in the deepest dark. In a shattered Inner Sea, they are a stubborn ember of the world that was promised.",
		m = ["Lost Omens, not the last age", "Aroden's promise, unbroken", "A light against the long dusk", "For the folk, not the gods", "We keep the old faith quietly", "The dawn was only delayed"]
	},
	"Lauded as providers": {
		d = "House %noblehousename% answers to its own people first and the wider world not at all. From %factionfortressname% its warbands strip the caravans and farms of the soft southern realms, and every wagon comes home to fill their own bowls. Cruel to strangers and generous to kin, they call it not banditry but providing, and their well-fed folk, while others starve, name it the same.",
		m = ["Bringing it home", "Kin before crown", "Hard abroad, true to kin", "The soft south feeds us", "Our people eat first", "A full bowl, a hard name"]
	},
	"master of cunning bargains": {
		d = "House %noblehousename% holds that a ledger conquers what a legion cannot. From the counting-houses of %factionfortressname% they broker deals across the broken Inner Sea, some blessed by Abadar, many more built on bribery and quiet threat. For all their fabled riches they are famously close-fisted; a coin that enters their vaults is not seen again.",
		m = ["Every man has his price", "Wealth is our sword", "The ledger conquers all", "A deal is a quieter war", "Abadar blesses the shrewd", "Coin in, coin never out"]
	},
	"when man first claimed this land": {
		d = "House %noblehousename% claims a bloodline older than Aroden's empire, back to when the first kings raised their halls upon the bones of Azlant. One house among many now, coffers thinning and name fading, from %factionfortressname% they fund doomed expeditions into sunken Thassilonian ruins and drowned Azlanti vaults, chasing the glory of an age the sea swallowed.",
		m = ["Our roots run to Azlant", "Kings when kings were young", "The old glory sleeps, not dead", "Down into the drowned vaults", "Blood older than empire", "Thassilon remembers"]
	},
	"secluded behind thick doors": {
		d = "The doors of %factionfortressname% have stayed barred for a generation. Rumor names the blood of house %noblehousename% cursed, touched by Zon-Kuthon's long shadow, or by something older that crept in when the gods stopped watching. Other houses keep their distance, for a guest here is as likely met with open arms as a crossbow bolt from a darkened window.",
		m = ["The blood remembers", "Shadows keep our counsel", "Knock, and pray no one answers", "The doors stay barred", "What crept in, stayed", "Madness is a kind of sight"]
	}
};
try {
	foreach (group in ::Const.FactionArchetypes) {
		if (typeof group != "array") continue;
		foreach (arch in group) {
			if (typeof arch != "table" || !("Description" in arch)) continue;
			foreach (key, repl in golarionArch) {
				if (arch.Description.find(key) != null) {
					arch.Description = repl.d;
					arch.Mottos = repl.m;
					break;
				}
			}
		}
	}
} catch (e) { ::logInfo("Golarion archetype reflavor skipped: " + e); }

// ==================== The pantheon: gods AS archetypes ====================
// Houses are named for RUNELORDS (NobleHouseNames); the ARCHETYPE is the god that
// house serves. This REPLACES FactionArchetypes (the phrase-match block above is now
// inert, kept only for easy revert). Drawn WITHOUT replacement, N per world.
//
// !! ENTRY COUNT MUST BE >= the Legends "Factions" mod setting !! createNobleHouses
// loops that many times doing houses.remove(rand(0, len-1)); too few archetypes indexes
// an empty array. (Array LENGTH gates the setting.)
//
// Traits are DOCUMENTATION ONLY (only NobleHouse and OrientalCityState are ever read).
// NO COLOUR TAGS here: the Factions panel renders them literally (contract/event screens parse them).
// Placeholders %noblehousename% %factionfortressname% %othernoblehouse% are live.
// %regionname% resolves to an EMPTY STRING (faction_manager stubs it) -- never use it.
::Const.FactionArchetypes = [
	[
		{	// ERASTIL -- Old Deadeye. LG. Longbow. Family, farming, hunting, trade.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.ManOfThePeople,
				::Const.FactionTrait.Collector
			],
			Description = "When the prophecies broke the cities went mad with it, and House %noblehousename% went out to the fields as it had the year before. Erastil promised no age, so no age of his has ended -- Old Deadeye asks only what a village can give. His people still plant five seeds in the shape of an arrow, asking only that each has a chance, and still leave bread on the road where a stranger will find it.",
			Mottos = [
				"The hearth outlasts the throne",
				"Old Deadeye asks nothing of you",
				"A full barn needs no prophecy",
				"We were farming before the gods",
				"Bow, hearth, harvest",
				"Let it burn. We have seed."
			]
		},
		{	// IOMEDAE -- The Inheritor. LG. Longsword. Honor, justice, rulership, valor.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% swore to Iomedae in the year the god died, and has not unsworn. The Inheritor was Aroden's herald; when he fell she took up the work instead of mourning it. Their knights kneel with the sword held upright and her symbol hung from it, swear what she swore, then ride out from %factionfortressname% to judgements nobody asked for.",
			Mottos = [
				"Aroden fell. The work did not.",
				"The Inheritor took up the sword",
				"We do not mourn. We march.",
				"Valor is a habit, not a mood",
				"Judgement rides out",
				"Someone must"
			]
		},
		{	// TORAG -- Father of Creation. LG. Warhammer. Forges, protection, strategy.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps Torag's forges, and the Father of Creation teaches that anything worth having is worth building twice -- once in iron, and once in stone around the iron. Their smiths beat the anvil ten minutes at a stretch for the sound of it, and whoever the noise draws in is asked to join the work, or, if it comes to that, the fight. Since the shattering proved the world could break they have done little but thicken the walls of %factionfortressname%. They will sell you a hammer, a plan, or a siege you cannot win.",
			Mottos = [
				"Build it twice",
				"The wall is the prayer",
				"Iron first, then stone around it",
				"Torag measured before he struck",
				"We do not lose ground",
				"Strategy is patience with a hammer"
			]
		},
		{	// SARENRAE -- The Dawnflower. NG. Scimitar. Healing, honesty, redemption, the sun.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.ManOfThePeople,
				::Const.FactionTrait.Warmonger
			],
			Description = "House %noblehousename% opens %factionfortressname% to anyone who comes to it broken, because Sarenrae teaches that no soul is past redeeming. The Dawnflower's clerics will feed a murderer, nurse him, and hear him out. On the days nobody will accept their help they walk out beyond the walls, bind their eyes with a red-and-gold scarf, and stand trying to find the sun through the cloth.",
			Mottos = [
				"No soul past redeeming",
				"The Dawnflower offers twice",
				"Mercy first. Fire after.",
				"Come broken. Leave whole.",
				"The scimitar is also the sun",
				"There is no third chance"
			]
		}
,
		{	// SHELYN -- The Eternal Rose. NG. Glaive. Art, beauty, love, music.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.ManOfThePeople,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% serves Shelyn, and the Eternal Rose asks nothing of her faithful except that they make something. A picture, a song, a few lines of verse -- it need not be large or clever, only honest and the best that was in them -- and then they must give it away to a stranger and say something kind while doing it. Where nobody will take it, they leave it on a bench with a note asking whoever finds it to keep it. From %factionfortressname% they have done this through two famines and a war, and no one has worked out how to make them stop.",
			Mottos = [
				"Make something. Give it away.",
				"The Eternal Rose asks only your best",
				"Beauty is not a luxury",
				"A kind word with the gift",
				"Two famines and a war, and still we paint",
				"Nobody has made us stop"
			]
		},
		{	// CAYDEN CAILEAN -- The Drunken Hero. CG. Rapier. Ale, bravery, freedom, wine.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.ManOfThePeople,
				::Const.FactionTrait.Warmonger
			],
			Description = "House %noblehousename% drinks to Cayden Cailean, who was mortal before he was a god and by every account not a careful one. His worship is a song about freedom and bravery and how well he wore both, sung loud enough that everyone nearby hears it -- friend or foe, no exceptions -- with a pull from the mug between stanzas. If the noise brings someone over, they are talked at about the Drunken Hero until they agree. If it brings a fight instead, that is also acceptable. From %factionfortressname% they have freed more slaves than they have won battles, which they consider the correct ratio.",
			Mottos = [
				"Sung loud enough for the enemy",
				"Freedom, bravery, and a full mug",
				"He was one of us first",
				"More slaves freed than battles won",
				"Leap in. Ask after.",
				"The correct ratio"
			]
		},
		{	// DESNA -- Song of the Spheres. CG. Starknife. Dreams, luck, stars, travelers.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% keeps Desna, and the Song of the Spheres is worshipped by dancing beneath the stars in no pattern at all -- you are meant to stop thinking about where your feet are going and let them fall where chance wants them. When the dance ends you study where you stopped, and the steps behind you, and read what they meant. If there are no stars, you sing the names of the ones you know instead. From %factionfortressname% they have chosen wars, marriages and harvests this way for six generations, and are no worse off than House %othernoblehouse%, which uses maps.",
			Mottos = [
				"Let the steps fall where they will",
				"Song of the Spheres knows the way",
				"We danced for this",
				"No worse off than the ones with maps",
				"Read where you stopped",
				"Chance is not the same as nothing"
			]
		},
		{	// ABADAR -- Master of the First Vault. LN. Light crossbow. Cities, laws,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% serves Abadar, Master of the First Vault, whose worship is bookkeeping. Each morning a handful of gems, coins and keys -- coins from three kingdoms at least, and three keys, one of them to a vault -- is balanced on a scale until it sits level, and the handful must be different every day so that it never becomes a habit. From %factionfortressname% they hold that a city is only a very large scale, and that everything on it, laws included, can be brought level by someone patient enough to keep the ledger honest.",
			Mottos = [
				"Bring it level",
				"The ledger is the prayer",
				"A city is a very large scale",
				"Never the same handful twice",
				"Patience, and an honest ledger",
				"Master of the First Vault keeps count"
			]
		},
		{	// IRORI -- Master of Masters. LN. Unarmed strike. History, knowledge,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Sheriff
			],
			Description = "House %noblehousename% follows Irori, who was a man before he was a god and arrived by not stopping. The Master of Masters is a title he was given rather than took, which his faithful consider the only honest way to get one. His hour divides into three equal parts: strike something, read something you have never read before, and braid a length of hair while considering the shape of the universe. The braid is worn around the neck until nightfall. From %factionfortressname% they field no army worth the name and hold no ambition anyone else can identify, and every one of them can kill you with their hands.",
			Mottos = [
				"He was a man before he was a god",
				"Strike, read, braid",
				"Perfection is only not stopping",
				"We have no ambitions you would notice",
				"Master of Masters was mortal once",
				"The hands are enough"
			]
		},
		{	// GOZREH -- The Wind and the Waves. N. Trident. Nature, the sea, weather.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% hangs chimes for Gozreh where the wind or the water will find them, and chants until the sound stops, then drinks a mouthful of clean water and pours a handful over the head. The Wind and the Waves is two things at once and neither is interested in you: the sea that carries the grain drowns the fleet, and the clerics of %factionfortressname% will tell you that is not cruelty, it is weather. They shelter whoever the storm sends them and take whatever it leaves on the rocks.",
			Mottos = [
				"It is not cruelty. It is weather.",
				"The Wind and the Waves owes you nothing",
				"Shelter what comes, take what stays",
				"The same sea does both",
				"Hang the chimes",
				"Grain or wreckage, as it falls"
			]
		}
,
		{	// NETHYS -- The All-Seeing Eye. N. Quarterstaff. Magic (that is the whole entry).
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Warmonger,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% serves Nethys, the All-Seeing Eye, who saw everything there is and came back wearing a mask that is white down one side and black down the other. Magic is his only concern and he holds no opinion whatever about what is done with it. His rite is to write a formula out on clean parchment and stop halfway -- never a whole spell, only enough of one that whoever finds it might be tempted to finish the working themselves. From %factionfortressname% they have been leaving these lying about for years.",
			Mottos = [
				"Never the whole spell",
				"The All-Seeing Eye has no opinion",
				"Finish it yourself",
				"White on one side, black on the other",
				"We only left it lying there",
				"Magic does not care either"
			]
		},
		{	// PHARASMA -- Lady of Graves. N. Dagger. Birth, death, fate, prophecy.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% keeps Pharasma, the Lady of Graves, who is owed every soul eventually and has never once hurried. Her people gather small bones as they come across them, lay them in a spiral, and set a slip of parchment at either end -- one named for somebody born that week, one for somebody dead -- then walk the coil chanting, trailing a black scarf along the ground behind them. She was the goddess of prophecy as well, once. From %factionfortressname% nobody has raised the subject in a hundred years.",
			Mottos = [
				"The bones land in a spiral",
				"She is owed, and she can wait",
				"Born at one end, dead at the other",
				"We do not discuss the prophecy",
				"The Lady of Graves keeps the roll",
				"Everyone arrives on her books"
			]
		},
		{	// CALISTRIA -- The Savored Sting. CN. Whip. Lust, revenge, trickery.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.Schemer
			],
			Description = "House %noblehousename% serves Calistria, the Savored Sting, who takes three daggers and a wasp for her sigil and holds that lust and revenge are one appetite aimed two ways. When there is nobody to take to bed, her faithful wrap themselves in yellow silk, hold the symbol against the chest, and spend the hour thinking in careful detail about a person who wronged them. From %factionfortressname% they forgive nothing and forget less, and they are extremely good company.",
			Mottos = [
				"Three daggers, and time",
				"We forgive nothing and forget less",
				"The Savored Sting remembers you",
				"One appetite, aimed two ways",
				"Yellow silk and a long memory",
				"It was always going to be us"
			]
		},
		{	// GORUM -- Our Lord in Iron. CN. Greatsword. Battle, strength, weapons.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Warmonger,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% shouts for Gorum, Our Lord in Iron, and the worship is done in the heaviest armour you own: bellow the oath until the breath goes, beating your weapon on shield or breastplate at every pause, then kneel with the blade on your shoulder and recite your victories aloud until the hour is out. Anyone who interrupts is to be killed -- your men may help, but the last blow must be yours. From %factionfortressname% they have never once had to be asked twice.",
			Mottos = [
				"The last blow must be yours",
				"Our Lord in Iron cares not whose blood",
				"Say it louder",
				"Recite them until the hour is out",
				"Never asked twice",
				"The sword is in the mountain"
			]
		},
		{	// ASMODEUS -- Prince of Darkness. LE. Mace. Contracts, pride, slavery, tyranny.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Tyrant,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% holds its contract with Asmodeus, the Prince of Darkness, and pays it in blood: symmetrical cuts opened with a ruby blade in something that belongs to you, drained into a bowl cut from a human skull, the blood used to draw the pentagram they then kneel inside. The doctrine is precise about the quantity -- never so much that the creature is weakened, or left too useless to go on serving. From %factionfortressname% they will remind you the terms were written down, and that you signed.",
			Mottos = [
				"The terms were written down",
				"You signed",
				"Asmodeus keeps his bargains",
				"Never more than the asset can bear",
				"Order is mercy, at a price",
				"Read it again"
			]
		},
		{	// ZON-KUTHON -- The Midnight Lord. LE. Spiked chain. Darkness, envy, loss, pain.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Tyrant,
				::Const.FactionTrait.Schemer
			],
			Description = "House %noblehousename% belongs to Zon-Kuthon, the Midnight Lord -- but he was not always that, and the house knows the older name. In the first age he was Dou-Bral, son of the spirit-wolf Thron, a god of beauty and art and light, and he shared both a love of lovely things and a single golden glaive with his half-sister Shelyn. Then he grew envious of her, and went out into the dark places beyond and between the planes, and something out there in the truly outer dark unmade him and put him back together wrong. What came home was not Dou-Bral. When Shelyn saw what her brother had become she fought him -- and won from his fingers the glaive they had shared, the Whisperer of Souls, which she keeps to this day because she alone has never accepted that he is gone for good, and believes, still, that the brother can be called back out of the thing wearing him. The house exists, in a way, to prove her wrong. Their worship is pain, but pain asked for: the rite needs a creature persuaded to permit it -- the needle, the lash, the hook, whatever is agreed -- and the agreeing is the sacrament, for consent given is the sweeter to spoil. Where none will consent, they coil a spiked chain into a nest and kneel until their own weight drives it home, and flog their own backs in praise. From %factionfortressname% they are unfailingly gentle, unfailingly polite, and they will explain to you, patiently and at length, exactly why you want this -- because their god was talked out of the light once, in the dark, by something patient, and they have learned from him how it is done.",
			Mottos = [
				"He was Dou-Bral once",
				"We exist to prove his sister wrong",
				"The agreeing is the sacrament",
				"He was talked out of the light, patiently",
				"We always ask first",
				"Say yes"
			]
		},
		{	// NORGORBER -- The Reaper of Reputation. NE. Short sword. Greed, murder, poison,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% does not discuss Norgorber, the Reaper of Reputation, which is the point of him. The rite is a prayer said inside a crowd, so quietly that nobody hears it -- and if you suspect somebody did, you follow them out and prick them with a poisoned needle. Where there is no crowd you dig a hole six inches deep, whisper into it, and bury the sound. It finishes the same way every time: a needle dipped and left where a stranger will find it with their hand.",
			Mottos = [
				"Bury the sound",
				"We do not discuss him",
				"Quietly enough that nobody hears",
				"Somebody heard",
				"A needle, and a windowsill",
				"The Reaper keeps his own ledger"
			]
		},
		{	// URGATHOA -- The Pallid Princess. NE. Scythe. Disease, gluttony, undeath.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Tyrant,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% feasts for Urgathoa, the Pallid Princess, whose concerns are disease, gluttony and undeath, and who has never seen much difference between them. Black velvet on the table, the best of everything laid on the cloth, and you eat past full and go on eating, wine between the courses and prayers between the mouthfuls. Then, at the end, one bite of something spoiled -- rotten fruit, rancid meat, cheese gone green -- swallowed on the understanding that she will not let it hurt you. From %factionfortressname% they are always hungry and never ill.",
			Mottos = [
				"Always hungry, never ill",
				"Eat past full, and go on",
				"The last bite is the prayer",
				"The Pallid Princess does not stop",
				"Black velvet, and everything on it",
				"She will not let it hurt us"
			]
		},
		{	// LAMASHTU -- Mother of Monsters. CE. Falchion. Madness, monsters, nightmares.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% belongs to Lamashtu, the Mother of Monsters, and her rite is a killing done slowly, because the terror is the offering and a clean death is a wasted one. When it is finished you take a bone out of what remains, sharpen it, and open your own skin with it deep enough to scar. The body stays where it fell, in the open, for the scavengers or for whoever comes along the road. From %factionfortressname% every one of them is marked, and every mark was somebody, and they will show you if you ask.",
			Mottos = [
				"Every mark was somebody",
				"The Mother takes what is hers",
				"A clean death is a wasted one",
				"Left where the road can see it",
				"She keeps her children",
				"Ask, and they will show you"
			]
		},
		{	// ROVAGUG -- The Rough Beast. CE. Greataxe. Destruction, disaster, wrath.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Warmonger,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% is sworn to Rovagug, the Rough Beast, who is not at liberty and whose faithful regard that as a temporary condition. They buy beautiful things -- good wine, fine glass, old carving, anything holy to Sarenrae by preference -- and they buy them specifically in order to break them, then roll in the pieces howling praise and curses until the shards draw blood and the lungs give out. From %factionfortressname% they keep a treasury that exists to be destroyed, and about the rest of it they are patient.",
			Mottos = [
				"A treasury that exists to be destroyed",
				"Not at liberty. For now.",
				"Buy it beautiful. Break it anyway.",
				"The Rough Beast is only waiting",
				"Roll in the pieces",
				"Sarenrae's, by preference"
			]
		}
,
		{	// ---- EXOTIC PANTHEON: gods reached for, past the Core 20 ----
			// ACHAEKEK -- He Who Walks in Blood. LE. Sawtooth sabre. Assassinations, divine
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Warmonger
			],
			Description = "House %noblehousename% belongs to Achaekek, He Who Walks in Blood, the Mantis God -- and to understand the house you must first understand exactly what he is for. The other gods made him, in the first age, as an impartial judge to stand sentinel over creation; and when Rovagug went rampaging through the young world Achaekek consumed his own impartiality and came out the far side a red thing, all claw and appetite. What they kept him for was one task above all: to kill anyone reaching for a divinity they were not granted. He can slay a demigod or a risen sorcerer-king or any mortal climbing toward godhood -- but the gods, cunningly, built him unable to touch a true deity, so that the blade they forged could never be turned on them. From this comes the one law his people will not break: they never kill a rightful ruler. A crowned and anointed king is, to them, the gods' own agent and untouchable; it is the graspers, the usurpers, the ones reaching past their station for power that was never given, on whom the sentence falls. His faithful are the Red Mantis of far Mediogalti, and their work is not called murder but sentence, carried out with the sawtooth sabre and a professional detachment that takes no joy and offers no mercy. The rite is done over a trophy cut from a marked target, anointed with a drop of the killer's own blood off the blade, then destroyed; lacking a contract, the killer opens their own right arm with the sabre and lets it bleed the hour through. From %factionfortressname% they take their contracts the way a court takes its cases, and in a shattered age crowded with sorcerer-kings and half-made powers all reaching for what they have not earned, a house that serves the god who kills the ambitious has picked, of everything it could fly, the flag the climbers fear most.",
			Mottos = [
				"Not murder. Sentence.",
				"We do not touch a rightful crown",
				"The blade falls on those who reach too high",
				"He was made to kill the ambitious",
				"A trophy, and a drop of blood",
				"The climbers fear us most"
			]
		},
		{	// ARAZNI -- The Harlot Queen. NE. Rapier. Command of undeath, lichdom. Symbol:
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% serves Arazni, the Harlot Queen, who was a herald of the age of prophecy before she was killed in front of the army that worshipped her, and raised again against her will, and passed hand to hand as a chattel for four hundred years. She rules the dead now and hates the living with a patience the living cannot imagine. Her rite is to sit for an hour and relive every wrong ever done to her, and to let no one see it. From %factionfortressname% they are courteous, immaculate, and keeping a list.",
			Mottos = [
				"Courteous, immaculate, and keeping a list",
				"She was a herald once",
				"Let no one see it",
				"Raised against her will, and remembering",
				"The Harlot Queen rules the dead now",
				"Every wrong, in order"
			]
		},
		{	// ZYPHUS -- The Grim Harvestman. NE. Heavy pick. Accidental death, graveyards,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% keeps Zyphus, the Grim Harvestman, god of the death that nobody intended -- the stair that gives way, the rope that parts, the ford that drowns a man on a calm day. Nobody is ever murdered in the lands of %factionfortressname%. There are only a great many accidents, more than the country roads elsewhere seem to suffer, and the faithful spend their devotions making certain of it: a sawn joist here, a loosened stone there, left for whoever comes next.",
			Mottos = [
				"Only a great many accidents",
				"Nobody is ever murdered here",
				"The stair that gives way",
				"Left for whoever comes next",
				"Chance wronged us first",
				"The Grim Harvestman takes the calm days too"
			]
		},
		{	// GROETUS -- God of the End Times. CN. Heavy flail. Empty places, oblivion, ruins.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% waits with Groetus, the God of the End Times, the skull-faced moon that hangs over the Boneyard with nothing to do until the last soul has been judged and creation can finally be ground quiet. His faithful preach that ending to strangers, an hour a day, and where there is no one to preach at they sit in some emptied place no living thing has entered in a month and draw the moon on the walls. From %factionfortressname% they are calm, and unhurried, and certain, because they are the only ones who already know how it comes out.",
			Mottos = [
				"They already know how it comes out",
				"The moon is waiting",
				"Calm, unhurried, certain",
				"An hour a day, to anyone",
				"Nothing lives here now",
				"The End Times are not in a hurry"
			]
		},
		{	// APSU -- The Waybringer. LG. Bite or quarterstaff. Good dragons, leadership, peace.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% keeps Apsu, the Waybringer, the first of the good dragons, who made the roads and the peace to travel them on. Twice a day the faithful walk out in a straight line: once studying the ground for every advantage a fight might turn on, and once back over the same country seeing only how beautiful it is, and thanking him that any of it exists at all. From %factionfortressname% they are the rarest thing the shattering left -- a house that means you no harm and can prove it.",
			Mottos = [
				"Once for the fight, once for the beauty",
				"The Waybringer made the roads",
				"We mean you no harm, and can prove it",
				"Every advantage, and every grace",
				"The rarest thing the shattering left",
				"Walk it twice"
			]
		},
		{	// GRUHASTHA -- The Keeper. LG. Shortbow. The Vudrani holy book (the Vudra scripture).
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% follows Gruhastha, the Keeper, who lived inside a book until he understood every word of it and then became a god of the reading itself. His rite is an hour spent teaching someone their letters, and where there is no student, an hour making a primer to leave at a school. While the other houses answered the broken age with walls and knives, %factionfortressname% answered it with a schoolroom, and holds -- against most of the evidence -- that a world that can still read can still be argued out of the dark.",
			Mottos = [
				"A world that can still read",
				"The Keeper lived inside the book",
				"We answered it with a schoolroom",
				"Letters, against the dark",
				"Teach one, then another",
				"Against most of the evidence"
			]
		},
		{	// SIVANAH -- The Seventh Veil. N. Bladed scarf. Illusions, mystery, reflections.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% is said to serve Sivanah, the Seventh Veil, goddess of illusion and reflection and the secret worth keeping -- though nobody outside its walls is entirely certain the house is there at all, or ever was. She wears seven veils, and the first six are each a different ancestry -- human, elf, halfling, and stranger things beneath -- while the seventh and last hides a face no worshipper has seen and lives; her true shape is that seventh, unknown thing, and she lets no one confirm it. She does not speak to her faithful in words but through mirrors, still water, and a person's own shadow, so that an instruction is never quite something anyone can prove was given. The rite honours this: veil the face, work an illusion beautiful enough to be believed, and then -- for her law forbids leaving a soul deceived forever -- let it fall, so the trick is known for a trick. From %factionfortressname%, if it is even called that, envoys arrive who are not quite the envoys who left, and treaties are signed that afterward no one can produce, and it is all, they assure you, exactly as it appears. They loathe Zon-Kuthon, who took the honest dark and made it a place of pain, and they alone keep faith with mad Razmir of Razmiran, the false god down the road -- for the Seventh Veil may be the only power in the world who looks at his imposture and sees, under the seventh veil of it, something real.",
			Mottos = [
				"Exactly as it appears",
				"You must be mistaking us",
				"The Seventh Veil is never lifted",
				"We were never the first one",
				"Treaties nobody can find",
				"It is all a reflection"
			]
		},
		{	// BESMARA -- The Pirate Queen. CN. Rapier. Piracy, sea monsters, strife.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Collector,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% flies Besmara's colours, the Pirate Queen, the Sea Banshee, Sailor's Doom -- and lives every day in breach of her first and plainest law. She commands her own to never settle on land, to keep faith with captain and crew above all, and to take whatever is not lashed down; and here the house sits, behind stone walls, holding ground, apostate from the hour it laid the first foundation. They square it the only way the creed leaves open. They do not govern the land so much as raid it from a fortress that might as well have run aground -- loyal absolutely to their own, faithless to everyone else, keeping no treaty one hour past the moment it stops paying. Her rite is small and exact: take a coin or a cup by force or by trick, toast her name loud enough that the one you took it from can hear, and drop the prize into deep water as her share, since everything is finally hers. What should trouble the neighbours is not the raiding but the goddess behind it. Besmara was no god once, only a spirit of the water that could call the sea's monsters up from below; she climbed to divinity by making war on the spirits of battle and gold and wood and swallowing them whole, and she has never stopped being hungry -- she hunts smaller gods still, looking for the next to absorb. In a shattered age crowded with half-made and nascent powers, that is no idle flag to fly, and the house that flies it has picked, knowingly, the side of the thing that eats the others.",
			Mottos = [
				"Never settle on land -- and yet",
				"Faith to captain and crew, first and last",
				"We do not hold the land, only bleed it",
				"Apostates since the first foundation stone",
				"Her share goes over the side",
				"The Pirate Queen eats smaller gods"
			]
		},
		{	// NOCTICULA -- The Redeemer Queen. CN. Dagger. Artists, exiles, midnight. Symbol:
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% keeps Nocticula, the Redeemer Queen, who was a demon lord of murder and assassins for an age of the world and then did the thing no demon had ever done -- put it down, and walked out, and took up the exiles and the artists instead. Her rite is an hour making something beautiful, alone, at midnight. From %factionfortressname% they take in whoever the other houses have cast out, and they do not talk about what any of them were before, because she of all powers has earned the right not to ask.",
			Mottos = [
				"She put it down and walked out",
				"The Redeemer Queen does not ask what you were",
				"Made beautiful, alone, at midnight",
				"Whoever the others cast out",
				"No demon had ever done it",
				"Come as you are now"
			]
		},
		{	// GHLAUNDER -- The Gossamer King. CE. Spear. Infection, parasites, stagnation.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% carries Ghlaunder, the Gossamer King, hatched from a wound that a kind healer should have left alone, god of the infection and the stagnant pool and the thing that gets into the blood. His rite mixes blood and filth into a poppet shaped like a biting insect, dries it while the leeches feed, and burns it to breathe the smoke. From %factionfortressname% they open their gates wide to the sick and the fevered, tend them with real tenderness, and send them home again carrying what they came in with, and more.",
			Mottos = [
				"Sent home with more than they came in with",
				"The Gossamer King got into the blood",
				"We tend them tenderly",
				"A wound the healer should have left alone",
				"Open the gates to the sick",
				"And more"
			]
		},
		{	// GYRONNA -- The Angry Hag. CE. Dagger. Extortion, hatred, spite. Symbol: bloodshot
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Warmonger
			],
			Description = "House %noblehousename% serves Gyronna, the Angry Hag, goddess of the grudge that never cools, worshipped by scorned women and bitter men at a single bloodshot eye scratched into a standing stone. Her rite is to spend an hour making one chosen life measurably worse -- ruin the crop, foul the medicine, lose the loan money -- then make sure the victim knows exactly who did it, and name a price to make it stop that does not have to be fair. From %factionfortressname% everything is for sale, especially mercy, and the rate is whatever hurts most.",
			Mottos = [
				"Especially mercy",
				"The price need not be fair",
				"She knows exactly who did it",
				"The grudge that never cools",
				"One bloodshot eye on the stone",
				"Pay, or it gets worse"
			]
		}
,
		{	// MAMMON -- The Argent Prince. LE. Shortspear. Avarice, watchfulness, wealth.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Collector,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% serves Mammon, the Argent Prince, who was a champion of Hell before avarice ate him hollow and left him a beautiful corpse in a diamond coffin at the centre of a vault nobody is permitted to spend. His rite is to shake a purse and account aloud for every coin in it -- earned, stolen, however it came -- then lay the coins in a pentagram on a mirror. From %factionfortressname% they keep the most exacting books in the world, and they will remind you that the Argent Prince watches his wealth even in death, and never once blinks.",
			Mottos = [
				"He watches it even in death",
				"Account for every coin",
				"A beautiful corpse in a diamond coffin",
				"The Argent Prince never blinks",
				"Nobody is permitted to spend it",
				"The books are exact"
			]
		},
		{	// BELIAL -- The Pale Kiss / Duke of Many Forms / Lord of the Fourth. LE archdevil,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% belongs to Belial, the Pale Kiss, the Duke of Many Forms, Lord of the Fourth -- and to know the house you must know how he was made. Before the great betrayal Asmodeus set out to build the most desirable being in all creation, and his first attempt, a thing that reshaped itself into the deepest wish of everyone who looked at it, came out a heaving insane horror he keeps locked away to this day. He tried again, and gave the second the power to command its own shape and a tongue that could talk anyone into anything, and named that success Belial. So the Duke of Many Forms is desire itself given control of its own face: he shifts form and species and gender to become whatever the one before him most wants, and leaves half-fiend children of every description behind him wherever he has been. His true shape no one but Asmodeus has seen; the face he wears among the other archdevils is split down the middle, one half shining and angelic, the other scarred and malformed as the ugliest thing in Hell. His rite fouls clean water with thirteen drops of the body, holds in the mind the single most desirable thing imaginable, and drinks the ruined cup to the bottom. From %factionfortressname% the envoys are charming, and beautiful, and never once the same face twice -- because that is precisely what their master is -- and every arrangement they offer is generous, and every one of them costs you something you did not know you had agreed to put on the table, for the house serves the god who becomes your wish in order to own you by it.",
			Mottos = [
				"He becomes your wish, then owns you by it",
				"Never the same face twice",
				"Asmodeus made him to be desired",
				"Every generous offer has a hidden line",
				"The Duke of Many Forms is what you want",
				"You agreed to more than you knew"
			]
		},
		{	// MAEHA -- The Father of False Words. LE. Net. Abduction, isolation, propaganda.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% follows Maeha, the Father of False Words, an asura of abduction and isolation and the lie told at scale. His worship is the cruellest small thing in the pool: put on the robes of a kindly priest of some gentle god, go among the poor, and spend the hour preaching comfort and handing out food you have poisoned. From %factionfortressname% the grain arrives in hard winters and the sermons are gentle and the missing are never quite accounted for, and the people love them, which is the entire point.",
			Mottos = [
				"The people love them. That is the point.",
				"The grain arrives in hard winters",
				"A kindly priest of some gentle god",
				"The missing are never quite accounted for",
				"The lie told at scale",
				"Comfort, and poison"
			]
		},
		{	// CHUGARRA -- The Guru of Butchers. LE. Handaxe. Blood, butchers, leather.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Collector,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% keeps Chugarra, the Guru of Butchers, an asura that ground its way up through a hundred lifetimes of the trade until it came out the other side a demigod of blood and meat and leather. There is nothing dramatic about the worship. You butcher an animal, cleanly, the way you were taught, or you work a hide until it is soft, and that is the whole of it. From %factionfortressname% they supply the tables of half the region and the tanneries of all of it, and they will tell you a thing only becomes useful once it has stopped being alive.",
			Mottos = [
				"Useful once it has stopped being alive",
				"Nothing dramatic about it",
				"Cleanly, the way you were taught",
				"We supply half the region",
				"Blood, meat, and leather",
				"A hundred lifetimes of the trade"
			]
		}
,
		{	// ---- DAEMON HARBINGERS: Abaddon's advisor-daemons (all NE) ----
			// AESDURATH -- The Pale Dowager. NE. Dagger. Immortality, liches, magical
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% serves Aesdurath, the Pale Dowager, a daemon of Abaddon who took immortality, liches and the deaths that magic causes as her portfolio and her pride. Her rite is the simplest kind of communion: eat a portion of something killed by a spell, and take a little of that unmaking into yourself. From %factionfortressname% they have outlived their own founders and most of their heirs, and they will tell you, patiently, that everything the shattering broke was only ever going to break, and that the trick is to be the thing that does not.",
			Mottos = [
				"Be the thing that does not break",
				"The Pale Dowager outlived her own cult",
				"It was always going to break",
				"Eat a little of the unmaking",
				"We buried our founders long ago",
				"Patiently, and forever"
			]
		},
		{	// LAIVATINIEL -- The Chains and the Cradle. NE. Light crossbow. Anxiety, coddling,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% belongs to Laivatiniel, the Chains and the Cradle, whose sign is a child's rattle bound in iron and whose concern is the love that does not let go. Her rite is to spend an hour making a careful likeness of your mother or your father, and then to eat it. In %factionfortressname% the children are cherished past all reason and never permitted to leave, the doors are kind and locked, and every heir is loved so completely and so close that by the time they might have ruled there is nothing left of them to do it.",
			Mottos = [
				"The doors are kind, and locked",
				"Loved past all reason",
				"The Chains and the Cradle never let go",
				"No heir of ours need ever leave",
				"Cherished until there is nothing left",
				"Stay. Stay. Stay."
			]
		},
		{	// SLANDRAIS -- The Watcher in the Walls. NE. Shortbow. Lechery, love potions,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps Slandrais, the Watcher in the Walls, daemon of lechery and love-philtres and the wanting that curdles into obsession. His rite is to sleep the night on the grave, or beside the corpse, of someone you knew while they lived. From %factionfortressname% they do not forget a face they have once wanted, in life or after it, and they are watching more of the region than the region suspects, and the thing they feel while they watch is not quite love and has never once been mistaken for kindness.",
			Mottos = [
				"Not quite love, and never kindness",
				"The Watcher forgets no face",
				"Wanted, in life or after it",
				"We are watching more than you think",
				"It does not stop at the grave",
				"Sleep beside what you wanted"
			]
		}
,
		{	// ---- DEMON LORDS: the Abyssal aristocracy (all CE) ----
			// BAPHOMET -- Lord of the Minotaurs. CE. Glaive. Beasts, labyrinths, minotaurs.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% keeps Baphomet, Lord of the Minotaurs, demon of beasts and labyrinths and the mind that loses its own thread. His rite is to sit without moving for the better part of an hour and then speak fifty separate observations of the room around you into a hollowed bull's horn, so that the walls are numbered and cannot close on you. In %factionfortressname% the corridors do not go where you expect, the plan of the place is known to nobody living, and guests who wander are not always seen again -- which the house calls the god keeping what is his.",
			Mottos = [
				"The god keeps what is his",
				"Number the walls before they close",
				"No living soul holds the plan",
				"The corridors do not go where you expect",
				"Lord of the Minotaurs owns the maze",
				"Some guests wander"
			]
		},
		{	// DESKARI -- Lord of the Locust Host. CE. Scythe. Chasms, infestations, locusts.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.Sheriff
			],
			Description = "House %noblehousename% belongs to Deskari, Lord of the Locust Host, the demon who opens the ground and lets the swarm pour through. His worship is to lie still and let the vermin walk on you, or, lacking them, to lie facedown in a dug trench and pray into the soil while you score your own skin with bone. From %factionfortressname% they treat the land itself as a thing to be hollowed and eaten, and where their border has stood a while the fields go strange, and the wells taste of something, and the neighbours have started counting their children at dusk.",
			Mottos = [
				"Counting their children at dusk",
				"The ground opens where he wills",
				"The land is a thing to be eaten",
				"Let the vermin walk on you",
				"Lord of the Locust Host is hungry",
				"The wells taste of something now"
			]
		},
		{	// MESTAMA -- The Mother of Witches. CE. Punching dagger. Cruelty, deception, hags.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% serves Mestama, the Mother of Witches, demon of cruelty and deception and the covens that traffic in both. Her rite is patient: watch someone who does not follow her, unseen, for a full hour, and then do the one small exact thing that will break them into tears or fury. From %factionfortressname% the house knows the private wound of everyone who matters for a hundred miles, offers each of them nothing but sympathy to their faces, and picks, very precisely, when to press.",
			Mottos = [
				"The one small exact thing",
				"She knows your private wound",
				"Sympathy to your face",
				"The Mother of Witches watches first",
				"Very precisely, when to press",
				"Every coven, one purpose"
			]
		},
		{	// NOCTICULA (ELDER) -- Our Lady in Shadow. CE. Hand crossbow. Assassins, darkness,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% keeps Nocticula as she was before she climbed out of it -- Our Lady in Shadow, demon of assassins and darkness and appetite, and every murder done unseen. Her rite mixes drugged visions, the acts of the body, and a pint of shed blood into one long dark hour. From %factionfortressname% the killers go out quiet and come back quieter, and somewhere on the same map, if the world has dealt it so, another house keeps the queen she managed to become -- and neither the Lady in Shadow nor the Redeemer will say which of them is the lie.",
			Mottos = [
				"Which of them is the lie",
				"Our Lady in Shadow was here first",
				"The killers come back quieter",
				"Before she climbed out of it",
				"Every murder done unseen",
				"She became something. This is what she left."
			]
		},
		{	// ORCUS -- Prince of Undeath. CE. Heavy mace. Death, necromancy, wrath. Symbol:
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Tyrant,
				::Const.FactionTrait.Warmonger
			],
			Description = "House %noblehousename% is sworn to Orcus, Prince of Undeath, demon of death and necromancy and the wrath that outlives the body. His rite grinds half a pound of bone from a thinking creature's skeleton, stirs it to grey paste with water, and eats it at the end of an hour's prayer. From %factionfortressname% the dead do not stay down and are not meant to -- they hold the walls, work the fields, and fill the ranks, and the living of the house are outnumbered by their own ancestors, which they consider only proper.",
			Mottos = [
				"Outnumbered by their own ancestors",
				"The dead do not stay down",
				"The Prince of Undeath fills the ranks",
				"They hold the walls and work the fields",
				"Wrath outlives the body",
				"Which they consider only proper"
			]
		},
		{	// XOVERON -- The Horned Prince. CE. Ranseur. Gargoyles, gluttony, ruins. Symbol:
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% keeps Xoveron, the Horned Prince, demon of gargoyles and gluttony and the slow patience of ruins. His rite is to perch high over the land and hold perfectly still for an hour -- and in a town, where a watcher might be noticed, anyone who realises the gargoyle is alive must be dead before the hour is out. From %factionfortressname% they hold the high broken places nobody else wants, they wait without any sign of impatience, and they are always, always looking down at you.",
			Mottos = [
				"Always looking down at you",
				"The Horned Prince does not hurry",
				"Hold still until the hour is out",
				"We keep the high broken places",
				"Anyone who notices does not last",
				"Patience, and stone"
			]
		}
,
		{	// ---- THE ELDEST: archfey lords of the First World ----
			// THE LOST PRINCE -- The Melancholy Lord. N. Quarterstaff. Forgotten things,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps the Lost Prince, the Melancholy Lord, an Eldest of the First World whose realm is a black tower falling slowly to pieces and whose concern is everything anyone has ever let themselves forget. His rite is quiet and costs something real: write down a memory you have never told a soul and have never burned before, and burn it now. In %factionfortressname% the archives are vast and full of gaps, the family keeps no grudges because it keeps no history, and there are rooms in the house that even the eldest of them cannot quite remember the purpose of.",
			Mottos = [
				"It keeps no grudges, and no history",
				"Write it down. Burn it.",
				"The Melancholy Lord forgets you kindly",
				"Rooms nobody remembers the purpose of",
				"The tower falls slowly to pieces",
				"Every memory, and then none"
			]
		},
		{	// COUNT RANALC -- The Traitor. CN. Rapier. Betrayal, exiles, shadows. Symbol: eye
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% serves Count Ranalc, the Traitor, an Eldest cast out of the First World's court for a betrayal nobody now agrees the shape of, whose sign is an eye weeping a single black tear. His rite is to sit in shadow and whisper the name of one you mean to betray, or who betrayed you, and precisely what you intend to do about it. From %factionfortressname% they gather every exile and turncoat the other houses have cast off, keep each one's grievance filed and sharpened, and are loyal, absolutely, right up until the hour it stops being worth it.",
			Mottos = [
				"Loyal until it stops being worth it",
				"The Traitor was cast out first",
				"Every exile has a use",
				"Filed, and sharpened",
				"Whisper it to the shadow",
				"Nobody agrees the shape of it"
			]
		},
		{	// THE LANTERN KING -- The Laughing Lie. CN. Dagger. Laughter, mischief,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% follows the Lantern King, the Laughing Lie, mightiest and least trustworthy of the Eldest, who finds the whole of creation funny and reserves the right to rearrange any part of it for a better joke. His rite is to light a small lantern and tell it a jest, or the tale of a prank you once played -- a new one every time, for he has heard the old ones. From %factionfortressname% the laughter carries a long way after dark, the envoys arrive wearing faces that are not their own, and nobody who has dealt with the house is entirely sure the deal has finished being funny.",
			Mottos = [
				"Not sure the deal has finished being funny",
				"A new joke every time",
				"The Laughing Lie has heard the old ones",
				"Faces that are not their own",
				"The laughter carries after dark",
				"He rearranges it for a better joke"
			]
		}
,
		{	// ---- EMPYREAL LORDS: the celestial tier (good counterweight) ----
			// NESHEN -- Knight of the Steel Lash. LG. Ranseur. Penitence, repentance,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% serves Neshen, the Knight of the Steel Lash, an angel of penitence who holds that a wrong is not undone by feeling sorry for it but by paying it back in full, in the open, where the wronged can see. His faithful keep the lash for their own backs and no one else's -- the suffering is owed, not inflicted -- and they will kneel in the square and name what they did before they ask any pardon. From %factionfortressname% they forgive freely and excuse nothing, least of all themselves.",
			Mottos = [
				"Pay it back in the open",
				"The lash is for our own backs",
				"Forgive freely, excuse nothing",
				"Name it before you ask pardon",
				"The Knight of the Steel Lash keeps the account",
				"Sorry is not enough"
			]
		},
		{	// RAGATHIEL -- General of Vengeance. LG. Bastard sword. Chivalry, duty, vengeance.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Warmonger
			],
			Description = "House %noblehousename% swears to Ragathiel, the General of Vengeance, half-fiend son of a Horseman who chose the light and became an angel of wrath aimed only at the guilty. His rite requires a wrongdoer proven -- not merely evil-hearted but caught in the deed -- put to death in his name, and never one drop past what the crime is worth. From %factionfortressname% they hunt the deserving with terrible patience, take no innocent with the guilty, and hold that mercy and the sword are the same duty seen from two sides.",
			Mottos = [
				"Never past what the crime is worth",
				"The guilty, and only the guilty",
				"Rage focused is a virtue",
				"He chose the light",
				"Mercy and the sword, one duty",
				"Proven, then punished"
			]
		},
		{	// SORALYON -- The Mystic Angel. NG. Heavy pick. Guardians, magic, monuments.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps Soralyon, the Mystic Angel, guardian of monuments and old magic, who alone among the powers of light looks on the works the runelords left and sees not a horror to be pulled down but a wonder to be kept standing. His rite is to carry a small marble likeness of some real monument and trace its every surface by touch before sleeping. From %factionfortressname% they guard the ancient stones nobody else will go near, read the runes without flinching, and hold that a thing built to last was built for a reason worth remembering.",
			Mottos = [
				"A thing built to last was built for a reason",
				"Keep it standing",
				"The Mystic Angel does not flinch at runes",
				"We guard the stones nobody will approach",
				"Read them without fear",
				"Worth remembering"
			]
		},
		{	// ASHAVA -- True Spark. CG. Bladed scarf. Dancers, lonely spirits, moonlight.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.ManOfThePeople,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps Ashava, the True Spark, an azata of moonlight who dances for the lonely dead so that no spirit need be alone in the dark. Her rite is a dance under the open moon, and where there is no moon, or where someone is watching, a prayer for the forgotten dead and a single lit lantern left in a dark place. From %factionfortressname% they tend the graves the other houses let go to weeds, sit with the dying who have no one, and leave a light burning in every window every night, for whoever is still out there.",
			Mottos = [
				"A light in every window",
				"No spirit alone in the dark",
				"She dances for the forgotten dead",
				"We sit with those who have no one",
				"Leave a lantern",
				"For whoever is still out there"
			]
		},
		{	// VALANI -- Fireshaker. CG. Club. Change, growth, primal forces. Symbol: volcano
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% follows Valani, the Fireshaker, an azata of change and primal growth who teaches that nothing is ever truly lost, only turned into the next thing. His rite is to burn something of real worth, then roll in the cooling cinders to put out the last of it and grind the ash into the earth, so that the fire feeds what grows after. From %factionfortressname% they welcome the storm, plant in the burn-scar, and hold -- alone among the houses, and against everything the shattering seemed to prove -- that the world ending was only the world beginning again.",
			Mottos = [
				"The world ending was the world beginning",
				"Nothing is lost, only turned",
				"Plant in the burn-scar",
				"The Fireshaker welcomes the storm",
				"Burn it, then grow it",
				"Against everything the shattering proved"
			]
		}
,
		{	// ---- Further fiends ----
			// TREERAZER -- Lord of the Blasted Tarn. CE. Greataxe. Corruption of nature,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Marauder,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% is sworn to Treerazer, the Lord of the Blasted Tarn, a demon squatting so long in one wood that the wood became him -- nature turned inside out, sap to poison, green to rot. His rite is to eat carrion riddled with hallucinogenic fungus and sit with the visions it brings. From %factionfortressname% the corruption spreads outward at the pace of a slow tide: the trees at the edge of their land die standing, the game comes back wrong, and the border can be found in the dark by the smell alone. They are not conquering the country. They are digesting it.",
			Mottos = [
				"They are digesting the country",
				"Sap to poison, green to rot",
				"The border can be found by smell",
				"Lord of the Blasted Tarn spreads slowly",
				"The game comes back wrong",
				"Not conquest. Digestion."
			]
		},
		{	// NIGHTRIPPER -- The Promise of Pain. CE. Bastard sword. Botched executions, pits.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% keeps Nightripper, the Promise of Pain, demon of the execution that goes wrong on purpose -- the drop that does not break the neck, the blade that stops halfway. Its rite is a patient series of cuts, breath held to the edge of blacking out between them. In %factionfortressname% there is a great deal of law and a great deal of sentencing, and the sentences are carried out slowly, in public, by people who are very good at making sure they take a long time, because the point was never the death.",
			Mottos = [
				"The point was never the death",
				"The drop that does not break the neck",
				"A great deal of law, slowly applied",
				"The Promise of Pain is kept",
				"They are very good at taking their time",
				"In public, and unhurried"
			]
		},
		{	// NERGAL -- The Slow Death. LE. Spiked chain. Atrocity, pestilence, war. Symbol: sun
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Warmonger,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% serves Nergal, the Slow Death, an infernal duke whose sign is the sun coming up over a field of the dead, and whose concern is atrocity done properly and filed in triplicate. War, to Nergal, is not fury -- it is administration, and plague is only a slower campaign. From %factionfortressname% they wage their wars like clerks: the burned village is a line in a ledger, the poisoned well a scheduled task, and every horror is somebody's assigned duty, discharged on time and without malice, which is the worst of it.",
			Mottos = [
				"Every horror is somebody's duty",
				"War is administration",
				"On time, and without malice",
				"The sun comes up over the dead",
				"Plague is a slower campaign",
				"Filed in triplicate"
			]
		},
		{	// FURCAS -- Knight of the Laurels. LE. Trident. Duty, flames, herbalism. Symbol:
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Tyrant
			],
			Description = "House %noblehousename% keeps Furcas, the Knight of the Laurels, an infernal duke of duty and flame who is also, of all things, a healer -- and whose cures come with terms. His rite mixes a herbal draught, drinks half, and burns the rest. From %factionfortressname% the sick are genuinely made well: the physicians are skilled, the medicine works, and the price is written into the recovery, so that a man walks out cured and finds himself, by degrees he never quite agreed to, belonging to the house that saved him.",
			Mottos = [
				"Cured, and accounted for",
				"The medicine works. So do the terms.",
				"You walk out well, and ours",
				"The price is in the recovery",
				"Duty, flame, and a good salve",
				"By degrees you never quite agreed to"
			]
		},
		{	// MURNATH -- The Horned Rat. CE. Short sword. Rats, sewers. Symbol: horned rat with
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Collector,
				::Const.FactionTrait.Marauder
			],
			Description = "House %noblehousename% will not say it serves Murnath, the Horned Rat, but the oldest families of %factionfortressname% came up out of the undercity long ago, took a fortress, took names, and never once stopped running the tunnels beneath it. His rite is to float in the filth of the sewers and pray. The banner is respectable now. The knives are not, the tunnels go everywhere the walls pretend to stop, and the house was there before the city and is still, quietly, underneath all of it.",
			Mottos = [
				"Underneath all of it",
				"We were here before your walls",
				"The banner is respectable now",
				"The tunnels go everywhere",
				"The Horned Rat rules the drains",
				"Quietly, and everywhere"
			]
		}
,
		{	// ---- MONITORS: outsiders of pure alignment ----
			// KERKAMOTH -- The Waiting Void. LN. Warhammer. Emptiness, entropy, stillness.
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Sheriff,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps Kerkamoth, the Waiting Void, an inevitable of stillness and entropy who is not cruel and not in any hurry, because everything comes to him in the end regardless. His rite is to take a cluttered place and empty it -- clear out half of everything, to keep or give or destroy, until what remains can be seen whole. From %factionfortressname% they govern by subtraction: fewer laws, fewer courtiers, fewer possessions each year, on the principle that the world is quietly returning to the empty and the wise meet it halfway.",
			Mottos = [
				"Govern by subtraction",
				"Everything comes to him regardless",
				"Meet the empty halfway",
				"Fewer laws, fewer courtiers, each year",
				"The Waiting Void is not in a hurry",
				"Clear it until it can be seen whole"
			]
		},
		{	// NARRISEMINEK -- The Crownless, the Maker of Kings. CN. Handaxe. Ascendance,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% follows Narriseminek, the Crownless, the Maker of Kings, a protean of pure chaos and revelation who raises others to thrones and wears no crown of their own. Their rite is to stand inside a ring of fire and chant until it burns down to coals. From %factionfortressname% they crown and counsel and elevate, put other houses' heirs on other houses' seats and whisper the future in their ears, and hold nothing in their own name -- which makes them, in a shattered age hungry for a king, quietly the most dangerous house on the map.",
			Mottos = [
				"He makes kings and wears no crown",
				"We hold nothing in our own name",
				"The most dangerous house on the map",
				"Crown them, counsel them, keep nothing",
				"The Crownless whispers the future",
				"Someone must make the king"
			]
		},
		{	// PHLEGYAS -- The Consoler of Atheists. N. Longbow. Atheists, legacies,
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.ManOfThePeople,
				::Const.FactionTrait.Collector
			],
			Description = "House %noblehousename% keeps Phlegyas, the Consoler of Atheists, an usher of the dead who tends especially to those who died believing in nothing at all, and asks only that the living make something lasting of them. His rite is an hour spent turning the dead into a thing that endures -- a ring woven from a loved one's hair, a name cut in stone, a law written to outlast its author. From %factionfortressname% they keep the memory of everyone who mattered and much of what they built, and hold that a person is not truly gone while the work still stands.",
			Mottos = [
				"Not gone while the work still stands",
				"He consoles those who believed in nothing",
				"Make something lasting of the dead",
				"A name cut in stone",
				"The Consoler asks only that they endure",
				"Hair, and stone, and law"
			]
		}
,
		{	// VEVELOR of the Broken Dream -- velstrac demagogue, demigod. LE. Whip. Illusion of
			Traits = [
				::Const.FactionTrait.NobleHouse,
				::Const.FactionTrait.Schemer,
				::Const.FactionTrait.ManOfThePeople
			],
			Description = "House %noblehousename% keeps Vevelor of the Broken Dream, a velstrac demagogue older than the shadow-kind's exile from Hell, whose realm of Cliffgrip sits at the lip of the same chasm the Midnight Lord climbed out of -- for Vevelor is Zon-Kuthon's neighbour, and his heretic. Where the Midnight Lord preaches an honest joy in servitude, Vevelor preaches freedom: he was mortal once and chose to be remade, and he will show you the path to your own perfection whether or not you ever asked to see it. His symbol is a broken chain, and that is the whole trick of him, because his concern is not freedom but the illusion of it -- the convert walks in believing they are casting off every bond and walks out having chosen, freely and gratefully, a heavier one. His rite is a wound taken willingly and dwelt in, the pain named aloud as a door rather than a hurt, until the flesh agrees. From %factionfortressname% they speak the language of liberation to everyone the age has broken -- the dispossessed, the enslaved, the ruined -- and they mean by it the exact opposite of what is heard, and where their preaching runs up against a house that keeps the Midnight Lord straight, the two cults of the shadow loathe each other with the particular venom kept only for a heresy, for they use the same needles and the same dark and cannot agree what any of it is for.",
			Mottos = [
				"Freedom is the trick, not the offer",
				"You will choose a heavier chain, and thank us",
				"The Midnight Lord's neighbour, and his heretic",
				"We speak liberation and mean its opposite",
				"The broken chain is the whole of it",
				"The same needles -- a different lie"
			]
		}
	]
];
::logInfo("Golarion: pantheon loaded, " + ::Const.GetFactionArchetypesList().len() + " god archetypes (set the Legends 'Factions' setting to at most this many)");
