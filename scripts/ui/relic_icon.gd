class_name RelicIcon extends TextureRect
## Relic bar entry - icon only at rest (screen composition doc, Part 2.1).
## Tooltip text is generated FROM condition_data/effects, never hand-written
## separately from the data driving actual behavior (data schema doc, Part
## 2.4) - this is the single most important rule for relics per that doc.

@export var relic: RelicData:
	set(value):
		relic = value
		if relic:
			_apply_relic()


func _apply_relic() -> void:
	var path := "res://assets/relics/%s.png" % relic.art_id
	texture = ResourceLoader.load(path) if ResourceLoader.exists(path) else null
	tooltip_text = _render_tooltip(relic)


func _render_tooltip(r: RelicData) -> String:
	return "%s\n%s\n%s" % [r.display_name, _trigger_sentence(r), r.flavor_text]


func _trigger_sentence(r: RelicData) -> String:
	var trigger_text: String = _condition_to_text(r.trigger, r.condition_data)
	var effect_text: String = " ".join(r.effects.map(_effect_to_text))
	return "%s %s" % [trigger_text, effect_text]


func _condition_to_text(trigger: RelicData.Trigger, condition_data: Dictionary) -> String:
	match trigger:
		RelicData.Trigger.ON_OVERKILL:
			if condition_data.has("min_ok"):
				return "Triggers when you Overkill by %d or more." % int(condition_data["min_ok"])
			return "Triggers on any Overkill."
		RelicData.Trigger.ON_KILL:
			return "Triggers on kill."
		RelicData.Trigger.ON_TURN_START:
			return "Triggers at the start of your turn."
		RelicData.Trigger.ON_TURN_END:
			return "Triggers at the end of your turn."
		RelicData.Trigger.ON_COMBAT_START:
			return "Triggers at the start of combat."
		RelicData.Trigger.ON_CARD_PLAYED:
			return "Triggers when you play a card."
		_:
			return "Always active."


func _effect_to_text(effect: EffectData) -> String:
	match effect.effect_type:
		EffectData.EffectType.GAIN_OK:
			return "Gain %d Overkill." % effect.value
		EffectData.EffectType.BLOCK:
			return "Gain %d Block." % effect.value
		EffectData.EffectType.DAMAGE:
			return "Deal %d damage." % effect.value
		EffectData.EffectType.DRAW:
			return "Draw %d card(s)." % effect.value
		EffectData.EffectType.ENERGY_GAIN:
			return "Gain %d energy." % effect.value
		_:
			return ""


## On-trigger flash (screen composition doc, Part 2.1) - lower-intensity than
## the Overkill feedback pulse, so a relic firing never upstages the kill
## that triggered it.
func play_trigger_flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.6, 1.6, 1.2), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
