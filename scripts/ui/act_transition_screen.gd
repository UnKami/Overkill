extends Control
## Act transition beat (user journey doc: "Act transition (brief beat)") -
## full-screen key art marking descent to the next act, dismissed on
## tap/input with no fixed auto-timer (same dismissal convention as the
## Excess-unlock celebration) rather than forcing a wait. Whatever should
## happen next (advance the act, start the final boss) is supplied by the
## caller as a Callable, so this screen stays a pure "show a moment, then
## continue" component instead of knowing about run structure itself.

@onready var _background: TextureRect = %Background
@onready var _label: Label = %ActLabel

var _background_path: String = ""
var _label_text: String = ""
var _on_complete: Callable = Callable()
var _dismissed: bool = false


func configure(background_path: String, label_text: String, on_complete: Callable) -> void:
	_background_path = background_path
	_label_text = label_text
	_on_complete = on_complete


func _ready() -> void:
	if ResourceLoader.exists(_background_path):
		_background.texture = ResourceLoader.load(_background_path)
	_label.text = _label_text
	AmbientMotion.apply_ken_burns(_background, 8.0, 0.03)
	AmbientMotion.punch_scale(_label, 1.1, 0.5)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_dismiss()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		_dismiss()


func _dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	if _on_complete.is_valid():
		_on_complete.call()
