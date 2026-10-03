class_name BattleGuidance extends Control
## Read-only intent overlay. Never changes relics, combat state, or random state.
var target: Control
var source: Control
var clock: Control
var hours: Array[int] = []
var elapsed := 0.0
var _caption: Label
var _ghost: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 35
	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size",27)
	_caption.add_theme_color_override("font_color",Color("e8d5a7"))
	_caption.add_theme_color_override("font_outline_color",Color("071018"))
	_caption.add_theme_constant_override("outline_size",8)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption)
	_ghost = TextureRect.new()
	_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.modulate.a = 0.62
	add_child(_ghost)

func point_to(dial: Control, socket: Control, active_hours: Array[int], caption: String, origin: Control = null, texture: Texture2D = null) -> void:
	if is_instance_valid(clock) and clock != dial: clock.set_readout_clearance(false)
	clock = dial
	clock.set_readout_clearance(true)
	target = socket
	source = origin
	hours = active_hours
	_caption.text = caption
	_ghost.texture = texture
	visible = true

func clear() -> void:
	if is_instance_valid(clock): clock.set_readout_clearance(false)
	visible = false
	target = null
	source = null
	_ghost.texture = null

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(clock): return
	elapsed += delta
	var center := clock.global_position + clock.size*0.5 - global_position
	_caption.position = center + Vector2(-115,-38)
	_caption.size = Vector2(230,76)
	_ghost.visible = is_instance_valid(target) and _ghost.texture != null
	if _ghost.visible:
		_ghost.size = Vector2(54,54)
		_ghost.position = target.global_position + target.size*0.5 - global_position - _ghost.size*0.5
	queue_redraw()

func _draw() -> void:
	if not visible or not is_instance_valid(clock): return
	var center := clock.global_position + clock.size*0.5 - global_position
	var phase := 0.5 if AudioManager.reduced_motion else (sin(elapsed*4)+1)*0.5
	for hour in hours:
		var socket: Control = clock.get_socket_view(hour)
		var at := socket.global_position + socket.size*0.5 - global_position
		draw_arc(at,38+phase*4,0,TAU,48,Color(0.54,0.92,1,0.6+phase*0.3),3,true)
	if not is_instance_valid(target): return
	if not is_instance_valid(source): return
	var end := target.global_position + target.size*0.5 - global_position
	var start := source.global_position + source.size*0.5 - global_position
	var direction := (end-start).normalized()
	var finish := end-direction*42
	# A hovered relic still has a ghost and pulsing destination if its connector
	# would cross the caption. Never draw a moving ray through decision text.
	var caption_rect: Rect2 = _caption.get_rect().grow(8.0)
	var corners: Array[Vector2] = [caption_rect.position,Vector2(caption_rect.end.x,caption_rect.position.y),caption_rect.end,Vector2(caption_rect.position.x,caption_rect.end.y)]
	if caption_rect.has_point(start) or caption_rect.has_point(finish): return
	for edge: int in range(4):
		if Geometry2D.segment_intersects_segment(start,finish,corners[edge],corners[(edge+1)%4]) != null: return
	draw_line(start,finish,Color(0.55,0.86,0.95,0.45),3,true)
	draw_colored_polygon(PackedVector2Array([finish,finish-direction.rotated(0.45)*18,finish-direction.rotated(-0.45)*18]),Color("a9edf0"))
	if not AudioManager.reduced_motion:
		draw_circle(start.lerp(finish,fmod(elapsed*0.65,1.0)),5,Color("e9d098"))
