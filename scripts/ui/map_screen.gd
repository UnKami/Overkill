extends Control
## The ascent map is the primary focus. Selecting a reachable waypoint enters
## its destination directly; the destination screen handles any next decision.

const TYPE_LABELS := {
	MapGenerator.NodeType.COMBAT: "Battle",
	MapGenerator.NodeType.ELITE: "Elite",
	MapGenerator.NodeType.REST: "Rest Site",
	MapGenerator.NodeType.SHOP: "Clockwright",
	MapGenerator.NodeType.EVENT: "Encounter",
	MapGenerator.NodeType.TREASURE: "Sealed Cache",
	MapGenerator.NodeType.BOSS: "Act Guardian",
}
const TYPE_ICON_PATHS := {
	MapGenerator.NodeType.COMBAT: "res://assets/icons/map/node_combat.png",
	MapGenerator.NodeType.ELITE: "res://assets/icons/map/node_elite.png",
	MapGenerator.NodeType.REST: "res://assets/icons/map/node_rest.png",
	MapGenerator.NodeType.SHOP: "res://assets/icons/map/node_shop.png",
	MapGenerator.NodeType.EVENT: "res://assets/icons/map/node_event.png",
	MapGenerator.NodeType.TREASURE: "res://assets/icons/map/node_treasure.png",
	MapGenerator.NodeType.BOSS: "res://assets/icons/map/node_boss.png",
}
const TYPE_COLORS := {
	MapGenerator.NodeType.COMBAT: Color("d8c7a6"),
	MapGenerator.NodeType.ELITE: Color("d18468"),
	MapGenerator.NodeType.REST: Color("82c5d0"),
	MapGenerator.NodeType.SHOP: Color("dfbd7c"),
	MapGenerator.NodeType.EVENT: Color("a99ac8"),
	MapGenerator.NodeType.TREASURE: Color("dfbd7c"),
	MapGenerator.NodeType.BOSS: Color("dfbd7c"),
}

const ROW_HEIGHT := 164.0
const TOP_MARGIN := 44.0
const BOTTOM_MARGIN := 64.0
const SIDE_MARGIN := 90.0
const NODE_SIZE := Vector2(80, 80)
const BOSS_NODE_SIZE := Vector2(104, 104)
const GLOW_SIZE_MULT := 1.9
const ICON_SIZE_MULT := 0.64
static var _icon_cache: Dictionary = {}

const PATH_COLOR_BRIGHT := Color(0.94, 0.62, 0.15, 0.9)
const CURRENT_MARKER_COLOR := Color("EF9F27")
const PATH_TEXTURE_PATH := "res://assets/ui/map/path_strip.png"
const PATH_LINE_WIDTH := 17.0


static func _centered_icon(path: String) -> Texture2D:
	if not _icon_cache.has(path):
		var source: Texture2D = load(path)
		var cropped := AtlasTexture.new()
		cropped.atlas = source
		# Center the visible silhouette, not the generator's transparent padding.
		cropped.region = Rect2(source.get_image().get_used_rect())
		_icon_cache[path] = cropped
	return _icon_cache[path]

@onready var _hud: CombatHUD = %HUD
@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _canvas: Control = %MapCanvas
@onready var _background: TextureRect = %Background

var _map_data: Dictionary = {}
var _positions: Dictionary = {}
var _reachable: Array[String] = []
var _buttons: Dictionary = {}
var _line_layer: Control = null
var _path_time: float = 0.0
var _hovered_node: String = ""
var _map_width: float = 900.0
var _route_hint: Label
var _header_stats: Label


func _ready() -> void:
	_hud.bind_run_state()
	_hud.hide()
	_load_background_art()
	_build_screen_ui()
	resized.connect(_layout_screen)
	_layout_screen()
	_rebuild_map()
	call_deferred("_scroll_to_bottom")


func _process(delta: float) -> void:
	if _line_layer == null:
		return
	_path_time += delta
	_line_layer.queue_redraw()


func _load_background_art() -> void:
	var path: String = CinematicArt.map_background(RunManager.act_number)
	_background.modulate = Color(0.82, 0.84, 0.86)
	if not path.is_empty() and ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		AmbientMotion.apply_cinematic_backdrop(self, _background, 50.0, 0.44)


