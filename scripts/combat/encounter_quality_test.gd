extends Node

func _ready() -> void:
	AudioManager.set_master_volume(0)
	var before: int = AudioManager.get_child_count()
	AudioManager.play_combat_sound("strike")
	assert(AudioManager.get_child_count() == before, "Muted combat must allocate no voices")
	AudioManager.set_master_volume(1)
	for i: int in 24:
		AudioManager.play_combat_sound("guard" if i % 2 == 0 else "strike")
	assert(AudioManager._voices.size() == 8, "Combat voices must stay bounded")
	AudioManager.set_sfx_volume(0)
	for voice: AudioStreamPlayer in AudioManager._voices:
		assert(voice.volume_db <= -80, "Changing SFX volume must affect active voices")
	await get_tree().create_timer(1.0).timeout
	assert(AudioManager._voices.is_empty(), "Finished combat voices must be released")
	AudioManager.set_sfx_volume(1)
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = false
	var stage: DirectedArena = DirectedArena.new()
	stage._kind = "sentinel"
	stage.size = Vector2(1920, 976)
	add_child(stage)
	await get_tree().process_frame
	var actor: RiggedCombatant = stage.player
	var animation: AnimationPlayer = actor._animation
	animation.play("execution_cut", 0)
	animation.pause()
	var foot: int = actor._skeleton.find_bone("foot.L")
	var initial: Vector3 = Vector3.ZERO
	for t: float in [0.0, 0.15, 0.32, 0.45, 0.75]:
		animation.seek(t, true)
		actor._skeleton.force_update_all_bone_transforms()
		var position: Vector3 = actor._skeleton.get_bone_global_pose(foot).origin
		if t == 0.0: initial = position
		assert(position.distance_to(initial) < 0.12, "Authored attack must retain planted feet")
	for fast: bool in [false, true]:
		AudioManager.fast_mode = fast
		for from_player: bool in [true, false]:
			actor = stage.player if from_player else stage.enemy
			stage.attack(from_player)
			await stage.await_contact(from_player)
			var length: float = 1.14 if from_player else 0.82
			var tip: Vector3 = actor._weapon.to_global(Vector3(0, 0.05, length))
			assert(tip.distance_to(stage.contact_point(not from_player)) < 0.25)
			stage.impact(not from_player, true)
			await get_tree().create_timer(0.8).timeout
			assert(is_zero_approx(actor._model.position.z))
	print("ENCOUNTER_018_OK: muted allocation, bounded voices, live volume, cleanup, planted feet, normal/fast weapon contact")
	get_tree().quit()

