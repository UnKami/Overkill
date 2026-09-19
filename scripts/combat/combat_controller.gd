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
@onready var _pedestal_row: HBoxContainer = %PedestalRow
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
var player_next_attack_multiplier: int = 1

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
var _feedback_serial: int = 0
var _choice_overlay: PanelContainer
var _resolution_hour: int = 1
var _combat_history: Array[String] = []
var _history_button: Button
var _intent_readout: Label
var _intent_clock_label: Label
var _intent_panel: PanelContainer
var _guidance: BattleGuidance


var _pending_enemies: Array[EnemyData] = []
var _pending_background_id: String = ""
var _is_started: bool = false


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	Presentation.install(self)
	Presentation.directed_layout(self)
	_choice_overlay = preload("res://scripts/ui/relic_choice_overlay.gd").new()
	add_child(_choice_overlay)
	_choice_overlay.install(self)
	_intent_readout = Label.new()
	_intent_panel = PanelContainer.new()
	_intent_panel.name = "EnemyIntentPanel"
	_intent_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_panel.z_index = 29
	add_child(_intent_panel)
	_intent_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_intent_panel.offset_left = -350
	_intent_panel.offset_right = -20
	_intent_panel.offset_top = 86
	var intent_style: StyleBoxFlat = StyleBoxFlat.new()
	intent_style.bg_color = Color(0.035,0.045,0.055,0.94)
	intent_style.border_color = Color("8e6650")
	intent_style.border_width_left = 2
	intent_style.content_margin_left = 14
	intent_style.content_margin_right = 14
	intent_style.content_margin_top = 12
	intent_style.content_margin_bottom = 12
	_intent_panel.add_theme_stylebox_override("panel",intent_style)
	_intent_panel.add_child(_intent_readout)
	_intent_readout.custom_minimum_size.x = 302
	_intent_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intent_readout.add_theme_font_size_override("font_size",24)
	_intent_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intent_clock_label = Label.new()
	_enemy_chrono.add_child(_intent_clock_label)
	_intent_clock_label.position = Vector2(105,135)
	_intent_clock_label.size = Vector2(210,150)
	_intent_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_clock_label.add_theme_font_size_override("font_size",24)
	_intent_clock_label.add_theme_constant_override("outline_size",6)
	_intent_clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioManager.settings_changed.connect(_refresh_intent_text_size)
	_refresh_intent_text_size()
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
	_battle_info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_battle_info.offset_top = -28
	_battle_info.offset_bottom = 0
	_battle_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_battle_info.add_theme_font_size_override("font_size", 18)
	_battle_info.add_theme_color_override("font_color", Color("c4b899"))
	_battle_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_turn_banner.offset_left = -600
	_turn_banner.offset_right = 600
	_turn_banner.offset_top = -140
	_turn_banner.offset_bottom = -100
	_skip_button.pressed.connect(_on_skip_button_pressed)
	_skip_button.mouse_entered.connect(_preview_sweep)
	_skip_button.focus_entered.connect(_preview_sweep)
	_skip_button.mouse_exited.connect(_refresh_guidance)
	_skip_button.focus_exited.connect(_refresh_guidance)
	_history_button = Button.new()
	_history_button.text = "COMBAT LOG"
	_history_button.add_theme_font_size_override("font_size",22)
	add_child(_history_button)
	_history_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_history_button.offset_left = -440
	_history_button.offset_right = -240
	_history_button.offset_top = 10
	_history_button.offset_bottom = 54
	_history_button.pressed.connect(func() -> void:
		var history: AcceptDialog = AcceptDialog.new()
		history.title = "Recent combat · newest first"
		history.dialog_text = "No actions resolved yet." if _combat_history.is_empty() else "\n".join(_combat_history)
		history.theme = ScreenDesign.build_theme()
		add_child(history)
		history.confirmed.connect(history.queue_free)
		history.canceled.connect(history.queue_free)
		history.popup_centered(Vector2i(850,650)))
	var help := Button.new()
	help.text = "HOW TO PLAY"
	help.add_theme_font_size_override("font_size", 16)
	add_child(help)
	help.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	help.offset_left = -230
	help.offset_right = -30
	help.offset_top = 10
	help.offset_bottom = 54
	help.pressed.connect(func() -> void:
		var guide := AcceptDialog.new()
		guide.title = "Your clock, one decision at a time"
		guide.dialog_text = "1. BUILD YOUR CLOCK\nChoose one of three relics. The first goes to 1 o'clock, then 2, up to 9.\nAfter each placement, your relic and the enemy's matching tick resolve.\nHover a relic to see its destination before committing.\n\n2. SWEEP YOUR CLOCK\nEach turn covers three hours: 1–3, 4–6, then 7–9.\nHover a glowing socket to preview replacing it with the offered reserve.\nClick the socket to replace AND resolve the three-hour sweep.\nKEEP & SWEEP discards the offered reserve and activates your current relics.\n\nThe enemy may rotate backward or use a second hand. Read its lit intents.\n\nKEYWORDS\nBlock persists until absorbed or battle ends.\nStrength: extra damage per hit. Thorns: return damage when attacked.\nBleed: lose HP at tick start. Weak: deal 25% less attack damage.\nVulnerable: take 50% more attack damage.\nLifesteal heals actual HP damage dealt, up to missing HP.\nOverdrive empowers your next attacking relic, including every hit."
		var help_text: RichTextLabel = RichTextLabel.new()
		help_text.text = guide.dialog_text
		guide.dialog_text = ""
		help_text.custom_minimum_size = Vector2(900,450)
		help_text.add_theme_font_size_override("normal_font_size",24)
		guide.add_child(help_text)
		guide.theme = ScreenDesign.build_theme()
		add_child(guide)
		guide.confirmed.connect(guide.queue_free)
		guide.canceled.connect(guide.queue_free)
		guide.popup_centered(Vector2i(1000,580)))
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
	_choice_overlay.visibility_changed.connect(func() -> void:
		if is_instance_valid(_stage) and _stage is DirectedArena:
			_stage.set_decision_view(_choice_overlay.visible))
	_stage.set_decision_view(_choice_overlay.visible)


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
	player_next_hit_bonus = 0
	player_next_attack_multiplier = 1

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
	for hour in range(1,10):
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

	# 9 empty player sockets
	for h in range(1, 10):
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
# PHASE 1: ASSEMBLY CYCLE (Turns 1 - 9)
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
	_reveal_enemy_hour(EnemyClockPattern.hour_for(turn_number, _active_enemy()))
	if EnemyClockPattern.has_twin(_active_enemy()) and turn_number % 3 == 0:
		_reveal_enemy_hour(((EnemyClockPattern.hour_for(turn_number, _active_enemy()) + 3) % 9) + 1)
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

	if turn_number < 9:
		turn_number += 1
		_prompt_phase_one_draft()
	else:
		_transition_to_phase_two()


