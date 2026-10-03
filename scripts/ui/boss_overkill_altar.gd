class_name BossOverkillAltar extends Control
## A one-choice, priced Zenith offer after each act boss. Uses the same run
## currency and 12-copy inventory rules as the rest of the game.

const OFFER_IDS := ["REL-27", "REL-28", "REL-29"]
const PRICES := {"REL-27": 25, "REL-28": 35, "REL-29": 45}
const BACKDROP := "res://assets/screens/cinematic/boss_overkill_altar.jpg"

var _boss: EnemyData
var _purchased: bool = false
var _departed: bool = false
var _pending_id: String = ""
var _balance_label: Label
var _status_label: Label
var _offer_buttons: Array[Button] = []
var _main_panel: PanelContainer
var _modal: PanelContainer
var _modal_kicker: Label
var _modal_title: Label
var _modal_detail: Label
var _replacement_scroll: ScrollContainer
var _replacement_grid: GridContainer
var _selection_label: Label
var _selected_replacement_uid: int = -1
var _selected_replacement_button: Button
var _confirm_button: Button
var _leave_button: Button


func set_boss_context(enemy_data: EnemyData) -> void:
	_boss = enemy_data


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_build_backdrop()
	_build_main_panel()
	_build_modal()
	_refresh_balance()
	_show_arrival()


func _build_backdrop() -> void:
	var art := TextureRect.new()
	art.name = "AltarBackdrop"
	art.texture = load(BACKDROP) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AmbientMotion.apply_cinematic_backdrop(self, art, 26.0, 0.45)
	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.025, 0.045, 0.16)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_main_panel() -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "AltarOfferPanel"
	_main_panel.set_anchors_preset(Control.PRESET_CENTER)
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_width: float = minf(1480.0, viewport_size.x - 96.0)
	var panel_height: float = minf(980.0, viewport_size.y - 72.0)
	_main_panel.offset_left = -panel_width * 0.5
	_main_panel.offset_right = panel_width * 0.5
	_main_panel.offset_top = -panel_height * 0.5
	_main_panel.offset_bottom = panel_height * 0.5
	_main_panel.add_theme_stylebox_override("panel", ScreenDesign.box(Color("06121ea3"), Color("c2a575a8"), 1))
	add_child(_main_panel)
	var column := VBoxContainer.new()
	column.name = "VBoxContainer"
	column.add_theme_constant_override("separation", 12)
	_main_panel.add_child(column)
	var kicker := _make_label("ACT GUARDIAN FALLEN    /    THE OVERKILL ALTAR", 16, Color("e3bb82"))
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(kicker)
	var title := _make_label("POWER HAS A PRICE", 49, Color("f8e9cf"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var premise := _make_label("The damage you dealt beyond death has become power. Bind one Zenith relic before the next descent.", 22, Color("c2d5da"))
	premise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	premise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	premise.custom_minimum_size.y = 48.0
	column.add_child(premise)
	var rule := ScreenDesign.rule(column, Color("d7b680"))
	rule.custom_minimum_size.y = 2.0
	_balance_label = _make_label("", 27, Color("f3c27e"))
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_balance_label)
	var offer_row := HBoxContainer.new()
	offer_row.name = "ZenithOffers"
	offer_row.add_theme_constant_override("separation", 20)
	offer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(offer_row)
	for id: String in OFFER_IDS:
		var relic: ClockRelicData = ContentDatabase.get_clock_relic(id)
		if relic != null:
			_build_offer(offer_row, relic, int(PRICES[id]))
	_status_label = _make_label("One purchase at this altar. You may leave and keep your Overkill Points.", 18, Color("afc3c9"))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_status_label)
	_leave_button = Button.new()
	_leave_button.text = "CONTINUE TO THE NEXT DESCENT  ›"
	_leave_button.custom_minimum_size = Vector2(430.0, 62.0)
	_leave_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_leave_button.pressed.connect(_continue_after_altar)
	ScreenDesign.add_actionable_fx(_leave_button, Color("e3bb82"), true)
	column.add_child(_leave_button)


