class_name CogMapScreen
extends Control
## A route is travelled as a sequence of meshed wheels. Choose one of the two
## forward gears, watch its three seats pass the arrival pointer, and advance.
## Arrival catches the nearest seat, so a mistimed input is never a dead end.

const WHEEL_ART := "res://assets/map/cog_navigation/wheel.png"
const EXECUTIONER_ART := "res://assets/map/cog_navigation/executioner_overhead.png"
const GEAR_SIZE := 286.0
const GEAR_PITCH_Y := 250.0
const GEAR_TOP := 30.0
const CANVAS_MIN_WIDTH := 1530.0
const NODE_ICON_PATHS := {
	MapGenerator.NodeType.COMBAT: "res://assets/icons/map/node_combat.png",
	MapGenerator.NodeType.ELITE: "res://assets/icons/map/node_elite.png",
	MapGenerator.NodeType.REST: "res://assets/icons/map/node_rest.png",
	MapGenerator.NodeType.SHOP: "res://assets/icons/map/node_shop.png",
	MapGenerator.NodeType.EVENT: "res://assets/icons/map/node_event.png",
	MapGenerator.NodeType.TREASURE: "res://assets/icons/map/node_treasure.png",
	MapGenerator.NodeType.BOSS: "res://assets/icons/map/node_boss.png",
}
const NODE_NAMES := {
	MapGenerator.NodeType.COMBAT: "BATTLE",
	MapGenerator.NodeType.ELITE: "ELITE",
	MapGenerator.NodeType.REST: "REST SITE",
	MapGenerator.NodeType.SHOP: "CLOCKWRIGHT",
	MapGenerator.NodeType.EVENT: "ENCOUNTER",
	MapGenerator.NodeType.TREASURE: "TREASURE",
	MapGenerator.NodeType.BOSS: "ACT GUARDIAN",
}
const NODE_COLORS := {
	MapGenerator.NodeType.COMBAT: Color("e9c98c"),
	MapGenerator.NodeType.ELITE: Color("ec927d"),
	MapGenerator.NodeType.REST: Color("7dd8dd"),
	MapGenerator.NodeType.SHOP: Color("f0c676"),
	MapGenerator.NodeType.EVENT: Color("c39be8"),
	MapGenerator.NodeType.TREASURE: Color("f2d58a"),
	MapGenerator.NodeType.BOSS: Color("ffb96f"),
}
const SEAT_CENTERS: Array[Vector2] = [Vector2(0.5, 0.145), Vector2(0.755, 0.735), Vector2(0.245, 0.735)]
const POINTER_ANGLE: float = -PI * 0.5
const PERFECT_WINDOW_RADIANS: float = 0.22
static var _icon_cache: Dictionary = {}

@onready var _background: TextureRect = %Background
@onready var _scroll: ScrollContainer = %MapScroll
@onready var _canvas: Control = %MapCanvas
@onready var _timing_hint: Label = %TimingHint
@onready var _destination_label: Label = %DestinationLabel
@onready var _advance_button: Button = %AdvanceButton
@onready var _seat_summary: HBoxContainer = %SeatSummary
var _header_status: Label
@onready var _route_hint: Label = %RouteHint

var _map: Dictionary = {}
var _gears: Dictionary = {}
var _gear_controls: Dictionary = {}
var _gear_surfaces: Dictionary = {}
var _gear_buttons: Dictionary = {}
var _gear_centers: Dictionary = {}
var _seat_markers: Dictionary = {}
var _current_node: MapGenerator.MapNode
var _current_gear_id: String = ""
var _reachable_gears: Array[String] = []
var _selected_gear_id: String = ""
var _travel_locked: bool = false
var _path_time: float = 0.0
var _canvas_width: float = CANVAS_MIN_WIDTH
var _status_flash_time: float = 0.0


func _ready() -> void:
	_load_map_art()
	_load_map_artwork()
	_build_header()
	_build_footer()
	_build_map()
	resized.connect(_layout)
	_layout()
	_scroll_to_current_layer.call_deferred()


