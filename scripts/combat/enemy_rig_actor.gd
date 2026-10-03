class_name EnemyRigActor extends IllustratedActor
## Connected mesh deformation over the canonical enemy silhouette. Lower
## support is planted; body, head and appendages use Blender-authored motion.
const MOTION: Dictionary = preload("res://assets/animations/enemies/enemy_tracks.gd").DATA
var skeleton: Skeleton2D
var _bones: Array[Bone2D] = []
var _mesh: Polygon2D
var _action: String = "idle"
var _clock: float = 0.0
var _phase: float = 0.0
var _duration: float = 1.0
var _profile: Dictionary = {}
var _visible_size: Vector2
var _floating: bool = false
var _mass: float = 1.0
var _blend: float = 1.0
var _from: Array[Transform2D] = []
var _fallen: bool = false

func _ready() -> void:
	super._ready()
	if atlas == null:
		return
	var bounds: Rect2i = _visible_bounds(atlas.get_image())
	_visible_size = Vector2(bounds.size) * _art_scale
	var path: String = atlas.resource_path
	_floating = "wraith" in path or "choir" in path
	_mass = 0.72 if "sentinel" in path or "warden" in path or "reliquary" in path else 1.0
	var head: Vector2 = Vector2(0.5, 0.22) if _floating else Vector2(0.25, 0.43)
	var centers: Array[Vector2] = [Vector2.ZERO, Vector2(0.52,0.55), head, Vector2(0.87,0.34), Vector2(0.5,0.96)]
	var offset: Vector2 = Vector2(bounds.position) * _art_scale
	skeleton = Skeleton2D.new()
	_front.add_child(skeleton)
	for index: int in 5:
		var bone := Bone2D.new()
		bone.name = str(MOTION.bones[index])
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 24.0
		var parent_index: int = 1 if index in [2,3] else 0
		bone.position = centers[index] * _visible_size + offset if index > 0 else Vector2.ZERO
		if index in [2,3]:
			bone.position -= centers[parent_index] * _visible_size + offset
		bone.rest = bone.transform
		if index == 0:
			skeleton.add_child(bone)
		else:
			_bones[parent_index].add_child(bone)
		_bones.append(bone)
	_mesh = Polygon2D.new()
	_mesh.texture = atlas
	_mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_front.add_child(_mesh)
	_mesh.skeleton = _mesh.get_path_to(skeleton)
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	var weights: Array[PackedFloat32Array] = []
	for index: int in 5:
		weights.append(PackedFloat32Array())
	for y: int in 25:
		for x: int in 25:
			var pixel: Vector2 = Vector2(x/24.0,y/24.0) * Vector2(atlas.get_size())
			points.append(pixel * _art_scale)
			uv.append(pixel)
			var normalized: Vector2 = (pixel - Vector2(bounds.position)) / Vector2(bounds.size)
			var planted: float = 0.0 if _floating else smoothstep(0.64,0.90,normalized.y)
			var head_weight: float = exp(-pow(normalized.distance_to(head)/0.25,2.0)) * 0.78 * (1.0-planted)
			var secondary_weight: float = exp(-pow(normalized.distance_to(centers[3])/0.22,2.0)) * 0.56 * (1.0-planted)
			var body_weight: float = maxf(0.0,1.0-planted-head_weight-secondary_weight)
			var total: float = planted+head_weight+secondary_weight+body_weight
			var values: Array[float] = [0.0,body_weight/total,head_weight/total,secondary_weight/total,planted/total]
			for index: int in 5:
				weights[index].append(values[index])
	var triangles: Array[PackedInt32Array] = []
	for y: int in 24:
		for x: int in 24:
			var a: int = y*25+x
			triangles.append(PackedInt32Array([a,a+1,a+26]))
			triangles.append(PackedInt32Array([a,a+26,a+25]))
	_mesh.polygon = points
	_mesh.uv = uv
	_mesh.polygons = triangles
	for index: int in 5:
		_mesh.add_bone(skeleton.get_path_to(_bones[index]),weights[index])
	_front.self_modulate.a = 0.0
	_sample("idle",0.0)

