class_name ScreenTransition extends Control
## A brief illustrated passage, never a second gameplay screen.
static var _plate_cache: Texture2D
var _progress: float = 0.0
var _label: Label
var _plate: TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _plate_cache == null:
		_plate_cache = load(CinematicArt.LOADING)
	_plate = TextureRect.new()
	_plate.texture = _plate_cache
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("040b1000"), Color("040b10ee")])
	var shade_texture := GradientTexture2D.new()
	shade_texture.gradient = gradient
	shade_texture.fill_from = Vector2(0.5, 0.35)
	shade_texture.fill_to = Vector2(0.5, 1.0)
	var shade := TextureRect.new()
	shade.texture = shade_texture
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label = ScreenDesign.label(_plate, "", 40, ScreenDesign.TEXT, true)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.offset_left = -850
	_label.offset_right = -86
	_label.offset_top = -174
	_label.offset_bottom = -106
	var caption := ScreenDesign.label(_plate, "T H E   H O U R S   C A R R Y   Y O U   O N", 14, ScreenDesign.GOLD)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	caption.offset_left = -850
	caption.offset_right = -90
	caption.offset_top = -99
	caption.offset_bottom = -64
	_set_progress(0.0)

func play_cover(destination: String = "") -> void:
	_label.text = destination.to_upper()
	_set_progress(0.0)
	var motion := create_tween()
	motion.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_method(_set_progress, 0.0, 1.0, 0.14 if AudioManager.reduced_motion else 0.42)
	await motion.finished

func play_reveal() -> void:
	var motion := create_tween()
	# A readable beat without a fake loading percentage or forced long wait.
	if not AudioManager.reduced_motion:
		motion.tween_interval(0.20)
	motion.tween_method(_set_progress, 1.0, 0.0, 0.16 if AudioManager.reduced_motion else 0.42)
	await motion.finished
	queue_free()

func _set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	_plate.modulate.a = _progress
	_plate.pivot_offset = size * 0.5
	_plate.scale = Vector2.ONE if AudioManager.reduced_motion else Vector2.ONE * (1.015 + (1.0 - _progress) * 0.025)
