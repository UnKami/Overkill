class_name CardView extends Control
## CardView - renders a CardData through the keyword/icon system. Per the data
## schema doc's anti-dashboard rule (Part 0): never print card.effects as a
## debug string. Every effect renders through KeywordRegistry so it reads as
## icon + exact number, matching the "read in under 3 seconds" rule
## (data schema doc Part 2.1).
##
## Card frame art doesn't exist yet - the Panel's StyleBox is a flat
## programmatic stand-in per rarity until real frame templates are generated
## (art doc Section C). Swapping it for real art later is a one-line change
## in _apply_rarity_frame, not a rework of this script.

signal pressed(card: CardData)

const RARITY_FRAME_COLORS := {
	CardData.Rarity.COMMON: Color("#8a8a8a"),
	CardData.Rarity.UNCOMMON: Color("#c0c0c8"),
	CardData.Rarity.RARE: Color("#d4af37"),
	CardData.Rarity.EXCESS: Color("#EF9F27"),
}

const TYPE_BADGE_ICON_IDS := {
	CardData.CardType.ATTACK: "badge_attack",
	CardData.CardType.SKILL: "badge_skill",
	CardData.CardType.POWER: "badge_power",
}

const RARITY_GEM_ICON_IDS := {
	CardData.Rarity.COMMON: "rarity_common",
	CardData.Rarity.UNCOMMON: "rarity_uncommon",
	CardData.Rarity.RARE: "rarity_rare",
	CardData.Rarity.EXCESS: "rarity_excess",
}

const RARITY_FRAME_PATHS := {
	CardData.Rarity.COMMON: "res://assets/ui/cards/frame_common.png",
	CardData.Rarity.UNCOMMON: "res://assets/ui/cards/frame_uncommon.png",
	CardData.Rarity.RARE: "res://assets/ui/cards/frame_rare.png",
	CardData.Rarity.EXCESS: "res://assets/ui/cards/frame_excess.png",
}

const TYPE_NAMES := {
	CardData.CardType.ATTACK: "Attack",
	CardData.CardType.SKILL: "Skill",
	CardData.CardType.POWER: "Power",
}

const RARITY_NAMES := {
	CardData.Rarity.COMMON: "Common",
	CardData.Rarity.UNCOMMON: "Uncommon",
	CardData.Rarity.RARE: "Rare",
	CardData.Rarity.EXCESS: "Excess",
}

@onready var _hover_glow: TextureRect = %HoverGlow
@onready var _card_background: Panel = %CardBackground
@onready var _panel: Panel = %Panel
@onready var _cost_badge: Panel = %CostBadge
@onready var _cost_label: Label = %CostLabel
@onready var _name_label: Label = %NameLabel
@onready var _art_rect: TextureRect = %ArtRect
@onready var _rules_text: RichTextLabel = %RulesText
@onready var _type_badge: TextureRect = %TypeBadge
@onready var _rarity_gem: TextureRect = %RarityGem
@onready var _frame_overlay: TextureRect = %FrameOverlay

var _card: CardData
var _hover_tween: Tween = null
var _base_z_index: int = 0
var _background_style: StyleBoxFlat


func _ready() -> void:
	_panel.gui_input.connect(_on_panel_gui_input)
	# Fixed solid backing, independent of the frame overlay - the frame PNGs
	# are hollow-centered border decorations (transparent middle by design),
	# so without this the card had nothing behind its header/rules text once
	# real frame art replaced the old flat programmatic panel style.
	_background_style = StyleBoxFlat.new()
	_background_style.bg_color = Color("#141416")
	_background_style.set_corner_radius_all(10)
	_card_background.add_theme_stylebox_override("panel", _background_style)
	_style_cost_badge()
	_hover_glow.texture = AmbientMotion._get_glow_texture()

	pivot_offset = size * Vector2(0.5, 1.0)
	resized.connect(func() -> void: pivot_offset = size * Vector2(0.5, 1.0))
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Hover affordance (readability doc: hovering should always tell you
## something) - the card lifts and glows so it's unmistakable which card
## you're about to click, distinct from the flat "read the text" resting
## state. z_index bump keeps a grown card from rendering behind its
## neighbors in the hand row.
## Hover affordance - the card lifts upwards, scales, tilts straight,
## and flares its rarity glow so it feels tactile and reactive.
func _on_mouse_entered() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_base_z_index = z_index
	z_index = _base_z_index + 20
	pivot_offset = size * 0.5
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "position:y", -35.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_hover_glow, "modulate:a", 1.0, 0.14)


