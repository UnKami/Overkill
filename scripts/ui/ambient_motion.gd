class_name AmbientMotion extends RefCounted
## Small reusable motion toolkit - the ONLY place these effects are defined,
## so every screen gets the same feel instead of hand-rolled one-off tweens.
## Two families, matching a screen's purpose:
##   - Idle/ambient (ken_burns, breathe, drift embers, pulse): screens meant
##     to be looked at calmly - title, shop, rest, map, class select.
##   - Action/reactive (punch_scale, shake): moments that mark something
##     happening - a reward reveal, an overkill hit, a run's outcome.
## All tweens are created via target.create_tween(), which Godot
## automatically stops when target leaves the tree - no manual cleanup.

static var _glow_texture_cache: ImageTexture = null


## Slow, continuous zoom+pan loop ("Ken Burns") for a full-screen background
## or a portrait that should feel alive without drawing attention to itself.
static func apply_ken_burns(target: Control, duration: float = 26.0, zoom_amount: float = 0.05) -> void:
	if AudioManager.reduced_motion: return
	target.pivot_offset = target.size * 0.5
	var tween := target.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "scale", Vector2.ONE * (1.0 + zoom_amount), duration * 0.5)
	tween.tween_property(target, "scale", Vector2.ONE, duration * 0.5)


## A subtle breathing scale loop - same mechanism as Ken Burns, tuned smaller
## and faster, for a character portrait or a "you are here" map marker.
static func breathe(target: Control, scale_delta: float = 0.03, duration: float = 2.6) -> void:
	apply_ken_burns(target, duration, scale_delta)


## Alpha breathing loop - for a glow/highlight that should pulse rather than
## scale (e.g. a reachable-node border, a tooltip accent).
static func pulse_alpha(target: CanvasItem, min_alpha: float = 0.55, max_alpha: float = 1.0, duration: float = 1.4) -> void:
	var tween := target.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "modulate:a", max_alpha, duration * 0.5)
	tween.tween_property(target, "modulate:a", min_alpha, duration * 0.5)


## Slow vertical bob loop - for a combat sprite's idle "breathing" motion.
static func idle_bob(target: Control, amplitude: float = 5.0, duration: float = 2.4) -> void:
	var base_position: Vector2 = target.position
	var tween := target.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "position:y", base_position.y - amplitude, duration * 0.5)
	tween.tween_property(target, "position:y", base_position.y, duration * 0.5)


## Quick scale-up-then-settle "punch" for a moment that just happened - a
## reward reveal, a run's win/lose title, an unlock celebration.
static func punch_scale(target: Control, peak_scale: float = 1.12, duration: float = 0.35) -> void:
	if AudioManager.reduced_motion: return
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE * 0.85
	var tween := target.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE * peak_scale, duration * 0.6)
	tween.tween_property(target, "scale", Vector2.ONE, duration * 0.4)


## Brief color tint pulse - the everyday "something just hit this" reaction
## (every normal attack landing, block gained, HP lost). Deliberately NOT
## shake(): shake stays reserved for the single biggest beat in the game (a
## large Overkill kill), so every hit doesn't compete for the same intensity
## and the big moment still reads as bigger than the routine ones.
static func flash(target: CanvasItem, color: Color, duration: float = 0.18) -> void:
	var base_modulate: Color = target.modulate
	var tween := target.create_tween()
	tween.tween_property(target, "modulate", color, duration * 0.35)
	tween.tween_property(target, "modulate", base_modulate, duration * 0.65)


## Brief positional shake - reserved for the single biggest reactive beat in
## the game (a large Overkill hit landing), not used casually.
static func shake(target: Control, magnitude: float = 10.0, duration: float = 0.3) -> void:
	if AudioManager.reduced_motion: return
	var base_position: Vector2 = target.position
	var tween := target.create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
		tween.tween_property(target, "position", base_position + offset, duration / steps)
	tween.tween_property(target, "position", base_position, duration / steps)


## Slow-drifting glow embers across (a region of) a Control, tinted to match
## the screen's palette - the ambient-life layer behind every calm screen.
## region defaults to the whole parent rect; pass a sub-rect (e.g. left/right
## half) to place two differently-tinted emitters side by side.
static func spawn_embers(parent: Control, color: Color, count: int = 14, upward: bool = true, region: Rect2 = Rect2()) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = _get_glow_texture()
	particles.amount = count
	particles.lifetime = 9.0
	particles.preprocess = 9.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var target_rect: Rect2 = region if region.size != Vector2.ZERO else Rect2(Vector2.ZERO, parent.size)
	particles.position = target_rect.position + target_rect.size * 0.5
	particles.emission_rect_extents = target_rect.size * 0.5
	particles.direction = Vector2.UP if upward else Vector2.DOWN
	particles.spread = 12.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 11.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.3
	particles.color = color
	parent.add_child(particles)
	particles.emitting = true
	return particles


static func _get_glow_texture() -> ImageTexture:
	if _glow_texture_cache != null:
		return _glow_texture_cache
	const SIZE := 16
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(SIZE, SIZE) * 0.5
	for x in SIZE:
		for y in SIZE:
			var d: float = Vector2(x, y).distance_to(center) / (SIZE * 0.5)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a *= a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_glow_texture_cache = ImageTexture.create_from_image(img)
	return _glow_texture_cache
