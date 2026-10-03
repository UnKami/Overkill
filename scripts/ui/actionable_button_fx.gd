class_name ActionableButtonFX extends Control
## Quiet electric contour: idle glint on primary actions, clear edge on focus.
var button: Button
var accent: Color = Color("c9aa76")
var time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 8

func _process(delta: float) -> void:
	if not is_instance_valid(button): return
	if not AudioManager.reduced_motion: time += delta
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(button) or button.disabled: return
	var emphasized: bool = button.has_focus() or button.is_hovered() or button.button_pressed
	var primary: bool = bool(button.get_meta("action_fx_primary", false))
	# Godot already draws the button's hover/focus/pressed style. Drawing our
	# contour at the same time creates a second misaligned outline around modal
	# actions. Keep the restrained idle glint for primary actions only.
	if emphasized or not primary: return
	var alpha: float = 0.24 if AudioManager.reduced_motion else 0.16 + 0.08 * sin(time * 2.1)
	var rect: Rect2 = Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var c: Color = Color(accent, alpha)
	var pts := PackedVector2Array()
	var inset: float = 2.0
	for p: Vector2 in [Vector2(inset, 8), Vector2(8, 4), Vector2(rect.size.x * .28, 5), Vector2(rect.size.x * .32, 2), Vector2(rect.size.x * .68, 2), Vector2(rect.size.x * .71, 5), Vector2(rect.size.x - 8, 4), Vector2(rect.size.x - 3, 9), Vector2(rect.size.x - 2, rect.size.y - 9), Vector2(rect.size.x - 9, rect.size.y - 3), Vector2(9, rect.size.y - 3), Vector2(2, rect.size.y - 9), Vector2(inset, 8)]:
		pts.append(p + Vector2(1, 1))
	draw_polyline(pts, Color(c, alpha * 0.15), 5.0, true)
	draw_polyline(pts, c, 1.0, true)
