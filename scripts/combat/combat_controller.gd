class_name CombatController extends Control
## CombatController - Orchestrates the Dual-Chronometer Battle Engine.
## Implements Phase 1 (Assembly Cycle) and Phase 2 (Quadrant Engine).

signal combat_won(enemies_data: Array[EnemyData])
signal combat_lost

enum Phase { ASSEMBLY, QUADRANT }
const Presentation := preload("res://scripts/combat/clock_battle_presentation.gd")

@export var pedestal_scene: PackedScene
@export var damage_number_scene: PackedScene

@onready var _background: TextureRect = %Background
@onready var _hud: CombatHUD = %HUD
@onready var _player_chrono: ChronometerView = %PlayerChronometer
@onready var _enemy_chrono: ChronometerView = %EnemyChronometer
@onready var _player_portrait: TextureRect = %PlayerPortrait
@onready var _enemy_portrait: TextureRect = %EnemyPortrait
@onready var _player_stats_label: Label = %PlayerStatsLabel
@onready var _enemy_stats_label: Label = %EnemyStatsLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _pedestal_row: VBoxContainer = %PedestalRow
@onready var _skip_button: Button = %SkipButton
@onready var _turn_banner: Label = %TurnBanner
@onready var _clash_nexus: Control = %ClashNexus
@onready var _nexus_sigil: TextureRect = %NexusSigil

var phase: Phase = Phase.ASSEMBLY
var turn_number: int = 1
var active_quadrant: int = 1

var player_hp: int = 80
var player_max_hp: int = 80
var player_block: int = 0
var player_strength: int = 0
var player_vulnerable: int = 0
var player_weak: int = 0
var player_thorns: int = 0
var player_bleed: int = 0
var player_next_hit_bonus: int = 0

var enemy_hp: int = 50
var enemy_max_hp: int = 50
var enemy_block: int = 0
var enemy_strength: int = 0
var enemy_vulnerable: int = 0
var enemy_weak: int = 0
var enemy_thorns: int = 0
var enemy_bleed: int = 0

var player_sockets: Array[ClockSocketData] = []
var enemy_sockets: Array[ClockSocketData] = []
var player_deck: Array[ClockRelicData] = []
var player_discard: Array[ClockRelicData] = []
var current_draft_selection: Array[ClockRelicData] = []
var current_drawn_relic: ClockRelicData = null
var enemies_data: Array[EnemyData] = []
var _combat_over: bool = false
var _resolving: bool = false
var _banner_tween: Tween
var _enemy_index: int = 0
var _battle_info: Label
var _stage: Control
var _choice_overlay: PanelContainer
var _guidance: BattleGuidance


var _pending_enemies: Array[EnemyData] = []
var _pending_background_id: String = ""
var _is_started: bool = false


func _ready() -> void:
	Presentation.install(self)
	Presentation.directed_layout(self)
	_choice_overlay = preload("res://scripts/ui/relic_choice_overlay.gd").new()
	add_child(_choice_overlay)
	_choice_overlay.install(self)
	_guidance = BattleGuidance.new()
	add_child(_guidance)
	_guidance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = ClockworkStage.new() if OS.get_cmdline_user_args().has("--3d-prototype") else preload("res://scripts/combat/illustrated_stage.gd").new()
	_clash_nexus.add_child(_stage)
	_clash_nexus.move_child(_stage, 0)
	_stage.position = Vector2(-320, -235)
	_stage.size = Vector2(640, 510)
	if OS.get_cmdline_user_args().has("--directed"):
		_install_directed_stage()
	_nexus_sigil.hide()
	_clash_nexus.get_node("NexusTitle").hide()
	_battle_info = Label.new()
	add_child(_battle_info)
	_battle_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_battle_info.offset_top = 76
	_battle_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_battle_info.add_theme_font_size_override("font_size", 18)
	_battle_info.add_theme_color_override("font_color", Color("c4b899"))
	_battle_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_button.pressed.connect(_on_skip_button_pressed)
	_skip_button.mouse_entered.connect(_preview_sweep)
	_skip_button.focus_entered.connect(_preview_sweep)
	_skip_button.mouse_exited.connect(_refresh_guidance)
	_skip_button.focus_exited.connect(_refresh_guidance)
	var help := Button.new()
	help.text = "HOW TO PLAY"
	add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	help.offset_left = -270
	help.offset_right = -30
	help.offset_top = 112
	help.offset_bottom = 162
	help.pressed.connect(func() -> void:
		var guide := AcceptDialog.new()
		guide.title = "Your clock, one decision at a time"
		guide.dialog_text = "1. BUILD YOUR CLOCK\nChoose one of three relics. The first goes to 1 o'clock, then 2, up to 12.\nAfter each placement, your relic and the enemy's matching tick resolve.\nHover a relic to see its destination before committing.\n\n2. SWEEP YOUR CLOCK\nEach turn covers three hours: 1–3, 4–6, 7–9, then 10–12.\nHover a glowing socket to preview replacing it with the offered reserve.\nClick the socket to replace AND resolve the three-hour sweep.\nKEEP & SWEEP discards the offered reserve and activates your current relics.\n\nThe enemy may rotate backward or use a second hand. Read its lit intents."
		guide.theme = ScreenDesign.build_theme()
		add_child(guide)
		guide.confirmed.connect(guide.queue_free)
		guide.canceled.connect(guide.queue_free)
		guide.popup_centered(Vector2i(1100,600)))
	_player_chrono.socket_pressed.connect(_on_player_socket_pressed)
	if not _is_started and not _pending_enemies.is_empty():
		_begin_combat()


