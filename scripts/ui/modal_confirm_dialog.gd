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
static func show_dialog(parent: Node, message: String, confirm_label: String, on_confirm: Callable, danger: bool = false) -> ModalConfirmDialog:
	var scene: PackedScene = load(SCENE_PATH)
	var instance: ModalConfirmDialog = scene.instantiate()
	instance._danger = danger
	parent.add_child(instance)
	instance.set_message(message)
	instance.set_confirm_label(confirm_label)
	instance.confirmed.connect(on_confirm)
	instance.confirmed.connect(instance.queue_free)
	instance.cancelled.connect(instance.queue_free)
	return instance


func _ready() -> void:
	ScreenDesign.polish(self)
	ScreenDesign.remove_actionable_fx(_cancel_button)
	ScreenDesign.remove_actionable_fx(_confirm_button)
	var panel: PanelContainer = get_node("CenterContainer/Panel")
	panel.custom_minimum_size.x = minf(560.0, get_viewport_rect().size.x - 48.0)
	var panel_style := StyleBoxFlat.new()
	# Keep underlying controls from ghosting through the panel and clashing
	# with the confirmation's own layout.
	panel_style.bg_color = Color("07111bf7")
	panel_style.border_color = Color("b66d64aa") if _danger else Color("c9aa768c")
	panel_style.set_border_width_all(2 if _danger else 1)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000dc")
	panel_style.shadow_size = 30
	panel_style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", panel_style)
	var stack: VBoxContainer = _message_label.get_parent()
	var kicker := ScreenDesign.label(stack, "IRREVERSIBLE COMMAND" if _danger else "CONFIRM COMMAND", 14, Color("df8076") if _danger else ScreenDesign.CYAN)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.move_child(kicker, 0)
	var title := ScreenDesign.label(stack, "Break the current course?" if _danger else "Commit this choice?", 30, ScreenDesign.GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.move_child(title, 1)
	var rule := ScreenDesign.rule(stack, Color("df8076") if _danger else ScreenDesign.GOLD)
	stack.move_child(rule, 2)
	_message_label.add_theme_font_size_override("normal_font_size", 20)
	_message_label.custom_minimum_size.y = 86
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cancel_button.text = "CANCEL"
	_cancel_button.custom_minimum_size = Vector2(220, 56)
	_confirm_button.custom_minimum_size = Vector2(220, 56)
	_cancel_button.pressed.connect(_on_cancel)
	_confirm_button.pressed.connect(_on_confirm)
	_background_button.pressed.connect(_on_cancel)
	if _danger:
		_confirm_button.theme_type_variation = &"DangerButton"


func set_message(text: String) -> void:
	_message_label.text = text


func set_confirm_label(text: String) -> void:
	_confirm_button.text = text


func align_to_horizontal_region(left_ratio: float, right_ratio: float) -> void:
	# Main-menu confirmation belongs to the same left-hand content column as
	# its journey actions, rather than floating over the character artwork.
	var center: CenterContainer = get_node("CenterContainer")
	center.anchor_left = clampf(left_ratio, 0.0, 1.0)
	center.anchor_right = clampf(right_ratio, center.anchor_left, 1.0)


func _on_cancel() -> void:
	cancelled.emit()


func _on_confirm() -> void:
	confirmed.emit()