func _on_mouse_exited() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	pivot_offset = size * 0.5
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE)
	_hover_tween.tween_property(self, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
	var resting_glow: float = 0.32 if _card != null and _card.upgrade_level > 0 else 0.0
	_hover_tween.tween_property(_hover_glow, "modulate:a", resting_glow, 0.14)
	_hover_tween.chain().tween_callback(func() -> void: z_index = _base_z_index)


## Dynamic card play animation: swooshes from hand towards battlefield/target
## with an energy pulse and scaling dissolve.
func play_launch_animation(target_global_pos: Vector2) -> Signal:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = _base_z_index + 40
	pivot_offset = size * 0.5

	var tween := create_tween()
	# Punch up & flare
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.24, 1.24), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - 60.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hover_glow, "modulate:a", 1.5, 0.08)

	# Launch swoosh toward target destination
	var dir := (target_global_pos - global_position).normalized()
	var launch_offset := dir * 180.0
	tween.chain().set_parallel(true)
	tween.tween_property(self, "position", position + launch_offset, 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", deg_to_rad(clampf(dir.x * 15.0, -20.0, 20.0)), 0.18)
	tween.tween_property(self, "scale", Vector2(0.8, 1.2), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.14).set_delay(0.06)

	return tween.finished


## Classic deckbuilder "cost gem" - a bold circular badge overlapping the
## card's top-left corner, always visible regardless of rarity/frame art, so
## energy cost never gets lost in the header row next to the name.
func _style_cost_badge() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1B4F72")
	style.border_color = Color("#5DADE2")
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	_cost_badge.add_theme_stylebox_override("panel", style)
	_cost_label.add_theme_color_override("font_color", Color("#D6EAF8"))


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(_card)


func get_card() -> CardData:
	return _card


## `compare_against`: when set, any effect whose resolved value differs from
## the same-index effect on this CardData is highlighted blue - the "before
## vs after" upgrade-preview view (rest-site upgrade UI). Callers showing a
## card normally (hand, shop, deck view, reward) never pass this.
func set_card(card: CardData, compare_against: CardData = null) -> void:
	_card = card
	_cost_label.text = "X" if card.energy_cost < 0 else str(card.energy_cost)
	_cost_badge.tooltip_text = "Costs all remaining Energy to play." if card.energy_cost < 0 else "Costs %d Energy to play." % card.energy_cost
	_name_label.text = card.display_name + ("+" if card.upgrade_level > 0 else "")
	_art_rect.texture = _load_art(card.art_id)
	_apply_rarity_frame(card.rarity)
	_load_icon_if_present(_type_badge, TYPE_BADGE_ICON_IDS.get(card.card_type, ""))
	_load_icon_if_present(_rarity_gem, RARITY_GEM_ICON_IDS.get(card.rarity, ""))
	_type_badge.tooltip_text = TYPE_NAMES.get(card.card_type, "")
	_rarity_gem.tooltip_text = RARITY_NAMES.get(card.rarity, "")
	_rules_text.text = _build_rules_bbcode(card, compare_against)
	var glow_color: Color = RARITY_FRAME_COLORS.get(card.rarity, Color.WHITE)
	var resting_glow: float = 0.32 if card.upgrade_level > 0 else 0.0
	_hover_glow.modulate = Color(ScreenDesign.GOLD if card.upgrade_level > 0 else glow_color, resting_glow)
	if _background_style != null:
		_background_style.border_color = ScreenDesign.GOLD if card.upgrade_level > 0 else Color.TRANSPARENT
		_background_style.set_border_width_all(3 if card.upgrade_level > 0 else 0)
	tooltip_text = ("UPGRADED  ·  " if card.upgrade_level > 0 else "") + card.display_name


func play_upgrade_animation(upgraded_card: CardData) -> void:
	if _hover_tween != null and _hover_tween.is_valid(): _hover_tween.kill()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = _base_z_index + 60
	pivot_offset = size * 0.5
	var flare := _hover_glow
	var windup := create_tween().set_parallel(true)
	windup.tween_property(self, "scale", Vector2(1.22, 1.22), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	windup.tween_property(self, "rotation", deg_to_rad(-2.5), 0.10).set_trans(Tween.TRANS_CUBIC)
	windup.tween_property(flare, "modulate", Color(1.45, 1.12, 0.42, 1.0), 0.18)
	await windup.finished
	set_card(upgraded_card)
	rotation = deg_to_rad(2.0)
	var settle := create_tween().set_parallel(true)
	settle.tween_property(self, "scale", Vector2(1.06, 1.06), 0.30).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	settle.tween_property(self, "rotation", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle.tween_property(flare, "modulate", Color(ScreenDesign.GOLD, 0.42), 0.30)
	await settle.finished


## Same "load if present, else leave blank" convention as CombatHUD - lets
## icons drop in without a code change once the matching PNG exists on disk.
func _load_icon_if_present(rect: TextureRect, icon_id: String) -> void:
	if icon_id.is_empty():
		return
	var path := "res://assets/icons/ui/%s.png" % icon_id
	if ResourceLoader.exists(path):
		rect.texture = ResourceLoader.load(path)


func _load_art(art_id: String) -> Texture2D:
	# Art lives under a category subfolder per the art doc's naming convention;
	# card art specifically resolves under /assets/cards/.
	var candidates := [
		"res://assets/cards/%s.png" % art_id,
		"res://assets/cards/executioner/%s.png" % art_id,
		"res://assets/cards/excess/%s.png" % art_id,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return ResourceLoader.load(path)
	return null


## Real frame art (art doc Section C) takes over when present; the flat
## programmatic border stays as the fallback for any rarity that isn't
## drawn yet, so a card is never framed in mismatched styles at once.
func _apply_rarity_frame(rarity: CardData.Rarity) -> void:
	var frame_path: String = RARITY_FRAME_PATHS.get(rarity, "")
	if not frame_path.is_empty() and ResourceLoader.exists(frame_path):
		_frame_overlay.texture = ResourceLoader.load(frame_path)
		_frame_overlay.show()
		_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		return
	_frame_overlay.hide()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1c1c1e")
	style.border_color = RARITY_FRAME_COLORS.get(rarity, Color.WHITE)
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)


## Renders each effect as icon + exact number wherever KeywordRegistry has an
## entry; falls back to plain text only for effect types with no keyword yet.
## `compare_against`: same-index effect on the pre-upgrade card - any line
## whose resolved value differs gets wrapped in blue (upgrade-preview mode).
func _build_rules_bbcode(card: CardData, compare_against: CardData = null) -> String:
	var effects: Array[EffectData] = card.base_effects
	if card.upgrade_level > 0 and not card.upgraded_effects.is_empty():
		effects = card.upgraded_effects
	var baseline: Array[EffectData] = []
	if compare_against != null:
		baseline = compare_against.base_effects

	var parts: PackedStringArray = []
	for i in effects.size():
		var effect := effects[i]
		var line := _effect_to_bbcode(effect)
		if line.is_empty():
			continue
		if i < baseline.size() and (effect.value != baseline[i].value or effect.value_multiplier != baseline[i].value_multiplier):
			line = "[color=#5DADE2][b]%s[/b][/color]" % line
		parts.append(line)
	if not card.rules_text_override.is_empty():
		parts.append(card.rules_text_override)
	return " ".join(parts)


func _effect_to_bbcode(effect: EffectData) -> String:
	match effect.effect_type:
		EffectData.EffectType.DAMAGE:
			var line := _damage_bbcode(effect)
			if _card_has_spillage():
				line += " " + _keyword_flag_bbcode("spillage")
			return line
		EffectData.EffectType.BLOCK:
			return _keyword_bbcode("block", effect.value)
		EffectData.EffectType.APPLY_STATUS:
			return _keyword_bbcode(effect.status_id, effect.value)
		EffectData.EffectType.GAIN_OK:
			return _keyword_bbcode("overkill", effect.value)
		EffectData.EffectType.DRAW:
			return "Draw %d card(s)." % effect.value
		EffectData.EffectType.ENERGY_GAIN:
			return _energy_gain_bbcode(effect)
		EffectData.EffectType.LOSE_HP:
			return _keyword_bbcode("lose_hp", effect.value)
		EffectData.EffectType.APPLY_SPILLAGE:
			return ""  # rendered as a suffix on the DAMAGE line above, not its own line
		_:
			return ""


## Card-face numbers must be the actual current numbers, never a base value
## the player has to mentally adjust (data schema doc 2.1) - for a
## non-FIXED value_source that means resolving against live OKRunState here,
## the same way combat_controller's _resolve_value() does for real combat.
## ENERGY_SPENT_ON_PLAY is the one exception: X isn't chosen until the card
## is played, so that renders as a per-X rate instead of a live number.
func _damage_bbcode(effect: EffectData) -> String:
	match effect.value_source:
		EffectData.ValueSource.LAST_KILL_OK:
			var resolved: int = int(floor(OKRunState.last_kill_ok * effect.value_multiplier))
			return "Deal %d damage (%d%% of your last kill's Overkill)." % [resolved, int(effect.value_multiplier * 100)]
		EffectData.ValueSource.ENERGY_SPENT_ON_PLAY:
			return "Deal %d damage per Energy spent." % int(effect.value_multiplier)
		_:
			return "Deal %d damage." % effect.value


func _energy_gain_bbcode(effect: EffectData) -> String:
	if effect.value_source == EffectData.ValueSource.LAST_KILL_OK:
		var resolved: int = int(floor(OKRunState.last_kill_ok * effect.value_multiplier))
		return "Refund %d Energy (from your last kill)." % resolved
	return "Gain %d energy." % effect.value


## Like _keyword_bbcode() but for a boolean flag keyword (Spillage) with no
## stack count to print alongside it.
func _keyword_flag_bbcode(keyword_id: String) -> String:
	var entry: KeywordEntry = KeywordRegistry.get_entry(keyword_id)
	if entry == null:
		push_warning("CardView: no KeywordRegistry entry for '%s' - add it before shipping this card." % keyword_id)
		return keyword_id.capitalize() + "."
	var label_text := _hinted_label(entry)
	var icon_path := entry.icon_path()
	if ResourceLoader.exists(icon_path):
		return "[img=20x20]%s[/img] %s." % [icon_path, label_text]
	return "%s." % label_text


## Every keyword that has a plain-language definition gets it as a hover
## tooltip on its own label text (RichTextLabel's built-in [hint] tag) - the
## rule from the polish pass: nothing on a card should require the player to
## already know what it means. Keywords without one yet (none currently)
## just render as plain, undecorated text.
func _hinted_label(entry: KeywordEntry) -> String:
	if entry.definition.is_empty():
		return entry.label
	return "[hint=%s]%s[/hint]" % [entry.definition, entry.label]


func _card_has_spillage() -> bool:
	var effects: Array[EffectData] = _card.base_effects
	if _card.upgrade_level > 0 and not _card.upgraded_effects.is_empty():
		effects = _card.upgraded_effects
	for effect in effects:
		if effect.effect_type == EffectData.EffectType.APPLY_SPILLAGE:
			return true
	return false


func _keyword_bbcode(keyword_id: String, value: int) -> String:
	var entry: KeywordEntry = KeywordRegistry.get_entry(keyword_id)
	if entry == null:
		push_warning("CardView: no KeywordRegistry entry for '%s' - add it before shipping this card." % keyword_id)
		return "%s %d." % [keyword_id.capitalize(), value]
	var label_text := _hinted_label(entry)
	var icon_path := entry.icon_path()
	if ResourceLoader.exists(icon_path):
		return "[img=20x20]%s[/img] %s %d." % [icon_path, label_text, value]
	return "%s %d." % [label_text, value]
