class_name CombatController extends Control
## CombatController - Orchestrates the Dual-Chronometer Battle Engine.
## Implements Phase 1 (Assembly Cycle) and Phase 2 (Quadrant Engine).
const TICK_STARTUP_DELAY: float = 0.09
const TICK_RECOVERY_DELAY: float = 0.12

signal combat_won(enemies_data: Array[EnemyData])
signal combat_lost
var _pending_lifesteal_visual: int = 0
var _twin_relic_motion: Node2D

enum Phase { ASSEMBLY, QUADRANT }
const Presentation := preload("res://scripts/combat/clock_battle_presentation.gd")
const ArtifactPresentation := preload("res://scripts/combat/artifact_presentation.gd")
const RelicMotion := preload("res://scripts/combat/relic_choreography.gd")

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
@onready var _relic_bar: HBoxContainer = %RelicBar

var phase: Phase = Phase.ASSEMBLY
var current_phase: Phase:
	get: return phase
	set(v): phase = v
var turn_number: int = 1
var active_quadrant: int = 1
var selected_assembly_hour: int = 1
var _swap_source_hour: int = 0

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
var _intent_clock_label: Label
var _guidance: BattleGuidance


var _pending_enemies: Array[EnemyData] = []
var _is_prepared: bool = false
var _phase_started: bool = false
var _pending_intro: bool = false
var _battle_intro: BattleIntroSequence
var _player_status_strip: HBoxContainer
var _enemy_status_strip: HBoxContainer
var _player_core_strip: HBoxContainer
var _enemy_core_strip: HBoxContainer
var _artifact_triggered_this_combat: Dictionary = {}


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_build_combatant_stat_ui()
	Presentation.install(self)
	Presentation.directed_layout(self)
	_choice_overlay = preload("res://scripts/ui/relic_choice_overlay.gd").new()
	add_child(_choice_overlay)
	_choice_overlay.install(self)
	# The phase name is the first thing players need to recognize before they
	# make a clock decision; make replacement distinct from ordinary binding.
	if is_instance_valid(_choice_overlay._heading):
		_choice_overlay._heading.add_theme_font_size_override("font_size", 28)
		_choice_overlay._heading.add_theme_font_override("font", ScreenDesign.display_font())
	_intent_clock_label = Label.new()
	_enemy_chrono.add_child(_intent_clock_label)
	_intent_clock_label.position = Vector2(105,135)
	_intent_clock_label.size = Vector2(210,150)
	_intent_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intent_clock_label.add_theme_font_size_override("font_size",22)
	_intent_clock_label.add_theme_constant_override("outline_size",6)
	_intent_clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioManager.settings_changed.connect(_refresh_intent_text_size)
	_refresh_intent_text_size()
	_guidance = BattleGuidance.new()
	add_child(_guidance)
	_guidance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# All encounters share the same supplied crystalline illustrated cast.
	# The retired 3D prototype used unrelated knight models and is intentionally
	# unavailable, including for bosses and command-line showcase flags.
	_stage = preload("res://scripts/combat/illustrated_stage.gd").new()
	_clash_nexus.add_child(_stage)
	_clash_nexus.move_child(_stage, 0)
	_stage.position = Vector2(-320, -235)
	_stage.size = Vector2(640, 510)
	_nexus_sigil.hide()
	_clash_nexus.get_node("NexusTitle").hide()
	_battle_info = Label.new()
	add_child(_battle_info)
	_battle_info.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_battle_info.offset_left = -500
	_battle_info.offset_right = 500
	_battle_info.offset_top = -62
	_battle_info.offset_bottom = -12
	_battle_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_battle_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_battle_info.add_theme_font_size_override("font_size", 20)
	_battle_info.add_theme_color_override("font_color", Color("e0cfaa"))
	_battle_info.add_theme_color_override("font_outline_color", Color("02070bd9"))
	_battle_info.add_theme_constant_override("outline_size", 4)
	_battle_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_turn_banner.offset_left = -360
	_turn_banner.offset_right = 360
	_turn_banner.offset_top = 245
	_turn_banner.offset_bottom = 299
	_turn_banner.add_theme_font_size_override("font_size", 24)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color("07121cdd")
	banner_style.border_color = Color("c9aa7688")
	banner_style.border_width_top = 1
	banner_style.border_width_bottom = 1
	banner_style.set_corner_radius_all(5)
	banner_style.content_margin_left = 20
	banner_style.content_margin_right = 20
	_turn_banner.add_theme_stylebox_override("normal", banner_style)
	_skip_button.pressed.connect(_on_skip_button_pressed)
	_skip_button.mouse_entered.connect(_preview_sweep)
	_skip_button.focus_entered.connect(_preview_sweep)
	_skip_button.mouse_exited.connect(_refresh_guidance)
	_skip_button.focus_exited.connect(_refresh_guidance)
	_player_chrono.socket_pressed.connect(_on_player_socket_pressed)
	if not _is_prepared and not _pending_enemies.is_empty():
		_prepare_combat(_pending_intro)
		if not _pending_intro: _start_prepared_combat()


func show_combat_log() -> void:
	var history_text: String = "[center][font_size=34][color=#80c8d1]◇[/color][/font_size]\n\n[color=#efc780][b]THE CHRONICLE IS UNWRITTEN[/b][/color]\n\n[color=#92a7b4]No mechanisms have resolved yet.\nEach clash, block, status and excess strike will be recorded here as the clock advances.[/color][/center]" if _combat_history.is_empty() else "\n\n".join(_combat_history)
	BattleReferenceOverlay.show_overlay(self, "RECENT COMBAT", "THE CHRONICLE  /  NEWEST FIRST", history_text, ScreenDesign.CYAN)


func show_combat_manual() -> void:
	var guide_text := "[color=#80c8d1][b]01  /  BUILD YOUR CLOCK[/b][/color]\nChoose one of three relics. The first binds to 1 o'clock, then 2, up to 9. After each placement, your relic and the enemy's matching tick resolve. Hover a relic to preview its destination before committing.\n\n[color=#efb85c][b]02  /  SWEEP THREE HOURS[/b][/color]\nEach turn covers 1–3, 4–6, then 7–9. Hover a glowing socket to preview replacing it with the offered reserve. Click the socket to replace and resolve the sweep. KEEP & SWEEP discards the offer and activates your current relics.\n\n[color=#80c8d1][b]03  /  READ THE ENEMY[/b][/color]\nThe enemy may rotate backward or use a second hand. Its illuminated intents show what resolves next.\n\n[color=#efb85c][b]KEYWORDS[/b][/color]\n[b]Block[/b] persists until absorbed or battle ends.  [b]Strength[/b] adds damage per hit.  [b]Thorns[/b] return damage when attacked.\n[b]Bleed[/b] removes HP at tick start.  [b]Weak[/b] reduces attack damage by 25%.  [b]Vulnerable[/b] increases damage taken by 50%.\n[b]Lifesteal[/b] heals actual HP damage dealt.  [b]Overdrive[/b] empowers the next attacking relic, including every hit."
	BattleReferenceOverlay.show_overlay(self, "READING THE CLOCK", "EXECUTIONER FIELD MANUAL", guide_text, ScreenDesign.CYAN)


func start_combat(incoming_enemies: Array[EnemyData], _background_id: String = "") -> void:
	_pending_enemies = incoming_enemies
	_pending_intro = false
	if is_node_ready():
		_prepare_combat(false)
		_start_prepared_combat()


func prepare_combat(incoming_enemies: Array[EnemyData], _background_id: String = "") -> void:
	_pending_enemies = incoming_enemies
	_pending_intro = true
	if is_node_ready(): _prepare_combat(true)


func begin_combat_intro() -> void:
	if _phase_started: return
	if not _is_prepared: _prepare_combat(true)
	_phase_started = true
	if is_instance_valid(_battle_intro): await _battle_intro.play()
	_start_phase_one()