func start_combat(incoming_enemies: Array[EnemyData], background_id: String = "") -> void:
	_pending_enemies = incoming_enemies
	_pending_background_id = background_id
	if is_node_ready():
		_begin_combat()

func _install_directed_stage() -> void:
	if _stage is DirectedArena: return
	_stage.get_parent().remove_child(_stage)
	_stage.queue_free()
	_stage = preload("res://scripts/combat/directed_arena.gd").new()
	add_child(_stage)
	move_child(_stage, 1)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_stage.offset_top = 64
	_stage.offset_bottom = 1040


func _begin_combat() -> void:
	if _is_started:
		return
	_is_started = true
	enemies_data = _pending_enemies
	var background_id := _pending_background_id
	_combat_over = false

	# Setup HP & stats
	player_hp = RunManager.current_hp if RunManager.current_hp > 0 else 80
	player_max_hp = RunManager.max_hp if RunManager.max_hp > 0 else 80
	player_block = 0

	var main_enemy: EnemyData = enemies_data[0] if not enemies_data.is_empty() else null
	if main_enemy and main_enemy.id == "act1_boss" and not OS.get_cmdline_user_args().has("--illustrated"):
		_install_directed_stage()
	if main_enemy != null:
		enemy_max_hp = main_enemy.max_hp
		enemy_hp = main_enemy.max_hp
	else:
		enemy_max_hp = 50
		enemy_hp = 50
	enemy_block = 0

	_load_visual_assets(main_enemy, background_id)
	_player_portrait.texture = null
	_enemy_portrait.texture = null
	_init_player_deck()
	_init_chronometers(main_enemy)
	for hour in range(1,13):
		var socket := _player_chrono.get_socket_view(hour)
		socket.previewed.connect(_preview_swap)
		socket.preview_ended.connect(_refresh_guidance)
	_update_stats_display()

	# Start Phase 1
	_start_phase_one()


func _load_visual_assets(main_enemy: EnemyData, background_id: String) -> void:
	# Dedicated Combat Arena Background
	var arena_bg_path := "res://assets/environments/chronoforge_arena.png"
	if not ResourceLoader.exists(arena_bg_path):
		arena_bg_path = "res://assets/environments/combat_arena_bg.jpg"
	if ResourceLoader.exists(arena_bg_path):
		_background.texture = ResourceLoader.load(arena_bg_path)
	else:
		var bg_path := "res://assets/environments/act%d/map_bg.jpg" % RunManager.act_number
		if not background_id.is_empty():
			bg_path = "res://assets/environments/act%d/%s.png" % [RunManager.act_number, background_id]
		if ResourceLoader.exists(bg_path):
			_background.texture = ResourceLoader.load(bg_path)

	# Player Portrait
	var char_img_path := "res://assets/characters/executioner/combat_sprite.png"
	if ResourceLoader.exists(char_img_path):
		_player_portrait.texture = ResourceLoader.load(char_img_path)

	# Enemy Portrait
	_enemy_portrait.flip_h = true
	if main_enemy != null:
		var e_art_path := "res://assets/enemies/act%d/%s_idle.png" % [RunManager.act_number, main_enemy.id]
		if not ResourceLoader.exists(e_art_path):
			e_art_path = "res://assets/enemies/%s_idle.png" % main_enemy.id
		if not ResourceLoader.exists(e_art_path):
			e_art_path = "res://assets/enemies/act%d/%s.png" % [RunManager.act_number, main_enemy.id]
		if not ResourceLoader.exists(e_art_path):
			e_art_path = "res://assets/enemies/%s.png" % main_enemy.id
		if ResourceLoader.exists(e_art_path):
			_enemy_portrait.texture = ResourceLoader.load(e_art_path)

	# Idle bobbing on portraits & pulse on sigil
	AmbientMotion.idle_bob(_player_portrait, 4.0, 3.0)
	AmbientMotion.idle_bob(_enemy_portrait, 4.0, 2.7)
	if _nexus_sigil:
		AmbientMotion.breathe(_nexus_sigil, 0.04, 3.0)


