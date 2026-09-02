extends Node
## OKRunState - Autoload singleton, not a per-scene Resource.
## The single source of truth for Overkill currency this run. No other script
## should cache its own copy of these values - read from here, always.
## Data schema doc, Part 1.5.

var current_ok: int = 0
var best_single_hit_ok_this_run: int = 0        ## drives Excess-tier unlock checks
var unlocked_excess_thresholds: Array[int] = [] ## thresholds already crossed - don't re-announce
var ok_spent_log: Array[Dictionary] = []        ## for a run-summary screen later

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


func spend_ok(amount: int, reason: String) -> bool:
	if amount > current_ok:
		return false
	current_ok -= amount
	ok_spent_log.append({"amount": amount, "reason": reason})
	return true


func _check_excess_thresholds() -> void:
	for act in EXCESS_THRESHOLDS_BY_ACT:
		var threshold: int = EXCESS_THRESHOLDS_BY_ACT[act]
		if best_single_hit_ok_this_run >= threshold and threshold not in unlocked_excess_thresholds:
			unlocked_excess_thresholds.append(threshold)
			excess_threshold_crossed.emit(threshold)


func reset_for_new_run() -> void:
	current_ok = 0
	best_single_hit_ok_this_run = 0
	unlocked_excess_thresholds.clear()
	ok_spent_log.clear()
