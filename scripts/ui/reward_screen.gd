extends Control
## Card reward (screen composition doc 4.3): "read carefully once" screen,
## never priced - no OK cost or currency icon anywhere here, deliberate
## contrast with the shop. Uses the mutually-exclusive-choice confirmation
## pattern: the full card is already visible (no separate preview step
## needed), a distinct "Take this" per card commits.
##
## Also owns act-transition routing: this is where "after combat resolution"
## actually autosaves (per RunManager/SaveManager's wiring design), and where
## an act-boss kill advances to the next act's map, or the third act boss
## leads straight into the final boss fight.

const CardViewScene := preload("res://scenes/card_view.tscn")
const CARD_CHOICE_COUNT := 3
const COMMON_WEIGHT := 4
const UNCOMMON_WEIGHT := 2
const RARE_WEIGHT := 1

@onready var _choice_row: HBoxContainer = %ChoiceRow
@onready var _skip_button: Button = %SkipButton

var _defeated_enemy: EnemyData
var _resolved: bool = false


func set_reward_context(context: Dictionary) -> void:
	_defeated_enemy = context.get("enemy_data", null)


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	$TitleLabel.text = "SALVAGE A RELIC"
	$TitleLabel.add_theme_font_size_override("font_size", 38)
	$TitleLabel.add_theme_color_override("font_color", Color("e8c994"))
	var art := TextureRect.new()
	art.texture = load("res://assets/environments/chronoforge_arena.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.3, 0.35, 0.4)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 1)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skip_button.pressed.connect(_on_skip_pressed)
	_offer_cards()
	var subtitle: Label = ScreenDesign.label(self, "Choose one relic to add to your deck. The others are left behind.", 22, ScreenDesign.MUTED)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.offset_top = 106
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_button.text = "LEAVE RELICS"
	_skip_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_button.offset_left = -150
	_skip_button.offset_right = 150
	_skip_button.offset_top = -124
	_skip_button.offset_bottom = -64
	ScreenDesign.polish(self)


func _offer_cards() -> void:
	var pool := ContentDatabase.all_clock_relics().duplicate()
	pool.shuffle()
	for relic: ClockRelicData in pool.slice(0, 3):
		var view: RelicPedestalView = load("res://scenes/relic_pedestal_view.tscn").instantiate()
		_choice_row.add_child(view)
		view.bind_relic(relic, "CLAIM RELIC")
		view.selected.connect(_on_relic_chosen)


func _on_relic_chosen(relic: ClockRelicData) -> void:
	if _resolved: return
	_resolved = true
	RunManager.add_clock_relic(relic.id)
	_continue_after_reward()

func _on_skip_pressed() -> void:
	if _resolved:
		return
	_resolved = true
	_continue_after_reward()


func _continue_after_reward() -> void:
	if _defeated_enemy != null and _defeated_enemy.tier == EnemyData.Tier.BOSS:
		if _defeated_enemy.id == "act3_boss":
			SaveManager.save_run()
			GameFlow.goto_act_transition(
				"res://assets/screens/act_transition_3_boss.jpg",
				"THE FINAL DESCENT",
				func() -> void:
					var final_boss := ContentDatabase.get_enemy("final_boss")
					if final_boss != null:
						GameFlow.goto_combat([final_boss])
			)
			return
		var next_act: int = RunManager.act_number + 1
		var art_path: String = "res://assets/screens/act_transition_%d_%d.jpg" % [RunManager.act_number, next_act]
		SaveManager.save_run()
		GameFlow.goto_act_transition(
			art_path,
			"ACT %d" % next_act,
			func() -> void:
				RunManager.advance_act()
				SaveManager.save_run()
				GameFlow.goto_map()
		)
		return
	SaveManager.save_run()
	GameFlow.goto_map()
