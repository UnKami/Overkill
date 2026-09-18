extends PanelContainer
## Floating decision surface; the arena always keeps its full height.
var choices: VBoxContainer
var replacements: VBoxContainer
var arrival: Tween

func install(battle: CombatController) -> void:
	name = "RelicChoiceOverlay"
	z_index = 30
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("101921")
	style.border_color = Color("8d7654")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_size = 20
	style.shadow_color = Color(0, 0, 0, 0.5)
	for edge: String in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + edge, 18.0)
	add_theme_stylebox_override("panel", style)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	add_child(choices)
	battle._phase_label.reparent(choices)
	battle._phase_label.custom_minimum_size = Vector2(390, 96)
	battle._phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle._phase_label.add_theme_font_size_override("font_size", 18)
	battle._pedestal_row.reparent(choices)
	battle._pedestal_row.add_theme_constant_override("separation", 12)
	replacements = VBoxContainer.new()
	replacements.add_theme_constant_override("separation", 8)
	choices.add_child(replacements)
	battle._skip_button.reparent(choices)
	battle._skip_button.add_theme_font_size_override("font_size", 20)
	_style_button(battle._skip_button)
	battle.get_node("BottomDock").hide()
	battle.get_node("CombatArena").offset_bottom = -24
	hide()

func present(battle: CombatController) -> void:
	for child: Node in replacements.get_children():
		replacements.remove_child(child)
		child.queue_free()
	if battle.phase == CombatController.Phase.QUADRANT:
		for hour: int in ChronometerView.get_quadrant_hours(battle.active_quadrant):
			var socket: ClockSocketView = battle._player_chrono.get_socket_view(hour)
			var button: Button = Button.new()
			var relic: ClockRelicData = socket.data.slotted_relic
			button.text = "%d O'CLOCK · %s" % [hour, relic.name if relic != null else "Empty"]
			button.tooltip_text = relic.description if relic != null else "Empty socket"
			button.custom_minimum_size = Vector2(390, 44)
			button.add_theme_font_size_override("font_size", 20)
			_style_button(button)
			button.disabled = socket.data.is_locked or battle.current_drawn_relic == null
			button.pressed.connect(battle._on_player_socket_pressed.bind(hour, socket))
			button.mouse_entered.connect(battle._preview_swap.bind(socket))
			button.focus_entered.connect(battle._preview_swap.bind(socket))
			button.mouse_exited.connect(battle._refresh_guidance)
			button.focus_exited.connect(battle._refresh_guidance)
			replacements.add_child(button)
	show()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	size = Vector2(426, 0)
	reset_size()
	position = (battle.size - size) * 0.5 + Vector2(0, 45)
	if arrival != null and arrival.is_valid(): arrival.kill()
	modulate.a = 0.0
	arrival = create_tween()
	arrival.tween_property(self, "modulate:a", 1.0, 0.12 if AudioManager.reduced_motion else 0.25)

func _style_button(button: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("17232c") if state in ["normal", "disabled"] else Color("30414a")
		style.border_color = Color("8d7654") if state == "normal" else Color("ebc68a")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state, style)
