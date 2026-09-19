extends Node3D
## Isolated look-development scene, not an encounter or production character.

func _ready() -> void:
	var model: Node3D = $Model
	assert(CustodianMaterials.apply(model) == 2)
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var player: AnimationPlayer = players[0] as AnimationPlayer
		for clip: StringName in player.get_animation_list():
			if "idle" in str(clip):
				player.play(clip)
				break
	$Camera3D.look_at(Vector3(0, 1.07, 0))
