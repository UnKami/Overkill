class_name RelicChoreography extends Node2D
## Presentation only. Every prop track is evaluated in Blender and sampled
## from its editable six-bone action; damage/status changes stay in controller.
## Normal playback uses authored seconds. Fast Mode is the explicit 2x option.
signal transfer_arrived
var _transfer_delivered: bool = false
var _combo_hold: bool = false
var _combo_second: bool = false

const TRACK_SOURCE: Script = preload("res://assets/animations/relics/relic_tracks.gd")
const PURPLE := Color("b76cff")
const BLUE := Color("65caff")
const GREEN := Color("73e29a")

var buff_target_global := Vector2.ZERO
var relic: ClockRelicData
var _stage: Node
var _canvas: Control
var _clip: Dictionary = {}
var _model: String = ""
var _clock: float = 0.0
var _running: bool = false
var _resolved: bool = false
var _contact: bool = false
var _finished: bool = false
var _relic_skeleton: Skeleton2D
var _prop: Node2D
var _extra: Node2D
var _hanger: Node2D
var _texture: Texture2D
var _particles: CPUParticles2D
var _launch := Vector2.ZERO
var _enemy_at_contact := Vector2.ZERO
var _target_frozen: bool = false
var _last_prop := Vector2.ZERO
var _outcome: Dictionary = {}
var _initial_tint := Color.WHITE
var _restored: bool = false
var _notified_resolve: bool = false
var _label_count: int = 0
var _released: bool = false
var _release_rotation: float = 0.0
var _siphon_tube: Polygon2D
var _siphon_enemy: Node2D
var _siphon_hand: Node2D
var _native_view: Relic3DView


static func create(stage: Node, canvas: Control, selected_relic: ClockRelicData) -> RelicChoreography:
	if stage == null or canvas == null or selected_relic == null:
		return null
	var cue := RelicChoreography.new()
	cue.name = "RelicChoreography_" + selected_relic.id.replace("-", "_")
	cue._stage = stage
	cue._canvas = canvas
	cue.relic = selected_relic
	cue._clip = TRACK_SOURCE.DATA.clips.get(selected_relic.id, TRACK_SOURCE.DATA.clips["REL-01"])
	cue._model = str(cue._clip.model)
	cue.z_index = 75
	canvas.add_child(cue)
	cue._build()
	return cue


func _build() -> void:
	_texture = RelicArt.load_texture(ContentDatabase.get_clock_relic("REL-01").art_id if _model == "blades" else relic.art_id)
	_relic_skeleton = Skeleton2D.new()
	_relic_skeleton.name = "RelicSkeleton"
	add_child(_relic_skeleton)
	_hanger = _create_relic_bone("root",_relic_skeleton)
	_prop = _create_relic_bone("prop",_hanger)
	_extra = _create_relic_bone("secondary",_hanger)
	for bone_name: String in ["flow","aura","tether"]:
		_create_relic_bone(bone_name,_hanger)
	if _texture != null and _model == "bell" and relic.id == "REL-15":
		_build_articulated_bell()
	elif _texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = _texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var width: float = 158.0 if _model in ["sword", "blades", "hammer", "wedge"] else 128.0
		sprite.scale = Vector2.ONE * width / float(maxi(_texture.get_width(), _texture.get_height()))
		if _model in ["sword", "blades", "hammer", "wedge"]:
			# The hilt, rather than the picture centre, is bound to the hand.
			var grip: Array = _clip.get("grip_uv",[.5,.5])
			sprite.offset = Vector2(_texture.get_size())*(Vector2(.5,.5)-Vector2(float(grip[0]),float(grip[1])))
			sprite.rotation = float(_clip.get("sprite_rotation",0.0))
		_prop.add_child(sprite)
		if _model == "blades":
			var second: Sprite2D = sprite.duplicate() as Sprite2D
			_extra.add_child(second)
	_prop.modulate.a = 0.0
	_extra.modulate.a = 0.0
	_hanger.modulate.a = 0.0 if _model == "bell" else 1.0
	if _model == "siphon" and relic.id == "REL-13" and _texture != null:
		_build_siphon_parts()
	var actor: CanvasItem = _player()
	if actor != null:
		_initial_tint = actor.modulate
	if actor is Executioner3DActor:
		_native_view = Relic3DView.new()
		_native_view.name = "PhysicalRelic3D"
		add_child(_native_view)
		_native_view.configure(actor as Executioner3DActor,relic.id,_model)
		# Keep the existing bone controls for event timing and diagnostics, but
		# render only the genuine volume meshes in the native 3D pass.
		for parent: Node2D in [_prop,_extra,_hanger]:
			for child: Node in parent.get_children():
				if child is Sprite2D or child is Polygon2D: (child as CanvasItem).hide()
	_particles = CPUParticles2D.new()
	_particles.name = "RelicEssenceParticles"
	_particles.texture = AmbientMotion._get_glow_texture()
	_particles.amount = 24
	_particles.lifetime = 0.85
	_particles.emitting = false
	_particles.direction = Vector2(0, -1)
	_particles.spread = 50.0
	_particles.initial_velocity_min = 16.0
	_particles.initial_velocity_max = 48.0
	_particles.gravity = Vector2(0, -18)
	_particles.scale_amount_min = 0.014
	_particles.scale_amount_max = 0.035
	_particles.color = PURPLE
	_particles.local_coords = false
	add_child(_particles)


