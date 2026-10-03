class_name AttackPresentation extends RefCounted
## Visual-only attack profiles. Combat math remains in CombatController; a
## profile only describes anticipation, travel, impact and recovery staging.

const GENERIC_ID := "weapon_cut"
const HEAVY_HAMMER_ID := "heavy_hammer"


static func for_relic(relic: ClockRelicData) -> Dictionary:
	var profile := {
		"id": "measured_strike",
		"anticipation": 0.20,
		"travel": 0.10,
		"impact_hold": 0.045,
		"recovery": 0.335,
		"hit_recoil": 0.065,
		"hit_settle": 0.225,
		"travel_pixels": 48.0,
		"lift_pixels": 0.0,
		"accent": Color("8ad5e1"),
		"shake": 0.0,
	}
	if relic == null:
		return profile
	profile.accent = relic.primary_color()
	var effect_magnitude: int = maxi(relic.base_damage * maxi(relic.hits, 1), maxi(relic.base_block, maxi(relic.apply_strength, maxi(relic.apply_thorns, maxi(relic.apply_vulnerable, maxi(relic.apply_weak, relic.apply_bleed))))))
	var prior_impact_scale: float = 2.0 if relic.id == "REL-03" else 1.45
	profile["impact_scale"] = clampf(prior_impact_scale * 2.0 + sqrt(float(effect_magnitude)) * 0.12, prior_impact_scale * 2.0, 5.2)
	if relic.hits > 1:
		profile.merge({
			"id": "quick_combo",
			"anticipation": 0.10,
			"travel": 0.055,
			"impact_hold": 0.035,
			"recovery": 0.13,
			"hit_recoil": 0.045,
			"hit_settle": 0.05,
			"travel_pixels": 36.0,
			"lift_pixels": 2.0,
		}, true)
	elif relic.base_damage >= 10 or relic.conditional_damage >= 10:
		profile.merge({
			"id": "heavy_strike",
			"anticipation": 0.27,
			"travel": 0.13,
			"impact_hold": 0.085,
			"recovery": 0.39,
			"hit_recoil": 0.09,
			"hit_settle": 0.215,
			"travel_pixels": 82.0,
			"lift_pixels": 12.0,
			"shake": 4.5,
		}, true)
	if relic.id == "REL-03":
		profile = {
			"id": HEAVY_HAMMER_ID,
			"anticipation": 0.28,
			"travel": 0.18,
			"impact_hold": 0.095,
			"recovery": 0.42,
			"hit_recoil": 0.10,
			"hit_settle": 0.225,
			"travel_pixels": 148.0,
			"lift_pixels": 38.0,
			"accent": Color("ffae52"),
			"shake": 9.0,
		}
	# Real relics use the same Blender-authored contact markers as the skeletal
	# actor and their articulated prop cue. Synthetic test/comparison resources
	# retain the generic profile above.
	var clips: Dictionary = preload("res://assets/animations/relics/relic_tracks.gd").DATA.clips
	if clips.has(relic.id):
		var clip: Dictionary = clips[relic.id]
		profile["relic_id"] = relic.id
		profile["rig_action"] = str(clip.actor_action)
		profile["rig_contact"] = float(clip.contact)
		profile["rig_duration"] = float(clip.duration)
		if relic.base_damage > 0:
			var travel: float = .55 if relic.id == "REL-01" else .40
			profile["anticipation"] = float(clip.contact) - travel
			profile["travel"] = travel
			profile["impact_hold"] = .12
			profile["recovery"] = maxf(.45, float(clip.duration) - float(clip.contact))
	return profile


## Enemy intent gets its own readable signature: fast, compact multi-hit
## flurries; a clear extra wind-up and stronger recoil for a heavy blow.
static func for_enemy(intent: ClockSocketData) -> Dictionary:
	var profile := {
		"id": "enemy_strike",
		"anticipation": 0.15,
		"travel": 0.08,
		"impact_hold": 0.045,
		"recovery": 0.295,
		"hit_recoil": 0.055,
		"hit_settle": 0.195,
		"travel_pixels": 38.0,
		"lift_pixels": 0.0,
		"accent": Color("e99778"),
		"shake": 3.0,
	}
	if intent.intent_hits > 1:
		profile.merge({
			"id": "enemy_flurry",
			"anticipation": 0.10,
			"travel": 0.055,
			"impact_hold": 0.025,
			"recovery": 0.13,
			"hit_recoil": 0.04,
			"hit_settle": 0.065,
			"travel_pixels": 27.0,
			"shake": 2.2,
		}, true)
	elif intent.intent_damage >= 10:
		profile.merge({
			"id": "enemy_heavy",
			"anticipation": 0.29,
			"travel": 0.15,
			"impact_hold": 0.09,
			"recovery": 0.40,
			"hit_recoil": 0.09,
			"hit_settle": 0.22,
			"travel_pixels": 66.0,
			"lift_pixels": 8.0,
			"shake": 7.0,
		}, true)
	return profile