func _init_player_deck() -> void:
	player_deck.clear()
	player_discard.clear()
	RunManager.ensure_clock_inventory()
	for entry in RunManager.clock_inventory:
		var relic := ClockInventory.resolve(entry)
		if relic != null: player_deck.append(relic)
	player_deck.shuffle()

func _init_chronometers(main_enemy: EnemyData) -> void:
	player_sockets.clear()
	enemy_sockets.clear()

	# 12 empty player sockets
	for h in range(1, 13):
		var s := ClockSocketData.new()
		s.hour_index = h
		player_sockets.append(s)

	enemy_sockets = EnemyClockPattern.create(main_enemy)

	_player_chrono.initialize(false, "THE EXECUTIONER")
	_enemy_chrono.initialize(true, main_enemy.display_name.to_upper() if main_enemy != null else "THE ADVERSARY")
	_player_chrono.bind_sockets(player_sockets)
	_enemy_chrono.bind_sockets(enemy_sockets)
	_configure_enemy_clock()


func _active_enemy() -> EnemyData:
	return enemies_data[_enemy_index] if not enemies_data.is_empty() else null


func _configure_enemy_clock() -> void:
	var enemy := _active_enemy()
	_enemy_chrono.rotation_direction = -1 if EnemyClockPattern.profile(enemy) in ["reverse", "eclipse"] else 1
	_enemy_chrono.set_twin_hand(EnemyClockPattern.has_twin(enemy))
	_battle_info.text = EnemyClockPattern.description(enemy)
	_stage.configure_enemy(EnemyClockPattern.profile(enemy))
	if enemies_data.size() > 1:
		_battle_info.text += "   •   OPPONENT %d / %d" % [_enemy_index + 1, enemies_data.size()]


# -------------------------------------------------------------
# PHASE 1: ASSEMBLY CYCLE (Turns 1 - 12)
# -------------------------------------------------------------
func _start_phase_one() -> void:
	phase = Phase.ASSEMBLY
	turn_number = 1
	_show_turn_banner("ASSEMBLY CYCLE ENGAGED")
	_prompt_phase_one_draft()


func _prompt_phase_one_draft() -> void:
	if _combat_over:
		return

	_resolving = false
	OKRunState.start_new_turn()
	_player_chrono.mark_hour(turn_number)
	_enemy_chrono.mark_hour(EnemyClockPattern.hour_for(turn_number, _active_enemy()))
	_refresh_guidance()
	_skip_button.hide()
	_clear_pedestals()

	# Draw 3 relics from deck
	current_draft_selection = _draw_relics(3)
	for relic in current_draft_selection:
		var ped: RelicPedestalView = pedestal_scene.instantiate()
		_pedestal_row.add_child(ped)
		ped.use_battle_layout()
		ped.bind_relic(relic, "BIND TO %d O'CLOCK" % turn_number)
		ped.previewed.connect(_preview_allocation)
		ped.preview_ended.connect(_refresh_guidance)
		ped.selected.connect(_on_phase_one_relic_chosen)
	_choice_overlay.present(self)


func _on_phase_one_relic_chosen(chosen: ClockRelicData) -> void:
	if _resolving or _combat_over or not current_draft_selection.has(chosen):
		return
	_resolving = true
	var target_hour := turn_number
	_guidance.clear()
	await _animate_placement(chosen,target_hour)
	_clear_pedestals()

	# 1. Socket Relic into Player Chronometer
	player_sockets[target_hour - 1].slotted_relic = chosen
	_player_chrono.bind_sockets(player_sockets)

	# 2. Return unchosen relics to deck & shuffle
	for relic in current_draft_selection:
		if relic != chosen:
			player_deck.append(relic)
	current_draft_selection.clear()
	player_deck.shuffle()

	# 3. Snap hands to Hour N & Resolve clash
	_player_chrono.snap_hand_to_hour(target_hour)
	await _enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(target_hour, _active_enemy()))
	await _resolve_tick(target_hour)

	if _check_combat_end():
		return

	if turn_number < 12:
		turn_number += 1
		_prompt_phase_one_draft()
	else:
		_transition_to_phase_two()


# -------------------------------------------------------------
# PHASE 2: QUADRANT ENGINE (Turns 13+)
# -------------------------------------------------------------
func _transition_to_phase_two() -> void:
	phase = Phase.QUADRANT
	turn_number = 13
	active_quadrant = 1
	_show_turn_banner("QUADRANT ENGINE ENGAGED")
	AmbientMotion.punch_scale(_nexus_sigil, 1.18, 0.5)
	CombatVFX.play_shield_pulse(self, _nexus_sigil.global_position + _nexus_sigil.size * 0.5)
	await get_tree().create_timer(0.4).timeout
	_prompt_phase_two_turn()


