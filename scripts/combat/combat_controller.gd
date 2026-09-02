extends Control
## Combat loop wiring - the "does it feel like a game" checkpoint (data
## schema doc Part 4, step 4). Draw -> play -> resolve -> OK -> HUD, with the
## split damage numbers, staggered feedback priority, and first-OK tutorial
## callout all live here.

const CardViewScene := preload("res://scenes/card_view.tscn")
const DamageNumberScene := preload("res://scenes/damage_number.tscn")

@export var enemy_data: EnemyData
@export var starting_deck: Array[CardData] = []
@export var relics: Array[RelicData] = []

@export var background_id: String = "env_crypt_bastion"

@onready var _hud: CombatHUD = $HUD
@onready var _hand_container: HBoxContainer = $HandContainer
@onready var _end_turn_button: Button = $EndTurnButton
@onready var _background: TextureRect = $Background
@onready var _enemy_sprite: TextureRect = $EnemySprite
@onready var _enemy_intent: IntentIcon = $EnemySprite/IntentIcon
@onready var _enemy_hp_label: Label = $EnemySprite/HPLabel
@onready var _feedback_queue: FeedbackQueue = $FeedbackQueue
@onready var _relic_bar: HBoxContainer = $RelicBar

var player: PlayerState
var enemy: EnemyInstance
var _combat_over: bool = false
var _relic_icons: Dictionary = {}  # RelicData.id -> RelicIcon


func _ready() -> void:
	_load_background_art()

	player = PlayerState.new()
	add_child(player)
	_hud.bind_player(player)

	enemy = EnemyInstance.new(enemy_data)
	add_child(enemy)
	enemy.hp_changed.connect(_on_enemy_hp_changed)
	enemy.move_revealed.connect(_enemy_intent.set_move)
	_on_enemy_hp_changed(enemy.current_hp, enemy.max_hp)
	_load_enemy_art()
	_enemy_intent.set_move(enemy.current_move)  # fairness contract: visible before player acts

	player.hand_changed.connect(_rebuild_hand_view)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)

	_setup_relics()

	player.setup_deck(starting_deck)
	player.start_turn()


## Relic bar (screen composition doc Part 2.1): icon-only, stable acquisition
## order, tooltip auto-rendered from data (RelicIcon owns that rule).
func _setup_relics() -> void:
	for relic_data in relics:
		var icon := RelicIcon.new()
		icon.custom_minimum_size = Vector2(40, 40)
		_relic_bar.add_child(icon)
		icon.relic = relic_data
		_relic_icons[relic_data.id] = icon


func _load_background_art() -> void:
	var path := "res://assets/environments/act1/%s.png" % background_id
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)


func _load_enemy_art() -> void:
	var path := "res://assets/enemies/act1/%s.png" % enemy_data.art_id
	if ResourceLoader.exists(path):
		_enemy_sprite.texture = ResourceLoader.load(path)


func _on_enemy_hp_changed(current: int, max_hp: int) -> void:
	_enemy_hp_label.text = "%d/%d" % [current, max_hp]


func _rebuild_hand_view(hand: Array) -> void:
	for child in _hand_container.get_children():
		child.queue_free()
	for card in hand:
		var view := CardViewScene.instantiate()
		_hand_container.add_child(view)
		view.set_card(card)
		view.pressed.connect(_on_card_pressed)


func _on_card_pressed(card: CardData) -> void:
	if _combat_over:
		return
	if not player.can_afford(card):
		return
	player.spend_energy(card.energy_cost)
	player.play_card(card)  # moves card hand -> discard, emits hand_changed (rebuilds view)
	await _resolve_effects(card.base_effects)


func _resolve_effects(effects: Array[EffectData]) -> void:
	for effect in effects:
		match effect.effect_type:
			EffectData.EffectType.DAMAGE:
				await _apply_damage_to_enemy(effect.value)
			EffectData.EffectType.BLOCK:
				player.gain_block(effect.value)
			EffectData.EffectType.DRAW:
				player.draw_extra(effect.value)
			EffectData.EffectType.ENERGY_GAIN:
				player.energy += effect.value
			EffectData.EffectType.APPLY_STATUS:
				push_warning("combat_controller: APPLY_STATUS not implemented in this vertical slice yet.")
			EffectData.EffectType.GAIN_OK:
				OKRunState.gain_ok(effect.value, "card")


func _apply_damage_to_enemy(raw_damage: int) -> void:
	if enemy.is_dead():
		return
	var result: Dictionary = enemy.apply_damage(raw_damage)
	var needed: int = result.needed
	var overkill: int = result.overkill

	var batch: Array = []
	batch.append({
		"priority": FeedbackQueue.Priority.PLAYER_STAT,
		"action": func() -> void: _spawn_damage_number(needed, false),
	})
	if overkill > 0:
		batch.append({
			"priority": FeedbackQueue.Priority.OVERKILL,
			"action": func() -> void:
				_spawn_damage_number(overkill, true)
				OKRunState.gain_ok(overkill, "combat:%s" % enemy.data.id, overkill)
				TutorialCallout.trigger("first_ok"),
		})
		# Relic/status triggers always queue at the lowest priority (screen
		# composition doc 1.2) - a relic firing must never upstage the kill
		# that triggered it.
		for relic_data in relics:
			if relic_data.trigger == RelicData.Trigger.ON_OVERKILL and overkill >= int(relic_data.condition_data.get("min_ok", 0)):
				batch.append({
					"priority": FeedbackQueue.Priority.RELIC_STATUS,
					"action": func() -> void: _fire_relic(relic_data),
				})
	await _feedback_queue.fire_batch(batch)

	if enemy.is_dead():
		_on_enemy_defeated()


func _fire_relic(relic_data: RelicData) -> void:
	for effect in relic_data.effects:
		match effect.effect_type:
			EffectData.EffectType.GAIN_OK:
				OKRunState.gain_ok(effect.value, "relic:%s" % relic_data.id)
			EffectData.EffectType.BLOCK:
				player.gain_block(effect.value)
			_:
				pass  # other relic effect types not needed by this vertical slice
	var icon: RelicIcon = _relic_icons.get(relic_data.id)
	if icon:
		icon.play_trigger_flash()


func _spawn_damage_number(value: int, is_overkill: bool) -> void:
	var number := DamageNumberScene.instantiate()
	_enemy_sprite.add_child(number)
	number.position = _enemy_sprite.size * 0.5 + Vector2(randf_range(-20, 20), -20)
	number.setup(value, is_overkill)


func _on_enemy_defeated() -> void:
	_combat_over = true
	_end_turn_button.disabled = true
	for child in _hand_container.get_children():
		child.get_node("Panel").mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_end_turn_pressed() -> void:
	if _combat_over:
		return
	player.end_turn()
	await _enemy_turn()
	if not _combat_over:
		player.start_turn()


func _enemy_turn() -> void:
	var move: EnemyMoveData = enemy.current_move
	await _feedback_queue.fire_batch([{
		"priority": FeedbackQueue.Priority.INTENT,
		"action": func() -> void: _enemy_intent.play_about_to_resolve(),
	}])
	await get_tree().create_timer(0.2).timeout

	for effect in move.effects:
		if effect.effect_type == EffectData.EffectType.DAMAGE:
			player.take_damage(effect.value)

	_enemy_intent.play_resolved()

	if player.is_dead():
		_combat_over = true
		_end_turn_button.disabled = true
		return

	enemy.roll_next_move()  # re-rolled and shown before the player's next turn - fairness contract