func _create_relic_bone(bone_name: String, parent: Node2D) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.set_autocalculate_length_and_angle(false)
	bone.length = 30.0
	bone.rest = Transform2D.IDENTITY
	parent.add_child(bone)
	return bone

func _build_articulated_bell() -> void:
	# UV-mapped shell, yoke, rim and clapper articulate independently. The source
	# picture is retained, but the bell is no longer rotated as one flat icon.
	var factor: float = 160.0 / 1280.0
	_add_textured_part(_hanger, [Vector2(102, 8),Vector2(1110, 8),Vector2(1188, 352),Vector2(830, 330),Vector2(670, 252),Vector2(450, 300),Vector2(112, 325)], factor)
	_add_textured_part(_prop, [Vector2(630, 250),Vector2(783, 320),Vector2(891, 558),Vector2(1135, 974),Vector2(1068, 1033),Vector2(878, 978),Vector2(601, 932),Vector2(375, 956),Vector2(198, 1030),Vector2(166, 1002),Vector2(389, 509),Vector2(468, 320)], factor)
	_add_textured_part(_prop, [Vector2(166, 1002),Vector2(224, 1134),Vector2(428, 1210),Vector2(686, 1242),Vector2(979, 1178),Vector2(1146, 1087),Vector2(1135, 974),Vector2(1097, 1080),Vector2(938, 1140),Vector2(697, 1175),Vector2(432, 1154),Vector2(249, 1090)], factor)
	_add_textured_part(_extra, [Vector2(576, 935),Vector2(660, 935),Vector2(688, 1000),Vector2(730, 1070),Vector2(689, 1177),Vector2(620, 1233),Vector2(573, 1180),Vector2(508, 1065),Vector2(535, 991)], factor)
	(_extra.get_child(0) as Node2D).position.y = -675.0*factor


func _add_textured_part(parent: Node2D, points: Array[Vector2], factor: float) -> void:
	var part := Polygon2D.new()
	part.texture = _texture
	part.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var geometry := PackedVector2Array()
	var uv := PackedVector2Array()
	for point: Vector2 in points:
		geometry.append((point - Vector2(640, 260)) * factor)
		uv.append(point)
	part.polygon = geometry
	part.uv = uv
	parent.add_child(part)


