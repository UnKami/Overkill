class_name RelicRigActor extends IllustratedActor
## Blender-authored skeletal cutout actor. Bone2D transforms drive weighted
## Polygon2D meshes; the original whole-character texture is never rendered.
const RIG_DATA: Dictionary = preload("res://assets/characters/executioner/rigged/rig_data.gd").DATA
const PARTS_TEXTURE: Texture2D = preload("res://assets/characters/executioner/rigged/parts_atlas.png")

var skeleton: Skeleton2D
var _rig_root: Node2D
var _bones: Array[Bone2D] = []
var _bone_names: Dictionary = {}
var _skin_meshes: Array[Polygon2D] = []
var _action_name: String = "idle"
var _action_time: float = 0.0
var _action_contact: float = -1.0
var _action_duration: float = 3.2
var _fallen: bool = false
var _blend_from: Array[Transform2D] = []
var _blend_time: float = 1.0
var _idle_phase: float = 0.0
var _recoil_amount: float = 0.0
var _recoil_blocked: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep the existing diagnostics/intro surface, but render only child meshes.
	_front = TextureRect.new()
	_front.name = "ArticulatedCharacter"
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_front)
	var bounds: Array = RIG_DATA.bounds
	_art_scale = minf(target_height / float(bounds[3]), target_width / float(bounds[2]))
	_front.size = Vector2(float(bounds[2]), float(bounds[3])) * _art_scale
	_pose_origin = Vector2(size.x * 0.5 + float(bounds[0]) * _art_scale, size.y - 45.0 + float(bounds[1]) * _art_scale)
	_front.position = _pose_origin
	_rig_root = Node2D.new()
	_rig_root.name = "RigRoot"
	_rig_root.position = Vector2(-float(bounds[0]), -float(bounds[1])) * _art_scale
	_rig_root.scale = Vector2(facing * _art_scale, _art_scale)
	_front.add_child(_rig_root)
	skeleton = Skeleton2D.new()
	skeleton.name = "ExecutionerSkeleton"
	_rig_root.add_child(skeleton)
	for entry: Dictionary in RIG_DATA.bones:
		var bone: Bone2D = Bone2D.new()
		bone.name = str(entry.name)
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 36.0
		var rest_xy: Array = entry.rest
		bone.position = Vector2(float(rest_xy[0]), float(rest_xy[1]))
		bone.rest = bone.transform
		var parent_name: String = str(entry.parent)
		if parent_name.is_empty():
			skeleton.add_child(bone)
		else:
			(_bone_names[parent_name] as Bone2D).add_child(bone)
		_bones.append(bone)
		_bone_names[str(entry.name)] = bone
	for entry: Dictionary in RIG_DATA.meshes:
		var mesh: Polygon2D = Polygon2D.new()
		mesh.name = str(entry.name)
		mesh.texture = PARTS_TEXTURE
		mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# Keep rear parts above the stage background; negative local z would
		# sort them behind an unrelated zero-z background Control in Godot.
		mesh.z_index = int(entry.z) + 10
		mesh.polygon = _points(entry.vertices)
		mesh.uv = _points(entry.uv)
		var triangles: Array[PackedInt32Array] = []
		for triangle: Array in entry.triangles:
			triangles.append(PackedInt32Array(triangle))
		mesh.polygons = triangles
		_rig_root.add_child(mesh)
		mesh.skeleton = mesh.get_path_to(skeleton)
		var weights: Dictionary = entry.weights
		for bone_name: String in weights:
			var bone: Bone2D = _bone_names[bone_name]
			mesh.add_bone(skeleton.get_path_to(bone), PackedFloat32Array(weights[bone_name]))
		_skin_meshes.append(mesh)
	_apply_sample("idle", 0.0)

func _points(values: Array) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for pair: Array in values:
		result.append(Vector2(float(pair[0]), float(pair[1])))
	return result

func _process(delta: float) -> void:
	if _bones.is_empty() or _fallen:
		return
	var speed: float = AudioManager.animation_speed_scale()
	_idle_phase = fmod(_idle_phase + delta * speed, float(RIG_DATA.actions.idle.duration))
	_action_time += delta * speed
	_blend_time = minf(1.0, _blend_time + delta * speed / 0.20)
	_recoil_amount = maxf(0.0, _recoil_amount - delta * speed / 0.28)
	if _busy:
		if _action_contact >= 0.0 and _action_time >= _action_contact:
			_contact_ready = true
		_apply_sample(_action_name, minf(_action_time, _action_duration))
		if _action_name == "fall":
			_front.modulate.a = clampf(1.0 - (_action_time - 0.45) / 0.65, 0.0, 1.0)
		if _action_time >= _action_duration:
			if _action_name == "fall":
				_fallen = true
				_busy = false
			else:
				_rest()
	else:
		_apply_sample("idle", 0.0 if AudioManager.reduced_motion else _idle_phase)

