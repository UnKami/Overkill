class_name DecisionPreview extends RefCounted
## Read-only forecast and live positional math inspector. Never reveals hidden sockets or mutates combat/RNG.

class ForecastResult extends RefCounted:
	var text: String = ""
	var summary: String = ""
	var player_hp_after: int = 0
	var player_block_after: int = 0
	var enemy_hp_after: int = 0
	var enemy_block_after: int = 0
	var overkill_after: int = 0
	var overkill_gained: int = 0
	var completed: int = 0
	var uncertain: bool = false
	var step_outcomes: Array[Dictionary] = []


static var last_forecast_result: ForecastResult = null


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
	if socket.is_hazard: parts.append("Hazard: 50% attack recoil")
	return " · ".join(parts) if not parts.is_empty() else "Wait"


static func evaluate_relic_on_hour(controller, relic: ClockRelicData, hour: int) -> Dictionary:
	var empty_breakdown: Array[String] = []
	var empty_tags: Array[String] = []
	if relic == null:
		return {
			"damage_per_hit": 0,
			"hits": 1,
			"total_damage": 0,
			"base_damage": 0,
			"block_gain": 0,
			"base_block": 0,
			"is_damage_buffed": false,
			"is_damage_weakened": false,
			"is_block_buffed": false,
			"math_breakdown": empty_breakdown,
			"active_tags": empty_tags,
		}

	var h: int = clampi(hour if hour > 0 else 1, 1, 9)
	var prev_h: int = ((h - 2 + 9) % 9) + 1
	var socket_mult: float = 1.0
	var prev_relic: ClockRelicData = null

	var p_block: int = 0
	var p_str: int = 0
	var p_thorns: int = 0
	var p_weak: int = 0
	var p_next_bonus: int = 0
	var p_next_mult: int = 1
	var e_hp: int = 100
	var e_max_hp: int = 100
	var e_vuln: int = 0
	var e_bleed: int = 0
	var banked_ok: int = OKRunState.current_ok

	if controller != null:
		p_block = int(controller.get("player_block"))
		p_str = int(controller.get("player_strength"))
		p_thorns = int(controller.get("player_thorns"))
		p_weak = int(controller.get("player_weak"))
		p_next_bonus = int(controller.get("player_next_hit_bonus"))
		p_next_mult = maxi(1, int(controller.get("player_next_attack_multiplier")))
		e_hp = int(controller.get("enemy_hp"))
		e_max_hp = maxi(1, int(controller.get("enemy_max_hp")))
		e_vuln = int(controller.get("enemy_vulnerable"))
		e_bleed = int(controller.get("enemy_bleed"))
		if controller is Dictionary and controller.has("overkill"):
			banked_ok = int(controller.get("overkill"))
		var sockets = controller.get("player_sockets")
		if sockets is Array and sockets.size() >= 9:
			var cur_sock: ClockSocketData = sockets[h - 1] as ClockSocketData
			if cur_sock != null:
				socket_mult = cur_sock.multiplier
			var prev_sock: ClockSocketData = sockets[prev_h - 1] as ClockSocketData
			if prev_sock != null:
				prev_relic = prev_sock.slotted_relic

	var active_tags: Array[String] = []
	var breakdown: Array[String] = []

	var has_echo: bool = relic.echo_previous_hour and prev_relic != null and not prev_relic.echo_previous_hour
	if has_echo:
		active_tags.append("ECHOES HOUR %d" % prev_h)

	var has_resonance: bool = relic.resonance_essence_bonus > 0 and prev_relic != null and relic.shares_essence_with(prev_relic)
	if has_resonance:
		active_tags.append("RESONANCE ACTIVE")

	var is_finisher_hour: bool = h in [3, 6, 9]
	if is_finisher_hour and (relic.sector_finisher_bonus_damage > 0 or relic.sector_finisher_hits_bonus > 0):
		active_tags.append("FINISHER ACTIVE")

	# If Echo is active and this relic has no direct attack/block of its own, include echoed buffs
	if has_echo:
		p_str += prev_relic.apply_strength
		p_thorns += prev_relic.apply_thorns
		e_vuln += prev_relic.apply_vulnerable
		e_bleed += floori(float(prev_relic.apply_bleed) * socket_mult)
		p_next_bonus += prev_relic.bonus_damage_next_hit
		banked_ok += prev_relic.grant_overkill

	# Step 2 self-buffs before Step 3 attack
	var base_blk: int = relic.base_block
	var raw_blk: int = base_blk + (relic.resonance_essence_bonus if base_blk > 0 and has_resonance else 0)
	var scaled_blk: int = floori(float(raw_blk) * socket_mult)
	var after_blk: int = p_block + scaled_blk
	if relic.multiply_current_block > 1.0 and after_blk > 0:
		after_blk = floori(float(after_blk) * relic.multiply_current_block)
	var block_gain: int = maxi(0, after_blk - p_block)
	p_block = after_blk

	p_str += relic.apply_strength
	p_thorns += relic.apply_thorns
	e_vuln += relic.apply_vulnerable
	e_bleed += floori(float(relic.apply_bleed) * socket_mult)
	if relic.multiply_enemy_bleed > 1.0 and e_bleed > 0:
		e_bleed = floori(float(e_bleed) * relic.multiply_enemy_bleed)
	p_next_bonus += relic.bonus_damage_next_hit
	banked_ok += relic.grant_overkill

	var eval_attack_relic: ClockRelicData = relic
	if relic.base_damage <= 0 and has_echo and prev_relic.base_damage > 0:
		eval_attack_relic = prev_relic

	var dmg_per_hit: int = 0
	var hit_count: int = maxi(1, eval_attack_relic.hits)
	var total_dmg: int = 0
	var base_dmg: int = eval_attack_relic.base_damage

	if eval_attack_relic.base_damage > 0:
		var raw_base: int = eval_attack_relic.base_damage
		if eval_attack_relic.conditional_hp_threshold_pct > 0.0 and float(e_hp) / float(e_max_hp) <= eval_attack_relic.conditional_hp_threshold_pct:
			raw_base = eval_attack_relic.conditional_damage
			breakdown.append("Execution Base: %d" % raw_base)
		else:
			breakdown.append("Base: %d" % raw_base)

		var running: int = raw_base
		var atk_resonance: bool = eval_attack_relic.resonance_essence_bonus > 0 and prev_relic != null and eval_attack_relic.shares_essence_with(prev_relic)
		if atk_resonance:
			running += eval_attack_relic.resonance_essence_bonus
			breakdown.append("Resonance: +%d" % eval_attack_relic.resonance_essence_bonus)
		if is_finisher_hour and eval_attack_relic.sector_finisher_bonus_damage > 0:
			running += eval_attack_relic.sector_finisher_bonus_damage
			breakdown.append("Sector Finisher: +%d" % eval_attack_relic.sector_finisher_bonus_damage)
		if p_str != 0:
			running += p_str
			breakdown.append("Strength: %+d" % p_str)
		if p_next_bonus != 0:
			running += p_next_bonus
			breakdown.append("Queued Bonus: +%d" % p_next_bonus)
		if eval_attack_relic.damage_per_current_block_pct > 0.0:
			var blk_dmg: int = floori(float(p_block) * eval_attack_relic.damage_per_current_block_pct)
			running += blk_dmg
			breakdown.append("Block Scaling (%d%%): +%d" % [int(round(eval_attack_relic.damage_per_current_block_pct * 100.0)), blk_dmg])
		if eval_attack_relic.thorns_to_damage_multiplier > 0.0:
			var th_dmg: int = floori(float(p_thorns) * eval_attack_relic.thorns_to_damage_multiplier)
			running += th_dmg
			breakdown.append("Thorns Scaling (×%.1f): +%d" % [eval_attack_relic.thorns_to_damage_multiplier, th_dmg])
		if eval_attack_relic.damage_per_enemy_bleed > 0:
			var bld_dmg: int = e_bleed * eval_attack_relic.damage_per_enemy_bleed
			running += bld_dmg
			breakdown.append("Bleed Scaling: +%d" % bld_dmg)
		if eval_attack_relic.damage_per_banked_overkill_div > 0:
			var ok_dmg: int = int(banked_ok / eval_attack_relic.damage_per_banked_overkill_div)
			running += ok_dmg
			breakdown.append("Overkill Scaling: +%d" % ok_dmg)

		if e_vuln > 0:
			running = floori(float(running) * 1.5)
			breakdown.append("Vulnerable ×1.5")
		if p_weak > 0:
			running = floori(float(running) * 0.75)
			breakdown.append("Weak ×0.75")
		if not is_equal_approx(socket_mult, 1.0):
			running = floori(float(running) * socket_mult)
			breakdown.append("Socket ×%.2f" % socket_mult)
		else:
			running = floori(float(running) * socket_mult)
		if p_next_mult > 1:
			running *= p_next_mult
			breakdown.append("Overdrive ×%d" % p_next_mult)

		dmg_per_hit = maxi(0, running)
		hit_count = eval_attack_relic.hits + (eval_attack_relic.sector_finisher_hits_bonus if is_finisher_hour else 0)
		if is_finisher_hour and eval_attack_relic.sector_finisher_hits_bonus > 0:
			breakdown.append("Finisher Hits: +%d" % eval_attack_relic.sector_finisher_hits_bonus)
		total_dmg = dmg_per_hit * hit_count
		if hit_count > 1:
			breakdown.append("Final: %d × %d = %d DMG" % [dmg_per_hit, hit_count, total_dmg])
		else:
			breakdown.append("Final: %d DMG" % total_dmg)

	if base_blk > 0 or relic.multiply_current_block > 1.0:
		if base_blk > 0:
			breakdown.append("Base Block: %d" % base_blk)
		if base_blk > 0 and has_resonance:
			breakdown.append("Resonance Block: +%d" % relic.resonance_essence_bonus)
		if not is_equal_approx(socket_mult, 1.0) and base_blk > 0:
			breakdown.append("Socket ×%.2f" % socket_mult)
		if relic.multiply_current_block > 1.0:
			breakdown.append("Block Multiplier ×%.1f" % relic.multiply_current_block)
		breakdown.append("Final: +%d BLOCK" % block_gain)

	var nominal_total: int = base_dmg * maxi(1, eval_attack_relic.hits)
	return {
		"damage_per_hit": dmg_per_hit,
		"hits": hit_count,
		"total_damage": total_dmg,
		"base_damage": base_dmg,
		"block_gain": block_gain,
		"base_block": base_blk,
		"is_damage_buffed": eval_attack_relic.base_damage > 0 and total_dmg > nominal_total,
		"is_damage_weakened": eval_attack_relic.base_damage > 0 and total_dmg < nominal_total,
		"is_block_buffed": block_gain > base_blk,
		"math_breakdown": breakdown,
		"active_tags": active_tags,
	}


