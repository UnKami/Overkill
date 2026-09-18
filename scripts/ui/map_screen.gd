extends Control
## Map screen (map-generation/audio doc Part 3.1 + screen-composition Part
## 4.1): the hub every other node type returns to. Nodes are positioned by
## absolute pixel coordinates on a tall scrollable canvas (row 0 / start at
## the bottom, boss at the top) with drawn connector lines between them, so
## the branching path actually reads as a path to climb - StS-style - rather
## than a stack of unconnected row labels. Regenerates the same branching
## graph deterministically from RunManager.seed_value/act_number every time
## it loads (MapGenerator is a pure function of those two values, so nothing
## about the graph itself needs to be saved) and highlights whatever's
## reachable from RunManager.current_node_id.

## Icon-only at every map view, no text on the node itself (icon-system doc
## Part 4) - TYPE_LABELS still used for tooltip_text (hover/accessibility)
## and as a safe text fallback if an icon fails to load.
const TYPE_LABELS := {
	MapGenerator.NodeType.COMBAT: "Combat",
	MapGenerator.NodeType.ELITE: "Elite",
	MapGenerator.NodeType.REST: "Rest Site",
	MapGenerator.NodeType.SHOP: "Shop",
	MapGenerator.NodeType.EVENT: "Event",
	MapGenerator.NodeType.TREASURE: "Treasure",
	MapGenerator.NodeType.BOSS: "Boss",
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
	MapGenerator.NodeType.COMBAT: Color("#c9c9c9"),
	MapGenerator.NodeType.ELITE: Color("#ff6b6a"),
	MapGenerator.NodeType.REST: Color("#5fb0f0"),
	MapGenerator.NodeType.SHOP: Color("#e8e8ee"),
	MapGenerator.NodeType.EVENT: Color("#c090ee"),
	MapGenerator.NodeType.TREASURE: Color("#ffc25c"),
	MapGenerator.NodeType.BOSS: Color("#ffffff"),
}

const ROW_HEIGHT := 150.0
const TOP_MARGIN := 80.0
const BOTTOM_MARGIN := 90.0
const SIDE_MARGIN := 110.0
const CANVAS_WIDTH := 900.0
const NODE_SIZE := Vector2(80, 80)
const BOSS_NODE_SIZE := Vector2(104, 104)
const GLOW_SIZE_MULT := 1.8

const PATH_COLOR_BRIGHT := Color(0.94, 0.62, 0.15, 0.9)
const PATH_COLOR_DIM := Color(1, 1, 1, 0.12)
const CURRENT_MARKER_COLOR := Color("#EF9F27")
const PATH_TEXTURE_PATH := "res://assets/ui/map/path_strip.png"
const PATH_LINE_WIDTH := 20.0

const BACKGROUND_ID_BY_ACT := {
	1: "res://assets/environments/act1/map_bg.jpg",
	2: "res://assets/environments/act2/map_bg.jpg",
	3: "res://assets/environments/act3/map_bg.jpg",
}

@onready var _hud: CombatHUD = %HUD
@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _canvas: Control = %MapCanvas
@onready var _act_label: Label = %ActLabel
@onready var _background: TextureRect = %Background

var _map_data: Dictionary = {}
var _positions: Dictionary = {}       # node_id -> Vector2 (center)
var _reachable: Array[String] = []
var _buttons: Dictionary = {}         # node_id -> Button
var _line_layer: Control = null
var _path_time: float = 0.0
var _hovered_node: String = ""
var _route_hint: Label


## Drives the traveling energy-pulse along bright connector lines. Redraw is
## cheap here (a handful of draw_line/draw_circle calls), so every frame is
## fine rather than throttling.
func _process(delta: float) -> void:
	if _line_layer == null:
		return
	_path_time += delta
	_line_layer.queue_redraw()