# -------------------------------------------------------------
# PHASE 2: QUADRANT ENGINE (Turns 10+)
# -------------------------------------------------------------
func _transition_to_phase_two() -> void:
	phase = Phase.QUADRANT
	turn_number = 10
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
	_phase_label.text = "SECTOR %s  /  HOURS %02d–%02d     ·     Select a lit socket to replace its relic, or sweep" % [str(active_quadrant), hours[0], hours[2]]

	_player_chrono.highlight_quadrant(active_quadrant, Color("#EF9F27"))
	for upcoming_hour: int in hours:
		_reveal_enemy_hour(EnemyClockPattern.hour_for(upcoming_hour, _active_enemy()))
	if EnemyClockPattern.has_twin(_active_enemy()):
		_reveal_enemy_hour(((EnemyClockPattern.hour_for(hours[2], _active_enemy()) + 3) % 9) + 1)
	var enemy_q := 4 - active_quadrant if _enemy_chrono.rotation_direction < 0 else active_quadrant
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
		_phase_label.text = "SECTOR %d  /  HOURS %02d–%02d     ·     All relics are bound. Sweep to activate this wedge." % [active_quadrant, hours[0], hours[2]]

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

	active_quadrant = (active_quadrant % 3) + 1
	turn_number += 1
	_prompt_phase_two_turn()


