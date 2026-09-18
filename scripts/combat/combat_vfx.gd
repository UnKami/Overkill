class_name CombatVFX extends Node
## CombatVFX - Central manager for all tactical and reactive visual effects.
## Provides punchy, responsive arcade effects (0.15s - 0.4s) that never stall
## input but give combat weight, impact, and excitement.

const SLASH_TEXTURE_PATH := "res://assets/vfx/vfx_slash.png"
const SPARK_TEXTURE_PATH := "res://assets/vfx/vfx_hit_spark.png"
const SHIELD_TEXTURE_PATH := "res://assets/vfx/vfx_shield_flash.png"
const OVERKILL_TEXTURE_PATH := "res://assets/vfx/vfx_overkill_burst.png"
const OK_ORB_TEXTURE_PATH := "res://assets/vfx/vfx_ok_orb.png"

static var _slash_tex: Texture2D = null
static var _spark_tex: Texture2D = null
static var _shield_tex: Texture2D = null
static var _overkill_tex: Texture2D = null
static var _ok_orb_tex: Texture2D = null


static func _get_tex(path: String, cache_ref: Texture2D) -> Texture2D:
	if cache_ref != null:
		return cache_ref
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


## Spawns an energetic slash crescent slicing across a target.
static func play_slash(parent: CanvasItem, target_center: Vector2, angle_deg: float = -35.0, color: Color = Color.WHITE, scale_factor: float = 1.5) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	_slash_tex = _get_tex(SLASH_TEXTURE_PATH, _slash_tex)
	if _slash_tex == null:
		return

	var slash := TextureRect.new()
	slash.texture = _slash_tex
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slash.custom_minimum_size = Vector2(240, 240)
	slash.size = Vector2(240, 240)
	slash.pivot_offset = Vector2(120, 120)
	slash.position = target_center - Vector2(120, 120)
	slash.rotation = deg_to_rad(angle_deg)
	slash.modulate = color
	slash.z_index = 50
	parent.add_child(slash)

	slash.scale = Vector2(0.2, scale_factor * 1.3)
	var tween := slash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash, "scale", Vector2(scale_factor * 1.2, scale_factor), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(slash, "position", slash.position + Vector2(randf_range(-15, 15), randf_range(-10, 10)), 0.18)
	tween.tween_property(slash, "modulate:a", 0.0, 0.14).set_delay(0.08)
	tween.chain().tween_callback(slash.queue_free)