static func forecast(b: CombatController, hours: Array, replace_hour: int = 0, relic: ClockRelicData = null) -> String:
	return build_forecast(b, hours, replace_hour, relic).text


static func forecast_result(b: CombatController, hours: Array, replace_hour: int = 0, relic: ClockRelicData = null) -> ForecastResult:
	return build_forecast(b, hours, replace_hour, relic)


static func get_step_outcomes(b: CombatController, hours: Array, replace_hour: int = 0, relic: ClockRelicData = null) -> Array[Dictionary]:
	return build_forecast(b, hours, replace_hour, relic).step_outcomes


static func build_forecast(b: CombatController, hours: Array, replace_hour: int = 0, relic: ClockRelicData = null) -> ForecastResult:
	var res := ForecastResult.new()
	var s: Dictionary = {}
	for key: String in ["player_hp","player_max_hp","player_block","player_strength","player_bleed","player_weak","player_vulnerable","player_thorns","player_next_hit_bonus","player_next_attack_multiplier","enemy_hp","enemy_max_hp","enemy_block","enemy_strength","enemy_bleed","enemy_weak","enemy_vulnerable","enemy_thorns"]:
		s[key] = b.get(key)
	s.overkill = OKRunState.current_ok
	var start_ok: int = int(s.overkill)
	var slotted_relics: Array[ClockRelicData] = []
	var socket_multipliers: Array[float] = []
	for idx: int in range(b.player_sockets.size()):
		var sock: ClockSocketData = b.player_sockets[idx]
		var h_idx: int = idx + 1
		slotted_relics.append(relic if h_idx == replace_hour else sock.slotted_relic)
		socket_multipliers.append(sock.multiplier)
	s.slotted_relics = slotted_relics
	s.socket_multipliers = socket_multipliers
	s.player_sockets = b.player_sockets
	s.enemy_sockets = b.enemy_sockets
	s.enemy = b._active_enemy()

	var completed: int = 0
	var uncertain: bool = false
	for hour: int in hours:
		var enemy_hour: int = EnemyClockPattern.hour_for(hour, b._active_enemy())
		var e: ClockSocketData = b.enemy_sockets[enemy_hour - 1]
		if not e.intent_revealed:
			uncertain = true
			break
		var hp_before: int = int(s.player_hp)
		var e_hp_before: int = int(s.enemy_hp)
		var ok_before: int = int(s.overkill)
		var p: ClockSocketData = b.player_sockets[hour - 1]
		var r: ClockRelicData = s.slotted_relics[hour - 1]
		_simulate_tick(s, hour, p, e, r)
		completed += 1
		var Twin_triggered: bool = false
		if int(s.player_hp) > 0 and int(s.enemy_hp) > 0:
			if EnemyClockPattern.has_twin(b._active_enemy()) and hour % 3 == 0:
				var echo: ClockSocketData = b.enemy_sockets[((enemy_hour + 3) % 9)]
				if not echo.intent_revealed:
					uncertain = true
					break
				Twin_triggered = true
				if echo.intent_damage > 0:
					_enemy_hit(s, _enemy_damage(s, echo.intent_damage), echo.is_siphon)
					s.enemy_block = int(s.enemy_block) + echo.intent_block
			if int(s.player_hp) > 0 and int(s.enemy_hp) > 0:
				for key: String in ["player_weak","player_vulnerable","enemy_weak","enemy_vulnerable"]:
					s[key] = maxi(0, int(s[key]) - 1)

		var p_hp_delta: int = maxi(0, int(s.player_hp)) - maxi(0, hp_before)
		var e_hp_delta: int = maxi(0, int(s.enemy_hp)) - maxi(0, e_hp_before)
		var ok_delta: int = int(s.overkill) - ok_before
		var relic_label: String = r.name if r != null else "Empty"
		var step_summary: String = "H%d (%s): Enemy %+d HP · You %+d HP · %d Blk%s" % [
			hour,
			relic_label,
			e_hp_delta,
			p_hp_delta,
			int(s.player_block),
			(" · +%d OK" % ok_delta) if ok_delta > 0 else (" · Twin Hand" if Twin_triggered else "")
		]
		res.step_outcomes.append({
			"hour": hour,
			"player_hp_delta": p_hp_delta,
			"player_hp_after": maxi(0, int(s.player_hp)),
			"player_block_after": int(s.player_block),
			"enemy_hp_delta": e_hp_delta,
			"enemy_hp_after": maxi(0, int(s.enemy_hp)),
			"enemy_block_after": int(s.enemy_block),
			"overkill_gained": ok_delta,
			"overkill_after": int(s.overkill),
			"summary": step_summary,
		})
		if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0:
			break

	res.completed = completed
	res.uncertain = uncertain
	res.player_hp_after = maxi(0, int(s.player_hp))
	res.player_block_after = int(s.player_block)
	res.enemy_hp_after = maxi(0, int(s.enemy_hp))
	res.enemy_block_after = int(s.enemy_block)
	res.overkill_after = int(s.overkill)
	res.overkill_gained = int(s.overkill) - start_ok

	var result: String = "You: %d HP · %d Block · %d Overkill   |   Enemy: %d HP · %d Block" % [res.player_hp_after, res.player_block_after, res.overkill_after, res.enemy_hp_after, res.enemy_block_after]
	res.summary = result
	if completed == 0:
		res.text = "Outcome unknown until the next enemy action is revealed."
		last_forecast_result = res
		return res
	var excludes_artifacts: bool = not RunManager.relics_held.is_empty()
	var prefix: String = "Estimate (Artifact triggers excluded) — " if excludes_artifacts else "After resolution — "
	if uncertain:
		res.text = ("Known hours only (Artifact triggers excluded) — " if excludes_artifacts else "Known hours only — ") + result + "\nRemaining actions are unrevealed."
		last_forecast_result = res
		return res
	if int(s.player_hp) <= 0: result += " · LETHAL TO YOU"
	elif int(s.enemy_hp) <= 0: result += " · ENEMY DEFEATED (forecast ends here)"
	res.text = prefix + result
	last_forecast_result = res
	return res