# -------------------------------------------------------------
# TICK CLASH RESOLUTION PIPELINE
# -------------------------------------------------------------
func _resolve_tick(hour: int) -> void:
	_resolution_hour = hour
	var starting_enemy := _enemy_index
	var enemy_hour := EnemyClockPattern.hour_for(hour, _active_enemy())
	_reveal_enemy_hour(enemy_hour)
	AudioManager.play_clock_sound("tick")
	_show_turn_banner("YOUR HOUR %d  ·  ENEMY HOUR %d" % [hour, enemy_hour])
	_phase_label.text = "RESOLVING  /  YOUR HOUR %d  •  ENEMY HOUR %d\nRelics activate, then the clocks advance." % [hour,enemy_hour]
	var p_socket: ClockSocketData = player_sockets[hour - 1]
	var e_socket: ClockSocketData = enemy_sockets[enemy_hour - 1]
	if p_socket.slotted_relic != null:
		_show_turn_banner("%s  ·  HOUR %d" % [p_socket.slotted_relic.name.to_upper(), hour])

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
		_spawn_damage_number(_player_portrait, player_bleed, false, Color("#E58CFF"), "BLEED")
	if enemy_bleed > 0:
		enemy_hp -= enemy_bleed
		_spawn_damage_number(_enemy_portrait, enemy_bleed, false, Color("#E58CFF"), "BLEED")
	_update_stats_display()
	if _check_combat_end() or starting_enemy != _enemy_index: return

	# 2. Resolve Shields & Buffs
	if p_socket.slotted_relic != null:
		var relic := p_socket.slotted_relic
		if relic.base_block > 0:
			player_block += relic.base_block
			_spawn_damage_number(_player_portrait, relic.base_block, false, Color("7bd6de"), "BLOCK")
			if _stage is DirectedArena: _stage.guard_pulse(true)
			else: CombatVFX.play_shield_pulse(self, _player_portrait.global_position + _player_portrait.size * 0.5)
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
		_spawn_damage_number(_enemy_portrait, e_socket.intent_block, false, Color("7bd6de"), "BLOCK")
		if _stage is DirectedArena: _stage.guard_pulse(false)
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
		dmg = int(floor(dmg * p_socket.multiplier)) * player_next_attack_multiplier
		player_next_attack_multiplier = maxi(1, relic.next_attack_multiplier)

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
	# The second hand resolves its secondary socket at each wedge end.
	if EnemyClockPattern.has_twin(_active_enemy()) and hour % 3 == 0:
		var opposite := ((enemy_hour + 3) % 9) + 1
		_reveal_enemy_hour(opposite)
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
	var swing_wait: float = _stage.swing_delay(true) if _stage.has_method("swing_delay") else 0.0
	if swing_wait > 0.0: await get_tree().create_timer(swing_wait / AudioManager.animation_speed_scale()).timeout
	AudioManager.play_combat_sound("swing")
	if not _stage is DirectedArena: Presentation.relay(self, _player_portrait, _enemy_portrait, Color("7bd6de"))
	if _stage.has_method("await_contact"): await _stage.await_contact(true)
	else: await get_tree().create_timer(0.16 / AudioManager.animation_speed_scale()).timeout
	AudioManager.play_combat_sound("guard" if enemy_block >= amount else ("shatter" if enemy_block > 0 else "strike"))
	_stage.impact(false, enemy_block >= amount)
	var nexus_pos: Vector2 = _stage.impact_position(false) if _stage is DirectedArena else _enemy_portrait.global_position + _enemy_portrait.size * 0.5
	if not _stage is DirectedArena:
		CombatVFX.play_slash(self, nexus_pos, randf_range(-40, 40), Color(0.8, 1.4, 1.8))
		CombatVFX.play_hit_sparks(self, nexus_pos, Color(1.0, 0.9, 0.5), 6)
	AmbientMotion.flash(_enemy_portrait, Color(2.0, 0.8, 0.8), 0.15)

	# Hazard modifier check (recoil)
	if p_socket.is_hazard:
		var recoil := int(floor(amount * 0.5))
		player_hp -= recoil
		_spawn_damage_number(_player_portrait, recoil, false, Color("#E24B4A"), "RECOIL")

	var hp_damage: int = mini(maxi(enemy_hp, 0), maxi(amount - enemy_block, 0))
	if enemy_block >= amount:
		enemy_block -= amount
		_spawn_damage_number(_enemy_portrait, amount, false, Color("#5DADE2"), "BLOCKED")
	else:
		var unblocked := amount - enemy_block
		var blocked_part := enemy_block
		enemy_block = 0
		if blocked_part > 0:
			_spawn_damage_number(_enemy_portrait, blocked_part, false, Color("#5DADE2"), "BLOCKED")

		if enemy_hp <= unblocked:
			# OVERKILL!
			var overkill := unblocked - enemy_hp
			_spawn_damage_number(_enemy_portrait, hp_damage, false, Color("#E24B4A"))
			enemy_hp = 0
			if p_socket.slotted_relic != null and p_socket.slotted_relic.recoil_block_on_overkill:
				player_block += overkill
			_handle_overkill(overkill)
		else:
			enemy_hp -= unblocked
			_spawn_damage_number(_enemy_portrait, unblocked, false, Color("#E24B4A"))

	if p_socket.slotted_relic != null and p_socket.slotted_relic.lifesteal and player_hp > 0:
		var healed: int = mini(hp_damage, maxi(player_max_hp - player_hp, 0))
		player_hp += healed
		if healed > 0:
			AudioManager.play_combat_sound("heal")
			_spawn_damage_number(_player_portrait, healed, false, Color("7ce0ac"), "HEAL")
	# Thorns check
	if enemy_thorns > 0:
		player_hp -= enemy_thorns
		_spawn_damage_number(_player_portrait, enemy_thorns, false, Color("#F39C12"), "THORNS")

	_update_stats_display()
	await get_tree().create_timer((_stage.recovery_delay() if _stage.has_method("recovery_delay") else 0.24) / AudioManager.animation_speed_scale()).timeout


