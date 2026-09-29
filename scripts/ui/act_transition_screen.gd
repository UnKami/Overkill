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
	_label.text = _label_text.to_upper()
	_label.add_theme_font_override("font", ScreenDesign.display_font())
	_label.add_theme_font_size_override("font_size", 68 if get_viewport_rect().size.x >= 1500.0 else 54)
	_label.add_theme_color_override("font_color", Color("f2dfbd"))
	_label.add_theme_color_override("font_outline_color", Color("071019d9"))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_shadow_color", Color("000000b8"))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 5)
	_label.add_theme_constant_override("shadow_outline_size", 8)
	var kicker := ScreenDesign.label(self, "THE MECHANISM DESCENDS", 16, ScreenDesign.CYAN)
	kicker.add_theme_color_override("font_outline_color", Color("071019d9"))
	kicker.add_theme_constant_override("outline_size", 3)
	kicker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	kicker.position += Vector2(-150, -76)
	kicker.size = Vector2(300, 30)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rule := ColorRect.new()
	rule.color = Color(ScreenDesign.GOLD, 0.72)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	rule.position += Vector2(-190, 66)
	rule.size = Vector2(380, 1)
	add_child(rule)
	var hint: Label = get_node("HintLabel")
	hint.text = "CLICK OR PRESS ANY KEY TO CONTINUE"
	hint.add_theme_font_size_override("font_size", 15)
	AmbientMotion.apply_cinematic_backdrop(self, _background, 18.0, 0.72)
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
