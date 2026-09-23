class_name AttackPresentation extends RefCounted
## Visual-only attack profiles. Combat math remains in CombatController; a
## profile only describes anticipation, travel, impact and recovery staging.

const GENERIC_ID := "weapon_cut"
const HEAVY_HAMMER_ID := "heavy_hammer"


static func for_relic(relic: ClockRelicData) -> Dictionary:
	var profile := {
		"id": GENERIC_ID,
		"anticipation": 0.19,
		"travel": 0.08,
		"impact_hold": 0.025,
		"recovery": 0.27,
		"travel_pixels": 42.0,
		"lift_pixels": 0.0,
		"accent": Color("8ad5e1"),
		"shake": 0.0,
	}
	if relic != null and relic.id == "REL-03":
		profile = {
			"id": HEAVY_HAMMER_ID,
			"anticipation": 0.22,
			"travel": 0.18,
			"impact_hold": 0.055,
			"recovery": 0.34,
			"travel_pixels": 138.0,
			"lift_pixels": 34.0,
			"accent": Color("ffae52"),
			"shake": 9.0,
		}
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
	var burst := shockwave.create_tween().set_parallel(true)
	burst.tween_property(shockwave, "scale", Vector2(1.85, 1.85), 0.24).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	burst.tween_property(shockwave, "modulate:a", 0.0, 0.22).set_delay(0.04)
	burst.chain().tween_callback(shockwave.queue_free)