func _apply_damage_to_player(amount: int, e_socket: ClockSocketData) -> void:
	_stage.attack(false)
	var swing_wait: float = _stage.swing_delay(false) if _stage.has_method("swing_delay") else 0.0
	if swing_wait > 0.0: await get_tree().create_timer(swing_wait / AudioManager.animation_speed_scale()).timeout
	AudioManager.play_combat_sound("swing")
	if not _stage is DirectedArena: Presentation.relay(self, _enemy_portrait, _player_portrait, Color("e99778"))
	if _stage.has_method("await_contact"): await _stage.await_contact(false)
	else: await get_tree().create_timer(0.16 / AudioManager.animation_speed_scale()).timeout
	AudioManager.play_combat_sound("guard" if player_block >= amount else ("shatter" if player_block > 0 else "strike"))
	_stage.impact(true, player_block >= amount)
	var p_pos: Vector2 = _stage.impact_position(true) if _stage is DirectedArena else _player_portrait.global_position + _player_portrait.size * 0.5
	if not _stage is DirectedArena:
		CombatVFX.play_slash(self, p_pos, randf_range(30, 60), Color(2.0, 0.4, 0.4), 1.2)
		CombatVFX.play_hit_sparks(self, p_pos, Color(2.0, 0.6, 0.6), 5)
	AmbientMotion.flash(_player_portrait, Color(1.8, 0.5, 0.5), 0.15)
	if not _stage is DirectedArena: AmbientMotion.shake(self, 6.0, 0.2)

	if player_block >= amount:
		player_block -= amount
		_spawn_damage_number(_player_portrait, amount, false, Color("#5DADE2"), "BLOCKED")
	else:
		var unblocked := amount - player_block
		var blocked_part := player_block
		player_block = 0
		if blocked_part > 0:
			_spawn_damage_number(_player_portrait, blocked_part, false, Color("#5DADE2"), "BLOCKED")

		player_hp -= unblocked
		_spawn_damage_number(_player_portrait, unblocked, false, Color("#E24B4A"))

		# Siphon modifier check
		if e_socket.is_siphon and OKRunState.current_ok > 0:
			var drained := int(floor(OKRunState.current_ok * 0.25))
			OKRunState.current_ok = max(0, OKRunState.current_ok - drained)

	# Thorns check
	if player_thorns > 0:
		enemy_hp -= player_thorns
		_spawn_damage_number(_enemy_portrait, player_thorns, false, Color("#F39C12"), "THORNS")

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

	var enemy_pos: Vector2 = _stage.impact_position(false) if _stage is DirectedArena else _enemy_portrait.global_position + _enemy_portrait.size * 0.5
	CombatVFX.play_overkill_burst(self, enemy_pos, overkill)

	var hud_ok_pos := Vector2(size.x * 0.5, 45.0)
	CombatVFX.play_ok_essence_trail(self, enemy_pos, hud_ok_pos, clampi(int(overkill * 0.5), 3, 8))

	if overkill >= 5 and not _stage is DirectedArena:
		AmbientMotion.shake(self, clampf(overkill * 0.4, 6.0, 12.0), 0.25)


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
	AudioManager.play_combat_sound("victory" if won else "defeat")
	_stage.finish(won)
	_guidance.clear()
	for clock: ChronometerView in [_player_chrono,_enemy_chrono]:
		clock.clear_quadrant_highlights()
		clock.mark_hour(0)
		clock.set_interactive_quadrant(active_quadrant,false)
	_refresh_intent_readout()
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
	_player_stats_label.text = "%d / %d HP   ·   %d BLOCK\n%s" % [maxi(player_hp, 0), player_max_hp, player_block, _status_text(player_strength, player_bleed, player_thorns, player_weak, player_vulnerable)]
	if player_next_attack_multiplier > 1:
		_player_stats_label.text += "  ·  NEXT ATTACK ×%d" % player_next_attack_multiplier
	_enemy_stats_label.text = "%d / %d HP   ·   %d BLOCK\n%s" % [maxi(enemy_hp, 0), enemy_max_hp, enemy_block, _status_text(enemy_strength, enemy_bleed, enemy_thorns, enemy_weak, enemy_vulnerable)]
	_hud.bind_clock_state(player_hp, player_max_hp)
	for entry in [[_player_portrait, player_hp, player_max_hp], [_enemy_portrait, enemy_hp, enemy_max_hp]]:
		var bar: ProgressBar = _player_chrono.get_node("Vitality") if entry[0] == _player_portrait else _enemy_chrono.get_node("Vitality")
		bar.max_value = entry[2]
		bar.value = maxi(entry[1], 0)


