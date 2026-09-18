extends Control
var _new_run_button: Button
var _continue_button: Button
var _replace_confirmation: ConfirmationDialog

func _ready() -> void:
	theme = ScreenDesign.build_theme()
	var stage := preload("res://scripts/ui/frontend_stage.gd").new()
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ScreenDesign.shade(self)
	ScreenDesign.frame(self,"THE CHRONOFORGE")
	var column := ScreenDesign.column(self,0.22)
	ScreenDesign.label(column,"A CLOCKWORK ROGUELIKE",18,ScreenDesign.CYAN)
	ScreenDesign.label(column,"OVERKILL",86,ScreenDesign.TEXT,true)
	ScreenDesign.label(column,"Every hour is a weapon.",26,ScreenDesign.GOLD,true)
	ScreenDesign.spacer(column,22)
	ScreenDesign.rule(column)
	ScreenDesign.spacer(column,12)
	_continue_button = ScreenDesign.button(column,"CONTINUE JOURNEY   ›",_on_continue_pressed,true)
	_continue_button.visible = SaveManager.has_run_save()
	_new_run_button = ScreenDesign.button(column,"NEW JOURNEY   ›",_new_journey,not _continue_button.visible)
	ScreenDesign.button(column,"SETTINGS",func() -> void: GameFlow.open_settings())
	ScreenDesign.button(column,"QUIT GAME",func() -> void: get_tree().quit())
	if _continue_button.visible:
		var data := SaveManager.load_run()
		ScreenDesign.label(column,"JOURNEY IN PROGRESS  /  ACT %d" % int(data.get("act_number",1)),16,ScreenDesign.MUTED)
	_replace_confirmation = ConfirmationDialog.new()
	_replace_confirmation.title = "Begin a new journey?"
	_replace_confirmation.dialog_text = "Your current journey will be replaced when you begin the new run."
	_replace_confirmation.ok_button_text = "Choose character"
	_replace_confirmation.confirmed.connect(func() -> void: GameFlow.goto_class_select())
	add_child(_replace_confirmation)
	(_continue_button if _continue_button.visible else _new_run_button).grab_focus()
	ScreenDesign.reveal(column)
	ScreenDesign.apply_text_size(self)

func _new_journey() -> void:
	if SaveManager.has_run_save(): _replace_confirmation.popup_centered(Vector2i(620,210))
	else: GameFlow.goto_class_select()

func _on_continue_pressed() -> void:
	var data := SaveManager.load_run()
	if data.is_empty(): return
	RunManager.load_from_save(data)
	GameFlow.goto_map()
