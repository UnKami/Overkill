extends RefCounted
## Composition and transient presentation only; combat owns all gameplay state.
## Wires SmartHoverInspector to Player/Enemy status bars and Reserve Draw/Discard HUD badges.

class BattleHudTracker extends Control:
	var battle: CombatController
	var draw_badge: Button
	var discard_badge: Button
	var _last_draw_count: int = -1
	var _last_discard_count: int = -1

	func setup(target_battle: CombatController) -> void:
		battle = target_battle
		name = "BattleHudTracker"
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 38

		draw_badge = _create_pile_badge("⬡ DRAW PILE · 0", ScreenDesign.CYAN, false)
		add_child(draw_badge)
		draw_badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		draw_badge.offset_left = 28.0
		draw_badge.offset_right = 244.0
		draw_badge.offset_top = -54.0
		draw_badge.offset_bottom = -14.0
		draw_badge.mouse_entered.connect(_on_draw_hover_entered)
		draw_badge.focus_entered.connect(_on_draw_hover_entered)
		draw_badge.mouse_exited.connect(func() -> void: SmartHoverInspector.hide_inspector(draw_badge))
		draw_badge.focus_exited.connect(func() -> void: SmartHoverInspector.hide_inspector(draw_badge))

		discard_badge = _create_pile_badge("⬡ DISCARD · 0", ScreenDesign.GOLD, true)
		add_child(discard_badge)
		discard_badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		discard_badge.offset_left = -244.0
		discard_badge.offset_right = -28.0
		discard_badge.offset_top = -54.0
		discard_badge.offset_bottom = -14.0
		discard_badge.mouse_entered.connect(_on_discard_hover_entered)
		discard_badge.focus_entered.connect(_on_discard_hover_entered)
		discard_badge.mouse_exited.connect(func() -> void: SmartHoverInspector.hide_inspector(discard_badge))
		discard_badge.focus_exited.connect(func() -> void: SmartHoverInspector.hide_inspector(discard_badge))

	func _create_pile_badge(label_text: String, accent: Color, align_right: bool) -> Button:
		var btn := Button.new()
		btn.text = label_text
		btn.tooltip_text = ""
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", ScreenDesign.TEXT)
		btn.add_theme_color_override("font_hover_color", accent.lightened(0.28))
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var st := StyleBoxFlat.new()
			st.bg_color = Color("08131de8") if state == "normal" else Color("122536f4")
			st.border_color = Color(accent, 0.55 if state == "normal" else 0.95)
			st.set_border_width_all(1)
			if align_right:
				st.border_width_right = 3
			else:
				st.border_width_left = 3
			st.set_corner_radius_all(5)
			st.content_margin_left = 12
			st.content_margin_right = 12
			st.content_margin_top = 5
			st.content_margin_bottom = 5
			btn.add_theme_stylebox_override(state, st)
		return btn

	func _on_draw_hover_entered() -> void:
		if not is_instance_valid(battle):
			return
		AudioManager.play_clock_sound("tick")
		SmartHoverInspector.inspect_pile(
			draw_badge,
			"RESERVE DRAW PILE",
			"UNBOUND RELICS READY TO DRAW (%d)" % battle.player_deck.size(),
			battle.player_deck,
			ScreenDesign.CYAN
		)

	func _on_discard_hover_entered() -> void:
		if not is_instance_valid(battle):
			return
		AudioManager.play_clock_sound("tick")
		SmartHoverInspector.inspect_pile(
			discard_badge,
			"DISCARD PILE",
			"DISPLACED & CYCLED RELICS (%d)" % battle.player_discard.size(),
			battle.player_discard,
			ScreenDesign.GOLD
		)

	func _process(_delta: float) -> void:
		if not is_instance_valid(battle):
			return
		var d_size: int = battle.player_deck.size()
		var c_size: int = battle.player_discard.size()
		if d_size != _last_draw_count:
			_last_draw_count = d_size
			draw_badge.text = "⬡ DRAW PILE · %d" % d_size
		if c_size != _last_discard_count:
			_last_discard_count = c_size
			discard_badge.text = "⬡ DISCARD · %d" % c_size