func _status_text(strength: int, bleed: int, thorns: int, weak: int, vulnerable: int) -> String:
	var parts: PackedStringArray = []
	for pair in [[strength, "STRENGTH"], [bleed, "BLEED"], [thorns, "THORNS"], [weak, "WEAK"], [vulnerable, "VULNERABLE"]]:
		if pair[0] > 0:
			parts.append("%d %s" % [pair[0], pair[1]])
	return " · ".join(parts)


func _spawn_damage_number(target: Control, val: int, is_ok: bool, col: Color, kind: String = "HP") -> void:
	if val <= 0: return
	_combat_history.push_front("Hour %d · %s · %s %d" % [_resolution_hour,"You" if target == _player_portrait or is_ok else "Enemy","Overkill gained" if is_ok else kind,val])
	if _combat_history.size() > 16: _combat_history.pop_back()
	var num: DamageNumber = damage_number_scene.instantiate()
	add_child(num)
	num.position = target.global_position + target.size * 0.5 + Vector2(randf_range(-20, 20), -20)
	if _stage is DirectedArena:
		num.position = _stage.impact_position(target == _player_portrait) - global_position + Vector2(randf_range(-15,15),-20)
	num.position += Vector2(-70, -float(_feedback_serial % 3) * 30.0)
	_feedback_serial += 1
	num.set_meta("feedback_kind", kind)
	num.z_index = 55
	if is_ok: num.setup(val,true)
	else:
		var prefix: String = "+" if kind in ["BLOCK", "HEAL"] else ("" if kind == "BLOCKED" else "−")
		num.setup_generic(val, col, prefix, kind)

func _refresh_guidance() -> void:
	_refresh_intent_readout()
	if _resolving or _combat_over: return
	if phase == Phase.ASSEMBLY:
		_player_chrono.snap_hand_to_hour(turn_number,0.18)
		_enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(turn_number,_active_enemy()),0.18)
		_phase_label.text = "Choose one relic for hour %d. Unchosen relics return to the draw pile." % turn_number
		_guidance.point_to(_player_chrono,_player_chrono.get_socket_view(turn_number),[turn_number],"NEXT SLOT\n%d O'CLOCK" % turn_number)
	else:
		var hours := ChronometerView.get_quadrant_hours(active_quadrant)
		_player_chrono.snap_hand_to_hour(hours[0],0.18)
		_enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(hours[0],_active_enemy()),0.18)
		_phase_label.text = "Replace one pulsing slot, then activate hours %d → %d → %d. Keep & Sweep discards the drawn relic." % hours
		if current_drawn_relic == null: _phase_label.text = "No reserve relic available. Sweep hours %d → %d → %d with your equipped relics." % hours
		_guidance.point_to(_player_chrono,null,hours,"NEXT SWEEP\n%d → %d → %d" % hours)

