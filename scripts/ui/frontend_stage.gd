extends DirectedArena
## The same lit world and animated character as combat, framed for navigation.
var character_view := false
var _base_position: Vector3

func _ready() -> void:
	super._ready()
	enemy.hide()
	player.position = Vector3(0.45,0,0.4)
	player.rotation.y = -0.35
	_camera.position = Vector3(0,1.8,5.6 if character_view else 6.5)
	_camera.fov = 32
	_camera.look_at(Vector3(-0.85,1.10,0))
	_base_position = _camera.position
	player.opponent = enemy

func _process(delta: float) -> void:
	super._process(delta)
	if AudioManager.reduced_motion: return
	_camera.position.x = _base_position.x + sin(_elapsed*0.12)*0.035
