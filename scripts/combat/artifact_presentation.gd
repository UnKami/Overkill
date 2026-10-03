class_name ArtifactPresentation extends RefCounted
## A run-wide Artifact visibly leaves its HUD reliquary and carries its color
## into the combatant it affects. This is presentation-only and never delays
## the deterministic clock resolver.

const BASE_FLIGHT_SIZE: float = 96.0


static func play(parent: Control, source: Control, target: Control, artifact: RelicData, effect: EffectData) -> void:
	if parent == null or target == null or artifact == null or not parent.is_inside_tree():
		return
	var tint: Color = _essence_color(artifact)
	var target_center: Vector2 = target.global_position + target.size * 0.5
	if AudioManager.reduced_motion:
		_impact(parent, target, target_center, tint, effect)
		return

	var origin_global: Vector2 = source.global_position + source.size * 0.5 if source != null and is_instance_valid(source) else parent.global_position + Vector2(110.0, 130.0)
	var start: Vector2 = _to_parent(parent, origin_global)
	var finish: Vector2 = _to_parent(parent, target_center)
	var magnitude: float = clampf(float(effect.value), 1.0, 24.0)
	var size_px: float = BASE_FLIGHT_SIZE + magnitude * 2.4
	var arc: Vector2 = (finish - start).rotated(-PI * 0.5).normalized() * minf(92.0, start.distance_to(finish) * 0.17)
	var midpoint: Vector2 = start.lerp(finish, 0.53) + arc
	var tint_lines: Array[Color] = [tint.lightened(0.40), tint, tint.darkened(0.22)]
	for strand_index: int in 3:
		var strand := Line2D.new()
		strand.name = "ArtifactEssenceTrail"
		strand.width = 2.8 if strand_index == 1 else 1.25
		strand.default_color = tint_lines[strand_index]
		strand.default_color.a = 0.72 if strand_index == 1 else 0.35
		strand.antialiased = true
		strand.z_index = 86
		strand.points = _trail_points(start, midpoint, finish, 0.0, float(strand_index - 1) * 4.0)
		parent.add_child(strand)
		var trail_tween := strand.create_tween()
		trail_tween.set_speed_scale(AudioManager.combat_animation_speed_scale())
		trail_tween.set_parallel(true)
		trail_tween.tween_method(func(progress: float) -> void:
			strand.points = _trail_points(start, midpoint, finish, progress, float(strand_index - 1) * 4.0)
		, 0.0, 1.0, 0.42).set_trans(Tween.TRANS_SINE)
		trail_tween.tween_property(strand, "modulate:a", 0.0, 0.15).set_delay(0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		trail_tween.chain().tween_callback(strand.queue_free)

	var flight := TextureRect.new()
	flight.name = "ArtifactEssenceFlight"
	flight.texture = RelicArt.load_texture(artifact.art_id)
	flight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flight.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flight.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flight.size = Vector2.ONE * size_px
	flight.pivot_offset = flight.size * 0.5
	flight.position = start - flight.size * 0.5
	flight.rotation = -0.22
	flight.scale = Vector2(0.46, 0.46)
	flight.modulate = tint.lightened(0.12)
	flight.modulate.a = 0.0
	flight.z_index = 87
	parent.add_child(flight)
	var tween := flight.create_tween()
	tween.set_speed_scale(AudioManager.combat_animation_speed_scale())
	tween.set_parallel(true)
	tween.tween_method(func(progress: float) -> void:
		flight.position = _bezier_point(start, midpoint, finish, progress) - flight.size * 0.5
	, 0.0, 1.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flight, "modulate:a", 1.0, 0.07)
	tween.tween_property(flight, "scale", Vector2.ONE * clampf(0.76 + magnitude * 0.012, 0.78, 1.04), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flight, "rotation", 0.28, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flight, "modulate:a", 0.0, 0.12).set_delay(0.33)
	tween.tween_property(flight, "scale", Vector2.ONE * 0.28, 0.12).set_delay(0.33).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(flight.queue_free)
	tween.tween_callback(func() -> void: _impact(parent, target, _to_parent(parent, target_center), tint, effect))


static func _impact(parent: Control, target: Control, center: Vector2, tint: Color, effect: EffectData) -> void:
	if not is_instance_valid(target):
		return
	var scale_factor: float = clampf(0.88 + float(effect.value) * 0.055, 0.92, 1.72)
	if effect.effect_type == EffectData.EffectType.BLOCK:
		CombatVFX.play_shield_pulse(parent, center)
		AmbientMotion.flash(target, Color(tint.r * 1.25, tint.g * 1.25, tint.b * 1.25, 1.0), 0.34)
	elif effect.effect_type == EffectData.EffectType.GAIN_OK:
		CombatVFX.play_hit_sparks(parent, center, tint, 6 + int(effect.value / 2), scale_factor)
		AmbientMotion.flash(target, Color(1.55, 0.72, 0.68, 1.0), 0.32)
	elif effect.effect_type == EffectData.EffectType.HEAL:
		CombatVFX.play_hit_sparks(parent, center, tint.lightened(0.2), 7 + int(effect.value / 3), scale_factor)
		AmbientMotion.flash(target, Color(1.3, 1.12, 1.55, 1.0), 0.42)
	elif effect.effect_type == EffectData.EffectType.STRENGTH:
		CombatVFX.play_hit_sparks(parent, center, tint.lightened(0.25), 6 + effect.value, scale_factor)
		AmbientMotion.punch_scale(target, clampf(1.08 + float(effect.value) * 0.015, 1.10, 1.22), 0.36)
	elif effect.effect_type == EffectData.EffectType.APPLY_STATUS or effect.effect_type == EffectData.EffectType.ATTACK_BONUS:
		CombatVFX.play_slash(parent, center, -26.0, tint.lightened(0.28), scale_factor)
		CombatVFX.play_hit_sparks(parent, center, tint, 5 + int(effect.value / 2), scale_factor)
		AmbientMotion.flash(target, Color(1.0 + tint.r * 0.35, 1.0 + tint.g * 0.35, 1.0 + tint.b * 0.35, 1.0), 0.30)
	else:
		CombatVFX.play_hit_sparks(parent, center, tint.lightened(0.18), 5 + int(effect.value / 2), scale_factor)
		AmbientMotion.flash(target, Color(1.0 + tint.r * 0.28, 1.0 + tint.g * 0.28, 1.0 + tint.b * 0.28, 1.0), 0.30)


static func _trail_points(start: Vector2, control: Vector2, finish: Vector2, progress: float, side_offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var perpendicular: Vector2 = (finish - start).normalized().orthogonal() * side_offset
	var tail: float = maxf(0.0, progress - 0.12)
	for step: int in 5:
		var blend: float = float(step) / 4.0
		var t: float = lerpf(tail, progress, blend)
		points.append(_bezier_point(start, control, finish, t) + perpendicular * sin(t * PI))
	return points


static func _bezier_point(start: Vector2, control: Vector2, finish: Vector2, progress: float) -> Vector2:
	var t: float = clampf(progress, 0.0, 1.0)
	return start.lerp(control, t).lerp(control.lerp(finish, t), t)


static func _to_parent(parent: Control, canvas_point: Vector2) -> Vector2:
	return parent.get_global_transform().affine_inverse() * canvas_point


static func _essence_color(artifact: RelicData) -> Color:
	match str(artifact.condition_data.get("essence", "orange")):
		"blue": return Color("63c9ff")
		"purple": return Color("c27aff")
		"green": return Color("78da87")
		"blood_red": return Color("ee535b")
		_: return Color("ff9a36")
