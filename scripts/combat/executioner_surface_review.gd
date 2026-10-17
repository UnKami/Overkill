extends Control
func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	get_window().size = Vector2i(1600,900)
	AudioManager.reduced_motion = false
	var bg := ColorRect.new()
	bg.color = Color("17232c")
	bg.size = Vector2(1920,1080)
	add_child(bg)
	var heroes: Array[Executioner3DActor] = []
	var labels: Array[Label] = []
	for i: int in 4:
		var hero := Executioner3DActor.new()
		hero.position = Vector2(i*480,70)
		hero.size = Vector2(480,950)
		hero.target_height = 720
		add_child(hero)
		if OS.get_cmdline_user_args().has("--woven-normal-review"):
			var normal_materials: int = 0
			for mesh: MeshInstance3D in hero._mesh_nodes:
				for surface: int in mesh.mesh.get_surface_count():
					var mat: StandardMaterial3D = mesh.get_active_material(surface) as StandardMaterial3D
					if mat == null or not mat.resource_name.to_lower().contains("painted pbr"): continue
					assert(mat.normal_texture != null,"The live skin must retain its baked cloth normal texture")
					assert(mat.normal_enabled != OS.get_cmdline_user_args().has("--flat-normal-review"),"Normal lighting matches the requested comparison")
					var tangent_data: PackedFloat32Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_TANGENT]
					assert(not tangent_data.is_empty(),"Tangent normals require actual skin tangents")
					normal_materials += 1
			assert(normal_materials>0,"Live PBR skin material must be checked")
		heroes.append(hero)
		hero.sample_action_for_review("idle",0)
		hero.model.rotation.y = deg_to_rad(float(i)*45)
		var label := Label.new()
		label.position = Vector2(i*480+20,30)
		label.text = ["FRONT","45 DEGREE TURN","SIDE","135 DEGREE TURN"][i]
		label.add_theme_font_size_override("font_size",26)
		add_child(label)
		labels.append(label)
	var output: String = "res://.test-artifacts/047/proper-character"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--review-output="):
			output = argument.trim_prefix("--review-output=").simplify_path()
			assert(output.begins_with("res://.test-artifacts/") or output.begins_with("user://"),"Review captures must stay in QA artifacts or the isolated profile")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if OS.get_cmdline_user_args().has("--texture-reference"):
		for i: int in range(1,heroes.size()): heroes[i].queue_free()
		var hero: Executioner3DActor = heroes[0]
		hero.viewport.size = Vector2i(1000,1400)
		hero.camera.size = 2.5
		for angle: int in [0,90,180,270]:
			hero.model.rotation.y = deg_to_rad(float(angle))
			hero.sample_action_for_review("idle",0)
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			assert(hero.viewport.get_texture().get_image().save_png(output+"/texture-reference-%03d.png" % angle)==OK)
		print("EXECUTIONER_TEXTURE_REFERENCES_OK four real native views at 1000x1400")
		get_tree().quit()
		return
	var review_poses: Array = [["idle",0.0],["iron_strike",1.65],["iron_strike",2.2],["iron_strike",2.8],["throw",.76],["block",1.1],["heavy",2.2],["heavy",2.66],["chalice",2.1],["bell",1.8],["siphon",2.4],["crown",1.4]]
	if OS.get_cmdline_user_args().has("--locomotion-review"):
		review_poses.clear()
		for action_name: String in ["iron_strike","heavy","twin_left"]:
			for time: float in [1.5,1.66,1.82,1.98,2.2,2.31,2.45,2.66,2.88,3.1]:
				review_poses.append([action_name,time])
	for group: int in 2:
		for i: int in heroes.size():
			heroes[i].model.rotation.y = deg_to_rad(float(group*180+i*45))
			labels[i].text = "BATTLE VIEW" if group==0 and i==0 else "%d DEGREE TURN" % (group*180+i*45)
		for pose: Array in review_poses:
			for hero: Executioner3DActor in heroes:
				hero.sample_action_for_review(str(pose[0]),float(pose[1]))
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path: String = output+"/turn-%s-%04d-%d.png" % [str(pose[0]),roundi(float(pose[1])*1000),group]
			assert(get_viewport().get_texture().get_image().save_png(path)==OK,"Turn capture must save")
			print("WARDROBE_TURN_CAPTURE ",path)
	print("WARDROBE_TURN_REVIEW_OK %d angle/pose views" % (review_poses.size()*heroes.size()*2))
	get_tree().quit()







