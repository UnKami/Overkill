class_name ClockworkStage extends SubViewportContainer
## Transparent, antialiased real-time 3D battle vignette embedded in the clock arena.
var player: ClockworkActor
var enemy: ClockworkActor
var _world: Node3D
var _camera: Camera3D
var _view: SubViewport
var _enemy_kind: String = "stalker"
var _camera_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	_view = SubViewport.new()
	_view.transparent_bg = true
	_view.size = Vector2i(960, 800)
	_view.msaa_3d = Viewport.MSAA_2X
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view.own_world_3d = true
	add_child(_view)
	_world = Node3D.new()
	_view.add_child(_world)
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("97b8d0")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	_world.add_child(world_env)
	_camera = Camera3D.new()
	_world.add_child(_camera)
	_camera.position = Vector3(0, 2.65, 7.6)
	_camera.look_at(Vector3(0, 1.35, 0))
	_camera.fov = 36
	_light(Vector3(-3, 4, 4), Color("9ce9ff"), 7.0)
	_light(Vector3(3, 4, 1), Color("ffc38b"), 9.0)
	_light(Vector3(0, 4, -3), Color("7198eb"), 11.0)
	player = ClockworkActor.new()
	_world.add_child(player)
	player.position.x = -0.98
	player.rotation.y = 0.52
	_replace_enemy()
	_build_dais()

func _light(at: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 10.0
	_world.add_child(light)

func _build_dais() -> void:
	var surface := player.material(Color("17232e"), 0.75, 0.3)
	for side in [-1.0, 1.0]:
		var base := player.cylinder(_world, Vector3(side * 0.98, -0.08, 0), 0.88, 0.97, 0.12, surface)
		var ring := player.ring(_world, Vector3(side * 0.98, -0.005, 0), 0.84, 0.018, player._gold)
		ring.rotation.x = 0
		for n in range(24):
			var angle := float(n) * TAU / 24.0
			var mark := player.box(_world, Vector3(side * 0.98 + sin(angle) * 0.82, 0.002, cos(angle) * 0.82), Vector3(0.018, 0.015, 0.07), player._glow)
			mark.rotation.y = angle
		base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func configure_enemy(kind: String) -> void:
	_enemy_kind = kind
	if is_node_ready(): _replace_enemy()

func _replace_enemy() -> void:
	if is_instance_valid(enemy):
		_world.remove_child(enemy)
		enemy.queue_free()
	enemy = ClockworkActor.new()
	enemy.hostile = true
	enemy.archetype = _enemy_kind
	_world.add_child(enemy)
	enemy.position.x = 0.98
	enemy.rotation.y = -0.52

func attack(from_player: bool, _profile: Dictionary = {}) -> void:
	(player if from_player else enemy).attack()

func impact(on_player: bool, blocked: bool, _profile: Dictionary = {}) -> void:
	(player if on_player else enemy).hit(blocked)
	if not AudioManager.reduced_motion:
		if _camera_tween and _camera_tween.is_valid(): _camera_tween.kill()
		_camera.h_offset = -0.045 if on_player else 0.045
		_camera_tween = create_tween()
		_camera_tween.tween_property(_camera, "h_offset", 0.0, 0.16)

func finish(won: bool) -> void:
	(enemy if won else player).fall()

func set_intro_hidden() -> void:
	player.hide()
	enemy.hide()

func reveal_combatant(from_player: bool) -> void:
	var actor: Node3D = player if from_player else enemy
	actor.show()
	if AudioManager.reduced_motion: return
	var target_scale: Vector3 = actor.scale
	actor.scale = target_scale * 0.82
	actor.create_tween().set_speed_scale(AudioManager.animation_speed_scale()).tween_property(actor,"scale",target_scale,0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
