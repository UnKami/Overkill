extends Control
## Excess-tier unlock celebration (turn-presentation/tutorial doc Part 3):
## top of the attention hierarchy, dismiss on tap/input with no fixed
## auto-timer, fires every time a new threshold is crossed - never muted for
## repeat players. GameFlow instantiates this directly into its overlay
## layer whenever OKRunState.excess_threshold_crossed fires.

@onready var _message_label: Label = %MessageLabel

var _threshold: int = 0


func set_threshold(threshold: int) -> void:
	_threshold = threshold


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_message_label.text = "EXCESS UNLOCKED\nSingle-hit Overkill of %d+ reached.\nNew Excess-tier cards are now purchasable." % _threshold
	# Top of the attention hierarchy (doc) - this is the single punchiest
	# reveal in the game, bigger than the reward/run-summary punches.
	AmbientMotion.punch_scale(_message_label, 1.15, 0.45)
	AmbientMotion.spawn_embers(self, Color(0.95, 0.65, 0.15, 0.7), 16, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		queue_free()
