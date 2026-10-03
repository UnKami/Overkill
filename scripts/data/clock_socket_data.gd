class_name ClockSocketData extends Resource
## ClockSocketData - Model representing one of the 9 hours in a Chronometer.

@export var hour_index: int = 1 # 1 to 12
@export var slotted_relic: ClockRelicData = null
@export var is_locked: bool = false
@export var is_hazard: bool = false
@export var is_siphon: bool = false
@export var multiplier: float = 1.0

# Enemy intent properties (used for Enemy Chronometer sockets)
@export var intent_damage: int = 0
@export var intent_hits: int = 1
@export var intent_block: int = 0
@export var intent_strength: int = 0
@export var intent_vulnerable: int = 0
@export var intent_weak: int = 0
@export var intent_bleed: int = 0
@export var intent_label: String = ""
@export var intent_revealed: bool = false


func has_relic() -> bool:
	return slotted_relic != null


func has_enemy_action() -> bool:
	return intent_damage > 0 or intent_block > 0 or intent_strength > 0 or intent_vulnerable > 0 or intent_weak > 0 or intent_bleed > 0


func clone() -> ClockSocketData:
	var copy := ClockSocketData.new()
	copy.hour_index = hour_index
	copy.slotted_relic = slotted_relic
	copy.is_locked = is_locked
	copy.is_hazard = is_hazard
	copy.is_siphon = is_siphon
	copy.multiplier = multiplier
	copy.intent_damage = intent_damage
	copy.intent_hits = intent_hits
	copy.intent_block = intent_block
	copy.intent_strength = intent_strength
	copy.intent_vulnerable = intent_vulnerable
	copy.intent_weak = intent_weak
	copy.intent_bleed = intent_bleed
	copy.intent_label = intent_label
	copy.intent_revealed = intent_revealed
	return copy