func _build_siphon_parts() -> void:
	_siphon_tube = Polygon2D.new()
	_siphon_tube.name = "DeformingPurpleConduit"
	_siphon_tube.z_index = -1
	_siphon_tube.texture = _texture
	_siphon_tube.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_siphon_tube)
	_siphon_enemy = Node2D.new()
	_siphon_enemy.name = "EmbeddedSiphonEnd"
	add_child(_siphon_enemy)
	_siphon_hand = Node2D.new()
	_siphon_hand.name = "SiphonHandEnd"
	add_child(_siphon_hand)
	var inlet: Array[Vector2] = [Vector2(151,62),Vector2(417,128),Vector2(557,324),Vector2(559,427),Vector2(454,568),Vector2(264,482),Vector2(70,322),Vector2(71,223)]
	var outlet: Array[Vector2] = [Vector2(932,654),Vector2(1124,790),Vector2(1220,960),Vector2(1198,1125),Vector2(1093,1204),Vector2(818,1063),Vector2(666,902),Vector2(703,750)]
	_add_textured_part(_siphon_enemy,inlet,.12)
	_add_textured_part(_siphon_hand,outlet,.12)
	(_siphon_enemy.get_child(0) as Node2D).position = (Vector2(640,260)-Vector2(320,300))*.12
	(_siphon_hand.get_child(0) as Node2D).position = (Vector2(640,260)-Vector2(946,932))*.12
	_siphon_tube.hide()
	_siphon_enemy.hide()
	_siphon_hand.hide()


func _update_siphon_parts() -> void:
	if _siphon_tube == null or not _contact:
		return
	_prop.hide()
	var tether: Array = _sample("tether")
	var extension: float = clampf(float(tether[0])/100.0,0.0,1.0)
	var opacity: float = float(tether[5])
	var from: Vector2 = to_local(_enemy_at_contact)
	var to: Vector2 = from.lerp(to_local(_anchor("hand")),extension)
	_siphon_enemy.show()
	_siphon_enemy.position = from
	_siphon_enemy.rotation = -.6
	_siphon_enemy.modulate.a = _prop.modulate.a
	_siphon_hand.visible = extension > .08
	_siphon_hand.position = to
	_siphon_hand.rotation = -.6
	_siphon_hand.modulate.a = opacity
	if extension < .02:
		return
	_siphon_tube.show()
	_siphon_tube.modulate.a = opacity*.85
	var centerline := PackedVector2Array()
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var count: int = 24
	for index: int in count+1:
		var progress: float = index/float(count)
		var center: Vector2 = from.lerp(to,progress)
		center.y += sin(progress*PI)*from.distance_to(to)*.12
		centerline.append(center)
	for edge: int in 2:
		for step: int in count+1:
			var index: int = step if edge == 0 else count-step
			var progress: float = index/float(count)
			var tangent: Vector2 = (centerline[mini(index+1,count)]-centerline[maxi(index-1,0)]).normalized()
			var normal := Vector2(-tangent.y,tangent.x)
			var sign_value: float = 1.0 if edge == 0 else -1.0
			var orb_progress: float = clampf(float(_sample("secondary")[0])/100.0,0.0,1.0)
			var bulge: float = 0.0
			if relic.id == "REL-13" and int(_outcome.get("damage_dealt",0)) > 0:
				bulge = exp(-pow((progress-orb_progress)/.09,2.0))*20.0*float(_sample("secondary")[5])
			vertices.append(centerline[index]+normal*(9.0+bulge)*sign_value)
			# UVs follow the existing purple hose, so its crystalline material
			# stretches with the articulated conduit, not an unrelated beam.
			var uv_center: Vector2 = Vector2(470,460).lerp(Vector2(839,800),progress)
			uv_center += Vector2(-34,32)*sin(progress*PI)
			uvs.append(uv_center+Vector2(-.67,.74)*45*sign_value)
	_siphon_tube.polygon = vertices
	_siphon_tube.uv = uvs


## Called before the controller applies non-damaging outcomes.
func play_prepare() -> void:
	if _running:
		await await_contact()
		return
	var actor: CanvasItem = _player()
	if actor != null and actor.has_method("play_action"):
		actor.call("play_action", str(_clip.actor_action))
	_start()
	await await_contact()


## Call at the same instant as stage.attack(true, profile), never after a
## separate summon wait. Iron Strike's first 1.5 seconds are its summon beat.
func start_attack(profile: Dictionary = {}) -> void:
	if _model == "blades":
		_clip = _clip.duplicate()
		_clip["actor_action"] = str(profile.get("rig_action", "twin_right"))
		_combo_second = int(profile.get("hit_index",0)) > 0
		_combo_hold = int(profile.get("hit_index",0)) < int(profile.get("hit_count",1))-1
		_running = false
		_finished = false
		_resolved = false
		_contact = false
		_notified_resolve = false
		_restored = false
		_target_frozen = false
	_start()