func _prompt_phase_two_turn() -> void:
	if _combat_over:
		return

	_resolving = false
	OKRunState.start_new_turn()
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "QUADRANT %s  /  HOURS %02d–%02d     ·     Select a lit socket to replace its relic, or sweep" % [str(active_quadrant), hours[0], hours[2]]

	_player_chrono.highlight_quadrant(active_quadrant, Color("#EF9F27"))
	var enemy_q := 5 - active_quadrant if _enemy_chrono.rotation_direction < 0 else active_quadrant
	_enemy_chrono.highlight_quadrant(enemy_q, Color("#E74C3C"))
	_player_chrono.set_interactive_quadrant(active_quadrant, true)

	_clear_pedestals()

	# Draw 1 relic for hot-swap
	var drawn := _draw_relics(1)
	current_drawn_relic = drawn[0] if not drawn.is_empty() else null

	if current_drawn_relic != null:
		var ped: RelicPedestalView = pedestal_scene.instantiate()
		_pedestal_row.add_child(ped)
		ped.use_battle_layout()
		ped.bind_relic(current_drawn_relic, "DRAWN RELIC")
		_choice_overlay._style_button(ped._slot_button)
		ped._slot_button.disabled = true
	else:
		_phase_label.text = "QUADRANT %d  /  HOURS %02d–%02d     ·     All relics are bound. Sweep to activate this wedge." % [active_quadrant, hours[0], hours[2]]

	_skip_button.show()
	_skip_button.text = "KEEP & SWEEP  %d → %d → %d" % hours
	_choice_overlay.present(self)
	_refresh_guidance()


func _on_player_socket_pressed(hour_index: int, socket_view: ClockSocketView) -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT or current_drawn_relic == null:
		return

	var q_hours := ChronometerView.get_quadrant_hours(active_quadrant)
	if not q_hours.has(hour_index):
		return

	var socket_data: ClockSocketData = player_sockets[hour_index - 1]
	if socket_data.is_locked:
		return
	_resolving = true
	_guidance.clear()
	await _animate_placement(current_drawn_relic,hour_index)
	AudioManager.play_clock_sound("slot")

	# Hot-swap: displace old relic to discard, slot new relic
	if socket_data.slotted_relic != null:
		player_discard.append(socket_data.slotted_relic)
	socket_data.slotted_relic = current_drawn_relic
	current_drawn_relic = null

	_player_chrono.bind_sockets(player_sockets)
	_clear_pedestals()
	_skip_button.hide()
	_player_chrono.set_interactive_quadrant(active_quadrant, false)

	await _execute_quadrant_sweep(active_quadrant)


func _on_skip_button_pressed() -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT:
		return
	_resolving = true
	_guidance.clear()

	if current_drawn_relic != null:
		player_discard.append(current_drawn_relic)
		current_drawn_relic = null

	_clear_pedestals()
	_skip_button.hide()
	_player_chrono.set_interactive_quadrant(active_quadrant, false)

	await _execute_quadrant_sweep(active_quadrant)


func _execute_quadrant_sweep(quadrant: int) -> void:
	var hours := ChronometerView.get_quadrant_hours(quadrant)

	for h in hours:
		_player_chrono.snap_hand_to_hour(h)
		await _enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(h, _active_enemy()))
		await _resolve_tick(h)

		if _check_combat_end():
			return

	active_quadrant = (active_quadrant % 4) + 1
	turn_number += 1
	_prompt_phase_two_turn()


