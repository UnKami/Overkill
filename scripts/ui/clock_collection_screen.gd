extends Control
## Shared inventory, merchant and forge. All actions mutate the same saved copies.
var mode: String = "collection"
var overlay: bool = false
var _grid: GridContainer
var _summary: Label
var _committed: bool = false
var _offers: Array = []
var _upgrade_preview: Control
const Pedestal := preload("res://scenes/relic_pedestal_view.tscn")

func _ready() -> void:
	theme = ScreenDesign.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RunManager.ensure_clock_inventory()

	var backdrop := TextureRect.new()
	var backdrop_path: String = "res://assets/screens/shop_bg.jpg" if mode == "shop" else (CinematicArt.UPGRADE if mode == "upgrade" else CinematicArt.COLLECTION)
	backdrop.texture = load(backdrop_path)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate = Color(0.62, 0.66, 0.70) if mode == "collection" else Color(0.48, 0.52, 0.56)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AmbientMotion.apply_cinematic_backdrop(self, backdrop, 42.0, 0.55)
	ScreenDesign.shade(self)
	var breadcrumb_text: String = {"collection":"O V E R K I L L     /     THE ARCHIVE  /  RELIQUARY", "shop":"O V E R K I L L     /     THE CLOCKWRIGHT", "upgrade":"O V E R K I L L     /     THE FORGE", "removal":"O V E R K I L L     /     DISMANTLING"}.get(mode, "O V E R K I L L     /     THE ARCHIVE")
	var breadcrumb := ScreenDesign.label(self, breadcrumb_text, 18, ScreenDesign.GOLD)
	breadcrumb.position = Vector2(64, 38)

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 92)
	margin.add_theme_constant_override("margin_bottom", 54)

	var stage := HBoxContainer.new()
	stage.add_theme_constant_override("separation", 30)
	margin.add_child(stage)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	stage.add_child(column)

	var kicker := Label.new()
	kicker.text = {"collection":"ACTIVE CHRONOMETER INVENTORY", "shop":"FIVE OBJECTS  ·  ONE PRICE", "upgrade":"ONE RELIC MAY BE TEMPERED", "removal":"BREAK ONE BINDING"}.get(mode, "ACTIVE CHRONOMETER INVENTORY")
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_color_override("font_color", ScreenDesign.CYAN)
	column.add_child(kicker)
	var title := Label.new()
	title.text = {"collection": "THE RELIQUARY", "shop": "THE CLOCKWRIGHT", "upgrade": "TEMPER A RELIC", "removal": "DISMANTLE A RELIC"}.get(mode, "THE RELIQUARY")
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_font_override("font",ScreenDesign.display_font())
	title.add_theme_color_override("font_color", Color("e8c994"))
	column.add_child(title)
	ScreenDesign.rule(column, Color("e8c994"))
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 18)
	_summary.add_theme_color_override("font_color", Color("c9d2d8"))
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_summary)

	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 8)
	column.add_child(legend)
	_add_legend_token(legend, "ATTACK", ClockRelicData.Essence.ATTACK)
	_add_legend_token(legend, "BLOCK", ClockRelicData.Essence.BLOCK)
	_add_legend_token(legend, "BUFF", ClockRelicData.Essence.BUFF)
	_add_legend_token(legend, "DEBUFF", ClockRelicData.Essence.DEBUFF)
	_add_legend_token(legend, "OVERKILL", ClockRelicData.Essence.OVERKILL)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if get_viewport_rect().size.x >= 1500.0 else ScrollContainer.SCROLL_MODE_AUTO
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5 if mode == "shop" else 4
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12 if mode == "shop" else 16)
	_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(_grid)
	scroll.resized.connect(func() -> void:
		var card_width: float = 258.0 if mode == "shop" else 288.0
		var maximum: int = 5 if mode == "shop" else 4
		_grid.columns = maxi(1, mini(maximum, int((scroll.size.x + 12.0) / card_width))))
	var back := Button.new()
	back.text = "RETURN TO MAP"
	back.custom_minimum_size = Vector2(220, 50)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_close)
	column.add_child(back)

	var presence := Control.new()
	var presence_width: float = 430.0 if mode == "collection" else (330.0 if get_viewport_rect().size.x >= 1500.0 else 0.0)
	presence.custom_minimum_size = Vector2(presence_width, 0)
	presence.visible = presence_width > 0.0
	stage.add_child(presence)
	var witness := VBoxContainer.new()
	witness.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	witness.offset_top = 72
	witness.offset_left = 24
	witness.offset_right = -10
	witness.add_theme_constant_override("separation", 5)
	presence.add_child(witness)
	var witness_kicker := ScreenDesign.label(witness, "THE EXECUTIONER", 14, ScreenDesign.CYAN)
	witness_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var witness_title_text: String = "Dealer in forbidden hours" if mode == "shop" else "Warden of the bound hours"
	var witness_title := ScreenDesign.label(witness, witness_title_text, 25, Color("f0d4a0"), true)
	witness_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	witness_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	witness_title.custom_minimum_size.y = 66
	var witness_copy_text: String = "A price is another kind of sacrifice.\nChoose what the clock will remember." if mode == "shop" else "Every object is a command.\nEvery color is a promise."
	var witness_copy := ScreenDesign.label(witness, witness_copy_text, 16, Color("b7c4cc"))
	witness_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	witness_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	witness_copy.custom_minimum_size.y = 70
	_offers = ContentDatabase.all_clock_relics().duplicate()
	_offers.shuffle()
	_offers = _offers.slice(0, 5)
	_rebuild()
	ScreenDesign.apply_text_size(self)
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _add_legend_token(parent: HBoxContainer, text: String, essence: int) -> void:
	var token := PanelContainer.new()
	var color: Color = ClockRelicData.essence_to_color(essence)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08131ccc")
	style.border_color = Color(color, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	token.add_theme_stylebox_override("panel", style)
	parent.add_child(token)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	token.add_child(label)

func _rebuild() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_summary.text = "%d relics  /  9 clock sockets  /  %d reserves     •     %d OVERKILL" % [RunManager.clock_inventory.size(), maxi(0, RunManager.clock_inventory.size() - 9), OKRunState.current_ok]
	if mode == "shop": _summary.text = "%d OVERKILL AVAILABLE     ·     EACH RELIC COSTS 15     ·     PURCHASES JOIN YOUR CHRONOMETER" % OKRunState.current_ok
	if mode == "upgrade": _summary.text += "     •     One free upgrade this visit."
	if mode == "removal": _summary.text += "     •     Keep at least 10 relics."
	if mode == "collection":
		var groups: Dictionary = {}
		var group_order: Array[String] = []
		for entry: Dictionary in RunManager.clock_inventory:
			var key := "%s:%d" % [str(entry.get("id", "")), int(entry.get("level", 0))]
			if not groups.has(key):
				groups[key] = {"entry": entry, "count": 0}
				group_order.append(key)
			var group: Dictionary = groups[key]
			group.count = int(group.count) + 1
			groups[key] = group
		_summary.text = "%d relics  /  %d designs  /  9 clock sockets  /  %d reserves     •     %d OVERKILL" % [RunManager.clock_inventory.size(), groups.size(), maxi(0, RunManager.clock_inventory.size() - 9), OKRunState.current_ok]
		for key: String in group_order:
			var group: Dictionary = groups[key]
			var relic := ClockInventory.resolve(group.entry)
			if relic == null:
				continue
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			view.use_collection_layout()
			view.bind_relic(relic, "")
			view.set_stack_count(int(group.count))
		return
	if mode == "upgrade":
		# Tempering is a decision between relic designs, not a wall of identical
		# inventory copies. Group owned copies by design and target one eligible
		# copy from the chosen group. This keeps the forge legible even when the
		# chronometer contains many starter duplicates.
		var upgrade_groups: Dictionary = {}
		var upgrade_order: Array[String] = []
		for entry: Dictionary in RunManager.clock_inventory:
			var relic_id: String = str(entry.get("id", ""))
			if not upgrade_groups.has(relic_id):
				upgrade_groups[relic_id] = []
				upgrade_order.append(relic_id)
			var entries: Array = upgrade_groups[relic_id]
			entries.append(entry)
			upgrade_groups[relic_id] = entries
		_summary.text = "%d relics  /  %d designs  /  9 clock sockets  /  %d reserves     •     One free tempering this visit." % [RunManager.clock_inventory.size(), upgrade_groups.size(), maxi(0, RunManager.clock_inventory.size() - 9)]
		for relic_id: String in upgrade_order:
			var entries: Array = upgrade_groups[relic_id]
			var target_entry: Dictionary = {}
			var ready_count: int = 0
			for candidate: Dictionary in entries:
				if int(candidate.get("level", 0)) == 0:
					ready_count += 1
					if target_entry.is_empty():
						target_entry = candidate
			if target_entry.is_empty():
				target_entry = entries[0]
			var relic: ClockRelicData = ClockInventory.resolve(target_entry)
			if relic == null:
				continue
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			var action: String = "PREVIEW TEMPERING  ·  %d READY" % ready_count if ready_count > 0 else "ALL COPIES TEMPERED"
			view.bind_relic(relic, action)
			view.set_stack_count(entries.size())
			view._slot_button.disabled = ready_count == 0
			if ready_count > 0:
				var upgraded: Dictionary = target_entry.duplicate()
				upgraded.level = 1
				var tempered: ClockRelicData = ClockInventory.resolve(upgraded)
				view.tooltip_text = "%d copies owned; %d may still be tempered.\n\nCURRENT\n%s\n\nAFTER TEMPERING\n%s" % [entries.size(), ready_count, relic.description, tempered.description]
				var target_uid: int = int(target_entry.get("uid", -1))
				view.selected.connect(func(_r: ClockRelicData) -> void: _choose(target_uid))
		return
	if mode == "shop":
		for relic: ClockRelicData in _offers:
			var price := RunManager.price_for("clock_relic", 15)
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			view.use_shop_layout()
			view.bind_relic(relic, "Buy · %d Overkill" % price)
			view._slot_button.disabled = OKRunState.current_ok < price
			if view._slot_button.disabled:
				view._slot_button.text = "Need %d more" % (price - OKRunState.current_ok)
			view.selected.connect(func(_r: ClockRelicData) -> void: _buy(relic, price))
		return
	for entry in RunManager.clock_inventory:
		var relic := ClockInventory.resolve(entry)
		if relic == null: continue
		var view: RelicPedestalView = Pedestal.instantiate()
		_grid.add_child(view)
		if mode == "collection":
			view.use_collection_layout()
		var action := ""
		if mode == "upgrade":
			action = "PREVIEW TEMPERING" if int(entry.level) == 0 else "ALREADY TEMPERED"
			if int(entry.level) == 0:
				var upgraded := entry.duplicate()
				upgraded.level = 1
				view.tooltip_text = "CURRENT\n%s\n\nAFTER TEMPERING\n%s" % [relic.description, ClockInventory.resolve(upgraded).description]
		elif mode == "removal": action = "DISMANTLE  /  25 OK"
		view.bind_relic(relic, action)
		view._slot_button.disabled = mode == "collection" or (mode == "upgrade" and int(entry.level) > 0) or (mode == "removal" and (RunManager.clock_inventory.size() <= ClockInventory.MINIMUM_SIZE or OKRunState.current_ok < 25))
		if mode == "collection":
			# A collection card is already self-evidently owned. Removing the
			# disabled pseudo-action gives the art and useful rules room to breathe.
			view._slot_button.hide()
		if mode == "removal" and RunManager.clock_inventory.size() <= ClockInventory.MINIMUM_SIZE:
			view._slot_button.text = "MINIMUM DECK SIZE"
		elif mode == "removal" and OKRunState.current_ok < 25:
			view._slot_button.text = "Need %d more Overkill" % (25 - OKRunState.current_ok)
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
			var tempered: ClockRelicData = ClockInventory.resolve(upgraded)
			UpgradePreviewDialog.show_relic_dialog(self, current, tempered, func() -> void: _commit_upgrade(uid))
			_upgrade_preview = get_child(get_child_count() - 1) as Control
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
