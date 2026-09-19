extends Node
var battle: CombatController

func _ready() -> void:
	AudioManager.set_master_volume(0)
	get_window().size = Vector2i(1920,1080)
	for won: bool in [true,false]:
		for fast: bool in [false,true]:
			for reduced: bool in [false,true]:
				await check_finish(won,fast,reduced)
	print("FINISH_SEQUENCE_OK: victory/defeat, single handoff, terminal death, normal/fast/reduced modes")
	get_tree().quit()

func check_finish(won: bool, fast: bool, reduced: bool) -> void:
	AudioManager.fast_mode = fast
	AudioManager.reduced_motion = reduced
	RunManager.start_new_run([],[],80,1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	await get_tree().create_timer(0.4).timeout
	var stage: DirectedArena = battle._stage
	var fallen: RiggedCombatant = stage.enemy if won else stage.player
	var survivor: RiggedCombatant = stage.player if won else stage.enemy
	var supporting_foot: Vector3 = bone_position(fallen,"foot.L")
	var starting_head: Vector3 = bone_position(fallen,"head")
	var observed: Dictionary = {"won":0,"lost":0}
	battle.combat_won.connect(func(_enemies: Array) -> void: observed.won += 1)
	battle.combat_lost.connect(func() -> void: observed.lost += 1)
	battle._clear_pedestals()
	battle._resolving = true
	# Apply a real lethal combat action, then use the resolver's end check.
	if won:
		battle.enemy_hp = 1
		battle.enemy_block = 0
		await battle._apply_damage_to_enemy(6,battle.player_sockets[0])
	else:
		battle.player_hp = 1
		battle.player_block = 0
		await battle._apply_damage_to_player(6,battle.enemy_sockets[0])
	var starting_fov: float = stage._camera.fov
	assert(battle._check_combat_end())
	assert(battle._check_combat_end(), "Repeated end checks must not restart the finish")
	assert(fallen._dead and not survivor._dead)
	assert(not battle._guidance.visible)
	battle._refresh_guidance()
	assert(not "NEXT" in battle._intent_readout.text)
	assert(battle._player_chrono._engraving.active_hour == 0 and battle._enemy_chrono._engraving.active_hour == 0)
	var death_clip: String = fallen._animation.current_animation
	var spark_count: int = stage._sparks.size()
	stage.impact(not won,false)
	stage.finish(not won)
	assert(fallen._animation.current_animation == death_clip and not survivor._dead, "Late presentation events must not alter the terminal result")
	assert(stage._sparks.size() == spark_count, "No fresh impact effects after defeat")
	assert(observed.won+observed.lost == 0, "Rewards must not interrupt the death animation")
	await get_tree().create_timer(0.75).timeout
	assert(observed.won+observed.lost == 0)
	for light_material: StandardMaterial3D in fallen._emissive_materials:
		assert(is_zero_approx(light_material.emission_energy_multiplier), "Defeated core and weapon lights must extinguish")
	for light_material: StandardMaterial3D in survivor._emissive_materials:
		assert(light_material.emission_energy_multiplier > 0.0, "Power-down must not modify the survivor's materials")
	if reduced: assert(is_equal_approx(stage._camera.fov,starting_fov), "Reduced motion must suppress finish camera movement")
	if not fast and not reduced: await capture("victory" if won else "defeat")
	await get_tree().create_timer(0.85).timeout
	assert(observed.won == (1 if won else 0) and observed.lost == (0 if won else 1))
	assert(fallen._dead)
	assert(fallen._animation.current_animation != fallen._clip("combat_idle"), "Defeated actor must never return to idle")
	if won:
		var right_knee: Vector3 = bone_position(fallen,"shin.R")
		var left_knee: Vector3 = bone_position(fallen,"shin.L")
		print("COLLAPSE_POSE right_knee=",right_knee," left_knee=",left_knee," foot_shift=",bone_position(fallen,"foot.L").distance_to(supporting_foot))
		assert(bone_position(fallen,"foot.L").distance_to(supporting_foot) < 0.03, "Collapse must preserve the supporting foot")
		assert(right_knee.y > 0.04 and right_knee.y < 0.23, "Armored knee must settle near the floor without sinking through it")
		assert(left_knee.y-right_knee.y > 0.15, "Sentinel collapse must have a distinct asymmetric kneel")
		assert(starting_head.y-bone_position(fallen,"head").y > 0.4, "Collapse must visibly lower the heavy body")
		if not fast and not reduced: await capture("sentinel-final-stage",stage._view)
	print("FINISH_MODE_OK won=",won," fast=",fast," reduced=",reduced)
	battle.queue_free()
	await get_tree().process_frame

func bone_position(actor: RiggedCombatant, bone: String) -> Vector3:
	actor._skeleton.force_update_all_bone_transforms()
	return actor._skeleton.get_bone_global_pose(actor._skeleton.find_bone(bone)).origin

func capture(label: String, source: Viewport = null) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://finish-027")
	var viewport: Viewport = source if source != null else get_viewport()
	viewport.get_texture().get_image().save_png("user://finish-027/"+label+".png")
