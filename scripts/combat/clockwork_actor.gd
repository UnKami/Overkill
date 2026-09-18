class_name ClockworkActor extends Node3D
## Articulated real-time magitech character: separate armor, joints and weapon rig.
var hostile: bool = false
var archetype: String = "executioner"
var torso: Node3D
var head: Node3D
var weapon_arm: Node3D
var off_arm: Node3D
var leg_l: Node3D
var leg_r: Node3D
var halo: Node3D
var _time: float = 0.0
var _acting: bool = false
var _motion: Tween
var _steel: StandardMaterial3D
var _gold: StandardMaterial3D
var _dark: StandardMaterial3D
var _glow: StandardMaterial3D
var _cloth: StandardMaterial3D

func _ready() -> void:
	_steel = material(Color("354852") if not hostile else Color("514039"), 0.85, 0.3)
	_gold = material(Color("bc9356"), 0.8, 0.26)
	_dark = material(Color("10171d"), 0.65, 0.48)
	_glow = material(Color("58e3ee") if not hostile else Color("f39452"), 0.25, 0.25, true)
	_cloth = material(Color("12212b") if not hostile else Color("391e27"), 0.0, 0.92)
	_build()

func material(color: Color, metal: float, rough: float, emissive: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metal
	result.roughness = rough
	if emissive:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 2.3
	return result

func mesh(parent: Node3D, geometry: Mesh, at: Vector3, scale_value: Vector3, surface: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = geometry
	piece.material_override = surface
	piece.position = at
	piece.scale = scale_value
	parent.add_child(piece)
	return piece

func box(parent: Node3D, at: Vector3, dimensions: Vector3, surface: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return mesh(parent, shape, at, Vector3.ONE, surface)

func orb(parent: Node3D, at: Vector3, dimensions: Vector3, surface: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 20
	shape.rings = 12
	return mesh(parent, shape, at, dimensions, surface)

func cylinder(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, surface: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 16
	return mesh(parent, shape, at, Vector3.ONE, surface)

func ring(parent: Node3D, at: Vector3, radius: float, thickness: float, surface: Material) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - thickness
	shape.outer_radius = radius + thickness
	shape.rings = 32
	shape.ring_segments = 8
	var result := mesh(parent, shape, at, Vector3.ONE, surface)
	result.rotation.x = PI * 0.5
	return result

func pivot(parent: Node3D, at: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.position = at
	parent.add_child(joint)
	return joint

func _build() -> void:
	torso = pivot(self, Vector3(0, 1.35, 0))
	# Interlocking cuirass plates, bevel-like overlapping tapered forms.
	orb(torso, Vector3(0, 0.37, 0), Vector3(0.72, 0.86, 0.48), _dark)
	for side in [-1.0, 1.0]:
		var breast := cylinder(torso, Vector3(side * 0.19, 0.5, 0.12), 0.19, 0.25, 0.48, _steel)
		breast.rotation.z = side * -0.12
		for n in range(4):
			var rib := box(torso, Vector3(side * 0.21, 0.25 - n * 0.12, 0.22), Vector3(0.29, 0.065, 0.11), _gold if n == 3 else _steel)
			rib.rotation.z = side * 0.18
		for n in range(3):
			orb(torso, Vector3(side * 0.3, 0.55 - n * 0.16, 0.25), Vector3.ONE * 0.035, _gold)
	ring(torso, Vector3(0, 0.38, 0.3), 0.15, 0.025, _gold)
	orb(torso, Vector3(0, 0.38, 0.31), Vector3(0.2, 0.2, 0.07), _glow)
	for n in range(8):
		var angle := float(n) * TAU / 8.0
		var cog := box(torso, Vector3(sin(angle) * 0.18, 0.38 + cos(angle) * 0.18, 0.3), Vector3(0.04, 0.07, 0.045), _gold)
		cog.rotation.z = -angle
	# Layered tassets and jointed legs.
	box(torso, Vector3(0, -0.13, 0.02), Vector3(0.64, 0.11, 0.48), _gold)
	for side in [-1.0, 1.0]:
		for n in range(3):
			var plate := box(torso, Vector3(side * (0.2 + n * 0.025), -0.27 - n * 0.11, 0.18), Vector3(0.27, 0.19, 0.10), _steel)
			plate.rotation.z = side * 0.16
	leg_l = _leg(-0.21)
	leg_r = _leg(0.21)
	# Masked helm with a luminous slit, crown ridges and breathing grille.
	head = pivot(torso, Vector3(0, 0.95, 0))
	orb(head, Vector3.ZERO, Vector3(0.43, 0.51, 0.44), _dark)
	var helm := cylinder(head, Vector3(0, 0.015, 0.0), 0.16, 0.22, 0.43, _steel)
	helm.rotation.y = PI / 8.0
	box(head, Vector3(0, -0.02, 0.222), Vector3(0.36, 0.065, 0.035), _dark)
	for side in [-1.0, 1.0]:
		var eye := box(head, Vector3(side * 0.086, -0.005, 0.246), Vector3(0.125, 0.022, 0.02), _glow)
		eye.rotation.z = side * 0.18
		var cheek := box(head, Vector3(side * 0.15, -0.13, 0.19), Vector3(0.1, 0.20, 0.1), _steel)
		cheek.rotation.z = side * -0.2
	for n in range(5):
		box(head, Vector3((n - 2) * 0.027, -0.15, 0.249), Vector3(0.011, 0.095, 0.015), _gold)
	box(head, Vector3(0, 0.16, 0.07), Vector3(0.06, 0.24, 0.48), _gold)
	# A broken aureole establishes the clockwork silhouette.
	halo = pivot(torso, Vector3(0, 0.93, -0.28))
	ring(halo, Vector3.ZERO, 0.42, 0.021, _gold)
	for n in range(12):
		var angle := float(n) * TAU / 12.0
		var marker := box(halo, Vector3(sin(angle) * 0.44, cos(angle) * 0.44, 0), Vector3(0.025, 0.10, 0.03), _glow if n % 3 == 0 else _gold)
		marker.rotation.z = -angle
	weapon_arm = _arm(-1.0)
	off_arm = _arm(1.0)
	_build_weapon(weapon_arm)
	# Cloak is a curved strip mesh, with discrete layered folds and a split hem.
	for n in range(9):
		var strip := box(torso, Vector3((n - 4) * 0.083, -0.06, -0.29 - absf(n - 4) * 0.012), Vector3(0.092, 1.6 - absf(n - 4) * 0.07, 0.028), _cloth)
		strip.rotation.x = -0.15
		strip.rotation.z = (n - 4) * 0.025
	if hostile:
		var horns := 3 if archetype in ["sentinel", "twin", "eclipse"] else 2
		for n in range(horns):
			var horn := cylinder(head, Vector3((n - (horns - 1) * 0.5) * 0.22, 0.38, -0.02), 0, 0.085, 0.42, _gold)
			horn.rotation.z = -(n - (horns - 1) * 0.5) * 0.45
		if archetype in ["sentinel", "bulwark", "twin", "eclipse"]:
			torso.scale = Vector3(1.2, 1.08, 1.15)
		elif archetype in ["stalker", "corrosion", "shards"]:
			torso.scale = Vector3(0.85, 1.05, 0.85)

func _leg(side: float) -> Node3D:
	var joint := pivot(self, Vector3(side, 1.18, 0))
	orb(joint, Vector3(0, -0.23, 0), Vector3(0.23, 0.56, 0.25), _steel)
	ring(joint, Vector3(0, -0.50, 0.08), 0.115, 0.025, _gold)
	cylinder(joint, Vector3(0, -0.77, 0), 0.13, 0.09, 0.48, _steel)
	box(joint, Vector3(0, -0.77, 0.105), Vector3(0.09, 0.38, 0.035), _gold)
	box(joint, Vector3(0, -1.075, 0.09), Vector3(0.25, 0.15, 0.44), _dark)
	return joint

func _arm(side: float) -> Node3D:
	var joint := pivot(torso, Vector3(side * 0.5, 0.58, 0))
	orb(joint, Vector3.ZERO, Vector3(0.48, 0.36, 0.5), _steel)
	ring(joint, Vector3(0, 0, 0.23), 0.19, 0.025, _gold)
	for n in range(3):
		var feather := box(joint, Vector3(side * 0.1, -0.07 - n * 0.09, 0.03), Vector3(0.39 - n * 0.055, 0.12, 0.39), _steel)
		feather.rotation.z = side * -0.2
	cylinder(joint, Vector3(0, -0.32, 0), 0.11, 0.09, 0.35, _dark)
	orb(joint, Vector3(0, -0.49, 0), Vector3.ONE * 0.2, _gold)
	cylinder(joint, Vector3(0, -0.68, 0.01), 0.14, 0.10, 0.31, _steel)
	box(joint, Vector3(0, -0.64, 0.15), Vector3(0.065, 0.23, 0.03), _glow)
	orb(joint, Vector3(0, -0.91, 0.03), Vector3(0.17, 0.20, 0.18), _dark)
	joint.rotation.z = side * 0.1
	return joint

func _build_weapon(parent: Node3D) -> void:
	var grip := cylinder(parent, Vector3(0, -0.9, 0.05), 0.037, 0.037, 0.48, _dark)
	grip.rotation.x = PI * 0.5
	box(parent, Vector3(0, -0.9, 0.29), Vector3(0.42, 0.08, 0.1), _gold)
	# Long engraved execution blade, forward in the character's hand.
	var blade := box(parent, Vector3(0, -0.9, 0.85), Vector3(0.18, 0.045, 1.04), _steel)
	blade.rotation.z = -0.1
	box(parent, Vector3(-0.093, -0.9, 0.85), Vector3(0.022, 0.04, 1.08), _glow)
	for n in range(6):
		box(parent, Vector3(0, -0.87, 0.44 + n * 0.13), Vector3(0.085, 0.013, 0.023), _gold)

func _process(delta: float) -> void:
	_time += delta
	if _acting: return
	torso.position.y = 1.35 + sin(_time * 1.7) * 0.022
	torso.rotation.y = sin(_time * 0.7) * 0.035
	head.rotation.y = sin(_time * 0.55) * 0.07
	weapon_arm.rotation.x = -0.16 + sin(_time * 1.7 + 0.4) * 0.035
	off_arm.rotation.x = sin(_time * 1.7) * 0.025
	halo.rotation.z += delta * (0.11 if hostile else -0.075)

func attack() -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	_acting = true
	_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_motion.set_parallel(true)
	_motion.tween_property(weapon_arm, "rotation:x", -1.6, 0.14).set_trans(Tween.TRANS_CUBIC)
	_motion.tween_property(torso, "rotation:y", -0.3, 0.14)
	_motion.chain().set_parallel(true)
	_motion.tween_property(weapon_arm, "rotation:x", 0.6, 0.10).set_trans(Tween.TRANS_EXPO)
	_motion.tween_property(torso, "rotation:y", 0.3, 0.10)
	_motion.tween_property(torso, "position:z", 0.22, 0.10)
	_motion.chain().set_parallel(true)
	_motion.tween_property(weapon_arm, "rotation:x", -0.16, 0.23)
	_motion.tween_property(torso, "rotation:y", 0.0, 0.23)
	_motion.tween_property(torso, "position:z", 0.0, 0.23)
	_motion.chain().tween_callback(func() -> void: _acting = false)

func hit(blocked: bool = false) -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	_acting = true
	_motion = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	_motion.tween_property(torso, "rotation:x", -0.08 if blocked else -0.24, 0.055)
	_motion.tween_property(torso, "rotation:x", 0.0, 0.25).set_trans(Tween.TRANS_BACK)
	_motion.tween_callback(func() -> void: _acting = false)

func fall() -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	_acting = true
	_motion = create_tween()
	_motion.set_parallel(true)
	_motion.tween_property(self, "rotation:x", -PI * 0.48, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion.tween_property(self, "position:y", -0.08, 0.65)
