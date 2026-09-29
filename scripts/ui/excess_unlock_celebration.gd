extends Control
## Excess-tier unlock celebration (turn-presentation/tutorial doc Part 3):
## top of the attention hierarchy, dismiss on tap/input with no fixed
## auto-timer, fires every time a new threshold is crossed - never muted for
## repeat players. GameFlow instantiates this directly into its overlay
## layer whenever OKRunState.excess_threshold_crossed fires.

@onready var _message_label: Label = %MessageLabel

var _threshold: int = 0


func set_threshold(threshold: int) -> void:
	_threshold = threshold


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var background: ColorRect = get_node("Background")
	# Preserve the battle beneath the milestone so the reveal feels like a
	# rupture inside combat, not a disconnected blank notification screen.
	background.color = Color("120509df")
	var blood_glow := TextureRect.new()
	blood_glow.name = "BloodGlow"
	blood_glow.texture = AmbientMotion._get_glow_texture()
	blood_glow.modulate = Color("d21f3c38")
	blood_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blood_glow.stretch_mode = TextureRect.STRETCH_SCALE
	blood_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blood_glow)
	move_child(blood_glow, background.get_index() + 1)
	blood_glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	blood_glow.position = Vector2(-520, -360)
	blood_glow.size = Vector2(1040, 720)
	AmbientMotion.pulse_alpha(blood_glow, 0.62, 1.0, 2.4)
	var panel: PanelContainer = get_node("CenterContainer/Panel")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("10060bfa")
	panel_style.border_color = Color("d21f3caa")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000e8")
	panel_style.shadow_size = 40
	panel_style.shadow_offset = Vector2(0, 14)
	panel.add_theme_stylebox_override("panel", panel_style)
	_message_label.text = "EXCESS AWAKENED\n%d+ OVERKILL — SINGLE BLOW\nBlood-bound cards have entered the clock." % _threshold
	_message_label.add_theme_font_override("font", ScreenDesign.display_font())
	_message_label.add_theme_font_size_override("font_size", 38)
	_message_label.add_theme_color_override("font_color", Color("e34b55"))
	_message_label.add_theme_color_override("font_outline_color", Color("180306"))
	_message_label.add_theme_constant_override("outline_size", 5)
	var kicker := ScreenDesign.label(self, "THE CLOCK HAS TASTED EXCESS", 16, Color("f0c79c"))
	kicker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	kicker.position += Vector2(-220, -126)
	kicker.size = Vector2(440, 30)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for offset_y: float in [-82.0, 112.0]:
		var rule := ColorRect.new()
		rule.color = Color("d21f3c99")
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rule.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		rule.position += Vector2(-260, offset_y)
		rule.size = Vector2(520, 2)
		add_child(rule)
	var hint := ScreenDesign.label(self, "CLICK OR PRESS ANY KEY TO RETURN TO BATTLE", 14, Color("c9a9a9"))
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint.position += Vector2(-260, 158)
	hint.size = Vector2(520, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Top of the attention hierarchy (doc) - this is the single punchiest
	# reveal in the game, bigger than the reward/run-summary punches.
	AmbientMotion.punch_scale(_message_label, 1.15, 0.45)
	AmbientMotion.spawn_embers(self, Color(0.95, 0.65, 0.15, 0.7), 16, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		queue_free()