static func install(battle: Control) -> void:
	var background: TextureRect = battle.get_node("Background")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atmosphere := preload("res://scripts/combat/battle_atmosphere.gd").new()
	battle.add_child(atmosphere)
	battle.move_child(atmosphere, background.get_index() + 1)
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hud: Control = battle.get_node("HUD")
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.offset_bottom = 64
	var arena: Control = battle.get_node("CombatArena")
	arena.offset_top = 100
	arena.offset_bottom = -365
	for entry in [["PlayerChronometer", 0.23], ["EnemyChronometer", 0.77]]:
		var clock: Control = arena.get_node(entry[0])
		clock.anchor_left = entry[1]
		clock.anchor_right = entry[1]
		clock.offset_left = -250
		clock.offset_right = 250
		clock.offset_top = -250
		clock.offset_bottom = 250
		clock.pivot_offset = Vector2(250, 250)
		clock.get_node("TitleLabel").add_theme_font_size_override("font_size", 20)
	var nexus := arena.get_node("ClashNexus")
	for entry in [["PlayerPortrait", -120.0, false], ["EnemyPortrait", 120.0, true]]:
		var portrait: TextureRect = nexus.get_node(entry[0])
		var is_enemy: bool = bool(entry[2])
		portrait.offset_left = float(entry[1]) - 100.0
		portrait.offset_right = float(entry[1]) + 100.0
		portrait.offset_top = -60
		portrait.offset_bottom = 180
		portrait.pivot_offset = Vector2(100, 120)
		portrait.mouse_filter = Control.MOUSE_FILTER_PASS
		var status_panel := Panel.new()
		status_panel.name = "CharacterStatusPanel"
		status_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		status_panel.mouse_default_cursor_shape = Control.CURSOR_HELP
		portrait.add_child(status_panel)
		portrait.move_child(status_panel, 0)
		var status_style := StyleBoxFlat.new()
		status_style.bg_color = Color("08131de8")
		status_style.border_color = Color("65bfca") if entry[0] == "PlayerPortrait" else Color("c87861")
		status_style.border_width_top = 2
		status_style.set_corner_radius_all(5)
		status_panel.add_theme_stylebox_override("panel", status_style)
		status_panel.mouse_entered.connect(func() -> void: SmartHoverInspector.inspect_combatant(status_panel, battle, is_enemy))
		status_panel.mouse_exited.connect(func() -> void: SmartHoverInspector.hide_inspector(status_panel))
		portrait.mouse_entered.connect(func() -> void: SmartHoverInspector.inspect_combatant(status_panel, battle, is_enemy))
		portrait.mouse_exited.connect(func() -> void: SmartHoverInspector.hide_inspector(status_panel))
		var health := ProgressBar.new()
		health.name = "Vitality"
		health.show_percentage = false
		health.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(health)
		health.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		health.offset_top = 5
		health.offset_bottom = 10
		var track := StyleBoxFlat.new()
		track.bg_color = Color("111a20")
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("7bcbd0") if entry[0] == "PlayerPortrait" else Color("db8b6e")
		health.add_theme_stylebox_override("background", track)
		health.add_theme_stylebox_override("fill", fill)
	var sigil: TextureRect = nexus.get_node("NexusSigil")
	sigil.offset_left = -92
	sigil.offset_right = 92
	sigil.offset_top = -185
	sigil.offset_bottom = -1
	var mask := ShaderMaterial.new()
	mask.shader = preload("res://assets/ui/combat/circular_art.gdshader")
	sigil.material = mask
	var nexus_title: Label = nexus.get_node("NexusTitle")
	nexus_title.text = "THE CLASH"
	nexus_title.offset_top = -224
	nexus_title.offset_bottom = -194
	nexus_title.add_theme_font_size_override("font_size", 20)
	for path in ["PlayerPortrait/PlayerStatsLabel", "EnemyPortrait/EnemyStatsLabel"]:
		var label: Label = nexus.get_node(path)
		label.offset_left = -114
		label.offset_right = 114
		label.offset_top = 12
		label.offset_bottom = 72
		label.add_theme_font_size_override("font_size", 18)
	var dock: Control = battle.get_node("BottomDock")
	dock.offset_top = -355
	dock.offset_bottom = -12
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.06, 0.9)
	style.border_color = Color(0.67, 0.53, 0.31, 0.5)
	style.border_width_top = 1
	dock.get_node("DockBackdrop").add_theme_stylebox_override("panel", style)
	var phase_label: Label = dock.get_node("PhaseLabel")
	phase_label.offset_top = 12
	phase_label.offset_bottom = 42
	phase_label.offset_left = -650
	phase_label.offset_right = 650
	phase_label.add_theme_font_size_override("font_size", 19)
	var row: Control = dock.get_node("PedestalRow")
	row.anchor_top = 0
	row.anchor_bottom = 0
	row.offset_top = 54
	row.offset_bottom = 344
	row.offset_left = -414
	row.offset_right = 414
	var title := Label.new()
	title.text = "O V E R K I L L"
	title.position = Vector2(28, 15)
	title.add_theme_color_override("font_color", Color("d7bc8c"))
	title.add_theme_font_size_override("font_size", 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "D U A L   C H R O N O M E T E R"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.add_theme_color_override("font_color", Color("91a5ac"))
	subtitle.add_theme_font_size_override("font_size", 14)
	battle.add_child(subtitle)
	subtitle.hide()
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	subtitle.offset_left = -380
	subtitle.offset_right = -28
	subtitle.offset_top = 23

	if battle is CombatController:
		var tracker := BattleHudTracker.new()
		battle.add_child(tracker)
		tracker.setup(battle as CombatController)


static func create_fade(battle: Control) -> ColorRect:
	var fade := ColorRect.new()
	fade.color = Color(0.015, 0.02, 0.03, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.z_index = 90
	battle.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return fade


static func directed_layout(battle: Control) -> void:
	var arena: Control = battle.get_node("CombatArena")
	arena.offset_bottom = -290
	for entry in [["PlayerChronometer", 0.11], ["EnemyChronometer", 0.89]]:
		var clock: Control = arena.get_node(entry[0])
		clock.anchor_left = entry[1]
		clock.anchor_right = entry[1]
		clock.offset_left = -210
		clock.offset_right = 210
		clock.offset_top = -210
		clock.offset_bottom = 210
		clock.pivot_offset = Vector2(210, 210)
	var nexus: Control = arena.get_node("ClashNexus")
	for entry in [["PlayerPortrait", -265.0], ["EnemyPortrait", 265.0]]:
		var portrait: Control = nexus.get_node(entry[0])
		portrait.offset_left = entry[1] - 156
		portrait.offset_right = entry[1] + 156
		portrait.offset_top = -190
		portrait.offset_bottom = 254
		portrait.pivot_offset = Vector2(156, 222)
	var dock: Control = battle.get_node("BottomDock")
	dock.offset_top = -290
	var row: Control = dock.get_node("PedestalRow")
	row.offset_left = -609
	row.offset_right = 609
	row.offset_top = 90
	row.offset_bottom = 280
	var phase: Label = dock.get_node("PhaseLabel")
	phase.offset_left = -900
	phase.offset_right = 900
	phase.offset_top = 6
	phase.offset_bottom = 80
	phase.add_theme_font_size_override("font_size", 26)
	var skip: Button = dock.get_node("SkipButton")
	skip.offset_left = -480
	skip.offset_right = -40
	skip.add_theme_font_size_override("font_size", 22)
	for path in ["PlayerPortrait/PlayerStatsLabel", "EnemyPortrait/EnemyStatsLabel"]:
		nexus.get_node(path).add_theme_font_size_override("font_size", 24)

	# Combat telemetry belongs to the combatant, never to the clock. The dial
	# is reserved for relic placement and intent; each character carries its
	# own vitality, Block and status readout directly underneath its body.
	for pair: Array in [["PlayerChronometer", "PlayerPortrait", "PlayerStatsLabel"], ["EnemyChronometer", "EnemyPortrait", "EnemyStatsLabel"]]:
		var dial: Control = arena.get_node(pair[0])
		dial.anchor_top = 0.30
		dial.anchor_bottom = 0.30
		var portrait: Control = nexus.get_node(pair[1])
		var stats: Label = portrait.get_node(pair[2])
		stats.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		stats.offset_left = 12
		stats.offset_right = -12
		stats.offset_top = 360
		stats.offset_bottom = 426
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats.add_theme_font_size_override("font_size", 22)
		stats.add_theme_color_override("font_color", Color("e5e4df"))
		stats.add_theme_constant_override("outline_size", 4)
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var health: ProgressBar = portrait.get_node("Vitality")
		health.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		health.offset_left = 16
		health.offset_right = -16
		health.offset_top = 631
		health.offset_bottom = 647
		var status_panel: Panel = portrait.get_node("CharacterStatusPanel")
		status_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		status_panel.offset_left = 0
		status_panel.offset_right = 0
		status_panel.offset_top = 555
		status_panel.offset_bottom = 649
		stats.tooltip_text = ""


static func relay(battle: Control, source: Control, target: Control, accent: Color) -> void:
	var line := Line2D.new()
	line.z_index = 40
	line.width = 3.0
	line.default_color = accent
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var start := source.global_position + source.size * 0.5 - battle.global_position
	var finish := target.global_position + target.size * 0.5 - battle.global_position
	line.points = PackedVector2Array([start, start])
	battle.add_child(line)
	var tween := line.create_tween()
	tween.set_speed_scale(AudioManager.combat_animation_speed_scale())
	tween.tween_method(func(progress: float) -> void: line.set_point_position(1, start.lerp(finish, progress)), 0.0, 1.0, 0.16)
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)
