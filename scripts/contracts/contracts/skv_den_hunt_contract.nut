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

		this.m.Category = this.Const.Contracts.Categories.Legendary;

		this.m.DescriptionTemplates = [
			"A bounty on the wolves that hold an abandoned village."
		];

		this.m.Den <- null;
	}

	function start()
	{

		this.m.DifficultyMult = this.Math.rand(150, 175) * 0.01;

		this.m.Payment.Pool = 1500 * (this.Math.rand(70, 110) * 0.01)
			* this.getPaymentMult()
			* this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW)
			* this.getReputationToPaymentMult();

		this.m.Payment.Completion = 0.6;
		this.m.Payment.Advance = 0.4;

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

						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "cleared the green");
						this.World.Contracts.finishActiveContract();
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

				if (this.Contract.m.Den == null || this.Contract.m.Den.isNull() || !this.Contract.m.Den.isAlive())
				{
					this.Contract.setScreen("Cleared");
					this.World.Contracts.showActiveContract();
					return;
				}
			}

		});
	}

	function onIsValid()
	{
		if (this.m.Den == null || this.m.Den.isNull() || !this.m.Den.isAlive())
		{
			return false;
		}

		return true;
	}

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
