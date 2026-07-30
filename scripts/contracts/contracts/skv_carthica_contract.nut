this.skv_carthica_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Deck        = null,
		CrawlIndex  = 0,
		Points      = 0,
		Wins        = 0,
		GotRing     = false,
		Humiliated  = false,
		Discreet    = false,
		HasLetter   = false,
		HasCloak    = false,
		Betrayed    = false,
		Done        = false,
		Decided     = false,
		OutcomeText = "",
		OutcomeRows = null,
		RoomRows    = null,
		RoomText    = "",
		ActorName   = "",
		FightWon    = false,
		FightFled   = false,
		SpottedTail = false,
		LastContest = "",
	},

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_carthica";
		this.m.Name = "Carthica's Pride";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 14.0;
		this.m.Category = this.Const.Contracts.Categories.Hunt;
		this.m.DescriptionTemplates = [
			"A young lord of a noble house has had his family signet lifted from his own hand by a pair of Sczarni cutpurses, and he wants it back before the theft is noticed: the thieves run down, the ring recovered, the pair of them shamed in front of their own - and his name kept well out of it. He hires through a fixer, and he pays for discretion.",
			"A proud young noble was robbed of his family signet by two Sczarni pickpockets, and would sooner spend a fortune than let it be known he was made a fool of in his own streets. Recover the ring, humble the thieves, and keep his name clean. The pay is good, and staying quiet is half the job.",
		];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(75, 120) * 0.01;

		this.m.Payment.Pool = 1000 * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();

		if (this.Math.rand(1, 100) <= 33)
		{
			this.m.Payment.Advance = 0.2;
			this.m.Payment.Completion = 0.8;
		}
		else
		{
			this.m.Payment.Completion = 1.0;
		}

		this.contract.start();
	}

	function brokerFee()
	{
		return 250 + this.Math.round(300 * this.getDifficultyMult());
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Run the Sczarni thieves to ground in the backstreets"
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{

				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = this.Contract.m.Done
					? [ "Report to Carthica" ]
					: [ "Deal with the Sczarni thieves in " + (this.Contract.m.Home != null && !this.Contract.m.Home.isNull() ? this.Contract.m.Home.getName() : "the town") ];
			}

			function update()
			{

				if (this.Contract.m.FightWon)
				{
					this.Contract.m.FightWon = false;
					this.Contract.recoverAlley();
					this.Contract.m.CrawlIndex = this.Contract.m.CrawlIndex + 1;
					this.Contract.setScreen("AlleyAfter");
					this.World.Contracts.showActiveContract();
					return;
				}

				if (this.Contract.m.FightFled)
				{
					this.Contract.m.FightFled = false;
					this.Contract.setScreen("AlleyRoom");
					this.World.Contracts.showActiveContract();
					return;
				}

				if (this.Contract.m.Done) return;

				if (this.Contract.m.Deck == null
					&& this.Contract.m.Home != null && !this.Contract.m.Home.isNull()
					&& this.Contract.isPlayerAt(this.Contract.m.Home))
				{
					this.Contract.m.Deck = this.Contract.assembleDeck();
					this.Contract.m.CrawlIndex = 0;
					this.Contract.setScreen(this.Contract.nextScreen());
					this.World.Contracts.showActiveContract();
				}
			}

			function onCombatVictory( _combatID )
			{
				if (_combatID == "CarthicaFight") this.Contract.m.FightWon = true;
			}

			function onRetreatedFromCombat( _combatID )
			{
				if (_combatID == "CarthicaFight") this.Contract.m.FightFled = true;
			}
		});
	}

	function assembleDeck()
	{
		return ["broker", "tail", "garbage", "alley", "courtyard", "door", "arm", "rail", "dagger", "hang", "cards"];
	}

	function roomScreenFor( _key )
	{
		if (_key == "broker")    return "BrokerRoom";
		if (_key == "tail")      return "TailRoom";
		if (_key == "garbage")   return "GarbageRoom";
		if (_key == "alley")     return "AlleyRoom";
		if (_key == "courtyard") return "CourtyardRoom";
		if (_key == "door")      return "DoorRoom";
		if (_key == "arm")       return "ArmRoom";
		if (_key == "rail")      return "RailRoom";
		if (_key == "dagger")    return "DaggerRoom";
		if (_key == "hang")      return "HangRoom";
		if (_key == "cards")     return "CardsRoom";
		return "Finale";
	}

	function nextScreen()
	{
		if (this.m.Deck == null || this.m.CrawlIndex >= this.m.Deck.len()) return "Finale";
		return this.roomScreenFor(this.m.Deck[this.m.CrawlIndex]);
	}

	function resolveRoom( _rows, _text )
	{
		this.m.RoomRows = _rows;
		this.m.RoomText = _text;
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return "RoomResult";
	}

	function vignette()
	{
		local pool = [
			"A rat trots past with something pale and finger-like in its jaws, unhurried, as if it has somewhere to be.",
			"A flower-girl falls in behind the company for half a street, singing a song with your deaths worked politely into the last verse, then peels away.",
			"A drunk slumped in a doorway lifts his head as you pass and says, quite clearly, \"you're not so lucky as you think,\" then goes back to sleep.",
			"Two children are playing dice against a wall for teeth. They do not look up.",
			"A shuttered shrine to Calistria - wasp-and-dagger over the door - has fresh candles burning behind the grille. Someone here still prays for revenge.",
			"A butcher hoses pink water into the gutter and watches you the whole time he does it.",
		];
		return pool[this.Math.rand(0, pool.len() - 1)];
	}

	function flourishFor()
	{
		local k = this.m.LastContest;
		if (k == "arm") return {
			opt = "{Needle Jhaari while he nurses that arm. (risky)}",
			win = "[img]gfx/ui/events/event_24.png[/img]{Someone leans over Jhaari and says a low thing about the size of a man who loses at his own table - and the room comes apart at the thief's expense. He goes red; the crowd goes to you.}",
			lose = "[img]gfx/ui/events/event_24.png[/img]{The jab at Jhaari misses - he just flexes the winning arm, and the room laughs with HIM, not you.}" };
		if (k == "rail") return {
			opt = "{Spin the room a tall tale about Atharius. (risky)}",
			win = "[img]gfx/ui/events/event_24.png[/img]{You give the crowd a story about Atharius - half invented, all of it landing - and by the end the rail-walker is laughing at himself with everyone else. The room warms.}",
			lose = "[img]gfx/ui/events/event_24.png[/img]{The tale wanders and dies; Atharius takes a slow, mocking bow while it does, and the room enjoys HIM finishing it for you.}" };
		if (k == "dagger") return {
			opt = "{Crack wise about Atharius's aim. (risky)}",
			win = "[img]gfx/ui/events/event_24.png[/img]{A quick word about where Atharius really ought to point that blade, and the room howls - the thief flips the dagger and concedes the laugh.}",
			lose = "[img]gfx/ui/events/event_24.png[/img]{The joke clatters wide of the mark, same as a bad throw, and Atharius is the first and loudest to say so.}" };
		if (k == "hang") return {
			opt = "{Play the crowd while the blood's in your head. (risky)}",
			win = "[img]gfx/ui/events/event_24.png[/img]{Upside down and purple-faced, your man keeps up a patter that has the whole yard weeping - there is nothing a crowd loves like nerve that jokes back. The room is a little more yours.}",
			lose = "[img]gfx/ui/events/event_24.png[/img]{The banter comes out a strangled wheeze, the crowd winces, and the thieves make sure everyone hears them enjoy it.}" };
		if (k == "cards") return {
			opt = "{Crow about Jhaari's rotten luck. (risky)}",
			win = "[img]gfx/ui/events/event_24.png[/img]{You raise the pot for the room and toast Jhaari's famously terrible luck - and the gambler cannot even deny it, which is the funniest part of all. The room roars for you.}",
			lose = "[img]gfx/ui/events/event_24.png[/img]{The dig at Jhaari's luck falls flat - he fans his winnings, raises a brow, and lets the coin make your point for you. The room cools.}" };
		return {
			opt = "{Play to the crowd - a jest, a swagger. (risky)}",
			win = "[img]gfx/ui/events/event_24.png[/img]{Someone turns and says a thing to the room - quick, filthy, perfectly timed - and the whole cellar loses itself laughing. The room warms.}",
			lose = "[img]gfx/ui/events/event_24.png[/img]{The jest dies in the air. A cough. A groan. Worse than silence, and the thieves enjoy it.}" };
	}

	function resolveContest( _res, _winText, _loseText, _key )
	{
		this.m.LastContest = _key;
		local rows = [];
		local text;
		if (_res.ok)
		{
			this.m.Points = this.m.Points + 2;
			this.m.Wins = this.m.Wins + 1;
			if (_res.actor != null && ("XP" in ::Skv)) rows = ::Skv.XP.grant(_res.actor, 150);
			text = _winText;
		}
		else
		{
			this.m.Points = this.m.Points - 1;
			text = _loseText;
		}
		this.m.RoomRows = rows;
		this.m.RoomText = text;
		this.m.CrawlIndex = this.m.CrawlIndex + 1;
		return "ContestFlourish";
	}

	function newFightProperties()
	{
		local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
		p.CombatID = "CarthicaFight";
		p.Tile = this.World.State.getPlayer().getTile();
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Center;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Circle;
		p.TerrainTemplate = "tactical.plains";
		p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
		p.LocationTemplate.Template[0] = "tactical.ruins";
		p.LocationTemplate.Fortification = this.Const.Tactical.FortificationType.None;
		return p;
	}

	function banditFactionID()
	{
		return this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits).getID();
	}

	function startAlleyFight()
	{
		this.m.FightWon = false;
		this.m.FightFled = false;
		local p = this.newFightProperties();
		local fac = this.banditFactionID();

		local budget = 73 * this.getDifficultyMult() * this.getScaledDifficultyMult();
		if (this.m.SpottedTail) budget = budget * 0.9;
		this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn.BanditRaiders, budget, fac);
		::Skv.dbg("Skv.Carthica alley budget=" + budget);
		this.World.Contracts.startScriptedCombat(p, false, true, true);
	}

	function recoverAlley()
	{
		this.m.HasCloak = true;
		this.m.HasLetter = true;
		local coin = this.Math.rand(60, 120);
		this.m.RoomRows = ::Skv.Loot.haul([], coin);
		this.m.RoomText = "[img]gfx/ui/events/event_63.png[/img]{Urie is the last to fall, and the first the company searches. Under his coat: a dark Sczarni half-cloak with the wasp stitched small at the collar - the kind of thing that lets a man walk into the wrong tavern as though he belongs - and a folded letter, still sealed, in a careful hand. %SKVNAME%%randombrother%%SKVNAME_OFF% breaks it and reads slowly. %SPEECH_ON%It's orders. From one 'Pictor' to our friend here. The ring was never the prize - the thieves were spending too free, so the family looked to see who they'd rolled, and it was your lord Carthica. His people run ships. They mean to take HIM, not the ring, and ransom him back to his own house.%SPEECH_OFF% He folds it away. Worth knowing. Worth telling.}";
	}

	function homeFaction()
	{
		try { return this.World.FactionManager.getFaction(this.getFaction()); }
		catch (e) { return null; }
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "A Matter of Some Delicacy",
			Text = "[img]gfx/ui/events/event_23.png[/img]{The meeting is not in a hall. It is in the back of a low tavern, the sort of place a lord's betters would never be seen - which is rather the point. %SKVNAME%Natasha Corvina%SKVNAME_OFF%, cool and unhurried, does the talking; %SKVNAME%Carthica%SKVNAME_OFF% himself sits stiff beside her, a young man in good cloth doing his best not to look like he has been crying with rage. %SPEECH_ON%Two nights ago a pair of Sczarni cutpurses took my client's family signet from his own hand, in his own street, and laughed while they did it,%SPEECH_OFF% Natasha says. %SPEECH_ON%He wants three things. The ring, back in his hand. The thieves, made small in front of their own kind - publicly, so it is FELT. And his name kept entirely out of it: a lord who cannot hold his own ring is a lord who gets talked about, and a signet in a forger's hands is worse. You will be paid through me, the balance when the ring is back in his hand.%SPEECH_OFF% Carthica speaks once, tight: %SPEECH_ON%Humble them. I do not care how.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = false,
			ShowDifficulty = true,
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{We will get his ring back - quietly.}",
						function getResult() { return "Negotiation"; }
					}
				];
				if (this.World.getPlayerRoster().getAll().len() >= 2)
				{
					this.Options.push({
						Text = "{Sczarni. Who exactly are we crossing?}",
						function getResult() { return "Lore"; }
					});
				}
				this.Options.push({
					Text = "{Find another company.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "Lore",
			Title = "The Sczarni",
			Text = "[img]gfx/ui/events/event_59.png[/img]{%SKVNAME%%randombrother%%SKVNAME_OFF% has crossed their sort before. %SPEECH_ON%Sczarni. Varisian crime families - pickpockets, cutpurses, confidence men, working the fairs and the backstreets wherever the Varisian caravans pass. They rob outsiders, not their own, and they rarely kill; a corpse is bad for business. Cross one family and you have crossed THAT family - not the whole people, who mostly want nothing to do with them - but a family keeps its accounts.%SPEECH_OFF% %SKVNAME%%randombrother2%%SKVNAME_OFF% spits. %SPEECH_ON%And when a family does need a throat cut, it does not dirty its own hands - it hires an executioner, one of those cold professionals, all code and price and no malice. So we do not go in swinging and turn the quarter against us. We find these two, we take the ring, we make the right people SEE them lose it - and we keep the lord's name out of our mouths. That last part is half the coin.%SPEECH_OFF% The first man nods. %SPEECH_ON%A job of the quiet kind. Those are the ones that go loud when you get them wrong.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{ Text = "{Enough. The terms again.}", function getResult() { return "Task"; } }
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "BrokerRoom",
			Title = "Lady Lilianna",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/event_106.png[/img]{" + this.Contract.vignette() + "\n\nThe only name Carthica had was a place that is not a place: the thieves run with 'The Urgent Messenger.' Finding out what that means costs, and in this quarter the cost is set by %SKVNAME%Lady Lilianna%SKVNAME_OFF% - an information-broker who keeps a scented parlour above a Calistrian pleasure-house and knows the worth of everything. %SPEECH_ON%The Urgent Messenger,%SPEECH_OFF% she says, amused, turning a ringed hand - and on one finger a plain grey ring you had not noticed sits a shade too still. %SPEECH_ON%Everyone asks for him as though he were a man. I will tell you what he actually is, and where. My price is coin - or, if your purse is shy, a secret. One of yours, and a TRUE one; I wear charms that redden at a lie, gifts from magi who owed me. Something that would cost you to have known. I collect them.%SPEECH_OFF%}";
				this.Options = [
					{
						Text = "{Pay her fee. (-" + this.Contract.brokerFee() + " crowns)}",
						function getResult()
						{
							local rows = [ ::Legends.EventList.changeMoney(-this.Contract.brokerFee()) ];
							return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/event_106.png[/img]{The coin goes into a lacquered box without being counted - she counted it by the sound. %SPEECH_ON%The Urgent Messenger is a door, not a fellow,%SPEECH_OFF% she says. %SPEECH_ON%A thieves' tavern with no sign, off a dead courtyard in the low quarter. Your pair drink there. Mind the way in - and mind that others are minding your pair, too. The Sczarni have noticed how free those two spend.%SPEECH_OFF%}");
						}
					},
					{
						Text = "{Give her a secret. (a brother pays in peace of mind)}",
						function getResult()
						{
							local pool = this.World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
							local rows = [];
							if (pool.len() > 0)
							{
								local bro = pool[this.Math.rand(0, pool.len() - 1)];
								rows.push(::Legends.EventList.changeMood(bro, -25, "gave up a secret to a broker"));
							}
							return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/event_106.png[/img]{One of the company tries her first with something small and safe - a common thing, half true. The grey ring on her finger warms to a dull red, and she laughs without warmth. %SPEECH_ON%That is no secret, and not worth one in kind. My charms do not care for hollow men.%SPEECH_OFF% So he leans in and gives her a REAL one, low, and the parlour cools by a degree; her smile does not change but her eyes do - she has it now, and she will keep it. %SPEECH_ON%Better. A fair trade,%SPEECH_OFF% she murmurs. %SPEECH_ON%The Urgent Messenger is a door, not a fellow - a thieves' tavern with no sign, off a dead courtyard in the low quarter. Your pair drink there. And do hurry: the Sczarni have noticed how free those two spend, and the Sczarni are not patient people.%SPEECH_OFF% Whoever spoke does not meet the others' eyes for a while.}");
						}
					},
					{
						Text = "{Half the lads swear it's a ship. Humour them - check the docks first?}",
						function getResult() { return "Docks"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Docks",
			Title = "The Wrong Boat",
			Text = "[img]gfx/ui/events/event_84.png[/img]{Because someone was absolutely certain of it, the company spends a good part of an afternoon tramping the wharves, asking hard-faced dockhands after a vessel called the Urgent Messenger. A fishwife laughs until she has to sit down. A one-eyed sailor swears he crewed her once - then asks a coin for the tale and describes, at great length, a ship that plainly never existed. By the time the light goes amber you have found three Messengers, none of them Urgent, and a very great deal of fish. Whatever the Urgent Messenger is, it does not float.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{...Right. It's a place, then. Back to Lilianna.}",
					function getResult() { return "BrokerRoom"; }
				}
			],
			function start() {}
		});

		this.m.Screens.push({
			ID = "TailRoom",
			Title = "Watched",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/event_84.png[/img]{" + this.Contract.vignette() + "\n\nLeaving Lilianna's, the back of your neck prickles. This quarter has eyes, and some of them have kept pace with you a street too long. If trouble is coming, the man who catches it first buys the company its footing.}";
				this.Options = [
					{
						Text = "{Watch the street - who's on us? (Perception)}",
						function getResult()
						{
							local res = ::Skv.Check.perception(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							if (res.ok)
							{
								this.Contract.m.SpottedTail = true;
								local rows = (res.actor != null && ("XP" in ::Skv)) ? ::Skv.XP.grant(res.actor, 150) : [];
								return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/event_84.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% makes them without breaking stride - two men in the press, wasp-marks half-hid at the collar, matching the company step for step. Sczarni. You do not let on. You drift the way they would rather you did not, toward ground of your own choosing, and quietly get your hands near your hilts. Whatever they meant to spring, they will not spring it clean.}");
							}
							return this.Contract.resolveRoom([], "[img]gfx/ui/events/event_84.png[/img]{Nothing but the ordinary press of the low quarter - washing overhead, a hawker crying figs, a dog nosing the gutter. If anyone is on you, they are better at it than your sharpest eye. You walk on into the narrowing streets, none the wiser.}");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "GarbageRoom",
			Title = "The Choked Passage",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/event_89.png[/img]{The way to the dead courtyard narrows to a gullet of refuse - knee-deep rotting fish, night-soil, things best not named, all of it stewing in the heat. There is no way round; the company has to wade it. Mind your footing and hold your breath, and pray your stomach is stronger than the stink.}";
				this.Options = [
					{
						Text = "{Pick a clean line through - and keep your gorge down.}",
						function getResult()
						{
							local pool = this.World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
							local rows = [];
							local sick = 0;
							foreach (bro in pool)
							{
								local sk = bro.getSkills();
								local chance = 60;
								if (sk.hasSkill("trait.sure_footing") || sk.hasSkill("trait.dexterous")) chance += 15;
								if (sk.hasSkill("trait.fat") || sk.hasSkill("trait.clumsy") || sk.hasSkill("trait.old") || sk.hasSkill("trait.clubfooted")) chance -= 12;
								if (this.Math.rand(1, 100) > chance && !sk.hasSkill("injury.sickness"))
								{
									local inj = ::new("scripts/skills/injury/sickness_injury");
									sk.add(inj);
									rows.push({ id = 10, icon = inj.getIcon(), text = "[color=" + this.Const.UI.Color.NegativeEventValue + "]" + bro.getName() + " is sick[/color]" });
									sick = sick + 1;
								}
							}
							local text = (sick == 0)
								? "[img]gfx/ui/events/event_89.png[/img]{The company wades the gullet with jaws set and eyes streaming, and every last man keeps his last meal where it belongs. You come out the far side reeking to the heavens - but whole, and ready. On, to whatever waits in the alley.}"
								: "[img]gfx/ui/events/event_89.png[/img]{The company wades in, and it gets the better of some. A boot bursts through something soft, a lungful of the reek - and one man doubles over heaving, which sets off another, and another. They come out the far side pale and gagging, guts still rolling, in no fit state for a fight. The rest haul them on.}";
							return this.Contract.resolveRoom(rows, text);
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AlleyRoom",
			Title = "The Garbage Alley",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/event_82.png[/img]{" + this.Contract.vignette() + "\n\nThe way to the dead courtyard runs through a garbage alley, close and stinking, and it is not empty. A lean man with a wasp inked on his throat steps into the light with a half-dozen at his back - %SKVNAME%Urie%SKVNAME_OFF%, an executioner the Sczarni keep on retainer, and he deals as plainly as his kind do. %SPEECH_ON%You're the lord's dogs,%SPEECH_OFF% he says, without heat. %SPEECH_ON%Here is a cleaner deal than the one you took. Your Carthica's people run ships; he's worth more to my employers as a guest than his ring is worth to you. Walk away - better, bring him to us - and you keep your skins and a purse besides. Refuse, and I earn my fee here in the muck. No hard feelings either way.%SPEECH_OFF%}";
				this.Options = [
					{
						Text = "{We took his coin. Blades - cut through them.}",
						function getResult()
						{
							this.Contract.startAlleyFight();
							return 0;
						}
					},
					{
						Text = "{...Name your price for the lord. (betray Carthica to the Sczarni)}",
						function getResult() { return "Betray"; }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "AlleyAfter",
			Title = "Off the Sczarni Executioner",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{

					Text = "{Pocket the cloak. On to the courtyard.}",
					function getResult() { return this.Contract.nextScreen(); }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You search the fallen and press on.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		this.m.Screens.push({
			ID = "Betray",
			Title = "A Kinder Deal",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{So it is done.}",
					function getResult()
					{
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}
				}
			],
			function start()
			{
				local rows = [];
				local bribe = this.Math.round(this.Contract.m.Payment.getOnCompletion() * 1.4) + this.Math.rand(200, 400);
				rows.push(::Legends.EventList.changeMoney(bribe));
				rows.push(::Legends.EventList.changeRenown(-40));
				this.World.Assets.addMoralReputation(-8);
				local nf = this.Contract.homeFaction();
				if (nf != null) nf.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Sold their own noble employer to the Sczarni");
				try {
					local bf = this.World.FactionManager.getFactionOfType(this.Const.FactionType.Bandits);
					if (bf != null) bf.addPlayerRelation(6, "Delivered a ransom prize to the Sczarni");
				} catch (e) {}
				this.Contract.m.Betrayed = true;
				this.Contract.m.GotRing = false;
				this.Contract.m.Done = true;
				this.Contract.m.Decided = true;
				this.Text = "[img]gfx/ui/events/event_62.png[/img]{You name a price, and Urie meets it without a flicker - which tells you it was low, but a coded man pays what he says he will. Carthica never learns how it was arranged; only that his own hired blades walked him into a quiet room and did not walk him out. The Sczarni pay well and say little. Some of the company will not look at the coin. Word of what you are travels ahead of you now, in the way that word does - and somewhere a noble house has a grievance with your name on it, and a lord's chair sits empty at a ransom table.}";
				this.List = rows;
			}
		});

		this.m.Screens.push({
			ID = "CourtyardRoom",
			Title = "The Dead Courtyard",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/event_111.png[/img]{" + this.Contract.vignette() + "\n\nThe courtyard is a dead end - soot-black walls, a dry fountain, a handful of ragged men dicing on a step who go very still as you enter. There is no tavern here that anyone can see. The door to the Urgent Messenger is somewhere in these walls, and it does not want to be found.}";
				this.Options = [
					{
						Text = "{Read the walls - someone find the seam. (Perception)}",
						function getResult()
						{
							local res = ::Skv.Check.perception(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							if (res.ok)
							{
								local rows = (res.actor != null && ("XP" in ::Skv)) ? ::Skv.XP.grant(res.actor, 150) : [];
								return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/event_74.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% works the soot with two fingers until it smears wrong - a hairline, then a whole door's worth of hairline, then the ghost of a latch under a false brick. A push, and the wall gives inward onto a stair going down, and warm noise, and lamplight. The Urgent Messenger.}");
							}

							this.Contract.m.RoomRows = [];
							this.Contract.m.RoomText = "[img]gfx/ui/events/event_111.png[/img]{The company runs its hands over cold brick and finds nothing but cold brick. The dicing men watch, and one of them grins around a bad tooth - he knows exactly where it is. This is going to cost after all.}";
							return "CourtyardBribe";
						}
					},
					{
						Text = "{Buy the answer from the dicers. (a little coin)}",
						function getResult()
						{
							local rows = [ ::Legends.EventList.changeMoney(-this.Math.rand(40, 80)) ];
							return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/event_74.png[/img]{A few coins change hands and the bad-tooth man tips his head at a stretch of soot-black wall as though it were obvious - and once you know, it is: a false brick, a hidden latch, a stair going down into warm lamplight and noise. The Urgent Messenger.}");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CourtyardBribe",
			Title = "The Dead Courtyard",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Fine - coin for the dicers.}",
					function getResult()
					{
						local rows = [ ::Legends.EventList.changeMoney(-this.Math.rand(40, 80)) ];
						return this.Contract.resolveRoom(rows, "[img]gfx/ui/events/event_74.png[/img]{The bad-tooth man takes the coin, tips his head at the wall, and there it is - false brick, hidden latch, a stair down into warm lamplight. The Urgent Messenger.}");
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{The wall keeps its secret. Coin it is.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		this.m.Screens.push({
			ID = "DoorRoom",
			Title = "The Threshold",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = "[img]gfx/ui/events/event_24.png[/img]{At the foot of the stair the noise resolves into a full house - thieves, fences, Calistrian girls working the room, and somewhere in it your pair, %SKVNAME%Atharius%SKVNAME_OFF% and %SKVNAME%Jhaari%SKVNAME_OFF%, holding court. Walk in as a noble's hired blades and the whole room knows whose errand you run, and Carthica's name is in every gutter by morning. Walk in as one of their own, and no one need ever know a lord was behind it.}";
				this.Options = [];
				if (this.Contract.m.HasCloak)
				{
					this.Options.push({
						Text = "{In cloaked - as Sczarni, on Sczarni business. (use Urie's cloak)}",
						function getResult()
						{
							this.Contract.m.Discreet = true;
							return this.Contract.resolveRoom([], "[img]gfx/ui/events/event_24.png[/img]{The wasp-stitched half-cloak does the work. You go down the stair as men who belong there - come to drink, come to gamble, come to see the two who are spending so free lately. No one looks twice. Whatever happens in this room tonight, it happens to two thieves and some hard strangers, and no lord's name is anywhere in it.}");
						}
					});
				}
				this.Options.push({
					Text = "{In as ourselves. Let them wonder.}",
					function getResult()
					{
						this.Contract.m.Discreet = false;
						this.Contract.m.Points = this.Contract.m.Points - 2;
						return this.Contract.resolveRoom([], "[img]gfx/ui/events/event_24.png[/img]{You go down the stair as what you are - armed, sober, and plainly on someone's errand - and the room reads it in a heartbeat. Talk drops a notch; a dozen faces turn cool and knowing. Whoever sent these blades, they are thinking, has coin and a grievance. It is a harder crowd to win now, and somewhere in it a small truth is already walking toward the wrong ears.}");
					}
				});
			}
		});

		this.m.Screens.push({
			ID = "ArmRoom",
			Title = "Fun and Games: The Arm",
			Text = "[img]gfx/ui/events/event_24.png[/img]{The thieves won't just hand the ring over - %SKVNAME%Atharius%SKVNAME_OFF% grins and makes a show of it. %SPEECH_ON%You want it? Then earn the room. Beat us at our own games and it's yours, fair as anything's fair down here.%SPEECH_OFF% First is the simplest: a plank table, two elbows, and %SKVNAME%Jhaari%SKVNAME_OFF% rolling a thick shoulder, waiting. Strength, and the crowd loves strength.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Put our strongest arm on the table.}",
						function getResult()
						{
							local res = ::Skv.Check.brawn(this.Contract, 50);
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							return this.Contract.resolveContest(res,
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% sets his elbow, and for a long breath nothing moves - then Jhaari's hand goes over slow and final, and the table cracks him down. The room ROARS. First blood to the strangers.}",
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% gives it everything and it is not enough - Jhaari walks his hand down by inches, grinning the whole way, and puts it flat. The room hoots. One to the thieves.}", "arm");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "RailRoom",
			Title = "Fun and Games: The Rail",
			Text = "[img]gfx/ui/events/event_24.png[/img]{A greased roof-beam is hauled down and laid across two barrels over the heads of the crowd. %SKVNAME%Atharius%SKVNAME_OFF%, light as a cat, walks it end to end and back without looking down, then spreads his hands: your turn. Agility, and a long drop into a laughing crowd if you miss.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Send our surest feet up.}",
						function getResult()
						{
							local res = ::Skv.Check.agility(this.Contract, 50);
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							return this.Contract.resolveContest(res,
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% goes up onto the greased beam and crosses it like it owes him money - turns at the end, walks it back, steps off to whistles and stamping. Atharius's grin tightens a notch. Even.}",
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% gets halfway before the grease finds him and he comes down in a heap of arms and spilled ale, to a great delighted roar. Atharius bows to it. The thieves lead.}", "rail");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "DaggerRoom",
			Title = "Fun and Games: The Toss",
			Text = "[img]gfx/ui/events/event_24.png[/img]{A wine-cork is jammed on a nail across the room and %SKVNAME%Jhaari%SKVNAME_OFF% buries a thrown dagger a finger's width from it, then offers the hilt of a second, eyebrows up. Not brute strength this time and not footwork - a steady hand and a true eye. The room goes quiet to watch.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Steadiest hand and keenest eye.}",
						function getResult()
						{
							local res = ::Skv.Check.handEye(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							return this.Contract.resolveContest(res,
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% weighs the blade once and lets it go, and it takes the cork clean off the nail and pins it to the wall behind. Dead silence - then the room comes apart with noise. Jhaari retrieves the dagger himself, which is its own kind of respect.}",
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% throws, and the blade thuds in a good hand's width wide, quivering. Close - but close loses, and the room lets him know it. Jhaari plucks it free with a wink.}", "dagger");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "HangRoom",
			Title = "Fun and Games: The Hang",
			Text = "[img]gfx/ui/events/event_24.png[/img]{This one has no skill in it, %SKVNAME%Atharius%SKVNAME_OFF% says, only guts: a rope over a beam, ankles bound, and you hang head-down over a pit floored with old cellar-spikes - blunted, probably - and see who calls to be let up first. It is a test of nerve, and the crowd smells fear like dogs.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Who here doesn't flinch? Up he goes.}",
						function getResult()
						{
							local res = ::Skv.Check.nerve(this.Contract, 50);
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							return this.Contract.resolveContest(res,
								"[img]gfx/ui/events/event_24.png[/img]{They string %SKVNAME%" + who + "%SKVNAME_OFF% up head-down over the spikes and he simply... hangs there, bored, and after a while asks whether anyone's going to bring him a drink at this angle. The room howls with it. Atharius signals to cut him down, beaten. Even the thief is laughing.}",
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% lasts a brave while head-down over the spikes - and then the blood and the dark points below get the better of him and he calls to be let up, and the room jeers good and loud. The thieves whoop. They are ahead.}", "hang");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "CardsRoom",
			Title = "Fun and Games: The Cards",
			Text = "[img]gfx/ui/events/event_24.png[/img]{The last game is theirs by right and they know it: greasy cards, a scarred table, and both thieves sitting down across from whoever the company puts up. This is cheating dressed as cards - reading the table, reading the men, keeping a straighter face than they do. Wits and nerve and a little larceny of your own. Win this and the room is yours.}",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Options = [
					{
						Text = "{Sit our sharpest down across from them.}",
						function getResult()
						{
							local res = ::Skv.Check.guile(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local who = (res.actor != null) ? res.actor.getName() : this.Contract.m.ActorName;
							return this.Contract.resolveContest(res,
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% plays them slow, loses a little to make them bold, then takes the whole pot on a hand he had no business holding - and the way he holds the thieves' eyes while he rakes it in says he knows exactly how they were cheating and did it better. The room ADORES him. Atharius sits back, robbed and half-admiring.}",
								"[img]gfx/ui/events/event_24.png[/img]{%SKVNAME%" + who + "%SKVNAME_OFF% plays a good game against two men who have played this exact good game a thousand times, and they take him apart with smiles. The room enjoys it enormously. The thieves gather the pot and their winning streak both.}", "cards");
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "ContestFlourish",
			Title = "Working the Room",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{The game is called.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
				local f = this.Contract.flourishFor();
				this.Options = [
					{
						Text = f.opt,
						function getResult()
						{
							local res = ::Skv.Check.charm(this.Contract, ::Skv.Check.scaledBase(this.Contract, 50));
							local fr = this.Contract.flourishFor();
							if (res.ok) { this.Contract.m.Points = this.Contract.m.Points + 1; this.Contract.m.RoomText = fr.win; }
							else        { this.Contract.m.Points = this.Contract.m.Points - 1; this.Contract.m.RoomText = fr.lose; }
							this.Contract.m.RoomRows = [];
							return "FlourishResult";
						}
					},
					{
						Text = "{Leave it. On to the next.}",
						function getResult() { return this.Contract.nextScreen(); }
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "FlourishResult",
			Title = "Working the Room",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On.}",
					function getResult() { return this.Contract.nextScreen(); }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{On to the next.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		this.m.Screens.push({
			ID = "RoomResult",
			Title = "The Backstreets",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{On.}",
					function getResult() { return this.Contract.nextScreen(); }
				}
			],
			function start()
			{
				this.Text = this.Contract.m.RoomText != "" ? this.Contract.m.RoomText : "{You press on.}";
				this.List = this.Contract.m.RoomRows != null ? this.Contract.m.RoomRows : [];
			}
		});

		this.m.Screens.push({
			ID = "Finale",
			Title = "The Reckoning",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local p = this.Contract.m.Points;
				local w = this.Contract.m.Wins;
				local t;
				if (p >= 7)
				{
					this.Contract.m.GotRing = true;
					this.Contract.m.Humiliated = true;
					t = "[img]gfx/ui/events/event_24.png[/img]{It is not close, in the end. The room is YOURS - stamping the table, buying the strangers drinks, chanting down the two thieves who swaggered in as kings and now cannot meet an eye. %SKVNAME%Atharius%SKVNAME_OFF% works the signet off his own finger and sets it on the table with a sick little smile, because to refuse in front of this crowd would be worse than losing it. %SPEECH_ON%Take it. Take it and get gone.%SPEECH_OFF% You take it. You are bought drinks all the way to the door, and the pair of them will not live tonight down for a year.}";
				}
				else if (w >= 3)
				{
					this.Contract.m.GotRing = true;
					this.Contract.m.Humiliated = false;
					t = "[img]gfx/ui/events/event_24.png[/img]{You take three of the five, and a wager is a wager even here - %SKVNAME%Jhaari%SKVNAME_OFF% slaps the ring down on the table hard enough to sting, sour about it, and jerks his head at the stair. %SPEECH_ON%You won it. Now clear off before the room decides it likes you less than it likes us.%SPEECH_OFF% You go, ring in hand, to no one's cheers - but you go with it, and that is the job.}";
				}
				else
				{
					this.Contract.m.GotRing = false;
					this.Contract.m.Humiliated = false;
					t = "[img]gfx/ui/events/event_24.png[/img]{It goes wrong. The room was theirs from the first game and you never took it back - %SKVNAME%Atharius%SKVNAME_OFF% and %SKVNAME%Jhaari%SKVNAME_OFF% play you for the crowd's delight and send you up the stair to laughter and thrown crusts, the ring still on the thief's hand and turning slow so everyone can see it. You came down here to make two thieves small in front of a room, and the room watched them make small of YOU. That will be told and retold, and it will cost.}";
				}
				this.Text = t;
				this.List = [];
				this.Options = [
					{
						Text = this.Contract.m.GotRing ? "{Back to Carthica with his ring.}" : "{Carthica will not like this.}",
						function getResult()
						{
							this.Contract.m.Done = true;
							return "Report";
						}
					}
				];
			}
		});

		this.m.Screens.push({
			ID = "Report",
			Title = "Carthica's Due",
			Text = "",
			Image = "",
			List = [],
			Options = [],
			function start()
			{
				local rows = [];
				local text;
				local goals = 0;
				if (this.Contract.m.GotRing)    goals += 1;
				if (this.Contract.m.Humiliated) goals += 1;
				if (this.Contract.m.Discreet)   goals += 1;

				if (this.Contract.m.GotRing)
				{
					rows.push(::Legends.EventList.changeMoney(this.Contract.m.Payment.getOnCompletion()));
					rows.push(::Legends.EventList.changeRenown(this.Contract.m.Humiliated ? 30 : 10));
					local nf = this.Contract.homeFaction();
					if (nf != null) nf.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Recovered a noble's signet, discreetly");

					if (goals > 0 && ("XP" in ::Skv))
					{
						local pool = this.World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
						local xprows = ::Skv.XP.grant(pool, goals * 150);
						foreach (r in xprows) rows.push(r);
					}

					if (this.Contract.m.Humiliated && this.Contract.m.Discreet)
						text = "[img]gfx/ui/events/event_183.png[/img]{%SKVNAME%Carthica%SKVNAME_OFF% receives you in a side room, not the hall - discretion runs both ways. He turns the recovered signet over once, twice, and something boyish and relieved crosses the practised sneer before he masters it. %SPEECH_ON%Back on my hand where it belongs - and by what I hear the pair of them cannot show their faces at their own tables, and my name never came into any of it. That is precisely the work I paid for.%SPEECH_OFF% He counts out the balance, and a little over.}";
					else if (this.Contract.m.Discreet)
						text = "[img]gfx/ui/events/event_183.png[/img]{%SKVNAME%Carthica%SKVNAME_OFF% takes the ring back with both hands and a long breath. %SPEECH_ON%Quietly done, at least - no one need know it was ever gone. Whether the thieves learned their lesson I neither know nor much care, so long as no one learned mine.%SPEECH_OFF% He counts out the balance.}";
					else if (this.Contract.m.Humiliated)
						text = "[img]gfx/ui/events/event_183.png[/img]{%SKVNAME%Carthica%SKVNAME_OFF% has the ring back and word of the thieves' disgrace both - and a crease of worry under the satisfaction. %SPEECH_ON%The ring, and the pair of them ruined for it. Good. Though I gather half the low quarter now knows a lord was behind it, which is... not nothing.%SPEECH_OFF% He counts out the balance all the same.}";
					else
						text = "[img]gfx/ui/events/event_183.png[/img]{%SKVNAME%Carthica%SKVNAME_OFF% has the ring back, and takes it with less grace than you expected. %SPEECH_ON%Back on my hand - though I hear you took it in front of half the quarter, and my name with it. I wanted this SMALL. Still. It is returned.%SPEECH_OFF% He counts out the balance, a shade grudgingly.}";

					this.Contract.m.OutcomeRows = rows;
					this.Contract.m.OutcomeText = text;
					this.Contract.m.Decided = true;
					this.Text = text;
					this.List = rows;
					this.Options = [];
					if (this.Contract.m.HasLetter)
					{
						this.Options.push({
							Text = "{One more thing, my lord - read this. (warn him of the Sczarni)}",
							function getResult()
							{
								local extra = [];
								extra.push(::Legends.EventList.changeMoney(this.Math.rand(150, 300)));
								extra.push(::Legends.EventList.changeRenown(10));
								this.Contract.m.OutcomeRows = extra;
								this.Contract.m.OutcomeText = "[img]gfx/ui/events/event_63.png[/img]{You lay Pictor's letter on the table. Carthica reads it, and the colour goes out of his face - the ring was never the point; his own family's ships made him a ransom prize, and a Sczarni family meant to take him. %SPEECH_ON%They were going to... and you knew, and you told me.%SPEECH_OFF% For once the pomp is entirely gone. %SPEECH_ON%My house does not forget this. Neither will I.%SPEECH_OFF% He presses more coin on you than the letter is worth, because it is worth more than coin.}";
								return "Outcome";
							}
						});
					}
					this.Options.push({
						Text = "{A pleasure doing quiet business.}",
						function getResult()
						{
							this.World.Contracts.finishActiveContract();
							return 0;
						}
					});
				}
				else
				{

					rows.push(::Legends.EventList.changeRenown(-60));
					local nf = this.Contract.homeFaction();
					if (nf != null) nf.addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Went to humble two thieves and were humbled instead");
					text = "[img]gfx/ui/events/event_183.png[/img]{%SKVNAME%Carthica%SKVNAME_OFF% does not receive you in a side room. He receives you in front of people, which is its own message, and he already knows - word of a company that went to shame two cutpurses and got shamed instead travels fast, and it travels funny. %SPEECH_ON%You had ONE thing to do quietly and you turned it into a story they are telling in every tavern in the quarter. With MY name in it. Get out of my sight. You will not see the rest of that coin, and you are fortunate that is all this costs you.%SPEECH_OFF% It is not all it costs you. A thing like this follows a company.}";
					this.Contract.m.OutcomeRows = rows;
					this.Contract.m.OutcomeText = text;
					this.Contract.m.Decided = true;
					this.Text = text;
					this.List = rows;
					this.Options = [
						{
							Text = "{Nothing to say to that.}",
							function getResult()
							{
								this.World.Contracts.finishActiveContract(true);
								return 0;
							}
						}
					];
				}
			}
		});

		this.m.Screens.push({
			ID = "Outcome",
			Title = "Carthica's Due",
			Text = "",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{So it is done.}",
					function getResult()
					{
						this.World.Contracts.finishActiveContract(this.Contract.m.GotRing ? false : true);
						return 0;
					}
				}
			],
			function start()
			{
				this.Text = this.Contract.m.OutcomeText != "" ? this.Contract.m.OutcomeText : "{The matter is closed, one way or another.}";
				this.List = this.Contract.m.OutcomeRows != null ? this.Contract.m.OutcomeRows : [];
			}
		});
	}

	function onClear()
	{
		::Skv.Once.release("Carthica");
		if (this.m.IsActive)
		{
			::Skv.Once.retire("Carthica");
		}
	}

	function onIsValid()
	{
		return true;
	}

	function onPrepareVariables( _vars )
	{
		local nameColor = "#9dbccb";
		_vars.push(["SKVNAME", "[color=" + nameColor + "]"]);
		_vars.push(["SKVNAME_OFF", "[/color]"]);
		local locColor = "#b39dbc";
		_vars.push(["SKVLOC", "[color=" + locColor + "]"]);
		_vars.push(["SKVLOC_OFF", "[/color]"]);
	}

	function onSerialize( _out )
	{
		_out.writeU8(this.m.GotRing ? 1 : 0);
		_out.writeU8(this.m.Humiliated ? 1 : 0);
		_out.writeU8(this.m.Discreet ? 1 : 0);
		_out.writeU8(this.m.HasLetter ? 1 : 0);
		_out.writeU8(this.m.HasCloak ? 1 : 0);
		_out.writeU8(this.m.Betrayed ? 1 : 0);
		_out.writeU8(this.m.Done ? 1 : 0);
		_out.writeU8(this.m.Decided ? 1 : 0);
		_out.writeU8(this.m.SpottedTail ? 1 : 0);

		_out.writeU8(this.m.Points + 50);
		_out.writeU8(this.m.Wins);
		_out.writeString(this.m.LastContest);

		if (this.m.Deck == null) _out.writeU8(0);
		else
		{
			_out.writeU8(this.m.Deck.len());
			foreach (k in this.m.Deck) _out.writeString(k);
		}
		_out.writeU8(this.m.CrawlIndex);

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.m.GotRing    = _in.readU8() == 1;
		this.m.Humiliated = _in.readU8() == 1;
		this.m.Discreet   = _in.readU8() == 1;
		this.m.HasLetter  = _in.readU8() == 1;
		this.m.HasCloak   = _in.readU8() == 1;
		this.m.Betrayed   = _in.readU8() == 1;
		this.m.Done        = _in.readU8() == 1;
		this.m.Decided     = _in.readU8() == 1;
		this.m.SpottedTail = _in.readU8() == 1;

		this.m.Points = _in.readU8() - 50;
		this.m.Wins   = _in.readU8();
		this.m.LastContest = _in.readString();

		local dn = _in.readU8();
		if (dn > 0)
		{
			this.m.Deck = [];
			for (local i = 0; i < dn; i = i + 1) this.m.Deck.push(_in.readString());
		}
		this.m.CrawlIndex = _in.readU8();

		this.contract.onDeserialize(_in);
	}

});