func _process(delta: float) -> void:
	if _bones.is_empty() or _fallen:
		return
	var speed: float = AudioManager.combat_animation_speed_scale()
	_phase = fmod(_phase+delta*speed,3.2)
	_clock += delta*speed
	_blend = minf(1.0,_blend+delta*speed/0.16)
	if _busy:
		var cursor: float = clampf(_clock/_duration,0.0,1.0)
		if _action in ["attack","heavy","flurry"]:
			var anticipation: float = float(_profile.anticipation)
			var travel: float = float(_profile.travel)
			var hold: float = float(_profile.impact_hold)
			var recovery: float = float(_profile.recovery)
			if _clock < anticipation:
				cursor = 0.3*_clock/anticipation
			elif _clock < anticipation+travel:
				cursor = 0.3+0.15*(_clock-anticipation)/travel
			elif _clock < anticipation+travel+hold:
				_contact_ready = true
				cursor = 0.45+0.1*(_clock-anticipation-travel)/hold
			else:
				_contact_ready = true
				cursor = 0.55+0.45*(_clock-anticipation-travel-hold)/recovery
		_sample(_action,minf(cursor,1.0))
		if _action == "fall":
			_front.modulate.a = 1.0-smoothstep(0.35,1.0,cursor)
		if _clock >= _duration:
			if _action == "fall":
				_fallen = true
				_busy = false
			else:
				_rest()
	else:
		_sample("idle",0.0 if AudioManager.reduced_motion else _phase)

func _sample(action_name: String,time: float) -> void:
	var clip: Dictionary = MOTION.actions[action_name]
	var frame: float = clampf(time*float(MOTION.fps),0.0,float(clip.frames.size()-1))
	var first: int = int(frame)
	var second: int = mini(first+1,clip.frames.size()-1)
	var fraction: float = frame-first
	for index: int in _bones.size():
		var a: Array = clip.frames[first][index]
		var b: Array = clip.frames[second][index]
		var gain: float = _mass*(0.24 if AudioManager.reduced_motion else 1.0)
		var move: Vector2 = Vector2(lerpf(float(a[0]),float(b[0]),fraction),lerpf(float(a[1]),float(b[1]),fraction))*_visible_size*gain
		var angle: float = lerp_angle(float(a[2]),float(b[2]),fraction)*gain
		if index == 0 and _floating and action_name == "idle" and not AudioManager.reduced_motion:
			move.y += sin(time*TAU/3.2)*2.5
		var result := Transform2D(angle,_bones[index].rest.origin+move)
		if _blend < 1.0 and _from.size() == _bones.size():
			result = _from[index].interpolate_with(result,_blend*_blend*(3.0-2.0*_blend))
		_bones[index].transform = result

func _begin_clip(action_name: String,duration: float) -> void:
	_from.clear()
	for bone: Bone2D in _bones:
		_from.append(bone.transform)
	_blend = 0.0
	_action = action_name
	_clock = 0.0
	_duration = maxf(0.1,duration)
	_busy = true
	_front.modulate = Color.WHITE

func attack(profile: Dictionary = {}) -> void:
	_profile = {"id":"enemy_strike","anticipation":0.18,"travel":0.12,"impact_hold":0.065,"recovery":0.32}
	_profile.merge(profile,true)
	_contact_ready = false
	var action_name: String = "heavy" if str(_profile.id) == "enemy_heavy" else "flurry" if str(_profile.id) == "enemy_flurry" else "attack"
	_begin_clip(action_name,float(_profile.anticipation)+float(_profile.travel)+float(_profile.impact_hold)+float(_profile.recovery))

func hit(blocked: bool,profile: Dictionary = {}) -> void:
	if _busy and _action in ["attack","heavy","flurry"]:
		# Preserve a pending contact and momentum during a simultaneous clash.
		var flash: Tween = create_tween()
		_front.modulate = Color(1.3,1.3,1.4)
		flash.tween_property(_front,"modulate",Color.WHITE,0.18)
		return
	_begin_clip("guard" if blocked else "hit",float(profile.get("hit_recoil",0.08))+float(profile.get("hit_settle",0.25))+0.08)

func fall() -> void:
	_begin_clip("fall",0.72)

func _rest() -> void:
	_begin_clip("idle",3.2)
	_busy = false

func anchor_position(anchor: String,global_space: bool = true) -> Vector2:
	var index: int = 2 if anchor == "head" else 4 if anchor == "feet" else 1
	var point: Vector2 = _bones[index].global_position if not _bones.is_empty() else global_position+size*.5
	return point if global_space else get_global_transform().affine_inverse()*point

func sample_action_for_review(action_name: String,time: float) -> void:
	set_process(false)
	_blend = 1.0
	_sample(action_name,time)
