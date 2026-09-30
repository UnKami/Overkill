extends Node
## Run the companion scene for deterministic presentation and input-regression checks.
var battle: CombatController

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	seed(42)
	# Keep this input-flow smoke deterministic and quick; the human-facing
	# default cadence is intentionally slower for impact readability.
	AudioManager.fast_mode = true
	AudioManager.set_master_volume(0.0)
	assert(is_equal_approx(AudioManager.clock_animation_speed_scale(), 2.0), "Fast Mode must preserve accelerated hand travel")
	assert(is_equal_approx(AudioManager.combat_animation_speed_scale(), 2.0), "Fast Mode must accelerate combat feedback")
	AudioManager.fast_mode = false
	assert(is_equal_approx(AudioManager.clock_animation_speed_scale(), 1.0), "Normal hand travel must remain crisp")
	assert(is_equal_approx(AudioManager.combat_animation_speed_scale(), 0.5), "Normal impacts must retain deliberate pacing")
	AudioManager.fast_mode = true
	var standard_relic := ClockRelicData.new()
	standard_relic.base_damage = 6
	var standard_profile := AttackPresentation.for_relic(standard_relic)
	var combo_relic := ClockRelicData.new()
	combo_relic.base_damage = 4
	combo_relic.hits = 2
	var combo_profile := AttackPresentation.for_relic(combo_relic)
	assert(combo_profile.anticipation < standard_profile.anticipation and combo_profile.recovery < standard_profile.recovery, "Multi-hit attacks need a quicker, clearly separate rhythm")
	var heavy_relic := ClockRelicData.new()
	heavy_relic.base_damage = 12
	var heavy_profile := AttackPresentation.for_relic(heavy_relic)
	assert(heavy_profile.anticipation > standard_profile.anticipation and heavy_profile.travel_pixels > standard_profile.travel_pixels, "Heavy strikes need more wind-up and travel")
	var light_intent := ClockSocketData.new()
	light_intent.intent_damage = 4
	var heavy_intent := ClockSocketData.new()
	heavy_intent.intent_damage = 12
	var flurry_intent := ClockSocketData.new()
	flurry_intent.intent_damage = 12
	flurry_intent.intent_hits = 2
	var enemy_fast_profile := AttackPresentation.for_enemy(light_intent)
	var enemy_heavy_profile := AttackPresentation.for_enemy(heavy_intent)
	var enemy_flurry_profile := AttackPresentation.for_enemy(flurry_intent)
	assert(enemy_heavy_profile.anticipation > enemy_fast_profile.anticipation and enemy_heavy_profile.shake > enemy_fast_profile.shake, "Dangerous enemy blows need a stronger tell and impact")
	assert(enemy_flurry_profile.id == "enemy_flurry" and enemy_flurry_profile.recovery < enemy_fast_profile.recovery, "Enemy multi-hit intents need a distinct quicker rhythm")
	AudioManager.play_clock_sound("tick")
	assert(AudioManager._clock_sounds.is_empty(), "Muted audio must not allocate a voice")
	RunManager.start_new_run([], [], 80, 42)
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
	# High health fixtures exercise the complete 9-hour assembly and wrap.
	battle.player_hp = 10000
	for hour in range(2, 10):
		for i: int in 9:
			assert(battle.enemy_sockets[i].intent_revealed == (i < hour), "Reveal before placement; retain previous actions")
		await battle._on_phase_one_relic_chosen(battle.current_draft_selection[0])
	await get_tree().create_timer(0.8).timeout
	assert(battle.phase == CombatController.Phase.QUADRANT)
	assert(battle.turn_number == 10)
	assert(battle.current_drawn_relic != null, "The real run inventory must leave reserves")
	assert(battle.player_deck.size() + battle.player_discard.size() == 2)
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
	assert(battle.active_quadrant == 1)
	var previous_rotation := battle._player_chrono._center_hand_pivot.rotation
	AudioManager.fast_mode = false
	var normal_start_usec: int = Time.get_ticks_usec()
	await battle._player_chrono.snap_hand_to_hour(2)
	var normal_snap_usec: int = Time.get_ticks_usec() - normal_start_usec
	AudioManager.fast_mode = true
	var fast_start_usec: int = Time.get_ticks_usec()
	await battle._player_chrono.snap_hand_to_hour(3)
	var fast_snap_usec: int = Time.get_ticks_usec() - fast_start_usec
	assert(fast_snap_usec < normal_snap_usec * 0.8, "Clock travel in Fast Mode should be perceptibly quicker")
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
	await get_tree().create_timer(1.0).timeout
	assert(wins.size() == 1, "Victory must be emitted once")
	print("CLOCK_SMOKE_OK: 9 assembly hours, double input, 3 sectors, hot swap, forward wrap, single victory signal, muted audio")
	get_tree().quit()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/clock-battle")
	get_viewport().get_texture().get_image().save_png("res://artifacts/clock-battle/%s.png" % label)
