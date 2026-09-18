extends Node
var battle: CombatController

func _ready() -> void:
	AudioManager.set_master_volume(0)
	RunManager.start_new_run([], [], 80, 150)
	get_window().size = Vector2i(1920,1080)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("act1_boss").duplicate()
	enemy.max_hp = 1000
	battle.start_combat([enemy])
	assert(battle._stage is DirectedArena)
	await get_tree().create_timer(1.5).timeout
	await capture("idle")
	battle._clear_pedestals()
	battle._resolving = true
	battle.player_hp = 60
	battle.player_block = 5
	battle.enemy_block = 2
	var socket: ClockSocketData = battle.player_sockets[0]
	socket.slotted_relic = ContentDatabase.get_clock_relic("REL-13")
	battle._apply_damage_to_enemy(3, socket)
	await get_tree().create_timer(0.39).timeout
	assert(battle.enemy_hp == 999 and battle.enemy_block == 0 and battle.player_hp == 61)
	assert(has_feedback("HP") and has_feedback("BLOCKED") and has_feedback("HEAL"))
	await capture("lifesteal-impact")
	await get_tree().create_timer(0.6).timeout
	battle._apply_damage_to_player(4, battle.enemy_sockets[0])
	await get_tree().create_timer(0.39).timeout
	assert(battle.player_hp == 61 and battle.player_block == 1)
	assert(has_feedback("BLOCKED"))
	await capture("guard-impact")
	await get_tree().create_timer(0.6).timeout
	AudioManager.reduced_motion = true
	battle._stage.guard_pulse(true)
	await capture("reduced-motion")
	get_window().size = Vector2i(1280,720)
	await get_tree().create_timer(0.2).timeout
	await capture("compact")
	AudioManager.reduced_motion = false
	print("CINEMATIC_FINISH_OK: rendered materials, labeled HP/block/heal, unchanged damage, world-space guard, reduced motion and 720p")
	get_tree().quit()

func has_feedback(kind: String) -> bool:
	for child: Node in battle.get_children():
		if child is DamageNumber and child.get_meta("feedback_kind", "") == kind: return true
	return false

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://cinematic-015")
	get_viewport().get_texture().get_image().save_png("user://cinematic-015/" + label + ".png")
