class_name RelicLightStrokes extends Control
## Crisp, colored rays behind isolated relic objects; no fog panels or bloom.
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
	var radius: float = minf(size.x, size.y) * 0.47
	var drift: float = sin(phase) * 2.0
	for i: int in 9:
		var angle: float = TAU * float(i) / 9.0 - PI * 0.5 + sin(phase + float(i)) * 0.025
		var start: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.20
		var tip: Vector2 = center + Vector2(cos(angle + 0.10), sin(angle + 0.10)) * (radius + drift)
		var kink: Vector2 = start.lerp(tip, 0.56) + Vector2(cos(angle + 1.2), sin(angle + 1.2)) * 3.0
		var color: Color = secondary if dual and i % 2 == 1 else primary
		draw_line(start, kink, Color(color, 0.13), 5.0, true)
		draw_line(kink, tip, Color(color, 0.18), 4.0, true)
		draw_line(start, kink, Color(color, 0.72), 1.0, true)
		draw_line(kink, tip, Color(color, 0.96), 1.35, true)
