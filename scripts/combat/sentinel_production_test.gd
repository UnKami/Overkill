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
	measuring = true
	await get_tree().create_timer(3.0).timeout
	measuring = false
	frames.sort()
	print("SENTINEL_PRODUCTION_PERF median_ms=",frames[frames.size()/2]," p95_ms=",frames[int(frames.size()*0.95)]," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
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
		check_model(stage.enemy)
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

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://sentinel-019")
	get_viewport().get_texture().get_image().save_png("user://sentinel-019/"+label+".png")