func _start() -> void:
	if _running:
		return
	_clock = 0.0
	_launch = _anchor("hand")
	_running = true
	_apply_frame()


func await_contact() -> void:
	while is_inside_tree() and not _contact:
		await get_tree().process_frame


## The caller passes measured results, never requested/theoretical values.
## A blocked siphon therefore displays no invented healing.
func play_resolve(outcome: Dictionary = {}) -> void:
	_outcome = outcome.duplicate()
	if not _running:
		_start()
	await await_contact()
	_resolved = true
	if not _notified_resolve:
		_notified_resolve = true
		_spawn_outcome_labels()
	while is_inside_tree() and not _finished:
		await get_tree().process_frame
	_restore_tint()


func _process(delta: float) -> void:
	if not _running:
		return
	if _finished:
		if _combo_hold: _apply_frame()
		return
	var speed: float = AudioManager.animation_speed_scale()
	_clock += delta * speed
	if not _resolved and _clock >= float(_clip.contact):
		_clock = float(_clip.contact)
		_contact = true
		if not _target_frozen:
			_enemy_at_contact = _enemy()
			_target_frozen = true
	if _model == "siphon" and relic.id == "REL-13" and _resolved and not _transfer_delivered and _clock >= float(_clip.transfer_end):
		_transfer_delivered = true
		transfer_arrived.emit()
	if _clock >= float(_clip.duration):
		_clock = float(_clip.duration)
		_finished = true
		_particles.emitting = false
	_apply_frame()
	queue_redraw()


func _sample(track_name: String) -> Array:
	var samples: Array = _clip.tracks[track_name]
	var cursor: float = _clock * float(TRACK_SOURCE.DATA.fps)
	var left: int = clampi(int(cursor), 0, samples.size() - 1)
	var right: int = mini(left + 1, samples.size() - 1)
	var weight: float = clampf(cursor - float(left), 0.0, 1.0)
	var a: Array = samples[left]
	var b: Array = samples[right]
	var result: Array = []
	for index: int in 6:
		result.append(lerpf(float(a[index]), float(b[index]), weight))
	return result


