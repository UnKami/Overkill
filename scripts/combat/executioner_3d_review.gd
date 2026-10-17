extends Control
## Anatomy and skin review on the same live 3D actor used by the arena.
var hero: Executioner3DActor
var anatomy: Executioner3DActor
var _label: Label
var _clock: float = 0
var _current: String = "idle"
var _checks: int = 0
var _failures: int = 0
var _captures: Dictionary = {}
const OUTPUT: String = "res://.test-artifacts/047/review"

func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280,720)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	AudioManager.set_master_volume(0)
	var background := ColorRect.new()
	background.color = Color("18212a")
	background.size = Vector2(1920,1080)
	add_child(background)
	_label = Label.new()
	_label.position = Vector2(40,25)
	_label.add_theme_font_size_override("font_size",30)
	add_child(_label)
	for i: int in 2:
		var actor := Executioner3DActor.new()
		actor.anatomy_only = i==1
		actor.position = Vector2(60+i*920,40)
		actor.size = Vector2(820,930)
		actor.target_height = 745
		add_child(actor)
		if i == 0: hero = actor
		else: anatomy = actor;actor.anatomy_review(true)
	await get_tree().process_frame
	print("3D_REVIEW_ACTORS_READY")
	for node: Node in hero.model.find_children("*","AnimationPlayer",true,false):
		var animator: AnimationPlayer = node as AnimationPlayer
		print("EXECUTIONER_NATIVE_ANIMATIONS ",animator.get_animation_list())
		for animation_name: String in animator.get_animation_list():
			if animation_name=="RESET": continue
			var animation: Animation = animator.get_animation(animation_name)
			print("EXECUTIONER_NATIVE_TRACKS ",animation_name," length=",animation.length," count=",animation.get_track_count()," first=",animation.track_get_path(0))
			break
	_check(hero.skeleton.get_bone_count() == 63,"Human, finger, twist and cloth bones are imported")
	for mesh: MeshInstance3D in hero._mesh_nodes: _check(mesh.skin != null,"Every volume mesh is skinned")
	for i: int in hero._indices.size():
		var entry: Dictionary = hero.MOTION.bones[i]
		var r: Array = entry.rest
		var source := Transform3D(Basis(Quaternion(r[3],r[4],r[5],r[6]).normalized()),Vector3(r[0],r[1],r[2]))
		var imported: Transform3D = hero.skeleton.get_bone_rest(hero._indices[i])
		_check(source.origin.distance_to(imported.origin)<.0001,"glTF bone translation matches Blender: "+str(entry.name))
		_check(absf(source.basis.get_rotation_quaternion().dot(imported.basis.get_rotation_quaternion()))>.99999,"glTF bone axes match Blender: "+str(entry.name))
	print("3D_REVIEW_RESTS_CHECKED")
	if OS.get_cmdline_user_args().has("--native-pose-diagnostic"):
		for sample: Array in [["idle",0.0],["iron_strike",2.2]]:
			hero.sample_action_for_review(str(sample[0]),float(sample[1]))
			var local: Array[Transform3D] = hero._local_frame(str(sample[0]),float(sample[1]))
			print("NATIVE_DIAGNOSTIC ",sample," model=",hero.model.transform," skeleton=",hero.skeleton.transform)
			for i: int in hero.MOTION.bones.size():
				if str(hero.MOTION.bones[i].name) not in ["root","pelvis","spine_upper","hand.R"]: continue
				print("NATIVE_BONE ",hero.MOTION.bones[i].name," expected=",local[i]," actual=",hero.skeleton.get_bone_pose(hero._indices[i]))
		get_tree().quit()
		return
	for action: String in hero.MOTION.actions:
		var duration: float = float(hero.MOTION.actions[action].duration)
		for index: int in 21:
			var time: float = duration*index/20.0
			hero.sample_action_for_review(action,time)
			var pure: Transform2D = hero.sample_grip_transform(action,time)
			_check(pure.origin.distance_to(hero.get_hand_global_position())<.01,"Pure 3D grip sampling matches displayed skin")
			for side: String in ["R","L"]:
				var arm: Transform3D = hero._bone_world("upper_arm."+side)
				var elbow: Transform3D = hero._bone_world("forearm."+side)
				var wrist: Transform3D = hero._bone_world("hand."+side)
				_check(arm.origin.distance_to(elbow.origin)>.1,"Upper arm retains volume and length")
				_check(elbow.origin.distance_to(wrist.origin)>.1,"Forearm retains volume and length")
	print("3D_REVIEW_SAMPLES_CHECKED")
	if OS.get_cmdline_user_args().has("--quality-review"):
		await _quality_review()
		get_tree().quit(0 if _failures==0 else 1)
		return
	if OS.get_cmdline_user_args().has("--weapon-contact-review"):
		await _weapon_contact_review()
		get_tree().quit(0 if _failures==0 else 1)
		return
	if OS.get_cmdline_user_args().has("--structural-only"):
		if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
		hero.queue_free();anatomy.queue_free()
		await get_tree().process_frame
		print("EXECUTIONER_3D_REVIEW_OK checks=%d failures=%d" % [_checks,_failures])
		get_tree().quit(0 if _failures==0 else 1)
		return
	hero.set_process(true)
	hero._rest()
	for action: String in ["idle","throw","channel","siphon","iron_strike","twin_left","heavy","bell","block","chalice","crown"]:
		_current = action
		_clock = 0
		hero.play_action(action)
		anatomy.play_action(action)
		while hero._busy or (action=="idle" and _clock<2):
			await get_tree().process_frame
			if _clock>.5 and _clock<.7: await _capture(action+"-prepare")
			var contact: float = float(hero.MOTION.actions[action].contact)
			if contact >= 0 and _clock>=contact and _clock<contact+.12: await _capture(action+"-contact")
		await get_tree().create_timer(.25).timeout
	hero.queue_free()
	anatomy.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("EXECUTIONER_3D_REVIEW_OK checks=%d failures=%d live glTF skin, actual 3D bones and fingers, exact projected grip sampling"%[_checks,_failures])
	get_tree().quit(0 if _failures==0 else 1)