# -------------------------------------------------------------
# TICK CLASH RESOLUTION PIPELINE
# -------------------------------------------------------------
func _resolve_tick(hour: int) -> void:
	var starting_enemy := _enemy_index
	var enemy_hour := EnemyClockPattern.hour_for(hour, _active_enemy())
	AudioManager.play_clock_sound("tick")
	_show_turn_banner("YOUR HOUR %d  ·  ENEMY HOUR %d" % [hour, enemy_hour])
	_phase_label.text = "RESOLVING  /  YOUR HOUR %d  •  ENEMY HOUR %d\nRelics activate, then the clocks advance." % [hour,enemy_hour]
	var p_socket: ClockSocketData = player_sockets[hour - 1]
	var e_socket: ClockSocketData = enemy_sockets[enemy_hour - 1]

	# Flash resolving hour sockets
	var p_view := _player_chrono.get_socket_view(hour)
	var e_view := _enemy_chrono.get_socket_view(enemy_hour)
	if p_view: p_view.play_tick_resolution_flash()
	if e_view: e_view.play_tick_resolution_flash()
	if p_view and p_socket.slotted_relic:
		Presentation.relay(self, p_view, _player_portrait, ClockRelicData.role_to_color(p_socket.slotted_relic.role))
	if e_view:
		Presentation.relay(self, e_view, _enemy_portrait, Color("e99778"))
	await get_tree().create_timer(0.22 / AudioManager.animation_speed_scale()).timeout

	# 1. Resolve Bleed (true unblockable damage at start of tick)
	if player_bleed > 0:
		player_hp -= player_bleed
		_spawn_damage_number(_player_portrait, player_bleed, false, Color("#E58CFF"))
	if enemy_bleed > 0:
		enemy_hp -= enemy_bleed
		_spawn_damage_number(_enemy_portrait, enemy_bleed, false, Color("#E58CFF"))
	_update_stats_display()
	if _check_combat_end() or starting_enemy != _enemy_index: return

	# 2. Resolve Shields & Buffs
	if p_socket.slotted_relic != null:
		var relic := p_socket.slotted_relic
		if relic.base_block > 0:
			player_block += relic.base_block
			CombatVFX.play_shield_pulse(self, _player_portrait.global_position + _player_portrait.size * 0.5)
		if relic.apply_strength > 0:
			player_strength += relic.apply_strength
		if relic.apply_thorns > 0:
			player_thorns += relic.apply_thorns
		if relic.apply_vulnerable > 0:
			enemy_vulnerable += relic.apply_vulnerable
		if relic.apply_weak > 0:
			enemy_weak += relic.apply_weak
		if relic.apply_bleed > 0:
			enemy_bleed += relic.apply_bleed
		if relic.bonus_damage_next_hit > 0:
			player_next_hit_bonus += relic.bonus_damage_next_hit

	if e_socket.intent_block > 0:
		enemy_block += e_socket.intent_block
	if e_socket.intent_strength > 0:
		enemy_strength += e_socket.intent_strength
	player_bleed += e_socket.intent_bleed
	player_weak += e_socket.intent_weak
	player_vulnerable += e_socket.intent_vulnerable

	_update_stats_display()

	# 3. Resolve Attacks
	# Player Attacks Enemy
	if p_socket.slotted_relic != null and p_socket.slotted_relic.base_damage > 0:
		var relic := p_socket.slotted_relic
		var dmg := relic.base_damage + player_strength + player_next_hit_bonus
		player_next_hit_bonus = 0

		# Execution Wedge condition
		if relic.conditional_hp_threshold_pct > 0.0 and float(enemy_hp) / float(enemy_max_hp) <= relic.conditional_hp_threshold_pct:
			dmg = relic.conditional_damage + player_strength

		if enemy_vulnerable > 0:
			dmg = int(floor(dmg * 1.5))
		if player_weak > 0:
			dmg = int(floor(dmg * 0.75))
		dmg = int(floor(dmg * p_socket.multiplier))

		for hit in relic.hits:
			await _apply_damage_to_enemy(dmg, p_socket)
			if _check_combat_end() or starting_enemy != _enemy_index: return

	# Enemy Attacks Player
	if e_socket.intent_damage > 0 and enemy_hp > 0:
		var e_dmg := e_socket.intent_damage + enemy_strength
		if player_vulnerable > 0:
			e_dmg = int(floor(e_dmg * 1.5))
		if enemy_weak > 0:
			e_dmg = int(floor(e_dmg * 0.75))

		for hit in e_socket.intent_hits:
			await _apply_damage_to_player(e_dmg, e_socket)
			if _check_combat_end() or starting_enemy != _enemy_index: return
	# The second hand resolves its opposite socket at each wedge end.
	if EnemyClockPattern.has_twin(_active_enemy()) and hour % 3 == 0:
		var opposite := ((enemy_hour + 5) % 12) + 1
		var echo: ClockSocketData = enemy_sockets[opposite - 1]
		_enemy_chrono.get_socket_view(opposite).play_tick_resolution_flash()
		_phase_label.text = "SECOND HAND  /  HOUR %02d" % opposite
		if echo.intent_damage > 0:
			var echo_damage := echo.intent_damage + enemy_strength
			if player_vulnerable > 0: echo_damage = int(echo_damage * 1.5)
			if enemy_weak > 0: echo_damage = int(echo_damage * 0.75)
			await _apply_damage_to_player(echo_damage, echo)
			enemy_block += echo.intent_block
			if _check_combat_end() or starting_enemy != _enemy_index: return

	# 4. Status Decay
	if player_vulnerable > 0: player_vulnerable -= 1
	if player_weak > 0: player_weak -= 1
	if enemy_vulnerable > 0: enemy_vulnerable -= 1
	if enemy_weak > 0: enemy_weak -= 1

	_update_stats_display()
	await get_tree().create_timer(0.25).timeout


