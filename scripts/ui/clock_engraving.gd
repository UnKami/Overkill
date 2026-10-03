extends Control
## Lightweight live engravings above the physical dial and below its sockets.
var accent: Color = Color("7bd6de"):
	set(value):
		accent = value
		queue_redraw()
		if is_instance_valid(_static): _refresh_engraving()
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
var _engraving_cache: SubViewport
var _was_reduced: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The etched rings do not animate. Render their antialiased strokes once,
	# preserving their appearance without submitting thousands of segments per frame.
	_engraving_cache = SubViewport.new()
	_engraving_cache.transparent_bg = true
	_engraving_cache.disable_3d = true
	_engraving_cache.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_engraving_cache)
	_static = Control.new()
	_static.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_engraving_cache.add_child(_static)
	_static.draw.connect(_draw_static)
	var image: TextureRect = TextureRect.new()
	image.texture = _engraving_cache.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_refresh_engraving)
	_refresh_engraving()

func _refresh_engraving() -> void:
	if not is_instance_valid(_engraving_cache): return
	_engraving_cache.size = Vector2i(maxi(1, roundi(size.x)), maxi(1, roundi(size.y)))
	_static.size = size
	_static.queue_redraw()
	_engraving_cache.render_target_update_mode = SubViewport.UPDATE_ONCE

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
