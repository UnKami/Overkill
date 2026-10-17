class_name Relic3DView extends Node2D
## Held weapons share the character's 3D depth and lighting. Thrown/ritual
## props use an overlay pass so they remain visible on illustrated enemies.
const MODELS: PackedScene = preload("res://assets/animations/relics/three_d/relics.glb")
var actor: Executioner3DActor
var skeleton: Skeleton3D
var viewport: SubViewport
var camera: Camera3D
var _image: TextureRect
var _meshes: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []
var _role_materials: Dictionary = {}
var _bones: Dictionary = {}
var _kind: String = ""
var _id: String = ""
var _tube: MeshInstance3D
var _life_orb: MeshInstance3D
var _life_light: OmniLight3D
var _tube_material: ShaderMaterial
var _shared_actor_viewport: bool = false
var _model_root: Node3D

func configure(player: Executioner3DActor,relic_id: String,kind: String) -> void:
	actor = player
	_id = relic_id
	_kind = kind
	_shared_actor_viewport = kind in ["sword","blades","hammer","wedge"]
	if _shared_actor_viewport:
		# Held weapons share the skin's depth buffer and lighting. Fingers can
		# wrap around a hilt instead of the whole weapon painting over the hand.
		viewport = actor.viewport
		camera = actor.camera
	else:
		viewport = SubViewport.new()
		viewport.size = _overlay_budget()
		viewport.transparent_bg = true
		viewport.own_world_3d = true
		viewport.msaa_3d = actor.viewport.msaa_3d
		if OS.get_cmdline_user_args().has("--profile-aa2"):
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.mesh_lod_threshold = 1.5
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		AudioManager.settings_changed.connect(_apply_render_quality)
		if OS.get_cmdline_user_args().has("--benchmark"):
			RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(),true)
			viewport.add_to_group("qa_render_measurements")
	var model: Node3D = MODELS.instantiate() as Node3D
	viewport.add_child(model)
	_model_root = model
	skeleton = actor._find_skeleton(model)
	assert(skeleton != null and skeleton.get_bone_count()==6,"Each physical relic has its source six-joint rig")
	for name: String in ["root","prop","secondary","flow","aura","tether"]: _bones[name] = skeleton.find_bone(name)
	var prefix: String = relic_id.replace("-","_")+"__"
	for node: Node in model.find_children("*","MeshInstance3D",true,false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		mesh.visible = str(mesh.name).begins_with(prefix)
		if not mesh.visible: continue
		assert(mesh.skin != null,"Physical relic geometry must retain its skin")
		_meshes.append(mesh)
		var role: String = "secondary" if str(mesh.name).contains("__secondary__") else "root" if str(mesh.name).contains("__root__") else "prop"
		for surface: int in mesh.mesh.get_surface_count():
			var original: Material = mesh.get_active_material(surface)
			var mat: StandardMaterial3D = original.duplicate() as StandardMaterial3D
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.set_surface_override_material(surface,mat)
			_materials.append(mat)
			if not _role_materials.has(role): _role_materials[role] = []
			(_role_materials[role] as Array).append(mat)
	if _shared_actor_viewport:
		var points: PackedVector3Array = []
		var prop_rest: Transform3D = skeleton.get_bone_global_rest(int(_bones.prop))
		for mesh: MeshInstance3D in _meshes:
			if not str(mesh.name).contains("__prop__"): continue
			var to_prop: Transform3D = prop_rest.affine_inverse()*skeleton.global_transform.affine_inverse()*mesh.global_transform
			for surface: int in mesh.mesh.get_surface_count():
				var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				for point: Vector3 in vertices: points.append(to_prop*point)
		assert(not points.is_empty(),"Held weapons require physical contact geometry")
		actor.bind_weapon_geometry(get_instance_id(),points)
		_set_alpha("prop",0)
		_set_alpha("secondary",0)
		_set_alpha("root",0)
		return
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0,0,0,0)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a7bdd1")
	settings.ambient_light_energy = .45
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	viewport.add_child(environment)
	for at: Vector3 in [Vector3(-3,4,5),Vector3(4,2,-3)]:
		var light := DirectionalLight3D.new()
		viewport.add_child(light)
		light.position = at
		light.look_at(Vector3(0,1,0))
		light.light_energy = 1.2
		light.light_color = Color("ffd7ab") if at.x<0 else Color("73bfff")
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	# Ritual props and tall pours need the original vertical effect space.
	# Their projection is independent of the cropped character render target.
	camera.size = 4.7
	camera.transform = actor.camera.transform
	_image = TextureRect.new()
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.texture = viewport.get_texture()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_image)
	_set_alpha("prop",0)
	_set_alpha("secondary",0)
	_set_alpha("root",0)
	if _kind == "siphon": _build_tether()

