class_name ClockCollectionScreen extends Control
## Shared inventory, merchant and forge. All actions mutate the same saved copies.
signal resolved

var mode: String = "collection"
var overlay: bool = false
var pre_battle: bool = false
var _grid: GridContainer
var _summary: Label
var _committed: bool = false
var _offers: Array = []
var _artifact_offers: Array[RelicData] = []
var _artifact_grid: GridContainer
var _artifact_purchase_made: bool = false
var _upgrade_preview: UpgradePreviewDialog
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
	kicker.text = {"collection":"ACTIVE CHRONOMETER INVENTORY", "shop":"FIVE OBJECTS  ·  ONE PRICE", "upgrade":"ONE RELIC MAY BE UPGRADED", "removal":"BREAK ONE BINDING"}.get(mode, "ACTIVE CHRONOMETER INVENTORY")
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_color_override("font_color", ScreenDesign.CYAN)
	column.add_child(kicker)
	var title := Label.new()
	title.text = {"collection": "THE RELIQUARY", "shop": "THE CLOCKWRIGHT", "upgrade": "UPGRADE A RELIC", "removal": "DISMANTLE A RELIC"}.get(mode, "THE RELIQUARY")
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
	scroll.name = "InventoryScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# The shop's artifact row sits below its five clock offers. Keep a visible
	# scroll cue at desktop resolutions so the separate, run-wide purchases are
	# not mistaken for decorative art below the fold.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5 if mode == "shop" else 4
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12 if mode == "shop" else 16)
	_grid.add_theme_constant_override("v_separation", 18)
	var scroll_content := VBoxContainer.new()
	scroll_content.add_theme_constant_override("separation", 22)
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_content)
	scroll_content.add_child(_grid)
	if mode == "shop":
		var artifact_heading := ScreenDesign.label(scroll_content, "RUN-WIDE ARTIFACTS  ·  ONE UNIQUE PURCHASE", 20, Color("e8c994"), true)
		artifact_heading.name = "RunArtifactShopHeading"
		var artifact_note := ScreenDesign.label(scroll_content, "These objects travel with you; they never occupy a clock socket.", 15, Color("b7c4cc"))
		artifact_note.name = "RunArtifactShopNote"
		_artifact_grid = GridContainer.new()
		_artifact_grid.name = "RunArtifactShopGrid"
		_artifact_grid.columns = 3
		_artifact_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_artifact_grid.add_theme_constant_override("h_separation", 26)
		_artifact_grid.add_theme_constant_override("v_separation", 16)
		scroll_content.add_child(_artifact_grid)
	scroll.resized.connect(func() -> void:
		var card_width: float = 258.0 if mode == "shop" else 288.0
		var maximum: int = 5 if mode == "shop" else 4
		_grid.columns = maxi(1, mini(maximum, int((scroll.size.x + 12.0) / card_width)))
		if mode == "shop" and is_instance_valid(_artifact_grid):
			_artifact_grid.columns = maxi(1, mini(3, int((scroll.size.x + 26.0) / 270.0)))
	)
	var back := Button.new()
	back.text = "ENTER BATTLE  ›" if pre_battle else ("CLOSE RELIQUARY" if overlay else "RETURN TO MAP")
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
	for relic: RelicData in ContentDatabase.all_relics(true):
		if relic.id.begins_with("artifact_") and not RunManager.has_relic(relic.id):
			_artifact_offers.append(relic)
	_artifact_offers.shuffle()
	_artifact_offers = _artifact_offers.slice(0, 3)
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
	if is_instance_valid(_artifact_grid):
		for child: Node in _artifact_grid.get_children():
			_artifact_grid.remove_child(child)
			child.queue_free()
	_summary.text = "%d relics  /  9 clock sockets  /  %d reserves     •     %d OVERKILL" % [RunManager.clock_inventory.size(), maxi(0, RunManager.clock_inventory.size() - 9), OKRunState.current_ok]
	if mode == "shop": _summary.text = "%d OVERKILL AVAILABLE     ·     CLOCK RELICS COST 15     ·     ARTIFACTS ARE UNIQUE AND RUN-WIDE" % OKRunState.current_ok
	if mode == "upgrade": _summary.text += "     •     One free upgrade this visit."
	if mode == "removal": _summary.text += "     •     Keep at least 10 relics."
	if mode == "collection":
		_summary.text = "%d INDIVIDUAL RELICS  /  9 CLOCK SOCKETS  /  %d RESERVES     •     %d OVERKILL" % [RunManager.clock_inventory.size(), maxi(0, RunManager.clock_inventory.size() - 9), OKRunState.current_ok]
		for index: int in RunManager.clock_inventory.size():
			var entry: Dictionary = RunManager.clock_inventory[index]
			var relic := ClockInventory.resolve(entry)
			if relic == null:
				continue
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			view.use_collection_layout()
			view.bind_relic(relic, "")
			view.set_instance_identities([entry])
		return
	if mode == "upgrade":
		# Every owned copy is its own forge target. Keep a compact per-design
		# ordinal so identical relics are visually distinguishable without hiding
		# them behind an aggregate stack count.
		var design_totals: Dictionary = {}
		for entry: Dictionary in RunManager.clock_inventory:
			var relic_id: String = str(entry.get("id", ""))
			design_totals[relic_id] = int(design_totals.get(relic_id, 0)) + 1
		var design_seen: Dictionary = {}
		var ready_count: int = 0
		for owned: Dictionary in RunManager.clock_inventory:
			if int(owned.get("level", 0)) == 0:
				ready_count += 1
		_summary.text = "%d INDIVIDUAL RELICS  /  9 CLOCK SOCKETS  /  %d RESERVES     •     %d READY TO UPGRADE" % [RunManager.clock_inventory.size(), maxi(0, RunManager.clock_inventory.size() - 9), ready_count]
		for entry: Dictionary in RunManager.clock_inventory:
			var relic_id: String = str(entry.get("id", ""))
			var copy_number: int = int(design_seen.get(relic_id, 0)) + 1
			design_seen[relic_id] = copy_number
			var copy_total: int = int(design_totals.get(relic_id, 1))
			var relic: ClockRelicData = ClockInventory.resolve(entry)
			if relic == null:
				continue
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			var is_ready: bool = int(entry.get("level", 0)) == 0
			var action: String = "UPGRADE COPY  %d / %d" % [copy_number, copy_total] if is_ready else "COPY  %d / %d  ·  UPGRADED" % [copy_number, copy_total]
			view.bind_relic(relic, action)
			view._role_badge.text += "    ·    COPY %d / %d" % [copy_number, copy_total]
			view._slot_button.disabled = not is_ready
			if is_ready:
				var upgraded: Dictionary = entry.duplicate()
				upgraded.level = 1
				var tempered: ClockRelicData = ClockInventory.resolve(upgraded)
				view.tooltip_text = "COPY %d / %d\nTARGET INSTANCE\n%s\n\nCURRENT\n%s\n\nAFTER UPGRADE\n%s" % [copy_number, copy_total, ClockInventory.instance_identity(entry), relic.description, tempered.description]
				var target_uid: int = int(entry.get("uid", -1))
				view.selected.connect(func(_r: ClockRelicData) -> void: _choose(target_uid))
			else:
				view.tooltip_text += "\n\nINSTANCE\n%s" % ClockInventory.instance_identity(entry)
		return
	if mode == "shop":
		for relic: ClockRelicData in _offers:
			var price := RunManager.price_for("clock_relic", 15)
			var view: RelicPedestalView = Pedestal.instantiate()
			_grid.add_child(view)
			view.use_shop_layout()
			view.bind_relic(relic, "Buy · %d Overkill" % price)
			view._slot_button.disabled = OKRunState.current_ok < price or RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE
			if view._slot_button.disabled:
				view._slot_button.text = "CHRONOMETER FULL" if RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE else "Need %d more" % (price - OKRunState.current_ok)
				view._slot_button.tooltip_text = "Dismantle or replace a relic before adding another." if RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE else "Not enough Overkill."
			view.selected.connect(func(_r: ClockRelicData) -> void: _buy(relic, price))
		for relic: RelicData in _artifact_offers:
			_build_artifact_offer(relic)
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
			action = "PREVIEW UPGRADE" if int(entry.level) == 0 else "ALREADY UPGRADED"
			if int(entry.level) == 0:
				var upgraded := entry.duplicate()
				upgraded.level = 1
				view.tooltip_text = "TARGET INSTANCE\n%s\n\nCURRENT\n%s\n\nAFTER UPGRADE\n%s" % [ClockInventory.instance_identity(entry), relic.description, ClockInventory.resolve(upgraded).description]
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
	if RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE: return
	if not _offers.has(relic) or not OKRunState.spend_ok(price, "clock_relic"): return
	if not RunManager.add_clock_relic(relic.id): return
	RunManager.record_purchase("clock_relic")
	_offers.erase(relic)
	SaveManager.save_run()
	_rebuild()


