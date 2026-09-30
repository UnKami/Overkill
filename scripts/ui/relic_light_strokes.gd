class_name RelicLightStrokes extends Control
## A few fine, refracted light strokes behind isolated relic objects.
var primary: Color = Color("80c8d1")
var secondary: Color = Color("e9a44a")
var dual: bool = false
var phase: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = -1

func set_essences(first: Color, second: Color, is_dual: bool) -> void:
	primary = first
	secondary = second
	dual = is_dual
	queue_redraw()

func _process(delta: float) -> void:
	if AudioManager.reduced_motion: return
	phase += delta * 0.22
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.40
	var drift: float = sin(phase) * 3.0
	for i: int in 7:
		var angle: float = TAU * float(i) / 7.0 - PI * 0.5
		var start: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.68
		var tip: Vector2 = center + Vector2(cos(angle + 0.11), sin(angle + 0.11)) * (radius + drift)
		var kink: Vector2 = start.lerp(tip, 0.58) + Vector2(cos(angle + 1.2), sin(angle + 1.2)) * 4.0
		var color: Color = secondary if dual and i % 2 == 1 else primary
		draw_line(start, kink, Color(color, 0.50), 1.0, true)
		draw_line(kink, tip, Color(color, 0.82), 1.3, true)
