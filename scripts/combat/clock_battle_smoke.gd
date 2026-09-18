extends Node
## Run the companion scene for deterministic presentation and input-regression checks.
var battle: CombatController

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	seed(42)
	AudioManager.set_master_volume(0.0)
	AudioManager.play_clock_sound("tick")
	assert(AudioManager._clock_sounds.is_empty(), "Muted audio must not allocate a voice")
	RunManager.current_hp = 80
	RunManager.max_hp = 80
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy := EnemyData.new()
	enemy.id = "boneghoul"
	enemy.display_name = "The Hollow Warden"
	enemy.max_hp = 800
	battle.start_combat([enemy])
	await get_tree().create_timer(1.3).timeout
	await capture("assembly")
	var chosen := battle.current_draft_selection[0]
	battle._on_phase_one_relic_chosen(chosen)
	battle._on_phase_one_relic_chosen(chosen)
	await get_tree().create_timer(2.0).timeout
	assert(battle.turn_number == 2, "Double-click must resolve only one hour")
	assert(battle.player_sockets[0].slotted_relic == chosen)
	# High health fixtures exercise the complete 12-hour assembly and wrap.
	battle.player_hp = 10000
	for hour in range(2, 13):
		await battle._on_phase_one_relic_chosen(battle.current_draft_selection[0])
	await get_tree().create_timer(0.8).timeout
	assert(battle.phase == CombatController.Phase.QUADRANT)
	assert(battle.turn_number == 13)
	assert(battle.current_drawn_relic != null, "The real run inventory must leave reserves")
	assert(battle.player_deck.size() + battle.player_discard.size() == 5)
	battle.player_hp = 66
	battle._update_stats_display()
	await capture("quadrant")
	battle.player_hp = 10000
	await battle._on_skip_button_pressed()
	assert(battle.active_quadrant == 2)
	# Use the actual drawn reserve; do not inject a test-only relic.
	var reserve := battle.current_drawn_relic
	assert(reserve != null)
	await battle._on_player_socket_pressed(4, battle._player_chrono.get_socket_view(4))
	assert(battle.active_quadrant == 3)
	assert(battle.player_sockets[3].slotted_relic == reserve)
	# Exercise forward wrap.
	await battle._on_skip_button_pressed()
	await battle._on_skip_button_pressed()
	assert(battle.active_quadrant == 1)
	var previous_rotation := battle._player_chrono._center_hand_pivot.rotation
	await battle._player_chrono.snap_hand_to_hour(1)
	assert(battle._player_chrono._center_hand_pivot.rotation > previous_rotation)
	get_window().size = Vector2i(1280, 720)
	battle.player_hp = 61
	battle._update_stats_display()
	await get_tree().create_timer(0.4).timeout
	await capture("compact")
	var wins: Array[bool] = []
	battle.combat_won.connect(func(_enemies: Array[EnemyData]) -> void: wins.append(true))
	battle.enemy_hp = 0
	assert(battle._check_combat_end())
	assert(battle._check_combat_end())
	await get_tree().create_timer(1.6 if battle._stage is DirectedArena else 1.0).timeout
	assert(wins.size() == 1, "Victory must be emitted once")
	print("CLOCK_SMOKE_OK: 12 assembly hours, double input, 4 quadrants, hot swap, forward wrap, single victory signal, muted audio")
	get_tree().quit()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/clock-battle")
	get_viewport().get_texture().get_image().save_png("res://artifacts/clock-battle/%s.png" % label)
