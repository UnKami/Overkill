class_name ScreenTransition extends Control
## Reusable navigation curtain. It covers the outgoing scene before the swap,
## then unwinds over the installed destination. The gameplay scene never owns
## the transition, so map, shop, event and combat navigation share one cadence.

var _veil: ColorRect
var _material: ShaderMaterial
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil = ColorRect.new()
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = preload("res://assets/shaders/screen_vortex.gdshader")
	_veil.material = _material
	_veil.color = Color.WHITE
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", ScreenDesign.display_font())
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", ScreenDesign.GOLD)
	_label.add_theme_constant_override("outline_size", 6)
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.offset_left = -360
	_label.offset_right = 360
	_label.offset_top = 90
	_label.offset_bottom = 134


func play_cover(destination: String = "") -> void:
	_label.text = destination.to_upper()
	if AudioManager.reduced_motion:
		_material.set_shader_parameter("progress", 1.5)
		_veil.modulate.a = 0.0
		var fade := create_tween().set_parallel(true)
		fade.tween_property(_veil, "modulate:a", 1.0, 0.18)
		if not destination.is_empty(): fade.tween_property(_label, "modulate:a", 1.0, 0.12)
		await fade.finished
		return
	var motion := create_tween().set_parallel(true)
	motion.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	motion.tween_method(_set_progress, -0.10, 1.52, 0.48)
	motion.tween_method(_set_spin, 0.0, 4.8, 0.48)
	if not destination.is_empty():
		motion.tween_property(_label, "modulate:a", 1.0, 0.18).set_delay(0.24)
	await motion.finished


func play_reveal() -> void:
	var motion := create_tween().set_parallel(true)
	if AudioManager.reduced_motion:
		motion.tween_property(_veil, "modulate:a", 0.0, 0.20)
		motion.tween_property(_label, "modulate:a", 0.0, 0.10)
	else:
		motion.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		motion.tween_method(_set_progress, 1.52, -0.10, 0.40)
		motion.tween_method(_set_spin, 4.8, 8.2, 0.40)
		motion.tween_property(_label, "modulate:a", 0.0, 0.12)
	await motion.finished
	queue_free()


func _set_progress(value: float) -> void:
	_material.set_shader_parameter("progress", value)


func _set_spin(value: float) -> void:
	_material.set_shader_parameter("spin", value)