func _process(delta: float) -> void:
	_path_time += delta
	if _status_flash_time > 0.0:
		_status_flash_time = maxf(0.0, _status_flash_time - delta)
	for gear_id: String in _gear_surfaces:
		var surface: Node2D = _gear_surfaces[gear_id]
		if _travel_locked:
			continue
		var gear: CogNavigationGenerator.Gear = _gears[gear_id]
		var direction: float = 1.0 if gear.layer % 2 == 0 else -1.0
		var rate: float = 0.88 if gear_id == _selected_gear_id and _reachable_gears.has(gear_id) else 0.035
		surface.rotation += direction * rate * delta
	_update_timing_hint()
	if is_instance_valid(_route_hint):
		_route_hint.queue_redraw()


func _load_map_art() -> void:
	_map = CogNavigationGenerator.generate(RunManager.seed_value, RunManager.act_number)
	_gears = _map.gears
	var current_id: String = RunManager.current_node_id
	if not current_id.is_empty() and current_id.begins_with("cogmap-"):
		_current_node = _map.nodes.get(current_id) as MapGenerator.MapNode
		_current_gear_id = CogNavigationGenerator.gear_id_from_node(current_id)
	if _current_gear_id.is_empty():
		_reachable_gears.assign([_map.layers[0][0]])
	else:
		var current_gear: CogNavigationGenerator.Gear = _gears.get(_current_gear_id) as CogNavigationGenerator.Gear
		if current_gear != null:
			_reachable_gears.assign(current_gear.connections)
	if not _reachable_gears.is_empty():
		_selected_gear_id = _reachable_gears[0]


func _load_map_artwork() -> void:
	var image_path: String = CinematicArt.map_background(RunManager.act_number)
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		_background.texture = load(image_path)
		AmbientMotion.apply_cinematic_backdrop(self, _background, 35.0, 0.33)


func _build_header() -> void:
	var header: PanelContainer = %Header
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	var title := ScreenDesign.label(row, "THE COGWORK ASCENT", 19, ScreenDesign.GOLD)
	title.add_theme_font_override("font", ScreenDesign.display_font())
	title.custom_minimum_size.x = 270.0
	var divider := ColorRect.new()
	divider.color = Color("d2b27c70")
	divider.custom_minimum_size = Vector2(1.0, 30.0)
	row.add_child(divider)
	var act_label := ScreenDesign.label(row, "ACT %02d · THE %s" % [RunManager.act_number, _act_name()], 17, ScreenDesign.TEXT)
	act_label.add_theme_font_override("font", ScreenDesign.display_font())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_header_status = ScreenDesign.label(row, "VITALITY %d / %d   ·   OVERKILL %d" % [RunManager.current_hp, RunManager.max_hp, OKRunState.current_ok], 16, ScreenDesign.MUTED)
	_header_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var relic_button := _header_button("RELICS", func() -> void: GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE))
	relic_button.custom_minimum_size = Vector2(96.0, 40.0)
	row.add_child(relic_button)
	var pause_button := _header_button("PAUSE", func() -> void: GameFlow.open_pause_menu())
	pause_button.custom_minimum_size = Vector2(88.0, 40.0)
	row.add_child(pause_button)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 17)
	margin.add_theme_constant_override("margin_right", 17)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	header.add_child(margin)
	margin.add_child(row)
	_route_hint = %RouteHint
	_route_hint.text = "CHOOSE A FORWARD GEAR  ·  TIME YOUR ARRIVAL  ·  MISSED WINDOWS SNAP TO THE NEAREST SEAT"
	if _current_node == null:
		_route_hint.text = "THE FIRST GEAR IS WAITING  ·  TIME YOUR ARRIVAL TO CHOOSE A SEAT"


func _build_footer() -> void:
	_destination_label = %DestinationLabel
	_seat_summary = %SeatSummary
	_timing_hint = %TimingHint
	_advance_button = %AdvanceButton
	_advance_button.pressed.connect(_on_advance_pressed)
	ScreenDesign.add_actionable_fx(_advance_button, ScreenDesign.GOLD, false)
	_update_destination_summary()


func _build_map() -> void:
	for child: Node in _canvas.get_children():
		child.queue_free()
	_gear_controls.clear()
	_gear_surfaces.clear()
	_gear_buttons.clear()
	_gear_centers.clear()
	var viewport_width: float = get_viewport_rect().size.x
	_canvas_width = maxf(CANVAS_MIN_WIDTH, viewport_width - 128.0)
	var layer_count: int = _map.layers.size()
	_canvas.custom_minimum_size = Vector2(_canvas_width, GEAR_TOP + (layer_count - 1) * GEAR_PITCH_Y + GEAR_SIZE + 60.0)
	_build_path_lines()
	_add_layer_labels()
	for layer_index: int in layer_count:
		var ids: Array = _map.layers[layer_index]
		for gear_index: int in ids.size():
			var gear_id: String = ids[gear_index]
			var center := _position_for_gear(layer_index, gear_index, ids.size())
			_gear_centers[gear_id] = center
			_add_gear(_gears[gear_id] as CogNavigationGenerator.Gear, center)
	for id: String in _gear_controls:
		_apply_gear_state(id)