func _start_prepared_combat() -> void:
	if _phase_started: return
	_phase_started = true
	_start_phase_one()

func _prepare_combat(with_intro: bool) -> void:
	if _is_prepared:
		return
	_is_prepared = true
	enemies_data = _pending_enemies
	_combat_over = false

	# Setup HP & stats
	player_hp = RunManager.current_hp if RunManager.current_hp > 0 else PlayerState.MAX_HP
	player_max_hp = RunManager.max_hp if RunManager.max_hp > 0 else PlayerState.MAX_HP
	player_block = 0
	player_next_hit_bonus = 0
	player_next_attack_multiplier = 1

	var main_enemy: EnemyData = enemies_data[0] if not enemies_data.is_empty() else null
	if main_enemy != null:
		enemy_max_hp = main_enemy.max_hp
		enemy_hp = main_enemy.max_hp
	else:
		enemy_max_hp = 50
		enemy_hp = 50
	enemy_block = 0

	_player_portrait.texture = null
	_enemy_portrait.texture = null
	_load_visual_assets(main_enemy)
	_init_player_deck()
	_init_chronometers(main_enemy)
	_artifact_triggered_this_combat.clear()
	_build_run_artifact_tray()
	for hour in range(1,10):
		var socket := _player_chrono.get_socket_view(hour)
		socket.previewed.connect(_preview_swap)
		socket.preview_ended.connect(_refresh_guidance)
	_update_stats_display()
	_apply_run_artifact_trigger(RelicData.Trigger.ON_COMBAT_START)
	_update_stats_display()
	if with_intro:
		_battle_intro = preload("res://scripts/combat/battle_intro_sequence.gd").new()
		add_child(_battle_intro)
		_battle_intro.prime(self, _stage)


func _load_visual_assets(main_enemy: EnemyData) -> void:
	# Encounter-tier art is selected deterministically from the cinematic
	# library. The plates stay character-free because the live illustrated
	# Executioner and enemy are composed over them during battle.
	var arena_bg_path := CinematicArt.combat_background(main_enemy, RunManager.act_number)
	if ResourceLoader.exists(arena_bg_path):
		_background.texture = ResourceLoader.load(arena_bg_path)
		AmbientMotion.apply_cinematic_backdrop(self, _background, 38.0, 0.48)
	else:
		# Keep the fallback inside the same character-free environment family;
		# never resurrect the retired arena plate with two baked-in fighters.
		_background.texture = ResourceLoader.load(CinematicArt.map_background(RunManager.act_number))
		AmbientMotion.apply_cinematic_backdrop(self, _background, 38.0, 0.48)

	# These legacy portrait controls anchor telemetry and combat VFX only.
	# Drawing their textures duplicated the animated stage actors at a different
	# scale, covering their animation and intruding into the relic choices.
	_player_portrait.texture = null
	_enemy_portrait.texture = null
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
	if _stage is IllustratedStage:
		(_stage as IllustratedStage).configure_enemy(EnemyClockPattern.profile(enemy), enemy.art_id if enemy != null else "")
	else:
		_stage.configure_enemy(EnemyClockPattern.profile(enemy))
	if enemies_data.size() > 1:
		_battle_info.text += "   •   OPPONENT %d / %d" % [_enemy_index + 1, enemies_data.size()]


# -------------------------------------------------------------
# PHASE 1: SECTOR ASSEMBLY & IMMEDIATE COMBO SWEEP (Turns 1 - 9)
# -------------------------------------------------------------
func _start_phase_one() -> void:
	phase = Phase.ASSEMBLY
	turn_number = 1
	active_quadrant = 1
	selected_assembly_hour = 1
	# Reveal all 9 enemy hours at combat start so the player can plan positional
	# synergies (Finishers on 3/6/9, Resonance chains, Socket Chargers) across all 3 sectors.
	for h: int in range(1, 10):
		_reveal_enemy_hour(h)
	_prompt_phase_one_draft()


func get_target_assembly_hour() -> int:
	if phase == Phase.ASSEMBLY:
		return clampi(selected_assembly_hour, 1, 9)
	return ChronometerView.get_quadrant_hours(active_quadrant)[0]


func _next_empty_sector_hour(quadrant: int) -> int:
	for h: int in ChronometerView.get_quadrant_hours(quadrant):
		if player_sockets[h - 1].slotted_relic == null and not player_sockets[h - 1].is_locked:
			return h
	for h: int in range(1, 10):
		if player_sockets[h - 1].slotted_relic == null and not player_sockets[h - 1].is_locked:
			return h
	return clampi(turn_number, 1, 9)


func _filled_sector_chain_hours(quadrant: int, include_hour: int = 0) -> Array[int]:
	var result: Array[int] = []
	for h: int in ChronometerView.get_quadrant_hours(quadrant):
		if h == include_hour or (player_sockets[h - 1].slotted_relic != null):
			result.append(h)
	if result.is_empty() and include_hour > 0:
		result.append(include_hour)
	return result


func _prompt_phase_one_draft() -> void:
	_phase_label.show()
	if _combat_over:
		return

	_resolving = false
	OKRunState.start_new_turn()
	active_quadrant = clampi(int((turn_number - 1) / 3) + 1, 1, 3)
	selected_assembly_hour = _next_empty_sector_hour(active_quadrant)
	var sector_hours := ChronometerView.get_quadrant_hours(active_quadrant)

	_player_chrono.highlight_quadrant(active_quadrant, Color("#EF9F27"))
	var enemy_q := 4 - active_quadrant if _enemy_chrono.rotation_direction < 0 else active_quadrant
	_enemy_chrono.highlight_quadrant(enemy_q, Color("#E74C3C"))
	_player_chrono.set_interactive_quadrant(active_quadrant, true)
	_sync_assembly_target_reticles()

	for h: int in sector_hours:
		_reveal_enemy_hour(EnemyClockPattern.hour_for(h, _active_enemy()))
	if EnemyClockPattern.has_twin(_active_enemy()):
		_reveal_enemy_hour(((EnemyClockPattern.hour_for(sector_hours[2], _active_enemy()) + 3) % 9) + 1)

	_player_chrono.mark_hour(selected_assembly_hour)
	_enemy_chrono.mark_hour(EnemyClockPattern.hour_for(selected_assembly_hour, _active_enemy()))
	_refresh_guidance()
	TutorialCallout.trigger("first_intent")
	_skip_button.hide()
	_clear_pedestals()

	# Draw 3 relics from deck
	current_draft_selection = _draw_relics(3)
	for relic in current_draft_selection:
		var ped: RelicPedestalView = pedestal_scene.instantiate()
		_pedestal_row.add_child(ped)
		ped.use_battle_layout()
		ped.bind_relic(relic, "BIND TO %d O'CLOCK" % selected_assembly_hour)
		ped.previewed.connect(_preview_allocation)
		ped.preview_ended.connect(_refresh_guidance)
		ped.selected.connect(_on_phase_one_relic_chosen)
	_choice_overlay.present(self)
	_update_stats_display()


func _sync_assembly_target_reticles() -> void:
	var sector_hours := ChronometerView.get_quadrant_hours(active_quadrant)
	for h: int in range(1, 10):
		var s_view: ClockSocketView = _player_chrono.get_socket_view(h)
		if s_view != null and s_view.has_method("set_targetable_empty"):
			var can_target: bool = phase == Phase.ASSEMBLY and not _resolving and sector_hours.has(h) and player_sockets[h - 1].slotted_relic == null and not player_sockets[h - 1].is_locked
			s_view.set_targetable_empty(can_target, can_target and h == selected_assembly_hour)


func _on_relic_chosen_for_assembly(chosen: ClockRelicData) -> void:
	if chosen != null and not current_draft_selection.has(chosen):
		current_draft_selection.append(chosen)
	await _on_phase_one_relic_chosen(chosen)


