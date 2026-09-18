class_name EnemySlot extends TextureRect
## One enemy's on-screen slot: sprite + intent icon + HP label + click-to-
## target highlight. combat_controller instances one of these per living
## enemy into the EnemyRow container, left to right - this row order is what
## Spillage's "next enemy" rule anchors to (data schema doc 1.6). Extracted
## from what used to be the single static EnemySprite node in combat_scene.

signal pressed(slot: EnemySlot)

@onready var _intent_icon: IntentIcon = $IntentIcon
@onready var _hp_label: Label = $HPLabel
@onready var _target_highlight: Panel = $TargetHighlight

var enemy: EnemyInstance
var _targetable: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "The enemy. Hover its intent icon above to see what it's about to do."
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color("#F2C744")
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	_target_highlight.add_theme_stylebox_override("panel", style)
	_target_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_highlight.hide()


func bind(enemy_instance: EnemyInstance) -> void:
	enemy = enemy_instance
	enemy.hp_changed.connect(_on_hp_changed)
	enemy.move_revealed.connect(_intent_icon.set_move)
	_on_hp_changed(enemy.current_hp, enemy.max_hp)
	_intent_icon.set_move(enemy.current_move)


func _on_hp_changed(current: int, max_hp: int) -> void:
	_hp_label.text = "%d/%d" % [current, max_hp]


func play_about_to_resolve() -> void:
	_intent_icon.play_about_to_resolve()


func play_resolved() -> void:
	_intent_icon.play_resolved()


## The visible "you just hit this enemy" beat - every landed hit, not just
## the big Overkill ones (which additionally get the screen shake).
func play_hit_flash() -> void:
	AmbientMotion.flash(self, Color(2.0, 0.8, 0.8), 0.18)
	play_knockback(Vector2.RIGHT, 22.0)


## Kinetic recoil knockback when struck by attacks.
func play_knockback(direction: Vector2 = Vector2.RIGHT, distance: float = 22.0) -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	# Fast punch in impact direction with slight squash/tilt
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + direction * distance, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(randf_range(3.0, 7.0)), 0.08)
	tween.tween_property(self, "scale", Vector2(0.9, 1.1), 0.08)
	# Elastic spring recovery
	tween.chain().set_parallel(true)
	tween.tween_property(self, "position", position, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Lunge forward when attacking the player.
func play_attack_lunge(target_global_pos: Vector2) -> Tween:
	pivot_offset = size * 0.5
	var origin := position
	var dir := (target_global_pos - global_position).normalized()
	var lunge_dist := 75.0

	var tween := create_tween()
	# Anticipation wind-up: lean back
	tween.set_parallel(true)
	tween.tween_property(self, "position", origin - dir * 25.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.92, 1.08), 0.12)
	# Rapid forward thrust strike
	tween.chain().set_parallel(true)
	tween.tween_property(self, "position", origin + dir * lunge_dist, 0.13).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.18, 0.88), 0.13)
	# Recovery return
	tween.chain().set_parallel(true)
	tween.tween_property(self, "position", origin, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_SINE)
	return tween


## Violent crystalline disintegration when killed via Overkill.
func play_death_shatter() -> Signal:
	pivot_offset = size * 0.5
	var tween := create_tween()
	# Hit-flash whiteout + violent jitter
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(2.5, 2.2, 1.8), 0.08)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Disintegration fade + shatter outward
	tween.chain().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.18).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(hide)
	return tween.finished


## Subtle idle breathing loop that operates on scale so it never fights HBoxContainer.
func start_idle_breathe(delay: float = 0.0) -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector2(0.985, 1.025), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.015, 0.985), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Yellow border + click-to-select, only ever shown while the player is
## choosing a target for a single-target card with more than one enemy
## alive - see combat_controller._begin_targeting().
func set_targetable(value: bool) -> void:
	_targetable = value
	_target_highlight.visible = value


func _gui_input(event: InputEvent) -> void:
	if not _targetable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(self)
