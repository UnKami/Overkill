class_name TutorialState extends Resource
## Persisted record of which one-time tutorial callouts have already been shown.
## overkill-tutorial-callout-system.md, Part 3.1.

const SAVE_PATH := "user://tutorial_state.tres"

@export var seen_callouts: Dictionary = {
	"first_intent": false,
	"first_ok": false,
	"first_rest_upgrade": false,
	"first_excess_gate": false,
}


func should_show(callout_id: String) -> bool:
	return not seen_callouts.get(callout_id, false)


func mark_seen(callout_id: String) -> void:
	seen_callouts[callout_id] = true
	ResourceSaver.save(self, SAVE_PATH)


static func load_or_create() -> TutorialState:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded: Resource = ResourceLoader.load(SAVE_PATH)
		if loaded is TutorialState:
			return loaded
	return TutorialState.new()
