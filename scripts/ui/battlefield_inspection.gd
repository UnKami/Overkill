class_name BattlefieldInspection extends Control
## Full-screen tactical readout. The arena is intentionally occluded so the
## two mechanisms and their deterministic nine-hour output become the focus.

signal close_requested

const CLOCK_SCENE := preload("res://scenes/chronometer_view.tscn")

var _battle: CombatController
var _player_clock: ChronometerView
var _enemy_clock: ChronometerView
var _player_details: RichTextLabel
var _enemy_details: RichTextLabel
var _subtitle: Label


func install(battle: CombatController) -> void:
	_battle = battle
	name = "BattlefieldInspection"
	z_index = 85
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ScreenDesign.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color("040a12")
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 30)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var heading := ScreenDesign.label(header, "BATTLEFIELD ANALYSIS", 34, ScreenDesign.TEXT, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := ScreenDesign.button(header, "RETURN TO RELIC CHOICE  [I]", func() -> void: close_requested.emit())
	close.custom_minimum_size.x = 360
	_subtitle = ScreenDesign.label(root, "A complete turn of both mechanisms, calculated from the current battle state.", 20, ScreenDesign.MUTED)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sides := HBoxContainer.new()
	sides.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sides.add_theme_constant_override("separation", 44)
	root.add_child(sides)
	var player_side := _build_side(false)
	var enemy_side := _build_side(true)
	sides.add_child(player_side)
	sides.add_child(enemy_side)

	ScreenDesign.apply_text_size(self)
	hide()


func _build_side(enemy: bool) -> VBoxContainer:
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 4)
	var clock: ChronometerView = CLOCK_SCENE.instantiate()
	clock.custom_minimum_size = Vector2(500, 500)
	clock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	side.add_child(clock)
	# install() runs while CombatController itself is entering the tree, so the
	# chronometer's @onready nodes become valid on the deferred initialization.
	clock.call_deferred("initialize", enemy, "ENEMY FULL CYCLE" if enemy else "YOUR FULL CYCLE")
	clock.get_node("TitleLabel").hide()
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var details := RichTextLabel.new()
	details.bbcode_enabled = true
	details.fit_content = false
	details.custom_minimum_size = Vector2(0, 230)
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.scroll_active = false
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_font_size_override("normal_font_size", 20)
	details.add_theme_color_override("default_color", Color("d9e1e5"))
	details.add_theme_stylebox_override("normal", _details_style(Color("d9896d") if enemy else Color("6fd8e4")))
	side.add_child(details)
	if enemy:
		_enemy_clock = clock
		_enemy_details = details
	else:
		_player_clock = clock
		_player_details = details
	return side


func _details_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1621f2")
	style.border_color = accent
	style.set_border_width_all(1)
	style.border_width_top = 3
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func open() -> void:
	refresh()
	show()


func close() -> void:
	hide()


func refresh() -> void:
	if not is_instance_valid(_battle):
		return
	_player_clock.bind_sockets(_battle.player_sockets)
	_player_clock.rotation_direction = 1
	_player_clock.set_twin_hand(false)
	_player_clock.mark_hour(_battle.turn_number)
	_player_clock.highlight_quadrant(_battle.active_quadrant, Color("6fd8e4"))
	_player_clock.snap_hand_to_hour(_battle.turn_number, 0.01)

	var enemy: EnemyData = _battle._active_enemy()
	var enemy_hour: int = EnemyClockPattern.hour_for(_battle.turn_number, enemy)
	_enemy_clock.bind_sockets(_battle.enemy_sockets)
	_enemy_clock.rotation_direction = -1 if EnemyClockPattern.profile(enemy) in ["reverse", "eclipse"] else 1
	_enemy_clock.set_twin_hand(EnemyClockPattern.has_twin(enemy))
	_enemy_clock.mark_hour(enemy_hour)
	_enemy_clock.highlight_quadrant(4 - _battle.active_quadrant if _enemy_clock.rotation_direction < 0 else _battle.active_quadrant, Color("e88b70"))
	_enemy_clock.snap_hand_to_hour(enemy_hour, 0.01)

	_player_details.text = _player_forecast()
	_enemy_details.text = _enemy_forecast(enemy)
	_subtitle.text = "Nine-hour deterministic forecast from the current state  ·  next player hour %d  ·  next enemy hour %d" % [_battle.turn_number, enemy_hour]