func _build_screen_ui() -> void:
	var header := PanelContainer.new()
	header.name = "MapHeader"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 42.0
	header.offset_top = 20.0
	header.offset_right = -42.0
	header.offset_bottom = 88.0
	header.add_theme_stylebox_override("panel", _panel_style(Color("08121ddc"), Color("c9aa764c"), 1, 5))
	add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 16)
	header_margin.add_theme_constant_override("margin_right", 16)
	header_margin.add_theme_constant_override("margin_top", 7)
	header_margin.add_theme_constant_override("margin_bottom", 7)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 16)
	header_margin.add_child(header_row)

	var brand := ScreenDesign.label(header_row, "O V E R K I L L", 15, ScreenDesign.GOLD)
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.custom_minimum_size.x = 195.0
	var divider := ColorRect.new()
	divider.color = Color("c9aa7666")
	divider.custom_minimum_size = Vector2(1, 30)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(divider)
	var act_name: String = {1: "THE CRYPT BASTION", 2: "THE REFINERY", 3: "THE ABYSS"}.get(RunManager.act_number, "THE FINAL DESCENT")
	var act_label := ScreenDesign.label(header_row, "ACT %02d  ·  %s" % [RunManager.act_number, act_name], 20, ScreenDesign.TEXT)
	act_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	act_label.add_theme_font_override("font", ScreenDesign.display_font())
	var push := Control.new()
	push.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(push)
	_header_stats = ScreenDesign.label(header_row, "", 17, ScreenDesign.MUTED)
	_header_stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_stats.custom_minimum_size.x = 300.0
	_header_stats.text = "VITALITY %d/%d  ·  OVERKILL %d" % [RunManager.current_hp, RunManager.max_hp, OKRunState.current_ok]
	var relic_button := _header_button("RELICS", func() -> void: GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE))
	relic_button.custom_minimum_size = Vector2(110.0, 42.0)
	header_row.add_child(relic_button)
	var pause_button := _header_button("PAUSE", func() -> void: GameFlow.open_pause_menu())
	pause_button.custom_minimum_size = Vector2(96.0, 42.0)
	header_row.add_child(pause_button)

	_route_hint = ScreenDesign.label(self, "CHOOSE A LIT WAYSTONE  ·  SCROLL TO SURVEY THE ASCENT", 15, Color("d9d0bf"))
	_route_hint.anchor_left = 0.0
	_route_hint.anchor_right = 1.0
	_route_hint.anchor_top = 0.0
	_route_hint.anchor_bottom = 0.0
	_route_hint.offset_left = 42.0
	_route_hint.offset_right = -42.0
	_route_hint.offset_top = 100.0
	_route_hint.offset_bottom = 127.0
	_route_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_hint.add_theme_color_override("font_shadow_color", Color("071019dd"))
	_route_hint.add_theme_constant_override("shadow_offset_y", 2)
	_route_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var footer := ScreenDesign.label(self, "FOLLOW THE GOLD LINE  ·  ESC OPENS PAUSE", 13, Color("c7c4bc"))
	footer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(44.0, -31.0)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_screen() -> void:
	if not is_instance_valid(_scroll):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	_scroll.anchor_left = 0.07
	_scroll.anchor_right = 0.93
	_scroll.offset_left = 0.0
	_scroll.offset_right = 0.0
	_scroll.offset_top = 132.0
	_scroll.offset_bottom = -150.0
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if is_instance_valid(_route_hint):
		_route_hint.offset_left = 42.0
		_route_hint.offset_right = -42.0
	var width: float = clampf(viewport_size.x * 0.79, 740.0, 1420.0)
	if absf(width - _map_width) > 2.0:
		_map_width = width
		if not _map_data.is_empty():
			_rebuild_map()
func _header_button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size.y = 42.0
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", ScreenDesign.box(Color("101b26d9"), Color("c9aa7650"), 1))
	button.add_theme_stylebox_override("hover", ScreenDesign.box(Color("213440f0"), ScreenDesign.GOLD, 1))
	button.add_theme_stylebox_override("pressed", ScreenDesign.box(Color("30404df0"), ScreenDesign.GOLD, 1))
	button.pressed.connect(action)
	ScreenDesign.add_actionable_fx(button, ScreenDesign.GOLD, false)
	return button


