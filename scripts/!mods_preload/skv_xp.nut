if (!("Skv" in getroottable())) ::Skv <- {};
::Skv.XP <- {};

::Skv.XP.grant <- function ( _actor, _base, _mult = 1.0 )
{
	local rows = [];
	local total = ::Math.round(_base * _mult);
	if (total <= 0)
		return rows;

	local list = (typeof _actor == "array") ? _actor : [_actor];
	local ids = {};
	local actors = [];
	foreach ( a in list )
		if (a != null && !(a.getID() in ids)) { ids[a.getID()] <- true; actors.push(a); }

	local sharePct = ::Skv.Cfg.DefaultActorShare;
	try { sharePct = ::Skv.Cfg.actorShare(); } catch (e) { sharePct = ::Skv.Cfg.DefaultActorShare; }
	if (sharePct < 0) sharePct = 0;
	if (sharePct > 100) sharePct = 100;

	local actorCut = ::Math.floor(total * sharePct / 100.0);
	local perActor = actors.len() > 0 ? ::Math.floor(actorCut / actors.len()) : 0;

	local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
	local n = pool.len();
	local perHead = n > 0 ? ::Math.floor((total - actorCut) / n) : 0;

	if (n > 0 && perHead < ::Skv.Cfg.MinOnlookerXP)
		perHead = ::Skv.Cfg.MinOnlookerXP;

	local paid = {};
	foreach ( bro in pool )
	{
		local grant = perHead;
		if (bro.getID() in ids) { grant += perActor; paid[bro.getID()] <- true; }
		if (grant <= 0)
			continue;

		rows.push(::Legends.EventList.changeBroExperience(bro, grant));
	}

	foreach ( a in actors )
		if (!(a.getID() in paid) && perActor > 0)
			rows.push(::Legends.EventList.changeBroExperience(a, perActor));

	return rows;
}

::Skv.XP.partyEach <- function ( _each, _mult = 1.0 )
{
	local rows = [];
	local each = ::Math.round(_each * _mult);
	if (each <= 0)
		return rows;

	local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
	foreach ( bro in pool )
		rows.push(::Legends.EventList.changeBroExperience(bro, each));
	return rows;
}

::Skv.XP.previewEach <- function ( _each )
{
	if (_each <= 0)
		return [];
	return [{
		id = 10,
		icon = "ui/icons/xp_received.png",
		text = "Every man gains " + ::MSU.Text.color(::Const.UI.Color.PositiveEventValue, _each) + " Experience"
	}];
}

::Skv.XP.check <- function ( _r, _mult = 1.0 )
{
	if (_r == null || !("ok" in _r) || !_r.ok)
		return [];

	local solo = ::Skv.Cfg.DefaultCheckXPSolo;
	local team = ::Skv.Cfg.DefaultCheckXPTeam;
	try
	{
		solo = ::Skv.Cfg.checkXPSolo();
		team = ::Skv.Cfg.checkXPTeam();
	}
	catch (e)
	{
		::logError("Skv.XP.check: settings unavailable, using defaults: " + e);
	}

	if ("total" in _r)
	{
		if (_r.total <= 0) return [];

		return ::Skv.XP.partyEach(team, _mult);
	}

	if (_r.actor == null) return [];
	return ::Skv.XP.grant(_r.actor, solo, _mult);
}

::Skv.XP.party <- function ( _base, _mult = 1.0 )
{
	local rows = [];
	local total = ::Math.round(_base * _mult);
	if (total <= 0)
		return rows;

	local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
	if (pool.len() == 0)
		return rows;

	local perHead = ::Math.floor(total / pool.len());
	if (perHead <= 0)
		return rows;

	foreach ( bro in pool )
		rows.push(::Legends.EventList.changeBroExperience(bro, perHead));

	return rows;
}
