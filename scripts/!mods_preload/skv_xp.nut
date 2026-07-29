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

	local sharePct = 50;
	try { sharePct = ::Skv.Cfg.actorShare(); } catch (e) { sharePct = 50; }
	if (sharePct < 0) sharePct = 0;
	if (sharePct > 100) sharePct = 100;

	local actorCut = ::Math.floor(total * sharePct / 100.0);
	local perActor = actors.len() > 0 ? ::Math.floor(actorCut / actors.len()) : 0;

	local pool = ::World.getPlayerRoster().getAll().filter(@(_, b) !b.isInReserves());
	local n = pool.len();
	local perHead = n > 0 ? ::Math.floor((total - actorCut) / n) : 0;

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
