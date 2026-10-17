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

const ELITE_BONUS_OK: int = 15

@onready var _choice_row: GridContainer = %ChoiceRow
@onready var _skip_button: Button = %SkipButton

var _defeated_enemy: EnemyData
var _is_elite: bool = false
var _elite_spoils_claimed: bool = false
var _elite_artifact_id: String = ""
var _elite_artifact: RelicData = null
var _resolved: bool = false
var _pending_relic_id: String = ""
var _subtitle: Label
var _elite_banner: PanelContainer
var _offer_ids: Array[String] = []


func set_reward_context(context: Dictionary) -> void:
	_defeated_enemy = context.get("enemy_data", null)
	_is_elite = bool(context.get("is_elite", _defeated_enemy != null and _defeated_enemy.tier == EnemyData.Tier.ELITE))
	_elite_spoils_claimed = bool(context.get("elite_spoils_claimed", false))
	_elite_artifact_id = str(context.get("elite_artifact_id", ""))
	_offer_ids.assign(context.get("offer_ids", []))


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	$TitleLabel.text = "ELITE VANQUISHED  ·  SALVAGE A RELIC" if _is_elite else "SALVAGE A RELIC"
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
	_award_elite_spoils_if_needed()
	_offer_relics()
	_subtitle = ScreenDesign.label(self, "Choose one relic to bind into your chronometer. The others are left behind.", 22, ScreenDesign.MUTED)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_subtitle.offset_top = 98 if _is_elite else 106
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _is_elite:
		_build_elite_spoils_banner()
	_skip_button.text = "LEAVE RELICS"
	_skip_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_button.offset_left = -150
	_skip_button.offset_right = 150
	_skip_button.offset_top = -124
	_skip_button.offset_bottom = -64
	ScreenDesign.polish(self)


func _award_elite_spoils_if_needed() -> void:
	if not _is_elite:
		return
	if not _elite_spoils_claimed:
		OKRunState.gain_ok(ELITE_BONUS_OK, "elite_victory_bonus")
		var candidates: Array[RelicData] = []
		for relic: RelicData in ContentDatabase.all_relics(true):
			if not RunManager.has_relic(relic.id):
				candidates.append(relic)
		if not candidates.is_empty():
			candidates.shuffle()
			_elite_artifact = candidates[0]
			_elite_artifact_id = _elite_artifact.id
			RunManager.add_relic(_elite_artifact)
		_elite_spoils_claimed = true
	elif not _elite_artifact_id.is_empty():
		_elite_artifact = ContentDatabase.get_relic(_elite_artifact_id)


func _build_elite_spoils_banner() -> void:
	_elite_banner = PanelContainer.new()
	_elite_banner.name = "EliteSpoilsBanner"
	var style: StyleBoxFlat = ScreenDesign.box(Color("0b1a26ee"), Color("e8c994"), 2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_elite_banner.add_theme_stylebox_override("panel", style)
	var text: String = "ELITE SPOILS CLAIMED:  +%d BONUS OVERKILL" % ELITE_BONUS_OK
	if _elite_artifact != null:
		text += "     ·     BONUS ARTIFACT:  %s" % _elite_artifact.display_name.to_upper()
	var label := ScreenDesign.label(_elite_banner, text, 17, Color("f6d28b"), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_elite_banner)
	_elite_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_elite_banner.offset_left = -460
	_elite_banner.offset_right = 460
	_elite_banner.offset_top = 132
	_elite_banner.offset_bottom = 174


func _roll_reward_pool() -> Array:
	if ContentDatabase.has_method("reward_clock_relics"):
		return (ContentDatabase.call("reward_clock_relics", _is_elite) as Array).duplicate()
	var commons: Array = []
	var rares: Array = []
	for relic: ClockRelicData in ContentDatabase.all_clock_relics():
		if relic.id == "REL-01" or relic.id == "REL-04" or relic.tier == ClockRelicData.Tier.STARTER:
			continue
		if relic.tier == ClockRelicData.Tier.RARE:
			rares.append(relic)
		else:
			commons.append(relic)
	commons.shuffle()
	rares.shuffle()
	var pool: Array = []
	if _is_elite:
		for r: ClockRelicData in rares:
			pool.append(r)
		for c: ClockRelicData in commons:
			pool.append(c)
	else:
		pool.append_array(commons)
		pool.append_array(rares)
		pool.shuffle()
	return pool


func _offer_relics() -> void:
	if _offer_ids.is_empty():
		var pool: Array = _roll_reward_pool()
		var chosen: Array[String] = []
		if _is_elite:
			var rares: Array[ClockRelicData] = []
			var others: Array[ClockRelicData] = []
			for relic: ClockRelicData in pool:
				if relic.tier == ClockRelicData.Tier.RARE:
					rares.append(relic)
				else:
					others.append(relic)
			rares.shuffle()
			others.shuffle()
			for r: ClockRelicData in rares.slice(0, 2):
				if not chosen.has(r.id):
					chosen.append(r.id)
			var combined: Array[ClockRelicData] = []
			combined.append_array(others)
			combined.append_array(rares)
			combined.shuffle()
			for item: ClockRelicData in combined:
				if chosen.size() >= 3:
					break
				if not chosen.has(item.id):
					chosen.append(item.id)
		else:
			pool.shuffle()
			for relic: ClockRelicData in pool:
				if chosen.size() >= 3:
					break
				if not chosen.has(relic.id):
					chosen.append(relic.id)
		_offer_ids.assign(chosen)
	# The same offers survive replacement/back and a saved Continue.
	if str(RunManager.resume_context.get("kind", "")) == "reward":
		RunManager.resume_context["offer_ids"] = _offer_ids.duplicate()
		RunManager.resume_context["is_elite"] = _is_elite
		RunManager.resume_context["elite_spoils_claimed"] = _elite_spoils_claimed
		RunManager.resume_context["elite_artifact_id"] = _elite_artifact_id
		SaveManager.save_run()
	for id: String in _offer_ids:
		var relic: ClockRelicData = ContentDatabase.get_clock_relic(id)
		if relic == null: continue
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
		GameFlow.goto_boss_exit(_defeated_enemy)
		return
	RunManager.resume_context = {"kind": "map"}
	SaveManager.save_run()
	GameFlow.goto_map()