func _on_phase_one_relic_chosen(chosen: ClockRelicData) -> void:
	if _resolving or _combat_over or not current_draft_selection.has(chosen):
		return
	_resolving = true
	var target_hour: int = selected_assembly_hour
	if target_hour < 1 or target_hour > 9 or player_sockets[target_hour - 1].slotted_relic != null:
		target_hour = _next_empty_sector_hour(active_quadrant)
	_guidance.clear()
	_player_chrono.set_interactive_quadrant(active_quadrant, false)
	await _animate_placement(chosen, target_hour)
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

	# 3. Immediate Sector Combo Sweep: fire all filled hours in the active sector in sequence!
	var chain_hours: Array[int] = _filled_sector_chain_hours(active_quadrant, target_hour)
	if chain_hours.size() >= 2:
		var chain_str: PackedStringArray = []
		for ch: int in chain_hours:
			chain_str.append(str(ch))
		_show_turn_banner("SECTOR %d COMBO SWEEP  ·  %s" % [active_quadrant, " → ".join(chain_str)])
	for h: int in chain_hours:
		_player_chrono.snap_hand_to_hour(h)
		await _enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(h, _active_enemy()))
		await _resolve_tick(h)
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
	_swap_source_hour = 0
	AmbientMotion.punch_scale(_nexus_sigil, 1.18, 0.5)
	CombatVFX.play_shield_pulse(self, _nexus_sigil.global_position + _nexus_sigil.size * 0.5)
	await get_tree().create_timer(0.4 / AudioManager.combat_animation_speed_scale()).timeout
	_prompt_phase_two_turn()


func _prompt_phase_two_turn() -> void:
	_phase_label.show()
	if _combat_over:
		return

	_resolving = false
	_swap_source_hour = 0
	OKRunState.start_new_turn()
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "SECTOR %s  /  HOURS %02d–%02d     ·     Replace a socket with the reserve relic, or Overcharge & Sweep" % [str(active_quadrant), hours[0], hours[2]]

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
		_phase_label.text = "SECTOR %d  /  HOURS %02d–%02d     ·     Click two sockets to swap positions, or Overcharge & Sweep." % [active_quadrant, hours[0], hours[2]]

	_skip_button.show()
	_skip_button.text = "OVERCHARGE (+0.25× H%d & +3 OK) · KEEP & SWEEP %d → %d → %d" % [hours[1], hours[0], hours[1], hours[2]]
	_choice_overlay.present(self)
	_refresh_guidance()


func swap_sockets_in_active_sector(hour_a: int, hour_b: int) -> bool:
	if _resolving or _combat_over or hour_a == hour_b:
		return false
	var q_hours := ChronometerView.get_quadrant_hours(active_quadrant)
	if not q_hours.has(hour_a) or not q_hours.has(hour_b):
		return false
	var sock_a: ClockSocketData = player_sockets[hour_a - 1]
	var sock_b: ClockSocketData = player_sockets[hour_b - 1]
	if sock_a.is_locked or sock_b.is_locked:
		return false
	var tmp: ClockRelicData = sock_a.slotted_relic
	sock_a.slotted_relic = sock_b.slotted_relic
	sock_b.slotted_relic = tmp
	AudioManager.play_clock_sound("slot")
	_player_chrono.bind_sockets(player_sockets)
	if is_instance_valid(_choice_overlay) and _choice_overlay.visible:
		_choice_overlay.present(self)
	_refresh_guidance()
	return true


