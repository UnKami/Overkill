extends Node
## Geometric routes, gear phasing, actual hit regions and save reconstruction.
var _failures: Array[String] = []
var _checks: int = 0


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	_check_tooth_clearance()
	for version: int in [1, 2]:
		for act: int in [1, 2, 3]:
			for run_seed: int in [0, 17, 19030, 42042]:
				_check_lattice(CogNavigationGenerator.generate(run_seed, act, version), version)
	RunManager.start_new_run([], [], 500, 19030)
	var screen := load("res://scenes/cog_map_screen.tscn").instantiate() as CogMapScreen
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(screen._gear_surfaces.size() == 16, "New screen has the sixteen-wheel concept diamond")
	_check(screen._reachable_gears.size() == 1 and not screen._advance_button.disabled, "Bottom entrance is actionable")
	_check(screen._gear_centers[screen._map.layers[0][0]].y > screen._gear_centers[screen._map.layers[-1][0]].y, "Progression climbs from bottom to top")
	_check(screen._seat_summary.get_child_count() == 3, "Timing outcomes remain explained")
	var start: String = screen._selected_gear_id
	var first_node: MapGenerator.MapNode = (screen._gears[start] as CogNavigationGenerator.Gear).seats[0]
	RunManager.commit_map_node(first_node.id)
	RunManager.cog_machine_angle = 1.234
	var snapshot: Dictionary = RunManager.to_save_dict()
	RunManager.load_from_save(snapshot)
	_check(RunManager.cog_layout_version == 2 and is_equal_approx(RunManager.cog_machine_angle, 1.234), "Save preserves map generation and machine phase")
	screen.queue_free()
	await get_tree().process_frame
	var resumed := load("res://scenes/cog_map_screen.tscn").instantiate() as CogMapScreen
	add_child(resumed)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(resumed._current_node.id == first_node.id and resumed._reachable_gears.size() == 2, "Landing restores two physically adjacent upward choices")
	var phase_before: float = resumed._machine_angle
	resumed._on_gear_selected(resumed._reachable_gears[1])
	_check(is_equal_approx(resumed._machine_angle, phase_before), "Choosing a direction does not rotate an individual gear")
	_check_phase(resumed)
	resumed._toggle_overview()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(resumed._overview and resumed._map_zoom < 1.0, "Overview fits the whole machine")
	_check(resumed._canvas.custom_minimum_size.y <= resumed._scroll.size.y + 1.0, "Overview fits all seven rows vertically")
	for gear_id: String in resumed._gears:
		var button: Button = resumed._gear_buttons[gear_id]
		_check(not button._has_point(Vector2.ZERO) and button._has_point(Vector2.ONE * 143.0), "Round gear hit region excludes overlapping square corners")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var folder: String = ProjectSettings.globalize_path("res://.test-artifacts/044")
		DirAccess.make_dir_recursive_absolute(folder)
		_check(get_viewport().get_texture().get_image().save_png(folder.path_join("machine-overview.png")) == OK, "Capture actual overview")
	resumed.queue_free()
	await get_tree().process_frame
	(snapshot.map as Dictionary).erase("cog_layout_version")
	RunManager.load_from_save(snapshot)
	_check(RunManager.cog_layout_version == 1, "Existing saves retain their current eight-stage encounters")
	var old: Dictionary = CogNavigationGenerator.generate(RunManager.seed_value, 1, RunManager.cog_layout_version)
	_check(old.nodes.has("cogmap-a1-r7-g0-s0") and old.gears.size() == 18, "Old guardian and all old seat IDs remain valid")
	RunManager.advance_act(19030)
	_check(RunManager.cog_layout_version == 2, "Next act uses the corrected seven-row concept")
	if _failures.is_empty():
		print("COG_NAVIGATION_OK: %d checks; concept diamond, edge routes, meshed phasing, round input, overview and old/new saves" % _checks)
	else:
		for failure: String in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check_lattice(map: Dictionary, version: int) -> void:
	var gears: Dictionary = map.gears
	var layers: Array = map.layers
	_check(layers.size() == (7 if version == 2 else 8), "Correct row count for map version")
	_check(gears.size() == (16 if version == 2 else 18), "Correct gear count for map version")
	var seen: Dictionary = {}
	var pending: Array[String] = [layers[0][0]]
	while not pending.is_empty():
		var id: String = pending.pop_front()
		if seen.has(id): continue
		seen[id] = true
		var gear: CogNavigationGenerator.Gear = gears[id]
		pending.append_array(gear.connections)
	_check(seen.size() == gears.size(), "All gears belong to one reachable upward apparatus")
	for gear_id: String in gears:
		var gear: CogNavigationGenerator.Gear = gears[gear_id]
		_check(gear.seats.size() == 3, "Three existing encounter seats remain")
		if gear.layer < layers.size() - 1:
			var current_count: int = layers[gear.layer].size()
			var next_count: int = layers[gear.layer + 1].size()
			if version == 2:
				var edge: bool = next_count < current_count and gear.index in [0, current_count - 1]
				_check(gear.connections.size() == (1 if edge else 2), "Only narrowing outer wheels have one onward contact: " + gear_id)
			_check(not gear.connections.is_empty(), "No non-guardian wheel is a dead end")
			for next_id: String in gear.connections:
				var next: CogNavigationGenerator.Gear = gears[next_id]
				_check(next.layer == gear.layer + 1 and next.machine_position.y < gear.machine_position.y, "Every route climbs one row")
				_check(absf(gear.machine_position.distance_to(next.machine_position) - CogNavigationGenerator.MESH_DISTANCE) < 0.01, "Every route has exact pitch-circle contact")
				for phase: float in [0.0, 0.27, 1.1, 4.32, 8.9]:
					var contact: float = (next.machine_position - gear.machine_position).angle()
					var sum: float = CogNavigationGenerator.rotation_for_layer(gear.layer, phase) + CogNavigationGenerator.rotation_for_layer(next.layer, phase)
					var expected: float = 2.0 * contact + PI - CogGearView.TOOTH_STEP * 0.5
					_check(absf(wrapf(sum - expected, -CogGearView.TOOTH_STEP * 0.5, CogGearView.TOOTH_STEP * 0.5)) < 0.001, "Teeth keep complementary phase through rotation")
		else:
			_check(gear.connections.is_empty(), "Guardian is the apex")
		for seat_index: int in gear.seats.size():
			var seat: MapGenerator.MapNode = gear.seats[seat_index]
			_check(CogNavigationGenerator.gear_id_from_node(seat.id) == gear_id, "Seat ID restores owning wheel")
			var phase: float = PI * 0.5 - CogNavigationGenerator.SEAT_ANGLES[seat_index]
			_check(CogMapScreen._nearest_seat(phase, PI * 0.5).seat == seat_index, "Timing matches the rendered seat angle")
		for other_id: String in layers[gear.layer]:
			if other_id == gear_id: continue
			var other: CogNavigationGenerator.Gear = gears[other_id]
			_check(gear.machine_position.distance_to(other.machine_position) > 2.0 * CogGearView.TIP_RADIUS, "Sideways gears have clearance instead of jammed triangular loops")
	for gear_id: String in layers[layers.size() - 2]:
		var approach: CogNavigationGenerator.Gear = gears[gear_id]
		_check(approach.seats[0].type == MapGenerator.NodeType.REST, "Guardian approach keeps rest option")


