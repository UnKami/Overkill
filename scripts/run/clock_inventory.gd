class_name ClockInventory extends RefCounted
## Each entry is a physical copy. Resource copies are isolated for combat/upgrades.
const STARTER_COUNTS: Dictionary = {"REL-01": 6, "REL-04": 6, "REL-02": 2, "REL-06": 2}
const MINIMUM_SIZE := 15

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
	if int(entry.get("level", 0)) > 0:
		copy.name += " +"
		if copy.base_damage > 0: copy.base_damage += 3
		if copy.base_block > 0: copy.base_block += 3
		if copy.conditional_damage > 0: copy.conditional_damage += 3
		if copy.apply_strength > 0: copy.apply_strength += 1
		if copy.apply_thorns > 0: copy.apply_thorns += 1
		if copy.apply_bleed > 0: copy.apply_bleed += 1
		if copy.apply_weak > 0: copy.apply_weak += 1
		if copy.apply_vulnerable > 0: copy.apply_vulnerable += 1
		if copy.bonus_damage_next_hit > 0: copy.bonus_damage_next_hit += 2
		copy.description = describe(copy)
	return copy

static func describe(relic: ClockRelicData) -> String:
	var parts: PackedStringArray = []
	if relic.base_damage > 0:
		parts.append("Deal %d damage%s." % [relic.base_damage, " × %d" % relic.hits if relic.hits > 1 else ""])
	if relic.base_block > 0: parts.append("Gain %d Block. Lasts until absorbed or battle ends." % relic.base_block)
	for pair in [[relic.apply_strength, "strength"], [relic.apply_thorns, "thorns"], [relic.apply_bleed, "bleed"], [relic.apply_weak, "weak"], [relic.apply_vulnerable, "vulnerable"]]:
		if pair[0] > 0: parts.append("Apply %d %s." % pair)
	if relic.bonus_damage_next_hit > 0: parts.append("Next attack +%d damage." % relic.bonus_damage_next_hit)
	if relic.conditional_damage > 0: parts.append("%d damage below %d%% enemy HP." % [relic.conditional_damage, int(relic.conditional_hp_threshold_pct * 100)])
	if relic.recoil_block_on_overkill: parts.append("Overkill becomes guard.")
	return " ".join(parts)