func _on_player_socket_pressed(hour_index: int, _socket_view: ClockSocketView) -> void:
	if _resolving or _combat_over:
		return

	var q_hours := ChronometerView.get_quadrant_hours(active_quadrant)
	if not q_hours.has(hour_index):
		return

	var socket_data: ClockSocketData = player_sockets[hour_index - 1]
	if socket_data.is_locked:
		return

	# Phase 1: allow choosing which empty socket in the active sector receives the next drafted relic!
	if phase == Phase.ASSEMBLY:
		if socket_data.slotted_relic == null:
			selected_assembly_hour = hour_index
			AudioManager.play_clock_sound("tick")
			_sync_assembly_target_reticles()
			_player_chrono.mark_hour(selected_assembly_hour)
			_enemy_chrono.mark_hour(EnemyClockPattern.hour_for(selected_assembly_hour, _active_enemy()))
			for child in _pedestal_row.get_children():
				if child is RelicPedestalView:
					(child as RelicPedestalView)._slot_button.text = "BIND TO %d O'CLOCK" % selected_assembly_hour
			if is_instance_valid(_choice_overlay) and is_instance_valid(_choice_overlay._heading):
				_choice_overlay._heading.text = "BIND A RELIC · SECTOR %d (HOUR %02d)" % [active_quadrant, selected_assembly_hour]
			_refresh_guidance()
		return

	# Phase 2 when no reserve relic is drawn: clicking two sockets in the active sector swaps their relics
	if current_drawn_relic == null:
		if _swap_source_hour == 0:
			_swap_source_hour = hour_index
			AudioManager.play_clock_sound("tick")
			_phase_label.text = "SWAP FROM HOUR %02d  ·  Select another socket in Sector %d to swap positions." % [hour_index, active_quadrant]
		elif _swap_source_hour == hour_index:
			_swap_source_hour = 0
			_refresh_guidance()
		else:
			var from_h: int = _swap_source_hour
			_swap_source_hour = 0
			swap_sockets_in_active_sector(from_h, hour_index)
		return

	_resolving = true
	_guidance.clear()
	await _animate_placement(current_drawn_relic, hour_index)
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

	# Overcharge & Sweep: reward keeping your sector clock by boosting the middle socket (+0.25x) and banking +3 Overkill
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	var mid_hour: int = hours[1]
	player_sockets[mid_hour - 1].multiplier = minf(4.0, player_sockets[mid_hour - 1].multiplier + 0.25)
	_player_chrono.bind_sockets(player_sockets)
	_gain_overkill(3, "combat:overcharge_sweep", true)

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
	# The player has committed. Clear decision helpers so hand, head and knee
	# motion remain visible, especially during the first tutorial encounter.
	_choice_overlay.hide()
	_guidance.clear()
	_phase_label.hide()
	var tutorial: TutorialCalloutView = get_node_or_null("TutorialCalloutView") as TutorialCalloutView
	if tutorial != null:
		tutorial.dismiss_now()
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
		Presentation.relay(self, p_view, _player_portrait, p_socket.slotted_relic.primary_color())
	if e_view:
		Presentation.relay(self, e_view, _enemy_portrait, Color("e99778"))
	await get_tree().create_timer(TICK_STARTUP_DELAY / AudioManager.combat_animation_speed_scale()).timeout

	# 1. Resolve Bleed (true unblockable damage at start of tick, with Overkill conversion on excess)
	if player_bleed > 0:
		player_hp -= player_bleed
		_spawn_damage_number(_player_portrait, player_bleed, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF), "BLEED")
	if enemy_bleed > 0:
		var target_was_alive: bool = enemy_hp > 0
		enemy_hp -= enemy_bleed
		_spawn_damage_number(_enemy_portrait, enemy_bleed, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF), "BLEED")
		if enemy_hp <= 0:
			var bleed_excess: int = maxi(0, -enemy_hp)
			enemy_hp = 0
			_notify_enemy_killed(target_was_alive)
			if bleed_excess > 0:
				_handle_overkill(bleed_excess)
	_update_stats_display()
	if _check_combat_end() or starting_enemy != _enemy_index: return

	# Build active relics for this hour (including Echo of previous hour if applicable)
	var prev_h: int = ((hour - 2 + 9) % 9) + 1
	var prev_relic: ClockRelicData = player_sockets[prev_h - 1].slotted_relic
	var active_relics: Array[ClockRelicData] = []
	if p_socket.slotted_relic != null:
		if p_socket.slotted_relic.echo_previous_hour and prev_relic != null and not prev_relic.echo_previous_hour:
			active_relics.append(prev_relic)
		active_relics.append(p_socket.slotted_relic)

	var player_attacks_this_tick: bool = false
	for ar: ClockRelicData in active_relics:
		if ar.base_damage > 0:
			player_attacks_this_tick = true
			break

	# 2. Resolve Shields, Buffs, Resonance, Bleed Multiplication/Detonation & Socket Charging
	var support_motion: Node2D = null
	if p_socket.slotted_relic != null and p_socket.slotted_relic.base_damage <= 0:
		support_motion = _new_relic_motion(p_socket.slotted_relic)
		await support_motion.play_prepare()

	var total_support_block_gained: int = 0
	var total_support_str_gained: int = 0
	var total_support_ok_gained: int = 0

	for relic: ClockRelicData in active_relics:
		var has_resonance: bool = relic.resonance_essence_bonus > 0 and prev_relic != null and relic.shares_essence_with(prev_relic)
		if relic.base_block > 0:
			var raw_blk: int = relic.base_block + (relic.resonance_essence_bonus if has_resonance else 0)
			var gained_blk: int = int(floor(float(raw_blk) * p_socket.multiplier))
			player_block += gained_blk
			total_support_block_gained += gained_blk
			_spawn_damage_number(_player_portrait, gained_blk, false, Color("7bd6de"), "BLOCK", false)
			CombatVFX.play_shield_pulse(self, _player_portrait.global_position + _player_portrait.size * 0.5)
			_apply_run_artifact_trigger(RelicData.Trigger.ON_BLOCK_GAIN)
		if relic.multiply_current_block > 1.0 and player_block > 0:
			var multiplied_blk: int = int(floor(float(player_block) * relic.multiply_current_block))
			var bonus_blk: int = maxi(0, multiplied_blk - player_block)
			player_block = multiplied_blk
			total_support_block_gained += bonus_blk
			if bonus_blk > 0:
				_spawn_damage_number(_player_portrait, bonus_blk, false, Color("7bd6de"), "BLOCK", false)
				CombatVFX.play_shield_pulse(self, _player_portrait.global_position + _player_portrait.size * 0.5)
				_apply_run_artifact_trigger(RelicData.Trigger.ON_BLOCK_GAIN)
		if relic.apply_strength > 0:
			player_strength += relic.apply_strength
			total_support_str_gained += relic.apply_strength
		if relic.apply_thorns > 0:
			player_thorns += relic.apply_thorns
		if relic.apply_vulnerable > 0:
			enemy_vulnerable += relic.apply_vulnerable + (1 if not player_attacks_this_tick else 0)
		if relic.apply_weak > 0:
			enemy_weak += relic.apply_weak + (1 if e_socket.intent_damage <= 0 else 0)
		if relic.apply_bleed > 0:
			enemy_bleed += int(floor(float(relic.apply_bleed) * p_socket.multiplier))
		if relic.multiply_enemy_bleed > 1.0 and enemy_bleed > 0:
			enemy_bleed = int(floor(float(enemy_bleed) * relic.multiply_enemy_bleed))
		if relic.trigger_bleed_times > 0 and enemy_bleed > 0:
			for _b_i: int in range(relic.trigger_bleed_times):
				var target_was_alive: bool = enemy_hp > 0
				enemy_hp -= enemy_bleed
				_spawn_damage_number(_enemy_portrait, enemy_bleed, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.DEBUFF), "BLEED")
				if enemy_hp <= 0:
					var det_excess: int = maxi(0, -enemy_hp)
					enemy_hp = 0
					_notify_enemy_killed(target_was_alive)
					if det_excess > 0:
						_handle_overkill(det_excess)
		if relic.bonus_damage_next_hit > 0:
			player_next_hit_bonus += relic.bonus_damage_next_hit
		if relic.base_damage <= 0 and relic.next_attack_multiplier > 1:
			player_next_attack_multiplier = maxi(player_next_attack_multiplier, relic.next_attack_multiplier)
		if relic.grant_overkill > 0:
			total_support_ok_gained += relic.grant_overkill
			_gain_overkill(relic.grant_overkill, "clock_relic:%s" % relic.id, false)
		if relic.charge_next_socket_multiplier > 0.0:
			var next_h: int = (hour % 9) + 1
			player_sockets[next_h - 1].multiplier = minf(4.0, player_sockets[next_h - 1].multiplier + relic.charge_next_socket_multiplier)
			_player_chrono.bind_sockets(player_sockets)

	if is_instance_valid(support_motion):
		_update_stats_display()
		await support_motion.play_resolve({
			"block_gained": total_support_block_gained,
			"strength_gained": total_support_str_gained,
			"overkill_gained": total_support_ok_gained,
		})
		support_motion.dispose()
		await _stage.await_player_recovery()

	_update_stats_display()
	if _check_combat_end() or starting_enemy != _enemy_index: return

	if e_socket.intent_block > 0:
		enemy_block += e_socket.intent_block
		_spawn_damage_number(_enemy_portrait, e_socket.intent_block, false, Color("7bd6de"), "BLOCK")
		CombatVFX.play_shield_pulse(self, _enemy_portrait.global_position + _enemy_portrait.size * 0.5)
	if e_socket.intent_strength > 0:
		enemy_strength += e_socket.intent_strength
	player_bleed += e_socket.intent_bleed
	if e_socket.intent_weak > 0:
		player_weak += e_socket.intent_weak + (1 if not player_attacks_this_tick else 0)
	if e_socket.intent_vulnerable > 0:
		player_vulnerable += e_socket.intent_vulnerable + (1 if e_socket.intent_damage <= 0 else 0)

	_update_stats_display()

	# 3. Resolve Attacks
	# Player Attacks Enemy (supports Echo + Sector Finisher + Resonance + Archetype Payoffs)
	for relic: ClockRelicData in active_relics:
		if relic.base_damage <= 0:
			continue
		_apply_run_artifact_trigger(RelicData.Trigger.ON_PLAYER_ATTACK)
		var has_resonance: bool = relic.resonance_essence_bonus > 0 and prev_relic != null and relic.shares_essence_with(prev_relic)
		var strike_bonus: int = player_next_hit_bonus
		player_next_hit_bonus = 0

		var raw_base: int = relic.base_damage
		# Execution Wedge condition
		if relic.conditional_hp_threshold_pct > 0.0 and float(enemy_hp) / maxf(float(enemy_max_hp), 1.0) <= relic.conditional_hp_threshold_pct:
			raw_base = relic.conditional_damage
		if has_resonance:
			raw_base += relic.resonance_essence_bonus
		if hour in [3, 6, 9] and relic.sector_finisher_bonus_damage > 0:
			raw_base += relic.sector_finisher_bonus_damage

		var arch_bonus: int = 0
		if relic.damage_per_current_block_pct > 0.0:
			arch_bonus += int(floor(float(player_block) * relic.damage_per_current_block_pct))
		if relic.thorns_to_damage_multiplier > 0.0:
			arch_bonus += int(floor(float(player_thorns) * relic.thorns_to_damage_multiplier))
		if relic.damage_per_enemy_bleed > 0:
			arch_bonus += enemy_bleed * relic.damage_per_enemy_bleed
		if relic.damage_per_banked_overkill_div > 0:
			arch_bonus += int(OKRunState.current_ok / relic.damage_per_banked_overkill_div)

		var dmg: int = raw_base + player_strength + strike_bonus + arch_bonus
		if enemy_vulnerable > 0:
			dmg = int(floor(dmg * 1.5))
		if player_weak > 0:
			dmg = int(floor(dmg * 0.75))
		dmg = int(floor(dmg * p_socket.multiplier)) * player_next_attack_multiplier
		player_next_attack_multiplier = maxi(1, relic.next_attack_multiplier)

		var total_hits: int = relic.hits + (relic.sector_finisher_hits_bonus if hour in [3, 6, 9] else 0)
		for hit_index: int in range(total_hits):
			await _apply_damage_to_enemy(dmg, p_socket, hit_index, total_hits, relic)
			# Keep this relic's hit sequence on the defeated target. A killing hit
			# ends the enemy's ability to retaliate, but remaining hits are still
			# real executions and bank their full damage as Overkill.
			if player_hp <= 0:
				_check_combat_end()
				return
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
	await get_tree().create_timer(TICK_RECOVERY_DELAY / AudioManager.combat_animation_speed_scale()).timeout


