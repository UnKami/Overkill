class_name ArenaBrazier extends Node3D
## Forged basket and coal bed, batched once; one small transparent flame surface.
var _flame: ShaderMaterial
var _light: OmniLight3D
var _elapsed: float = 0.0

func _ready() -> void:
	var frame: Node3D = Node3D.new()
	frame.name = "ForgedFrame"
	add_child(frame)
	var iron: ShaderMaterial = ShaderMaterial.new()
	iron.shader = preload("res://assets/shaders/forged_metal.gdshader")
	iron.set_shader_parameter("steel_color",Color("302e2a"))
	iron.set_shader_parameter("metalness",0.7)
	iron.set_shader_parameter("surface_detail",preload("res://assets/characters/rigged/worn_metal_015.png"))
	var bronze: StandardMaterial3D = StandardMaterial3D.new()
	bronze.albedo_color = Color("66513a")
	bronze.metallic = 0.75
	bronze.roughness = 0.7
	_cylinder(frame,0.08,0.16,0.22,0.14,iron)
	_cylinder(frame,0.76,0.075,0.10,1.22,iron)
	_cylinder(frame,1.40,0.26,0.12,0.16,iron)
	for y: float in [0.18,0.28,1.25,1.36]: _ring(frame,y,0.105,bronze)
	for y: float in [1.46,1.58,1.69]: _ring(frame,y,0.25,iron)
	for index: int in 9:
		var angle: float = TAU*index/9.0
		var radial: Vector3 = Vector3(cos(angle),0,sin(angle))
		var rib: CylinderMesh = CylinderMesh.new()
		rib.top_radius = 0.013
		rib.bottom_radius = 0.018
		rib.height = 0.36
		rib.radial_segments = 6
		var instance: MeshInstance3D = _part(frame,rib,Vector3.UP*1.54+radial*0.245,iron)
		instance.rotation.z = -cos(angle)*0.10
		instance.rotation.x = sin(angle)*0.10
	ForgedArmor.combine_finish(frame)
	var coal: SphereMesh = SphereMesh.new()
	coal.radius = 1.0
	coal.height = 2.0
	coal.radial_segments = 8
	coal.rings = 4
	var ember: StandardMaterial3D = StandardMaterial3D.new()
	ember.albedo_color = Color("3c1406")
	ember.emission_enabled = true
	ember.emission = Color("c24c0b")
	ember.emission_energy_multiplier = 0.75
	ember.roughness = 1.0
	var coals: MultiMeshInstance3D = MultiMeshInstance3D.new()
	coals.name = "CoalBed"
	coals.multimesh = MultiMesh.new()
	coals.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	coals.multimesh.mesh = coal
	coals.multimesh.instance_count = 19
	for index: int in 19:
		var angle: float = index*2.399963
		var radius: float = 0.19*sqrt(float(index)/19.0)
		var at: Vector3 = Vector3(cos(angle)*radius,1.52+0.012*sin(index*2.0),sin(angle)*radius)
		coals.multimesh.set_instance_transform(index,Transform3D(Basis(Vector3.UP,angle).scaled(Vector3(0.055,0.027,0.047)),at))
	coals.material_override = ember
	coals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(coals)
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.57,0.58)
	_flame = ShaderMaterial.new()
	_flame.shader = preload("res://assets/shaders/brazier_flame.gdshader")
	_flame.set_shader_parameter("phase",position.x*2.7)
	var flame_mesh: MeshInstance3D = _part(self,quad,Vector3(0,1.81,0),_flame)
	flame_mesh.name = "Flame"
	flame_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_light = OmniLight3D.new()
	_light.position = Vector3(0,1.8,0.1)
	_light.light_color = Color("d78b46")
	_light.light_energy = 1.3
	_light.omni_range = 3.5
	add_child(_light)
	AudioManager.settings_changed.connect(_settings_changed)
	_settings_changed({})

func _settings_changed(_settings: Dictionary) -> void:
	_flame.set_shader_parameter("motion",0.0 if AudioManager.reduced_motion else 1.0)
	if AudioManager.reduced_motion: _light.light_energy = 1.3

func _process(delta: float) -> void:
	if AudioManager.reduced_motion: return
	_elapsed += delta
	var t: float = _elapsed+position.x*2.7
	_light.light_energy = 1.3*(1.0+0.025*sin(t*2.5)+0.02*sin(t*7.1))

func _part(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part

func _cylinder(parent: Node3D, y: float, top: float, bottom: float, height: float, material: Material) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	_part(parent,mesh,Vector3.UP*y,material)

func _ring(parent: Node3D, y: float, radius: float, material: Material) -> void:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = radius-0.012
	mesh.outer_radius = radius+0.012
	mesh.rings = 24
	mesh.ring_segments = 6
	_part(parent,mesh,Vector3.UP*y,material)
