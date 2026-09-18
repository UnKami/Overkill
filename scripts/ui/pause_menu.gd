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
	get_node("CenterContainer/Panel").custom_minimum_size.x = 540
	_resume_button.grab_focus()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(func() -> void: GameFlow.close_pause_menu())
	_settings_button.pressed.connect(func() -> void: GameFlow.open_settings())
	_view_deck_button.pressed.connect(func() -> void: GameFlow.open_deck_view(GameFlow.DeckViewMode.REFERENCE))
	_abandon_button.pressed.connect(_on_abandon_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)


func _on_abandon_pressed() -> void:
	ModalConfirmDialog.show_dialog(
		self,
		"Abandon this run? Your deck, relics, and progress this run will be lost. This cannot be undone.",
		"Abandon Run",
		func() -> void: GameFlow.abandon_run(),
		true
	)


func _on_main_menu_pressed() -> void:
	if not RunManager.run_active:
		GameFlow.close_pause_menu()
		GameFlow.goto_title()
		return
	ModalConfirmDialog.show_dialog(
		self,
		"Return to the main menu? Your current run will be saved and can be resumed with Continue.",
		"Return to Menu",
		func() -> void:
			SaveManager.save_run()
			GameFlow.close_pause_menu()
			GameFlow.goto_title()
	)
