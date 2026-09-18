extends Control
## Shared choice-presentation component driving placeholder event content
## (map-generation/audio doc Part 3.2): body text, 2-4 choice buttons with
## consequence summaries. Any resource change routes through the same
## RunManager/OKRunState methods everything else uses - no bespoke treatment.

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: RichTextLabel = %BodyLabel
@onready var _choice_box: VBoxContainer = %ChoiceBox
@onready var _panel: PanelContainer = %Panel
@onready var _background: TextureRect = %Background

var _event: EventData
var _resolved: bool = false


func set_event(event: EventData) -> void:
	_event = event


func _ready() -> void:
	if _event == null:
		GameFlow.goto_map()
		return
	_title_label.text = _event.title
	_body_label.text = _event.body_text
	for choice in _event.choices:
		var button := Button.new()
		button.text = "%s\n[%s]" % [choice.label, choice.consequence_summary]
		button.disabled = RunManager.current_hp <= choice.hp_cost or OKRunState.current_ok < choice.ok_cost
		button.pressed.connect(func() -> void: _on_choice_pressed(choice))
		_choice_box.add_child(button)
	_load_background()
	# Arriving at an event is a small "something is happening" beat - a
	# quick reveal punch on the panel, then it settles into idle purple
	# embers for the mystery/read-carefully mood while the player decides.
	AmbientMotion.punch_scale(_panel, 1.06, 0.3)
	AmbientMotion.spawn_embers(self, Color(0.75, 0.55, 0.95, 0.45), 10, true)


func _load_background() -> void:
	var path := "res://assets/screens/event_bg.jpg"
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		AmbientMotion.apply_ken_burns(_background, 45.0, 0.02)


func _on_choice_pressed(choice: EventData.EventChoice) -> void:
	if _resolved or RunManager.current_hp <= choice.hp_cost or OKRunState.current_ok < choice.ok_cost: return
	_resolved = true
	if choice.hp_cost > 0: RunManager.apply_run_hp_change(-choice.hp_cost)
	if choice.ok_cost > 0: OKRunState.spend_ok(choice.ok_cost, "event:%s" % _event.id)
	match choice.effect_type:
		EventData.ChoiceEffectType.GRANT_CLOCK_RELIC:
			RunManager.add_clock_relic(choice.relic_id)
		EventData.ChoiceEffectType.HP_DELTA:
			RunManager.apply_run_hp_change(choice.value)
		EventData.ChoiceEffectType.OK_DELTA:
			if choice.value > 0:
				OKRunState.gain_ok(choice.value, "event:%s" % _event.id)
			elif choice.value < 0:
				OKRunState.spend_ok(-choice.value, "event:%s" % _event.id)
		EventData.ChoiceEffectType.GRANT_CARD:
			var card := ContentDatabase.get_card(choice.card_id)
			if card != null:
				RunManager.add_card_to_deck(card)
		EventData.ChoiceEffectType.GRANT_RELIC:
			var relic := ContentDatabase.get_relic(choice.relic_id)
			if relic != null:
				RunManager.add_relic(relic)
	SaveManager.save_run()
	GameFlow.goto_map()