func _ready() -> void:
	_hud.bind_run_state()
	_act_label.hide()
	_load_background_art()
	_scroll.anchor_left = 0.40
	_scroll.anchor_right = 0.98
	_scroll.offset_top = 108
	_scroll.offset_bottom = -96
	ScreenDesign.frame(self,"THE ASCENT")
	var column := ScreenDesign.column(self,0.23,0.34)
	ScreenDesign.label(column,"ACT  %02d" % RunManager.act_number,18,ScreenDesign.CYAN)
	var chapter: String = {1:"The Crypt\nBastion",2:"The\nRefinery",3:"The\nAbyss"}.get(RunManager.act_number,"The Final\nDescent")
	ScreenDesign.label(column,chapter,44,ScreenDesign.GOLD,true)
	ScreenDesign.spacer(column,18)
	ScreenDesign.rule(column)
	var instructions := ScreenDesign.label(column,"Choose an illuminated destination.\nYour route climbs toward the boss.",22,ScreenDesign.MUTED)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ScreenDesign.label(column,"Gold: available · ✓: completed",24,ScreenDesign.GOLD)
	_route_hint = ScreenDesign.label(column,"Hover or focus a destination\nto inspect your next encounter.",24,ScreenDesign.MUTED)
	_route_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_route_hint.custom_minimum_size.y = 84
	ScreenDesign.spacer(column,20)
	ScreenDesign.button(column,"VIEW YOUR RELICS",func() -> void: GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE))
	ScreenDesign.button(column,"PAUSE JOURNEY",func() -> void: GameFlow.open_pause_menu())
	ScreenDesign.spacer(column,12)
	ScreenDesign.label(column,"SCROLL TO SURVEY THE ROUTE",15,ScreenDesign.MUTED)
	_rebuild_map()
	call_deferred("_scroll_to_bottom")


func _load_background_art() -> void:
	var path: String = "res://assets/environments/chronoforge_arena.png"
	_background.modulate = Color(0.42,0.48,0.53)
	if not path.is_empty() and ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)


func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = int(_canvas.custom_minimum_size.y)


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
	_canvas.custom_minimum_size = Vector2(CANVAS_WIDTH, canvas_height)

	for row_index in row_count:
		var row_ids: Array = rows[row_index]
		var y: float = TOP_MARGIN + (row_count - 1 - row_index) * ROW_HEIGHT
		var count: int = row_ids.size()
		for col in count:
			var x: float
			if count == 1:
				x = CANVAS_WIDTH * 0.5
			else:
				x = SIDE_MARGIN + col * (CANVAS_WIDTH - 2.0 * SIDE_MARGIN) / float(count - 1)
			_positions[row_ids[col]] = Vector2(x, y)

	# Live/bright edges get a real textured Line2D conduit (the path that
	# matters); dim/muted edges stay flat drawn lines underneath, per the
	# doc's "path lines secondary/muted" rule - texture would just be noise
	# on paths you're not looking at. Line2D nodes go in first so they sit
	# beneath the dim-line Control's _draw() and the buttons.
	var path_texture: Texture2D = null
	if ResourceLoader.exists(PATH_TEXTURE_PATH):
		path_texture = ResourceLoader.load(PATH_TEXTURE_PATH)
	for node_id in nodes:
		var node: MapGenerator.MapNode = nodes[node_id]
		for next_id in node.connections:
			var bright: bool = RunManager.current_node_id == node_id and _reachable.has(next_id)
			var hovered: bool = _hovered_node == next_id or _hovered_node == node_id
			if not bright or path_texture == null:
				continue
			var live_line := Line2D.new()
			live_line.points = PackedVector2Array([_positions[node_id], _positions[next_id]])
			live_line.width = PATH_LINE_WIDTH
			live_line.texture = path_texture
			live_line.texture_mode = Line2D.LINE_TEXTURE_TILE
			live_line.z_index = -1
			_canvas.add_child(live_line)

	# Dim edges (and the traveling pulse, drawn every frame regardless of
	# texture availability) via a dedicated child Control whose _draw() this
	# script feeds through a bound Callable.
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
		# Glow sits BEHIND the icon - added to the canvas before the button
		# so paint order puts it underneath, replacing the old pill
		# border/background entirely (icon-system doc: icon-only nodes).
		var glow: TextureRect = null
		if is_current or is_reachable:
			var node_size: Vector2 = BOSS_NODE_SIZE if node.type == MapGenerator.NodeType.BOSS else NODE_SIZE
			var glow_color: Color = CURRENT_MARKER_COLOR if is_current else TYPE_COLORS.get(node.type, Color.WHITE)
			glow = _build_node_glow(_positions[node.id], node_size, glow_color)
			_canvas.add_child(glow)
		var button := _build_node_button(node, is_current, is_reachable)
		_canvas.add_child(button)
		_buttons[node_id] = button
		var caption: Label = Label.new()
		caption.text = ("YOU ARE HERE · " if is_current else ("✓ " if RunManager.visited_nodes.has(node_id) else "")) + TYPE_LABELS.get(node.type, "")
		caption.position = _positions[node.id] + Vector2(-95,43)
		caption.size = Vector2(190,32)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size",24)
		caption.add_theme_constant_override("outline_size",6)
		caption.modulate = ScreenDesign.GOLD if is_reachable or is_current else Color("b1bcc5")
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(caption)

		# Affordance motion: the node you're standing on breathes gently,
		# every node you could move to next breathes a little faster - an
		# idle map is still visibly "yours to act on," not a static diagram.
		# Deliberately modulate.a (opacity) here, never scale/pivot -
		# animating a clickable Button's own transform is exactly the kind
		# of thing that can make click hit-testing unreliable.
		if glow != null:
			if is_current:
				AmbientMotion.pulse_alpha(glow, 0.45, 0.85, 2.4)
			else:
				AmbientMotion.pulse_alpha(glow, 0.3, 0.65, 1.6)


