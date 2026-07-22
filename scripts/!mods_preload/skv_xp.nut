// skv_xp.nut  —  ::Skv.XP : award experience on a successful skill check.
//
// Preload module (adds to the ::Skv table like skv_engine.nut). Register it in the
// preload load list next to the other ::Skv modules.
//
// Rule (locked this session):
//   On a check SUCCESS only, grant a flat authored `base` * optional `mult`.
//     - actorShare% of the total goes to the acting brother (::Skv.Cfg.actorShare, default 50)
//     - the remainder is split evenly across every ACTIVE (non-reserve) brother, actor included
//     - difficulty-scaled PER BROTHER inside addXP (scale = true), exactly like combat XP,
//       so `base` is a pre-scale design number, not a promised in-game number
//   Call from the outcome resolver on ok == true, behind the once-per-beat latch.
//
// Returns an array of EventList row descriptors so the caller can push them onto a
// screen's `List`. ::Legends.EventList.changeBroExperience IS the grant path here
// (it performs addXP + updateLevel and returns the "+N Experience" row) — do NOT also
// call addXP for the same brother, or you double-grant.
//
// Verified against Legends 19.4.10:
//   - player.addXP(_xp, _scale=true) + player.updateLevel()   (mod_legends/hooks/entity/tactical/player.nut)
//   - player.isInReserves()                                   (ibid.)
//   - active-roster filter idiom                              (mod_legends/system/static_functions.nut:269)
//   - ::Legends.EventList.changeBroExperience                 (mod_legends/config/event_list.nut)

if (!("Skv" in getroottable())) ::Skv <- {};
::Skv.XP <- {};

// _actor may be ONE actor OR an ARRAY of actors that SHARE the actor-cut (e.g. a two-part check
// with a spotter and a crosser). The array is deduped by id, so the same brother listed twice
// takes one full share (not a halved one). A single actor behaves exactly as before.
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
