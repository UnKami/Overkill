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

var _active_tween: Tween = null


const INTENT_NAMES := {
	EnemyMoveData.IntentType.ATTACK: "Attack",
	EnemyMoveData.IntentType.DEFEND: "Defend",
	EnemyMoveData.IntentType.BUFF: "Buff",
	EnemyMoveData.IntentType.DEBUFF: "Debuff",
	EnemyMoveData.IntentType.ATTACK_DEFEND: "Attack + Defend",
	EnemyMoveData.IntentType.UNKNOWN: "Unknown",
}


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
	tooltip_text = _build_tooltip(move)

	show_revealed()


## Hover explanation (always available, per the "everything has a tooltip"
## rule) - spells out exactly what this move does in plain language, not
## just icon+number, since the icon/color/number combo is a lot to parse at
## a glance for a first-time player.
func _build_tooltip(move: EnemyMoveData) -> String:
	var intent_name: String = INTENT_NAMES.get(move.intent_type, "Unknown")
	var hits_suffix: String = " (x%d hits)" % move.hit_count if move.hit_count > 1 else ""
	match move.intent_type:
		EnemyMoveData.IntentType.ATTACK:
			return "%s: will deal %d damage%s next turn." % [intent_name, move.intent_value, hits_suffix]
		EnemyMoveData.IntentType.DEFEND:
			return "%s: will gain %d Block next turn." % [intent_name, move.intent_value]
		EnemyMoveData.IntentType.ATTACK_DEFEND:
			return "%s: will deal %d damage%s and gain Block next turn." % [intent_name, move.intent_value, hits_suffix]
		EnemyMoveData.IntentType.BUFF:
			return "%s: will strengthen itself next turn." % intent_name
		EnemyMoveData.IntentType.DEBUFF:
			return "%s: will weaken you next turn." % intent_name
		_:
			return "%s: this enemy's next move can't be read." % intent_name


func _resolve_icon_path(intent_type: EnemyMoveData.IntentType) -> String:
	return "res://assets/icons/ui/%s.png" % INTENT_ICON_IDS.get(intent_type, "intent_unknown")


## Revealed state (icon doc 3.2): full icon + value, static, shown before the
## player acts. Kills any in-flight fade/pulse tween first - without this, a
## still-running play_resolved() fade-to-0 tween would win the next frame and
## silently override this reset, leaving intent invisible from round 2 on
## (confirmed real bug: the async tween outlived the synchronous reset).
func show_revealed() -> void:
	_kill_active_tween()
	modulate.a = 1.0
	scale = Vector2.ONE


## About-to-resolve state: brief pulse (150-250ms) drawing the eye to which
## enemy is acting now.
func play_about_to_resolve() -> void:
	_kill_active_tween()
	modulate.a = 1.0
	scale = Vector2.ONE
	_active_tween = create_tween()
	_active_tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	_active_tween.tween_property(self, "scale", Vector2.ONE, 0.1)


## Resolved state: fades out after the move executes. Next turn's intent must
## be re-rolled before it appears again - never show a stale intent.
func play_resolved() -> void:
	_kill_active_tween()
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate:a", 0.0, 0.25)


func _kill_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
