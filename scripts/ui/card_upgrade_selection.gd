class_name CardUpgradeSelection extends Control
## Dedicated resolution screen for the upgrade offer. CardView owns tactile
## hover/transform feedback; this screen owns eligibility and the one-shot
## run-state commit.

signal resolved

const CardViewScene := preload("res://scenes/card_view.tscn")

var _grid: GridContainer
var _status: Label
var _continue: Button
var _title: Label
var _note: Label
var _views: Array[CardView] = []
var _instance_by_view: Dictionary = {}
var _caption_by_view: Dictionary = {}
var _copy_count_by_view: Dictionary = {}
var _committed: bool = false


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_build_background()
	ScreenDesign.frame(self, "REFINE A CARD")
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 88)
	margin.add_theme_constant_override("margin_top", 88)
	margin.add_theme_constant_override("margin_bottom", 54)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var kicker := ScreenDesign.label(column, "THE MEMORY FORGE", 16, ScreenDesign.CYAN)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title = ScreenDesign.label(column, "Choose the memory to sharpen.", 46, ScreenDesign.TEXT, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note = ScreenDesign.label(column, "Choose a card design. One owned copy will be permanently tempered for this run.", 20, ScreenDesign.MUTED)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 28)
	_grid.add_theme_constant_override("v_separation", 26)
	center.add_child(_grid)
	scroll.resized.connect(func() -> void: _grid.columns = maxi(1, mini(4, int((scroll.size.x + 28.0) / 298.0))))
	_status = ScreenDesign.label(column, "SELECT ONE UPGRADEABLE MEMORY", 20, ScreenDesign.GOLD, true)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size.y = 38
	_continue = ScreenDesign.button(column, "ENTER BATTLE   ›", func() -> void: resolved.emit(), true)
	_continue.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.custom_minimum_size.x = 330
	_continue.hide()
	_populate()
	ScreenDesign.apply_text_size(self)


func _build_background() -> void:
	var background := TextureRect.new()
	background.texture = load(CinematicArt.UPGRADE)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.46, 0.49, 0.52)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color("07101973")
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ScreenDesign.shade(self)
	AmbientMotion.apply_cinematic_backdrop(self, background, 52.0, 0.58)


func _populate() -> void:
	var eligible_by_id: Dictionary = {}
	var card_order: Array[String] = []
	for entry: RunCardEntry in RunManager.deck:
		var source: CardData = RunManager.resolve_card(entry)
		if source == null or entry.upgrade_level > 0: continue
		if not eligible_by_id.has(entry.card_id):
			eligible_by_id[entry.card_id] = []
			card_order.append(entry.card_id)
		eligible_by_id[entry.card_id].append(entry)
	var eligible_copy_count: int = 0
	for card_id: String in card_order:
		var entries: Array = eligible_by_id[card_id]
		eligible_copy_count += entries.size()
		var entry: RunCardEntry = entries[0]
		var source: CardData = RunManager.resolve_card(entry)
		var card: CardData = source.duplicate(false)
		card.upgrade_level = entry.upgrade_level
		var choice := VBoxContainer.new()
		choice.custom_minimum_size = Vector2(270, 438)
		choice.add_theme_constant_override("separation", 8)
		_grid.add_child(choice)
		var view: CardView = CardViewScene.instantiate()
		view.custom_minimum_size = Vector2(270, 405)
		choice.add_child(view)
		view.set_card(card)
		view.pressed.connect(_select.bind(view, card))
		var copy_caption := ScreenDesign.label(choice, "%d %s OWNED  ·  TEMPER ONE" % [entries.size(), "COPY" if entries.size() == 1 else "COPIES"], 14, ScreenDesign.CYAN)
		copy_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_views.append(view)
		_instance_by_view[view] = entry.instance_id
		_caption_by_view[view] = copy_caption
		_copy_count_by_view[view] = entries.size()
	if _views.is_empty():
		_status.text = "EVERY CARD IS ALREADY UPGRADED"
		_continue.show()
	else:
		_status.text = "%d UPGRADEABLE %s     ·     %d ELIGIBLE %s     ·     SELECT ONE" % [_views.size(), "DESIGN" if _views.size() == 1 else "DESIGNS", eligible_copy_count, "CARD" if eligible_copy_count == 1 else "CARDS"]


func _select(_pressed_card: CardData, view: CardView, card: CardData) -> void:
	if _committed: return
	_committed = true
	for item: CardView in _views:
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if item != view:
			var other_choice: Control = item.get_parent() as Control
			var fade := other_choice.create_tween()
			fade.tween_property(other_choice, "modulate:a", 0.0, 0.18)
			fade.tween_callback(other_choice.hide)
	var instance_id: int = int(_instance_by_view.get(view, -1))
	if instance_id < 0 or not RunManager.apply_card_upgrade(instance_id):
		_status.text = "THE CARD COULD NOT BE UPGRADED"
		_continue.show()
		return
	var upgraded: CardData = card.duplicate(false)
	upgraded.upgrade_level = 1
	var owned_copies: int = int(_copy_count_by_view.get(view, 1))
	var selected_caption: Label = _caption_by_view.get(view) as Label
	selected_caption.text = "THE MEMORY IS TEMPERED" if owned_copies == 1 else "1 COPY TEMPERED  ·  %d %s UNCHANGED" % [owned_copies - 1, "REMAINS" if owned_copies == 2 else "REMAIN"]
	selected_caption.add_theme_color_override("font_color", ScreenDesign.GOLD)
	_title.text = "The memory is reforged."
	_note.text = "Its sharpened form will remain bound to this run."
	_status.text = "TEMPERING  /  %s" % card.display_name.to_upper()
	await view.play_upgrade_animation(upgraded)
	_status.text = "%s+  ·  UPGRADE COMPLETE" % card.display_name.to_upper()
	_continue.show()
	_continue.grab_focus()