func _build_path_lines() -> void:
	var layer_lines := Control.new()
	layer_lines.name = "CogLinks"
	layer_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer_lines.draw.connect(_draw_links.bind(layer_lines))
	layer_lines.z_index = -5
	_canvas.add_child(layer_lines)


func _add_layer_labels() -> void:
	for layer_index: int in _map.layers.size():
		var layer_name: String = "ACT GUARDIAN" if layer_index == _map.layers.size() - 1 else "STAGE %02d" % (layer_index + 1)
		var label := ScreenDesign.label(_canvas, layer_name, 13, ScreenDesign.MUTED)
		label.position = Vector2(18.0, _layer_y(layer_index) + GEAR_SIZE * 0.5 - 13.0)
		label.size = Vector2(130.0, 26.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _add_gear(gear: CogNavigationGenerator.Gear, center: Vector2) -> void:
	var root := Control.new()
	root.name = gear.id.replace("-", "_")
	root.position = center - Vector2.ONE * GEAR_SIZE * 0.5
	root.size = Vector2.ONE * GEAR_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.z_index = 1
	_canvas.add_child(root)
	_gear_controls[gear.id] = root

	var clickable := Button.new()
	clickable.name = "GearChoice"
	clickable.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clickable.focus_mode = Control.FOCUS_ALL
	clickable.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clickable.add_theme_stylebox_override("normal", _invisible_box())
	clickable.add_theme_stylebox_override("hover", _invisible_box())
	clickable.add_theme_stylebox_override("pressed", _invisible_box())
	clickable.add_theme_stylebox_override("focus", _invisible_box())
	clickable.pressed.connect(_on_gear_selected.bind(gear.id))
	root.add_child(clickable)
	_gear_buttons[gear.id] = clickable

	var surface := Node2D.new()
	surface.name = "RotatingWheel"
	surface.position = Vector2.ONE * GEAR_SIZE * 0.5
	surface.z_index = -1
	root.add_child(surface)
	var wheel := Sprite2D.new()
	wheel.name = "WheelArt"
	wheel.texture = load(WHEEL_ART)
	wheel.scale = _sprite_scale(wheel.texture, GEAR_SIZE)
	surface.add_child(wheel)
	var glow := Sprite2D.new()
	glow.name = "GearGlow"
	glow.texture = AmbientMotion._get_glow_texture()
	glow.scale = _sprite_scale(glow.texture, GEAR_SIZE * 1.24)
	glow.modulate = Color("63dce0", 0.18)
	surface.add_child(glow)
	surface.move_child(glow, 0)

	for seat_index: int in gear.seats.size():
		var point: Vector2 = _seat_position(seat_index)
		var node: MapGenerator.MapNode = gear.seats[seat_index]
		var icon := Sprite2D.new()
		icon.name = "SeatIcon%d" % seat_index
		icon.texture = _centered_icon(NODE_ICON_PATHS.get(node.type, ""))
		icon.position = point - Vector2.ONE * GEAR_SIZE * 0.5
		icon.scale = _sprite_scale(icon.texture, 28.0)
		icon.modulate = NODE_COLORS.get(node.type, Color.WHITE)
		surface.add_child(icon)
		_seat_markers[node.id] = icon

	var pointer := ColorRect.new()
	pointer.name = "ArrivalPointer"
	pointer.position = Vector2(GEAR_SIZE * 0.5 - 2.0, 8.0)
	pointer.size = Vector2(4.0, 44.0)
	pointer.color = Color("f1cc7f")
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pointer)
	var gear_label := ScreenDesign.label(root, "GEAR %02d" % (gear.index + 1), 12, ScreenDesign.TEXT)
	gear_label.position = Vector2(42.0, GEAR_SIZE - 26.0)
	gear_label.size = Vector2(GEAR_SIZE - 84.0, 22.0)
	gear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var marker := Sprite2D.new()
	marker.name = "ExecutionerMarker"
	marker.texture = load(EXECUTIONER_ART)
	marker.scale = _sprite_scale(marker.texture, 64.0)
	marker.visible = false
	surface.add_child(marker)
	if gear.id == _current_gear_id and _current_node != null:
		var current_seat: int = CogNavigationGenerator.seat_index_from_node(_current_node.id)
		if current_seat >= 0 and current_seat < gear.seats.size():
			var marker_point: Vector2 = _seat_position(current_seat)
			marker.position = marker_point - Vector2.ONE * GEAR_SIZE * 0.5
			marker.visible = true

	_gear_surfaces[gear.id] = surface


