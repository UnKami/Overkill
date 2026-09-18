class_name IllustratedActor extends Control
## Pose atlas with eased anticipation, strike travel, recoil and recovery.
var atlas: Texture2D
var facing: float = 1.0
var target_height: float = 310.0
var _front: TextureRect
var _back: TextureRect
var _motion: Tween
var _idle_time: float = 0.0
var _busy: bool = false
var _contact_ready: bool = false
var _origin := Vector2.ZERO
var _frame_bottoms: Array[float] = []
var _pose_origin := Vector2.ZERO
var _art_scale: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(2):
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if i == 0: _back = art
		else: _front = art
	_front.pivot_offset = size * Vector2(0.5, 0.85)
	if atlas:
		var pixels := atlas.get_image()
		var cell_size := Vector2i(atlas.get_width() / 4, atlas.get_height() / 2)
		for frame in range(8):
			var bounds := _visible_bounds(pixels.get_region(Rect2i(Vector2i(frame % 4, frame / 4) * cell_size, cell_size)))
			_frame_bottoms.append(float(bounds.end.y))
			if frame == 0: _art_scale = target_height / maxf(1.0, float(bounds.size.y))
	set_pose(0)


func _visible_bounds(pixels: Image) -> Rect2i:
	# Ignore nearly transparent edge noise in generated atlases, using a sparse scan.
	var low := Vector2i(pixels.get_width(), pixels.get_height())
	var high := Vector2i.ZERO
	for y in range(0, pixels.get_height(), 3):
		for x in range(0, pixels.get_width(), 3):
			if pixels.get_pixel(x, y).a > 0.2:
				low.x = mini(low.x, x)
				low.y = mini(low.y, y)
				high.x = maxi(high.x, x + 3)
				high.y = maxi(high.y, y + 3)
	return Rect2i(low, high - low) if high.y > low.y else Rect2i(Vector2i.ZERO, pixels.get_size())

func set_pose(frame: int) -> void:
	if atlas == null: return
	var region := AtlasTexture.new()
	region.atlas = atlas
	var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 2.0)
	region.region = Rect2(Vector2(frame % 4, floori(float(frame) / 4.0)) * cell, cell)
	_front.texture = region
	_front.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_front.size = cell * _art_scale
	_pose_origin = Vector2((size.x - _front.size.x) * 0.5, size.y - 45.0 - _frame_bottoms[frame] * _art_scale)
	_front.position = _pose_origin
	_front.pivot_offset = Vector2(_front.size.x * 0.5, _frame_bottoms[frame] * _art_scale)

func _process(delta: float) -> void:
	_idle_time += delta
	if not _busy and not AudioManager.reduced_motion:
		_front.position.y = _pose_origin.y + sin(_idle_time * 1.65) * 2.0
		_front.scale.y = 1.0 + sin(_idle_time * 1.65) * 0.005

func _begin() -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	_busy = true
	_front.position = _pose_origin
	_front.scale = Vector2.ONE
	_front.rotation = 0
	_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())

func attack() -> void:
	_contact_ready = false
	_begin()
	set_pose(1)
	_motion.tween_property(_front, "position:x", _pose_origin.x - facing * 14.0, 0.19).set_trans(Tween.TRANS_CUBIC)
	_motion.tween_callback(func() -> void: set_pose(2))
	_motion.tween_property(_front, "position:x", _pose_origin.x + facing * 42.0, 0.07).set_trans(Tween.TRANS_EXPO)
	_motion.tween_callback(func() -> void: _contact_ready = true)
	_motion.tween_interval(0.085)
	_motion.tween_callback(func() -> void: set_pose(3))
	_motion.tween_property(_front, "position:x", _pose_origin.x, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.tween_callback(_rest)

func hit(blocked: bool) -> void:
	_begin()
	set_pose(4 if blocked else 5)
	_front.modulate = Color(1.4, 1.4, 1.4)
	_motion.set_parallel(true)
	_motion.tween_property(_front, "position:x", _pose_origin.x - facing * (6 if blocked else 17), 0.065)
	_motion.tween_property(_front, "modulate", Color.WHITE, 0.16)
	_motion.chain().tween_property(_front, "position:x", _pose_origin.x, 0.2)
	_motion.tween_callback(_rest)

func fall() -> void:
	_begin()
	set_pose(7)
	_motion.tween_property(_front, "position:y", _pose_origin.y + 14.0, 0.3)
	_motion.tween_property(_front, "modulate:a", 0.0, 0.4)

func _rest() -> void:
	set_pose(0)
	_front.position = _pose_origin
	_busy = false