func _build_offer(parent: HBoxContainer, relic: ClockRelicData, price: int) -> void:
	var card := PanelContainer.new()
	card.name = relic.id
	var card_width: float = minf(410.0, (get_viewport_rect().size.x - 180.0) / 3.0)
	card.custom_minimum_size = Vector2(card_width, 530.0)
	card.add_theme_stylebox_override("panel", ScreenDesign.box(Color("071522a6"), relic.primary_color().darkened(0.32), 1))
	parent.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 7)
	card.add_child(inner)
	var tier := _make_label("ZENITH    /    %s" % ClockRelicData.role_to_name(relic.role).to_upper(), 14, relic.primary_color())
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(tier)
	var art := TextureRect.new()
	art.texture = RelicArt.load_texture(relic.art_id)
	art.custom_minimum_size = Vector2(card_width - 44.0, 238.0)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(art)
	var name_label := _make_label(relic.name.to_upper(), 24, Color("fae8cf"), true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(name_label)
	var effect := _make_label(relic.description, 17, Color("dae5e6"))
	effect.custom_minimum_size.y = 77.0
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(effect)
	var buy := Button.new()
	buy.name = "BuyButton"
	buy.text = "BIND  ·  %d OVERKILL" % price
	buy.custom_minimum_size.y = 56.0
	buy.alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy.pressed.connect(func() -> void: _open_purchase(relic.id))
	ScreenDesign.add_actionable_fx(buy, relic.primary_color(), true)
	inner.add_child(buy)
	_offer_buttons.append(buy)


func _build_modal() -> void:
	_modal = PanelContainer.new()
	_modal.name = "PurchaseScreen"
	_modal.set_anchors_preset(Control.PRESET_CENTER)
	var viewport_size: Vector2 = get_viewport_rect().size
	var modal_width: float = minf(1360.0, viewport_size.x - 48.0)
	var modal_height: float = minf(880.0, viewport_size.y - 40.0)
	_modal.offset_left = -modal_width * 0.5
	_modal.offset_right = modal_width * 0.5
	_modal.offset_top = -modal_height * 0.5
	_modal.offset_bottom = modal_height * 0.5
	_modal.add_theme_stylebox_override("panel", ScreenDesign.box(Color("07121cf8"), Color("e7c48a"), 2))
	add_child(_modal)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_modal.add_child(column)
	_modal_kicker = _make_label("ZENITH BINDING", 15, Color("e7c48a"))
	_modal_kicker.name = "PurchaseKicker"
	_modal_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_modal_kicker)
	_modal_title = _make_label("", 37, Color("f6e8d0"), true)
	_modal_title.name = "PurchaseTitle"
	_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_modal_title)
	_modal_detail = _make_label("", 21, Color("c5d7da"))
	_modal_detail.name = "PurchaseDetail"
	_modal_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_detail.custom_minimum_size.y = 68.0
	column.add_child(_modal_detail)
	_replacement_scroll = ScrollContainer.new()
	_replacement_scroll.name = "ReplacementChoicesScroll"
	_replacement_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_replacement_scroll.custom_minimum_size.y = 240.0
	_replacement_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_replacement_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(_replacement_scroll)
	_replacement_grid = GridContainer.new()
	_replacement_grid.name = "ReplacementChoices"
	_replacement_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_replacement_grid.add_theme_constant_override("h_separation", 12)
	_replacement_grid.add_theme_constant_override("v_separation", 10)
	_replacement_scroll.add_child(_replacement_grid)
	_selection_label = _make_label("Select the exact relic copy to replace.", 17, Color("b6c8cf"))
	_selection_label.name = "ReplacementConsequence"
	_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_selection_label)
	_confirm_button = Button.new()
	_confirm_button.custom_minimum_size.y = 60.0
	_confirm_button.pressed.connect(_confirm_purchase)
	ScreenDesign.add_actionable_fx(_confirm_button, Color("e7c48a"), true)
	column.add_child(_confirm_button)
	var cancel := Button.new()
	cancel.name = "BackToAltar"
	cancel.text = "‹  BACK TO THE ALTAR"
	cancel.custom_minimum_size.y = 52.0
	cancel.pressed.connect(_cancel_purchase)
	column.add_child(cancel)
	_modal.hide()


