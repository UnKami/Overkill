extends Control
## Lightweight live engravings above the physical dial and below its sockets.
var accent: Color = Color("7bd6de"):
	set(value):
		accent = value
		queue_redraw()
		if is_instance_valid(_static): _static.queue_redraw()
var active_hour: int = 0:
	set(value):
		active_hour = value
		queue_redraw()
var quadrant: int = 0:
	set(value):
		quadrant = value
		queue_redraw()
var elapsed: float = 0.0
var _static: Control
var _was_reduced: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_static = Control.new()
	_static.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_static)
	_static.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_static.draw.connect(_draw_static)
	resized.connect(func() -> void: _static.queue_redraw())

func _process(delta: float) -> void:
	var reduced: bool = AudioManager.reduced_motion
	if not reduced:
		elapsed += delta
		queue_redraw()
	elif not _was_reduced:
		queue_redraw()
	_was_reduced = reduced

func _draw_static() -> void:
	var center := size * 0.5
	var radius := size.x * 0.5
	for ring in [0.97, 0.92, 0.61, 0.57]:
		_static.draw_arc(center, radius * ring, 0, TAU, 128, Color(accent, 0.22), 1.0, true)
	var minor_lines := PackedVector2Array()
	var major_lines := PackedVector2Array()
	for tick in range(90):
		var angle := float(tick) * TAU / 90.0 - PI * 0.5
		var ray := Vector2.from_angle(angle)
		var major := tick % 10 == 0
		var lines: PackedVector2Array = major_lines if major else minor_lines
		lines.append(center + ray * radius * 0.91)
		lines.append(center + ray * radius * (0.87 if major else 0.895))
		if major: major_lines = lines
		else: minor_lines = lines
	_static.draw_multiline(minor_lines,Color(accent,0.28),1.0,true)
	_static.draw_multiline(major_lines,Color(accent,0.7),2.0,true)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = size.x * 0.5
	if quadrant > 0:
		var start := deg_to_rad(float((quadrant - 1) * 120) - 70.0)
		draw_arc(center, radius * 0.84, start, start + TAU / 3.0, 40, Color(accent, 0.45), 3.0, true)
	if active_hour > 0:
		var angle := deg_to_rad(float(active_hour) * 40.0 - 90.0)
		var point := center + Vector2.from_angle(angle) * radius * 0.71
		var pulse := 0.5 + sin(elapsed * 3.0) * 0.15
		draw_arc(point, 36.0, 0, TAU, 48, Color(accent, pulse), 2.0, true)
	# Slowly counter-rotating energy arcs stay inside the readable hour track.
	for i in range(3):
		var start := elapsed * 0.08 + float(i) * TAU / 3.0
		draw_arc(center, radius * 0.52, start, start + 0.65, 24, Color(accent, 0.3), 1.5, true)
