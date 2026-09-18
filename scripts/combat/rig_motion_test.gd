extends Node

func _ready() -> void:
	AudioManager.fast_mode = false
	var stage := DirectedArena.new()
	stage.size = Vector2(1920,776)
	add_child(stage)
	await get_tree().process_frame
	var actor: RiggedCombatant = stage.player
	var animation := actor._animation
	assert(animation.get_animation_list().size() >= 5)
	animation.play("execution_cut",0)
	animation.pause()
	var foot := actor._skeleton.find_bone("foot.L")
	var initial := Vector3.ZERO
	for t in [0.0,0.15,0.32,0.45,0.75]:
		animation.seek(t,true)
		await get_tree().process_frame
		var position := actor._skeleton.get_bone_global_pose(foot).origin
		if t==0.0: initial=position
		print("PLANTED_FOOT ",t," drift=",position.distance_to(initial))
		assert(position.distance_to(initial)<0.12,"Attack foot must stay near its planted position")
		if t==0.32:
			print("STRIKE_POSE_OK")
	actor.attack()
	await get_tree().create_timer(0.32).timeout
	var distance := actor._weapon.to_global(Vector3(0,0.05,1.1)).distance_to(stage.enemy.global_position+Vector3(0,1.45,0))
	print("CONTACT_DISTANCE ",distance)
	assert(distance < 0.6,"Weapon must reach the opponent's silhouette at impact")
	AudioManager.reduced_motion = true
	stage.attack(true)
	stage.impact(false,false)
	assert(is_zero_approx(stage._camera.h_offset))
	assert(is_equal_approx(stage._camera.fov,32))
	await get_tree().create_timer(0.6).timeout
	assert(stage._sparks.is_empty(),"Impact particles must be released")
	stage.finish(true)
	assert(stage.enemy._dead)
	print("RIG_MOTION_OK: five clips, planted feet, reduced camera motion, particle cleanup, death state")
	get_tree().quit()