func _open_purchase(id: String) -> void:
	if _purchased or _departed:
		return
	var relic: ClockRelicData = ContentDatabase.get_clock_relic(id)
	var price: int = int(PRICES.get(id, 0))
	if relic == null or price <= 0 or OKRunState.current_ok < price:
		return
	_pending_id = id
	_selected_replacement_uid = -1
	_selected_replacement_button = null
	for child: Node in _replacement_grid.get_children():
		_replacement_grid.remove_child(child)
		child.queue_free()
	var full: bool = RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE
	_replacement_scroll.visible = full
	_selection_label.visible = full
	if full:
		_modal_kicker.text = "ZENITH REPLACEMENT  ·  A BINDING MUST BE CHOSEN"
		_modal_title.text = "CHOOSE A RELIC TO REPLACE"
		_modal_detail.text = "%s\n\nBinding %s costs %d Overkill; your bank will be %d." % [relic.description, relic.name, price, OKRunState.current_ok - price]
		_selection_label.text = "Choose one of your individual relic copies. The selected relic will be lost."
		_build_replacement_choices()
	else:
		_modal_kicker.text = "SEAL THE BARGAIN"
		_modal_title.text = relic.name.to_upper()
		_modal_detail.text = "%s\n\nCost: %d Overkill  ·  Bank after purchase: %d" % [relic.description, price, OKRunState.current_ok - price]
	_update_confirm_state()
	_main_panel.hide()
	_modal.show()
	_modal.move_to_front()
	call_deferred("_fit_purchase_screen")


func _fit_purchase_screen() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var full: bool = RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE
	var modal_width: float = minf(1360.0 if full else 980.0, viewport_size.x - 48.0)
	var modal_height: float = minf(880.0 if full else 560.0, viewport_size.y - 40.0)
	_modal.offset_left = -modal_width * 0.5
	_modal.offset_right = modal_width * 0.5
	_modal.offset_top = -modal_height * 0.5
	_modal.offset_bottom = modal_height * 0.5
	var columns: int = 4 if modal_width >= 1180.0 else (3 if modal_width >= 860.0 else 2)
	_replacement_grid.columns = columns
	_replacement_scroll.custom_minimum_size.y = clampf(modal_height - 460.0, 120.0, 340.0) if full else 0.0
	var gaps: float = float(columns - 1) * 12.0
	var choice_width: float = maxf(0.0, (modal_width - 104.0 - gaps) / float(columns))
	for choice: Button in _replacement_grid.get_children():
		choice.custom_minimum_size = Vector2(choice_width, 112.0)


func _build_replacement_choices() -> void:
	for entry: Dictionary in RunManager.clock_inventory:
		var owned: ClockRelicData = ClockInventory.resolve(entry)
		if owned == null:
			continue
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(240.0, 112.0)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.icon = RelicArt.load_texture(owned.art_id)
		choice.expand_icon = true
		choice.add_theme_constant_override("icon_max_width", 76)
		choice.add_theme_font_size_override("font_size", 18)
		choice.text = "%s\n%s" % [owned.name.to_upper(), ClockInventory.instance_identity(entry)]
		choice.tooltip_text = "%s\n%s\n\n%s" % [ClockInventory.instance_identity(entry), owned.name, owned.description]
		choice.set_meta("replacement_uid", int(entry.get("uid", -1)))
		choice.set_meta("replacement_color", owned.primary_color())
		choice.pressed.connect(_select_replacement.bind(choice))
		ScreenDesign.add_actionable_fx(choice, owned.primary_color(), false)
		_replacement_grid.add_child(choice)
	_fit_purchase_screen()