func _apply_frame() -> void:
	for control_name: String in ["flow","aura","tether"]:
		var control: Bone2D = _hanger.get_node(control_name) as Bone2D
		var track: Array = _sample(control_name)
		control.position = Vector2(float(track[0]),float(track[1]))
		control.rotation = float(track[2])
		control.scale = Vector2(float(track[3]),float(track[4]))
	var prop_track: Array = _sample("prop")
	var secondary: Array = _sample("secondary")
	var flow: Array = _sample("flow")
	var origin: Vector2 = _anchor(str(_clip.anchor))
	var destination: Vector2 = _enemy_at_contact if _target_frozen else _enemy()
	var is_thrown: bool = str(_clip.anchor) == "hand" and _model not in ["sword", "blades", "hammer", "wedge"]
	var hand_rotation: float = 0.0
	var player_actor: CanvasItem = _player()
	if player_actor != null and player_actor.has_method("get_hand_global_rotation"):
		hand_rotation = float(player_actor.call("get_hand_global_rotation"))
	if is_thrown:
		var release_time: float = float(_clip.get("release", 0.76))
		if _clock <= release_time:
			_launch = origin
			_release_rotation = hand_rotation
		else:
			if not _released:
				_released = true
				if player_actor != null and player_actor.has_method("sample_grip_transform"):
					var grip: Transform2D = player_actor.call("sample_grip_transform",str(_clip.actor_action),release_time)
					_launch = grip.origin
					_release_rotation = grip.get_rotation()
				else:
					_launch = origin
					_release_rotation = hand_rotation
			var travel: float = clampf(float(flow[0]) / 100.0, 0.0, 1.0)
			origin = _launch.lerp(destination, travel)
			if not AudioManager.reduced_motion:
				origin.y -= 4.0 * travel * (1.0 - travel) * 45.0
	var offset := Vector2(float(prop_track[0]), float(prop_track[1]))
	if _model in ["sword", "blades", "hammer", "wedge"]:
		offset = Vector2.ZERO
	_prop.position = to_local(origin) + offset
	_prop.rotation = 0.0 if AudioManager.reduced_motion else float(prop_track[2])
	if not AudioManager.reduced_motion:
		if _model in ["sword", "blades", "hammer", "wedge"]:
			_prop.rotation += hand_rotation
		elif is_thrown:
			var travel_weight: float = clampf(float(flow[0]) / 100.0, 0.0, 1.0)
			_prop.rotation += lerp_angle(_release_rotation, 0.0, travel_weight) if _released else hand_rotation
	_prop.scale = Vector2(float(prop_track[3]), float(prop_track[4]))
	_prop.modulate.a = float(prop_track[5])
	if _model == "blades" and ((_combo_hold and _clock > 1.5) or (_combo_second and _clock < float(_clip.duration)-.2)):
		_prop.modulate.a = 1.0
	if AudioManager.reduced_motion and is_thrown:
		_prop.position = to_local(destination if _contact else _anchor("hand"))
	_last_prop = _prop.position
	if _model == "blades" and player_actor != null:
		if (_combo_hold and _clock > 1.5) or (_combo_second and _clock < 1.5): _prop.scale = Vector2.ONE
		var swinging_left: bool = str(_clip.actor_action) == "twin_left"
		if not AudioManager.reduced_motion and swinging_left: _prop.rotation = hand_rotation - .72
		_extra.position = to_local(player_actor.call("anchor_position", "hand_far", true))
		var far_angle: float = 0.0
		if player_actor is Executioner3DActor:
			far_angle = (player_actor as Executioner3DActor).sample_grip_transform(str(_clip.actor_action),_clock,"hand_far").get_rotation()
		else:
			var far_bone: Bone2D = player_actor.get("_bone_names")["hand_far"]
			far_angle = far_bone.global_rotation
		_extra.rotation = far_angle + (float(secondary[2]) if swinging_left else -.72) if not AudioManager.reduced_motion else 0.0
		_extra.scale = _prop.scale
		_extra.modulate.a = _prop.modulate.a
	if _model == "bell":
		_extra.position = to_local(_anchor("head")) + Vector2(float(secondary[0]),float(secondary[1]))
		if relic.id == "REL-15":
			_extra.position.y += 675.0*160.0/1280.0
		_extra.rotation = 0.0 if AudioManager.reduced_motion else float(secondary[2])
		_extra.modulate.a = float(secondary[5])
		_hanger.position = to_local(_anchor("head")) + Vector2(0, -103)
		_hanger.modulate.a = _prop.modulate.a
	# Authored anchors are in cue space; the skeleton stores parent-relative transforms.
	_prop.position -= _hanger.position
	_extra.position -= _hanger.position
	var aura: Array = _sample("aura")
	var amount: float = float(aura[5])
	if _model == "siphon" and _resolved and int(_outcome.get("damage_dealt",0)) <= 0:
		amount = 0.0
	var aura_color: Color = BLUE if relic.base_block > 0 else PURPLE
	if relic.primary_essence == ClockRelicData.Essence.OVERKILL:
		aura_color = Color("ee528d")
	var actor: CanvasItem = _player()
	if actor != null:
		var tint: Color = _initial_tint.lerp(aura_color.lightened(.25), amount * (.16 if _native_view != null else .38))
		tint.a = actor.modulate.a
		actor.modulate = tint
		if actor.has_method("set_relic_aura"): actor.call("set_relic_aura",aura_color,amount)
	_particles.position = to_local(_anchor("body"))
	_particles.color = aura_color
	_particles.speed_scale = AudioManager.animation_speed_scale()
	_particles.emitting = amount > 0.2 and not _finished and not AudioManager.reduced_motion and relic.id != "REL-13"
	_update_siphon_parts()
	if _native_view != null:
		_native_view.present(_prop.global_position,_extra.global_position,_hanger.global_position,_prop.global_rotation,_extra.global_rotation,_prop.scale,_extra.scale,_prop.modulate.a,_extra.modulate.a,_hanger.modulate.a,_model in ["sword","blades","hammer","wedge"])
		if _siphon_enemy != null:
			_siphon_enemy.hide()
			_siphon_hand.hide()
			_siphon_tube.hide()
			var tether_track: Array = _sample("tether")
			var energy_track: Array = _sample("secondary")
			var life_energy: float = float(energy_track[5]) if _resolved and int(_outcome.get("damage_dealt",0))>0 else 0.0
			_native_view.present_tether(_enemy_at_contact,_anchor("hand"),float(tether_track[0])/100.0,float(energy_track[0])/100.0,float(tether_track[5]),life_energy)


