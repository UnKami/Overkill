class_name EnemyData extends Resource

enum Tier { TRASH, ELITE, BOSS }
enum MovePattern { SEQUENTIAL, WEIGHTED_RANDOM, SCRIPTED }

@export var id: String = ""
@export var display_name: String = ""
@export var tier: Tier = Tier.TRASH
@export var max_hp: int = 10
@export var hp_variance: Vector2i = Vector2i.ZERO  ## min/max roll range for slight per-run variation

@export var move_pool: Array[EnemyMoveData] = []
@export var move_pattern: MovePattern = MovePattern.SEQUENTIAL

@export var tempered: bool = false              ## if true, caps OK generation - a design lever, not a default
@export var overkill_death_threshold: int = 999 ## OK amount above which the "shattered" death anim plays

@export var art_id: String = ""
