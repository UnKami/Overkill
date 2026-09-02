class_name CardData extends Resource

enum CardType { ATTACK, SKILL, POWER }
enum Rarity { COMMON, UNCOMMON, RARE, EXCESS }
enum TargetType { SELF, SINGLE_ENEMY, ALL_ENEMIES, NONE }
enum ExcessGateType { NONE, SINGLE_HIT_OK, TURN_TOTAL_OK, CARD_SOURCED_OK }

@export var id: String = ""                     ## unique, matches art asset filename
@export var display_name: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var energy_cost: int = 1                ## -1 reserved for "X cost" cards
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

@export var base_effects: Array[EffectData] = []      ## what the unupgraded card does
@export var upgraded_effects: Array[EffectData] = []  ## empty = "no change other than stated"
@export var upgrade_level: int = 0              ## 0 = base, 1 = upgraded

@export var excess_gate_threshold: int = 0      ## 0 for non-Excess cards; single-hit OK required to unlock
@export var excess_gate_type: ExcessGateType = ExcessGateType.NONE

@export_multiline var flavor_text: String = ""  ## never load-bearing for understanding the card
@export_multiline var rules_text_override: String = ""  ## escape hatch only - see KeywordRegistry first

@export var art_id: String = ""                 ## matches art requirements doc naming convention
