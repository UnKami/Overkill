extends PanelContainer
## Floating decisions share a compact footprint so both chronometers, enemy intents,
## and battlefield actors remain clearly readable at all times.

var choices: VBoxContainer
var replacements: HBoxContainer
var arrival: Tween
var _battle: CombatController
var _heading: Label
var _body: HBoxContainer
var _footer: HBoxContainer
var _battlefield_inspection: BattlefieldInspection
var _inspecting: bool = false
var _pulse_time: float = 0.0
var _last_status_hash: int = 0


func install(battle: CombatController) -> void:
	_battle = battle
	name = "RelicChoiceOverlay"
	z_index = 30
	theme = ScreenDesign.build_theme()
	var style: StyleBoxEmpty = StyleBoxEmpty.new()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", style)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 6)
	choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(choices)
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices.add_child(header)
	header.show()
	_heading = ScreenDesign.label(header, "BIND A RELIC", 22, ScreenDesign.GOLD, true)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle._phase_label.reparent(choices)
	battle._phase_label.custom_minimum_size = Vector2(920, 42)
	battle._phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle._phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle._phase_label.add_theme_font_size_override("font_size", 17)
	battle._phase_label.add_theme_color_override("font_color", Color("e4e8e9"))
	battle._phase_label.add_theme_color_override("font_outline_color", Color("080d12"))
	battle._phase_label.add_theme_constant_override("outline_size", 6)
	battle._phase_label.clip_text = false
	battle._phase_label.show()
	_body = HBoxContainer.new()
	_body.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_theme_constant_override("separation", 10)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices.add_child(_body)
	battle._pedestal_row.reparent(_body)
	battle._pedestal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	battle._pedestal_row.add_theme_constant_override("separation", 10)
	replacements = HBoxContainer.new()
	replacements.alignment = BoxContainer.ALIGNMENT_CENTER
	replacements.add_theme_constant_override("separation", 10)
	replacements.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(replacements)
	choices.move_child(battle._phase_label, choices.get_child_count() - 1)
	_footer = HBoxContainer.new()
	_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices.add_child(_footer)
	_footer.hide()
	battle._skip_button.reparent(header)
	header.move_child(battle._skip_button, 1)
	battle._skip_button.z_index = 31
	battle._skip_button.custom_minimum_size = Vector2(440, 46)
	battle._skip_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	battle._skip_button.add_theme_font_size_override("font_size", 16)
	battle._skip_button.add_theme_stylebox_override("normal", ScreenDesign.box(Color("5a3020f2"), Color("f0bd69"), 2))
	battle._skip_button.add_theme_stylebox_override("hover", ScreenDesign.box(Color("75402af5"), Color("ffe0a1"), 2))
	ScreenDesign.add_actionable_fx(battle._skip_button, Color("f0bd69"), true)
	battle.get_node("BottomDock").hide()
	battle.get_node("CombatArena").offset_bottom = -24
	for dial: Control in [battle._player_chrono, battle._enemy_chrono]:
		dial.anchor_top = 0.62
		dial.anchor_bottom = 0.62
	_battlefield_inspection = BattlefieldInspection.new()
	battle.add_child(_battlefield_inspection)
	_battlefield_inspection.install(battle)
	_battlefield_inspection.close_requested.connect(_close_inspection)
	battle._player_chrono.socket_pressed.connect(_on_assembly_socket_pressed)
	battle.resized.connect(_place)
	hide()


