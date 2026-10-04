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
	await _capture("review-overview")
	screen._toggle_overview()
	await get_tree().create_timer(1.0).timeout
	_check(screen._scroll.scroll_vertical > 0, "Follow camera frames the bottom entrance")
	await _capture("review-entrance")
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
		await get_tree().create_timer(0.8).timeout
		_check(screen.landings == stage + 1 and RunManager.current_node_id == seat_id, "Timed landing resolves exactly the selected seat")
		_check(not screen._travel_locked and screen._current_node.row == stage, "Landing unlocks the next stage")
		for id: String in screen._gear_surfaces:
			var gear: CogNavigationGenerator.Gear = screen._gears[id]
			_check(is_equal_approx(screen._gear_surfaces[id].rotation, CogNavigationGenerator.rotation_for_layer(gear.layer, screen._machine_angle)), "Landing retains one shared phase across every gear")
		await _capture("review-landed-%02d" % stage)
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

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder: String = ProjectSettings.globalize_path("res://.test-artifacts/044/machine-review")
	DirAccess.make_dir_recursive_absolute(folder)
	_check(get_viewport().get_texture().get_image().save_png(folder.path_join(label + ".png")) == OK, "Native review capture")

func _check(passed: bool, label: String) -> void:
	_checks += 1
	if not passed:
		_failures.append(label)