func _apply_damage_to_enemy(amount: int, p_socket: ClockSocketData, hit_index: int = 0, hit_count: int = 1, active_relic: ClockRelicData = null) -> void:
	var relic_used: ClockRelicData = active_relic if active_relic != null else p_socket.slotted_relic
	var profile: Dictionary = AttackPresentation.for_relic_hit(relic_used, hit_index)
	profile["hit_index"] = hit_index
	profile["hit_count"] = hit_count
	var target_was_alive: bool = enemy_hp > 0
	var relic_motion: Node2D = _new_relic_motion(relic_used)
	if _stage.has_method("prepare_defense"): _stage.prepare_defense(false, enemy_block >= amount)
	_stage.attack(true, profile)
	relic_motion.start_attack(profile)
	var swing_wait: float = _stage.swing_delay(true) if _stage.has_method("swing_delay") else 0.0
	if swing_wait > 0.0: await get_tree().create_timer(swing_wait / AudioManager.combat_animation_speed_scale()).timeout
	AudioManager.play_combat_sound("swing")
	Presentation.relay(self, _player_portrait, _enemy_portrait, profile.get("accent", Color("7bd6de")))
	if _stage.has_method("await_contact"): await _stage.await_contact(true)
	else: await get_tree().create_timer(0.16 / AudioManager.combat_animation_speed_scale()).timeout
	await relic_motion.await_contact()
	AudioManager.play_combat_sound("guard" if enemy_block >= amount else ("shatter" if enemy_block > 0 else "strike"))
	_stage.impact(false, enemy_block >= amount, profile)
	var nexus_pos: Vector2 = _enemy_portrait.global_position + _enemy_portrait.size * 0.5
	AttackPresentation.play_canvas_impact(self, nexus_pos, profile)
	AmbientMotion.flash(_enemy_portrait, Color(2.0, 0.8, 0.8), 0.30)
	if AttackPresentation.is_heavy_hammer(profile):
		AmbientMotion.shake(self, float(profile.get("shake", 9.0)), 0.44)
		await get_tree().create_timer(float(profile.get("impact_hold", 0.055)) / AudioManager.combat_animation_speed_scale()).timeout

	# Hazard modifier check (recoil)
	if p_socket.is_hazard:
		var recoil := int(floor(amount * 0.5))
		player_hp -= recoil
		_spawn_damage_number(_player_portrait, recoil, false, Color("#E24B4A"), "RECOIL")

	var hp_damage: int = mini(maxi(enemy_hp, 0), maxi(amount - enemy_block, 0))
	var recoil_block_gained: int = 0
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
			_spawn_damage_number(_enemy_portrait, hp_damage, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.ATTACK))
			enemy_hp = 0
			_notify_enemy_killed(target_was_alive)
			if relic_used != null and relic_used.recoil_block_on_overkill:
				player_block += overkill
				recoil_block_gained = overkill
			_handle_overkill(overkill)
		else:
			enemy_hp -= unblocked
			_spawn_damage_number(_enemy_portrait, unblocked, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.ATTACK))

		# Overkill Extraction payoff on unblocked attack damage
		if unblocked > 0 and relic_used != null and relic_used.overkill_extraction_pct > 0.0:
			var extracted_ok: int = maxi(1, int(floor(float(unblocked) * relic_used.overkill_extraction_pct)))
			_gain_overkill(extracted_ok, "combat:extraction:%s" % relic_used.id, true)

	var healed: int = 0
	if relic_used != null and relic_used.lifesteal and player_hp > 0:
		healed = mini(hp_damage, maxi(player_max_hp - player_hp, 0))
		player_hp += healed
		if healed > 0:
			if relic_used.id == "REL-13":
				_pending_lifesteal_visual = healed
				relic_motion.transfer_arrived.connect(_finish_lifesteal_feedback.bind(healed), CONNECT_ONE_SHOT)
			else:
				_finish_lifesteal_feedback(healed)
	# Thorns check
	if target_was_alive and enemy_thorns > 0:
		player_hp -= enemy_thorns
		_spawn_damage_number(_player_portrait, enemy_thorns, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF), "THORNS")

	_update_stats_display()
	await relic_motion.play_resolve({
		"damage_dealt": hp_damage,
		"healed": healed,
		"block_gained": (relic_used.base_block if relic_used != null and hit_index == 0 else 0) + recoil_block_gained,
		"strength_gained": relic_used.apply_strength if relic_used != null and hit_index == 0 else 0,
		"overkill_gained": relic_used.grant_overkill if relic_used != null and hit_index == 0 else 0,
		"next_attack_multiplier": player_next_attack_multiplier if hit_index == hit_count - 1 else 1,
	})
	if relic_used == null or relic_used.id != "REL-02" or hit_index == hit_count - 1 or player_hp <= 0:
		relic_motion.dispose()
		_twin_relic_motion = null
	await _stage.await_player_recovery()


func _finish_lifesteal_feedback(healed: int) -> void:
	_pending_lifesteal_visual = 0
	AudioManager.play_combat_sound("heal")
	_spawn_damage_number(_player_portrait, healed, false, Color("7ce0ac"), "HEAL")
	_update_stats_display()

func _new_relic_motion(relic: ClockRelicData) -> Node2D:
	if relic.id == "REL-02" and is_instance_valid(_twin_relic_motion):
		return _twin_relic_motion
	var motion: Node2D = RelicMotion.create(_stage, self, relic)
	if relic.id == "REL-02": _twin_relic_motion = motion
	motion.buff_target_global = _player_core_strip.get_global_rect().get_center()
	return motion


func _apply_damage_to_player(amount: int, e_socket: ClockSocketData) -> void:
	var profile: Dictionary = AttackPresentation.for_enemy(e_socket)
	if _stage.has_method("prepare_defense"): _stage.prepare_defense(true, player_block >= amount)
	_stage.attack(false, profile)
	var swing_wait: float = _stage.swing_delay(false) if _stage.has_method("swing_delay") else 0.0
	if swing_wait > 0.0: await get_tree().create_timer(swing_wait / AudioManager.combat_animation_speed_scale()).timeout
	AudioManager.play_combat_sound("swing")
	Presentation.relay(self, _enemy_portrait, _player_portrait, profile.accent)
	if _stage.has_method("await_contact"): await _stage.await_contact(false)
	else: await get_tree().create_timer(0.16 / AudioManager.combat_animation_speed_scale()).timeout
	AudioManager.play_combat_sound("guard" if player_block >= amount else ("shatter" if player_block > 0 else "strike"))
	_stage.impact(true, player_block >= amount, profile)
	var p_pos: Vector2 = _player_portrait.global_position + _player_portrait.size * 0.5
	AttackPresentation.play_canvas_impact(self, p_pos, profile)
	AmbientMotion.flash(_player_portrait, Color(1.8, 0.5, 0.5), 0.30)
	AmbientMotion.shake(self, float(profile.shake), 0.4 if profile.id != "enemy_heavy" else 0.52)

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
		if player_hp > 0:
			_apply_run_artifact_trigger(RelicData.Trigger.ON_PLAYER_HIT)

		# Siphon modifier check
		if e_socket.is_siphon and OKRunState.current_ok > 0:
			var drained := int(floor(OKRunState.current_ok * 0.25))
			OKRunState.current_ok = max(0, OKRunState.current_ok - drained)

	# Thorns check (with 1:1 Overkill conversion if Thorns reduces enemy_hp below 0)
	if player_thorns > 0:
		var target_was_alive: bool = enemy_hp > 0
		enemy_hp -= player_thorns
		_spawn_damage_number(_enemy_portrait, player_thorns, false, ClockRelicData.essence_to_color(ClockRelicData.Essence.BUFF), "THORNS")
		if enemy_hp <= 0:
			var thorns_excess: int = maxi(0, -enemy_hp)
			enemy_hp = 0
			_notify_enemy_killed(target_was_alive)
			if thorns_excess > 0:
				_handle_overkill(thorns_excess)

	_update_stats_display()
	await get_tree().create_timer((_stage.recovery_delay() if _stage.has_method("recovery_delay") else 0.24) / AudioManager.combat_animation_speed_scale()).timeout


