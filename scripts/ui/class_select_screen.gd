extends Control
const STARTING_CARD_COUNTS := {"strike":5,"defend":4,"split_strike":1}
const STARTING_RELIC_IDS := ["relic_greed_battery"]
const STARTING_MAX_HP := 75
var _start_button: Button
var _starting := false

func _ready() -> void:
	theme = ScreenDesign.build_theme()
	var stage := preload("res://scripts/ui/frontend_stage.gd").new()
	stage.character_view = true
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ScreenDesign.shade(self)
	ScreenDesign.frame(self,"CHOOSE YOUR EXECUTIONER")
	# This screen ends at the Back action; the global motto reads like stray
	# explanatory copy underneath it here, so keep the character page clean.
	for child: Node in get_children():
		if child is Label and child.text == "BIND THE HOURS. BREAK THE CYCLE.":
			child.queue_free()
	var column := ScreenDesign.column(self,0.16,0.40)
	ScreenDesign.label(column,"01  /  THE EXECUTIONER",18,ScreenDesign.CYAN)
	ScreenDesign.label(column,"Death by\ndesign.",66,ScreenDesign.TEXT,true)
	var description := ScreenDesign.label(column,"A keeper of forbidden hours. Turn ancient relics into a killing mechanism — and make every final blow count.",23,ScreenDesign.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ScreenDesign.spacer(column,18)
	ScreenDesign.rule(column)
	ScreenDesign.spacer(column,18)
	_start_button = ScreenDesign.button(column,"STANDART BATTLE   ›",_on_start_pressed,true)
	ScreenDesign.button(column,"‹   BACK",func() -> void: GameFlow.goto_title())
	_start_button.grab_focus()
	ScreenDesign.reveal(column)
	ScreenDesign.apply_text_size(self)

func _on_start_pressed() -> void:
	if _starting: return
	_starting = true
	_start_button.disabled = true
	var starting_deck: Array[CardData] = []
	for card_id in STARTING_CARD_COUNTS:
		var card := ContentDatabase.get_card(card_id)
		if card != null:
			for _i in STARTING_CARD_COUNTS[card_id]: starting_deck.append(card)
	var starting_relics: Array[RelicData] = []
	for relic_id in STARTING_RELIC_IDS:
		var relic := ContentDatabase.get_relic(relic_id)
		if relic != null: starting_relics.append(relic)
	RunManager.start_new_run(starting_deck,starting_relics,STARTING_MAX_HP)
	SaveManager.save_run()
	GameFlow.goto_map()
