extends Control
## Pause menu overlay (pause/settings doc Part 2) - a control surface, not a
## second HUD: no re-display of gameplay info beyond what's listed here.
## process_mode ALWAYS so its own buttons stay responsive while the tree is
## paused (GameFlow.open_pause_menu sets get_tree().paused = true).

@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _view_deck_button: Button = %ViewDeckButton
@onready var _abandon_button: Button = %AbandonButton
@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	ScreenDesign.polish(self)
	var panel: PanelContainer = get_node("CenterContainer/Panel")
	panel.custom_minimum_size.x = 620
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("091520f2")
	panel_style.border_color = Color("c9aa768c")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000d6")
	panel_style.shadow_size = 30
	panel_style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", panel_style)
	var stack: VBoxContainer = _resume_button.get_parent()
	var title: Label = stack.get_node("TitleLabel")
	title.text = "JOURNEY PAUSED"
	title.add_theme_font_size_override("font_size", 38)
	var kicker := ScreenDesign.label(stack, "THE CLOCK WAITS", 14, ScreenDesign.CYAN)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.move_child(kicker, 0)
	var subtitle := ScreenDesign.label(stack, "Your current run is safe.", 17, ScreenDesign.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.move_child(subtitle, title.get_index() + 1)
	var rule := ScreenDesign.rule(stack, ScreenDesign.GOLD)
	stack.move_child(rule, subtitle.get_index() + 1)
	_resume_button.text = "RESUME JOURNEY"
	_settings_button.text = "SETTINGS"
	_view_deck_button.text = "VIEW RELIQUARY"
	_main_menu_button.text = "RETURN TO TITLE"
	_abandon_button.text = "ABANDON RUN"
	for button: Button in [_resume_button, _settings_button, _view_deck_button, _main_menu_button, _abandon_button]:
		button.custom_minimum_size.y = 58
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_resume_button.grab_focus()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var combat := get_tree().current_scene as CombatController
	if combat != null:
		_add_combat_reference_button(stack, "COMBAT LOG", combat.show_combat_log)
		_add_combat_reference_button(stack, "HOW TO PLAY", combat.show_combat_manual)
	_resume_button.pressed.connect(func() -> void: GameFlow.close_pause_menu())
	_settings_button.pressed.connect(func() -> void: GameFlow.open_settings())
	_view_deck_button.pressed.connect(func() -> void: GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE))
	_abandon_button.pressed.connect(_on_abandon_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)


func _add_combat_reference_button(stack: VBoxContainer, label_text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.theme_type_variation = &"SecondaryButton"
	button.custom_minimum_size.y = 58
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	stack.add_child(button)
	stack.move_child(button, _view_deck_button.get_index())


func _on_abandon_pressed() -> void:
	var panel: Control = get_node("CenterContainer/Panel")
	panel.hide()
	var dialog: ModalConfirmDialog = ModalConfirmDialog.show_dialog(
		self,
		"Abandon this run? Your current path, bound relics, cards, and unbanked Overkill will be lost. This cannot be undone.",
		"ABANDON RUN",
		func() -> void: GameFlow.abandon_run(),
		true
	)
	dialog.cancelled.connect(func() -> void:
		if is_instance_valid(panel): panel.show()
	)


func _on_main_menu_pressed() -> void:
	if not RunManager.run_active:
		GameFlow.close_pause_menu()
		GameFlow.goto_title()
		return
	var message: String = "Return to the main menu? Your current run will be saved and can be resumed with Continue."
	if str(RunManager.resume_context.get("kind", "")) == "combat":
		message = "Return to the main menu? Continue will restart this encounter with the vitality, relics and Overkill you had when it began."
	elif str(RunManager.resume_context.get("kind", "")) == "prebattle":
		message = "Return to the main menu? Continue will return to the offer before this battle. Any unfinished choice will be reset."
	ModalConfirmDialog.show_dialog(
		self,
		message,
		"Return to Menu",
		func() -> void:
			SaveManager.save_run()
			GameFlow.close_pause_menu()
			GameFlow.goto_title()
	)