func _apply_damage_to_enemy(amount: int, p_socket: ClockSocketData) -> void:
	_stage.attack(true)
	if not _stage is DirectedArena: Presentation.relay(self, _player_portrait, _enemy_portrait, Color("7bd6de"))
	await get_tree().create_timer((_stage.impact_delay() if _stage.has_method("impact_delay") else 0.16) / AudioManager.animation_speed_scale()).timeout
	AudioManager.play_clock_sound("impact")
	_stage.impact(false, enemy_block >= amount)
	var nexus_pos: Vector2 = _stage.impact_position(false) if _stage is DirectedArena else _enemy_portrait.global_position + _enemy_portrait.size * 0.5
	CombatVFX.play_slash(self, nexus_pos, randf_range(-40, 40), Color(0.8, 1.4, 1.8))
	CombatVFX.play_hit_sparks(self, nexus_pos, Color(1.0, 0.9, 0.5), 6)
	AmbientMotion.flash(_enemy_portrait, Color(2.0, 0.8, 0.8), 0.15)

	# Hazard modifier check (recoil)
	if p_socket.is_hazard:
		var recoil := int(floor(amount * 0.5))
		player_hp -= recoil
		_spawn_damage_number(_player_portrait, recoil, false, Color("#E24B4A"))

	if enemy_block >= amount:
		enemy_block -= amount
		_spawn_damage_number(_enemy_portrait, amount, false, Color("#5DADE2"))
	else:
		var unblocked := amount - enemy_block
		var blocked_part := enemy_block
		enemy_block = 0
		if blocked_part > 0:
			_spawn_damage_number(_enemy_portrait, blocked_part, false, Color("#5DADE2"))

		if enemy_hp <= unblocked:
			# OVERKILL!
			var overkill := unblocked - enemy_hp
			enemy_hp = 0
			if p_socket.slotted_relic != null and p_socket.slotted_relic.recoil_block_on_overkill:
				player_block += overkill
			_handle_overkill(overkill)
		else:
			enemy_hp -= unblocked
			_spawn_damage_number(_enemy_portrait, unblocked, false, Color("#E24B4A"))

	# Thorns check
	if enemy_thorns > 0:
		player_hp -= enemy_thorns
		_spawn_damage_number(_player_portrait, enemy_thorns, false, Color("#F39C12"))

	_update_stats_display()
	await get_tree().create_timer((_stage.recovery_delay() if _stage.has_method("recovery_delay") else 0.24) / AudioManager.animation_speed_scale()).timeout


func _apply_damage_to_player(amount: int, e_socket: ClockSocketData) -> void:
	_stage.attack(false)
	if not _stage is DirectedArena: Presentation.relay(self, _enemy_portrait, _player_portrait, Color("e99778"))
	await get_tree().create_timer((_stage.impact_delay() if _stage.has_method("impact_delay") else 0.16) / AudioManager.animation_speed_scale()).timeout
	AudioManager.play_clock_sound("impact")
	_stage.impact(true, player_block >= amount)
	var p_pos: Vector2 = _stage.impact_position(true) if _stage is DirectedArena else _player_portrait.global_position + _player_portrait.size * 0.5
	CombatVFX.play_slash(self, p_pos, randf_range(30, 60), Color(2.0, 0.4, 0.4), 1.2)
	CombatVFX.play_hit_sparks(self, p_pos, Color(2.0, 0.6, 0.6), 5)
	AmbientMotion.flash(_player_portrait, Color(1.8, 0.5, 0.5), 0.15)
	if not _stage is DirectedArena: AmbientMotion.shake(self, 6.0, 0.2)

	if player_block >= amount:
		player_block -= amount
		_spawn_damage_number(_player_portrait, amount, false, Color("#5DADE2"))
	else:
		var unblocked := amount - player_block
		var blocked_part := player_block
		player_block = 0
		if blocked_part > 0:
			_spawn_damage_number(_player_portrait, blocked_part, false, Color("#5DADE2"))

		player_hp -= unblocked
		_spawn_damage_number(_player_portrait, unblocked, false, Color("#E24B4A"))

		# Siphon modifier check
		if e_socket.is_siphon and OKRunState.current_ok > 0:
			var drained := int(floor(OKRunState.current_ok * 0.25))
			OKRunState.current_ok = max(0, OKRunState.current_ok - drained)

	# Thorns check
	if player_thorns > 0:
		enemy_hp -= player_thorns
		_spawn_damage_number(_enemy_portrait, player_thorns, false, Color("#F39C12"))

	_update_stats_display()
	await get_tree().create_timer((_stage.recovery_delay() if _stage.has_method("recovery_delay") else 0.24) / AudioManager.animation_speed_scale()).timeout


func _handle_overkill(overkill: int) -> void:
	_spawn_damage_number(_enemy_portrait, overkill, true, Color("#EF9F27"))
	OKRunState.record_kill(overkill, "combat:chronometer")
	for passive in RunManager.relics_held:
		if passive.trigger != RelicData.Trigger.ON_OVERKILL or overkill < int(passive.condition_data.get("min_ok", 1)): continue
		for effect in passive.effects:
			if effect.effect_type == EffectData.EffectType.BLOCK:
				player_block += effect.value
			elif effect.effect_type == EffectData.EffectType.GAIN_OK:
				OKRunState.gain_ok(effect.value, passive.id)
	TutorialCallout.trigger("first_ok")

	var enemy_pos := _enemy_portrait.global_position + _enemy_portrait.size * 0.5
	CombatVFX.play_overkill_burst(self, enemy_pos, overkill)

	var hud_ok_pos := Vector2(size.x * 0.5, 45.0)
	CombatVFX.play_ok_essence_trail(self, enemy_pos, hud_ok_pos, clampi(int(overkill * 0.5), 3, 8))

	if overkill >= 5:
		AmbientMotion.shake(self, clampf(overkill * 0.4, 6.0, 20.0), 0.35)


