extends Node
## TutorialCallout - the only place a first-time tutorial callout is allowed to
## originate from. No combat/UI code should hand-roll its own one-off tutorial
## text. overkill-tutorial-callout-system.md, Parts 1-2.
##
## This autoload is UI-agnostic on purpose: it owns the catalog and the
## one-time-ever state, and emits a signal for a display layer (built with the
## combat HUD) to render. That display layer must not add any permanent
## element - it renders the callout, then fully disappears per its dismissal
## rule. See Part 1, guardrail 3 & 4.

signal callout_requested(callout_id: String, definition: Dictionary)

var _state: TutorialState

## Catalog matches overkill-tutorial-callout-system.md Part 2 exactly.
## dismiss_seconds: auto-fade timer. dismiss_on: additional dismiss triggers,
## interpreted by the display layer ("input", "chain_resolve", etc).
const CATALOG := {
	"first_ok": {
		"text": "Excess damage becomes Overkill (OK) — spend it between fights.",
		"accent_color": "#EF9F27",
		"icon_id": "overkill_icon",
		"dismiss_seconds": 4.0,
		"dismiss_on": "input",
	},
	"first_intent": {
		"text": "Enemy intent is locked. Red = incoming damage next turn.",
		"accent_color": "#E24B4A",
		"icon_id": "attack_intent_icon",
		"dismiss_seconds": 5.0,
		"dismiss_on": "input",
	},
	"first_rest_upgrade": {
		"text": "Upgrades cost OK earned from combat kills.",
		"accent_color": "#EF9F27",
		"icon_id": "anvil_icon",
		"dismiss_seconds": -1.0,  # no auto-fade, dismiss_on governs
		"dismiss_on": "selection_or_completion",
	},
	"first_excess_gate": {
		"text": "Excess cards unlock permanently for this run when you land a single hit meeting their target.",
		"accent_color": "#EF9F27",
		"icon_id": "lock_icon",
		"dismiss_seconds": -1.0,
		"dismiss_on": "scroll_or_click_away",
	},
}


func _ready() -> void:
	_state = TutorialState.load_or_create()


## Call this at the exact moment a callout's trigger condition is met.
## No-ops silently if already seen - safe to call unconditionally at the
## trigger site rather than checking should_show separately everywhere.
func trigger(callout_id: String) -> void:
	if not CATALOG.has(callout_id):
		push_error("TutorialCallout: unknown callout_id '%s'" % callout_id)
		return
	if not _state.should_show(callout_id):
		return
	_state.mark_seen(callout_id)
	callout_requested.emit(callout_id, CATALOG[callout_id])
