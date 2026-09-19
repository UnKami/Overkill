extends Node
## Render and motion acceptance for the mounted armor and bounded attack shift.
var battle: CombatController
var frames: Array[float] = []
var measuring: bool = false

func _process(delta: float) -> void:
	if measuring: frames.append(delta * 1000.0)

func _ready() -> void:
	check_mixed_weapon_geometry()
	AudioManager.set_master_volume(0)
	AudioManager.fast_mode = false
	get_window().size = Vector2i(1920,1080)
	RunManager.start_new_run([],[],80,1729)
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	battle.start_combat([ContentDatabase.get_enemy("act1_boss")])
	await get_tree().create_timer(2.0).timeout
	var stage: DirectedArena = battle._stage
	var hours: MultiMeshInstance3D = stage._world.get_node("FloorMajorHours")
	var minor_ticks: MultiMeshInstance3D = stage._world.get_node("FloorMinorTicks")
	assert(hours.multimesh.instance_count == 9)
	assert(minor_ticks.multimesh.instance_count == 27)
	var architecture: Node3D = stage._world.get_node("CathedralArchitecture")
	assert(architecture.get_child_count() == 2, "Architecture must retain two instanced batches")
	var pier: MultiMeshInstance3D = architecture.get_node("Clustered stone piers")
	var arrays: Array = pier.multimesh.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	# Side normals must point out of the column, not into its hollow center.
	var side_vertex: int = 6 * 48
	assert(normals[side_vertex].dot(Vector3(positions[side_vertex].x,0,positions[side_vertex].z)) > 0)
	print("CATHEDRAL_STAGE_OK: nine floor hours, two architectural batches, outward pier normals")
	await capture("idle")
	if DisplayServer.get_name() != "headless":
		var engraving: Control = battle._player_chrono._engraving
		var cache: SubViewport = engraving._engraving_cache
		var prior: PackedByteArray = cache.get_texture().get_image().get_data()
		# Godot's node getter retains UPDATE_ONCE; verify the pixels actually stay cached.
		engraving._static.modulate = Color.GREEN
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(cache.get_texture().get_image().get_data() == prior, "Static cache must not redraw without invalidation")
		engraving._static.modulate = Color.WHITE
		var original: Color = engraving.accent
		engraving.accent = Color.RED
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		assert(cache.get_texture().get_image().get_data() != prior, "Faction color changes must invalidate the cache")
		engraving.accent = original

	check_model(stage.enemy)
	for actor: RiggedCombatant in [stage.player,stage.enemy]:
		var materials: Dictionary = {}
		for piece: Node in actor._weapon.get_children():
			assert(piece is MeshInstance3D)
			assert(not materials.has(piece.material_override), "Weapon finish must use one mesh per material")
			materials[piece.material_override] = true
		assert(materials.size() == 4, "Weapon must retain grip, steel, trim and luminous/blade finish")
	print("WEAPON_BATCH_OK: four retained finishes per weapon")
	measuring = true
	await get_tree().create_timer(3.0).timeout
	measuring = false
	frames.sort()
	print("SENTINEL_PRODUCTION_PERF median_ms=",frames[frames.size()/2]," p95_ms=",frames[int(frames.size()*0.95)]," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	for from_player: bool in [true,false]:
		var actor: RiggedCombatant = stage.player if from_player else stage.enemy
		stage.attack(from_player)
		await get_tree().create_timer(actor._retimed_attack_time(0.19)).timeout
		assert(absf(actor._model.position.z) <= 0.07)
		actor.set_process(false)
		actor._animation.pause()
		await capture("player-windup" if from_player else "sentinel-windup")
		actor.set_process(true)
		# Restart so PNG capture time cannot shift the actual contact measurement.
		stage.attack(from_player)
		await stage.await_contact(from_player)
		check_model(stage.enemy)
		var contact: Vector3 = actor._weapon.to_global(Vector3(0,0.05,1.14 if from_player else 0.82))
		var gap: float = contact.distance_to(stage.contact_point(not from_player))
		print("STRIKE_GAP ",from_player," ",gap," clip_time=",actor._animation.current_animation_position)
		assert(gap < 0.25,"Weapons must meet the opponent at the damage event")
		stage.impact(not from_player,false)
		await capture("player-impact" if from_player else "sentinel-impact")
		await get_tree().create_timer(0.8).timeout
		assert(is_zero_approx(actor._model.position.z),"Attack translation must settle, including repeated actions")
	var defender: RiggedCombatant = stage.enemy
	var left_foot: int = defender._skeleton.find_bone("foot.L")
	var left_hand: int = defender._skeleton.find_bone("hand.L")
	var initial_foot: Vector3 = defender._skeleton.get_bone_global_pose(left_foot).origin
	var initial_hand: Vector3 = defender._skeleton.get_bone_global_pose(left_hand).origin
	var head_index: int = defender._skeleton.find_bone("head")
	var initial_head: Vector3 = defender._skeleton.get_bone_global_pose(head_index).origin
	var brace_direction: Vector3 = Vector3.ZERO
	for repeat: int in 2:
		defender.hit(true)
		await get_tree().create_timer(0.10).timeout
		defender._skeleton.force_update_all_bone_transforms()
		assert(defender._skeleton.get_bone_global_pose(left_foot).origin.distance_to(initial_foot) < 0.025, "Bracing must keep the supporting foot planted")
		assert(defender._skeleton.get_bone_global_pose(left_hand).origin.distance_to(initial_hand) > 0.07, "Guard must visibly change the off-hand pose")
		if repeat == 0:
			brace_direction = defender._skeleton.get_bone_global_pose(head_index).origin-initial_head
			defender.set_process(false)
			defender._animation.pause()
			await capture("sentinel-guard")
			defender.set_process(true)
			defender.hit(true)
	await get_tree().create_timer(0.65).timeout
	assert(defender._animation.current_animation == defender._clip("combat_idle"), "Repeated guards must recover to idle")
	print("SENTINEL_GUARD_OK: distinct off-hand brace, planted foot and repeated-hit recovery")
	for fast: bool in [false,true]:
		AudioManager.fast_mode = fast
		# A fresh hit must interrupt an existing brace and recover cleanly.
		defender.hit(true)
		await get_tree().create_timer(0.06/AudioManager.animation_speed_scale()).timeout
		defender.hit(false)
		await get_tree().create_timer(0.10/AudioManager.animation_speed_scale()).timeout
		defender._skeleton.force_update_all_bone_transforms()
		var recoil_direction: Vector3 = defender._skeleton.get_bone_global_pose(head_index).origin-initial_head
		assert(recoil_direction.length() > 0.05, "Unguarded hit needs readable upper-body recoil")
		assert(recoil_direction.dot(brace_direction) < 0.0, "A hit must recoil away from the forward guard brace")
		assert(defender._skeleton.get_bone_global_pose(left_foot).origin.distance_to(initial_foot) < 0.025, "Impact must not slide the supporting foot")
		if not fast:
			defender.set_process(false)
			defender._animation.pause()
			await capture("sentinel-recoil")
			defender.set_process(true)
			defender.hit(false)
		await get_tree().create_timer(0.65/AudioManager.animation_speed_scale()).timeout
		assert(defender._animation.current_animation == defender._clip("combat_idle"), "Recoil must settle after interruption and repeated impacts")
	AudioManager.fast_mode = false
	print("SENTINEL_RECOIL_OK: opposite guard/hit directions, planted foot, normal/fast interruption recovery")
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
	if DisplayServer.get_name() != "headless":
		get_window().size = Vector2i(1920,1080)
		for child: Node in battle.get_children():
			if child is CanvasItem and child != stage: child.hide()
		stage.player.hide()
		stage._camera.v_offset = 0.0
		stage._camera.fov = 40
		stage._camera.position = stage.enemy.position + Vector3(-2.2,1.8,3.2)
		stage._camera.look_at(stage.enemy.position + Vector3.UP * 1.2)
		await get_tree().create_timer(0.3).timeout
		await capture("material-cool")
		for light: Node in stage._world.get_children():
			if light is DirectionalLight3D: light.light_color = Color("ffcf9c")
		await get_tree().create_timer(0.3).timeout
		await capture("material-warm")
	print("SENTINEL_PRODUCTION_OK: original mesh, four surfaces, skinning, repeated strikes, contact, reduced motion, cleanup and framing")
	get_tree().quit()

func check_model(actor: RiggedCombatant) -> void:
	var meshes: Array[Node] = actor._model.find_children("*", "MeshInstance3D", true, false)
	var body: Array[MeshInstance3D] = []
	for candidate: MeshInstance3D in meshes:
		assert(not String(candidate.name).begins_with("Knight_"))
		if candidate.skin != null: body.append(candidate)
	assert(body.size() == 1, "Sentinel must have one authored skinned body")
	var mesh: MeshInstance3D = body[0]
	assert(mesh.mesh.get_surface_count() == 4)
	assert(mesh.skin != null, "Sentinel body must be skinned to the combat rig")
	assert(actor._skeleton.find_bone("hand.R") >= 0)
	for surface: int in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		assert(not (arrays[Mesh.ARRAY_BONES] as PackedInt32Array).is_empty())
		var source: Material = mesh.mesh.surface_get_material(surface)
		if source.resource_name in ["Sentinel_Iron", "Sentinel_Bronze"]:
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			assert(not colors.is_empty(), "Authored wear must survive the model export")
			var minimum: float = 1.0
			var maximum: float = 0.0
			var cavity_min: float = 1.0
			var cavity_max: float = 0.0
			for color: Color in colors:
				minimum = minf(minimum, color.r)
				maximum = maxf(maximum, color.r)
				cavity_min = minf(cavity_min, color.b)
				cavity_max = maxf(cavity_max, color.b)
			assert(minimum < 0.1 and maximum > 0.9, "Both plate faces and exposed bevels need authored mask values")
			assert(cavity_min < 0.9 and cavity_max > 0.9, "Baked cavity visibility must survive export")
			assert(mesh.get_surface_override_material(surface) is ShaderMaterial)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://sentinel-019")
	get_viewport().get_texture().get_image().save_png("user://sentinel-019/"+label+".png")

func check_mixed_weapon_geometry() -> void:
	var fixture: Node3D = Node3D.new()
	add_child(fixture)
	var finish: StandardMaterial3D = StandardMaterial3D.new()
	var box: BoxMesh = BoxMesh.new()
	ForgedArmor.add_mesh(fixture,box,finish)
	var triangle: SurfaceTool = SurfaceTool.new()
	triangle.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in [Vector3(3,0,0),Vector3(4,0,0),Vector3(3,1,0)]: triangle.add_vertex(point)
	triangle.generate_normals()
	var plate: MeshInstance3D = ForgedArmor.add_mesh(fixture,triangle.commit(),finish)
	plate.position = Vector3(2,0,0)
	ForgedArmor.combine_finish(fixture)
	assert(fixture.get_child_count() == 1)
	var combined: MeshInstance3D = fixture.get_child(0)
	var arrays: Array = combined.mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert(indices.size() == 39, "All twelve indexed box triangles and the authored triangle must survive")
	assert(is_equal_approx(combined.mesh.get_aabb().end.x,6.0), "Baking must preserve each piece transform")
	fixture.queue_free()
	print("MIXED_GEOMETRY_OK: indexed and non-indexed pieces retain all triangles and placement")
