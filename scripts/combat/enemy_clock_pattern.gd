class_name EnemyClockPattern extends RefCounted
## Authored deterministic telegraphs, with encounter-specific order and mechanics.

static func profile(enemy: EnemyData) -> String:
	if enemy == null: return "stalker"
	return {"boneghoul": "stalker", "act1_elite": "chainbinder", "act1_boss": "sentinel", "act2_trash": "corrosion", "act2_elite": "bulwark", "act2_boss": "reverse", "act3_trash": "shards", "act3_elite": "siphon", "act3_boss": "twin", "final_boss": "eclipse"}.get(enemy.id, "stalker")

static func description(enemy: EnemyData) -> String:
	return {"stalker": "STALKER  /  Claw · brace · rend", "chainbinder": "CHAINBINDER  /  Weakening chains before the heavy lash", "sentinel": "SENTINEL  /  Armors up before crushing blows", "corrosion": "CORROSION  /  Bleed persists between ticks", "bulwark": "BULWARK  /  Guard and strength fuel the counterstrike", "reverse": "REVERSE CLOCK  /  Enemy hand runs counterclockwise", "shards": "SHARD SWARM  /  Multiple small strikes", "siphon": "SIPHON  /  Unblocked strikes drain banked Overkill", "twin": "TWIN HANDS  /  Opposite hour also attacks at each wedge end", "eclipse": "ECLIPSE  /  Reverse clock with an opposing second hand"}.get(profile(enemy), "")

static func hour_for(player_hour: int, enemy: EnemyData) -> int:
	return 13 - player_hour if profile(enemy) in ["reverse", "eclipse"] else player_hour

static func has_twin(enemy: EnemyData) -> bool:
	return profile(enemy) in ["twin", "eclipse"]

static func create(enemy: EnemyData) -> Array[ClockSocketData]:
	var result: Array[ClockSocketData] = []
	var kind := profile(enemy)
	for hour in range(1, 13):
		var s := ClockSocketData.new()
		s.hour_index = hour
		var beat := (hour - 1) % 3
		var late := (hour - 1) / 6
		match kind:
			"stalker":
				if beat == 0: s.intent_damage = 4
				elif beat == 1: s.intent_block = 3
				else: s.intent_damage = 7
			"chainbinder":
				if beat == 0: s.intent_weak = 2
				elif beat == 1: s.intent_damage = 6
				else: s.intent_damage = 9; s.intent_vulnerable = 2
			"sentinel":
				if beat == 0: s.intent_block = 7
				elif beat == 1: s.intent_strength = 1
				else: s.intent_damage = 10 + late
			"bulwark":
				if beat == 0: s.intent_block = 10
				elif beat == 1: s.intent_damage = 4; s.intent_strength = 1
				else: s.intent_damage = 8; s.intent_block = 3
			"corrosion":
				if beat == 0: s.intent_bleed = 1
				elif beat == 1: s.intent_block = 4
				else: s.intent_damage = 7
			"reverse":
				if beat == 0: s.intent_damage = 11
				elif beat == 1: s.intent_vulnerable = 2; s.intent_block = 4
				else: s.intent_damage = 5
			"shards":
				if beat == 1: s.intent_block = 5
				else: s.intent_damage = 3; s.intent_hits = 2 if beat == 0 else 3
			"siphon":
				if beat == 1: s.intent_block = 6
				else: s.intent_damage = 8; s.is_siphon = true
			"twin", "eclipse":
				if beat == 1: s.intent_block = 6
				else: s.intent_damage = 6 if kind == "twin" else 8
		var parts: PackedStringArray = []
		if s.intent_damage > 0: parts.append("%d damage%s" % [s.intent_damage, " × %d" % s.intent_hits if s.intent_hits > 1 else ""])
		if s.intent_block > 0: parts.append("%d guard" % s.intent_block)
		if s.intent_strength > 0: parts.append("+%d strength" % s.intent_strength)
		if s.intent_weak > 0: parts.append("%d weak" % s.intent_weak)
		if s.intent_vulnerable > 0: parts.append("%d vulnerable" % s.intent_vulnerable)
		if s.intent_bleed > 0: parts.append("%d bleed" % s.intent_bleed)
		if s.is_siphon: parts.append("drain 25% Overkill on HP damage")
		s.intent_label = " · ".join(parts)
		result.append(s)
	return result
