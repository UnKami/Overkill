class_name TutorialCalloutView extends Control
## The one display layer for TutorialCallout. Renders whatever the autoload
## requests, then fully disappears - never leaves a permanent element behind.
## overkill-tutorial-callout-system.md, Part 1 guardrails 2-4.

@onready var _panel: PanelContainer = %Panel
@onready var _label: Label = %MessageLabel
@onready var _icon: TextureRect = %Icon

var _dismiss_timer: SceneTreeTimer


func _ready() -> void:
	visible = false
	z_index = 70
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hbox: HBoxContainer = _label.get_parent()
	hbox.add_theme_constant_override("separation", 14)
	var kicker := Label.new()
	kicker.name = "SignalLabel"
	kicker.text = "CHRONOMETER SIGNAL"
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", ScreenDesign.GOLD)
	kicker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(kicker)
	hbox.move_child(kicker, 1)
	_icon.custom_minimum_size = Vector2(34, 34)
	_label.custom_minimum_size.x = 360
	_label.add_theme_font_size_override("font_size", 18)
	TutorialCallout.callout_requested.connect(_on_requested)


func _on_requested(callout_id: String, definition: Dictionary) -> void:
	_label.text = definition.get("text", "")
	_place_for(callout_id)

	var icon_path: String = "res://assets/icons/ui/%s.png" % definition.get("icon_id", "")
	_icon.texture = ResourceLoader.load(icon_path) if ResourceLoader.exists(icon_path) else null

	var style := StyleBoxFlat.new()
	style.bg_color = Color("091520f2")
	style.border_color = Color(definition.get("accent_color", "#ffffff"))
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color("000000c8")
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", style)

	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	var dismiss_seconds: float = definition.get("dismiss_seconds", -1.0)
	if dismiss_seconds > 0.0:
		_dismiss_timer = get_tree().create_timer(dismiss_seconds)
		_dismiss_timer.timeout.connect(_dismiss)


func _place_for(callout_id: String) -> void:
	# Keep tutorial signals clear of the live object they explain. Combat
	# signals use the open center lanes; progression signals sit at the edge of
	# the scene so the underlying choice remains visible.
	match callout_id:
		"first_ok":
			_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			_panel.offset_left = -310
			_panel.offset_right = 310
			_panel.offset_top = 76
			_panel.offset_bottom = 164
		"first_intent":
			_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			_panel.offset_left = -330
			_panel.offset_right = 330
			_panel.offset_top = -360
			_panel.offset_bottom = -264
		_:
			_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			_panel.offset_left = -690
			_panel.offset_right = -64
			_panel.offset_top = 92
			_panel.offset_bottom = 188


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed:
		_dismiss()


func dismiss_now() -> void:
	_dismiss()


func _dismiss() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: visible = false)
