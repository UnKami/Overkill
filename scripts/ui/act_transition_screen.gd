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
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_override("font", ScreenDesign.display_font())
	_label.add_theme_font_size_override("font_size", 52)
	_label.add_theme_color_override("font_color", Color("f2dfbd"))
	_label.add_theme_color_override("font_outline_color", Color("071019d9"))
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_shadow_color", Color("000000b8"))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_constant_override("shadow_outline_size", 3)
	var viewport_size: Vector2 = get_viewport_rect().size
	var left_edge: float = viewport_size.x * 0.075
	_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label.position = Vector2(left_edge, viewport_size.y * 0.50)
	_label.size = Vector2(viewport_size.x * 0.32, 150.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var kicker := ScreenDesign.label(self, "THE MECHANISM DESCENDS", 16, ScreenDesign.CYAN)
	kicker.add_theme_color_override("font_outline_color", Color("071019d9"))
	kicker.add_theme_constant_override("outline_size", 3)
	kicker.position = Vector2(left_edge + 4.0, viewport_size.y * 0.50 - 52.0)
	kicker.size = Vector2(viewport_size.x * 0.36, 28.0)
	kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rule := ColorRect.new()
	rule.color = Color(ScreenDesign.GOLD, 0.72)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.position = Vector2(left_edge + 4.0, viewport_size.y * 0.50 + 164.0)
	rule.size = Vector2(viewport_size.x * 0.30, 1.0)
	add_child(rule)
	var hint: Label = get_node("HintLabel")
	hint.text = "CLICK OR PRESS ENTER TO CONTINUE"
	hint.add_theme_font_size_override("font_size", 15)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(left_edge + 4.0, viewport_size.y - 74.0)
	hint.size = Vector2(viewport_size.x * 0.4, 30.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	AmbientMotion.apply_cinematic_backdrop(self, _background, 18.0, 0.72)
	AmbientMotion.punch_scale(_label, 1.035, 0.5)


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