func _select_replacement(choice: Button) -> void:
	if not is_instance_valid(choice):
		return
	if is_instance_valid(_selected_replacement_button):
		for state: String in ["normal", "hover", "pressed", "focus"]:
			_selected_replacement_button.remove_theme_stylebox_override(state)
	_selected_replacement_button = choice
	_selected_replacement_uid = int(choice.get_meta("replacement_uid", -1))
	var color: Color = choice.get_meta("replacement_color", Color("e7c48a"))
	var selected_style: StyleBoxFlat = ScreenDesign.box(Color("243747f2"), color, 2)
	choice.add_theme_stylebox_override("normal", selected_style)
	choice.add_theme_stylebox_override("hover", selected_style)
	choice.add_theme_stylebox_override("pressed", selected_style)
	_selection_label.text = "Replacing %s  ·  %s" % [choice.text.get_slice("\n", 0), choice.text.get_slice("\n", 1)]
	_update_confirm_state()


func _cancel_purchase() -> void:
	_pending_id = ""
	_selected_replacement_uid = -1
	_selected_replacement_button = null
	_modal.hide()
	_main_panel.show()


func _update_confirm_state() -> void:
	var full: bool = RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE
	_confirm_button.text = "SPEND OVERKILL & REPLACE RELIC" if full else "SPEND OVERKILL & BIND RELIC"
	_confirm_button.disabled = full and _selected_replacement_uid < 0


func _confirm_purchase() -> void:
	if _pending_id.is_empty() or _purchased or _departed:
		return
	var price: int = int(PRICES.get(_pending_id, 0))
	if price <= 0 or OKRunState.current_ok < price:
		_modal.hide()
		_refresh_balance()
		return
	var full: bool = RunManager.clock_inventory.size() >= ClockInventory.MAX_SIZE
	var replacement_uid: int = -1
	if full:
		if _selected_replacement_uid < 0:
			return
		replacement_uid = _selected_replacement_uid
	if not OKRunState.spend_ok(price, "boss_zenith:%s" % _pending_id):
		return
	var accepted: bool = RunManager.replace_clock_relic(replacement_uid, _pending_id) if full else RunManager.add_clock_relic(_pending_id)
	if not accepted:
		OKRunState.gain_ok(price, "boss_zenith_refund")
		_modal.hide()
		_main_panel.show()
		_refresh_balance()
		return
	_purchased = true
	_modal.hide()
	_main_panel.show()
	var bound: ClockRelicData = ContentDatabase.get_clock_relic(_pending_id)
	_status_label.text = "%s BOUND. The next act begins with a different clock." % bound.name.to_upper()
	for button: Button in _offer_buttons:
		button.disabled = true
	_leave_button.text = "CARRY THIS POWER FORWARD  ›"
	SaveManager.save_run()
	_refresh_balance()


func _refresh_balance() -> void:
	_balance_label.text = "YOUR OVERKILL BANK     %d" % OKRunState.current_ok
	for index: int in _offer_buttons.size():
		var price: int = int(PRICES[OFFER_IDS[index]])
		var button: Button = _offer_buttons[index]
		button.disabled = _purchased or OKRunState.current_ok < price
		if not _purchased:
			button.text = "BIND  ·  %d OVERKILL" % price if OKRunState.current_ok >= price else "NEED %d MORE OVERKILL" % (price - OKRunState.current_ok)


func _show_arrival() -> void:
	var panel: Control = get_node("AltarOfferPanel") as Control
	panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _continue_after_altar() -> void:
	if _departed:
		return
	_departed = true
	SaveManager.save_run()
	if _boss != null and _boss.id == "act3_boss":
		GameFlow.goto_act_transition(
			CinematicArt.transition_background(3),
			"THE FINAL DESCENT",
			func() -> void:
				var final_boss: EnemyData = ContentDatabase.get_enemy("final_boss")
				if final_boss != null:
					var enemies: Array[EnemyData] = [final_boss]
					GameFlow.goto_combat(enemies)
		)
		return
	var next_act: int = RunManager.act_number + 1
	var background_path: String = CinematicArt.transition_background(RunManager.act_number)
	GameFlow.goto_act_transition(
		background_path,
		"ACT %d" % next_act,
		func() -> void:
			RunManager.advance_act()
			SaveManager.save_run()
			GameFlow.goto_map()
	)


func _make_label(value: String, font_size: int, color: Color, display: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if display:
		label.add_theme_font_override("font", ScreenDesign.display_font())
	return label
