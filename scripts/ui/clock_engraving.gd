extends Control
## Lightweight live engravings above the physical dial and below its sockets.
var accent := Color("7bd6de")
var active_hour: int = 0
var quadrant: int = 0
var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := size.x * 0.5
	for ring in [0.97, 0.92, 0.61, 0.57]:
		draw_arc(center, radius * ring, 0, TAU, 128, Color(accent, 0.22), 1.0, true)
	var minor_lines := PackedVector2Array()
	var major_lines := PackedVector2Array()
	for tick in range(120):
		var angle := float(tick) * TAU / 120.0 - PI * 0.5
		var ray := Vector2.from_angle(angle)
		var major := tick % 10 == 0
		var lines: PackedVector2Array = major_lines if major else minor_lines
		lines.append(center + ray * radius * 0.91)
		lines.append(center + ray * radius * (0.87 if major else 0.895))
		if major: major_lines = lines
		else: minor_lines = lines
	draw_multiline(minor_lines,Color(accent,0.28),1.0,true)
	draw_multiline(major_lines,Color(accent,0.7),2.0,true)
	if quadrant > 0:
		var start := deg_to_rad(float((quadrant - 1) * 90) - 75.0)
		draw_arc(center, radius * 0.84, start, start + PI * 0.5, 40, Color(accent, 0.45), 3.0, true)
	if active_hour > 0:
		var angle := deg_to_rad(float(active_hour) * 30.0 - 90.0)
		var point := center + Vector2.from_angle(angle) * radius * 0.71
		var pulse := 0.5 + sin(elapsed * 3.0) * 0.15
		draw_arc(point, 36.0, 0, TAU, 48, Color(accent, pulse), 2.0, true)
	# Slowly counter-rotating energy arcs stay inside the readable hour track.
	for i in range(3):
		var start := elapsed * 0.08 + float(i) * TAU / 3.0
		draw_arc(center, radius * 0.52, start, start + 0.65, 24, Color(accent, 0.3), 1.5, true)
