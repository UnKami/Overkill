class_name EnemyInstance extends Node
## Runtime state for one enemy in combat, wrapping its static EnemyData.
## Intent is rolled and exposed BEFORE the player can act, per the fairness
## contract (data schema doc 1.2, 2.2) - see roll_next_move().

signal hp_changed(current: int, max: int)
signal move_revealed(move: EnemyMoveData)

var data: EnemyData
var max_hp: int
var current_hp: int
var block: int = 0
var current_move: EnemyMoveData
var _move_index: int = 0

## Damage-modifier state (data schema doc 1.6) - same fields/rules as
## PlayerState. Strength never decays; Weak/Vulnerable tick down at the end
## of this enemy's own turn.
var strength: int = 0
var weak_stacks: int = 0
var vulnerable_stacks: int = 0


func _init(enemy_data: EnemyData = null) -> void:
	if enemy_data:
		setup(enemy_data)


func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	if data.hp_variance != Vector2i.ZERO:
		max_hp = randi_range(data.hp_variance.x, data.hp_variance.y)
	else:
		max_hp = data.max_hp
	current_hp = max_hp
	roll_next_move()


## Rolled and revealed immediately - never leave a combat frame where the
## enemy has a next move but no visible intent.
func roll_next_move() -> void:
	if data.move_pool.is_empty():
		return
	match data.move_pattern:
		EnemyData.MovePattern.WEIGHTED_RANDOM:
			current_move = data.move_pool[randi() % data.move_pool.size()]
		_:  # SEQUENTIAL / SCRIPTED - this slice only ever has one move
			current_move = data.move_pool[_move_index % data.move_pool.size()]
			_move_index += 1
	move_revealed.emit(current_move)


func is_dead() -> bool:
	return current_hp <= 0


## Applies raw damage, returns {needed: int, overkill: int} - the split is
## computed here so combat_controller never has to re-derive it, keeping the
## "one place computes OK" rule (data schema doc, Part 1.5 closing note).
func apply_damage(raw_damage: int) -> Dictionary:
	var absorbed: int = min(block, raw_damage)
	block -= absorbed
	var post_block: int = raw_damage - absorbed

	var needed: int = min(post_block, current_hp)
	var overkill: int = max(0, post_block - current_hp)
	current_hp = max(0, current_hp - needed)
	hp_changed.emit(current_hp, max_hp)
	return {"needed": needed, "overkill": overkill}


func gain_block(amount: int) -> void:
	block += amount


## Called once at the end of this enemy's own turn (data schema doc 1.6) -
## Strength doesn't decay, only the two duration-stacking debuffs do.
func tick_status_down() -> void:
	weak_stacks = max(0, weak_stacks - 1)
	vulnerable_stacks = max(0, vulnerable_stacks - 1)