func _check_phase(screen: CogMapScreen) -> void:
	for id: String in screen._gears:
		var gear: CogNavigationGenerator.Gear = screen._gears[id]
		var surface: Node2D = screen._gear_surfaces[id]
		_check(is_equal_approx(surface.rotation, CogNavigationGenerator.rotation_for_layer(gear.layer, screen._machine_angle)), "All actual wheels use one drive phase")


func _check_tooth_clearance() -> void:
	var outline: PackedVector2Array = CogGearView.tooth_outline()
	for sample: int in 48:
		var phase: float = CogGearView.TOOTH_STEP * sample / 48.0
		var first: PackedVector2Array = Transform2D(phase, Vector2.ZERO) * outline
		var second: PackedVector2Array = Transform2D(-phase + PI / 24.0, Vector2(CogNavigationGenerator.MESH_DISTANCE, 0.0)) * outline
		var intersections: Array[PackedVector2Array] = Geometry2D.intersect_polygons(first, second)
		var area: float = 0.0
		for polygon: PackedVector2Array in intersections:
			var signed_area: float = 0.0
			for index: int in polygon.size():
				signed_area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
			area += absf(signed_area) * 0.5
		_check(area < 2.0, "Tooth profiles remain clear throughout a full tooth cycle: %.3f pixels squared" % area)


func _check(passed: bool, description: String) -> void:
	_checks += 1
	if not passed:
		_failures.append(description)