static func _tick(s: Dictionary, p: ClockSocketData, e: ClockSocketData, r: ClockRelicData) -> void:
	var hour: int = p.hour_index if p != null and p.hour_index > 0 else 1
	_simulate_tick(s, hour, p, e, r)


static func _simulate_tick(s: Dictionary, hour: int, p: ClockSocketData, e: ClockSocketData, r: ClockRelicData) -> void:
	s.player_hp = int(s.player_hp) - int(s.player_bleed)
	if int(s.enemy_bleed) > 0:
		s.enemy_hp = int(s.enemy_hp) - int(s.enemy_bleed)
		if int(s.enemy_hp) <= 0:
			var bleed_excess: int = maxi(0, -int(s.enemy_hp))
			s.enemy_hp = 0
			s.overkill = int(s.overkill) + bleed_excess
	if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0:
		return

	var socket_mult: float = p.multiplier if p != null else 1.0
	if s.has("socket_multipliers") and hour >= 1 and hour <= s.socket_multipliers.size():
		socket_mult = float(s.socket_multipliers[hour - 1])

	var prev_h: int = ((hour - 2 + 9) % 9) + 1
	var prev_r: ClockRelicData = null
	if s.has("slotted_relics") and prev_h >= 1 and prev_h <= s.slotted_relics.size():
		prev_r = s.slotted_relics[prev_h - 1]

	var active_relics: Array[ClockRelicData] = []
	if r != null:
		if r.echo_previous_hour and prev_r != null and not prev_r.echo_previous_hour:
			active_relics.append(prev_r)
		active_relics.append(r)

	var player_attacks_this_tick: bool = false
	for ar: ClockRelicData in active_relics:
		if ar.base_damage > 0:
			player_attacks_this_tick = true
			break

	# Step 2A: Player Support, Shields, Buffs, Bleed Multiplication/Detonation, Socket Charging
	for ar: ClockRelicData in active_relics:
		var has_resonance: bool = ar.resonance_essence_bonus > 0 and prev_r != null and ar.shares_essence_with(prev_r)
		if ar.base_block > 0:
			var raw_blk: int = ar.base_block + (ar.resonance_essence_bonus if has_resonance else 0)
			s.player_block = int(s.player_block) + floori(float(raw_blk) * socket_mult)
		if ar.multiply_current_block > 1.0 and int(s.player_block) > 0:
			s.player_block = floori(float(s.player_block) * ar.multiply_current_block)
		s.player_strength = int(s.player_strength) + ar.apply_strength
		s.player_thorns = int(s.player_thorns) + ar.apply_thorns
		if ar.apply_vulnerable > 0:
			s.enemy_vulnerable = int(s.enemy_vulnerable) + ar.apply_vulnerable + (1 if not player_attacks_this_tick else 0)
		if ar.apply_weak > 0:
			s.enemy_weak = int(s.enemy_weak) + ar.apply_weak + (1 if e.intent_damage <= 0 else 0)
		if ar.apply_bleed > 0:
			s.enemy_bleed = int(s.enemy_bleed) + floori(float(ar.apply_bleed) * socket_mult)
		if ar.multiply_enemy_bleed > 1.0 and int(s.enemy_bleed) > 0:
			s.enemy_bleed = floori(float(s.enemy_bleed) * ar.multiply_enemy_bleed)
		if ar.trigger_bleed_times > 0 and int(s.enemy_bleed) > 0:
			for _b_i: int in range(ar.trigger_bleed_times):
				s.enemy_hp = int(s.enemy_hp) - int(s.enemy_bleed)
				if int(s.enemy_hp) <= 0:
					var det_excess: int = maxi(0, -int(s.enemy_hp))
					s.enemy_hp = 0
					s.overkill = int(s.overkill) + det_excess
		s.player_next_hit_bonus = int(s.player_next_hit_bonus) + ar.bonus_damage_next_hit
		if ar.base_damage <= 0 and ar.next_attack_multiplier > 1:
			s.player_next_attack_multiplier = maxi(int(s.player_next_attack_multiplier), ar.next_attack_multiplier)
		s.overkill = int(s.overkill) + ar.grant_overkill
		if ar.charge_next_socket_multiplier > 0.0 and s.has("socket_multipliers"):
			var next_h: int = (hour % 9) + 1
			s.socket_multipliers[next_h - 1] = minf(4.0, float(s.socket_multipliers[next_h - 1]) + ar.charge_next_socket_multiplier)

	if int(s.enemy_hp) <= 0:
		return

	# Step 2B: Enemy Support / Intents
	s.enemy_block = int(s.enemy_block) + e.intent_block
	s.enemy_strength = int(s.enemy_strength) + e.intent_strength
	s.player_bleed = int(s.player_bleed) + e.intent_bleed
	if e.intent_weak > 0:
		s.player_weak = int(s.player_weak) + e.intent_weak + (1 if not player_attacks_this_tick else 0)
	if e.intent_vulnerable > 0:
		s.player_vulnerable = int(s.player_vulnerable) + e.intent_vulnerable + (1 if e.intent_damage <= 0 else 0)

	# Step 3A: Player Attacks
	for ar: ClockRelicData in active_relics:
		if ar.base_damage <= 0:
			continue
		var has_resonance: bool = ar.resonance_essence_bonus > 0 and prev_r != null and ar.shares_essence_with(prev_r)
		var strike_bonus: int = int(s.player_next_hit_bonus)
		s.player_next_hit_bonus = 0
		var raw_base: int = ar.base_damage
		if ar.conditional_hp_threshold_pct > 0.0 and float(s.enemy_hp) / maxf(float(s.enemy_max_hp), 1.0) <= ar.conditional_hp_threshold_pct:
			raw_base = ar.conditional_damage
		if has_resonance:
			raw_base += ar.resonance_essence_bonus
		if hour in [3, 6, 9] and ar.sector_finisher_bonus_damage > 0:
			raw_base += ar.sector_finisher_bonus_damage

		var arch_bonus: int = 0
		if ar.damage_per_current_block_pct > 0.0:
			arch_bonus += floori(float(s.player_block) * ar.damage_per_current_block_pct)
		if ar.thorns_to_damage_multiplier > 0.0:
			arch_bonus += floori(float(s.player_thorns) * ar.thorns_to_damage_multiplier)
		if ar.damage_per_enemy_bleed > 0:
			arch_bonus += int(s.enemy_bleed) * ar.damage_per_enemy_bleed
		if ar.damage_per_banked_overkill_div > 0:
			arch_bonus += int(int(s.overkill) / ar.damage_per_banked_overkill_div)

		var damage: int = raw_base + int(s.player_strength) + strike_bonus + arch_bonus
		if int(s.enemy_vulnerable) > 0:
			damage = floori(float(damage) * 1.5)
		if int(s.player_weak) > 0:
			damage = floori(float(damage) * 0.75)
		damage = floori(float(damage) * socket_mult) * int(s.player_next_attack_multiplier)
		s.player_next_attack_multiplier = maxi(1, ar.next_attack_multiplier)
		var total_hits: int = ar.hits + (ar.sector_finisher_hits_bonus if hour in [3, 6, 9] else 0)
		for _hit: int in range(total_hits):
			var target_was_alive: bool = int(s.enemy_hp) > 0
			if p != null and p.is_hazard:
				s.player_hp = int(s.player_hp) - floori(float(damage) * 0.5)
			var unblocked: int = maxi(0, damage - int(s.enemy_block))
			var hp_damage: int = mini(maxi(int(s.enemy_hp), 0), unblocked)
			var overkill: int = maxi(0, unblocked - maxi(int(s.enemy_hp), 0))
			s.overkill = int(s.overkill) + overkill
			s.enemy_hp = maxi(0, int(s.enemy_hp) - hp_damage)
			s.enemy_block = maxi(0, int(s.enemy_block) - damage)
			if unblocked > 0 and ar.overkill_extraction_pct > 0.0:
				s.overkill = int(s.overkill) + maxi(1, floori(float(unblocked) * ar.overkill_extraction_pct))
			if ar.recoil_block_on_overkill:
				s.player_block = int(s.player_block) + overkill
			if ar.lifesteal and int(s.player_hp) > 0:
				s.player_hp = int(s.player_hp) + mini(hp_damage, maxi(0, int(s.player_max_hp) - int(s.player_hp)))
			if target_was_alive:
				s.player_hp = int(s.player_hp) - int(s.enemy_thorns)
			if int(s.player_hp) <= 0:
				return
		# A relic finishes its remaining hits on the defeated target and banks
		# their damage as Overkill before the enemy's retaliation is skipped.
		if int(s.enemy_hp) <= 0:
			return

	# Step 3B: Enemy Attacks
	if e.intent_damage > 0 and int(s.enemy_hp) > 0:
		var damage: int = _enemy_damage(s, e.intent_damage)
		for _hit: int in e.intent_hits:
			_enemy_hit(s, damage, e.is_siphon)
			if int(s.player_hp) <= 0 or int(s.enemy_hp) <= 0:
				return


static func _enemy_damage(s: Dictionary, base: int) -> int:
	var damage: int = base + int(s.enemy_strength)
	if int(s.player_vulnerable) > 0: damage = floori(damage * 1.5)
	if int(s.enemy_weak) > 0: damage = floori(damage * 0.75)
	return damage


static func _enemy_hit(s: Dictionary, damage: int, siphon: bool = false) -> void:
	var hp_damage: int = maxi(0, damage - int(s.player_block))
	s.player_hp = int(s.player_hp) - hp_damage
	s.player_block = maxi(0, int(s.player_block) - damage)
	if siphon and hp_damage > 0 and int(s.overkill) > 0:
		s.overkill = int(s.overkill) - floori(int(s.overkill) * 0.25)
	if int(s.player_thorns) > 0:
		s.enemy_hp = int(s.enemy_hp) - int(s.player_thorns)
		if int(s.enemy_hp) <= 0:
			var thorns_excess: int = maxi(0, -int(s.enemy_hp))
			s.enemy_hp = 0
			s.overkill = int(s.overkill) + thorns_excess
