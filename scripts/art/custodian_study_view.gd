extends Node3D
## Isolated look-development scene, not an encounter or production character.

var _player: AnimationPlayer
var _idle_clip: StringName

func _ready() -> void:
	var model: Node3D = $Model
	assert(CustodianMaterials.apply(model) == 2)
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
	instructions.text = "CUSTODIAN • ART STUDY\nA: Attack     G: Guard     H: Hit     R: Idle"
	instructions.position = Vector2(24, 24)
	instructions.add_theme_font_size_override("font_size", 20)
	overlay.add_child(instructions)

func play_guard() -> void:
	if _player and _player.has_animation("custodian_guard"):
		_player.get_animation("custodian_guard").loop_mode = Animation.LOOP_NONE
		_player.play("custodian_guard", 0.08)

func play_attack() -> void:
	if _player and _player.has_animation("custodian_attack"):
		_player.get_animation("custodian_attack").loop_mode = Animation.LOOP_NONE
		_player.play("custodian_attack", 0.08)

func play_hit() -> void:
	if _player and _player.has_animation("custodian_hit"):
		_player.get_animation("custodian_hit").loop_mode = Animation.LOOP_NONE
		if _player.assigned_animation == &"custodian_hit":
			_player.stop(true)
		_player.play("custodian_hit", 0.035)

func _return_to_idle(_finished: StringName = &"") -> void:
	if _player:
		_player.play(_idle_clip, 0.12)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			play_guard()
		elif event.keycode == KEY_A:
			play_attack()
		elif event.keycode == KEY_H:
			play_hit()
		elif event.keycode == KEY_R:
			_return_to_idle()
