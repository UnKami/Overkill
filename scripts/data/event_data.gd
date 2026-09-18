class_name EventData extends Resource
## Minimal event-node content: a body of text and 2-4 choices. Each choice is
## a flat effect (HP delta, OK delta, or a specific card id granted) rather
## than a general effect list - event-node content authoring is intentionally
## kept simple for this pass (screen-flow completeness, not narrative depth).

enum ChoiceEffectType { HP_DELTA, OK_DELTA, GRANT_CARD, GRANT_RELIC, GRANT_CLOCK_RELIC }

class EventChoice:
	var label: String = ""
	var consequence_summary: String = ""
	var effect_type: ChoiceEffectType = ChoiceEffectType.HP_DELTA
	var value: int = 0
	var card_id: String = ""
	var relic_id: String = ""
	var hp_cost: int = 0
	var ok_cost: int = 0

	func _init(p_label: String = "", p_summary: String = "", p_effect_type: ChoiceEffectType = ChoiceEffectType.HP_DELTA, p_value: int = 0, p_card_id: String = "", p_relic_id: String = "") -> void:
		label = p_label
		consequence_summary = p_summary
		effect_type = p_effect_type
		value = p_value
		card_id = p_card_id
		relic_id = p_relic_id

@export var id: String = ""
@export var title: String = ""
@export_multiline var body_text: String = ""
@export var art_id: String = ""

var choices: Array[EventChoice] = []