func _draw_connectors(line_layer: Control) -> void:
	var nodes: Dictionary = _map_data.nodes
	var have_texture := ResourceLoader.exists(PATH_TEXTURE_PATH)
	for node_id in nodes:
		var node: MapGenerator.MapNode = nodes[node_id]
		var from_pos: Vector2 = _positions[node_id]

		for next_id in node.connections:
			var to_pos: Vector2 = _positions[next_id]
			var bright: bool = RunManager.current_node_id == node_id and _reachable.has(next_id)
			var hovered: bool = _hovered_node == next_id or _hovered_node == node_id
			if bright:
				# Already drawn as a textured Line2D in _rebuild_map() when
				# art is available - only fall back to a flat bright line
				# here if that art is missing, so there's never a gap.
				line_layer.draw_line(from_pos, to_pos, PATH_COLOR_BRIGHT, 5.0)
				_draw_traveling_pulse(line_layer, from_pos, to_pos)
			else:
				line_layer.draw_line(from_pos, to_pos, Color(0.8,0.75,0.55,0.7) if hovered else Color(0.6,0.7,0.75,0.20), 3.0 if hovered else 2.0)


	# Draw all node bases after all routes so no route crosses a node icon.
	for node_id: String in nodes:
		var at: Vector2 = _positions[node_id]
		var available: bool = _reachable.has(node_id)
		line_layer.draw_circle(at, 42, Color("111c28"))
		line_layer.draw_arc(at, 42, 0, TAU, 48, ScreenDesign.GOLD if available else Color("53606b"), 2, true)

## A small bright dot sliding from the current node toward what's next -
## the one piece of motion on this screen that reads as "action," not idle
## ambience: it's literally pointing at where you can go.
func _draw_traveling_pulse(line_layer: Control, from_pos: Vector2, to_pos: Vector2) -> void:
	const PULSE_SPEED := 0.35  # loops per second
	var t: float = fmod(_path_time * PULSE_SPEED, 1.0)
	var pulse_pos: Vector2 = from_pos.lerp(to_pos, t)
	var fade: float = sin(t * PI)  # fades in/out at each end rather than popping
	line_layer.draw_circle(pulse_pos, 6.0, Color(1.0, 0.85, 0.5, 0.9 * fade))


func _current_reachable_ids() -> Array[String]:
	var nodes: Dictionary = _map_data.nodes
	if RunManager.current_node_id.is_empty():
		return _map_data.start_ids
	var current: MapGenerator.MapNode = nodes.get(RunManager.current_node_id)
	if current == null:
		return _map_data.start_ids
	return current.connections


## Icon-only node marker (icon-system doc: no text/pill chrome on the node
## itself) - a big centered icon, state read from a glow behind it (built by
## _build_node_glow) plus modulate brightness, nothing else. Every visual
## button state is explicitly overridden to empty: leaving "pressed"/"focus"
## unstyled let Godot's global button theme fall back to its full-size pill
## texture squeezed into a tiny node rect on press - a real, confirmed bug
## (looked like a broken flash, and made the click feel like it did nothing).
func _build_node_button(node: MapGenerator.MapNode, is_current: bool, is_reachable: bool) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var node_size: Vector2 = BOSS_NODE_SIZE if node.type == MapGenerator.NodeType.BOSS else NODE_SIZE
	var center: Vector2 = _positions[node.id]
	button.position = center - node_size * 0.5
	button.size = node_size
	button.custom_minimum_size = node_size
	button.disabled = false
	button.tooltip_text = TYPE_LABELS.get(node.type, "?")
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	var icon_path: String = TYPE_ICON_PATHS.get(node.type, "")
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		button.icon = ResourceLoader.load(icon_path)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", int(node_size.x * 0.75))
	else:
		button.text = TYPE_LABELS.get(node.type, "?")
		button.add_theme_color_override("font_color", TYPE_COLORS.get(node.type, Color.WHITE))
		button.add_theme_color_override("font_disabled_color", TYPE_COLORS.get(node.type, Color.WHITE))

	var empty_style := StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: empty_style.set_content_margin(side,0)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state_name, empty_style)

	var is_visited: bool = RunManager.visited_nodes.has(node.id)
	if is_visited and not is_current:
		button.modulate = Color(1, 1, 1, 0.35)
		button.disabled = true
	elif is_reachable:
		button.modulate = Color(1, 1, 1, 1.0)
		button.pressed.connect(_on_node_pressed.bind(node))
	else:
		button.modulate = Color(1, 1, 1, 0.6)
		button.disabled = true

	button.mouse_entered.connect(_inspect_node.bind(node))
	button.focus_entered.connect(_inspect_node.bind(node))
	button.mouse_exited.connect(func() -> void: _hovered_node = "")
	button.focus_exited.connect(func() -> void: _hovered_node = "")
	return button

