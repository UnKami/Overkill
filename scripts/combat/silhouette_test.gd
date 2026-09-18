extends Node
## Render and motion acceptance for the mounted armor and bounded attack shift.
var battle: CombatController
var frames: Array[float] = []
var measuring: bool = false

func _process(delta: float) -> void:
	if measuring: frames.append(delta * 1000.0)

func _ready() -> void:
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = false
	get_window().size = Vector2i(1920,1080)
	RunManager.start_new_run([],[],80,1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	await get_tree().create_timer(2.0).timeout
	var stage: DirectedArena = battle._stage
	await capture("idle")
	check_armor(stage.enemy)
	measuring = true
	await get_tree().create_timer(3.0).timeout
	measuring = false
	frames.sort()
	print("SILHOUETTE_PERF median_ms=",frames[frames.size()/2]," p95_ms=",frames[int(frames.size()*0.95)]," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	for from_player: bool in [true,false]:
		var actor: RiggedCombatant = stage.player if from_player else stage.enemy
		stage.attack(from_player)
		await get_tree().create_timer(0.19).timeout
		assert(absf(actor._model.position.z) <= 0.07)
		actor._animation.pause()
		await capture("player-windup" if from_player else "sentinel-windup")
		# Restart so PNG capture time cannot shift the actual contact measurement.
		stage.attack(from_player)
		await stage.await_contact(from_player)
		check_armor(stage.enemy)
		var contact: Vector3 = actor._weapon.to_global(Vector3(0,0.05,1.14 if from_player else 0.82))
		var gap: float = contact.distance_to(stage.contact_point(not from_player))
		print("STRIKE_GAP ",from_player," ",gap," clip_time=",actor._animation.current_animation_position)
		assert(gap < 0.25,"Weapons must meet the opponent at the damage event")
		stage.impact(not from_player,false)
		await capture("player-impact" if from_player else "sentinel-impact")
		await get_tree().create_timer(0.8).timeout
		assert(is_zero_approx(actor._model.position.z),"Attack translation must settle, including repeated actions")
	AudioManager.reduced_motion = true
	stage.attack(true)
	await get_tree().create_timer(0.2).timeout
	assert(is_zero_approx(stage.player._model.position.z))
	stage.impact(false,true)
	await get_tree().create_timer(0.6).timeout
	assert(stage._sparks.is_empty())
	AudioManager.reduced_motion = false
	get_window().size = Vector2i(1280,720)
	await get_tree().create_timer(0.3).timeout
	await capture("compact")
	print("SILHOUETTE_OK: mounted armor bounds, outward faces, repeated strikes, settled root, reduced motion and cleanup")
	get_tree().quit()

func check_armor(actor: RiggedCombatant) -> void:
	var count: int = 0
	for anchor: Node in actor._skeleton.get_children():
		if not anchor is BoneAttachment3D: continue
		if not String(anchor.bone_name).begins_with("shoulder"): continue
		for piece: Node in anchor.find_children("*","MeshInstance3D",true,false):
			var center: Vector3 = piece.to_global(piece.get_aabb().get_center())
			assert(center.distance_to(anchor.global_position) < 0.42,"Armor must stay near its shoulder, not across the body")
			var arrays: Array = piece.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			for i: int in range(0,vertices.size(),3):
				var cross: Vector3 = (vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i])
				if cross.length_squared() > 0.000000001:
					assert(cross.dot(normals[i]) < 0.0,"Godot front faces need clockwise winding")
			count += 1
	assert(count == 8,"Both layered shoulder assemblies must exist")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://silhouette-016")
	get_viewport().get_texture().get_image().save_png("user://silhouette-016/"+label+".png")
