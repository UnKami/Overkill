class_name ClockInventory extends RefCounted
## Each entry is a physical copy. Resource copies are isolated for combat/upgrades.
const STARTER_COUNTS: Dictionary = {
	"REL-01": 3,
	"REL-04": 3,
	"REL-02": 1,
	"REL-08": 1,
	"REL-13": 1,
	"REL-14": 1,
}
const MINIMUM_SIZE := 6
const MAX_SIZE := 12

static func starter() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in STARTER_COUNTS:
		for copy_index: int in int(STARTER_COUNTS[id]):
			result.append({"uid": result.size(), "id": id, "level": 0})
	return result

static func resolve(entry: Dictionary) -> ClockRelicData:
	var source := ContentDatabase.get_clock_relic(str(entry.get("id", "")))
	if source == null:
		return null
	var copy: ClockRelicData = source.duplicate(true)
	var level: int = int(entry.get("level", 0))
	if level > 0:
		copy.name += " +"
		if copy.base_damage > 0: copy.base_damage += 3 * level
		if copy.base_block > 0: copy.base_block += 3 * level
		if copy.conditional_damage > 0: copy.conditional_damage += 4 * level
		if copy.apply_strength > 0: copy.apply_strength += 1 * level
		if copy.apply_thorns > 0: copy.apply_thorns += 2 * level
		if copy.apply_bleed > 0: copy.apply_bleed += 1 * level
		if copy.apply_weak > 0: copy.apply_weak += 1 * level
		if copy.apply_vulnerable > 0: copy.apply_vulnerable += 1 * level
		if copy.grant_overkill > 0: copy.grant_overkill += 2 * level
		if copy.bonus_damage_next_hit > 0: copy.bonus_damage_next_hit += 2 * level
		if copy.sector_finisher_bonus_damage > 0: copy.sector_finisher_bonus_damage += 4 * level
		if copy.charge_next_socket_multiplier > 0.0: copy.charge_next_socket_multiplier += 0.5 * float(level)
		if copy.resonance_essence_bonus > 0: copy.resonance_essence_bonus += 2 * level
		if copy.trigger_bleed_times > 0: copy.trigger_bleed_times += 1 * level
		if copy.multiply_current_block > 1.0: copy.multiply_current_block += 0.5 * float(level)
		if copy.multiply_enemy_bleed > 1.0: copy.multiply_enemy_bleed += 0.5 * float(level)
		if copy.damage_per_enemy_bleed > 0: copy.damage_per_enemy_bleed += 1 * level
		if copy.damage_per_banked_overkill_div > 1: copy.damage_per_banked_overkill_div = maxi(2, copy.damage_per_banked_overkill_div - level)
	copy.description = copy.live_description()
	return copy

static func describe(relic: ClockRelicData) -> String:
	if relic == null:
		return ""
	return relic.live_description()

static func instance_identity(entry: Dictionary) -> String:
	var level_text: String = "UPGRADED" if int(entry.get("level", 0)) > 0 else "BASE FORM"
	return "%s  ·  COPY #%04d  ·  %s" % [str(entry.get("id", "UNKNOWN")), int(entry.get("uid", -1)) + 1, level_text]