func _inspect_node(node: MapGenerator.MapNode) -> void:
	_hovered_node = node.id
	var descriptions: Dictionary = {MapGenerator.NodeType.COMBAT:"Battle · win a relic reward.",MapGenerator.NodeType.ELITE:"Elite · a more dangerous battle.",MapGenerator.NodeType.REST:"Rest · recover or improve a relic.",MapGenerator.NodeType.SHOP:"Shop · spend your Overkill.",MapGenerator.NodeType.EVENT:"Event · make a story choice.",MapGenerator.NodeType.TREASURE:"Treasure · collect a reward.",MapGenerator.NodeType.BOSS:"Boss · win to finish this act."}
	_route_hint.text = descriptions.get(node.type,"Explore this destination.")
	if not node.enemy_id.is_empty():
		var enemy: EnemyData = ContentDatabase.get_enemy(node.enemy_id)
		if enemy != null: _route_hint.text += "\n" + enemy.display_name


## Soft radial glow marker behind the icon (replaces the old pill border) -
## reuses AmbientMotion's cached procedural glow texture rather than needing
## a dedicated art asset.
func _build_node_glow(center: Vector2, node_size: Vector2, color: Color) -> TextureRect:
	var glow_size: Vector2 = node_size * GLOW_SIZE_MULT
	var glow := TextureRect.new()
	glow.texture = AmbientMotion._get_glow_texture()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.position = center - glow_size * 0.5
	glow.size = glow_size
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.modulate = Color(color.r, color.g, color.b, 0.55)
	return glow


func _on_node_pressed(node: MapGenerator.MapNode) -> void:
	RunManager.commit_map_node(node.id)
	SaveManager.save_run()
	# Rebuild immediately, even though every branch below normally navigates
	# away right after - if a branch silently fails to navigate (e.g. no
	# matching enemy), the map must still reflect the committed node instead
	# of leaving stale connector-line art (drawn against the OLD reachable
	# set) on screen with nothing pointing at what's actually reachable now.
	_rebuild_map()
	match node.type:
		MapGenerator.NodeType.COMBAT, MapGenerator.NodeType.ELITE, MapGenerator.NodeType.BOSS:
			var ids: Array[String] = node.enemy_ids
			if ids.is_empty():
				ids = [node.enemy_id]
			var enemies: Array[EnemyData] = []
			for enemy_id in ids:
				var enemy := ContentDatabase.get_enemy(enemy_id)
				if enemy != null:
					enemies.append(enemy)
			if enemies.size() == ids.size():
				GameFlow.goto_combat(enemies)
			else:
				push_error("map_screen: no EnemyData found for enemy_id(s) '%s' (node %s) - cannot start combat" % [ids, node.id])
				ModalConfirmDialog.show_dialog(self, "Couldn't start combat: enemy data '%s' is missing. This has been logged." % node.enemy_id, "OK", func() -> void: pass)
		MapGenerator.NodeType.REST:
			GameFlow.goto_rest_site()
		MapGenerator.NodeType.SHOP:
			GameFlow.goto_shop()
		MapGenerator.NodeType.EVENT:
			var events := EventCatalog.get_all_events()
			GameFlow.goto_event(events[randi() % events.size()])
		MapGenerator.NodeType.TREASURE:
			_resolve_treasure()


func _resolve_treasure() -> void:
	var candidates: Array = []
	for relic in ContentDatabase.all_relics():
		if not RunManager.has_relic(relic.id):
			candidates.append(relic)
	var ok_gain := randi_range(20, 40)
	OKRunState.gain_ok(ok_gain, "treasure")
	var message := "Treasure: +%d OK" % ok_gain
	if not candidates.is_empty():
		var relic: RelicData = candidates[randi() % candidates.size()]
		RunManager.add_relic(relic)
		message += " and relic: %s" % relic.display_name
	SaveManager.save_run()
	ModalConfirmDialog.show_dialog(self, message, "Continue", func() -> void: pass)
	_rebuild_map()