func _draw() -> void:
	if not _running or _clip.is_empty():
		return
	var body: Vector2 = to_local(_anchor("body"))
	var head: Vector2 = to_local(_anchor("head"))
	var hand: Vector2 = to_local(_anchor("hand"))
	var enemy: Vector2 = to_local(_enemy_at_contact if _target_frozen else _enemy())
	var aura: Array = _sample("aura")
	var flow: Array = _sample("flow")
	var glow: float = float(aura[5])
	if _model == "siphon" and _resolved and int(_outcome.get("damage_dealt",0)) <= 0:
		glow = 0.0
	if glow > .01:
		var color: Color = BLUE if relic.base_block > 0 else PURPLE
		if relic.primary_essence == ClockRelicData.Essence.OVERKILL:
			color = Color("ee528d")
		_draw_aura(body, color, glow, float(aura[3]))
	if _model == "sword" and _clock < 1.5:
		var intensity: float = sin(clampf(_clock / 1.5, 0.0, 1.0) * PI)
		_draw_aura(hand, Color("ffd6a0"), intensity * .75, .30)
	if _model == "chalice" and float(flow[5]) > .01:
		_draw_conduit(_last_prop + Vector2(-24, -5), head + Vector2(0,35), PURPLE, float(flow[5]), 0.0, true)
	if _model in ["oil", "censer", "leech"] and float(flow[5]) > .01:
		var reach: float = clampf(float(flow[0])/100.0,0.0,1.0)
		_draw_conduit(_last_prop, _last_prop.lerp(enemy,reach), GREEN, float(flow[5]), .30, false)
	if _model == "siphon" and _contact:
		var tether: Array = _sample("tether")
		var extension: float = clampf(float(tether[0]) / 100.0, 0.0, 1.0)
		var end: Vector2 = enemy.lerp(hand, extension)
		# The channel grows from the embedded enemy end toward the hand.
		# Pulses then travel in that same enemy -> player direction.
		var transferring: bool = extension >= .98 and int(_outcome.get("damage_dealt",0)) > 0
		if relic.id == "REL-13" and _native_view == null:
			if transferring and float(_sample("secondary")[5]) > .01:
				var energy: Array = _sample("secondary")
				var progress: float = clampf(float(energy[0])/100.0,0.0,1.0)
				var orb: Vector2 = enemy.lerp(hand,progress)
				orb.y += sin(progress*PI)*enemy.distance_to(hand)*.12
				var opacity: float = float(energy[5])
				draw_circle(orb,30.0,Color(GREEN,opacity*.14))
				draw_circle(orb,21.0,Color(GREEN,opacity*.55))
				draw_circle(orb,13.0,Color(GREEN.lightened(.45),opacity))
		elif relic.id != "REL-13":
			_draw_conduit(enemy, end, PURPLE, float(tether[5]), .12, false, transferring)
	if _model == "bell" and _clock > .5 and _clock < 2.5 and not AudioManager.reduced_motion:
		var ring: float = fmod((_clock - .5) * 1.5, 1.0)
		for index: int in 3:
			var phase: float = fmod(ring + index / 3.0, 1.0)
			draw_arc(_last_prop + Vector2(0,75), 36 + phase * 75, .2, PI - .2, 32, Color(BLUE,(1.0-phase)*.5), 2.0,true)
	if _model in ["thorns", "wall", "ward", "battery", "reservoir"] and glow > .01:
		_draw_ward(body, glow)
	if _model == "crown" and _clock > .85:
		draw_arc(head + Vector2(0,-22), 50, PI, TAU, 24, Color(PURPLE,_prop.modulate.a*.55),3,true)


