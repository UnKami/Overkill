extends Node


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	var generated: Dictionary = CogNavigationGenerator.generate(19030, 1)
	var gears: Dictionary = generated.gears
	var layers: Array = generated.layers
	assert(layers.size() == 8, "A run should progress across eight wheel stages before the guardian")
	assert(gears.size() == 18, "The lattice should contain eighteen interlocking route gears")
	for gear_id: String in gears:
		var gear: CogNavigationGenerator.Gear = gears[gear_id]
		assert(gear.seats.size() == 3, "Every cog must present three timed seats")
		if gear.layer < layers.size() - 2:
			assert(gear.connections.size() == 2, "Each route cog before the guardian approach must offer two onward gears: %s" % gear.id)
		elif gear.layer == layers.size() - 2:
			assert(gear.connections.size() == 1, "Guardian approach wheels converge on the act guardian")
		for seat_index: int in gear.seats.size():
			var seat: MapGenerator.MapNode = gear.seats[seat_index]
			assert(CogNavigationGenerator.gear_id_from_node(seat.id) == gear_id, "Seat IDs must recover their owning gear")
			assert(CogNavigationGenerator.seat_index_from_node(seat.id) == seat_index, "Seat IDs must preserve the landing slot")
	for layer_index: int in range(5):
		for gear_id: String in layers[layer_index]:
			var gear: CogNavigationGenerator.Gear = gears[gear_id]
			for seat: MapGenerator.MapNode in gear.seats:
				assert(seat.type in [MapGenerator.NodeType.COMBAT, MapGenerator.NodeType.ELITE], "The first five stages must remain battles")
	for gear_id: String in layers[6]:
		var approach: CogNavigationGenerator.Gear = gears[gear_id]
		assert(approach.seats[0].type == MapGenerator.NodeType.REST, "Each guardian approach must offer a rest seat")
	var current_start: CogNavigationGenerator.Gear = gears[layers[0][0]]
	var target_angle: float = -PI * 0.5 - CogNavigationGenerator.SEAT_ANGLES[2]
	var arrival: Dictionary = CogMapScreen._nearest_seat(target_angle)
	assert(int(arrival.seat) == 2 and float(arrival.error) < 0.001, "A correctly timed entry should align the chosen seat")
	assert(current_start.connections.size() == 2, "The opening wheel must present a left/right route choice")

	RunManager.start_new_run([], [], 75, 19030)
	var screen := load("res://scenes/cog_map_screen.tscn").instantiate() as CogMapScreen
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(screen._gear_surfaces.size() == 18, "The route screen must render the full gear lattice")
	assert(screen._reachable_gears.size() == 1, "Fresh runs begin on one entrance cog")
	assert(screen._seat_summary.get_child_count() == 3, "The selected cog must explain all three seat outcomes")
	assert(not screen._advance_button.disabled, "A reachable gear should always offer the timing action")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var rendered: Image = get_viewport().get_texture().get_image()
		var capture_path: String = OS.get_environment("TEMP").path_join("overkill-cog-map-review.png")
		assert(rendered.save_png(capture_path) == OK, "The rendered cog map must be captured for visual review")
	var first_node: MapGenerator.MapNode = (screen._gears[screen._selected_gear_id] as CogNavigationGenerator.Gear).seats[0]
	RunManager.commit_map_node(first_node.id)
	screen.queue_free()
	await get_tree().process_frame
	var resumed := load("res://scenes/cog_map_screen.tscn").instantiate() as CogMapScreen
	add_child(resumed)
	await get_tree().process_frame
	assert(resumed._current_node.id == first_node.id, "Returning from an event must restore the exact landing seat")
	assert(resumed._reachable_gears.size() == 2, "After an event the player should choose between two forward wheels")
	assert(resumed._current_gear_id == CogNavigationGenerator.gear_id_from_node(first_node.id), "The saved location must restore the correct cog")
	print("COG_NAVIGATION_OK: deterministic lattice, timed seats, forward branches, rest guarantee and save-resume")
	resumed.queue_free()
	await get_tree().process_frame
	get_tree().quit()