func _gain_overkill(amount: int, source: String = "combat:extraction", show_visual: bool = true) -> void:
	if amount <= 0:
		return
	OKRunState.gain_ok(amount, source)
	_spawn_damage_number(_player_portrait, amount, true, ClockRelicData.essence_to_color(ClockRelicData.Essence.OVERKILL), "OVERKILL", show_visual)
	CombatVFX.play_hit_sparks(self, _player_portrait.global_position + _player_portrait.size * 0.5, ClockRelicData.essence_to_color(ClockRelicData.Essence.OVERKILL).lightened(0.2), 9)
	TutorialCallout.trigger("first_ok")


func _handle_overkill(overkill: int) -> void:
	_spawn_damage_number(_enemy_portrait, overkill, true, ClockRelicData.essence_to_color(ClockRelicData.Essence.OVERKILL))
	OKRunState.record_kill(overkill, "combat:chronometer")
	if overkill > 0:
		_apply_run_artifact_trigger(RelicData.Trigger.ON_OVERKILL, overkill)
	TutorialCallout.trigger("first_ok")

	var enemy_pos: Vector2 = _enemy_portrait.global_position + _enemy_portrait.size * 0.5
	CombatVFX.play_overkill_burst(self, enemy_pos, overkill)

	var hud_ok_pos := Vector2(size.x * 0.5, 45.0)
	CombatVFX.play_ok_essence_trail(self, enemy_pos, hud_ok_pos, clampi(int(overkill * 0.5), 3, 8))

	if overkill >= 5:
		AmbientMotion.shake(self, clampf(overkill * 0.4, 6.0, 12.0), 0.5)


