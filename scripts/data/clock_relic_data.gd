class_name ClockRelicData extends Resource
## ClockRelicData - The fundamental active instruction in the Dual-Chronometer Engine.
## Replaces cards: relics are physical components slotted into the 9-hour circular array.

enum Tier { STARTER, COMMON, RARE, ZENITH }
enum Role { IMPACT, BULWARK, TEMPO, BREAKER }

@export var id: String = ""
@export var name: String = ""
@export var tier: Tier = Tier.STARTER
@export var role: Role = Role.IMPACT
@export_multiline var description: String = ""
@export var art_id: String = ""

@export_group("Combat Stats")
@export var base_damage: int = 0
@export var hits: int = 1
@export var base_block: int = 0
@export var apply_strength: int = 0
@export var apply_vulnerable: int = 0
@export var apply_weak: int = 0
@export var apply_bleed: int = 0
@export var apply_thorns: int = 0

@export_group("Special Synergies")
@export var conditional_damage: int = 0
@export var conditional_hp_threshold_pct: float = 0.0 # e.g. 0.5 for Execution Wedge
@export var recoil_block_on_overkill: bool = false # e.g. Recoil Piston
@export var lifesteal: bool = false
@export var next_attack_multiplier: int = 1
@export var bonus_damage_next_hit: int = 0 # e.g. Kinetic Battery


static func role_to_name(r: Role) -> String:
	match r:
		Role.IMPACT: return "Impact"
		Role.BULWARK: return "Bulwark"
		Role.TEMPO: return "Tempo"
		Role.BREAKER: return "Breaker"
		_: return "Impact"


static func role_to_color(r: Role) -> Color:
	match r:
		Role.IMPACT: return Color("#E24B4A") # Striking Crimson
		Role.BULWARK: return Color("#5DADE2") # Shielding Cyan
		Role.TEMPO: return Color("#BB8FCE") # Mystic Purple
		Role.BREAKER: return Color("#F39C12") # Volatile Amber
		_: return Color.WHITE
