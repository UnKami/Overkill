extends Node
## OKRunState - Autoload singleton, not a per-scene Resource.
## The single source of truth for Overkill currency this run. No other script
## should cache its own copy of these values - read from here, always.
## Data schema doc, Part 1.5.

var current_ok: int = 0
var best_single_hit_ok_this_run: int = 0        ## drives SINGLE_HIT_OK excess-tier unlock checks
var best_turn_total_ok_this_run: int = 0        ## drives TURN_TOTAL_OK excess-tier unlock checks
var last_kill_ok: int = 0                       ## OK from the most recent kill - 0 if it wasn't a
                                                 ## kill, or it Spillaged instead of banking
var unlocked_excess_thresholds: Array[int] = [] ## thresholds already crossed - don't re-announce
var ok_spent_log: Array[Dictionary] = []        ## for a run-summary screen later

var _turn_ok_accumulator: int = 0               ## resets every player turn - see start_new_turn()

signal ok_gained(amount: int, source: String)
signal excess_threshold_crossed(threshold: int)

## Excess-tier unlock thresholds by act, balance doc Section 4.
const EXCESS_THRESHOLDS_BY_ACT := {
	1: 20,
	2: 35,
	3: 60,
	4: 90,  # final boss / Act 4 equivalent
}


func gain_ok(amount: int, source: String, single_hit_ok: int = 0) -> void:
	if amount <= 0:
		return
	current_ok += amount
	ok_gained.emit(amount, source)

	if single_hit_ok > best_single_hit_ok_this_run:
		best_single_hit_ok_this_run = single_hit_ok
		_check_excess_thresholds()


## The one call site for "a kill happened" (combat_controller, at the exact
## point of resolution) - centralizes last_kill_ok / best_single_hit /
## best_turn_total / the actual OK bank in one place, per the data schema
## doc's "every field updates at the exact same call site" rule (Part 1.5).
## overkill_ok is 0 for an exact-lethal hit, and this is also the function to
## call (with 0) when a kill Spillaged instead of banking, so last_kill_ok
## still reflects "the most recent kill" correctly either way.
func record_kill(overkill_ok: int, source: String) -> void:
	last_kill_ok = overkill_ok
	_turn_ok_accumulator += overkill_ok
	if _turn_ok_accumulator > best_turn_total_ok_this_run:
		best_turn_total_ok_this_run = _turn_ok_accumulator
	gain_ok(overkill_ok, source, overkill_ok)


## Called at the start of every player turn - the turn-total accumulator this
## drives is scoped to a single turn (data schema doc 1.5's TURN_TOTAL_OK).
func start_new_turn() -> void:
	_turn_ok_accumulator = 0


func spend_ok(amount: int, reason: String) -> bool:
	if amount > current_ok:
		return false
	current_ok -= amount
	ok_spent_log.append({"amount": amount, "reason": reason})
	return true


## The one place "is this Excess card unlocked" gets decided - shop_screen
## and reward_screen both call this instead of each re-deriving it, per the
## data schema doc's "never let a UI script independently calculate this"
## rule (Part 1.5 closing note). Branches on the card's OWN excess_gate_type
## rather than assuming SINGLE_HIT_OK for everything.
func is_card_unlocked(card: CardData) -> bool:
	if card.rarity != CardData.Rarity.EXCESS or card.excess_gate_threshold <= 0:
		return true
	match card.excess_gate_type:
		CardData.ExcessGateType.TURN_TOTAL_OK:
			return best_turn_total_ok_this_run >= card.excess_gate_threshold
		CardData.ExcessGateType.CARD_SOURCED_OK:
			return false  # not tracked this pass - no shipped card uses this gate type yet
		_:  # SINGLE_HIT_OK
			return best_single_hit_ok_this_run >= card.excess_gate_threshold


func _check_excess_thresholds() -> void:
	for act in EXCESS_THRESHOLDS_BY_ACT:
		var threshold: int = EXCESS_THRESHOLDS_BY_ACT[act]
		if best_single_hit_ok_this_run >= threshold and threshold not in unlocked_excess_thresholds:
			unlocked_excess_thresholds.append(threshold)
			excess_threshold_crossed.emit(threshold)


func reset_for_new_run() -> void:
	current_ok = 0
	best_single_hit_ok_this_run = 0
	best_turn_total_ok_this_run = 0
	last_kill_ok = 0
	_turn_ok_accumulator = 0
	unlocked_excess_thresholds.clear()
	ok_spent_log.clear()


## SaveManager reads through these rather than touching fields directly -
## keeps this autoload the single owner even when its state gets persisted.
func to_save_dict() -> Dictionary:
	return {
		"current_ok": current_ok,
		"best_single_hit_ok_this_run": best_single_hit_ok_this_run,
		"best_turn_total_ok_this_run": best_turn_total_ok_this_run,
		"unlocked_excess_thresholds": unlocked_excess_thresholds.duplicate(),
		"ok_spent_log": ok_spent_log.duplicate(),
	}


func load_from_save(data: Dictionary) -> void:
	current_ok = data.get("current_ok", 0)
	best_single_hit_ok_this_run = data.get("best_single_hit_ok_this_run", 0)
	best_turn_total_ok_this_run = data.get("best_turn_total_ok_this_run", 0)
	unlocked_excess_thresholds.assign(data.get("unlocked_excess_thresholds", []))
	ok_spent_log.clear()
	for entry in data.get("ok_spent_log", []):
		if entry is Dictionary: ok_spent_log.append(entry.duplicate())