func _player_forecast() -> String:
	var attack: int = 0
	var block_gain: int = 0
	var strength: int = _battle.player_strength
	var thorns_gain: int = 0
	var bleed_applied: int = 0
	var weak_applied: int = 0
	var vulnerable_applied: int = 0
	var enemy_vulnerable: int = _battle.enemy_vulnerable
	var player_weak: int = _battle.player_weak
	var next_bonus: int = _battle.player_next_hit_bonus
	var next_multiplier: int = _battle.player_next_attack_multiplier
	for socket: ClockSocketData in _battle.player_sockets:
		var relic: ClockRelicData = socket.slotted_relic
		if relic == null:
			continue
		block_gain += relic.base_block
		strength += relic.apply_strength
		thorns_gain += relic.apply_thorns
		bleed_applied += relic.apply_bleed
		weak_applied += relic.apply_weak
		vulnerable_applied += relic.apply_vulnerable
		enemy_vulnerable += relic.apply_vulnerable
		if relic.bonus_damage_next_hit > 0:
			next_bonus += relic.bonus_damage_next_hit
		if relic.base_damage > 0:
			var damage: int = relic.base_damage + strength + next_bonus
			next_bonus = 0
			if relic.conditional_hp_threshold_pct > 0.0 and float(_battle.enemy_hp) / maxf(float(_battle.enemy_max_hp), 1.0) <= relic.conditional_hp_threshold_pct:
				damage = relic.conditional_damage + strength
			if enemy_vulnerable > 0:
				damage = int(floor(damage * 1.5))
			if player_weak > 0:
				damage = int(floor(damage * 0.75))
			damage = int(floor(damage * socket.multiplier)) * next_multiplier
			attack += damage * relic.hits
			next_multiplier = maxi(1, relic.next_attack_multiplier)
		if enemy_vulnerable > 0:
			enemy_vulnerable -= 1
		if player_weak > 0:
			player_weak -= 1
	return _format_forecast(
		"YOUR MECHANISM",
		_battle.player_hp,
		_battle.player_max_hp,
		_battle.player_block,
		attack,
		block_gain,
		strength - _battle.player_strength,
		thorns_gain,
		bleed_applied,
		weak_applied,
		vulnerable_applied,
		_battle._status_text(_battle.player_strength, _battle.player_bleed, _battle.player_thorns, _battle.player_weak, _battle.player_vulnerable),
		_player_sequence(),
		0
	)


