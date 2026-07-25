// skv_xp.nut  —  ::Skv.XP : award experience on a successful skill check.
// actorShare% to the acting brother (::Skv.Cfg.actorShare); the rest split evenly across active (non-reserve) brothers.
// XP is difficulty-scaled per brother inside addXP (scale = true), so `base` is a pre-scale design number.
// Returns EventList rows. changeBroExperience IS the grant path (addXP + updateLevel) — do NOT also call addXP or you double-grant.

if (!("Skv" in getroottable())) ::Skv <- {};
::Skv.XP <- {};

// _actor may be ONE actor OR an ARRAY that SHARE the actor-cut (deduped by id). Single actor behaves as before.
::Skv.XP.grant <- function ( _actor, _base, _mult = 1.0 )
{
	local rows = [];
	local total = ::Math.round(_base * _mult);
	if (total <= 0)
		return rows;

	// Normalise + dedupe the acting brother(s).
	local list = (typeof _actor == "array") ? _actor : [_actor];
	local ids = {};
	local actors = [];
	foreach ( a in list )
		if (a != null && !(a.getID() in ids)) { ids[a.getID()] <- true; actors.push(a); }

	// actor-share knob (0..100). Defensive read — never throw out of an event tick.
	local sharePct = 50;
	try { sharePct = ::Skv.Cfg.actorShare(); } catch (e) { sharePct = 50; }
	if (sharePct < 0) sharePct = 0;
	if (sharePct > 100) sharePct = 100;

	local actorCut = ::Math.floor(total * sharePct / 100.0);
	local perActor = actors.len() > 0 ? ::Math.floor(actorCut / actors.len()) : 0;   // split evenly

	// active company = all brothers NOT on reserve (proven Legends idiom; 2-arg filter)
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

		// changeBroExperience: addXP(grant, scale=true) + updateLevel + returns the row
		rows.push(::Legends.EventList.changeBroExperience(bro, grant));
	}

	// Any acting brother not in the active pool (e.g. benched) still gets his share.
	foreach ( a in actors )
		if (!(a.getID() in paid) && perActor > 0)
			rows.push(::Legends.EventList.changeBroExperience(a, perActor));

	return rows;
}
