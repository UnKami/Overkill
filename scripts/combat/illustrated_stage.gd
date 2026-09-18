extends Control
## Authored high-detail pose animation, matching the illustrated environment.
var player: IllustratedActor
var enemy: IllustratedActor
var _kind: String = "stalker"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	player = _actor("res://assets/characters/executioner/executioner_combat_atlas_v2.png", 1.0, Vector2(-70, -45))
	_replace_enemy()

func _actor(path: String, facing: float, at: Vector2) -> IllustratedActor:
	var actor := IllustratedActor.new()
	if ResourceLoader.exists(path): actor.atlas = load(path)
	actor.facing = facing
	actor.position = at
	actor.size = Vector2(460, 520)
	add_child(actor)
	return actor

func configure_enemy(kind: String) -> void:
	_kind = kind
	if is_node_ready(): _replace_enemy()

func _replace_enemy() -> void:
	if is_instance_valid(enemy):
		remove_child(enemy)
		enemy.queue_free()
	var path := "res://assets/enemies/revenant_combat_atlas_v2.png"
	if _kind in ["sentinel", "bulwark", "twin", "eclipse"] and ResourceLoader.exists("res://assets/enemies/sentinel_combat_atlas.png"):
		path = "res://assets/enemies/sentinel_combat_atlas.png"
	enemy = _actor(path, -1.0, Vector2(250, -45))
	if _kind in ["reverse", "twin"]: enemy.modulate = Color(0.9, 0.76, 1.0)
	if _kind == "corrosion": enemy.modulate = Color(0.78, 1.0, 0.8)

func attack(from_player: bool) -> void:
	(player if from_player else enemy).attack()

func impact(on_player: bool, blocked: bool) -> void:
	(player if on_player else enemy).hit(blocked)

func finish(won: bool) -> void:
	(enemy if won else player).fall()
