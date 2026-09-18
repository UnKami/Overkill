class_name ModalConfirmDialog extends Control
## Full modal warning tier of the confirmation convention (pause/settings doc
## Part 1.2): full-screen dim, explicit consequence text, Cancel styled
## neutral/default, Confirm styled danger-red. Tapping outside the panel or
## the Cancel button always cancels, never confirms. Built once, used by
## every irreversible/high-consequence action in the game (abandon run,
## return to main menu mid-run) - nothing should hand-roll its own version.

const SCENE_PATH := "res://scenes/modal_confirm_dialog.tscn"

signal confirmed()
signal cancelled()

@onready var _message_label: RichTextLabel = %MessageLabel
@onready var _cancel_button: Button = %CancelButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _background_button: Button = %BackgroundButton

var _danger: bool = false


## Spawns and shows a modal confirm as a child of `parent`. Fire-and-forget:
## caller doesn't need to keep a reference, connect to on_confirm directly.
## `danger` styles Confirm red for genuinely irreversible/high-consequence
## actions (abandon run) - most uses of this dialog (upgrade/removal spends,
## informational continues) are NOT that, so it defaults to false rather
## than red-flagging everything that merely asks for confirmation.
static func show_dialog(parent: Node, message: String, confirm_label: String, on_confirm: Callable, danger: bool = false) -> void:
	var scene: PackedScene = load(SCENE_PATH)
	var instance: ModalConfirmDialog = scene.instantiate()
	instance._danger = danger
	parent.add_child(instance)
	instance.set_message(message)
	instance.set_confirm_label(confirm_label)
	instance.confirmed.connect(on_confirm)
	instance.confirmed.connect(instance.queue_free)
	instance.cancelled.connect(instance.queue_free)


func _ready() -> void:
	_cancel_button.pressed.connect(_on_cancel)
	_confirm_button.pressed.connect(_on_confirm)
	_background_button.pressed.connect(_on_cancel)
	if _danger:
		_confirm_button.theme_type_variation = &"DangerButton"


func set_message(text: String) -> void:
	_message_label.text = text


func set_confirm_label(text: String) -> void:
	_confirm_button.text = text


func _on_cancel() -> void:
	cancelled.emit()


func _on_confirm() -> void:
	confirmed.emit()
