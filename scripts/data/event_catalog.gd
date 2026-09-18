class_name EventCatalog extends RefCounted
## Placeholder event content, defined in code rather than as .tres files -
## same pattern TutorialCallout already uses for its CATALOG. Chosen because
## EventData.choices holds a custom RefCounted sub-type (EventChoice) that
## doesn't round-trip through Godot's text Resource format without the
## editor's Inspector to author it, and without editor access in this build
## environment, hand-writing that format is fragile for no real benefit at
## this content scope (1-2 placeholder events).

static func get_all_events() -> Array[EventData]:
	return [_greedy_shrine(), _cursed_offering()]


static func _greedy_shrine() -> EventData:
	var event := EventData.new()
	event.id = "greedy_shrine"
	event.title = "A Humming Shrine"
	event.body_text = "A cracked shard-shrine pulses with amber light. It seems to want a trade."
	var blood := EventData.EventChoice.new("Wind the shrine with your blood", "Lose 8 HP. Gain a Kinetic Battery for your clock.", EventData.ChoiceEffectType.GRANT_CLOCK_RELIC, 0, "", "REL-10")
	blood.hp_cost = 8
	var coins := EventData.EventChoice.new("Feed it excess energy", "Spend 15 Overkill. Gain a Heavy Hammer.", EventData.ChoiceEffectType.GRANT_CLOCK_RELIC, 0, "", "REL-03")
	coins.ok_cost = 15
	event.choices = [
		blood,
		coins,
		EventData.EventChoice.new("Walk away", "Nothing happens", EventData.ChoiceEffectType.OK_DELTA, 0),
	]
	return event


static func _cursed_offering() -> EventData:
	var event := EventData.new()
	event.id = "cursed_offering"
	event.title = "Overflowing Cache"
	event.body_text = "A shattered cache spills excess energy across the floor - free for the taking."
	event.choices = [
		EventData.EventChoice.new("Take the excess (+20 OK)", "Gain 20 OK", EventData.ChoiceEffectType.OK_DELTA, 20),
		EventData.EventChoice.new("Leave it be, rest a moment (+10 HP)", "Heal 10 HP", EventData.ChoiceEffectType.HP_DELTA, 10),
	]
	return event
