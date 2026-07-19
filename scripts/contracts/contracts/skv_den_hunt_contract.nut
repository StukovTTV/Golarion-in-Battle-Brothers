// ============================================================================
//  THE DEN HUNT -- CONTRACT
//
//  Takes a bounty on a location the contract did not create and cannot rely on.
//  Three consequences, all handled below:
//
//  1. THE TARGET IS PERSISTENT, so it must be serialized. WeakTableRef in,
//     writeU32(getID()) out, WeakTableRef(World.getEntityByID(id)) back --
//     restore_location_contract:7, :672, :697. A WeakTableRef does NOT keep the
//     entity alive; every read must guard isNull().
//
//  2. THE PLAYER CAN KILL IT WITHOUT US. The Den is a real hostile location once
//     warned; nothing stops you attacking it with no contract, or taking the job
//     and finishing a fight you had already started. So completion is NOT
//     "my callback fired" -- it is "the Den is dead, however that happened".
//     update() watching !isAlive() catches every path. This is the watchtower's
//     MSU.isNull(Destination) idiom pointed at someone else's entity.
//
//     setOnCombatWithPlayerCallback (stollwurms:109) is the richer mechanism and
//     is DELIBERATELY NOT USED: it fires when the player enters combat with the
//     location, and an unwarned Den CANNOT be entered into combat. It sits at
//     faction 0, and world_entity.nut:160 counts faction 0 as allied with the
//     player, so world_state.nut:1218's `isAttackable() && !isAlliedWithPlayer()`
//     is false and there is no combat to hook. The Den only becomes attackable
//     when its enter event sets the faction. Hooking a callback that cannot fire
//     on first contact is worse than not hooking one.
//
//  3. WE MUST NOT BREAK THE DEN. Everything this contract does to the location
//     is reversible and undone in onClear: the claim flag and the selection
//     sprite. It never touches faction, IsVisited, or the garrison -- those
//     belong to the Den's own enter event, and the whole design depends on that
//     event running normally while you are under contract.
//
//  THE POINT OF THE THING
//  There is no moral fork written here, because the Den already has one and it
//  fires whether or not you are employed. You take a bounty on vermin, you walk
//  out to collect, and the vermin SPEAKS TO YOU in a language nobody present
//  knows. The contract's job is to get you to that door with money on the line.
//  It should not editorialise before you arrive; the employer does not know what
//  he is asking for, and neither should the offer screen.
// ============================================================================
this.skv_den_hunt_contract <- this.inherit("scripts/contracts/contract", {
	m = {},

	function setDen( _l )
	{
		this.m.Den <- this.WeakTableRef(_l);
	}

	function create()
	{
		this.contract.create();
		this.m.Type = "contract.skv_den_hunt";
		this.m.Name = "The Wolves of the Green";
		this.m.TimeOut = this.World.getTime().SecondsPerDay * 14;

		// Set directly. Legends' category-hook loop already ran during its own
		// load, before this mod's files exist, so it will not stamp ours.
		this.m.Category = this.Const.Contracts.Categories.Legendary;

		this.m.DescriptionTemplates = [
			"A bounty on the wolves that hold an abandoned village."
		];

		this.m.Den <- null;
	}

	function start()
	{
		// Marquee. Hand-set, per the guide's rule: pay is a tier you choose, not
		// a number derived from the fight. This is the biggest fixed roster in the
		// mod (20 direwolves, 7 frenzied, none of which rout on Legendary) and it
		// is a named site, so it sits at the top band.
		//
		// A big ADVANCE is doing real work here, not flavour. The Den can end
		// badly in a way the watchtower cannot: you may arrive, be spoken to, and
		// decide not to do it. The advance is the portion that can never be
		// clawed back, so it is the floor that makes walking away a CHOICE rather
		// than a punishment. Size it to the risk shape of the contract.
		this.m.DifficultyMult = this.Math.rand(150, 175) * 0.01;

		this.m.Payment.Pool = 1500 * (this.Math.rand(70, 110) * 0.01)
			* this.getPaymentMult()
			* this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW)
			* this.getReputationToPaymentMult();

		this.m.Payment.Completion = 0.6;
		this.m.Payment.Advance = 0.4;

		// !! REQUIRED, AND NOT OPTIONAL BOILERPLATE !!
		// contract.nut:269-289 -- the PARENT start() is what runs the state
		// machine:
		//     this.m.IsStarted = true;
		//     if (this.m.Home == null) this.setHome(getCurrentTown());
		//     if (this.m.Origin == null) this.setOrigin(getCurrentTown());
		//     this.onImportIntro();
		//     if (this.hasState("Offer")) this.setState("Offer");   <-- THIS
		//
		// setState("Offer") runs Offer.start(), which is the only thing that ever
		// calls setScreen("Task"), which is the only thing that ever sets
		// m.ActiveScreen. Override start() without chaining and the contract
		// still creates, still scores, still renders on the noticeboard with its
		// name, description, category and skulls -- and then dies the instant you
		// CLICK it, because getUIContent (contract.nut:639) reads
		// m.ActiveScreen.Text and ActiveScreen was never set:
		//     "the index 'Text' does not exist"
		//     getUIContent -> scripts/contracts/contract.nut : 482
		// and it takes the town screen down with it.
		//
		// All three other contracts in this mod call this. It is the last line of
		// start() in every one of them.
		this.contract.start();
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);

		this.m.Screens.push({
			ID = "Task",
			Title = "At the noticeboard...",
			Text = "[img]gfx/ui/events/event_20.png[/img]{%employer% has the look of a man repeating something he does not believe.%SPEECH_ON%There is a village out in the green that is not a village any more. Wolves have it. Big ones, and more of them than wolves ought to be. Folk walked out years back and left everything standing, and nobody has walked back in.%SPEECH_OFF%He turns the paper round so you can see the mark on it.%SPEECH_ON%It is good ground and it is doing nobody any good with wolves on it. Clear them out. I will pay for the whole pack and I will not ask how many there were.%SPEECH_OFF%}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{We will clear them out.}",
					function getResult()
					{
						return "Negotiation";
					}
				},
				{
					Text = "{Find someone else.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}
				}
			],
			function start()
			{
			}
		});

		this.m.Screens.push({
			ID = "Cleared",
			Title = "The green is quiet",
			Text = "[img]gfx/ui/events/event_115.png[/img]{The last of them does not run, which is the part the men will leave out.\n\nYou take the count back to %employer%, who does not want it, and pays without looking at the tally. It is good ground. It will be worked again in a year and nobody working it will know what it was called before, or what was living in the granary, or that it had anything to say.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "{Take the pay.}",
					function getResult()
					{
						this.Contract.collectReward();
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "cleared the green");
						this.Contract.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
			}
		});
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.setScreen("Task");
			}

			function update()
			{
			}

			function end()
			{
				// ACCEPT. This is the reveal, and it is the whole reason a bounty
				// on a fixture is playable at all: the employer TELLS you where it
				// is. Four calls, verbatim in shape from stollwurms:497-501 --
				// lift the fog, claim it, discover it, fly the camera to it.
				//
				// The claim flag is the shipped lock that stops two contracts
				// owning one site (stollwurms filters candidates on it at :485).
				// The action reads it; onClear releases it.
				if (this.Contract.m.Den != null && !this.Contract.m.Den.isNull())
				{
					local den = this.Contract.m.Den;
					this.World.uncoverFogOfWar(den.getTile().Pos, 700.0);
					den.getFlags().set("IsEventLocation", true);
					den.setDiscovered(true);
					this.World.getCamera().moveTo(den);
				}

				this.World.Contracts.setActiveContract(this.Contract);
			}
		});

		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Destroy the wolves that hold the green"
				];

				if (this.Contract.m.Den != null && !this.Contract.m.Den.isNull())
				{
					this.Contract.m.Den.getSprite("selection").Visible = true;
				}
			}

			function update()
			{
				// The ONLY completion check, and deliberately the dumbest one that
				// works. It does not care how the Den died: your scripted assault,
				// a fight you started before taking the job, or anything else that
				// kills a location. isNull() first -- a WeakTableRef does not hold
				// the entity alive, so the reference can go hollow before we look.
				if (this.Contract.m.Den == null || this.Contract.m.Den.isNull() || !this.Contract.m.Den.isAlive())
				{
					this.Contract.setScreen("Cleared");
					this.World.Contracts.showActiveContract();
					return;
				}
			}

			function onCombatFinished()
			{
				this.contract_state.onCombatFinished();
			}
		});
	}

	// Cribbed from restore_location:651 -- the model for a contract whose target
	// is a world entity it does not own. If the Den is gone before you accept
	// (or between load and tick), the contract invalidates itself instead of
	// sitting on the board pointing at nothing.
	function onIsValid()
	{
		if (this.m.Den == null || this.m.Den.isNull() || !this.m.Den.isAlive())
		{
			return false;
		}

		return true;
	}

	// REQUIRED on every contract -- Legends' contract_decendants hook reads
	// o.onClear on each descendant, and a missing one makes the class fail to
	// register, which surfaces as a cascade of "the index '...' does not exist".
	//
	// It is also doing real work here: everything we did TO someone else's
	// location gets undone. Miss this and a cancelled contract leaves the Den
	// permanently claimed -- no future contract could ever target it, silently.
	function onClear()
	{
		if (this.m.Den != null && !this.m.Den.isNull())
		{
			this.m.Den.getSprite("selection").Visible = false;
			this.m.Den.getFlags().set("IsEventLocation", false);
		}

		this.m.Den = null;
	}

	function onSerialize( _out )
	{
		if (this.m.Den != null && !this.m.Den.isNull())
		{
			_out.writeU32(this.m.Den.getID());
		}
		else
		{
			_out.writeU32(0);
		}

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local den = _in.readU32();

		if (den != 0)
		{
			this.m.Den = this.WeakTableRef(this.World.getEntityByID(den));
		}

		this.contract.onDeserialize(_in);
	}

});
