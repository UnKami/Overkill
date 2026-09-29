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
	_background.show()
	get_node("ColorFallback").hide()
	_load_background_art()
	_background.modulate = Color(0.58, 0.62, 0.68)
	ScreenDesign.shade(self)
	ScreenDesign.frame(self,"JOURNEY COMPLETE" if _won else "JOURNEY ENDED")
	_title_label.text = "The cycle is broken." if _won else "The clock falls silent."
	_title_label.modulate = Color.WHITE
	_title_label.add_theme_font_override("font",ScreenDesign.display_font())
	_title_label.add_theme_font_size_override("font_size",48)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel.reparent(self)
	_panel.anchor_left = 0.075
	_panel.anchor_right = 0.47
	_panel.anchor_top = 0.22
	_panel.anchor_bottom = 0.22
	_panel.offset_left = 0
	_panel.offset_right = 0
	_panel.offset_top = 0
	_panel.offset_bottom = 0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("091520e3")
	panel_style.border_color = Color("c9aa7699")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000c4")
	panel_style.shadow_size = 28
	panel_style.shadow_offset = Vector2(0, 12)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var total_spent := 0
	for entry in OKRunState.ok_spent_log:
		total_spent += int(entry.get("amount", 0))
	var stack: VBoxContainer = _title_label.get_parent()
	var kicker := ScreenDesign.label(stack, "FINAL CHRONICLE" if _won else "FRACTURED CHRONICLE", 15, ScreenDesign.CYAN if _won else Color("d98576"))
	stack.move_child(kicker, 0)
	var rule := ScreenDesign.rule(stack, ScreenDesign.GOLD)
	stack.move_child(rule, _title_label.get_index() + 1)
	_ok_summary_label.text = "THE HOURS HOLD YOUR RECORD." if _won else "THE MECHANISM REMEMBERS HOW FAR YOU CARRIED IT."
	_ok_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ok_summary_label.add_theme_font_size_override("font_size", 16)
	_ok_summary_label.add_theme_color_override("font_color", ScreenDesign.MUTED)
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 12)
	stats.add_theme_constant_override("v_separation", 12)
	stack.add_child(stats)
	stack.move_child(stats, _ok_summary_label.get_index() + 1)
	_add_stat(stats, "ACT REACHED", "FINAL" if _won else str(RunManager.act_number))
	_add_stat(stats, "VITALITY", "%d / %d" % [RunManager.current_hp, RunManager.max_hp])
	_add_stat(stats, "BOUND RELICS", str(RunManager.clock_inventory.size()))
	_add_stat(stats, "BEST KILL", str(OKRunState.best_single_hit_ok_this_run))
	_add_stat(stats, "BEST TURN", str(OKRunState.best_turn_total_ok_this_run))
	_add_stat(stats, "OVERKILL EARNED", str(OKRunState.current_ok + total_spent))
	_add_stat(stats, "OVERKILL SPENT", str(total_spent))
	_add_stat(stats, "OVERKILL BANKED", str(OKRunState.current_ok))
	_return_button.text = "RETURN TO THE CHRONOFORGE"
	_return_button.custom_minimum_size.y = 62

	_return_button.pressed.connect(func() -> void: GameFlow.goto_title())

	# This is the moment a run resolves - the panel gets a reveal punch
	# (an action beat), then the screen settles into slow idle motion:
	# cyan-dominant embers for victory, amber-dominant (dying fire) for
	# defeat, mirroring the win/lose key art's color balance.
	ScreenDesign.reveal(_panel)
	_return_button.grab_focus()


func _add_stat(parent: GridContainer, caption: String, value: String) -> void:
	var plate := PanelContainer.new()
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0f202bd9")
	style.border_color = Color("70808a66")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	plate.add_theme_stylebox_override("panel", style)
	parent.add_child(plate)
	var row := HBoxContainer.new()
	plate.add_child(row)
	var name_label := ScreenDesign.label(row, caption, 13, ScreenDesign.MUTED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := ScreenDesign.label(row, value, 20, ScreenDesign.TEXT, true)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _load_background_art() -> void:
	var path := CinematicArt.VICTORY if _won else CinematicArt.DEFEAT
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		AmbientMotion.apply_cinematic_backdrop(self, _background, 56.0, 0.72 if _won else 0.48)
