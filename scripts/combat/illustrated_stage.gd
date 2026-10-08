class_name IllustratedStage extends Control
## Authored high-detail pose animation, matching the illustrated environment.
var player: IllustratedActor
var enemy: IllustratedActor
var _kind: String = "stalker"
var _art_id: String = ""
var _shadows: Dictionary = {}
var _last_attack_profile: Dictionary = {}
var _has_configured_enemy: bool = false

func _process(_delta: float) -> void:
	for actor: IllustratedActor in [player, enemy]:
		if not is_instance_valid(actor) or not actor.has_method("anchor_position"):
			continue
		var shadow_value: Variant = _shadows.get(actor.get_instance_id())
		if not is_instance_valid(shadow_value):
			continue
		var shadow: Polygon2D = shadow_value as Polygon2D
		var feet: Vector2 = get_global_transform().affine_inverse() * (actor.call("anchor_position", "feet", true) as Vector2)
		shadow.position.x = feet.x
		var height: float = maxf(0.0, shadow.position.y - feet.y)
		var grounded: float = clampf(1.0-height/90.0,0.45,1.0)
		shadow.scale = Vector2(lerpf(0.72,1.0,grounded),lerpf(0.6,1.0,grounded))
		shadow.modulate.a = actor.modulate.a*grounded

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = _actor("res://assets/characters/executioner/combat_sprite.png", 1.0, Vector2(-221, -5))
	_replace_enemy()

func _actor(path: String, facing: float, at: Vector2) -> IllustratedActor:
	var actor: IllustratedActor = preload("res://scripts/combat/meshy_battle_actor.gd").new() if facing > 0.0 else preload("res://scripts/combat/enemy_rig_actor.gd").new()
	if ResourceLoader.exists(path):
		actor.atlas = load(path)
		actor.target_height = 432.0
		actor.target_width = 662.0
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
	_shadows[actor.get_instance_id()] = shadow
	actor.tree_exiting.connect(_release_shadow.bind(actor.get_instance_id()))
	return actor

func _release_shadow(actor_id: int) -> void:
	var shadow_value: Variant = _shadows.get(actor_id)
	_shadows.erase(actor_id)
	if is_instance_valid(shadow_value): shadow_value.queue_free()

func configure_enemy(kind: String, art_id: String = "") -> void:
	_kind = kind
	_art_id = art_id
	if is_node_ready():
		_replace_enemy(_has_configured_enemy)
		_has_configured_enemy = true

func _replace_enemy(animate_reinforcement: bool = false) -> void:
	var departing_enemy: IllustratedActor = enemy if is_instance_valid(enemy) and animate_reinforcement else null
	if is_instance_valid(enemy) and not animate_reinforcement:
		remove_child(enemy)
		enemy.queue_free()
	var path := _enemy_art_path(_art_id if not _art_id.is_empty() else _kind)
	enemy = _actor(path, -1.0, Vector2(309, -5))
	if departing_enemy != null:
		_animate_reinforcement(departing_enemy, enemy)


func _animate_reinforcement(departing: IllustratedActor, incoming: IllustratedActor) -> void:
	# A brief crystalline handoff makes a kill legible before the next enemy acts.
	var departure := departing.create_tween().set_parallel(true).set_speed_scale(AudioManager.combat_animation_speed_scale())
	departure.tween_property(departing, "modulate:a", 0.0, 0.15)
	departure.tween_property(departing, "position:y", departing.position.y + 20.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var departing_shadow: Variant = _shadows.get(departing.get_instance_id())
	if is_instance_valid(departing_shadow):
		departure.tween_property(departing_shadow, "modulate:a", 0.0, 0.15)
	departure.chain().tween_callback(departing.queue_free)
	incoming.pivot_offset = incoming.size * Vector2(0.5, 0.82)
	incoming.position += Vector2(58.0, -8.0)
	incoming.scale = Vector2(0.88, 0.88)
	incoming.modulate.a = 0.0
	var arrival := incoming.create_tween().set_speed_scale(AudioManager.combat_animation_speed_scale())
	arrival.tween_interval(0.10)
	arrival.tween_property(incoming, "position", Vector2(309.0, -5.0), 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.parallel().tween_property(incoming, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrival.parallel().tween_property(incoming, "modulate:a", 1.0, 0.16)


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


func await_player_recovery() -> void:
	while is_instance_valid(player) and player._busy:
		await get_tree().process_frame


func finish_delay() -> float:
	# Controller divides this legacy timing unit by combat speed. The skeletal
	# fall uses authored seconds, so Fast Mode must still reach its final pose.
	return maxf(0.8, 1.1 * AudioManager.combat_animation_speed_scale() / AudioManager.animation_speed_scale())


func set_intro_hidden() -> void:
	for actor: IllustratedActor in [player, enemy]:
		actor.hide()
		var shadow: CanvasItem = _shadows.get(actor.get_instance_id())
		if shadow != null: shadow.hide()


func reveal_combatant(from_player: bool) -> void:
	var actor: IllustratedActor = player if from_player else enemy
	var shadow: CanvasItem = _shadows.get(actor.get_instance_id())
	actor.show()
	if shadow != null: shadow.show()
	actor.modulate.a = 1.0
	if from_player and actor.has_method("begin_entrance"):
		var battle: Node = get_parent().get_parent().get_parent()
		var clock: Control = battle.get_node("CombatArena/PlayerChronometer")
		actor.call("begin_entrance", clock.global_position + Vector2(clock.size.x * 0.5, clock.size.y * 0.25))
		return
	if AudioManager.reduced_motion: return
	actor.scale = Vector2(0.82, 0.82)
	actor.modulate.a = 0.0
	var reveal := actor.create_tween().set_parallel(true).set_speed_scale(AudioManager.combat_animation_speed_scale())
	reveal.tween_property(actor, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(actor, "modulate:a", 1.0, 0.16)