func _draw_links(layer: Control) -> void:
	for gear_id: String in _gears:
		var gear: CogNavigationGenerator.Gear = _gears[gear_id]
		var from_center: Vector2 = _gear_centers.get(gear_id, Vector2.ZERO)
		for next_id: String in gear.connections:
			var to_center: Vector2 = _gear_centers.get(next_id, Vector2.ZERO)
			var active_link: bool = gear_id == _current_gear_id and _reachable_gears.has(next_id)
			var opening_link: bool = _current_node == null and gear.layer == 0
			var color: Color = Color("f1bf68", 0.78) if active_link or opening_link else Color("68a4b2", 0.24)
			layer.draw_line(from_center, to_center, color, 4.0 if active_link or opening_link else 2.0, true)
			if active_link or opening_link:
				var t: float = fposmod(_path_time * 0.22, 1.0)
				layer.draw_circle(from_center.lerp(to_center, t), 5.0, Color("ffe09a", 0.85))


func _layout() -> void:
	if not is_instance_valid(_scroll):
		return
	_scroll.anchor_left = 0.025
	_scroll.anchor_right = 0.975
	_scroll.offset_top = 142.0
	_scroll.offset_bottom = -194.0
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var desired_width: float = maxf(CANVAS_MIN_WIDTH, get_viewport_rect().size.x - 128.0)
	if not _gears.is_empty() and absf(desired_width - _canvas_width) > 1.0:
		_build_map()
		_update_destination_summary()


func _scroll_to_current_layer() -> void:
	if not is_instance_valid(_scroll):
		return
	var layer_index: int = 0 if _current_node == null else _current_node.row
	var target: int = maxi(0, roundi(_layer_y(layer_index) - _scroll.size.y * 0.48))
	_scroll.scroll_vertical = target


func _position_for_gear(layer_index: int, gear_index: int, count: int) -> Vector2:
	var y: float = _layer_y(layer_index) + GEAR_SIZE * 0.5
	var available_width: float = _canvas_width - GEAR_SIZE - 36.0
	var x: float = _canvas_width * 0.5 if count == 1 else GEAR_SIZE * 0.5 + 18.0 + float(gear_index) * available_width / float(count - 1)
	return Vector2(x, y)


func _layer_y(layer_index: int) -> float:
	# Route progression reads from the entrance at the top toward the guardian below.
	# This keeps the first two reachable gears visible without dropping the player
	# at the bottom of a long scroll surface on a new run.
	return GEAR_TOP + float(layer_index) * GEAR_PITCH_Y


func _seat_position(seat_index: int) -> Vector2:
	var center: Vector2 = Vector2.ONE * GEAR_SIZE * 0.5
	var normalized: Vector2 = SEAT_CENTERS[seat_index]
	return Vector2(normalized.x * GEAR_SIZE, normalized.y * GEAR_SIZE)


func _on_gear_selected(gear_id: String) -> void:
	if _travel_locked or not _reachable_gears.has(gear_id):
		return
	_selected_gear_id = gear_id
	for current_id: String in _gear_controls:
		_apply_gear_state(current_id)
	_update_destination_summary()


