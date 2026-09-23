class_name BattleIntroSequence extends Control
## Short, reusable opening choreography. It owns presentation locks only;
## CombatController starts the first real decision after this sequence ends.

var _battle: CombatController
var _stage: Control
var _player_target_hp: float = 0.0
var _enemy_target_hp: float = 0.0


func prime(battle: CombatController, stage: Control) -> void:
	_battle = battle
	_stage = stage
	name = "BattleIntroSequence"
	z_index = 80
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _stage.has_method("set_intro_hidden"): _stage.set_intro_hidden()
	for clock: Control in [_battle._player_chrono, _battle._enemy_chrono]:
		clock.modulate.a = 0.0
	for portrait: Control in [_battle._player_portrait, _battle._enemy_portrait]:
		var panel: Control = portrait.get_node("CharacterStatusPanel")
		var stats: Control = portrait.get_node("PlayerStatsLabel" if portrait == _battle._player_portrait else "EnemyStatsLabel")
		var health: ProgressBar = portrait.get_node("Vitality")
		panel.modulate.a = 0.0
		stats.modulate.a = 0.0
		health.modulate.a = 0.0
		if portrait == _battle._player_portrait: _player_target_hp = health.value
		else: _enemy_target_hp = health.value
		health.value = 0.0
	_battle._choice_overlay.hide()
	_battle._intent_panel.hide()
	_battle._battle_info.hide()
	_battle._history_button.hide()
	for child: Node in _battle.get_children():
		if child is Button and child.text == "HOW TO PLAY": child.hide()


func play() -> void:
	var speed: float = AudioManager.animation_speed_scale()
	await get_tree().create_timer(0.08 / speed).timeout
	await _play_title(speed)
	var clock_reveal := create_tween().set_parallel(true).set_speed_scale(speed)
	for clock: Control in [_battle._player_chrono, _battle._enemy_chrono]:
		clock_reveal.tween_property(clock, "modulate:a", 1.0, 0.24)
	if _stage.has_method("reveal_combatant"): _stage.reveal_combatant(true)
	_spawn_ground_burst(_battle._player_portrait, Color("70d8e4"))
	await get_tree().create_timer(0.18 / speed).timeout
	await _reveal_status(_battle._player_portrait, _player_target_hp, speed)
	if _stage.has_method("reveal_combatant"): _stage.reveal_combatant(false)
	_spawn_ground_burst(_battle._enemy_portrait, Color("e08b69"))
	await get_tree().create_timer(0.14 / speed).timeout
	await _reveal_status(_battle._enemy_portrait, _enemy_target_hp, speed)
	_battle._intent_panel.show()
	_battle._battle_info.show()
	_battle._history_button.show()
	for child: Node in _battle.get_children():
		if child is Button and child.text == "HOW TO PLAY": child.show()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_free()


func _play_title(speed: float) -> void:
	var glow := TextureRect.new()
	glow.texture = AmbientMotion._get_glow_texture()
	glow.modulate = Color(0.45, 0.9, 1.0, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	glow.offset_left = -290
	glow.offset_right = 290
	glow.offset_top = -290
	glow.offset_bottom = 290
	glow.pivot_offset = Vector2(290, 290)
	glow.scale = Vector2(0.25, 0.25)
	var title := Label.new()
	title.text = "BATTLE START"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", ScreenDesign.display_font())
	title.add_theme_font_size_override("font_size", 82)
	title.add_theme_color_override("font_color", Color("f5e9cf"))
	title.add_theme_color_override("font_outline_color", Color("071019"))
	title.add_theme_constant_override("outline_size", 14)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.offset_left = -560
	title.offset_right = 560
	title.offset_top = -90
	title.offset_bottom = 90
	title.pivot_offset = Vector2(560, 90)
	title.scale = Vector2(0.24, 0.24) if not AudioManager.reduced_motion else Vector2.ONE
	title.modulate.a = 0.0
	AudioManager.play_combat_sound("reveal")
	var impact := create_tween().set_speed_scale(speed)
	impact.set_parallel(true)
	impact.tween_property(title, "modulate:a", 1.0, 0.10)
	impact.tween_property(title, "scale", Vector2(1.10, 1.10), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact.tween_property(glow, "modulate:a", 0.82, 0.12)
	impact.tween_property(glow, "scale", Vector2(1.25, 1.25), 0.26).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await impact.finished
	AmbientMotion.shake(_battle, 4.0, 0.14)
	var settle := create_tween().set_speed_scale(speed)
	settle.tween_property(title, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.tween_interval(0.18)
	settle.set_parallel(true)
	settle.tween_property(title, "modulate:a", 0.0, 0.14)
	settle.tween_property(glow, "modulate:a", 0.0, 0.18)
	await settle.finished
	title.queue_free()
	glow.queue_free()


func _reveal_status(portrait: Control, target_hp: float, speed: float) -> void:
	var panel: Control = portrait.get_node("CharacterStatusPanel")
	var stats: Control = portrait.get_node("PlayerStatsLabel" if portrait == _battle._player_portrait else "EnemyStatsLabel")
	var health: ProgressBar = portrait.get_node("Vitality")
	var reveal := create_tween().set_parallel(true).set_speed_scale(speed)
	reveal.tween_property(panel, "modulate:a", 1.0, 0.16)
	reveal.tween_property(stats, "modulate:a", 1.0, 0.16)
	reveal.tween_property(health, "modulate:a", 1.0, 0.12)
	reveal.tween_property(health, "value", target_hp, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await reveal.finished


func _spawn_ground_burst(portrait: Control, color: Color) -> void:
	var burst := TextureRect.new()
	burst.texture = AmbientMotion._get_glow_texture()
	burst.modulate = Color(color, 0.86)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 79
	_battle.add_child(burst)
	burst.size = Vector2(220, 76)
	burst.position = portrait.global_position - _battle.global_position + Vector2((portrait.size.x - burst.size.x) * 0.5, portrait.size.y * 0.72)
	burst.pivot_offset = burst.size * 0.5
	burst.scale = Vector2(0.18, 0.35)
	var pulse := burst.create_tween().set_parallel(true)
	pulse.tween_property(burst, "scale", Vector2(1.35, 1.0), 0.28).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	pulse.tween_property(burst, "modulate:a", 0.0, 0.30).set_delay(0.06)
	pulse.chain().tween_callback(burst.queue_free)
