extends Control
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

@onready var _panel: Panel = %Panel
@onready var _cost_label: Label = %CostLabel
@onready var _name_label: Label = %NameLabel
@onready var _art_rect: TextureRect = %ArtRect
@onready var _rules_text: RichTextLabel = %RulesText

var _card: CardData


func _ready() -> void:
	_panel.gui_input.connect(_on_panel_gui_input)


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(_card)


func set_card(card: CardData) -> void:
	_card = card
	_cost_label.text = "X" if card.energy_cost < 0 else str(card.energy_cost)
	_name_label.text = card.display_name
	_art_rect.texture = _load_art(card.art_id)
	_apply_rarity_frame(card.rarity)
	_rules_text.text = _build_rules_bbcode(card)


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


func _apply_rarity_frame(rarity: CardData.Rarity) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1c1c1e")
	style.border_color = RARITY_FRAME_COLORS.get(rarity, Color.WHITE)
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)


## Renders each effect as icon + exact number wherever KeywordRegistry has an
## entry; falls back to plain text only for effect types with no keyword yet.
func _build_rules_bbcode(card: CardData) -> String:
	var parts: PackedStringArray = []
	for effect in card.base_effects:
		parts.append(_effect_to_bbcode(effect))
	if not card.rules_text_override.is_empty():
		parts.append(card.rules_text_override)
	return " ".join(parts)


func _effect_to_bbcode(effect: EffectData) -> String:
	match effect.effect_type:
		EffectData.EffectType.DAMAGE:
			return "Deal %d damage." % effect.value
		EffectData.EffectType.BLOCK:
			return _keyword_bbcode("block", effect.value)
		EffectData.EffectType.APPLY_STATUS:
			return _keyword_bbcode(effect.status_id, effect.value)
		EffectData.EffectType.GAIN_OK:
			return _keyword_bbcode("overkill", effect.value)
		EffectData.EffectType.DRAW:
			return "Draw %d card(s)." % effect.value
		EffectData.EffectType.ENERGY_GAIN:
			return "Gain %d energy." % effect.value
		_:
			return ""


func _keyword_bbcode(keyword_id: String, value: int) -> String:
	var entry: KeywordEntry = KeywordRegistry.get_entry(keyword_id)
	if entry == null:
		push_warning("CardView: no KeywordRegistry entry for '%s' - add it before shipping this card." % keyword_id)
		return "%s %d." % [keyword_id.capitalize(), value]
	var icon_path := entry.icon_path()
	if ResourceLoader.exists(icon_path):
		return "[img=20x20]%s[/img] %s %d." % [icon_path, entry.label, value]
	return "%s %d." % [entry.label, value]