func _process(delta: float) -> void:
	_clock += delta
	if _label != null: _label.text = "LIVE 3D EXECUTIONER / %s / %.2f s     ARMOR + ANATOMY"%[_current.to_upper(),_clock]

func _check(ok: bool,message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(message)

func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless" or _captures.has(label) or OS.get_cmdline_user_args().has("--movie-review"): return
	_captures[label] = true
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+label+".png")

func _weapon_contact_review() -> void:
	set_process(false)
	var output: String = "res://.test-artifacts/047/proper-character"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--review-output="):
			output = argument.trim_prefix("--review-output=").simplify_path()
			assert(output.begins_with("res://.test-artifacts/") or output.begins_with("user://"),"Equipped captures must stay in the isolated QA profile or test artifacts")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var capture_count: int = 0
	for item: Array in [["iron_strike","REL-01","sword"],["twin_left","REL-02","blades"],["heavy","REL-03","hammer"]]:
		var prop := Relic3DView.new()
		add_child(prop)
		prop.configure(hero,str(item[1]),str(item[2]))
		for time: float in [.4,1.5,1.66,1.82,1.94,2.02,2.2,2.4,2.52,2.66,2.8,3.08]:
			hero.sample_action_for_review(str(item[0]),time)
			anatomy.sample_action_for_review(str(item[0]),time)
			prop.present(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,0,0,Vector2.ONE,Vector2.ONE,1,1 if str(item[2])=="blades" else 0,0,true)
			_label.text = "ACTUAL EQUIPPED WEAPON / %s / %.2f s" % [str(item[0]).to_upper(),time]
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path: String = output+"/equipped-%s-%04d.png" % [str(item[0]),roundi(time*1000)]
			_check(get_viewport().get_texture().get_image().save_png(path)==OK,"Save actual equipped weapon pose")
			capture_count += 1
		prop.queue_free()
		await get_tree().process_frame
	print("EXECUTIONER_WEAPON_REVIEW_OK %d native equipped poses / checks=%d failures=%d" % [capture_count,_checks,_failures])