func _apply_gear_state(gear_id: String) -> void:
	var gear: CogNavigationGenerator.Gear = _gears[gear_id]
	var reachable: bool = _reachable_gears.has(gear_id)
	var selected: bool = gear_id == _selected_gear_id and reachable
	var current: bool = gear_id == _current_gear_id
	var is_start: bool = _current_node == null and gear.layer == 0
	var button: Button = _gear_buttons[gear_id]
	button.disabled = not reachable
	button.focus_mode = Control.FOCUS_ALL if reachable else Control.FOCUS_NONE
	button.tooltip_text = "Destination gear · click to select this route" if reachable and not selected else ("Current location" if current else "This wheel lies beyond your available routes")
	var wheel: Sprite2D = _gear_surfaces[gear_id].get_node("WheelArt") as Sprite2D
	wheel.modulate = Color.WHITE if reachable else Color(0.55, 0.63, 0.68, 0.64)
	var glow: Sprite2D = _gear_surfaces[gear_id].get_node("GearGlow") as Sprite2D
	glow.modulate = Color("f5c67c", 0.40) if selected or current or is_start else Color("63dce0", 0.12 if reachable else 0.035)
	if selected or current or is_start:
		AmbientMotion.pulse_alpha(glow, 0.32 if selected else 0.14, 0.62 if selected else 0.28, 1.2)
	else:
		AmbientMotion.pulse_alpha(glow, 0.04, 0.14, 2.0)


func _update_destination_summary() -> void:
	for child: Node in _seat_summary.get_children():
		child.queue_free()
	var selected: CogNavigationGenerator.Gear = _gears.get(_selected_gear_id) as CogNavigationGenerator.Gear
	if selected == null:
		_destination_label.text = "NO FORWARD GEAR"
		_timing_hint.text = "The ascent is complete."
		_advance_button.disabled = true
		return
	var is_first: bool = _current_node == null
	_destination_label.text = ("ENTER THE FIRST GEAR" if is_first else "DESTINATION GEAR %02d  ·  STAGE %02d" % [selected.index + 1, selected.layer + 1])
	for seat_index: int in selected.seats.size():
		var node: MapGenerator.MapNode = selected.seats[seat_index]
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 8)
		chip.custom_minimum_size = Vector2(170.0, 42.0)
		var icon := TextureRect.new()
		icon.texture = _centered_icon(NODE_ICON_PATHS.get(node.type, ""))
		icon.custom_minimum_size = Vector2(28.0, 28.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = NODE_COLORS.get(node.type, Color.WHITE)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon)
		var seat_text := ScreenDesign.label(chip, "SEAT %d  %s" % [seat_index + 1, NODE_NAMES[node.type]], 13, NODE_COLORS[node.type])
		seat_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seat_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_seat_summary.add_child(chip)
	_advance_button.disabled = _travel_locked or not _reachable_gears.has(_selected_gear_id)
	_update_timing_hint()


func _update_timing_hint() -> void:
	if _selected_gear_id.is_empty() or not _gear_surfaces.has(_selected_gear_id):
		return
	var gear: CogNavigationGenerator.Gear = _gears[_selected_gear_id]
	var surface: Node2D = _gear_surfaces[_selected_gear_id]
	var nearest: Dictionary = _nearest_seat(surface.rotation)
	var seat_index: int = nearest.seat
	var node: MapGenerator.MapNode = gear.seats[seat_index]
	var perfect: bool = float(nearest.error) <= PERFECT_WINDOW_RADIANS
	_timing_hint.text = "POINTER ALIGNMENT  ·  SEAT %d: %s%s" % [seat_index + 1, NODE_NAMES[node.type], "  ·  SWEET SPOT" if perfect else ""]
	_timing_hint.add_theme_color_override("font_color", Color("f3d68f") if perfect else NODE_COLORS[node.type])


static func _nearest_seat(rotation: float) -> Dictionary:
	var best_seat: int = 0
	var best_error: float = INF
	for seat_index: int in CogNavigationGenerator.SEAT_ANGLES.size():
		var angle: float = CogNavigationGenerator.SEAT_ANGLES[seat_index] + rotation
		var error: float = absf(wrapf(POINTER_ANGLE - angle, -PI, PI))
		if error < best_error:
			best_error = error
			best_seat = seat_index
	return {"seat": best_seat, "error": best_error}


func _on_advance_pressed() -> void:
	if _travel_locked or not _gear_surfaces.has(_selected_gear_id):
		return
	var gear: CogNavigationGenerator.Gear = _gears[_selected_gear_id]
	var surface: Node2D = _gear_surfaces[_selected_gear_id]
	var arrival: Dictionary = _nearest_seat(surface.rotation)
	var seat_index: int = arrival.seat
	var seat: MapGenerator.MapNode = gear.seats[seat_index]
	var signed_error: float = wrapf(POINTER_ANGLE - (CogNavigationGenerator.SEAT_ANGLES[seat_index] + surface.rotation), -PI, PI)
	var final_rotation: float = surface.rotation + signed_error
	_travel_locked = true
	_advance_button.disabled = true
	_timing_hint.text = ("CLEAN LANDING  ·  %s" if float(arrival.error) <= PERFECT_WINDOW_RADIANS else "SNAPPED TO NEAREST SEAT  ·  %s") % NODE_NAMES[seat.type]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(surface, "rotation", final_rotation, 0.30)
	tween.tween_callback(func() -> void: _resolve_seat(seat))


