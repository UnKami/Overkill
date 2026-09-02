class_name IntentIcon extends Control
## IntentIcon - the ONLY place enemy intent is allowed to render. Bound
## directly to EnemyMoveData fields, no other script may independently render
## intent info in a different format. Icon system doc, Part 3.
##
## Fairness contract (data schema doc 1.2 / 2.2): this must show the exact
## intent_value before the player can act - no exceptions, even here in the
## minimal vertical slice.
##
## Dedicated intent-icon art (art doc Section E) doesn't exist yet. Falls
## back to a plain colored badge (color is still the spec's secondary
## reinforcement channel) until that art lands - swapping in real icons is a
## one-line change in _resolve_icon_path, not a rework of this component.

const INTENT_COLORS := {
	EnemyMoveData.IntentType.ATTACK: "#E24B4A",
	EnemyMoveData.IntentType.DEFEND: "#378ADD",
	EnemyMoveData.IntentType.BUFF: "#4CAF50",
	EnemyMoveData.IntentType.DEBUFF: "#9C4FDD",
	EnemyMoveData.IntentType.ATTACK_DEFEND: "#B37A6B",
	EnemyMoveData.IntentType.UNKNOWN: "#8A8A8A",
}

const INTENT_ICON_IDS := {
	EnemyMoveData.IntentType.ATTACK: "intent_attack",
	EnemyMoveData.IntentType.DEFEND: "intent_defend",
	EnemyMoveData.IntentType.BUFF: "intent_buff",
	EnemyMoveData.IntentType.DEBUFF: "intent_debuff",
	EnemyMoveData.IntentType.ATTACK_DEFEND: "intent_attack_defend",
	EnemyMoveData.IntentType.UNKNOWN: "intent_unknown",
}

## Non-numeric buffs/debuffs (e.g. "applies Weak" with no stacking choice)
## show the status icon in the badge position instead of a number - not
## modeled yet since no such move exists in this slice's content.
@onready var _icon_texture: TextureRect = %IconTexture
@onready var _badge_bg: Panel = %BadgeBackground
@onready var _value_label: Label = %ValueLabel
@onready var _multiplier_tag: Label = %MultiplierTag


func set_move(move: EnemyMoveData) -> void:
	var color := Color(INTENT_COLORS.get(move.intent_type, "#8A8A8A"))
	var icon_path := _resolve_icon_path(move.intent_type)

	if ResourceLoader.exists(icon_path):
		_icon_texture.texture = ResourceLoader.load(icon_path)
		_icon_texture.modulate = Color.WHITE
	else:
		_icon_texture.texture = null
		_icon_texture.modulate = color  # fallback tint until real intent art exists

	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	_badge_bg.add_theme_stylebox_override("panel", style)

	_value_label.text = str(move.intent_value)
	_multiplier_tag.visible = move.hit_count > 1
	_multiplier_tag.text = "x%d" % move.hit_count

	show_revealed()


func _resolve_icon_path(intent_type: EnemyMoveData.IntentType) -> String:
	return "res://assets/icons/ui/%s.png" % INTENT_ICON_IDS.get(intent_type, "intent_unknown")


## Revealed state (icon doc 3.2): full icon + value, static, shown before the
## player acts.
func show_revealed() -> void:
	modulate.a = 1.0
	scale = Vector2.ONE


## About-to-resolve state: brief pulse (150-250ms) drawing the eye to which
## enemy is acting now.
func play_about_to_resolve() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


## Resolved state: fades out after the move executes. Next turn's intent must
## be re-rolled before it appears again - never show a stale intent.
func play_resolved() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