func _build_artifact_offer(relic: RelicData) -> void:
	var offer := VBoxContainer.new()
	# Keep the CTA inside the first desktop viewport; the parent ScrollContainer
	# remains available for smaller windows without clipping the purchase action.
	offer.custom_minimum_size = Vector2(246.0, 286.0)
	offer.add_theme_constant_override("separation", 2)
	_artifact_grid.add_child(offer)
	var art_stage := Control.new()
	art_stage.custom_minimum_size = Vector2(0.0, 112.0)
	art_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	offer.add_child(art_stage)
	var aura := TextureRect.new()
	aura.texture = load(_artifact_aura_path(relic))
	aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	aura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aura.modulate = Color(1.0, 1.0, 1.0, 0.46)
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_stage.add_child(aura)
	AmbientMotion.pulse_alpha(aura, 0.34, 0.49, 3.2)
	var art := TextureRect.new()
	art.texture = RelicArt.load_texture(relic.art_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 18.0
	art.offset_right = -18.0
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_stage.add_child(art)
	AmbientMotion.idle_bob(art, 3.0, 3.1)
	var color: Color = _artifact_color(relic)
	var label := ScreenDesign.label(offer, relic.display_name.to_upper(), 24, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = 32.0
	var detail := ScreenDesign.label(offer, _artifact_description(relic), 16, ScreenDesign.TEXT)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 48.0
	var price: int = RunManager.price_for("run_artifact", 30)
	var buy := Button.new()
	buy.custom_minimum_size.y = 48.0
	buy.text = "PURCHASE  ·  %d OVERKILL" % price if not _artifact_purchase_made else "ONE ARTIFACT PER VISIT"
	buy.disabled = _artifact_purchase_made or OKRunState.current_ok < price
	if not _artifact_purchase_made and OKRunState.current_ok < price:
		buy.text = "NEED %d MORE OVERKILL" % (price - OKRunState.current_ok)
	ScreenDesign.add_actionable_fx(buy, color, true)
	buy.pressed.connect(func() -> void: _buy_artifact(relic, price))
	art_stage.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not buy.disabled:
			_buy_artifact(relic, price)
			art_stage.accept_event()
	)
	offer.add_child(buy)


func _buy_artifact(relic: RelicData, price: int) -> void:
	if _artifact_purchase_made or not _artifact_offers.has(relic) or RunManager.has_relic(relic.id):
		return
	if OKRunState.current_ok < price or not OKRunState.spend_ok(price, "run_artifact"):
		return
	if not RunManager.add_relic(relic):
		OKRunState.gain_ok(price, "artifact_purchase_rollback")
		return
	_artifact_purchase_made = true
	_artifact_offers.erase(relic)
	RunManager.record_purchase("run_artifact")
	SaveManager.save_run()
	_rebuild()


func _artifact_color(relic: RelicData) -> Color:
	match str(relic.condition_data.get("essence", "blue")):
		"orange": return Color("ff9a36")
		"blood_red": return Color("cf5e5b")
		"green": return Color("77d28b")
		"purple": return Color("bd83ed")
		_: return Color("76d9ee")


func _artifact_aura_path(relic: RelicData) -> String:
	var essence: String = str(relic.condition_data.get("essence", "blue"))
	var path: String = "res://assets/relics/essence_sunbursts/%s.png" % essence
	return path if ResourceLoader.exists(path) else "res://assets/relics/essence_sunbursts/blue.png"


func _artifact_description(relic: RelicData) -> String:
	var when_text: String = ""
	match relic.trigger:
		RelicData.Trigger.ON_COMBAT_START: when_text = "Battle start"
		RelicData.Trigger.ON_KILL: when_text = "First kill"
		RelicData.Trigger.ON_OVERKILL: when_text = "Qualifying Overkill"
		RelicData.Trigger.ON_PLAYER_ATTACK: when_text = "First attack"
		RelicData.Trigger.ON_BLOCK_GAIN: when_text = "Block relic"
		RelicData.Trigger.ON_PLAYER_HIT: when_text = "After a hit"
		_: when_text = "When its condition is met"
	var effect_text: String = ""
	for effect: EffectData in relic.effects:
		match effect.effect_type:
			EffectData.EffectType.BLOCK: effect_text = "+%d Block" % effect.value
			EffectData.EffectType.GAIN_OK: effect_text = "+%d Overkill" % effect.value
			EffectData.EffectType.HEAL: effect_text = "+%d Vitality" % effect.value
			EffectData.EffectType.APPLY_STATUS:
				effect_text = "Weaken next strike" if relic.trigger == RelicData.Trigger.ON_PLAYER_HIT and effect.status_id == "weak" else "Apply %d %s" % [effect.value, effect.status_id.capitalize()]
			EffectData.EffectType.ATTACK_BONUS: effect_text = "+%d damage" % effect.value
			EffectData.EffectType.STRENGTH: effect_text = "+%d Strength" % effect.value
	var limit_text: String = " · 1/battle" if bool(relic.condition_data.get("once_per_combat", false)) else ""
	return "%s: %s%s" % [when_text, effect_text, limit_text]

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
			_upgrade_preview = get_child(get_child_count() - 1) as UpgradePreviewDialog
			_upgrade_preview.completed.connect(_close)
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
		if is_instance_valid(_upgrade_preview): _upgrade_preview.show_relic_success()
	else:
		_committed = false
		if is_instance_valid(_upgrade_preview): _upgrade_preview.show_relic_failure()

func _close() -> void:
	if pre_battle: resolved.emit()
	elif overlay: GameFlow.close_deck_view()
	else: GameFlow.goto_map()
