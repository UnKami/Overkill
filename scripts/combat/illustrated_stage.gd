class_name IllustratedStage extends Control
## Authored high-detail pose animation, matching the illustrated environment.
var player: IllustratedActor
var enemy: IllustratedActor
var _kind: String = "stalker"
var _art_id: String = ""
var _shadows: Dictionary = {}
var _last_attack_profile: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = _actor("res://assets/characters/executioner/combat_sprite.png", 1.0, Vector2(-221, -5))
	_replace_enemy()

func _actor(path: String, facing: float, at: Vector2) -> IllustratedActor:
	var actor := IllustratedActor.new()
	if ResourceLoader.exists(path):
		actor.atlas = load(path)
		actor.target_height = 360.0
		actor.target_width = 552.0
	actor.facing = facing
	actor.position = at
	actor.size = Vector2(552, 624)
	var shadow: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = []
	for i: int in 32:
		var angle: float = TAU * i / 32.0
		points.append(Vector2(cos(angle) * 82, sin(angle) * 11))
	shadow.polygon = points
	shadow.color = Color(0.015,0.02,0.025,0.38)
	shadow.position = at + Vector2(276,574)
	add_child(shadow)
	add_child(actor)
	_shadows[actor] = shadow
	actor.tree_exiting.connect(shadow.queue_free)
	return actor

func configure_enemy(kind: String, art_id: String = "") -> void:
	_kind = kind
	_art_id = art_id
	if is_node_ready(): _replace_enemy()

func _replace_enemy() -> void:
	if is_instance_valid(enemy):
		remove_child(enemy)
		enemy.queue_free()
	var path := _enemy_art_path(_art_id if not _art_id.is_empty() else _kind)
	enemy = _actor(path, -1.0, Vector2(309, -5))


func _enemy_art_path(enemy_id: String) -> String:
	var candidates: Array[String] = []
	for act: int in range(1, 4):
		candidates.append("res://assets/enemies/act%d/%s.png" % [act, enemy_id])
		candidates.append("res://assets/enemies/act%d/%s_idle.png" % [act, enemy_id])
	candidates.append("res://assets/enemies/%s.png" % enemy_id)
	candidates.append("res://assets/enemies/%s_idle.png" % enemy_id)
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return candidate
	return "res://assets/enemies/act1/boneghoul_crystalline.png"

func attack(from_player: bool, profile: Dictionary = {}) -> void:
	_last_attack_profile = profile
	(player if from_player else enemy).attack(profile)

func impact(on_player: bool, blocked: bool, _profile: Dictionary = {}) -> void:
	(player if on_player else enemy).hit(blocked, _profile)

func finish(won: bool) -> void:
	(enemy if won else player).fall()

func await_contact(from_player: bool) -> void:
	var actor: IllustratedActor = player if from_player else enemy
	while is_instance_valid(actor) and not actor._contact_ready:
		await get_tree().process_frame

func recovery_delay() -> float:
	return float(_last_attack_profile.get("recovery", 0.40))


func set_intro_hidden() -> void:
	for actor: IllustratedActor in [player, enemy]:
		actor.hide()
		var shadow: CanvasItem = _shadows.get(actor)
		if shadow != null: shadow.hide()


func reveal_combatant(from_player: bool) -> void:
	var actor: IllustratedActor = player if from_player else enemy
	var shadow: CanvasItem = _shadows.get(actor)
	actor.show()
	if shadow != null: shadow.show()
	actor.modulate.a = 1.0
	if AudioManager.reduced_motion: return
	actor.scale = Vector2(0.82, 0.82)
	actor.modulate.a = 0.0
	var reveal := actor.create_tween().set_parallel(true).set_speed_scale(AudioManager.combat_animation_speed_scale())
	reveal.tween_property(actor, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(actor, "modulate:a", 1.0, 0.16)