## Spawns kinetic impact sparks radiating from a hit point.
static func play_hit_sparks(parent: CanvasItem, target_center: Vector2, color: Color = Color(1.0, 0.95, 0.8), count: int = 5) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	_spark_tex = _get_tex(SPARK_TEXTURE_PATH, _spark_tex)
	if _spark_tex == null:
		return

	var flare := TextureRect.new()
	flare.texture = _spark_tex
	flare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flare.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flare.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flare.custom_minimum_size = Vector2(128, 128)
	flare.size = Vector2(128, 128)
	flare.pivot_offset = Vector2(64, 64)
	flare.position = target_center - Vector2(64, 64)
	flare.rotation = randf_range(0, TAU)
	flare.modulate = color
	flare.scale = Vector2(0.4, 0.4)
	flare.z_index = 51
	parent.add_child(flare)

	var tween := flare.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flare, "scale", Vector2(1.6, 1.6), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flare, "modulate:a", 0.0, 0.16).set_delay(0.06)
	tween.chain().tween_callback(flare.queue_free)

	for i in count:
		var speck := TextureRect.new()
		speck.texture = _spark_tex
		speck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		speck.custom_minimum_size = Vector2(32, 32)
		speck.size = Vector2(32, 32)
		speck.pivot_offset = Vector2(16, 16)
		speck.position = target_center - Vector2(16, 16)
		speck.modulate = color
		speck.scale = Vector2(randf_range(0.3, 0.6), randf_range(0.3, 0.6))
		speck.z_index = 52
		parent.add_child(speck)

		var ang := randf_range(0, TAU)
		var dist := randf_range(50, 110)
		var dest := speck.position + Vector2(cos(ang), sin(ang)) * dist
		var sp_tween := speck.create_tween()
		sp_tween.set_parallel(true)
		sp_tween.tween_property(speck, "position", dest, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sp_tween.tween_property(speck, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		sp_tween.chain().tween_callback(speck.queue_free)


## Spawns an expanding hexagonal crystalline runic shield barrier over the player.
static func play_shield_pulse(parent: CanvasItem, target_center: Vector2) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	_shield_tex = _get_tex(SHIELD_TEXTURE_PATH, _shield_tex)
	if _shield_tex == null:
		return

	var shield := TextureRect.new()
	shield.texture = _shield_tex
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shield.custom_minimum_size = Vector2(256, 256)
	shield.size = Vector2(256, 256)
	shield.pivot_offset = Vector2(128, 128)
	shield.position = target_center - Vector2(128, 128)
	shield.modulate = Color(1.2, 1.4, 1.8, 0.0)
	shield.scale = Vector2(0.5, 0.5)
	shield.z_index = 48
	parent.add_child(shield)

	var tween := shield.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shield, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(shield, "modulate:a", 1.0, 0.1)
	tween.chain().set_parallel(true)
	tween.tween_property(shield, "scale", Vector2(1.5, 1.5), 0.22).set_trans(Tween.TRANS_SINE)
	tween.tween_property(shield, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(shield.queue_free)


## Spawns a violent explosive shockwave and crystal shard burst on Overkill kills.
static func play_overkill_burst(parent: CanvasItem, target_center: Vector2, overkill: int = 10) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	_overkill_tex = _get_tex(OVERKILL_TEXTURE_PATH, _overkill_tex)
	if _overkill_tex == null:
		return

	var burst := TextureRect.new()
	burst.texture = _overkill_tex
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.custom_minimum_size = Vector2(300, 300)
	burst.size = Vector2(300, 300)
	burst.pivot_offset = Vector2(150, 150)
	burst.position = target_center - Vector2(150, 150)
	burst.rotation = randf_range(0, TAU)
	burst.modulate = Color(1.5, 1.3, 0.8, 1.0)
	burst.scale = Vector2(0.4, 0.4)
	burst.z_index = 55
	parent.add_child(burst)

	var scale_target: float = clampf(1.8 + overkill * 0.04, 2.0, 3.2)
	var tween := burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2(scale_target, scale_target), 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "rotation", burst.rotation + 0.5, 0.3)
	tween.tween_property(burst, "modulate:a", 0.0, 0.26).set_delay(0.06)
	tween.chain().tween_callback(burst.queue_free)


## Emits glowing amber OK essence particles that arc from a slain enemy into the Overkill HUD meter.
static func play_ok_essence_trail(parent: CanvasItem, from_pos: Vector2, to_pos: Vector2, orb_count: int = 5) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	_ok_orb_tex = _get_tex(OK_ORB_TEXTURE_PATH, _ok_orb_tex)
	if _ok_orb_tex == null:
		return

	var count: int = clampi(orb_count, 3, 8)
	for i in count:
		var orb := TextureRect.new()
		orb.texture = _ok_orb_tex
		orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orb.custom_minimum_size = Vector2(32, 32)
		orb.size = Vector2(32, 32)
		orb.pivot_offset = Vector2(16, 16)
		orb.position = from_pos - Vector2(16, 16)
		orb.scale = Vector2(0.3, 0.3)
		orb.modulate = Color(1.4, 1.2, 0.5, 0.0)
		orb.z_index = 60
		parent.add_child(orb)

		var delay: float = i * 0.06
		var mid_offset := Vector2(randf_range(-120, 120), randf_range(-140, -40))
		var mid_pos := (from_pos + to_pos) * 0.5 + mid_offset

		var tween := orb.create_tween()
		tween.tween_property(orb, "scale", Vector2(1.2, 1.2), 0.12).set_delay(delay)
		tween.parallel().tween_property(orb, "modulate:a", 1.0, 0.08).set_delay(delay)
		tween.tween_property(orb, "position", mid_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(orb, "position", to_pos - Vector2(16, 16), 0.24).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(orb, "scale", Vector2(0.4, 0.4), 0.24)
		tween.parallel().tween_property(orb, "modulate:a", 0.0, 0.08).set_delay(0.36 + delay)
		tween.chain().tween_callback(orb.queue_free)
