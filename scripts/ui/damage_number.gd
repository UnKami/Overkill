class_name DamageNumber extends Label
## Split damage-number system (data schema doc, Part 2.3): normal and Overkill
## damage are NEVER a single combined number - this scene is instantiated
## once per number, gray for base damage, amber for Overkill, so the split is
## legible on every single kill. OK-gain animation intensity scales with the
## amount gained (small pop for a small kill, bigger/longer for a big one).

const COLOR_BASE := Color("#D8D8D8")
const COLOR_OVERKILL := Color("#EF9F27")


func setup(value: int, is_overkill: bool) -> void:
	text = str(value)
	if is_overkill:
		add_theme_color_override("font_color", COLOR_OVERKILL)
		add_theme_font_size_override("font_size", 36)
		_animate_overkill(value)
	else:
		add_theme_color_override("font_color", COLOR_BASE)
		add_theme_font_size_override("font_size", 26)
		_animate_base()


func _animate_base() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.15)
	tween.chain().tween_callback(queue_free)


## Intensity scales with OK amount: a 3 OK kill gets a small pop, a 40 OK
## kill gets a bigger, longer, more dramatic moment.
func _animate_overkill(value: int) -> void:
	var intensity: float = clampf(float(value) / 40.0, 0.0, 1.0)
	var punch_scale: float = lerpf(1.15, 1.6, intensity)
	var float_distance: float = lerpf(35.0, 70.0, intensity)
	var duration: float = lerpf(0.5, 0.9, intensity)

	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * punch_scale, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(self, "position:y", position.y - float_distance, duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
