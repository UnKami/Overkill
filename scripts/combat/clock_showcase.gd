extends Node
## Render QA for battle poses and progression screens, using an isolated test profile.
func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	seed(1729)
	AudioManager.set_master_volume(0)
	RunManager.start_new_run([], [], 80, 1729)
	var battle: CombatController = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act3_boss")])
	await get_tree().create_timer(1.4).timeout
	await capture("polished-boss")
	battle._stage.attack(true)
	await get_tree().create_timer(0.17).timeout
	battle._stage.impact(false, false)
	await capture("polished-attack")
	await get_tree().create_timer(0.6).timeout
	# Inspect every authored pose for cell bleeding and crop defects.
	for pose in range(8):
		battle._stage.player.set_pose(pose)
		battle._stage.enemy.set_pose(pose)
		await get_tree().create_timer(0.08).timeout
		await capture("pose-%d" % pose)
	battle.queue_free()
	await get_tree().process_frame
	OKRunState.current_ok = 90
	for mode in ["shop", "collection", "upgrade"]:
		var screen := preload("res://scripts/ui/clock_collection_screen.gd").new()
		screen.mode = mode
		add_child(screen)
		await get_tree().create_timer(0.5).timeout
		await capture("polished-" + mode)
		screen.queue_free()
		await get_tree().process_frame
	print("SHOWCASE_RENDER_OK: boss, attack, eight poses, shop, collection, forge")
	get_tree().quit()

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/clock-battle")
	get_viewport().get_texture().get_image().save_png("res://artifacts/clock-battle/%s.png" % label)