func present(battle: CombatController) -> void:
	_inspecting = false
	_battlefield_inspection.close()
	SmartHoverInspector.hide_inspector()
	for child: Node in replacements.get_children():
		replacements.remove_child(child)
		child.queue_free()
	var quadrant: bool = battle.phase == CombatController.Phase.QUADRANT
	var target_hour: int = SmartHoverInspector._resolve_default_target_hour(battle)
	var active_sector: int = battle.active_quadrant if quadrant else (((maxi(1, target_hour) - 1) / 3) + 1)
	_heading.text = "REPLACE OR KEEP · SECTOR %d" % battle.active_quadrant if quadrant else "BIND A RELIC · SECTOR %d (HOUR %02d)" % [active_sector, target_hour]
	_footer.hide()
	replacements.visible = quadrant

	# Refresh live numbers on both clocks and all active pedestals
	battle._player_chrono.refresh_live_values(battle)
	battle._enemy_chrono.refresh_live_values(battle)
	if not quadrant:
		battle._player_chrono.set_interactive_assembly_sector(active_sector, target_hour, true)
	for ped_node: Node in battle._pedestal_row.get_children():
		if ped_node is RelicPedestalView:
			(ped_node as RelicPedestalView).refresh_live_combat_preview(battle, target_hour)

	if quadrant:
		for hour: int in ChronometerView.get_quadrant_hours(battle.active_quadrant):
			var socket: ClockSocketView = battle._player_chrono.get_socket_view(hour)
			var relic: ClockRelicData = socket.data.slotted_relic
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(204, 256)
			button.disabled = socket.data.is_locked or battle.current_drawn_relic == null
			button.tooltip_text = ""
			replacements.add_child(button)
			var relic_color: Color = relic.primary_color() if relic != null else ScreenDesign.GOLD
			for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
				var replacement_style := StyleBoxFlat.new()
				replacement_style.bg_color = Color(0, 0, 0, 0) if state == "normal" else Color("18293699")
				replacement_style.border_color = Color(0, 0, 0, 0)
				replacement_style.set_border_width_all(0)
				replacement_style.set_corner_radius_all(0)
				replacement_style.shadow_color = Color(0, 0, 0, 0)
				replacement_style.shadow_size = 0
				button.add_theme_stylebox_override(state, replacement_style)
			var column: VBoxContainer = VBoxContainer.new()
			button.add_child(column)
			column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			column.offset_left = 8
			column.offset_right = -8
			column.offset_top = 10
			column.offset_bottom = -8
			column.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_theme_constant_override("separation", 2)
			var finisher_tag: String = " ★" if hour in [3, 6, 9] else ""
			var header_str: String = ("LOCKED · %02d" if socket.data.is_locked else ("HOUR %02d" if battle.current_drawn_relic == null else "REPLACE · %02d")) % hour + finisher_tag
			ScreenDesign.label(column, header_str, 18, relic_color, true)
			var title: Label = ScreenDesign.label(column, relic.name if relic != null else "Empty slot", 21, ScreenDesign.TEXT, true)
			title.autowrap_mode = TextServer.AUTOWRAP_OFF
			title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			title.clip_text = true
			var art := TextureRect.new()
			art.custom_minimum_size.y = 136
			art.texture = RelicArt.load_texture(relic.art_id) if relic != null else null
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(art)
			var sunburst := TextureRect.new()
			sunburst.name = "EssenceSunburst"
			sunburst.texture = load(RelicPedestalView.essence_sunburst_path(relic)) as Texture2D if relic != null else null
			sunburst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sunburst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sunburst.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sunburst.modulate.a = 0.34
			sunburst.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sunburst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			button.add_child(sunburst)
			button.move_child(sunburst, 0)
			art.z_index = 1
			column.z_index = 2
			var effect: Label = ScreenDesign.label(column, RelicPedestalView.summary(relic) if relic != null else "No relic bound.", 15, ScreenDesign.TEXT)
			effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			effect.clip_text = false
			effect.custom_minimum_size.y = 32
			effect.text = effect.text.replace("Lasts until absorbed or battle ends.", "")
			for label: Node in column.get_children():
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ScreenDesign.add_actionable_fx(button, relic_color, false)
			button.pressed.connect(battle._on_player_socket_pressed.bind(hour, socket))
			button.mouse_entered.connect(_on_replacement_hover_entered.bind(button, socket))
			button.focus_entered.connect(_on_replacement_hover_entered.bind(button, socket))
			button.mouse_exited.connect(_on_replacement_hover_exited.bind(button))
			button.focus_exited.connect(_on_replacement_hover_exited.bind(button))
	ScreenDesign.apply_text_size(self)
	show()
	_place()
	call_deferred("_place")
	if arrival != null and arrival.is_valid():
		arrival.kill()
	modulate.a = 0.0
	arrival = create_tween()
	arrival.tween_property(self, "modulate:a", 1.0, 0.1 if AudioManager.reduced_motion else 0.22)


func _on_replacement_hover_entered(button: Button, socket: ClockSocketView) -> void:
	if is_instance_valid(_battle):
		_battle._preview_swap(socket)
		if _battle.current_drawn_relic != null and not socket.data.is_locked:
			SmartHoverInspector.inspect_relic(
				button,
				_battle.current_drawn_relic,
				_battle,
				socket.data.hour_index,
				"HOT-SWAP HOUR %02d  ·  REPLACES %s" % [socket.data.hour_index, socket.data.slotted_relic.name.to_upper() if socket.data.slotted_relic != null else "EMPTY"]
			)
		else:
			SmartHoverInspector.inspect_socket(socket, _battle)