func _check_combat_end() -> bool:
	if _combat_over:
		return true

	if enemy_hp <= 0 and player_hp > 0:
		if _enemy_index + 1 < enemies_data.size() and player_hp > 0:
			_enemy_index += 1
			var incoming := _active_enemy()
			enemy_max_hp = incoming.max_hp
			enemy_hp = enemy_max_hp
			enemy_block = 0
			enemy_strength = 0
			enemy_bleed = 0
			enemy_vulnerable = 0
			enemy_weak = 0
			enemy_thorns = 0
			enemy_sockets = EnemyClockPattern.create(incoming)
			_enemy_chrono.bind_sockets(enemy_sockets)
			_enemy_chrono.get_node("TitleLabel").text = incoming.display_name.to_upper()
			_configure_enemy_clock()
			_show_turn_banner("REINFORCEMENTS")
			_update_stats_display()
			return false
		_combat_over = true
		_show_turn_banner("VICTORY")
		_finish_presentation(true)
		RunManager.sync_hp_from_combat(player_hp)
		get_tree().create_timer(_stage.finish_delay() if _stage.has_method("finish_delay") else 0.8).timeout.connect(func() -> void: combat_won.emit(enemies_data))
		return true

	if player_hp <= 0:
		_combat_over = true
		_show_turn_banner("DEFEAT")
		_finish_presentation(false)
		RunManager.sync_hp_from_combat(0)
		get_tree().create_timer(_stage.finish_delay() if _stage.has_method("finish_delay") else 0.8).timeout.connect(func() -> void: combat_lost.emit())
		return true

	return false


func _finish_presentation(won: bool) -> void:
	_stage.finish(won)
	_clear_pedestals()
	_skip_button.hide()
	_player_chrono.set_interactive_quadrant(active_quadrant, false)
	_phase_label.text = "ENEMY MECHANISM SHATTERED" if won else "YOUR MECHANISM FALLS SILENT"
	var fallen: Control = _enemy_portrait if won else _player_portrait
	var exit_tween := create_tween()
	exit_tween.tween_property(fallen, "modulate", Color(0.25, 0.25, 0.3, 0.0), 0.45)
	var fade := Presentation.create_fade(self)
	fade.color.a = 0.0
	var fade_tween := create_tween()
	fade_tween.tween_interval(1.15 if _stage is DirectedArena else 0.5)
	fade_tween.tween_property(fade, "color:a", 1.0, 0.28)


func _update_stats_display() -> void:
	_player_stats_label.text = "%d / %d HP   ·   %d GUARD\n%s" % [maxi(player_hp, 0), player_max_hp, player_block, _status_text(player_strength, player_bleed, player_thorns, player_weak, player_vulnerable)]
	_enemy_stats_label.text = "%d / %d HP   ·   %d GUARD\n%s" % [maxi(enemy_hp, 0), enemy_max_hp, enemy_block, _status_text(enemy_strength, enemy_bleed, enemy_thorns, enemy_weak, enemy_vulnerable)]
	_hud.bind_clock_state(player_hp, player_max_hp)
	for entry in [[_player_portrait, player_hp, player_max_hp], [_enemy_portrait, enemy_hp, enemy_max_hp]]:
		var bar: ProgressBar = entry[0].get_node("Vitality")
		bar.max_value = entry[2]
		bar.value = maxi(entry[1], 0)


func _status_text(strength: int, bleed: int, thorns: int, weak: int, vulnerable: int) -> String:
	var parts: PackedStringArray = []
	for pair in [[strength, "STR"], [bleed, "BLEED"], [thorns, "THORNS"], [weak, "WEAK"], [vulnerable, "VULN"]]:
		if pair[0] > 0:
			parts.append("%d %s" % [pair[0], pair[1]])
	return " · ".join(parts)


func _spawn_damage_number(target: Control, val: int, is_ok: bool, col: Color) -> void:
	if val <= 0: return
	var num: DamageNumber = damage_number_scene.instantiate()
	add_child(num)
	num.position = target.global_position + target.size * 0.5 + Vector2(randf_range(-20, 20), -20)
	if _stage is DirectedArena:
		num.position = _stage.impact_position(target == _player_portrait) - global_position + Vector2(randf_range(-15,15),-20)
	num.z_index = 55
	if is_ok: num.setup(val,true)
	else: num.setup_generic(val,col)

