class_name CardUpgradeSelection extends Control
## Dedicated resolution screen for the upgrade offer. CardView owns tactile
## hover/transform feedback; this screen owns eligibility and the one-shot
## run-state commit.

signal resolved

const CardViewScene := preload("res://scenes/card_view.tscn")

var _grid: GridContainer
var _status: Label
var _continue: Button
var _views: Array[CardView] = []
var _instance_by_view: Dictionary = {}
var _committed: bool = false


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_build_background()
	ScreenDesign.frame(self, "REFINE A CARD")
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + edge, 64)
	margin.add_theme_constant_override("margin_top", 92)
	margin.add_theme_constant_override("margin_bottom", 48)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title := ScreenDesign.label(column, "Choose the memory to sharpen.", 44, ScreenDesign.TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var note := ScreenDesign.label(column, "Hover to inspect. The selected card transforms permanently for this run.", 20, ScreenDesign.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 26)
	scroll.add_child(_grid)
	scroll.resized.connect(func() -> void: _grid.columns = maxi(1, mini(5, int((scroll.size.x + 22.0) / 270.0))))
	_status = ScreenDesign.label(column, "SELECT ONE UPGRADEABLE CARD", 22, ScreenDesign.GOLD, true)
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
	background.texture = load("res://assets/screens/rest_site_bg.jpg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.24, 0.27, 0.30)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color("071019db")
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _populate() -> void:
	for entry: RunCardEntry in RunManager.deck:
		var source: CardData = RunManager.resolve_card(entry)
		if source == null or entry.upgrade_level > 0: continue
		var card: CardData = source.duplicate(false)
		card.upgrade_level = entry.upgrade_level
		var view: CardView = CardViewScene.instantiate()
		_grid.add_child(view)
		view.set_card(card)
		view.pressed.connect(_select.bind(view, card))
		_views.append(view)
		_instance_by_view[view] = entry.instance_id
	if _views.is_empty():
		_status.text = "EVERY CARD IS ALREADY UPGRADED"
		_continue.show()


func _select(_pressed_card: CardData, view: CardView, card: CardData) -> void:
	if _committed: return
	_committed = true
	for item: CardView in _views:
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if item != view: item.create_tween().tween_property(item, "modulate", Color(0.38, 0.42, 0.48, 0.35), 0.22)
	var instance_id: int = int(_instance_by_view.get(view, -1))
	if instance_id < 0 or not RunManager.apply_card_upgrade(instance_id):
		_status.text = "THE CARD COULD NOT BE UPGRADED"
		_continue.show()
		return
	var upgraded: CardData = card.duplicate(false)
	upgraded.upgrade_level = 1
	_status.text = "TEMPERING  /  %s" % card.display_name.to_upper()
	await view.play_upgrade_animation(upgraded)
	_status.text = "%s+  ·  UPGRADE COMPLETE" % card.display_name.to_upper()
	_continue.show()
	_continue.grab_focus()