func _apply_sample(action_name: String, time: float) -> void:
	var action: Dictionary = RIG_DATA.actions[action_name]
	var frames: Array = action.frames
	var frame_float: float = clampf(time * float(RIG_DATA.fps), 0.0, float(frames.size() - 1))
	var first: int = int(floor(frame_float))
	var second: int = mini(first + 1, frames.size() - 1)
	var weight: float = frame_float - float(first)
	var a: Array = frames[first]
	var b: Array = frames[second]
	for index: int in _bones.size():
		var ta: Array = a[index]
		var tb: Array = b[index]
		var rest: Transform2D = _bones[index].rest
		var at: Vector2 = Vector2(float(ta[0]), float(ta[1])).lerp(Vector2(float(tb[0]), float(tb[1])), weight)
		var angle: float = lerp_angle(float(ta[2]), float(tb[2]), weight)
		if AudioManager.reduced_motion:
			at = rest.origin.lerp(at, 0.28)
			angle *= 0.35
		var sampled: Transform2D = Transform2D(angle, at)
		if _blend_time < 1.0 and _blend_from.size() == _bones.size():
			var eased: float = _blend_time * _blend_time * (3.0 - 2.0 * _blend_time)
			sampled = _blend_from[index].interpolate_with(sampled, eased)
		if _recoil_amount > 0.0 and not AudioManager.reduced_motion:
			var envelope: float = sin(_recoil_amount * PI)
			if str(_bones[index].name) == "spine":
				sampled = Transform2D(sampled.get_rotation() + deg_to_rad(-2.0 if _recoil_blocked else -4.5) * envelope, sampled.origin)
			elif str(_bones[index].name) == "head":
				sampled = Transform2D(sampled.get_rotation() + deg_to_rad(-2.0) * envelope, sampled.origin)
		_bones[index].transform = sampled

func play_action(action_name: String, _profile: Dictionary = {}) -> void:
	if not RIG_DATA.actions.has(action_name) or _fallen:
		return
	_blend_from.clear()
	for bone: Bone2D in _bones:
		_blend_from.append(bone.transform)
	_blend_time = 0.0
	_action_name = action_name
	_action_time = 0.0
	var action: Dictionary = RIG_DATA.actions[action_name]
	_action_contact = float(action.contact)
	_action_duration = float(action.duration)
	_busy = action_name != "idle"
	_contact_ready = false
	_front.modulate = Color.WHITE
	_apply_sample(action_name, 0.0)

func attack(profile: Dictionary = {}) -> void:
	var action: String = str(profile.get("rig_action", "iron_strike"))
	if AttackPresentation.is_heavy_hammer(profile):
		action = "heavy"
	if not RIG_DATA.actions.has(action):
		action = "iron_strike"
	play_action(action, profile)

func hit(blocked: bool, _profile: Dictionary = {}) -> void:
	# Incoming impact must never cancel an outgoing contact event and deadlock the
	# deterministic clash sequence. Overlay a brief tint if already performing.
	if _busy:
		_recoil_amount = 1.0
		_recoil_blocked = blocked
		var flash: Tween = create_tween()
		_front.modulate = Color(1.35, 1.35, 1.5)
		flash.tween_property(_front, "modulate", Color.WHITE, 0.18)
		return
	play_action("guard_hit" if blocked else "hit")

func fall() -> void:
	play_action("fall")

func set_pose(_frame: int) -> void:
	# Compatibility for older stage callers: the skin has continuous bone poses.
	if not _bones.is_empty():
		_apply_sample("idle", 0.0)

func _rest() -> void:
	# Recovery joins the current breathing phase; there is no one-frame reset
	# of root, knee, shoulder or head transforms at the end of an action.
	_blend_from.clear()
	for bone: Bone2D in _bones:
		_blend_from.append(bone.transform)
	_blend_time = 0.0
	_busy = false
	_action_name = "idle"
	_action_time = 0.0
	_front.modulate = Color.WHITE
	_apply_sample("idle", _idle_phase)

func is_busy() -> bool:
	return _busy

func contact_ready() -> bool:
	return _contact_ready

func anchor_position(anchor: String, global_space: bool = true) -> Vector2:
	if anchor == "feet" and _bone_names.has("foot_near"):
		var near_foot: Bone2D = _bone_names["foot_near"]
		var far_foot: Bone2D = _bone_names["foot_far"]
		var ground: Vector2 = (near_foot.global_position + far_foot.global_position) * 0.5 + Vector2(0.0, 34.0 * _art_scale)
		return ground if global_space else get_global_transform().affine_inverse() * ground
	var bone_name: String = "spine"
	var offset: Vector2 = Vector2(0, -25)
	match anchor:
		"hand", "hand_near":
			bone_name = "hand_near"
			offset = Vector2(5, 14)
		"hand_far":
			bone_name = "hand_far"
			offset = Vector2(0, 12)
		"head":
			bone_name = "head"
			offset = Vector2(0, -70)
		"chest", "body":
			bone_name = "spine"
			offset = Vector2(0, -25)
		"feet":
			bone_name = "root"
			offset = Vector2.ZERO
	var bone: Bone2D = _bone_names.get(bone_name)
	if bone == null:
		return global_position + size * 0.5 if global_space else size * 0.5
	var point: Vector2 = bone.to_global(offset)
	return point if global_space else get_global_transform().affine_inverse() * point

func get_hand_global_position() -> Vector2:
	return anchor_position("hand")

func get_head_global_position() -> Vector2:
	return anchor_position("head")

func get_chest_global_position() -> Vector2:
	return anchor_position("chest")

func get_feet_global_position() -> Vector2:
	return anchor_position("feet")

func get_hand_global_rotation() -> float:
	var bone: Bone2D = _bone_names.get("hand_near")
	return bone.global_rotation if bone != null else 0.0

func sample_action_for_review(action_name: String, time: float) -> void:
	# Deterministic pose review without running the battle resolver.
	set_process(false)
	_blend_time = 1.0
	_apply_sample(action_name, time)