func _build_run_artifact_tray() -> void:
	for child: Node in _relic_bar.get_children():
		child.queue_free()
	_relic_bar.visible = not RunManager.relics_held.is_empty()
	_relic_bar.offset_left = 30.0
	_relic_bar.offset_top = 106.0
	_relic_bar.offset_right = 300.0
	_relic_bar.offset_bottom = 158.0
	_relic_bar.add_theme_constant_override("separation", 8)
	for artifact: RelicData in RunManager.relics_held:
		var icon := RelicIcon.new()
		icon.custom_minimum_size = Vector2(46.0, 46.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.relic = artifact
		_relic_bar.add_child(icon)


func _apply_run_artifact_trigger(trigger: RelicData.Trigger, trigger_value: int = 0) -> void:
	for artifact: RelicData in RunManager.relics_held:
		if artifact.trigger != trigger:
			continue
		var minimum_overkill: int = int(artifact.condition_data.get("min_ok", 0))
		if trigger == RelicData.Trigger.ON_OVERKILL and trigger_value < minimum_overkill:
			continue
		var minimum_missing_hp: int = int(artifact.condition_data.get("min_hp_missing", 0))
		if trigger == RelicData.Trigger.ON_KILL and player_max_hp - player_hp < minimum_missing_hp:
			continue
		var once_per_combat: bool = bool(artifact.condition_data.get("once_per_combat", false))
		if once_per_combat and _artifact_triggered_this_combat.has(artifact.id):
			continue
		if once_per_combat:
			_artifact_triggered_this_combat[artifact.id] = true
		for effect: EffectData in artifact.effects:
			var presentation_target: Control = _player_portrait
			match effect.effect_type:
				EffectData.EffectType.BLOCK:
					player_block += effect.value
					_spawn_damage_number(_player_portrait, effect.value, false, Color("76d9ee"), "BLOCK")
					CombatVFX.play_shield_pulse(self, _player_portrait.global_position + _player_portrait.size * 0.5)
				EffectData.EffectType.GAIN_OK:
					OKRunState.gain_ok(effect.value, "artifact:%s" % artifact.id)
					_spawn_damage_number(_player_portrait, effect.value, true, Color("cf5e5b"))
				EffectData.EffectType.HEAL:
					# Kill-trigger healing is recovery, not resurrection. Thorns
					# and Bleed may still earn a kill after the incoming lethal
					# damage; retain that accounting without undoing death.
					if player_hp <= 0:
						continue
					var healed: int = mini(effect.value, maxi(player_max_hp - player_hp, 0))
					player_hp += healed
					if healed > 0:
						AudioManager.play_combat_sound("heal")
						_spawn_damage_number(_player_portrait, healed, false, Color("b78af4"), "HEAL")
				EffectData.EffectType.APPLY_STATUS:
					if effect.status_id == "weak":
						# Player-hit triggers resolve after the foe's hit; retain the
						# status through this tick's decay so it affects its next strike.
						enemy_weak += effect.value + (1 if trigger == RelicData.Trigger.ON_PLAYER_HIT else 0)
						presentation_target = _enemy_portrait
					elif effect.status_id == "vulnerable":
						enemy_vulnerable += effect.value
						presentation_target = _enemy_portrait
				EffectData.EffectType.ATTACK_BONUS:
					player_next_hit_bonus += effect.value
					presentation_target = _enemy_portrait
				EffectData.EffectType.STRENGTH:
					player_strength += effect.value
			ArtifactPresentation.play(self, _artifact_icon(artifact.id), presentation_target, artifact, effect)
		for child: Node in _relic_bar.get_children():
			if child is RelicIcon and child.relic.id == artifact.id:
				(child as RelicIcon).play_trigger_flash()
				break


func _artifact_icon(artifact_id: String) -> RelicIcon:
	for child: Node in _relic_bar.get_children():
		if child is RelicIcon and (child as RelicIcon).relic != null and (child as RelicIcon).relic.id == artifact_id:
			return child as RelicIcon
	return null


func _notify_enemy_killed(target_was_alive: bool) -> void:
	if target_was_alive and enemy_hp <= 0:
		_apply_run_artifact_trigger(RelicData.Trigger.ON_KILL)


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
		get_tree().create_timer((_stage.finish_delay() if _stage.has_method("finish_delay") else 0.8) / AudioManager.combat_animation_speed_scale()).timeout.connect(func() -> void: combat_won.emit(enemies_data))
		return true

	if player_hp <= 0:
		_combat_over = true
		_show_turn_banner("DEFEAT")
		_finish_presentation(false)
		RunManager.sync_hp_from_combat(0)
		get_tree().create_timer((_stage.finish_delay() if _stage.has_method("finish_delay") else 0.8) / AudioManager.combat_animation_speed_scale()).timeout.connect(func() -> void: combat_lost.emit())
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
	exit_tween.set_speed_scale(AudioManager.combat_animation_speed_scale())
	exit_tween.tween_property(fallen, "modulate", Color(0.25, 0.25, 0.3, 0.0), 0.45)
	var fade := Presentation.create_fade(self)
	fade.color.a = 0.0
	var fade_tween := create_tween()
	fade_tween.set_speed_scale(AudioManager.combat_animation_speed_scale())
	fade_tween.tween_interval(_stage.finish_fade_delay() if _stage.has_method("finish_fade_delay") else 0.5)
	fade_tween.tween_property(fade, "color:a", 1.0, 0.28)


func _update_stats_display() -> void:
	var visible_player_hp: int = maxi(player_hp - _pending_lifesteal_visual, 0)
	_player_stats_label.text = "%d / %d  ·  %d" % [visible_player_hp, player_max_hp, player_block]
	_player_stats_label.tooltip_text = "Vitality: %d / %d\nBlock: %d" % [visible_player_hp, player_max_hp, player_block]
	_enemy_stats_label.text = "%d / %d  ·  %d" % [maxi(enemy_hp, 0), enemy_max_hp, enemy_block]
	_enemy_stats_label.tooltip_text = "Vitality: %d / %d\nBlock: %d" % [maxi(enemy_hp, 0), enemy_max_hp, enemy_block]
	_update_core_strip(_player_core_strip, visible_player_hp, player_max_hp, player_block, player_next_attack_multiplier)
	_update_core_strip(_enemy_core_strip, maxi(enemy_hp, 0), enemy_max_hp, enemy_block, 1)
	_update_status_strip(_player_status_strip, player_strength, player_bleed, player_thorns, player_weak, player_vulnerable)
	_update_status_strip(_enemy_status_strip, enemy_strength, enemy_bleed, enemy_thorns, enemy_weak, enemy_vulnerable)
	_hud.bind_clock_state(visible_player_hp, player_max_hp)
	for entry in [[_player_portrait, visible_player_hp, player_max_hp], [_enemy_portrait, enemy_hp, enemy_max_hp]]:
		var bar: ProgressBar = entry[0].get_node("Vitality")
		bar.max_value = entry[2]
		bar.value = maxi(entry[1], 0)
	_sync_assembly_target_reticles()
	for h: int in range(1, 10):
		var p_sview: ClockSocketView = _player_chrono.get_socket_view(h)
		if p_sview != null and p_sview.has_method("refresh_live_from_context"):
			p_sview.refresh_live_from_context(self)
		var e_sview: ClockSocketView = _enemy_chrono.get_socket_view(h)
		if e_sview != null and e_sview.has_method("refresh_live_from_context"):
			e_sview.refresh_live_from_context(self)


func _build_combatant_stat_ui() -> void:
	_player_core_strip = _make_stat_row(_player_portrait, "CoreStatStrip", -138.0, 124.0, 276.0, 34.0)
	_enemy_core_strip = _make_stat_row(_enemy_portrait, "CoreStatStrip", -138.0, 124.0, 276.0, 34.0)
	_player_status_strip = _make_stat_row(_player_portrait, "StatusIconStrip", -138.0, 160.0, 276.0, 34.0)
	_enemy_status_strip = _make_stat_row(_enemy_portrait, "StatusIconStrip", -138.0, 160.0, 276.0, 34.0)
	_player_stats_label.visible = false
	_enemy_stats_label.visible = false


func _make_stat_row(parent: Control, row_name: String, left: float, top: float, width: float, height: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = row_name
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = left
	row.offset_top = top
	row.offset_right = left + width
	row.offset_bottom = top + height
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(row)
	return row


func _update_core_strip(row: HBoxContainer, hp: int, max_hp: int, block: int, next_attack_multiplier: int) -> void:
	_sync_battle_chip(row, "HP", "res://assets/icons/ui/icon_hp.png", "♥", "%d/%d" % [hp,max_hp], hp, "Vitality: %d of %d" % [hp,max_hp], Color("f08a83"))
	_sync_battle_chip(row, "Block", "res://assets/icons/ui/icon_block.png", "◇", str(block), block, "Block absorbs incoming damage before Vitality.", Color("76d9ee"))
	if next_attack_multiplier > 1:
		_sync_battle_chip(row, "Overdrive", "res://assets/icons/ui/icon_overkill.png", "×", "×%d" % next_attack_multiplier, next_attack_multiplier, "Your next attacking relic is empowered.", Color("b76cff"))
	else:
		_remove_battle_chip(row,"Overdrive")

func _update_status_strip(row: HBoxContainer, strength: int, bleed: int, thorns: int, weak: int, vulnerable: int) -> void:
	var entries: Array = [
		["Strength", strength, "res://assets/icons/status/status_strength.png", "✦", Color("b76cff"), "Strength adds damage to each attack."],
		["Bleed", bleed, "", "⌁", Color("f08a83"), "Bleed removes Vitality each tick."],
		["Thorns", thorns, "", "❖", Color("b76cff"), "Thorns return damage when struck."],
		["Weak", weak, "res://assets/icons/status/status_weak.png", "↓", Color("84c8ae"), "Weak reduces outgoing damage."],
		["Vulnerable", vulnerable, "res://assets/icons/status/status_vulnerable.png", "⌖", Color("efb477"), "Vulnerable increases incoming damage."]]
	for entry: Array in entries:
		if int(entry[1]) > 0:
			_sync_battle_chip(row,str(entry[0]),str(entry[2]),str(entry[3]),str(entry[1]),int(entry[1]),str(entry[5]),entry[4])
		else:
			_remove_battle_chip(row,str(entry[0]))

func _remove_battle_chip(row: HBoxContainer, key: String) -> void:
	row.set_meta("previous_"+key,0)
	var chip: Node = row.get_node_or_null(NodePath(key))
	if chip != null:
		row.remove_child(chip)
		chip.queue_free()

func _sync_battle_chip(row: HBoxContainer, key: String, icon_path: String, glyph: String, value: String, amount: int, explanation: String, tint: Color) -> void:
	var chip: Control = row.get_node_or_null(NodePath(key)) as Control
	var previous: int = int(row.get_meta("previous_"+key, 0))
	if chip == null:
		_add_stat_chip(row,icon_path,glyph,value,explanation,tint)
		chip = row.get_child(row.get_child_count()-1) as Control
		chip.name = key
		if key == "Strength" and chip.get_child(0) is TextureRect:
			var material := ShaderMaterial.new()
			material.shader = preload("res://assets/ui/combat/status_tint.gdshader")
			material.set_shader_parameter("status_color",tint)
			(chip.get_child(0) as TextureRect).material = material
	chip.tooltip_text = explanation + "\nCurrent: " + value
	(chip.get_child(chip.get_child_count()-1) as Label).text = value
	row.set_meta("previous_"+key,amount)
	if amount > previous and (key != "HP" or previous > 0):
		var old_tween: Tween = (chip.get_meta("gain_tween") as Tween) if chip.has_meta("gain_tween") else null
		if old_tween != null and old_tween.is_valid(): old_tween.kill()
		chip.pivot_offset = chip.size*.5
		chip.scale = Vector2.ONE if AudioManager.reduced_motion else Vector2(1.22,1.22)
		chip.modulate = tint.lightened(.65)
		chip.set_meta("gain_count",int(chip.get_meta("gain_count",0))+1)
		var tween: Tween = chip.create_tween().set_speed_scale(AudioManager.animation_speed_scale())
		chip.set_meta("gain_tween",tween)
		tween.tween_property(chip,"scale",Vector2.ONE,.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(chip,"modulate",Color.WHITE,.7)


func _add_stat_chip(row: HBoxContainer, icon_path: String, fallback_glyph: String, value: String, explanation: String, tint: Color) -> void:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.tooltip_text = explanation
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon := TextureRect.new()
	if ResourceLoader.exists(icon_path): icon.texture = load(icon_path)
	if icon.texture == null:
		icon.free()
		var glyph := Label.new()
		glyph.text = fallback_glyph
		glyph.add_theme_color_override("font_color", tint)
		glyph.add_theme_font_size_override("font_size", 21)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(glyph)
	else:
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon)
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", Color("f1eadb"))
	label.add_theme_font_size_override("font_size", 21)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	row.add_child(chip)


func _add_status_chip(row: HBoxContainer, icon_path: String, glyph: String, stack: int, explanation: String) -> void:
	var tint: Color = Color("b6d9ef")
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 2)
	chip.tooltip_text = "%s\nStack: %d" % [explanation, stack]
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon := TextureRect.new()
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path): icon.texture = load(icon_path)
	if icon.texture != null:
		icon.custom_minimum_size = Vector2(21, 21)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon)
	else:
		icon.free()
		var symbol := Label.new()
		symbol.text = glyph
		symbol.add_theme_color_override("font_color", tint)
		symbol.add_theme_font_size_override("font_size", 19)
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(symbol)
	var amount := Label.new()
	amount.text = str(stack)
	amount.add_theme_font_size_override("font_size", 19)
	amount.add_theme_color_override("font_color", tint)
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(amount)
	row.add_child(chip)