func _on_replacement_hover_exited(button: Button) -> void:
	SmartHoverInspector.hide_inspector(button)
	if is_instance_valid(_battle):
		_battle._refresh_guidance()


func _on_assembly_socket_pressed(hour_index: int, socket_view: ClockSocketView) -> void:
	if not is_instance_valid(_battle) or _battle._resolving or _battle._combat_over:
		return
	if _battle.phase != CombatController.Phase.ASSEMBLY:
		return
	if socket_view == null or socket_view.data == null or socket_view.data.is_locked or socket_view.data.slotted_relic != null:
		return
	var current_target: int = SmartHoverInspector._resolve_default_target_hour(_battle)
	var sector_idx: int = ((maxi(1, current_target) - 1) / 3) + 1
	var sector_hours: Array[int] = ChronometerView.get_quadrant_hours(sector_idx)
	if not sector_hours.has(hour_index):
		return
	AudioManager.play_clock_sound("tick")
	if _battle.get("selected_assembly_hour") != null:
		_battle.set("selected_assembly_hour", hour_index)
	elif _battle.get("_selected_assembly_hour") != null:
		_battle.set("_selected_assembly_hour", hour_index)
	_heading.text = "BIND A RELIC · SECTOR %d (HOUR %02d)" % [sector_idx, hour_index]
	_battle._player_chrono.set_interactive_assembly_sector(sector_idx, hour_index, true)
	_battle._player_chrono.mark_hour(hour_index)
	var enemy_h: int = EnemyClockPattern.hour_for(hour_index, _battle._active_enemy())
	_battle._enemy_chrono.mark_hour(enemy_h)
	_battle._reveal_enemy_hour(enemy_h)
	for ped_node: Node in _battle._pedestal_row.get_children():
		if ped_node is RelicPedestalView:
			var ped: RelicPedestalView = ped_node as RelicPedestalView
			ped._slot_button.text = "BIND TO %d O'CLOCK" % hour_index
			ped.refresh_live_combat_preview(_battle, hour_index)


func _place() -> void:
	if not is_instance_valid(_battle):
		return
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	size = Vector2(minf(1140.0, _battle.size.x - 64.0), 0)
	reset_size()
	position = Vector2((_battle.size.x - size.x) * 0.5, 14)


func toggle_inspection() -> void:
	if _battle._resolving or _battle._combat_over:
		return
	SmartHoverInspector.hide_inspector()
	_inspecting = not _inspecting
	visible = not _inspecting
	if _inspecting:
		_battlefield_inspection.open()
	else:
		_battlefield_inspection.close()
		_place()


func _close_inspection() -> void:
	if not _inspecting:
		return
	_inspecting = false
	_battlefield_inspection.close()
	show()
	_place()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if (visible or _inspecting) and not _battle._resolving and not _battle._combat_over:
			toggle_inspection()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_instance_valid(_battle):
		var cur_hash: int = (
			_battle.player_strength * 31
			+ _battle.player_block * 17
			+ _battle.player_weak * 13
			+ _battle.player_vulnerable * 7
			+ _battle.player_thorns * 5
			+ _battle.enemy_strength * 23
			+ _battle.enemy_weak * 19
			+ _battle.enemy_vulnerable * 11
			+ _battle.enemy_bleed * 3
			+ _battle.player_next_attack_multiplier * 41
			+ _battle.player_next_hit_bonus * 43
		)
		if cur_hash != _last_status_hash:
			_last_status_hash = cur_hash
			_battle._player_chrono.refresh_live_values(_battle)
			_battle._enemy_chrono.refresh_live_values(_battle)
	if visible and not _battle._resolving:
		if not AudioManager.reduced_motion:
			_pulse_time += delta
		for button: Button in replacements.get_children():
			button.modulate = Color.WHITE if button.disabled or AudioManager.reduced_motion else Color(1, 1, 1, 0.86 + 0.14 * sin(_pulse_time * 3.0))
	if _inspecting and (_battle._resolving or _battle._combat_over):
		_inspecting = false
		_battlefield_inspection.close()


func _style_button(button: Button) -> void:
	button.theme = ScreenDesign.build_theme()