func _refresh_guidance() -> void:
	if _resolving or _combat_over: return
	if phase == Phase.ASSEMBLY:
		_phase_label.text = "CHOOSE FOR %d O'CLOCK\nChoose a relic for the pulsing slot. Both clocks then resolve this hour." % turn_number
		_guidance.point_to(_player_chrono,_player_chrono.get_socket_view(turn_number),[turn_number],"NEXT SLOT\n%d O'CLOCK" % turn_number)
	else:
		var hours := ChronometerView.get_quadrant_hours(active_quadrant)
		_phase_label.text = "HOURS %d → %d → %d\nReplace one of the three pulsing slots, or keep your clock and sweep." % hours
		_guidance.point_to(_player_chrono,null,hours,"NEXT SWEEP\n%d → %d → %d" % hours)

func _preview_allocation(view: RelicPedestalView) -> void:
	if _resolving or _combat_over or phase != Phase.ASSEMBLY: return
	_phase_label.text = "PREVIEW  /  %s → %d O'CLOCK\nBind this relic, then resolve your hour %d and enemy hour %d. No change until you click." % [view.relic.name,turn_number,turn_number,EnemyClockPattern.hour_for(turn_number,_active_enemy())]
	_guidance.point_to(_player_chrono,_player_chrono.get_socket_view(turn_number),[turn_number],"BIND HERE\n%d O'CLOCK" % turn_number,view._art_rect,view._art_rect.texture)

func _preview_swap(socket: ClockSocketView) -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT or not socket.is_interactive or current_drawn_relic == null: return
	var previous := socket.data.slotted_relic.name if socket.data.slotted_relic else "empty slot"
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "PREVIEW  /  %d O'CLOCK: %s → %s\nThe old relic goes to discard. Then hours %d → %d → %d activate in order." % [socket.data.hour_index,previous,current_drawn_relic.name,hours[0],hours[1],hours[2]]
	var ped: RelicPedestalView = _pedestal_row.get_child(0)
	_guidance.point_to(_player_chrono,socket,hours,"REPLACE\n%d O'CLOCK" % socket.data.hour_index,ped._art_rect,ped._art_rect.texture)

func _preview_sweep() -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT: return
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "PREVIEW  /  KEEP YOUR CLOCK\nDiscard the offered reserve. Activate hours %d → %d → %d with your current relics." % hours
	_guidance.point_to(_player_chrono,null,hours,"KEEP & SWEEP\n%d → %d → %d" % hours)

func _animate_placement(relic: ClockRelicData, hour: int) -> void:
	var origin: TextureRect
	for child in _pedestal_row.get_children():
		if child.relic == relic: origin = child._art_rect
	if origin == null: return
	var flight := TextureRect.new()
	flight.texture = origin.texture
	flight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flight.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flight.z_index = 45
	add_child(flight)
	flight.size = Vector2(82,82)
	flight.position = origin.global_position + origin.size*0.5 - global_position - flight.size*0.5
	_choice_overlay.hide()
	var socket := _player_chrono.get_socket_view(hour)
	var finish := socket.global_position + socket.size*0.5 - global_position - Vector2(28,28)
	_phase_label.text = "BINDING  /  %s → %d O'CLOCK\nThe relic will activate after it reaches the clock." % [relic.name,hour]
	var motion := create_tween().set_parallel(true)
	var duration := 0.12 if AudioManager.reduced_motion else 0.38 / AudioManager.animation_speed_scale()
	if AudioManager.reduced_motion: flight.position = finish
	motion.tween_property(flight,"position",finish,duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(flight,"size",Vector2(56,56),duration)
	await motion.finished
	flight.queue_free()
	AudioManager.play_clock_sound("slot")


func _show_turn_banner(text_content: String) -> void:
	_turn_banner.text = text_content
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	var tween := create_tween()
	_banner_tween = tween
	tween.tween_property(_turn_banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(0.6)
	tween.tween_property(_turn_banner, "modulate:a", 0.0, 0.25)


func _draw_relics(count: int) -> Array[ClockRelicData]:
	var result: Array[ClockRelicData] = []
	var parked: Array[ClockRelicData] = []
	var seen: Dictionary = {}
	var available := player_deck.size() + player_discard.size()
	for attempt in available:
		if result.size() >= count: break
		if player_deck.is_empty():
			player_deck = player_discard.duplicate()
			player_discard.clear()
			player_deck.shuffle()
		if player_deck.is_empty(): break
		var relic: ClockRelicData = player_deck.pop_back()
		if count > 1 and seen.has(relic.id):
			parked.append(relic)
		else:
			result.append(relic)
			seen[relic.id] = true
	while result.size() < count and not parked.is_empty(): result.append(parked.pop_back())
	player_deck.append_array(parked)
	return result

func _clear_pedestals() -> void:
	_choice_overlay.hide()
	for c in _pedestal_row.get_children():
		_pedestal_row.remove_child(c)
		c.queue_free()
