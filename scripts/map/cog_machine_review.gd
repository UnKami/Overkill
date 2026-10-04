extends Node
## Isolated review fixture: exercises production timing and transfer, then marks
## encounters cleared without fighting them. This is not campaign autoplay.
var _failures: Array[String] = []
var _checks: int = 0

class ReviewMap extends CogMapScreen:
	var landings: int = 0
	func _resolve_seat(node: MapGenerator.MapNode) -> void:
		landings += 1
		RunManager.cog_machine_angle = _machine_angle
		RunManager.commit_map_node(node.id)
		_transfer_progress = -1.0
		_travel_locked = false
		_load_map_art()
		_build_map()
		_update_destination_summary()
		_scroll_to_current_layer.call_deferred()

func _ready() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/.tools/042-audit-profile/"):
		push_error("Cog machine review requires an isolated developer profile")
		get_tree().quit(1)
		return
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	RunManager.start_new_run([], [], 500, 19030)
	var instance: Control = load("res://scenes/cog_map_screen.tscn").instantiate() as Control
	instance.set_script(ReviewMap)
	var screen: ReviewMap = instance as ReviewMap
	add_child(screen)
	await get_tree().create_timer(2.0).timeout
	_check(not screen._overview and screen._map_zoom > 1.5, "Entrance begins with a focused view")
	await _capture("review-entrance")
	screen._toggle_overview()
	await get_tree().create_timer(1.0).timeout
	await _capture("review-overview")
	screen._toggle_overview()
	await get_tree().create_timer(0.6).timeout
	var initial_camera: Vector2 = screen._camera_center
	var selection_before_drag: String = screen._selected_gear_id
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = screen._scroll.get_global_rect().get_center()
	screen._input(press)
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.position = press.position + Vector2(100.0, 420.0)
	screen._input(drag)
	press.pressed = false
	press.position = drag.position
	screen._input(press)
	_check(screen._manual_pan and screen._camera_center.y < initial_camera.y - 100.0, "Drag moves up the apparatus for planning")
	_check(screen._selected_gear_id == selection_before_drag and not screen._travel_locked, "Dragging never selects or advances a wheel")
	await get_tree().create_timer(0.7).timeout
	_check(screen._manual_pan and screen._camera_center.y < initial_camera.y - 100.0, "Planning camera remains where the player leaves it")
	await _capture("review-drag-planning")
	screen._toggle_overview()
	await get_tree().create_timer(0.6).timeout
	_check(not screen._manual_pan and screen._camera_center.distance_to(initial_camera) < 0.1, "Recenter smoothly returns to the immediate decision")
	for stage: int in 7:
		var key := InputEventKey.new()
		key.pressed = true
		key.keycode = KEY_LEFT if stage % 2 == 0 else KEY_RIGHT
		screen._shortcut_input(key)
		var expected: String = screen._reachable_gears[0 if stage % 2 == 0 else -1]
		_check(screen._selected_gear_id == expected, "Direction shortcut selects an actual meshed neighbor")
		await get_tree().create_timer(1.0).timeout
		var selected: CogNavigationGenerator.Gear = screen._gears[expected]
		var nearest: Dictionary = screen._nearest_seat(screen._gear_surfaces[expected].rotation, screen._arrival_angle(expected))
		var seat_id: String = selected.seats[int(nearest.seat)].id
		# A recently clicked Overview control must not consume the timing shortcut.
		screen._overview_button.grab_focus()
		key.keycode = KEY_SPACE
		screen._shortcut_input(key)
		_check(screen._travel_locked, "Space starts travel even after camera-button focus")
		await get_tree().create_timer(0.65).timeout
		_check(is_instance_valid(screen._transfer_marker), "Transfer creates the travelling character")
		_check(screen._transfer_progress > 0.0 and screen._transfer_progress < 1.0, "Character traverses a continuous arc")
		await _capture("review-transfer-%02d" % stage)
		await get_tree().create_timer(0.47).timeout
		var destination_surface: Node2D = screen._gear_surfaces[expected]
		var anchor: Vector2 = (CogNavigationGenerator.SEAT_CENTERS[int(nearest.seat)] - Vector2.ONE * 0.5) * screen.GEAR_SIZE
		var landing: Vector2 = screen._gear_centers[expected] + anchor.rotated(destination_surface.rotation)
		_check(screen._transfer_marker.position.distance_to(landing) < 0.001, "Landing snaps exactly to its actual hole, regardless of input accuracy")
		_check(screen._travel_locked and screen._landing_time > 0.0, "Landing remains visible before encounter transition")
		if stage in [0, 3, 6]:
			await _capture("review-settled-%02d" % stage)
		await get_tree().create_timer(0.95).timeout
		_check(screen.landings == stage + 1 and RunManager.current_node_id == seat_id, "Timed landing resolves exactly the selected seat")
		_check(not screen._travel_locked and screen._current_node.row == stage, "Landing unlocks the next stage")
		var marker: Sprite2D = screen._gear_surfaces[expected].get_node("ExecutionerMarker") as Sprite2D
		_check(marker.position.distance_to(anchor) < 0.001 and marker.visible, "Resumed player stays anchored to the same socket")
		_check(screen._camera_center.distance_to(initial_camera) > 50.0 or stage == 0, "Camera progresses along the climb")
		for id: String in screen._gear_surfaces:
			var gear: CogNavigationGenerator.Gear = screen._gears[id]
			_check(is_equal_approx(screen._gear_surfaces[id].rotation, CogNavigationGenerator.rotation_for_layer(gear.layer, screen._machine_angle)), "Landing retains one shared phase across every gear")
		await _capture("review-landed-%02d" % stage)
		if stage == 0:
			await _check_gui_drag(screen)
	_check(screen._reachable_gears.is_empty() and screen._advance_button.disabled, "Guardian has no further gear")
	screen._toggle_overview()
	await get_tree().create_timer(1.0).timeout
	await _capture("review-complete")
	screen.queue_free()
	await get_tree().process_frame
	for failure: String in _failures:
		push_error(failure)
	print("COG_MACHINE_REVIEW_OK: %d checks; production transfers, direction/timing controls and all seven stages" % _checks)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check_gui_drag(screen: ReviewMap) -> void:
	var selected: String = screen._selected_gear_id
	var other: String = screen._reachable_gears[-1]
	var button: Button = screen._gear_buttons[other]
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = button.get_global_rect().get_center()
	Input.parse_input_event(press)
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = press.position + Vector2(55.0, 80.0)
	Input.parse_input_event(motion)
	await get_tree().process_frame
	press.pressed = false
	press.position = motion.position
	Input.parse_input_event(press)
	await get_tree().process_frame
	_check(screen._selected_gear_id == selected and screen._manual_pan, "Real GUI event dispatch suppresses click-through when dragging the other branch")
	_check(not screen._dragging and screen._drag_button == MOUSE_BUTTON_NONE, "GUI drag releases cleanly without a stuck mouse capture")
	await _capture("review-drag-branches")
	screen._toggle_overview()
	await get_tree().create_timer(0.6).timeout

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://.test-artifacts/045/machine-review")
	DirAccess.make_dir_recursive_absolute(folder)
	_check(get_viewport().get_texture().get_image().save_png(folder.path_join(label + ".png")) == OK, "Native review capture")

func _check(passed: bool, label: String) -> void:
	_checks += 1
	if not passed:
		_failures.append(label)