func _draw_aura(center: Vector2, color: Color, strength: float, radius_scale: float) -> void:
	var factor: float = maxf(.15, radius_scale)
	for layer: int in 4:
		var points := PackedVector2Array()
		for index: int in 65:
			var angle: float = TAU * float(index) / 64.0
			var ripple: float = 1.0 if AudioManager.reduced_motion else 1.0 + sin(angle * 5 + _clock * 3.0) * .025
			points.append(center + Vector2(cos(angle) * (95 + layer * 8),sin(angle) * (150 + layer * 4)) * factor * ripple)
		draw_polyline(points,Color(color,strength * (.30 - layer * .065)),9.0-layer*1.6,true)
	if AudioManager.reduced_motion:
		return
	for index: int in 12:
		var phase: float = fmod(_clock*.28+index/12.0,1.0)
		var angle: float = TAU*float(index)/12.0+_clock*.4
		var at: Vector2 = center+Vector2(cos(angle)*88*factor,(.5-phase)*255*factor)
		draw_circle(at,2.0,Color(color,strength*sin(phase*PI)))


func _draw_conduit(from: Vector2, to: Vector2, color: Color, opacity: float, sag: float, pour: bool, pulses: bool = true) -> void:
	if opacity < .01:
		return
	var points := PackedVector2Array()
	var distance: float = from.distance_to(to)
	for index: int in 41:
		var amount: float = index / 40.0
		var at: Vector2 = from.lerp(to,amount)
		at.y += sin(amount*PI)*distance*sag
		if not AudioManager.reduced_motion:
			at += Vector2(sin(_clock*7+amount*TAU*2),cos(_clock*4+amount*TAU))*4.0*sin(amount*PI)
		points.append(at)
	draw_polyline(points,Color(color,opacity*.12),28 if not pour else 22,true)
	draw_polyline(points,Color(color,opacity*.32),16 if not pour else 12,true)
	draw_polyline(points,Color(color.lightened(.2),opacity*.9),6 if not pour else 5,true)
	draw_polyline(points,Color(color.lightened(.7),opacity*.65),1.5,true)
	if pulses and not AudioManager.reduced_motion:
		for index: int in 7:
			var progress: float = fmod(_clock*.70+index/7.0,1.0)
			var point: Vector2 = points[clampi(int(progress*40),0,40)]
			draw_circle(point,5.0,Color(color.lightened(.7),opacity*.95))
	if pour:
		for index: int in 10:
			var progress: float = fmod(_clock*.7+index/10.0,1.0)
			var drop: Vector2 = from.lerp(to,progress)+Vector2(sin(index*2.4)*12*progress,0)
			draw_circle(drop,2.0+progress*2,Color(color.lightened(.4),opacity*(1-progress*.6)))


func _draw_ward(center: Vector2, glow: float) -> void:
	for index: int in 6:
		var angle: float = index*TAU/6.0-PI*.5
		var at: Vector2 = center+Vector2(cos(angle)*105,sin(angle)*145)
		if _model == "thorns":
			var spike := PackedVector2Array([at+Vector2(-7,8),at+Vector2(0,-18),at+Vector2(7,8)])
			draw_colored_polygon(spike,Color(PURPLE,glow*.75))
		else:
			draw_arc(at,12,0,TAU,6,Color(BLUE,glow*.8),3,true)


func _spawn_outcome_labels() -> void:
	var delay: float = .0
	var gained_block: int = int(_outcome.get("block_gained",0))
	if gained_block > 0:
		_fly_label("+%d BLOCK" % gained_block, BLUE, _anchor("body"), delay)
		delay += .18
	var gained_strength: int = int(_outcome.get("strength_gained",0))
	if gained_strength > 0:
		_fly_label("+%d STRENGTH" % gained_strength,PURPLE,_anchor("body"),delay)
		delay += .18
	var healed: int = int(_outcome.get("healed",0))
	if healed > 0 and relic.id != "REL-13":
		_fly_label("+%d HEAL" % healed,PURPLE,_enemy_at_contact,.55)
	var multiplier: int = int(_outcome.get("next_attack_multiplier",1))
	if multiplier > 1:
		_fly_label("NEXT ATTACK x%d" % multiplier,PURPLE,_enemy_at_contact,.1)
	var gained_overkill: int = int(_outcome.get("overkill_gained",0))
	if gained_overkill > 0:
		_fly_label("+%d OVERKILL" % gained_overkill,Color("f16b9e"),_anchor("body"),delay)