func _apply_render_quality(_settings: Dictionary = {}) -> void:
	if _shared_actor_viewport or viewport == null or not is_instance_valid(actor): return
	viewport.size = _overlay_budget()
	viewport.msaa_3d = actor.viewport.msaa_3d

func _overlay_budget() -> Vector2i:
	return Vector2i(1200,900) if AudioManager.render_quality=="high" else Vector2i(900,675) if AudioManager.render_quality=="balanced" else Vector2i(720,540)

func _projection_scale() -> float:
	return actor.target_height/(1.91*float(viewport.size.y)/camera.size)

func _projection_origin() -> Vector2:
	return Vector2(actor.size.x*.5,actor.size.y-45)-camera.unproject_position(Vector3.ZERO)*_projection_scale()

func _build_tether() -> void:
	var tether := BoneAttachment3D.new()
	tether.bone_name = "tether"
	skeleton.add_child(tether)
	_tube = MeshInstance3D.new()
	tether.add_child(_tube)
	_tube_material = ShaderMaterial.new()
	_tube_material.shader = preload("res://assets/shaders/combat/siphon_tether.gdshader")
	_tube_material.set_shader_parameter("relic_texture",RelicArt.load_texture("rel_13_blood_siphon"))
	_tube.material_override = _tube_material
	# Fixed connectivity is uploaded once. Authored control values deform the
	# actual tube vertices on the GPU; no mesh resource is replaced per frame.
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in 25:
		for side: int in 10:
			var angle: float = float(side)*TAU/10.0
			builder.set_uv(Vector2(float(ring)/24.0,float(side)/10.0))
			builder.set_normal(Vector3(cos(angle),sin(angle),0))
			builder.add_vertex(Vector3(.024*cos(angle),.024*sin(angle),float(ring)/24.0))
	for ring: int in 24:
		for side: int in 10:
			var a: int = ring*10+side
			var b: int = ring*10+(side+1)%10
			var c: int = (ring+1)*10+(side+1)%10
			var d: int = (ring+1)*10+side
			for index: int in [a,b,c,a,c,d]: builder.add_index(index)
	_tube.mesh = builder.commit()
	_tube.visible = false
	var flow := BoneAttachment3D.new()
	flow.bone_name = "flow"
	skeleton.add_child(flow)
	_life_orb = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .054
	sphere.height = .108
	sphere.radial_segments = 24
	sphere.rings = 12
	_life_orb.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8cff63")
	material.roughness = .22
	material.emission_enabled = true
	material.emission = Color("58f030")
	material.emission_energy_multiplier = .65
	_life_orb.material_override = material
	flow.add_child(_life_orb)
	_life_orb.visible = false
	_life_light = OmniLight3D.new()
	_life_light.omni_range = .3
	_life_light.light_color = Color("65ff3d")
	_life_light.light_energy = 0
	flow.add_child(_life_light)

func _tether_point(enemy: Vector3,hand: Vector3,t: float) -> Vector3:
	var at: Vector3 = enemy.lerp(hand,t)
	at.y -= sin(t*PI)*enemy.distance_to(hand)*.12
	return at

func present_tether(enemy_screen: Vector2,hand_screen: Vector2,extension: float,progress: float,opacity: float,energy: float) -> void:
	if _tube == null: return
	_tube.visible = extension>.01 and opacity>.01
	_life_orb.visible = energy>.01 and extension>.98
	_life_light.light_energy = energy*.65 if _life_orb.visible else 0.0
	if not _tube.visible:
		_set_alpha("secondary",0.0)
		return
	var enemy: Vector3 = _world_from_screen(enemy_screen)
	var hand: Vector3 = actor.grip_world("R").origin
	_set_bone("secondary",_plane_pose(enemy_screen.lerp(hand_screen,extension),-.6,Vector2.ONE*1.4))
	_set_alpha("secondary",opacity if extension>.02 else 0.0)
	_set_bone("tether",Transform3D.IDENTITY)
	_tube_material.set_shader_parameter("enemy_point",enemy)
	_tube_material.set_shader_parameter("hand_point",hand)
	_tube_material.set_shader_parameter("camera_axis",camera.global_basis.z)
	_tube_material.set_shader_parameter("extension",extension)
	_tube_material.set_shader_parameter("progress",progress)
	_tube_material.set_shader_parameter("energy",energy)
	_tube_material.set_shader_parameter("opacity",opacity)
	# Shader displacement requires bounds that follow both live endpoints.
	_tube.custom_aabb = AABB(enemy,Vector3.ZERO).expand(hand).grow(.20+enemy.distance_to(hand)*.12)
	_set_bone("flow",Transform3D(Basis.IDENTITY,_tether_point(enemy,hand,progress)))
	skeleton.force_update_all_bone_transforms()

