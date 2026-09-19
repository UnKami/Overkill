class_name CustodianActor extends Node3D
## Custodian battle adapter for the opt-in encounter preview.
signal contact_reached

enum State { IDLE, ATTACK, GUARD, RECOIL, DEAD }
const CONTACT_TIME: float = 14.0 / 30.0
const ATTACK_LENGTH: float = 36.0 / 30.0
var state: State = State.IDLE
var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var _clips: Dictionary = {}
var _contact_sent: bool = false
var _guard_held: bool = false
var _dead: bool = false
var _visor: StandardMaterial3D
var _shutdown_time: float = 0.0
var _visor_energy: float = 0.0
var _visor_color: Color
const GUARD_HOLD_TIME: float = 9.0 / 30.0

func _ready() -> void:
	model = preload("res://assets/characters/rigged/custodian-study.glb").instantiate()
	add_child(model)
	CustodianMaterials.apply(model)
	_bind_visor()
	model.rotation.y = PI
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	animation = model.find_children("*", "AnimationPlayer", true, false)[0]
	# Manual advancement keeps contact crossing and interruption in the same clock.
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: StringName in animation.get_animation_list():
		for key: String in ["custodian_idle", "custodian_attack", "custodian_guard", "custodian_hit", "custodian_collapse"]:
			if key in str(clip): _clips[key] = clip
	assert(_clips.size() == 5)
	_play("custodian_idle", 0.0)

func _bind_visor() -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var body: MeshInstance3D = node
		for surface: int in body.mesh.get_surface_count():
			var source: Material = body.mesh.surface_get_material(surface)
			if source.resource_name == "Custodian_Amber":
				_visor = source.duplicate() as StandardMaterial3D
				_visor_energy = _visor.emission_energy_multiplier
				_visor_color = _visor.albedo_color
				body.set_surface_override_material(surface, _visor)

func _process(delta: float) -> void:
	advance_motion(delta * AudioManager.animation_speed_scale())

func advance_motion(seconds: float) -> void:
	if state == State.DEAD:
		_shutdown_time += seconds
		if _visor:
			_visor.emission_energy_multiplier = _visor_energy * (1.0 - smoothstep(0.25, 1.05, _shutdown_time))
			_visor.albedo_color = _visor_color.lerp(Color(0.06, 0.03, 0.005), smoothstep(0.25, 1.05, _shutdown_time))
	var before: float = animation.current_animation_position
	if state == State.GUARD and _guard_held:
		animation.advance(minf(seconds, maxf(0.0, GUARD_HOLD_TIME - before)))
		skeleton.force_update_all_bone_transforms()
		return
	if state == State.ATTACK and not _contact_sent and before + seconds >= CONTACT_TIME:
		var until_contact: float = maxf(0.0, CONTACT_TIME - before)
		animation.advance(until_contact)
		skeleton.force_update_all_bone_transforms()
		_contact_sent = true
		contact_reached.emit()
		# A contact listener may kill or interrupt this actor synchronously.
		# Remaining time belongs to the new state, never the cancelled attack.
		advance_motion(maxf(0.0, seconds - until_contact))
		return
	var length: float = animation.current_animation_length
	animation.advance(seconds)
	skeleton.force_update_all_bone_transforms()
	if before + seconds < length: return
	if state == State.DEAD:
		animation.seek(length, true)
	elif state == State.IDLE:
		_play("custodian_idle", 0.0)
	else:
		state = State.IDLE
		_play("custodian_idle", 0.08)

func _play(key: String, blend: float) -> void:
	animation.stop(true)
	animation.play(_clips[key], blend)
	animation.advance(0.0)

func attack() -> void:
	if state == State.DEAD: return
	_guard_held = false
	state = State.ATTACK
	_contact_sent = false
	_play("custodian_attack", 0.06)

func hit(blocked: bool) -> void:
	if state == State.DEAD: return
	if blocked and state == State.GUARD and _guard_held:
		_guard_held = false
		return # Release the existing brace; do not restart its raise at impact.
	_guard_held = false
	state = State.GUARD if blocked else State.RECOIL
	_play("custodian_guard" if blocked else "custodian_hit", 0.025)

func fall() -> void:
	if state == State.DEAD: return
	_dead = true
	_guard_held = false
	state = State.DEAD
	_play("custodian_collapse", 0.08)

func prepare_guard() -> void:
	if state == State.DEAD: return
	if state == State.GUARD and _guard_held: return
	state = State.GUARD
	_guard_held = true
	_play("custodian_guard", 0.025)

func is_guarding() -> bool:
	return state == State.GUARD

func guard_contact_point(attacker_position: Vector3) -> Vector3:
	# Meet the armored right forearm rather than the ribcage behind it.
	var bracer: Vector3 = bone_point("forearm.R").lerp(bone_point("hand.R"), 0.65)
	return bracer + (attacker_position - bracer).normalized() * 0.035

func contact_time() -> float:
	return CONTACT_TIME

func recovery_time() -> float:
	return ATTACK_LENGTH - CONTACT_TIME

func at_contact() -> bool:
	return state != State.ATTACK or _contact_sent

func prepare_contact() -> void:
	if state != State.ATTACK: return
	animation.seek(CONTACT_TIME, true)
	skeleton.force_update_all_bone_transforms()

func bone_point(bone: String) -> Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin)

func claw_tip() -> Vector3:
	var index: int = skeleton.find_bone("f_middle.03.R")
	var pose: Transform3D = skeleton.get_bone_global_pose(index)
	return skeleton.to_global(pose * Vector3(0.0, 0.045, 0.0))
