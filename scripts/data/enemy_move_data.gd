class_name EnemyMoveData extends Resource

enum IntentType { ATTACK, DEFEND, BUFF, DEBUFF, ATTACK_DEFEND, UNKNOWN }

@export var move_id: String = ""
@export var intent_type: IntentType = IntentType.ATTACK
@export var intent_value: int = 0               ## the number shown on the intent icon - MUST be player-visible
                                                 ## before the move resolves, no exceptions (fairness contract)
@export var effects: Array[EffectData] = []
@export var hit_count: int = 1                  ## multi-hit attacks must show as N separate hits, never pre-summed
