class_name DecisionPreview extends RefCounted
## Read-only forecast. Never reveals hidden sockets or mutates combat/RNG.
static func intent(socket: ClockSocketData) -> String:
	if not socket.intent_revealed: return "Unrevealed action"
	var parts: Array[String] = []
	if socket.intent_damage > 0: parts.append("Attack %d%s base" % [socket.intent_damage, " × %d" % socket.intent_hits if socket.intent_hits > 1 else ""])
	if socket.intent_block > 0: parts.append("Gain %d Block" % socket.intent_block)
	if socket.intent_strength > 0: parts.append("Gain %d Strength" % socket.intent_strength)
	if socket.intent_bleed > 0: parts.append("Apply %d Bleed" % socket.intent_bleed)
	if socket.intent_weak > 0: parts.append("Apply %d Weak" % socket.intent_weak)
	if socket.intent_vulnerable > 0: parts.append("Apply %d Vulnerable" % socket.intent_vulnerable)
	if socket.is_siphon: parts.append("On HP damage: drain 25% Overkill")
	return " · ".join(parts) if not parts.is_empty() else "Wait"

static func forecast(b: CombatController, hours: Array, replace_hour: int = 0, relic: ClockRelicData = null) -> String:
	var s: Dictionary = {}
	for key: String in ["player_hp","player_max_hp","player_block","player_strength","player_bleed","player_weak","player_vulnerable","player_thorns","player_next_hit_bonus","player_next_attack_multiplier","enemy_hp","enemy_max_hp","enemy_block","enemy_strength","enemy_bleed","enemy_weak","enemy_vulnerable","enemy_thorns"]:
		s[key] = b.get(key)
	var completed: int = 0
	var uncertain: bool = false
	for hour: int in hours:
		var enemy_hour: int = EnemyClockPattern.hour_for(hour, b._active_enemy())
		var e: ClockSocketData = b.enemy_sockets[enemy_hour - 1]
		if not e.intent_revealed:
			uncertain = true
			break
		var p: ClockSocketData = b.player_sockets[hour - 1]
		var r: ClockRelicData = relic if hour == replace_hour else p.slotted_relic
		_tick(s, p, e, r)
		completed += 1
		if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0: break
		if EnemyClockPattern.has_twin(b._active_enemy()) and hour % 3 == 0:
			var echo: ClockSocketData = b.enemy_sockets[((enemy_hour + 3) % 9)]
			if not echo.intent_revealed:
				uncertain = true
				break
			if echo.intent_damage > 0:
				_enemy_hit(s, _enemy_damage(s, echo.intent_damage))
				s.enemy_block += echo.intent_block
		for key: String in ["player_weak","player_vulnerable","enemy_weak","enemy_vulnerable"]: s[key] = maxi(0, int(s[key]) - 1)
	var result: String = "You: %d HP · %d Block   |   Enemy: %d HP · %d Block" % [maxi(0,s.player_hp),s.player_block,maxi(0,s.enemy_hp),s.enemy_block]
	if completed == 0: return "Outcome unknown until the next enemy action is revealed."
	if uncertain: return "Known hours only — " + result + "\nRemaining actions are unrevealed."
	if int(s.player_hp) <= 0: result += " · LETHAL TO YOU"
	elif int(s.enemy_hp) <= 0: result += " · ENEMY DEFEATED (forecast ends here)"
	return "After resolution — " + result

static func _tick(s: Dictionary, p: ClockSocketData, e: ClockSocketData, r: ClockRelicData) -> void:
	s.player_hp -= s.player_bleed
	s.enemy_hp -= s.enemy_bleed
	if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0: return
	if r != null:
		s.player_block += r.base_block
		s.player_strength += r.apply_strength
		s.player_thorns += r.apply_thorns
		s.enemy_vulnerable += r.apply_vulnerable
		s.enemy_weak += r.apply_weak
		s.enemy_bleed += r.apply_bleed
		s.player_next_hit_bonus += r.bonus_damage_next_hit
	s.enemy_block += e.intent_block
	s.enemy_strength += e.intent_strength
	s.player_bleed += e.intent_bleed
	s.player_weak += e.intent_weak
	s.player_vulnerable += e.intent_vulnerable
	if r != null and r.base_damage > 0:
		var damage: int = r.base_damage + int(s.player_strength) + int(s.player_next_hit_bonus)
		s.player_next_hit_bonus = 0
		if r.conditional_hp_threshold_pct > 0.0 and float(s.enemy_hp) / float(s.enemy_max_hp) <= r.conditional_hp_threshold_pct: damage = r.conditional_damage + int(s.player_strength)
		if int(s.enemy_vulnerable) > 0: damage = floori(damage * 1.5)
		if int(s.player_weak) > 0: damage = floori(damage * 0.75)
		damage = floori(damage * p.multiplier) * int(s.player_next_attack_multiplier)
		s.player_next_attack_multiplier = maxi(1, r.next_attack_multiplier)
		for hit: int in r.hits:
			if p.is_hazard: s.player_hp -= floori(damage * 0.5)
			var hp_damage: int = mini(maxi(s.enemy_hp,0), maxi(damage - int(s.enemy_block), 0))
			var overkill: int = maxi(0, damage - int(s.enemy_block) - int(s.enemy_hp))
			s.enemy_hp -= hp_damage
			s.enemy_block = maxi(0,int(s.enemy_block)-damage)
			if r.recoil_block_on_overkill: s.player_block += overkill
			if r.lifesteal and int(s.player_hp) > 0: s.player_hp += mini(hp_damage,maxi(0,int(s.player_max_hp)-int(s.player_hp)))
			s.player_hp -= s.enemy_thorns
			if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0: return
	if e.intent_damage > 0:
		var damage: int = _enemy_damage(s,e.intent_damage)
		for hit: int in e.intent_hits:
			_enemy_hit(s,damage)
			if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0: return

static func _enemy_damage(s: Dictionary, base: int) -> int:
	var damage: int = base + int(s.enemy_strength)
	if int(s.player_vulnerable) > 0: damage = floori(damage * 1.5)
	if int(s.enemy_weak) > 0: damage = floori(damage * 0.75)
	return damage

static func _enemy_hit(s: Dictionary, damage: int) -> void:
	s.player_hp -= maxi(0, damage - int(s.player_block))
	s.player_block = maxi(0,int(s.player_block)-damage)
	s.enemy_hp -= s.player_thorns