func _resolve_seat(node: MapGenerator.MapNode) -> void:
	_travel_locked = false
	match node.type:
		MapGenerator.NodeType.COMBAT, MapGenerator.NodeType.ELITE, MapGenerator.NodeType.BOSS:
			var ids: Array[String] = node.enemy_ids
			if ids.is_empty():
				ids = [node.enemy_id]
			var enemies: Array[EnemyData] = []
			for enemy_id: String in ids:
				var enemy: EnemyData = ContentDatabase.get_enemy(enemy_id)
				if enemy != null:
					enemies.append(enemy)
			if enemies.size() != ids.size():
				push_error("CogMapScreen: encounter missing enemy data for %s" % ids)
				ModalConfirmDialog.show_dialog(self, "This encounter could not be loaded. The issue has been logged.", "OK", func() -> void: pass)
				return
			if RunManager.should_offer_pre_battle():
				GameFlow.goto_pre_battle_offer(enemies, node.id)
			else:
				_commit_destination(node.id)
				GameFlow.goto_combat(enemies)
		MapGenerator.NodeType.REST:
			_commit_destination(node.id)
			GameFlow.goto_rest_site()
		MapGenerator.NodeType.SHOP:
			_commit_destination(node.id)
			GameFlow.goto_shop()
		MapGenerator.NodeType.EVENT:
			_commit_destination(node.id)
			var events: Array[EventData] = EventCatalog.get_all_events()
			if events.is_empty():
				push_error("CogMapScreen: no events are registered")
				GameFlow.goto_map()
			else:
				GameFlow.goto_event(events[randi() % events.size()])
		MapGenerator.NodeType.TREASURE:
			_resolve_treasure(node.id)


func _commit_destination(node_id: String) -> void:
	RunManager.commit_map_node(node_id)
	SaveManager.save_run()


func _resolve_treasure(node_id: String) -> void:
	var candidates: Array[RelicData] = []
	for relic: RelicData in ContentDatabase.all_relics():
		if not RunManager.has_relic(relic.id):
			candidates.append(relic)
	var gain: int = randi_range(20, 40)
	var found: RelicData = null
	if not candidates.is_empty():
		found = candidates[randi() % candidates.size()]
	RunManager.commit_map_node(node_id)
	OKRunState.gain_ok(gain, "treasure")
	if found != null and RunManager.relics_held.size() < 12:
		RunManager.add_relic(found)
	SaveManager.save_run()
	GameFlow.goto_treasure(gain, found)


func _current_layer() -> int:
	return -1 if _current_node == null else _current_node.row


func _act_name() -> String:
	return {1: "CRYPT BASTION", 2: "REFINERY", 3: "ABYSS"}.get(RunManager.act_number, "FINAL DESCENT")


func _header_button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", ScreenDesign.box(Color("101b26d9"), Color("c9aa7650"), 1))
	button.add_theme_stylebox_override("hover", ScreenDesign.box(Color("213440f0"), ScreenDesign.GOLD, 1))
	button.add_theme_stylebox_override("pressed", ScreenDesign.box(Color("30404df0"), ScreenDesign.GOLD, 1))
	button.pressed.connect(action)
	ScreenDesign.add_actionable_fx(button, ScreenDesign.GOLD, false)
	return button


func _invisible_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	return style


func _centered_icon(path: String) -> Texture2D:
	if _icon_cache.has(path):
		return _icon_cache[path]
	var source: Texture2D = load(path)
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = Rect2(source.get_image().get_used_rect())
	_icon_cache[path] = cropped
	return cropped


func _sprite_scale(texture: Texture2D, desired_size: float) -> Vector2:
	if texture == null:
		return Vector2.ONE
	var longest_side: float = maxf(texture.get_width(), texture.get_height())
	return Vector2.ONE * desired_size / longest_side
