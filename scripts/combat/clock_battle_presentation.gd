extends RefCounted
## Composition and transient presentation only; combat owns all gameplay state.

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
	for entry in [["PlayerPortrait", -120.0], ["EnemyPortrait", 120.0]]:
		var portrait: TextureRect = nexus.get_node(entry[0])
		portrait.offset_left = entry[1] - 100
		portrait.offset_right = entry[1] + 100
		portrait.offset_top = -60
		portrait.offset_bottom = 180
		portrait.pivot_offset = Vector2(100, 120)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var fade := create_fade(battle)
	var entrance := battle.create_tween()
	entrance.tween_property(fade, "color:a", 0.0, 0.65)
	entrance.tween_callback(fade.queue_free)

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
	for entry in [["PlayerChronometer", 0.14], ["EnemyChronometer", 0.86]]:
		var clock: Control = arena.get_node(entry[0])
		clock.anchor_left = entry[1]
		clock.anchor_right = entry[1]
		clock.offset_left = -210
		clock.offset_right = 210
		clock.offset_top = -210
		clock.offset_bottom = 210
		clock.pivot_offset = Vector2(210,210)
	var nexus: Control = arena.get_node("ClashNexus")
	for entry in [["PlayerPortrait", -180.0], ["EnemyPortrait", 180.0]]:
		var portrait: Control = nexus.get_node(entry[0])
		portrait.offset_left = entry[1] - 105
		portrait.offset_right = entry[1] + 105
		portrait.offset_top = -100
		portrait.offset_bottom = 260
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
	phase.add_theme_font_size_override("font_size",26)
	var skip: Button = dock.get_node("SkipButton")
	skip.offset_left = -480
	skip.offset_right = -40
	skip.add_theme_font_size_override("font_size",22)
	for path in ["PlayerPortrait/PlayerStatsLabel","EnemyPortrait/EnemyStatsLabel"]:
		nexus.get_node(path).add_theme_font_size_override("font_size",24)

	# Keep the clocks and telemetry above the temporary decision panel.
	for pair: Array in [["PlayerChronometer", "PlayerPortrait", "PlayerStatsLabel"], ["EnemyChronometer", "EnemyPortrait", "EnemyStatsLabel"]]:
		var dial: Control = arena.get_node(pair[0])
		dial.anchor_top = 0.30
		dial.anchor_bottom = 0.30
		var portrait: Control = nexus.get_node(pair[1])
		var stats: Label = portrait.get_node(pair[2])
		stats.reparent(dial)
		stats.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		stats.grow_vertical = Control.GROW_DIRECTION_END
		stats.position = Vector2(0,450)
		stats.size = Vector2(420,100)
		stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats.add_theme_font_size_override("font_size", 26)
		stats.add_theme_color_override("font_color", Color("e5e4df"))
		stats.add_theme_constant_override("outline_size", 4)
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var health: ProgressBar = portrait.get_node("Vitality")
		health.reparent(dial)
		health.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		health.offset_left = 40
		health.offset_right = -40
		health.offset_top = 14
		health.offset_bottom = 24
		stats.tooltip_text = "Block persists until absorbed or the battle ends."

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
	tween.tween_method(func(progress: float) -> void: line.set_point_position(1, start.lerp(finish, progress)), 0.0, 1.0, 0.16 / AudioManager.animation_speed_scale())
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)
