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
	if relic.hits > 1:
		profile.merge({
			"id": "quick_combo",
			"anticipation": 0.115,
			"travel": 0.065,
			"impact_hold": 0.035,
			"recovery": 0.235,
			"hit_recoil": 0.045,
			"hit_settle": 0.155,
			"travel_pixels": 36.0,
			"lift_pixels": 2.0,
		}, true)
	elif relic.base_damage >= 10 or relic.conditional_damage >= 10:
		profile.merge({
			"id": "heavy_strike",
			"anticipation": 0.29,
			"travel": 0.14,
			"impact_hold": 0.085,
			"recovery": 0.475,
			"hit_recoil": 0.09,
			"hit_settle": 0.30,
			"travel_pixels": 82.0,
			"lift_pixels": 12.0,
			"shake": 4.5,
		}, true)
	if relic.id == "REL-03":
		profile = {
			"id": HEAVY_HAMMER_ID,
			"anticipation": 0.31,
			"travel": 0.21,
			"impact_hold": 0.095,
			"recovery": 0.525,
			"hit_recoil": 0.10,
			"hit_settle": 0.33,
			"travel_pixels": 148.0,
			"lift_pixels": 38.0,
			"accent": Color("ffae52"),
			"shake": 9.0,
		}
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
			"recovery": 0.205,
			"hit_recoil": 0.04,
			"hit_settle": 0.14,
			"travel_pixels": 27.0,
			"shake": 2.2,
		}, true)
	elif intent.intent_damage >= 10:
		profile.merge({
			"id": "enemy_heavy",
			"anticipation": 0.29,
			"travel": 0.15,
			"impact_hold": 0.09,
			"recovery": 0.48,
			"hit_recoil": 0.09,
			"hit_settle": 0.30,
			"travel_pixels": 66.0,
			"lift_pixels": 8.0,
			"shake": 7.0,
		}, true)
	return profile


static func is_heavy_hammer(profile: Dictionary) -> bool:
	return str(profile.get("id", GENERIC_ID)) == HEAVY_HAMMER_ID


static func play_canvas_impact(parent: Control, at: Vector2, profile: Dictionary) -> void:
	var accent: Color = profile.get("accent", Color("8ad5e1"))
	CombatVFX.play_slash(parent, at, -62.0 if is_heavy_hammer(profile) else -35.0, accent, 2.0 if is_heavy_hammer(profile) else 1.45)
	CombatVFX.play_hit_sparks(parent, at, accent.lightened(0.28), 12 if is_heavy_hammer(profile) else 6)
	if not is_heavy_hammer(profile): return
	var shockwave := TextureRect.new()
	shockwave.texture = AmbientMotion._get_glow_texture()
	shockwave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shockwave.position = at - Vector2(110, 110)
	shockwave.size = Vector2(220, 220)
	shockwave.pivot_offset = Vector2(110, 110)
	shockwave.modulate = Color(accent, 0.9)
	shockwave.scale = Vector2(0.18, 0.18)
	shockwave.z_index = 54
	parent.add_child(shockwave)
	var burst := shockwave.create_tween().set_parallel(true).set_speed_scale(AudioManager.combat_animation_speed_scale())
	burst.tween_property(shockwave, "scale", Vector2(1.85, 1.85), 0.24).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	burst.tween_property(shockwave, "modulate:a", 0.0, 0.22).set_delay(0.04)
	burst.chain().tween_callback(shockwave.queue_free)
