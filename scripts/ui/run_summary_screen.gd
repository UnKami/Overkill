extends Control
## Run summary / victory-defeat screen (screen composition doc 4.4): OK
## earned/spent gets its own highlighted line, not buried in generic stats.
## By the time this loads, GameFlow has already called RunManager.end_run()
## and SaveManager.delete_run_save() - nothing here mutates run state, it
## only reads the final numbers before the next run resets them.

@onready var _title_label: Label = %TitleLabel
@onready var _ok_summary_label: Label = %OkSummaryLabel
@onready var _return_button: Button = %ReturnButton
@onready var _background: TextureRect = %Background
@onready var _panel: PanelContainer = %Panel

var _won: bool = false


func set_outcome(won: bool) -> void:
	_won = won


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_background.hide()
	get_node("ColorFallback").hide()
	var stage := preload("res://scripts/ui/frontend_stage.gd").new()
	add_child(stage)
	move_child(stage,0)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not _won: stage.player.fall()
	ScreenDesign.shade(self)
	move_child(get_child(-1),1)
	ScreenDesign.frame(self,"JOURNEY COMPLETE" if _won else "JOURNEY ENDED")
	_title_label.text = "The cycle is broken." if _won else "The clock falls silent."
	_title_label.modulate = Color.WHITE
	_title_label.add_theme_font_override("font",ScreenDesign.display_font())
	_title_label.add_theme_font_size_override("font_size",40)
	_panel.reparent(self)
	_panel.anchor_left = 0.075
	_panel.anchor_right = 0.43
	_panel.anchor_top = 0.32
	_panel.anchor_bottom = 0.32
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0

	var total_spent := 0
	for entry in OKRunState.ok_spent_log:
		total_spent += int(entry.get("amount", 0))
	_ok_summary_label.text = "OVERKILL EARNED   %d\nOVERKILL SPENT   %d" % [OKRunState.current_ok + total_spent, total_spent]

	_return_button.pressed.connect(func() -> void: GameFlow.goto_title())

	# This is the moment a run resolves - the panel gets a reveal punch
	# (an action beat), then the screen settles into slow idle motion:
	# cyan-dominant embers for victory, amber-dominant (dying fire) for
	# defeat, mirroring the win/lose key art's color balance.
	ScreenDesign.reveal(_panel)
	_return_button.grab_focus()
	var ember_color: Color = Color(0.4, 0.85, 0.95, 0.5) if _won else Color(0.95, 0.55, 0.25, 0.55)
	AmbientMotion.spawn_embers(self, ember_color, 12, true)


func _load_background_art() -> void:
	var path := "res://assets/screens/win_screen_bg.jpg" if _won else "res://assets/screens/lose_screen_bg.jpg"
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