func _panel_style(fill: Color, outline: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("00000088")
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = maxi(0, int(_canvas.custom_minimum_size.y - _scroll.size.y))


func _rebuild_map() -> void:
	for child in _canvas.get_children():
		child.queue_free()
	_buttons.clear()
	_positions.clear()

	_map_data = MapGenerator.generate(RunManager.seed_value, RunManager.act_number)
	var nodes: Dictionary = _map_data.nodes
	var rows: Array = _map_data.rows
	_reachable = _current_reachable_ids()
	var row_count: int = rows.size()
	var canvas_height: float = TOP_MARGIN + BOTTOM_MARGIN + (row_count - 1) * ROW_HEIGHT
	_canvas.custom_minimum_size = Vector2(_map_width, canvas_height)

	for row_index in row_count:
		var row_ids: Array = rows[row_index]
		var y: float = TOP_MARGIN + (row_count - 1 - row_index) * ROW_HEIGHT
		var count: int = row_ids.size()
		for col in count:
			var x: float = _map_width * 0.5 if count == 1 else SIDE_MARGIN + col * (_map_width - 2.0 * SIDE_MARGIN) / float(count - 1)
			_positions[row_ids[col]] = Vector2(x, y)

	var path_texture: Texture2D = null
	if ResourceLoader.exists(PATH_TEXTURE_PATH):
		path_texture = ResourceLoader.load(PATH_TEXTURE_PATH)
	for node_id in nodes:
		var node: MapGenerator.MapNode = nodes[node_id]
		for next_id in node.connections:
			var bright: bool = RunManager.current_node_id == node_id and _reachable.has(next_id)
			if not bright or path_texture == null:
				continue
			var live_line := Line2D.new()
			live_line.points = PackedVector2Array([_positions[node_id], _positions[next_id]])
			live_line.width = PATH_LINE_WIDTH
			live_line.texture = path_texture
			live_line.texture_mode = Line2D.LINE_TEXTURE_TILE
			live_line.z_index = -1
			_canvas.add_child(live_line)

	var line_layer := Control.new()
	line_layer.name = "LineLayer"
	line_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_layer.draw.connect(_draw_connectors.bind(line_layer))
	_canvas.add_child(line_layer)
	_line_layer = line_layer
	line_layer.queue_redraw()

	for node_id in nodes:
		var node: MapGenerator.MapNode = nodes[node_id]
		var is_current: bool = node.id == RunManager.current_node_id
		var is_reachable: bool = _reachable.has(node.id)
		var glow: TextureRect = null
		if is_current or is_reachable:
			var node_size: Vector2 = BOSS_NODE_SIZE if node.type == MapGenerator.NodeType.BOSS else NODE_SIZE
			var glow_color: Color = CURRENT_MARKER_COLOR if is_current else TYPE_COLORS.get(node.type, Color.WHITE)
			glow = _build_node_glow(_positions[node.id], node_size, glow_color)
			_canvas.add_child(glow)
		var button := _build_node_button(node, is_current, is_reachable)
		_canvas.add_child(button)
		_buttons[node_id] = button
		if is_current:
			var caption := Label.new()
			caption.text = "CURRENT POSITION"
			caption.position = _positions[node.id] + Vector2(-110.0, 42.0)
			caption.size = Vector2(220.0, 26.0)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			caption.add_theme_font_size_override("font_size", 13)
			caption.add_theme_color_override("font_color", ScreenDesign.GOLD)
			caption.add_theme_constant_override("outline_size", 4)
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_canvas.add_child(caption)
		if glow != null:
			AmbientMotion.pulse_alpha(glow, 0.38, 0.72, 1.8 if is_current else 1.4)

func _draw_connectors(line_layer: Control) -> void:
	var nodes: Dictionary = _map_data.nodes
	for node_id in nodes:
		var node: MapGenerator.MapNode = nodes[node_id]
		var from_pos: Vector2 = _positions[node_id]
		for next_id in node.connections:
			var to_pos: Vector2 = _positions[next_id]
			var bright: bool = RunManager.current_node_id == node_id and _reachable.has(next_id)
			var hovered: bool = _hovered_node == next_id or _hovered_node == node_id
			if bright:
				line_layer.draw_line(from_pos, to_pos, PATH_COLOR_BRIGHT, 4.0)
				_draw_traveling_pulse(line_layer, from_pos, to_pos)
			else:
				var traversed: bool = RunManager.visited_nodes.has(node_id) and RunManager.visited_nodes.has(next_id)
				var dim_color := Color(0.82, 0.72, 0.52, 0.42) if traversed else Color(0.58, 0.70, 0.76, 0.12)
				line_layer.draw_line(from_pos, to_pos, Color(0.90, 0.77, 0.52, 0.72) if hovered else dim_color, 2.5 if hovered else (1.8 if traversed else 1.0))

	for node_id: String in nodes:
		var at: Vector2 = _positions[node_id]
		var available: bool = _reachable.has(node_id)
		var current: bool = node_id == RunManager.current_node_id
		var visited: bool = RunManager.visited_nodes.has(node_id)
		var radius: float = 40.0 if current else (52.0 if nodes[node_id].type == MapGenerator.NodeType.BOSS else 37.0)
		var fill := Color("17232fe8") if available or current else Color("09121ab8")
		var line := ScreenDesign.GOLD if available or current else (Color("58646d78") if not visited else Color("7d8a9270"))
		line_layer.draw_circle(at, radius, fill)
		line_layer.draw_arc(at, radius, 0, TAU, 48, line, 2.0 if available or current else 1.0, true)


func _draw_traveling_pulse(line_layer: Control, from_pos: Vector2, to_pos: Vector2) -> void:
	var t: float = fmod(_path_time * 0.30, 1.0)
	var pulse_pos: Vector2 = from_pos.lerp(to_pos, t)
	var fade: float = sin(t * PI)
	line_layer.draw_circle(pulse_pos, 5.0, Color(1.0, 0.88, 0.62, 0.82 * fade))


func _current_reachable_ids() -> Array[String]:
	var nodes: Dictionary = _map_data.nodes
	if RunManager.current_node_id.is_empty():
		return _map_data.start_ids
	var current: MapGenerator.MapNode = nodes.get(RunManager.current_node_id)
	if current == null:
		return _map_data.start_ids
	return current.connections


func _build_node_button(node: MapGenerator.MapNode, is_current: bool, is_reachable: bool) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	var node_size: Vector2 = BOSS_NODE_SIZE if node.type == MapGenerator.NodeType.BOSS else NODE_SIZE
	var center: Vector2 = _positions[node.id]
	button.position = center - node_size * 0.5
	button.size = node_size
	button.custom_minimum_size = node_size
	button.disabled = true
	button.tooltip_text = TYPE_LABELS.get(node.type, "Waypoint")
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var icon_path: String = TYPE_ICON_PATHS.get(node.type, "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.name = "CenteredNodeIcon"
		icon.texture = _centered_icon(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		var icon_size: float = node_size.x * ICON_SIZE_MULT
		icon.offset_left = -icon_size * 0.5
		icon.offset_top = -icon_size * 0.5
		icon.offset_right = icon_size * 0.5
		icon.offset_bottom = icon_size * 0.5
		button.add_child(icon)
	else:
		button.text = TYPE_LABELS.get(node.type, "?")
		button.add_theme_color_override("font_color", TYPE_COLORS.get(node.type, Color.WHITE))

	var empty_style := StyleBoxEmpty.new()
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		empty_style.set_content_margin(side, 0)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state_name, empty_style)
	# The project button theme initially clamps width to 120px. Reset the
	# geometry AFTER removing that style minimum, otherwise 80px nodes have
	# a 20px rightward artwork/hit-target shift relative to the drawn circle.
	button.size = node_size
	button.position = center - node_size * 0.5
	var is_visited: bool = RunManager.visited_nodes.has(node.id)
	if not is_current and not is_visited and is_reachable:
		button.disabled = false
		button.modulate = Color.WHITE
		button.pressed.connect(_select_destination.bind(node))
	else:
		button.modulate = Color(1, 1, 1, 0.36) if not is_current else Color(1, 1, 1, 0.72)
	button.mouse_entered.connect(_inspect_node.bind(node))
	button.focus_entered.connect(_inspect_node.bind(node))
	button.mouse_exited.connect(func() -> void: _hovered_node = "")
	button.focus_exited.connect(func() -> void: _hovered_node = "")
	button.resized.connect(func() -> void: button.position = center - button.size * 0.5)
	button.position = center - button.size * 0.5
	return button


func _inspect_node(node: MapGenerator.MapNode) -> void:
	_hovered_node = node.id
	_route_hint.text = "%s  ·  CLICK TO ENTER" % TYPE_LABELS.get(node.type, "DESTINATION").to_upper() if _reachable.has(node.id) else TYPE_LABELS.get(node.type, "WAYPOINT").to_upper()


func _build_node_glow(center: Vector2, node_size: Vector2, color: Color) -> TextureRect:
	var glow_size: Vector2 = node_size * GLOW_SIZE_MULT
	var glow := TextureRect.new()
	glow.texture = AmbientMotion._get_glow_texture()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.position = center - glow_size * 0.5
	glow.size = glow_size
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.modulate = Color(color.r, color.g, color.b, 0.52)
	return glow


func _select_destination(node: MapGenerator.MapNode) -> void:
	if not _reachable.has(node.id):
		return
	_on_node_pressed(node)


func _on_node_pressed(node: MapGenerator.MapNode) -> void:
	match node.type:
		MapGenerator.NodeType.COMBAT, MapGenerator.NodeType.ELITE, MapGenerator.NodeType.BOSS:
			var ids: Array[String] = node.enemy_ids
			if ids.is_empty():
				ids = [node.enemy_id]
			var enemies: Array[EnemyData] = []
			for enemy_id in ids:
				var enemy: EnemyData = ContentDatabase.get_enemy(enemy_id)
				if enemy != null:
					enemies.append(enemy)
			if enemies.size() == ids.size():
				if RunManager.should_offer_pre_battle():
					GameFlow.goto_pre_battle_offer(enemies, node.id)
				else:
					_commit_destination(node.id)
					GameFlow.goto_combat(enemies)
			else:
				push_error("map_screen: no EnemyData found for enemy_id(s) '%s' (node %s) - cannot start combat" % [ids, node.id])
				ModalConfirmDialog.show_dialog(self, "Couldn't start combat: enemy data '%s' is missing. This has been logged." % node.enemy_id, "OK", func() -> void: pass)
		MapGenerator.NodeType.REST:
			_commit_destination(node.id)
			GameFlow.goto_rest_site()
		MapGenerator.NodeType.SHOP:
			_commit_destination(node.id)
			GameFlow.goto_shop()
		MapGenerator.NodeType.EVENT:
			_commit_destination(node.id)
			var events: Array[EventData] = EventCatalog.get_all_events()
			if not events.is_empty():
				GameFlow.goto_event(events[randi() % events.size()])
			else:
				push_error("map_screen: no events are registered")
				GameFlow.goto_map()
		MapGenerator.NodeType.TREASURE:
			_resolve_treasure(node.id)


func _commit_destination(node_id: String) -> void:
	RunManager.commit_map_node(node_id)
	SaveManager.save_run()
	_rebuild_map()


func _resolve_treasure(node_id: String) -> void:
	var candidates: Array[RelicData] = []
	for relic: RelicData in ContentDatabase.all_relics():
		if not RunManager.has_relic(relic.id):
			candidates.append(relic)
	var ok_gain: int = randi_range(20, 40)
	var found_relic: RelicData = null
	if not candidates.is_empty():
		found_relic = candidates[randi() % candidates.size()]
	RunManager.commit_map_node(node_id)
	OKRunState.gain_ok(ok_gain, "treasure")
	if found_relic != null:
		RunManager.add_relic(found_relic)
	SaveManager.save_run()
	_rebuild_map()
	GameFlow.goto_treasure(ok_gain, found_relic)