func _refresh_intent_readout() -> void:
	_enemy_chrono.set_readout_clearance(true)
	if _combat_over:
		_intent_readout.text = "DEFEATED" if enemy_hp <= 0 else "BATTLE OVER"
		_intent_clock_label.text = _intent_readout.text
		_intent_panel.call_deferred("reset_size")
		return
	if enemy_sockets.is_empty(): return
	var hours: Array = [turn_number] if phase == Phase.ASSEMBLY else ChronometerView.get_quadrant_hours(active_quadrant)
	var lines: Array[String] = []
	var clock_hours: PackedStringArray = []
	var has_siphon: bool = false
	for hour: int in hours:
		var index: int = EnemyClockPattern.hour_for(hour,_active_enemy())
		clock_hours.append(str(index))
		var socket: ClockSocketData = enemy_sockets[index-1]
		has_siphon = has_siphon or (socket.intent_revealed and socket.is_siphon)
		var description: String = DecisionPreview.intent(socket).replace("On HP damage: drain 25% Overkill","Siphon").replace("Attack ","").replace(" base"," damage")
		lines.append("%d: %s" % [index,description])
	if EnemyClockPattern.has_twin(_active_enemy()) and int(hours.back()) % 3 == 0:
		var last_hour: int = EnemyClockPattern.hour_for(int(hours.back()),_active_enemy())
		var echo_index: int = (last_hour + 3) % 9
		var echo: ClockSocketData = enemy_sockets[echo_index]
		var echo_text: String = "No strike" if echo.intent_revealed and echo.intent_damage == 0 else DecisionPreview.intent(echo)
		lines.append("Second hand · %d: %s" % [echo_index+1,echo_text])
	_intent_clock_label.text = "ENEMY NEXT\n" + " → ".join(clock_hours)
	_intent_readout.text = "ENEMY NEXT\nBase damage shown\n" + "\n".join(lines)
	if has_siphon: _intent_readout.text += "\nSiphon: lose 25% Overkill on HP damage."
	_intent_panel.call_deferred("reset_size")

func _refresh_intent_text_size(_settings: Dictionary = {}) -> void:
	ScreenDesign.apply_text_size(_intent_panel)
	ScreenDesign.apply_text_size(_intent_clock_label)
	_intent_panel.call_deferred("reset_size")

func _preview_allocation(view: RelicPedestalView) -> void:
	if _resolving or _combat_over or phase != Phase.ASSEMBLY: return
	_phase_label.text = "%s → hour %d. Resolve your hour %d against enemy hour %d." % [view.relic.name,turn_number,turn_number,EnemyClockPattern.hour_for(turn_number,_active_enemy())]
	_phase_label.text += "\n" + DecisionPreview.forecast(self,[turn_number],turn_number,view.relic)
	_guidance.point_to(_player_chrono,_player_chrono.get_socket_view(turn_number),[turn_number],"BIND HERE\n%d O'CLOCK" % turn_number,view._art_rect,view._art_rect.texture)

func _preview_swap(socket: ClockSocketView) -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT or not socket.is_interactive or current_drawn_relic == null: return
	var previous := socket.data.slotted_relic.name if socket.data.slotted_relic else "empty slot"
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "Hour %d: %s → %s. Old relic is discarded; sweep %d → %d → %d." % [socket.data.hour_index,previous,current_drawn_relic.name,hours[0],hours[1],hours[2]]
	_phase_label.text += "\n" + DecisionPreview.forecast(self,hours,socket.data.hour_index,current_drawn_relic)
	var ped: RelicPedestalView = _pedestal_row.get_child(0)
	_guidance.point_to(_player_chrono,socket,hours,"REPLACE\n%d O'CLOCK" % socket.data.hour_index,ped._art_rect,ped._art_rect.texture)

func _preview_sweep() -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT: return
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "KEEP YOUR CLOCK · Discard the drawn relic and activate %d → %d → %d." % hours
	_phase_label.text += "\n" + DecisionPreview.forecast(self,hours)
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

func _reveal_enemy_hour(hour: int) -> void:
	if hour < 1 or hour > enemy_sockets.size(): return
	var socket: ClockSocketData = enemy_sockets[hour - 1]
	if socket.intent_revealed: return
	socket.intent_revealed = true
	var view: ClockSocketView = _enemy_chrono.get_socket_view(hour)
	view.bind_socket(socket, true)
	if not AudioManager.reduced_motion:
		view.modulate.a = 0.3
		view.create_tween().tween_property(view, "modulate:a", 1.0, 0.28)
