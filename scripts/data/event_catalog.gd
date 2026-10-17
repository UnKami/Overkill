class_name EventCatalog extends RefCounted
## Placeholder event content, defined in code rather than as .tres files -
## same pattern TutorialCallout already uses for its CATALOG. Chosen because
## EventData.choices holds a custom RefCounted sub-type (EventChoice) that
## doesn't round-trip through Godot's text Resource format without the
## editor's Inspector to author it, and without editor access in this build
## environment, hand-writing that format is fragile for no real benefit at
## this content scope (1-2 placeholder events).

static func get_all_events() -> Array[EventData]:
	return [
		_greedy_shrine(),
		_cursed_offering(),
		_clockwright_anvil(),
		_crimson_alembic(),
		_paradox_mirror(),
		_hollow_reliquary(),
	]


static func _greedy_shrine() -> EventData:
	var event := EventData.new()
	event.id = "greedy_shrine"
	event.title = "A Humming Shrine"
	event.body_text = "A cracked shard-shrine pulses with amber light, its brass conduits starving for a catalyst. It seems to want a trade."
	var blood := EventData.EventChoice.new(
		"Wind the shrine with your blood (-10 HP)",
		"Lose 10 HP. Gain a Kinetic Battery (REL-10). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-10"
	)
	blood.hp_cost = 10
	var coins := EventData.EventChoice.new(
		"Feed it excess energy (-15 OK)",
		"Spend 15 Overkill. Gain a Heavy Hammer (REL-03). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-03"
	)
	coins.ok_cost = 15
	event.choices = [
		blood,
		coins,
		EventData.EventChoice.new("Walk away", "Leave the shrine untouched.", EventData.ChoiceEffectType.OK_DELTA, 0),
	]
	return event


static func _cursed_offering() -> EventData:
	var event := EventData.new()
	event.id = "cursed_offering"
	event.title = "The Blood Pendulum"
	event.body_text = "Arazor-edged pendulum swings above an obsidian basin, counting hours in spilled vitality and condensed Overkill."
	var blood_ok := EventData.EventChoice.new(
		"Let the blade graze your palm (-12 HP)",
		"Lose 12 HP. Gain 28 Overkill.",
		EventData.ChoiceEffectType.OK_DELTA,
		28
	)
	blood_ok.hp_cost = 12
	var needle := EventData.EventChoice.new(
		"Seize the Rupture Needle (-8 HP)",
		"Lose 8 HP. Gain a Rupture Needle (REL-23). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-23"
	)
	needle.hp_cost = 8
	event.choices = [
		blood_ok,
		needle,
		EventData.EventChoice.new("Steady your breathing (+12 HP)", "Heal 12 HP.", EventData.ChoiceEffectType.HP_DELTA, 12),
	]
	return event


static func _clockwright_anvil() -> EventData:
	var event := EventData.new()
	event.id = "clockwright_anvil"
	event.title = "Abandoned Clockwright Anvil"
	event.body_text = "Embers still glow beneath a master clockwright's tempering anvil. Unfinished gears and plating tools lie within reach."
	var upgrade_choice := EventData.EventChoice.new(
		"Strike the anvil (Upgrade a random relic)",
		"Upgrade a random unupgraded relic in your chronometer for free.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"UPGRADE_RANDOM"
	)
	var reinforce := EventData.EventChoice.new(
		"Bolt spare plates to your frame (-12 OK)",
		"Spend 12 Overkill. Gain +10 Max HP (and heal 10 HP).",
		EventData.ChoiceEffectType.HP_DELTA,
		10,
		"MAX_HP"
	)
	reinforce.ok_cost = 12
	event.choices = [
		upgrade_choice,
		reinforce,
		EventData.EventChoice.new("Salvage the loose gears (+14 OK)", "Gain 14 Overkill.", EventData.ChoiceEffectType.OK_DELTA, 14),
	]
	return event


static func _crimson_alembic() -> EventData:
	var event := EventData.new()
	event.id = "crimson_alembic"
	event.title = "The Crimson Alembic"
	event.body_text = "Coils of stained glass distill caustic oils and royal gilding from the tower's lower furnaces."
	var oil := EventData.EventChoice.new(
		"Draw a vial of Corrosive Oil (-8 HP)",
		"Lose 8 HP. Gain a Corrosive Oil (REL-09). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-09"
	)
	oil.hp_cost = 8
	var crown := EventData.EventChoice.new(
		"Condense the gilded condensate (-18 OK)",
		"Spend 18 Overkill. Gain a War Crown (REL-16). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-16"
	)
	crown.ok_cost = 18
	event.choices = [
		oil,
		crown,
		EventData.EventChoice.new("Drink the warm dregs (+10 HP)", "Heal 10 HP.", EventData.ChoiceEffectType.HP_DELTA, 10),
	]
	return event


static func _paradox_mirror() -> EventData:
	var event := EventData.new()
	event.id = "paradox_mirror"
	event.title = "Mirror of Hours"
	event.body_text = "A tall mercury glass reflects your chronometer running backward. Reaching through the silvered surface costs something permanent."
	var prism := EventData.EventChoice.new(
		"Shatter the reflection (-10 HP)",
		"Lose 10 HP. Gain a Siege Prism (REL-24). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-24"
	)
	prism.hp_cost = 10
	var sacrifice := EventData.EventChoice.new(
		"Trade a piece of your frame (-6 Max HP)",
		"Sacrifice 6 Max HP. Gain 30 Overkill.",
		EventData.ChoiceEffectType.OK_DELTA,
		30,
		"MAX_HP_COST"
	)
	sacrifice.hp_cost = 6
	event.choices = [
		prism,
		sacrifice,
		EventData.EventChoice.new("Step back from the glass", "Nothing happens.", EventData.ChoiceEffectType.OK_DELTA, 0),
	]
	return event


static func _hollow_reliquary() -> EventData:
	var event := EventData.new()
	event.id = "hollow_reliquary"
	event.title = "The Hollow Reliquary"
	event.body_text = "An iron reliquary stands ajar, its counting beads still clicking in the dark. A toll of Overkill will release its centerpiece."
	var abacus := EventData.EventChoice.new(
		"Pay the reliquary's toll (-15 OK)",
		"Spend 15 Overkill. Gain a Butcher's Abacus (REL-19). Replaces a basic relic if at 12/12.",
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC,
		0,
		"",
		"REL-19"
	)
	abacus.ok_cost = 15
	event.choices = [
		abacus,
		EventData.EventChoice.new("Pry out the residual sparks (+15 OK)", "Gain 15 Overkill.", EventData.ChoiceEffectType.OK_DELTA, 15),
		EventData.EventChoice.new("Leave undisturbed", "Nothing happens.", EventData.ChoiceEffectType.OK_DELTA, 0),
	]
	return event
