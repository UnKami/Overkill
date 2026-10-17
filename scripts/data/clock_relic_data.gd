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

@export_group("Clock & Positional Mechanics")
@export var charge_next_socket_multiplier: float = 0.0 # Permanently adds +X to the next hour socket's multiplier
@export var echo_previous_hour: bool = false # Re-triggers the relic effects of the preceding hour
@export var sector_finisher_bonus_damage: int = 0 # Bonus damage when slotted in Hour 3, 6, or 9
@export var sector_finisher_hits_bonus: int = 0 # Extra hits when slotted in Hour 3, 6, or 9
@export var resonance_essence_bonus: int = 0 # Bonus damage/block if previous hour shares an Essence

@export_group("Archetype Payoffs")
@export var damage_per_current_block_pct: float = 0.0 # Adds floor(player_block * pct) to attack damage
@export var multiply_current_block: float = 1.0 # Multiplies player_block (e.g. 1.5x or 2.0x)
@export var thorns_to_damage_multiplier: float = 0.0 # Adds floor(player_thorns * mult) to attack damage
@export var trigger_bleed_times: int = 0 # Immediately triggers enemy_bleed damage N times
@export var multiply_enemy_bleed: float = 1.0 # Multiplies enemy_bleed stacks (e.g. 1.5x or 2.0x)
@export var damage_per_enemy_bleed: int = 0 # Adds +X damage per enemy_bleed stack
@export var damage_per_banked_overkill_div: int = 0 # Adds +1 damage per N banked Overkill points
@export var overkill_extraction_pct: float = 0.0 # Generates floor(unblocked_damage * pct) Overkill on hit


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


func shares_essence_with(other: ClockRelicData) -> bool:
	if other == null:
		return false
	if int(primary_essence) == int(other.primary_essence) or int(primary_essence) == other.secondary_essence:
		return true
	if secondary_essence >= 0 and (secondary_essence == int(other.primary_essence) or secondary_essence == other.secondary_essence):
		return true
	return false


func live_description() -> String:
	var clauses: Array[String] = []
	if base_damage > 0:
		if hits > 1:
			clauses.append("Deal %d damage %d times" % [base_damage, hits])
		else:
			clauses.append("Deal %d damage" % base_damage)
	if conditional_damage > 0 and conditional_hp_threshold_pct > 0.0:
		clauses.append("(%d damage if target HP <= %d%%)" % [conditional_damage, int(round(conditional_hp_threshold_pct * 100.0))])
	if damage_per_current_block_pct > 0.0:
		clauses.append("+%d%% of your current Block as bonus damage" % int(round(damage_per_current_block_pct * 100.0)))
	if thorns_to_damage_multiplier > 0.0:
		clauses.append("+%d× your Thorns as bonus damage" % int(round(thorns_to_damage_multiplier)))
	if damage_per_enemy_bleed > 0:
		clauses.append("+%d damage per enemy Bleed stack" % damage_per_enemy_bleed)
	if damage_per_banked_overkill_div > 0:
		clauses.append("+1 damage per %d banked Overkill" % damage_per_banked_overkill_div)
	if sector_finisher_bonus_damage > 0:
		clauses.append("Sector Finisher (Hour 3/6/9): +%d damage" % sector_finisher_bonus_damage)
	if sector_finisher_hits_bonus > 0:
		clauses.append("Sector Finisher (Hour 3/6/9): +%d extra hit(s)" % sector_finisher_hits_bonus)
	if base_block > 0:
		clauses.append("Gain %d Block" % base_block)
	if multiply_current_block > 1.0:
		clauses.append("Multiply your Block by %.1f×" % multiply_current_block)
	if apply_strength > 0:
		clauses.append("Gain +%d Strength" % apply_strength)
	if apply_thorns > 0:
		clauses.append("Gain +%d Thorns" % apply_thorns)
	if apply_vulnerable > 0:
		clauses.append("Apply %d Vulnerable" % apply_vulnerable)
	if apply_weak > 0:
		clauses.append("Apply %d Weak" % apply_weak)
	if apply_bleed > 0:
		clauses.append("Apply %d Bleed" % apply_bleed)
	if multiply_enemy_bleed > 1.0:
		clauses.append("Multiply enemy Bleed by %.1f×" % multiply_enemy_bleed)
	if trigger_bleed_times > 0:
		clauses.append("Trigger enemy Bleed %d time(s) immediately" % trigger_bleed_times)
	if bonus_damage_next_hit > 0:
		clauses.append("Next attack deals +%d damage per hit" % bonus_damage_next_hit)
	if next_attack_multiplier > 1:
		clauses.append("Next attack deals %d× damage" % next_attack_multiplier)
	if charge_next_socket_multiplier > 0.0:
		clauses.append("Charge next Hour socket by +%.1f× multiplier" % charge_next_socket_multiplier)
	if resonance_essence_bonus > 0:
		clauses.append("Resonance (matching previous Hour Essence): +%d power" % resonance_essence_bonus)
	if echo_previous_hour:
		clauses.append("Echo: Re-triggers the preceding Hour's relic")
	if lifesteal:
		clauses.append("Lifesteal (heal unblocked HP damage dealt)")
	if recoil_block_on_overkill:
		clauses.append("Gain Block equal to Overkill dealt")
	if overkill_extraction_pct > 0.0:
		clauses.append("Harvest %d%% of unblocked damage as Overkill" % int(round(overkill_extraction_pct * 100.0)))
	if grant_overkill > 0:
		clauses.append("Gain %d Overkill" % grant_overkill)
	if clauses.is_empty():
		return description
	return ". ".join(clauses) + "."

