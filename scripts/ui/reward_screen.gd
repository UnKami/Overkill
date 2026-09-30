extends Control
## Relic reward (screen composition doc 4.3): "read carefully once" screen,
## never priced - no OK cost or currency icon anywhere here, deliberate
## contrast with the shop. Uses the mutually-exclusive-choice confirmation
## pattern: the full card is already visible (no separate preview step
## needed), a distinct "Take this" per card commits.
##
## Also owns act-transition routing: this is where "after combat resolution"
## actually autosaves (per RunManager/SaveManager's wiring design), and where
## an act-boss kill advances to the next act's map, or the third act boss
## leads straight into the final boss fight.

@onready var _choice_row: GridContainer = %ChoiceRow
@onready var _skip_button: Button = %SkipButton

var _defeated_enemy: EnemyData
var _resolved: bool = false
var _pending_relic_id: String = ""
var _subtitle: Label


func set_reward_context(context: Dictionary) -> void:
	_defeated_enemy = context.get("enemy_data", null)


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	$TitleLabel.text = "SALVAGE A RELIC"
	$TitleLabel.add_theme_font_size_override("font_size", 38)
	$TitleLabel.add_theme_color_override("font_color", Color("e8c994"))
	var art := TextureRect.new()
	art.texture = load(CinematicArt.REWARD)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.3, 0.35, 0.4)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 1)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AmbientMotion.apply_cinematic_backdrop(self, art, 46.0, 0.72)
	_skip_button.pressed.connect(_on_skip_pressed)
	_offer_relics()
	_subtitle = ScreenDesign.label(self, "Choose one relic to bind into your chronometer. The others are left behind.", 22, ScreenDesign.MUTED)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_subtitle.offset_top = 106
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_button.text = "LEAVE RELICS"
	_skip_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_button.offset_left = -150
	_skip_button.offset_right = 150
	_skip_button.offset_top = -124
	_skip_button.offset_bottom = -64
	ScreenDesign.polish(self)


func _offer_relics() -> void:
	var pool := ContentDatabase.all_clock_relics().duplicate()
	pool.shuffle()
	for relic: ClockRelicData in pool.slice(0, 3):
		var view: RelicPedestalView = load("res://scenes/relic_pedestal_view.tscn").instantiate()
		_choice_row.add_child(view)
		view.bind_relic(relic, "CLAIM RELIC")
		view.selected.connect(_on_relic_chosen)


func _on_relic_chosen(relic: ClockRelicData) -> void:
	if _resolved: return
	if RunManager.add_clock_relic(relic.id):
		_resolved = true
		_continue_after_reward()
		return
	_pending_relic_id = relic.id
	_show_replacement_picker()


func _show_replacement_picker() -> void:
	for child: Node in _choice_row.get_children():
		_choice_row.remove_child(child)
		child.queue_free()
	var viewport_width: float = get_viewport_rect().size.x
	_choice_row.columns = 4 if viewport_width >= 1500.0 else 3
	_choice_row.add_theme_constant_override("h_separation", 18)
	_choice_row.add_theme_constant_override("v_separation", 14)
	_subtitle.text = "YOUR CHRONOMETER IS FULL  ·  CHOOSE ONE RELIC TO REPLACE"
	var choice_width: float = (viewport_width - 144.0 - float(_choice_row.columns - 1) * 18.0) / float(_choice_row.columns)
	for entry: Dictionary in RunManager.clock_inventory:
		var relic: ClockRelicData = ClockInventory.resolve(entry)
		if relic == null:
			continue
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(choice_width, 112)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.add_theme_font_size_override("font_size", 19)
		choice.text = "%s\n%s" % [relic.name.to_upper(), ClockInventory.instance_identity(entry)]
		choice.icon = RelicArt.load_texture(relic.art_id)
		choice.expand_icon = true
		choice.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.add_theme_constant_override("icon_max_width", 74)
		choice.tooltip_text = "%s\n%s\n\n%s" % [ClockInventory.instance_identity(entry), relic.name, relic.description]
		ScreenDesign.add_actionable_fx(choice, relic.primary_color(), true)
		var target_uid: int = int(entry.uid)
		choice.pressed.connect(func() -> void: _replace_with_pending_relic(target_uid))
		_choice_row.add_child(choice)
	var back := Button.new()
	back.text = "‹  BACK TO RELIC OFFERS"
	back.custom_minimum_size = Vector2(320, 52)
	back.pressed.connect(_show_relic_offers)
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	back.offset_left = -160
	back.offset_right = 160
	back.offset_top = -190
	back.offset_bottom = -140
	back.name = "ReplacementBackButton"
	_skip_button.text = "KEEP CURRENT 12"
	_skip_button.tooltip_text = "Leave the offer and keep your current relic lineup."


func _replace_with_pending_relic(uid: int) -> void:
	if _resolved or _pending_relic_id.is_empty():
		return
	if RunManager.replace_clock_relic(uid, _pending_relic_id):
		_resolved = true
		_continue_after_reward()


func _show_relic_offers() -> void:
	var back: Node = get_node_or_null("ReplacementBackButton")
	if back != null:
		back.queue_free()
	for child: Node in _choice_row.get_children():
		_choice_row.remove_child(child)
		child.queue_free()
	_choice_row.columns = 3
	_subtitle.text = "Choose one relic to bind into your chronometer. The others are left behind."
	_skip_button.text = "LEAVE RELICS"
	_pending_relic_id = ""
	_offer_relics()

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
				CinematicArt.transition_background(3),
				"THE FINAL DESCENT",
				func() -> void:
					var final_boss := ContentDatabase.get_enemy("final_boss")
					if final_boss != null:
						GameFlow.goto_combat([final_boss])
			)
			return
		var next_act: int = RunManager.act_number + 1
		var art_path: String = CinematicArt.transition_background(RunManager.act_number)
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