static func is_heavy_hammer(profile: Dictionary) -> bool:
	return str(profile.get("id", GENERIC_ID)) == HEAVY_HAMMER_ID


static func play_canvas_impact(parent: Control, at: Vector2, profile: Dictionary) -> void:
	var accent: Color = profile.get("accent", Color("8ad5e1"))
	var impact_scale: float = float(profile.get("impact_scale", 4.0 if is_heavy_hammer(profile) else 2.9))
	CombatVFX.play_slash(parent, at, -62.0 if is_heavy_hammer(profile) else -35.0, accent, impact_scale)
	CombatVFX.play_hit_sparks(parent, at, accent.lightened(0.28), 18 if is_heavy_hammer(profile) else 10, impact_scale / 2.0)
	if not is_heavy_hammer(profile): return
	var shockwave := TextureRect.new()
	shockwave.texture = AmbientMotion._get_glow_texture()
	shockwave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shockwave.position = at - Vector2(110, 110)
	var shockwave_size: float = 220.0 * impact_scale / 2.0
	shockwave.size = Vector2(shockwave_size, shockwave_size)
	shockwave.pivot_offset = Vector2(shockwave_size * 0.5, shockwave_size * 0.5)
	shockwave.modulate = Color(accent, 0.9)
	shockwave.scale = Vector2(0.18, 0.18)
	shockwave.z_index = 54
	parent.add_child(shockwave)
	var burst := shockwave.create_tween().set_parallel(true).set_speed_scale(AudioManager.combat_animation_speed_scale())
	burst.tween_property(shockwave, "scale", Vector2(1.85, 1.85), 0.24).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	burst.tween_property(shockwave, "modulate:a", 0.0, 0.22).set_delay(0.04)
	burst.chain().tween_callback(shockwave.queue_free)


## Relic identities now travel with the execution rather than firing as an
## unseen math event. Multi-hit calls this once per hit so each beat reads.
static func play_relic_activation(
	parent: Control,
	relic: ClockRelicData,
	from_global: Vector2,
	to_global: Vector2,
	effect_magnitude: int,
	hit_index: int = 0,
	hit_count: int = 1
) -> void:
	if parent == null or relic == null or not parent.is_inside_tree():
		return
	var texture: Texture2D = RelicArt.load_texture(relic.art_id)
	if texture == null:
		return
	var view := TextureRect.new()
	view.name = "RelicActivationFlight"
	view.texture = texture
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var size_px: float = 300.0 * clampf(1.0 + sqrt(float(maxi(effect_magnitude, 1))) * 0.055, 1.05, 1.8)
	view.size = Vector2(size_px, size_px)
	view.pivot_offset = view.size * 0.5
	view.position = from_global - parent.global_position - view.size * 0.5
	view.rotation = -0.18 if relic.primary_essence == ClockRelicData.Essence.ATTACK else 0.0
	view.modulate = Color(1, 1, 1, 0)
	view.scale = Vector2(0.62, 0.62)
	view.z_index = 90
	parent.add_child(view)
	var destination: Vector2 = to_global - parent.global_position - view.size * 0.5
	var direction: Vector2 = (to_global - from_global).normalized()
	var overshoot: Vector2 = destination + direction * minf(38.0, size_px * 0.09)
	var duration: float = 0.34 if hit_count <= 1 else 0.27
	var tween: Tween = view.create_tween().set_speed_scale(AudioManager.combat_animation_speed_scale())
	tween.set_parallel(true)
	tween.tween_property(view, "modulate:a", 1.0, 0.07)
	tween.tween_property(view, "position", overshoot, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(view, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "rotation", view.rotation + direction.angle() * 0.16, duration)
	tween.chain().tween_property(view, "scale", Vector2(0.72, 0.72), 0.10)
	tween.parallel().tween_property(view, "modulate:a", 0.0, 0.10)
	if hit_count > 1:
		var hit_label := Label.new()
		hit_label.name = "RelicHitCount"
		hit_label.text = "HIT %d / %d" % [hit_index + 1, hit_count]
		hit_label.add_theme_font_size_override("font_size", 24)
		hit_label.add_theme_color_override("font_color", relic.primary_color().lightened(0.25))
		hit_label.add_theme_color_override("font_outline_color", Color("06101be8"))
		hit_label.add_theme_constant_override("outline_size", 5)
		hit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hit_label.position = (from_global + to_global) * 0.5 - parent.global_position + Vector2(-120, -size_px * 0.45)
		hit_label.size = Vector2(240, 36)
		hit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit_label.z_index = 91
		parent.add_child(hit_label)
		var label_tween: Tween = hit_label.create_tween().set_speed_scale(AudioManager.combat_animation_speed_scale())
		label_tween.tween_property(hit_label, "position:y", hit_label.position.y - 28.0, duration + 0.08)
		label_tween.parallel().tween_property(hit_label, "modulate:a", 0.0, duration + 0.08)
		label_tween.tween_callback(hit_label.queue_free)
	tween.chain().tween_callback(view.queue_free)
