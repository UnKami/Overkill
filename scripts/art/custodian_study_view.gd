extends Node3D
## Isolated look-development scene, not an encounter or production character.

var _player: AnimationPlayer
var _idle_clip: StringName
var _visor: StandardMaterial3D
var _visor_color: Color
var _visor_energy: float
var _visor_tween: Tween

func _ready() -> void:
	var model: Node3D = $Model
	assert(CustodianMaterials.apply(model) == 2)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		for surface: int in mesh_instance.mesh.get_surface_count():
			var source: Material = mesh_instance.mesh.surface_get_material(surface)
			if source is StandardMaterial3D and source.resource_name == "Custodian_Amber":
				_visor = source.duplicate() as StandardMaterial3D
				_visor_color = _visor.albedo_color
				_visor_energy = _visor.emission_energy_multiplier
				mesh_instance.set_surface_override_material(surface, _visor)
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_player = players[0] as AnimationPlayer
		for clip: StringName in _player.get_animation_list():
			if "idle" in str(clip):
				_idle_clip = clip
				_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				_player.play(clip)
				break
		_player.animation_finished.connect(_return_to_idle)
	$Camera3D.look_at(Vector3(0, 1.07, 0))
	var overlay: CanvasLayer = CanvasLayer.new()
	add_child(overlay)
	var instructions: Label = Label.new()
	instructions.text = "CUSTODIAN • ART STUDY\nA: Attack     G: Guard     H: Hit     D: Defeat     R: Idle"
	instructions.position = Vector2(24, 24)
	instructions.add_theme_font_size_override("font_size", 20)
	overlay.add_child(instructions)

func play_guard() -> void:
	if _player and _player.has_animation("custodian_guard"):
		_restore_visor()
		_player.get_animation("custodian_guard").loop_mode = Animation.LOOP_NONE
		_player.play("custodian_guard", 0.08)

func play_attack() -> void:
	if _player and _player.has_animation("custodian_attack"):
		_restore_visor()
		_player.get_animation("custodian_attack").loop_mode = Animation.LOOP_NONE
		_player.play("custodian_attack", 0.08)

func play_hit() -> void:
	if _player and _player.has_animation("custodian_hit"):
		_restore_visor()
		_player.get_animation("custodian_hit").loop_mode = Animation.LOOP_NONE
		if _player.assigned_animation == &"custodian_hit":
			_player.stop(true)
		_player.play("custodian_hit", 0.035)

func _return_to_idle(_finished: StringName = &"") -> void:
	if _finished == &"custodian_collapse":
		return
	if _player:
		_restore_visor()
		_player.play(_idle_clip, 0.12)

func play_collapse() -> void:
	if _player and _player.has_animation("custodian_collapse"):
		_player.get_animation("custodian_collapse").loop_mode = Animation.LOOP_NONE
		if _player.assigned_animation == &"custodian_collapse":
			_player.stop(true)
		_player.play("custodian_collapse", 0.08)
		if _visor:
			_restore_visor()
			_visor_tween = create_tween().set_parallel(true)
			_visor_tween.tween_property(_visor, "emission_energy_multiplier", 0.0, 0.8).set_delay(0.25)
			_visor_tween.tween_property(_visor, "albedo_color", Color(0.06, 0.03, 0.005), 0.8).set_delay(0.25)

func _restore_visor() -> void:
	if _visor_tween:
		_visor_tween.kill()
		_visor_tween = null
	if _visor:
		_visor.albedo_color = _visor_color
		_visor.emission_energy_multiplier = _visor_energy

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			play_guard()
		elif event.keycode == KEY_A:
			play_attack()
		elif event.keycode == KEY_H:
			play_hit()
		elif event.keycode == KEY_D:
			play_collapse()
		elif event.keycode == KEY_R:
			_return_to_idle()