func _enemy_forecast(enemy: EnemyData) -> String:
	var attack: int = 0
	var block_gain: int = 0
	var strength: int = _battle.enemy_strength
	var strength_gain: int = 0
	var bleed_applied: int = 0
	var weak_applied: int = 0
	var vulnerable_applied: int = 0
	var player_vulnerable: int = _battle.player_vulnerable
	var enemy_weak: int = _battle.enemy_weak
	var hidden_hours: int = 0
	for player_hour: int in range(1, 10):
		var enemy_hour: int = EnemyClockPattern.hour_for(player_hour, enemy)
		var socket: ClockSocketData = _battle.enemy_sockets[enemy_hour - 1]
		if not socket.intent_revealed:
			hidden_hours += 1
			continue
		block_gain += socket.intent_block
		strength += socket.intent_strength
		strength_gain += socket.intent_strength
		bleed_applied += socket.intent_bleed
		weak_applied += socket.intent_weak
		vulnerable_applied += socket.intent_vulnerable
		player_vulnerable += socket.intent_vulnerable
		if socket.intent_damage > 0:
			var damage: int = socket.intent_damage + strength
			if player_vulnerable > 0:
				damage = int(floor(damage * 1.5))
			if enemy_weak > 0:
				damage = int(floor(damage * 0.75))
			attack += damage * socket.intent_hits
		if EnemyClockPattern.has_twin(enemy) and player_hour % 3 == 0:
			var opposite: int = ((enemy_hour + 3) % 9) + 1
			var echo: ClockSocketData = _battle.enemy_sockets[opposite - 1]
			if echo.intent_revealed and echo.intent_damage > 0:
				var echo_damage: int = echo.intent_damage + strength
				if player_vulnerable > 0:
					echo_damage = int(floor(echo_damage * 1.5))
				if enemy_weak > 0:
					echo_damage = int(floor(echo_damage * 0.75))
				attack += echo_damage
			if echo.intent_revealed:
				block_gain += echo.intent_block
		if player_vulnerable > 0:
			player_vulnerable -= 1
		if enemy_weak > 0:
			enemy_weak -= 1
	return _format_forecast(
		"%s  ·  %s" % [enemy.display_name.to_upper() if enemy != null else "ENEMY", EnemyClockPattern.profile(enemy).to_upper()],
		_battle.enemy_hp,
		_battle.enemy_max_hp,
		_battle.enemy_block,
		attack,
		block_gain,
		strength_gain,
		0,
		bleed_applied,
		weak_applied,
		vulnerable_applied,
		_battle._status_text(_battle.enemy_strength, _battle.enemy_bleed, _battle.enemy_thorns, _battle.enemy_weak, _battle.enemy_vulnerable),
		_enemy_sequence(enemy),
		hidden_hours
	)


func _player_sequence() -> String:
	var sectors: PackedStringArray = []
	for start: int in [0, 3, 6]:
		var entries: PackedStringArray = []
		for index: int in range(start, start + 3):
			var socket: ClockSocketData = _battle.player_sockets[index]
			var relic: ClockRelicData = socket.slotted_relic
			entries.append("%d %s" % [index + 1, RelicPedestalView.summary(relic) if relic != null else "empty"])
		sectors.append("  |  ".join(entries))
	return "\n".join(sectors)


func _enemy_sequence(enemy: EnemyData) -> String:
	var sectors: PackedStringArray = []
	for start: int in [0, 3, 6]:
		var entries: PackedStringArray = []
		for player_index: int in range(start, start + 3):
			var player_hour: int = player_index + 1
			var enemy_hour: int = EnemyClockPattern.hour_for(player_hour, enemy)
			var socket: ClockSocketData = _battle.enemy_sockets[enemy_hour - 1]
			entries.append("%d %s" % [enemy_hour, socket.intent_label if socket.intent_revealed else "hidden"])
		sectors.append("  |  ".join(entries))
	return "\n".join(sectors)


func _format_forecast(title: String, hp: int, max_hp: int, current_block: int, attack: int, block_gain: int, strength_gain: int, thorns_gain: int, bleed_applied: int, weak_applied: int, vulnerable_applied: int, statuses: String, sequence: String, hidden_hours: int) -> String:
	var accumulations: PackedStringArray = []
	for entry: Array in [[strength_gain, "Strength"], [thorns_gain, "Thorns"], [bleed_applied, "Bleed"], [weak_applied, "Weak"], [vulnerable_applied, "Vulnerable"]]:
		if int(entry[0]) > 0:
			accumulations.append("+%d %s" % [entry[0], entry[1]])
	if accumulations.is_empty():
		accumulations.append("No additional statuses")
	var current_status: String = statuses if not statuses.is_empty() else "none"
	var cycle_name: String = "REVEALED CYCLE" if hidden_hours > 0 else "FULL CYCLE"
	var concealment: String = "  ·  %d HOURS HIDDEN" % hidden_hours if hidden_hours > 0 else ""
	return "[font_size=24][b]%s[/b][/font_size]\nCURRENT  ·  %d / %d HP  ·  %d BLOCK  ·  %s\n[font_size=26][b]%s  ·  %d ATTACK  ·  +%d BLOCK%s[/b][/font_size]\nACCUMULATES  ·  %s\nSEQUENCE\n%s" % [title, maxi(hp, 0), max_hp, current_block, current_status, cycle_name, attack, block_gain, concealment, "  ·  ".join(accumulations), sequence]
