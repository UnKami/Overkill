class_name IllustratedActor extends Control
## Pose atlas with eased anticipation, strike travel, recoil and recovery.
const HEAVY_HAMMER_PATH := "res://assets/vfx/heavy_hammer_strike.png"

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
var _ability_weapon: Node2D
var _ability_weapon_motion: Tween

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

func attack(profile: Dictionary = {}) -> void:
	_contact_ready = false
	_begin()
	var anticipation: float = float(profile.get("anticipation", 0.19))
	var travel: float = float(profile.get("travel", 0.07))
	var impact_hold: float = float(profile.get("impact_hold", 0.085))
	var recovery: float = float(profile.get("recovery", 0.27))
	var travel_pixels: float = float(profile.get("travel_pixels", 42.0))
	var lift_pixels: float = float(profile.get("lift_pixels", 0.0))
	var heavy: bool = AttackPresentation.is_heavy_hammer(profile)
	set_pose(1)
	if heavy: _play_spectral_hammer(profile)
	_motion.tween_property(_front, "position:x", _pose_origin.x - facing * (22.0 if heavy else 14.0), anticipation).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_motion.parallel().tween_property(_front, "position:y", _pose_origin.y + (7.0 if heavy else 0.0), anticipation)
	_motion.tween_callback(func() -> void: set_pose(2))
	_motion.tween_property(_front, "position:x", _pose_origin.x + facing * travel_pixels, travel).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_motion.parallel().tween_property(_front, "position:y", _pose_origin.y - lift_pixels, travel).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion.tween_callback(func() -> void: _contact_ready = true)
	_motion.tween_interval(impact_hold)
	_motion.tween_callback(func() -> void: set_pose(3))
	_motion.tween_property(_front, "position:x", _pose_origin.x, recovery).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.parallel().tween_property(_front, "position:y", _pose_origin.y, recovery).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_motion.tween_callback(_rest)


func _play_spectral_hammer(profile: Dictionary) -> void:
	if is_instance_valid(_ability_weapon): _ability_weapon.queue_free()
	_ability_weapon = Node2D.new()
	_ability_weapon.z_index = 8
	_ability_weapon.position = _front.size * Vector2(0.5, 0.58)
	_ability_weapon.scale.x = facing
	# Parenting the ability weapon to the animated pose makes it travel with the
	# Executioner's launch instead of hovering where the idle frame began.
	_front.add_child(_ability_weapon)
	var weapon := Sprite2D.new()
	weapon.texture = load(HEAVY_HAMMER_PATH)
	weapon.scale = Vector2(0.17, 0.17)
	# Offset the art so the tween rotates around the lower grip in the
	# Executioner's hands instead of around the center of the image.
	weapon.position = Vector2(0, -55)
	_ability_weapon.add_child(weapon)
	_ability_weapon.modulate.a = 0.0
	_ability_weapon.rotation = -1.0 * facing
	_ability_weapon_motion = _ability_weapon.create_tween().set_parallel(true).set_speed_scale(AudioManager.animation_speed_scale())
	_ability_weapon_motion.tween_property(_ability_weapon, "modulate:a", 1.0, 0.10)
	_ability_weapon_motion.tween_property(_ability_weapon, "rotation", 1.38 * facing, float(profile.get("anticipation",0.22)) + float(profile.get("travel",0.18))).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_ability_weapon_motion.chain().tween_property(_ability_weapon, "modulate:a", 0.0, float(profile.get("recovery",0.34)))
	_ability_weapon_motion.chain().tween_callback(_ability_weapon.queue_free)

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
