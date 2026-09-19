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
	var hero_clip: Animation = stage.player._animation.get_animation(stage.player._clip("execution_cut"))
	var heavy_clip: Animation = stage.enemy._animation.get_animation(stage.enemy._clip("execution_cut"))
	assert(hero_clip.length < 0.8 and heavy_clip.length > 1.0, "Enemy retiming must not mutate the hero's shared clip")
	assert(is_equal_approx(stage.player.contact_time(), 0.32))
	assert(is_equal_approx(stage.enemy.contact_time(), 0.46))
	assert(is_equal_approx(stage.enemy.recovery_time(), 0.62))
	for track: int in heavy_clip.get_track_count():
		var prior_time: float = -1.0
		for key: int in heavy_clip.track_get_key_count(track):
			var key_time: float = heavy_clip.track_get_key_time(track, key)
			assert(key_time > prior_time and key_time <= heavy_clip.length + 0.00001)
			prior_time = key_time
	stage.enemy._animation.play(stage.enemy._clip("execution_cut"), 0.0)
	stage.enemy._animation.advance(0.0)
	stage.enemy._animation.seek(0.32, true)
	assert(not stage.enemy.at_contact(), "Sentinel must remain in anticipation after the hero's contact time")
	stage.enemy._animation.seek(0.46, true)
	assert(stage.enemy.at_contact())
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
	print("ENCOUNTER_018_OK: muted allocation, bounded voices, live volume, cleanup, planted feet, normal/fast weapon contact, isolated heavy timing and ordered animation keys")
	get_tree().quit()

