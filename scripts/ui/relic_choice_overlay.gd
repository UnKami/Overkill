extends PanelContainer
## Floating decisions share a fixed footprint and never resize the arena.
var choices: VBoxContainer
var replacements: HBoxContainer
var arrival: Tween
var _battle: CombatController
var _heading: Label
var _body: HBoxContainer
var _footer: HBoxContainer
var _inspect: Button
var _resume: Button
var _inspecting: bool = false
var _pulse_time: float = 0.0

func install(battle: CombatController) -> void:
	_battle = battle
	name = "RelicChoiceOverlay"
	z_index = 30
	theme = ScreenDesign.build_theme()
	var style: StyleBoxEmpty = StyleBoxEmpty.new()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", style)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	add_child(choices)
	var header: HBoxContainer = HBoxContainer.new()
	choices.add_child(header)
	header.show()
	_heading = ScreenDesign.label(header, "BIND A RELIC", 24, ScreenDesign.GOLD, true)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspect = Button.new()
	_inspect.text = "INSPECT BATTLEFIELD  [I]"
	_inspect.add_theme_font_size_override("font_size", 22)
	header.add_child(_inspect)
	_inspect.pressed.connect(toggle_inspection)
	battle._phase_label.reparent(choices)
	battle._phase_label.custom_minimum_size = Vector2(1180, 110)
	battle._phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle._phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	battle._phase_label.add_theme_font_size_override("font_size", 24)
	battle._phase_label.add_theme_color_override("font_color", Color("e4e8e9"))
	battle._phase_label.add_theme_color_override("font_outline_color",Color("080d12"))
	battle._phase_label.add_theme_constant_override("outline_size",6)
	battle._phase_label.clip_text = false
	battle._phase_label.show()
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 20)
	choices.add_child(_body)
	battle._pedestal_row.reparent(_body)
	battle._pedestal_row.add_theme_constant_override("separation", 20)
	replacements = HBoxContainer.new()
	replacements.add_theme_constant_override("separation", 12)
	_body.add_child(replacements)
	choices.move_child(battle._phase_label, choices.get_child_count() - 1)
	_footer = HBoxContainer.new()
	_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_child(_footer)
	battle._skip_button.reparent(header)
	header.move_child(battle._skip_button,1)
	battle._skip_button.z_index = 31
	battle._skip_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	battle._skip_button.offset_left = -180
	battle._skip_button.offset_right = 180
	battle._skip_button.offset_top = -76
	battle._skip_button.offset_bottom = -28
	battle._skip_button.custom_minimum_size = Vector2(285, 48)
	battle._skip_button.add_theme_font_size_override("font_size", 24)
	battle.get_node("BottomDock").hide()
	battle.get_node("CombatArena").offset_bottom = -24
	for dial: Control in [battle._player_chrono, battle._enemy_chrono]:
		dial.anchor_top = 0.66
		dial.anchor_bottom = 0.66
	_resume = Button.new()
	_resume.text = "RETURN TO RELIC CHOICE  [I]"
	_resume.z_index = 31
	_resume.theme = theme
	battle.add_child(_resume)
	_resume.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_resume.offset_left = -230
	_resume.offset_right = 230
	_resume.offset_top = -80
	_resume.offset_bottom = -24
	_resume.pressed.connect(toggle_inspection)
	_resume.hide()
	battle.resized.connect(_place)
	visibility_changed.connect(_visibility_changed)
	hide()

func present(battle: CombatController) -> void:
	_inspecting = false
	_resume.hide()
	for child: Node in replacements.get_children():
		replacements.remove_child(child)
		child.queue_free()
	var quadrant: bool = battle.phase == CombatController.Phase.QUADRANT
	_heading.text = "REPLACE · SECTOR %d" % battle.active_quadrant if quadrant else "BIND A RELIC · HOUR %02d" % battle.turn_number
	_footer.hide()
	replacements.visible = quadrant
	if quadrant:
		for hour: int in ChronometerView.get_quadrant_hours(battle.active_quadrant):
			var socket: ClockSocketView = battle._player_chrono.get_socket_view(hour)
			var relic: ClockRelicData = socket.data.slotted_relic
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(250, 232)
			button.disabled = socket.data.is_locked or battle.current_drawn_relic == null
			button.tooltip_text = "%s\n%s\nReplace this relic and resolve the three-hour sweep." % [relic.name if relic else "Empty slot",ClockInventory.describe(relic) if relic else ""]
			replacements.add_child(button)
			var column: VBoxContainer = VBoxContainer.new()
			button.add_child(column)
			column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			column.offset_left = 10
			column.offset_right = -10
			column.offset_top = 10
			column.offset_bottom = -10
			column.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_theme_constant_override("separation", 2)
			ScreenDesign.label(column, ("LOCKED · %02d" if socket.data.is_locked else ("HOUR %02d" if battle.current_drawn_relic == null else "REPLACE · %02d")) % hour, 24, ScreenDesign.GOLD, true)
			var title: Label = ScreenDesign.label(column, relic.name if relic != null else "Empty slot", 24)
			title.autowrap_mode = TextServer.AUTOWRAP_OFF
			title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			title.clip_text = true
			var effect: Label = ScreenDesign.label(column, RelicPedestalView.summary(relic) if relic != null else "No relic bound.", 24, ScreenDesign.MUTED)
			effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			effect.clip_text = false
			effect.custom_minimum_size.y = 36
			effect.text = effect.text.replace("Lasts until absorbed or battle ends.", "")
			for label: Node in column.get_children(): label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.pressed.connect(battle._on_player_socket_pressed.bind(hour, socket))
			button.mouse_entered.connect(battle._preview_swap.bind(socket))
			button.focus_entered.connect(battle._preview_swap.bind(socket))
			button.mouse_exited.connect(battle._refresh_guidance)
			button.focus_exited.connect(battle._refresh_guidance)
	ScreenDesign.apply_text_size(self)
	show()
	_place()
	call_deferred("_place")
	if arrival != null and arrival.is_valid(): arrival.kill()
	modulate.a = 0.0
	arrival = create_tween()
	arrival.tween_property(self, "modulate:a", 1.0, 0.1 if AudioManager.reduced_motion else 0.22)

func _place() -> void:
	if not is_instance_valid(_battle): return
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(1180, 0)
	reset_size()
	position = Vector2((_battle.size.x - size.x) * 0.5, 70)

func toggle_inspection() -> void:
	if _battle._resolving or _battle._combat_over: return
	_inspecting = not _inspecting
	visible = not _inspecting
	_resume.visible = _inspecting
	if not _inspecting: _place()

func _visibility_changed() -> void:
	if not visible and not _inspecting: _resume.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if (visible or _inspecting) and not _battle._resolving and not _battle._combat_over:
			toggle_inspection()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if visible and not _battle._resolving:
		if not AudioManager.reduced_motion: _pulse_time += delta
		for button: Button in replacements.get_children():
			button.modulate = Color.WHITE if button.disabled or AudioManager.reduced_motion else Color(1, 1, 1, 0.86 + 0.14 * sin(_pulse_time * 3.0))
	if _inspecting and (_battle._resolving or _battle._combat_over):
		_inspecting = false
		_resume.hide()

func _style_button(button: Button) -> void:
	button.theme = ScreenDesign.build_theme()
