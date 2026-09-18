extends Control
## Shared inventory, merchant and forge. All actions mutate the same saved copies.
var mode: String = "collection"
var overlay: bool = false
var _grid: GridContainer
var _summary: Label
var _committed: bool = false
var _offers: Array = []
var _upgrade_preview: ConfirmationDialog
const Pedestal := preload("res://scenes/relic_pedestal_view.tscn")

func _ready() -> void:
	theme = ScreenDesign.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RunManager.ensure_clock_inventory()
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/screens/shop_bg.jpg" if mode == "shop" else ("res://assets/screens/rest_site_bg.jpg" if mode == "upgrade" else "res://assets/environments/chronoforge_arena.png"))
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.24, 0.29, 0.34)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 64)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)
	var title := Label.new()
	title.text = {"collection": "THE RELIQUARY", "shop": "THE CLOCKWRIGHT", "upgrade": "TEMPER A RELIC", "removal": "DISMANTLE A RELIC"}.get(mode, "THE RELIQUARY")
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_font_override("font",ScreenDesign.display_font())
	title.add_theme_color_override("font_color", Color("e8c994"))
	column.add_child(title)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 20)
	column.add_child(_summary)
	if mode == "shop":
		var space := Control.new()
		space.custom_minimum_size.y = 120
		column.add_child(space)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 28)
	scroll.add_child(_grid)
	var back := Button.new()
	back.text = "RETURN"
	back.custom_minimum_size = Vector2(220, 52)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(_close)
	column.add_child(back)
	_offers = ContentDatabase.all_clock_relics().duplicate()
	_offers.shuffle()
	_offers = _offers.slice(0, 5)
	_rebuild()
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func _rebuild() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_summary.text = "%d relics  /  12 clock sockets  /  %d reserves     •     %d OVERKILL" % [RunManager.clock_inventory.size(), maxi(0, RunManager.clock_inventory.size() - 12), OKRunState.current_ok]
	if mode == "upgrade": _summary.text += "     •     One free upgrade this visit."
	if mode == "removal": _summary.text += "     •     Keep at least 15 relics."
	if mode == "shop":
		for relic: ClockRelicData in _offers:
			var price := RunManager.price_for("clock_relic", 15)
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			view.bind_relic(relic, "ACQUIRE  /  %d OK" % price)
			view._slot_button.disabled = OKRunState.current_ok < price
			view.selected.connect(func(_r: ClockRelicData) -> void: _buy(relic, price))
		return
	for entry in RunManager.clock_inventory:
		var relic := ClockInventory.resolve(entry)
		if relic == null: continue
		var view: RelicPedestalView = Pedestal.instantiate()
		_grid.add_child(view)
		var action := "BOUND TO YOUR COLLECTION"
		if mode == "upgrade":
			action = "PREVIEW TEMPERING" if int(entry.level) == 0 else "ALREADY TEMPERED"
			if int(entry.level) == 0:
				var upgraded := entry.duplicate()
				upgraded.level = 1
				view.tooltip_text = "CURRENT\n%s\n\nAFTER TEMPERING\n%s" % [relic.description, ClockInventory.resolve(upgraded).description]
		elif mode == "removal": action = "DISMANTLE  /  25 OK"
		view.bind_relic(relic, action)
		view._slot_button.disabled = mode == "collection" or (mode == "upgrade" and int(entry.level) > 0) or (mode == "removal" and (RunManager.clock_inventory.size() <= ClockInventory.MINIMUM_SIZE or OKRunState.current_ok < 25))
		view.selected.connect(func(_r: ClockRelicData) -> void: _choose(int(entry.uid)))

func _buy(relic: ClockRelicData, price: int) -> void:
	if not _offers.has(relic) or not OKRunState.spend_ok(price, "clock_relic"): return
	RunManager.add_clock_relic(relic.id)
	RunManager.record_purchase("clock_relic")
	_offers.erase(relic)
	SaveManager.save_run()
	_rebuild()

func _choose(uid: int) -> void:
	if _committed: return
	if mode == "upgrade":
		for entry in RunManager.clock_inventory:
			if int(entry.uid) != uid or int(entry.level) > 0: continue
			if is_instance_valid(_upgrade_preview): _upgrade_preview.queue_free()
			var current := ClockInventory.resolve(entry)
			var upgraded := entry.duplicate()
			upgraded.level = 1
			_upgrade_preview = ConfirmationDialog.new()
			_upgrade_preview.title = "Temper " + current.name
			_upgrade_preview.dialog_text = "CURRENT\n%s\n\nTEMPERED\n%s\n\nFree. Uses your one upgrade at this rest site." % [current.description, ClockInventory.resolve(upgraded).description]
			_upgrade_preview.ok_button_text = "TEMPER RELIC"
			add_child(_upgrade_preview)
			_upgrade_preview.confirmed.connect(func() -> void: _commit_upgrade(uid))
			_upgrade_preview.popup_centered(Vector2i(640, 320))
			return
	elif mode == "removal" and OKRunState.current_ok >= 25:
		if RunManager.remove_clock_relic(uid):
			OKRunState.spend_ok(25, "clock_dismantle")
			SaveManager.save_run()
			_rebuild()

func _commit_upgrade(uid: int) -> void:
	if _committed or mode != "upgrade": return
	_committed = true
	if RunManager.upgrade_clock_relic(uid):
		SaveManager.save_run()
		_close()
	else: _committed = false

func _close() -> void:
	if overlay: GameFlow.close_deck_view()
	else: GameFlow.goto_map()
