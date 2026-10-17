extends Node
## Automated Verification Suite for Global Run & Career Leaderboards with Firestore Integration.

func _ready() -> void:
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = true

	await _test_leaderboard_manager_lifecycle()
	await _test_firestore_payload_conversions()
	await _test_leaderboard_view_ui()
	await _test_run_summary_and_title_integration()

	print("LEADERBOARD_VERIFICATION_OK: Global run leaderboard, career account stats, Firestore payload parity, UI tab switching, and run summary integration verified!")
	get_tree().quit()


func _test_leaderboard_manager_lifecycle() -> void:
	assert(LeaderboardManager != null, "LeaderboardManager autoload must exist")
	assert(not LeaderboardManager.player_id.is_empty(), "LeaderboardManager must assign a unique player_id")
	assert(not LeaderboardManager.player_name.is_empty(), "LeaderboardManager must have a player_name")

	var initial_started: int = LeaderboardManager.runs_started
	var initial_completed: int = LeaderboardManager.runs_completed
	var initial_ok: int = LeaderboardManager.lifetime_overkill

	# 1. Test run started
	LeaderboardManager.record_run_started()
	assert(LeaderboardManager.runs_started == initial_started + 1, "runs_started must increment by 1")

	# 2. Test run completed with 150 Overkill in Act 3 (Victory)
	var rank: int = LeaderboardManager.record_run_completed(150, 3, true, 11, "Chrono-Overdrive")
	assert(LeaderboardManager.runs_completed == initial_completed + 1, "runs_completed must increment")
	assert(LeaderboardManager.lifetime_overkill == initial_ok + 150, "lifetime_overkill must increase by 150")
	assert(LeaderboardManager.best_run_overkill >= 150, "best_run_overkill must be at least 150")
	assert(rank > 0, "Placement rank must be positive")
	assert(LeaderboardManager.last_run_rank == rank, "last_run_rank must match returned rank")

	# 3. Test average overkill calculation
	var expected_avg: float = float(LeaderboardManager.lifetime_overkill) / float(LeaderboardManager.runs_started)
	var calc_avg: float = LeaderboardManager.get_average_overkill()
	assert(absf(calc_avg - expected_avg) < 0.001, "get_average_overkill() must equal lifetime / started")

	# 4. Test account ranking
	var acc_rank: int = LeaderboardManager.get_account_rank()
	assert(acc_rank > 0, "Account rank must be positive")

	# 5. Test player name modification
	LeaderboardManager.set_player_name("Vanquisher_99")
	assert(LeaderboardManager.player_name == "Vanquisher_99", "Player name must update")

	print("LIFECYCLE_OK: Run started, completion, average Overkill, and ranking verified.")


func _test_firestore_payload_conversions() -> void:
	# Test dictionary to Firestore typed fields
	var raw_data: Dictionary = {
		"run_id": "run_test_12345678",
		"player_id": "ply_test_87654321",
		"player_name": "TestExecutioner",
		"overkill_score": 240,
		"act_reached": 3,
		"won": true,
		"relics_count": 12,
		"average_overkill": 120.5,
		"timestamp": 1729170000
	}

	var firestore_fields: Dictionary = LeaderboardManager._dict_to_firestore_fields(raw_data)
	assert(firestore_fields["run_id"]["stringValue"] == "run_test_12345678", "String field conversion failed")
	assert(firestore_fields["overkill_score"]["integerValue"] == "240", "Integer field conversion failed")
	assert(firestore_fields["won"]["booleanValue"] == true, "Boolean field conversion failed")
	assert(absf(firestore_fields["average_overkill"]["doubleValue"] - 120.5) < 0.001, "Double field conversion failed")

	# Test roundtrip back from Firestore typed fields
	var restored: Dictionary = LeaderboardManager._firestore_fields_to_dict(firestore_fields)
	assert(restored["run_id"] == raw_data["run_id"], "Roundtrip string failed")
	assert(restored["overkill_score"] == raw_data["overkill_score"], "Roundtrip int failed")
	assert(restored["won"] == raw_data["won"], "Roundtrip bool failed")
	assert(absf(restored["average_overkill"] - raw_data["average_overkill"]) < 0.001, "Roundtrip double failed")

	print("FIRESTORE_CONVERSION_OK: Bidirectional typed serialization verified.")


func _test_leaderboard_view_ui() -> void:
	var view_script = preload("res://scripts/ui/leaderboard_view.gd")
	var view: Control = view_script.new()
	add_child(view)
	await get_tree().process_frame

	assert(view._panel != null, "Leaderboard panel must exist")
	assert(view._rows_container != null, "Leaderboard rows container must exist")
	assert(view._rows_container.get_child_count() > 0, "Rows container must be populated with entries")

	# Test tab switching
	view._switch_category("accounts")
	await get_tree().process_frame
	assert(view.current_category == "accounts", "Category must switch to accounts")
	assert(view._rows_container.get_child_count() > 0, "Account rows must be populated")

	view._switch_category("runs")
	await get_tree().process_frame
	assert(view.current_category == "runs", "Category must switch back to runs")

	view.queue_free()
	await get_tree().process_frame
	print("UI_OK: LeaderboardView instantiates, renders rows, and switches category tabs cleanly.")


func _test_run_summary_and_title_integration() -> void:
	# 1. Test RunSummaryScreen integration
	var summary_scene: PackedScene = load("res://scenes/run_summary_screen.tscn")
	var summary: Control = summary_scene.instantiate()
	summary.set_outcome(true)
	add_child(summary)
	await get_tree().process_frame

	# Check that Leaderboard placement plate was added to panel stack
	var stack: VBoxContainer = summary._title_label.get_parent()
	var found_ldr_plate: bool = false
	var found_ldr_button: bool = false
	for child in stack.get_children():
		if child is PanelContainer and child != summary._panel:
			found_ldr_plate = true
		if child is Button and child.text.contains("LEADERBOARD"):
			found_ldr_button = true
	assert(found_ldr_plate, "RunSummaryScreen must feature Global Leaderboard placement card")
	assert(found_ldr_button, "RunSummaryScreen must feature dedicated View Leaderboard button")

	summary.queue_free()
	await get_tree().process_frame

	# 2. Test TitleScreen integration
	var title_scene: PackedScene = load("res://scenes/title_screen.tscn")
	var title: Control = title_scene.instantiate()
	add_child(title)
	await get_tree().process_frame

	var title_stack: Control = title._menu_column
	var found_title_ldr_btn: bool = false
	for child in title_stack.get_children():
		if child is Button and child.text == "LEADERBOARDS":
			found_title_ldr_btn = true
	assert(found_title_ldr_btn, "TitleScreen menu column must include LEADERBOARDS button")

	title.queue_free()
	await get_tree().process_frame
	print("INTEGRATION_OK: RunSummaryScreen and TitleScreen buttons verified.")