func _fly_label(text: String, color: Color, from_global: Vector2, delay: float) -> void:
	var lane: int = _label_count
	_label_count += 1
	var label := Label.new()
	label.name = "RelicOutcome"
	label.text = text
	label.add_theme_font_size_override("font_size",22)
	label.add_theme_color_override("font_color",color.lightened(.22))
	label.add_theme_color_override("font_outline_color",Color("080d16"))
	label.add_theme_constant_override("outline_size",6)
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(.025,.04,.065,.88)
	backing.border_color = Color(color,.45)
	backing.set_border_width_all(1)
	backing.set_corner_radius_all(5)
	backing.content_margin_left = 9
	backing.content_margin_right = 9
	backing.content_margin_top = 3
	backing.content_margin_bottom = 3
	label.add_theme_stylebox_override("normal",backing)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(280,36)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 110
	label.modulate.a = 0.0
	label.position = to_local(from_global)+Vector2(-140,-45-lane*40)
	add_child(label)
	var destination: Vector2 = buff_target_global
	if destination == Vector2.ZERO:
		destination = _anchor("body")+Vector2(0,195)
	var tween: Tween = label.create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	tween.tween_interval(delay)
	tween.tween_property(label,"modulate:a",1.0,.12)
	tween.tween_interval(.45)
	tween.tween_property(label,"position",to_local(destination)+Vector2(-140,-64-lane*40),.62 if not AudioManager.reduced_motion else .08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(.10)
	tween.tween_property(label,"modulate:a",0.0,.20)
	tween.tween_callback(label.queue_free)


func _player() -> CanvasItem:
	if not is_instance_valid(_stage):
		return null
	return _stage.get("player") as CanvasItem


func _anchor(key: String) -> Vector2:
	var actor: CanvasItem = _player()
	if actor == null:
		return global_position+Vector2(450,500)
	if key == "head" and actor.has_method("get_head_global_position"):
		return actor.call("get_head_global_position") as Vector2
	if key == "hand" and actor.has_method("get_hand_global_position"):
		return actor.call("get_hand_global_position") as Vector2
	if actor.has_method("anchor_position"):
		return actor.call("anchor_position","chest" if key == "body" else key,true) as Vector2
	var control: Control = actor as Control
	if control != null:
		return control.global_position + control.size * (Vector2(.5,.34) if key == "head" else Vector2(.5,.65))
	return global_position


func _enemy() -> Vector2:
	if not is_instance_valid(_stage):
		return global_position+Vector2(950,500)
	var actor: Control = _stage.get("enemy") as Control
	if actor == null:
		return global_position+Vector2(950,500)
	if actor.has_method("anchor_position"):
		return actor.call("anchor_position","chest",true) as Vector2
	return actor.global_position+actor.size*Vector2(.5,.61)


func _restore_tint() -> void:
	if _restored:
		return
	_restored = true
	var actor: CanvasItem = _player()
	if actor != null:
		var tint: Color = _initial_tint
		tint.a = actor.modulate.a
		actor.modulate = tint
		if actor.has_method("set_relic_aura"): actor.call("set_relic_aura",Color.WHITE,0.0)


func dispose() -> void:
	_restore_tint()
	_running = false
	if is_instance_valid(_particles):
		_particles.emitting = false
	# Labels finish their measured-outcome trip even if the next clock beat is
	# ready. All effects are children, so a scene transition still clears them.
	var tween: Tween = create_tween().set_speed_scale(AudioManager.animation_speed_scale())
	tween.tween_interval(.78)
	tween.tween_callback(queue_free)


func _exit_tree() -> void:
	_restore_tint()