func _status_text(strength: int, bleed: int, thorns: int, weak: int, vulnerable: int) -> String:
	var parts: PackedStringArray = []
	for pair in [[strength, "STRENGTH"], [bleed, "BLEED"], [thorns, "THORNS"], [weak, "WEAK"], [vulnerable, "VULNERABLE"]]:
		if pair[0] > 0:
			parts.append("%d %s" % [pair[0], pair[1]])
	return " · ".join(parts)


func _spawn_damage_number(target: Control, val: int, is_ok: bool, col: Color, kind: String = "HP", show_visual: bool = true) -> void:
	if val <= 0: return
	_combat_history.push_front("Hour %d · %s · %s %d" % [_resolution_hour,"You" if target == _player_portrait or is_ok else "Enemy","Overkill gained" if is_ok else kind,val])
	if _combat_history.size() > 16: _combat_history.pop_back()
	if not show_visual: return
	var num: DamageNumber = damage_number_scene.instantiate()
	add_child(num)
	num.position = target.global_position + target.size * 0.5 + Vector2(randf_range(-20, 20), -20)
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
		var target_h: int = get_target_assembly_hour()
		var chain_hours: Array[int] = _filled_sector_chain_hours(active_quadrant, target_h)
		var chain_labels: PackedStringArray = []
		for ch: int in chain_hours:
			chain_labels.append(str(ch))
		_player_chrono.snap_hand_to_hour(target_h, 0.18)
		_enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(target_h, _active_enemy()), 0.18)
		_phase_label.text = "SECTOR %d · Bind a relic to Hour %d (or click another open socket in Sector %d), then chain %s." % [active_quadrant, target_h, active_quadrant, " → ".join(chain_labels)]
		_guidance.point_to(_player_chrono, _player_chrono.get_socket_view(target_h), chain_hours, "NEXT SLOT\n%d O'CLOCK" % target_h)
	else:
		var hours := ChronometerView.get_quadrant_hours(active_quadrant)
		_player_chrono.snap_hand_to_hour(hours[0], 0.18)
		_enemy_chrono.snap_hand_to_hour(EnemyClockPattern.hour_for(hours[0], _active_enemy()), 0.18)
		_phase_label.text = "Replace one pulsing slot, then activate hours %d → %d → %d. Overcharge & Sweep boosts Hour %d (+0.25×) & +3 Overkill." % [hours[0], hours[1], hours[2], hours[1]]
		if current_drawn_relic == null: _phase_label.text = "No reserve relic available. Click two sockets in Sector %d to swap positions, or Overcharge & Sweep %d → %d → %d." % [active_quadrant, hours[0], hours[1], hours[2]]
		_guidance.point_to(_player_chrono, null, hours, "NEXT SWEEP\n%d → %d → %d" % hours)

func _refresh_intent_readout() -> void:
	_enemy_chrono.set_readout_clearance(true)
	if _combat_over:
		_intent_clock_label.text = "DEFEATED" if enemy_hp <= 0 else "BATTLE OVER"
		return
	if enemy_sockets.is_empty(): return
	var hours: Array = _filled_sector_chain_hours(active_quadrant, get_target_assembly_hour()) if phase == Phase.ASSEMBLY else ChronometerView.get_quadrant_hours(active_quadrant)
	var clock_hours: PackedStringArray = []
	for hour: int in hours:
		var index: int = EnemyClockPattern.hour_for(hour,_active_enemy())
		clock_hours.append(str(index))
	if EnemyClockPattern.has_twin(_active_enemy()) and int(hours.back()) % 3 == 0:
		var last_hour: int = EnemyClockPattern.hour_for(int(hours.back()),_active_enemy())
		var echo_index: int = (last_hour + 3) % 9
		clock_hours.append("echo %d" % (echo_index + 1))
	_intent_clock_label.text = " → ".join(clock_hours)

func _refresh_intent_text_size(_settings: Dictionary = {}) -> void:
	ScreenDesign.apply_text_size(_intent_clock_label)

func _preview_allocation(view: RelicPedestalView) -> void:
	if _resolving or _combat_over or phase != Phase.ASSEMBLY: return
	var target_h: int = get_target_assembly_hour()
	var chain_hours: Array[int] = _filled_sector_chain_hours(active_quadrant, target_h)
	var eval_info: Dictionary = DecisionPreview.evaluate_relic_on_hour(self, view.relic, target_h)
	var tags: Array = eval_info.get("active_tags", [])
	var tag_suffix: String = ("  ·  [" + " + ".join(tags) + "]") if not tags.is_empty() else ""
	_phase_label.text = "%s → hour %d%s. Resolve Sector %d chain against enemy hour %d." % [view.relic.name, target_h, tag_suffix, active_quadrant, EnemyClockPattern.hour_for(target_h, _active_enemy())]
	_phase_label.text += "\n" + DecisionPreview.forecast(self, chain_hours, target_h, view.relic)
	_guidance.point_to(_player_chrono, _player_chrono.get_socket_view(target_h), chain_hours, "BIND HERE\n%d O'CLOCK" % target_h, view._art_rect, view._art_rect.texture)

func _preview_swap(socket: ClockSocketView) -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT or not socket.is_interactive or current_drawn_relic == null: return
	var previous := socket.data.slotted_relic.name if socket.data.slotted_relic else "empty slot"
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	var eval_info: Dictionary = DecisionPreview.evaluate_relic_on_hour(self, current_drawn_relic, socket.data.hour_index)
	var tags: Array = eval_info.get("active_tags", [])
	var tag_suffix: String = (" [" + " + ".join(tags) + "]") if not tags.is_empty() else ""
	_phase_label.text = "Hour %d: %s → %s%s. Old relic is discarded; sweep %d → %d → %d." % [socket.data.hour_index, previous, current_drawn_relic.name, tag_suffix, hours[0], hours[1], hours[2]]
	_phase_label.text += "\n" + DecisionPreview.forecast(self, hours, socket.data.hour_index, current_drawn_relic)
	var ped: RelicPedestalView = _pedestal_row.get_child(0)
	_guidance.point_to(_player_chrono, socket, hours, "REPLACE\n%d O'CLOCK" % socket.data.hour_index, ped._art_rect, ped._art_rect.texture)

func _preview_sweep() -> void:
	if _resolving or _combat_over or phase != Phase.QUADRANT: return
	var hours := ChronometerView.get_quadrant_hours(active_quadrant)
	_phase_label.text = "OVERCHARGE & KEEP YOUR CLOCK · Boost Hour %d (+0.25×) & +3 Overkill, then activate %d → %d → %d." % [hours[1], hours[0], hours[1], hours[2]]
	_phase_label.text += "\n" + DecisionPreview.forecast(self, hours)
	_guidance.point_to(_player_chrono, null, hours, "OVERCHARGE & SWEEP\n%d → %d → %d" % hours)

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
	var duration := 0.12 if AudioManager.reduced_motion else 0.38 / AudioManager.combat_animation_speed_scale()
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
	var tween := create_tween().set_speed_scale(AudioManager.combat_animation_speed_scale())
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
		view.create_tween().set_speed_scale(AudioManager.combat_animation_speed_scale()).tween_property(view, "modulate:a", 1.0, 0.28)