func _set_alpha(role: String,opacity: float) -> void:
	for mat: StandardMaterial3D in _role_materials.get(role,[]):
		var color: Color = mat.albedo_color
		color.a = clampf(opacity,0,1)
		mat.albedo_color = color
		# Fully revealed volume needs the depth buffer. Alpha blending sorts
		# whole surfaces and can paint internal shafts over the outer core.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if color.a>=.999 else BaseMaterial3D.TRANSPARENCY_ALPHA

func _world_from_screen(point: Vector2) -> Vector3:
	var local: Vector2 = actor.get_global_transform().affine_inverse()*point
	var pixel: Vector2 = (local-_projection_origin())/_projection_scale()
	var depth: float = -camera.to_local(Vector3(0,1.3,0)).z
	return camera.project_position(pixel,depth)

func _plane_pose(point: Vector2,angle: float,scale: Vector2) -> Transform3D:
	var basis: Basis = camera.global_basis*Basis(Vector3.BACK,-angle)
	basis = basis.scaled(Vector3(scale.x,scale.y,minf(scale.x,scale.y)))
	return Transform3D(basis,_world_from_screen(point))

func _set_bone(name: String,global_pose: Transform3D) -> void:
	var index: int = int(_bones[name])
	var local: Transform3D = global_pose
	if name != "root": local = skeleton.get_bone_pose(int(_bones.root)).affine_inverse()*global_pose
	skeleton.set_bone_pose_position(index,local.origin)
	skeleton.set_bone_pose_rotation(index,local.basis.get_rotation_quaternion().normalized())
	skeleton.set_bone_pose_scale(index,local.basis.get_scale())

func present(primary: Vector2,secondary: Vector2,hanger: Vector2,angle: float,left_angle: float,scale: Vector2,left_scale: Vector2,alpha: float,left_alpha: float,root_alpha: float,melee: bool) -> void:
	if _image != null:
		_image.position = to_local(actor.get_global_transform()*_projection_origin())
		_image.size = Vector2(viewport.size)*_projection_scale()*(actor.get_global_transform().get_scale()/get_global_transform().get_scale())
	var root_pose: Transform3D = _plane_pose(hanger,0,Vector2.ONE)
	_set_bone("root",root_pose)
	var primary_pose: Transform3D = _plane_pose(primary,angle,scale)
	var second_pose: Transform3D = _plane_pose(secondary,left_angle,left_scale)
	if melee:
		# Socket lies within the articulated palm. The hilt is a real cylinder
		# through the grip axis, with full wrist orientation and depth rotation.
		primary_pose = actor.weapon_world("R",Vector3(scale.x,scale.y,scale.x))
		second_pose = actor.weapon_world("L",Vector3(left_scale.x,left_scale.y,left_scale.x))
	elif _kind in ["chalice","crown","bell","guard","piston","siphon"]:
		var factor: float = 1.15 if _kind == "crown" else (1.65 if _kind in ["bell","chalice"] else 1.4)
		primary_pose.basis = primary_pose.basis.scaled(Vector3.ONE*factor)
		second_pose.basis = second_pose.basis.scaled(Vector3.ONE*factor)
		if _kind == "bell": second_pose.origin = primary_pose.origin
		if _kind == "crown": primary_pose.origin = _world_from_screen(primary+Vector2(0,-40))
	_set_bone("prop",primary_pose)
	_set_bone("secondary",second_pose)
	_set_alpha("prop",alpha)
	_set_alpha("secondary",left_alpha)
	_set_alpha("root",root_alpha if _kind=="bell" else 0)
	skeleton.force_update_all_bone_transforms()

func _exit_tree() -> void:
	# Shared props live beneath the actor's viewport, outside this cue's branch.
	# Release only the model instance created by this view when its cue finishes.
	if _shared_actor_viewport and is_instance_valid(_model_root):
		_model_root.queue_free()
	if _shared_actor_viewport and is_instance_valid(actor):
		actor.clear_weapon_geometry(get_instance_id())