func _quality_review() -> void:
	set_process(false)
	var output: String = "res://.test-artifacts/047/proper-character/quality"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--review-output="):
			output = argument.trim_prefix("--review-output=").simplify_path()
			assert(output.begins_with("res://.test-artifacts/") or output.begins_with("user://"),"Quality captures must stay in the isolated QA profile or test artifacts")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var held := Relic3DView.new()
	add_child(held)
	held.configure(hero,"REL-01","sword")
	var overlay := Relic3DView.new()
	add_child(overlay)
	overlay.configure(hero,"REL-15","bell")
	var sizes: Dictionary = {"high":Vector2i(1200,709),"balanced":Vector2i(900,532),"performance":Vector2i(720,425)}
	var overlay_sizes: Dictionary = {"high":Vector2i(1200,900),"balanced":Vector2i(900,675),"performance":Vector2i(720,540)}
	for pose: Array in [["idle",0.0],["iron_strike",2.2],["block",1.1]]:
		AudioManager.render_quality = "high"
		AudioManager.settings_changed.emit({"render_quality":"high"})
		hero.sample_action_for_review(str(pose[0]),float(pose[1]))
		anatomy.sample_action_for_review(str(pose[0]),float(pose[1]))
		# Compare to the former full-height viewport, not only the new presets.
		hero.camera.size = 4.7
		hero.viewport.size = Vector2i(1200,900)
		hero._update_projection()
		await get_tree().process_frame
		await get_tree().process_frame
		var anchors: Dictionary = {}
		for anchor: String in ["hand","hand_far","head","chest","feet"]: anchors[anchor] = hero.anchor_position(anchor)
		hero.camera.size = 3.7
		hero._quality = ""
		for quality: String in ["high","balanced","performance"]:
			AudioManager.render_quality = quality
			AudioManager.settings_changed.emit({"render_quality":quality})
			await get_tree().process_frame
			await get_tree().process_frame
			_check(hero.viewport.size==sizes[quality],"Character uses the selected render budget")
			_check(overlay.viewport.size==overlay_sizes[quality],"Separate relic retains full-height effect space at selected quality")
			_check(held.viewport==hero.viewport,"Held prop retains the character's depth buffer")
			for mesh: MeshInstance3D in hero._mesh_nodes:
				for surface: int in mesh.mesh.get_surface_count():
					var mat: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
					if mat != null and mat.resource_name.to_lower().contains("painted pbr"):
						_check(mat.normal_enabled and mat.normal_texture != null,"Baked cloth relief remains active at selected quality")
					if mat != null and mat.resource_name.to_lower().contains("woven pbr"):
						_check(is_zero_approx(mat.metallic) and mat.metallic_texture == null,"Woven cloth cannot inherit metallic atlas mip highlights")
						_check(mat.roughness>.85 and mat.normal_enabled,"Cloth retains matte woven relief")
						_check(mat.albedo_texture.get_width()==4096,"Character uses the detailed 4K surface bake")
			for anchor: String in anchors:
				_check(hero.anchor_position(anchor).distance_to(anchors[anchor] as Vector2)<.05,"Quality preserves "+anchor+" screen position")
			var point: Vector2 = hero.get_head_global_position()-Vector2(0,90)
			var world: Vector3 = overlay._world_from_screen(point)
			var projected: Vector2 = hero.get_global_transform()*(overlay._projection_origin()+overlay.camera.unproject_position(world)*overlay._projection_scale())
			_check(projected.distance_to(point)<.05,"Separate relic screen/world conversion preserves its target")
			held.present(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,0,0,Vector2.ONE,Vector2.ONE,1,0,0,true)
			overlay.present(point,point,point,0,0,Vector2.ONE,Vector2.ONE,1,0,0,false)
			_label.text = "QUALITY / %s / %s" % [quality.to_upper(),str(pose[0]).to_upper()]
			await RenderingServer.frame_post_draw
			_check(get_viewport().get_texture().get_image().save_png(output+"/%s-%s.png" % [quality,str(pose[0])])==OK,"Save quality comparison")
	held.queue_free()
	overlay.queue_free()
	await get_tree().process_frame
	print("EXECUTIONER_QUALITY_REVIEW_OK checks=%d failures=%d three presets, five anchors, shared grip depth and separate prop projection" % [_checks,_failures])


