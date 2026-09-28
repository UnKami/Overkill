class_name ClockRelicData extends Resource
## ClockRelicData - The fundamental active instruction in the Dual-Chronometer Engine.
## Replaces cards: relics are physical components slotted into the 9-hour circular array.

enum Tier { STARTER, COMMON, RARE, ZENITH }
enum Role { IMPACT, BULWARK, TEMPO, BREAKER, HARVEST }
enum Essence { ATTACK, BLOCK, BUFF, DEBUFF, OVERKILL }

@export var id: String = ""
@export var name: String = ""
@export var tier: Tier = Tier.STARTER
@export var role: Role = Role.IMPACT
@export var primary_essence: Essence = Essence.ATTACK
@export_range(-1, 4, 1) var secondary_essence: int = -1
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
@export var grant_overkill: int = 0

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
		Role.HARVEST: return "Harvest"
		_: return "Impact"


static func role_to_color(r: Role) -> Color:
	match r:
		Role.IMPACT: return essence_to_color(Essence.ATTACK)
		Role.BULWARK: return essence_to_color(Essence.BLOCK)
		Role.TEMPO: return essence_to_color(Essence.BUFF)
		Role.BREAKER: return essence_to_color(Essence.DEBUFF)
		Role.HARVEST: return essence_to_color(Essence.OVERKILL)
		_: return Color.WHITE


static func essence_to_name(essence: int) -> String:
	match essence:
		Essence.ATTACK: return "Orange Attack"
		Essence.BLOCK: return "Blue Block"
		Essence.BUFF: return "Purple Buff"
		Essence.DEBUFF: return "Green Debuff"
		Essence.OVERKILL: return "Blood Overkill"
		_: return "Unbound"


static func essence_to_color(essence: int) -> Color:
	match essence:
		Essence.ATTACK: return Color("#FF8A1F")
		Essence.BLOCK: return Color("#4FB8FF")
		Essence.BUFF: return Color("#B76CFF")
		Essence.DEBUFF: return Color("#58D66B")
		Essence.OVERKILL: return Color("#C41734")
		_: return Color.WHITE


static func essence_to_short_name(essence: int) -> String:
	match essence:
		Essence.ATTACK: return "Attack"
		Essence.BLOCK: return "Block"
		Essence.BUFF: return "Buff"
		Essence.DEBUFF: return "Debuff"
		Essence.OVERKILL: return "Overkill"
		_: return "Unbound"


func primary_color() -> Color:
	return essence_to_color(primary_essence)


func secondary_color() -> Color:
	return essence_to_color(secondary_essence) if secondary_essence >= 0 else primary_color()


func affinity_name() -> String:
	var label := essence_to_name(primary_essence)
	if secondary_essence >= 0:
		label += " + " + essence_to_name(secondary_essence)
	return label


func compact_affinity_name() -> String:
	var label := essence_to_short_name(primary_essence)
	if secondary_essence >= 0:
		label += " + " + essence_to_short_name(secondary_essence)
	return label
