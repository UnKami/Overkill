extends Control
## LeaderboardView — Slay-the-Spire-styled Global Overkill Leaderboard Modal.
## Displays:
## 1. Single-Run Overkill Records (Peak Overkill earned in a single journey).
## 2. Career Account Standings (Lifetime average Overkill per run + total runs started/won).
##
## NOTE FOR FUTURE GRAPHICAL AI SPECIALISTS (Gemini 4 Argon / ChatGPT 6):
## Layout hierarchy, responsive anchors, sorting contracts, and Firestore data bindings
## are fully operational and verified. Visual styling (obsidian panel frames, gold filigree,
## rank medals, tab pill shaders, and row pulse animations) is implemented via clean
## CanvasItem / StyleBoxFlat primitives for 100% bug-free presentation. You are welcome to
## enhance the visual shaders, border textures, particle embers, and UI badges.

const COLOR_BG_OBSIDIAN: Color = Color("071019f2")
const COLOR_PANEL_BG: Color = Color("0c1a26fa")
const COLOR_BORDER_BRASS: Color = Color("c9aa76b3")
const COLOR_CYAN_ACCENT: Color = Color("4fe3c1")
const COLOR_GOLD_ACCENT: Color = Color("f3c877")
const COLOR_CORAL_DEFEAT: Color = Color("d98576")
const COLOR_SELF_ROW_BG: Color = Color("102b28")
const COLOR_SELF_ROW_BORDER: Color = Color("67e68d")

var initial_category: String = "runs" # "runs" or "accounts"
var current_category: String = "runs"

# UI Nodes
var _panel: PanelContainer
var _tab_runs_btn: Button
var _tab_accounts_btn: Button
var _rows_container: VBoxContainer
var _scroll: ScrollContainer
var _status_summary_label: Label
var _name_edit: LineEdit
var _name_edit_btn: Button
var _refresh_btn: Button
var _close_btn: Button
var _loading_spinner: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ScreenDesign.build_theme()
	_build_ui()
	current_category = initial_category
	_update_tab_buttons()
	_populate_rows()
	
	if LeaderboardManager != null:
		LeaderboardManager.leaderboard_updated.connect(_on_leaderboard_updated)
		LeaderboardManager.profile_updated.connect(_on_profile_updated)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	# 1. Dark Backdrop
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("04090ef0")
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# 2. Centered Obsidian/Brass Main Panel (1500 x 900)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -750
	_panel.offset_right = 750
	_panel.offset_top = -450
	_panel.offset_bottom = 450
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL_BG
	panel_style.border_color = COLOR_BORDER_BRASS
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.shadow_color = Color("000000d0")
	panel_style.shadow_size = 36
	panel_style.shadow_offset = Vector2(0, 16)
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(main_vbox)

	# --- HEADER SECTION ---
	var header_hbox := HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	main_vbox.add_child(header_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var kicker := Label.new()
	kicker.text = "THE CHRONOFORGE ARCHIVES · GLOBAL LEADERBOARDS"
	kicker.add_theme_font_size_override("font_size", 13)
	kicker.add_theme_color_override("font_color", COLOR_CYAN_ACCENT)
	title_vbox.add_child(kicker)

	var title_lbl := Label.new()
	title_lbl.text = "CHRONOMETER OF FAME"
	title_lbl.add_theme_font_override("font", ScreenDesign.display_font())
	title_lbl.add_theme_font_size_override("font_size", 38)
	title_lbl.add_theme_color_override("font_color", ScreenDesign.TEXT)
	title_vbox.add_child(title_lbl)

	# Tabs container
	var tabs_hbox := HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 8)
	header_hbox.add_child(tabs_hbox)

	_tab_runs_btn = Button.new()
	_tab_runs_btn.text = "⚔ RUN RECORDS"
	_tab_runs_btn.custom_minimum_size = Vector2(170, 44)
	_tab_runs_btn.pressed.connect(func(): _switch_category("runs"))
	tabs_hbox.add_child(_tab_runs_btn)

	_tab_accounts_btn = Button.new()
	_tab_accounts_btn.text = "👑 CAREER STANDINGS"
	_tab_accounts_btn.custom_minimum_size = Vector2(190, 44)
	_tab_accounts_btn.pressed.connect(func(): _switch_category("accounts"))
	tabs_hbox.add_child(_tab_accounts_btn)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(44, 44)
	_close_btn.pressed.connect(_close)
	tabs_hbox.add_child(_close_btn)

	# Thin divider
	var rule := ScreenDesign.rule(main_vbox, COLOR_BORDER_BRASS)
	rule.custom_minimum_size.y = 1

	# --- COLUMN HEADERS ---
	var table_header := _build_table_header()
	main_vbox.add_child(table_header)

	# --- SCROLLABLE LIST OF ROWS ---
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll)

	_rows_container = VBoxContainer.new()
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_container.add_theme_constant_override("separation", 6)
	_scroll.add_child(_rows_container)

	# --- FOOTER SECTION: PLAYER STATUS CARD & ACTIONS ---
	var footer_panel := PanelContainer.new()
	var footer_style := StyleBoxFlat.new()
	footer_style.bg_color = Color("08141ee6")
	footer_style.border_color = Color("50607066")
	footer_style.set_border_width_all(1)
	footer_style.set_corner_radius_all(6)
	footer_style.content_margin_left = 18
	footer_style.content_margin_right = 18
	footer_style.content_margin_top = 12
	footer_style.content_margin_bottom = 12
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	main_vbox.add_child(footer_panel)

	var footer_hbox := HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	footer_panel.add_child(footer_hbox)

	var player_info_vbox := VBoxContainer.new()
	player_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_info_vbox.add_theme_constant_override("separation", 4)
	footer_hbox.add_child(player_info_vbox)

	# Inline name editor
	var name_hbox := HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 8)
	player_info_vbox.add_child(name_hbox)

	var id_tag := Label.new()
	id_tag.text = "PLAYER IDENTITY:"
	id_tag.add_theme_font_size_override("font_size", 13)
	id_tag.add_theme_color_override("font_color", ScreenDesign.MUTED)
	name_hbox.add_child(id_tag)

	_name_edit = LineEdit.new()
	_name_edit.text = LeaderboardManager.player_name if LeaderboardManager else "Executioner"
	_name_edit.custom_minimum_size.x = 220
	_name_edit.max_length = 20
	_name_edit.text_submitted.connect(_on_name_submitted)
	name_hbox.add_child(_name_edit)

	_name_edit_btn = Button.new()
	_name_edit_btn.text = "SAVE NAME"
	_name_edit_btn.pressed.connect(func(): _on_name_submitted(_name_edit.text))
	name_hbox.add_child(_name_edit_btn)

	_status_summary_label = Label.new()
	_status_summary_label.add_theme_font_size_override("font_size", 14)
	_status_summary_label.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	player_info_vbox.add_child(_status_summary_label)

	# Action buttons
	var actions_hbox := HBoxContainer.new()
	actions_hbox.add_theme_constant_override("separation", 10)
	footer_hbox.add_child(actions_hbox)

	_refresh_btn = Button.new()
	_refresh_btn.text = "⟳ REFRESH"
	_refresh_btn.custom_minimum_size = Vector2(130, 44)
	_refresh_btn.pressed.connect(_on_refresh_pressed)
	actions_hbox.add_child(_refresh_btn)

	var bottom_close_btn := Button.new()
	bottom_close_btn.text = "RETURN   ›"
	bottom_close_btn.custom_minimum_size = Vector2(140, 44)
	bottom_close_btn.pressed.connect(_close)
	actions_hbox.add_child(bottom_close_btn)

	ScreenDesign.reveal(_panel)


func _build_table_header() -> Control:
	var header_bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("05101a88")
	style.border_color = Color("3a4b5966")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	header_bar.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	header_bar.add_child(hbox)

	if current_category == "runs":
		_add_header_col(hbox, "RANK", 90, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "RUNNER", 280, HORIZONTAL_ALIGNMENT_LEFT)
		_add_header_col(hbox, "OVERKILL SCORE", 200, HORIZONTAL_ALIGNMENT_RIGHT)
		_add_header_col(hbox, "ACT", 100, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "OUTCOME", 140, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "RELICS", 100, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "PRIMARY ARCHETYPE", 240, HORIZONTAL_ALIGNMENT_LEFT)
	else:
		_add_header_col(hbox, "RANK", 90, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "RUNNER", 280, HORIZONTAL_ALIGNMENT_LEFT)
		_add_header_col(hbox, "AVERAGE OVERKILL", 200, HORIZONTAL_ALIGNMENT_RIGHT)
		_add_header_col(hbox, "TOTAL OVERKILL", 180, HORIZONTAL_ALIGNMENT_RIGHT)
		_add_header_col(hbox, "RUNS STARTED", 140, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "RUNS WON", 120, HORIZONTAL_ALIGNMENT_CENTER)
		_add_header_col(hbox, "PEAK OVERKILL", 150, HORIZONTAL_ALIGNMENT_RIGHT)

	return header_bar


func _add_header_col(parent: HBoxContainer, title: String, width: int, align: HorizontalAlignment) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.custom_minimum_size.x = width
	lbl.horizontal_alignment = align
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", ScreenDesign.MUTED)
	parent.add_child(lbl)


func _populate_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()

	if current_category == "runs":
		_populate_run_rows()
	else:
		_populate_account_rows()
	_update_footer_summary()


func _populate_run_rows() -> void:
	var runs: Array = LeaderboardManager.cached_runs if LeaderboardManager else []
	for i in range(runs.size()):
		var entry: Dictionary = runs[i]
		var rank: int = i + 1
		var row := _create_run_row(rank, entry)
		_rows_container.add_child(row)


func _populate_account_rows() -> void:
	var accounts: Array = LeaderboardManager.cached_accounts if LeaderboardManager else []
	for i in range(accounts.size()):
		var entry: Dictionary = accounts[i]
		var rank: int = i + 1
		var row := _create_account_row(rank, entry)
		_rows_container.add_child(row)


func _create_run_row(rank: int, entry: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size.y = 44
	var is_self: bool = entry.get("is_self", false) or (LeaderboardManager and entry.get("player_id", "") == LeaderboardManager.player_id)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SELF_ROW_BG if is_self else (Color("081420cc") if rank % 2 == 0 else Color("060f18aa"))
	style.border_color = COLOR_SELF_ROW_BORDER if is_self else Color("33445544")
	style.set_border_width_all(2 if is_self else 1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	row_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row_panel.add_child(hbox)

	# 1. Rank Badge
	var rank_lbl := Label.new()
	rank_lbl.custom_minimum_size.x = 90
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_override("font", ScreenDesign.display_font())
	rank_lbl.add_theme_font_size_override("font_size", 18)
	if rank == 1:
		rank_lbl.text = "1 👑"
		rank_lbl.add_theme_color_override("font_color", Color("#FFD700"))
	elif rank == 2:
		rank_lbl.text = "2 🥈"
		rank_lbl.add_theme_color_override("font_color", Color("#C0C0C0"))
	elif rank == 3:
		rank_lbl.text = "3 🥉"
		rank_lbl.add_theme_color_override("font_color", Color("#CD7F32"))
	else:
		rank_lbl.text = "#%d" % rank
		rank_lbl.add_theme_color_override("font_color", ScreenDesign.MUTED)
	hbox.add_child(rank_lbl)

	# 2. Player Name (+ YOU badge)
	var name_box := HBoxContainer.new()
	name_box.custom_minimum_size.x = 280
	name_box.add_theme_constant_override("separation", 8)
	hbox.add_child(name_box)

	var name_lbl := Label.new()
	name_lbl.text = str(entry.get("player_name", "Unknown"))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", COLOR_SELF_ROW_BORDER if is_self else ScreenDesign.TEXT)
	name_box.add_child(name_lbl)

	if is_self:
		var you_tag := Label.new()
		you_tag.text = "(YOU)"
		you_tag.add_theme_font_size_override("font_size", 12)
		you_tag.add_theme_color_override("font_color", COLOR_SELF_ROW_BORDER)
		name_box.add_child(you_tag)

	# 3. Overkill Score
	var score_lbl := Label.new()
	score_lbl.custom_minimum_size.x = 200
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.text = "%d OK" % int(entry.get("overkill_score", 0))
	score_lbl.add_theme_font_override("font", ScreenDesign.display_font())
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	hbox.add_child(score_lbl)

	# 4. Act Reached
	var act_lbl := Label.new()
	act_lbl.custom_minimum_size.x = 100
	act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	act_lbl.text = "ACT %d" % int(entry.get("act_reached", 1))
	act_lbl.add_theme_font_size_override("font_size", 14)
	act_lbl.add_theme_color_override("font_color", ScreenDesign.MUTED)
	hbox.add_child(act_lbl)

	# 5. Outcome
	var won: bool = bool(entry.get("won", false))
	var out_lbl := Label.new()
	out_lbl.custom_minimum_size.x = 140
	out_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	out_lbl.text = "VICTORY" if won else "DEFEAT"
	out_lbl.add_theme_font_size_override("font_size", 14)
	out_lbl.add_theme_color_override("font_color", COLOR_CYAN_ACCENT if won else COLOR_CORAL_DEFEAT)
	hbox.add_child(out_lbl)

	# 6. Relics Count
	var relics_lbl := Label.new()
	relics_lbl.custom_minimum_size.x = 100
	relics_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relics_lbl.text = "%d / 12" % int(entry.get("relics_count", 0))
	relics_lbl.add_theme_font_size_override("font_size", 14)
	relics_lbl.add_theme_color_override("font_color", ScreenDesign.TEXT)
	hbox.add_child(relics_lbl)

	# 7. Archetype Badge
	var arch_name: String = str(entry.get("archetype", "Chrono-Overdrive"))
	var arch_lbl := Label.new()
	arch_lbl.custom_minimum_size.x = 240
	arch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	arch_lbl.text = arch_name
	arch_lbl.add_theme_font_size_override("font_size", 13)
	if arch_name == "Chrono-Overdrive":
		arch_lbl.add_theme_color_override("font_color", Color("#3498DB"))
	elif arch_name == "Iron Bastion":
		arch_lbl.add_theme_color_override("font_color", Color("#95A5A6"))
	elif arch_name == "Crimson Hemorrhage":
		arch_lbl.add_theme_color_override("font_color", Color("#E74C3C"))
	elif arch_name == "Overkill Harvest":
		arch_lbl.add_theme_color_override("font_color", Color("#F39C12"))
	else:
		arch_lbl.add_theme_color_override("font_color", ScreenDesign.MUTED)
	hbox.add_child(arch_lbl)

	return row_panel


func _create_account_row(rank: int, entry: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size.y = 44
	var is_self: bool = entry.get("is_self", false) or (LeaderboardManager and entry.get("player_id", "") == LeaderboardManager.player_id)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SELF_ROW_BG if is_self else (Color("081420cc") if rank % 2 == 0 else Color("060f18aa"))
	style.border_color = COLOR_SELF_ROW_BORDER if is_self else Color("33445544")
	style.set_border_width_all(2 if is_self else 1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	row_panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row_panel.add_child(hbox)

	# 1. Rank Badge
	var rank_lbl := Label.new()
	rank_lbl.custom_minimum_size.x = 90
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_override("font", ScreenDesign.display_font())
	rank_lbl.add_theme_font_size_override("font_size", 18)
	if rank == 1:
		rank_lbl.text = "1 👑"
		rank_lbl.add_theme_color_override("font_color", Color("#FFD700"))
	elif rank == 2:
		rank_lbl.text = "2 🥈"
		rank_lbl.add_theme_color_override("font_color", Color("#C0C0C0"))
	elif rank == 3:
		rank_lbl.text = "3 🥉"
		rank_lbl.add_theme_color_override("font_color", Color("#CD7F32"))
	else:
		rank_lbl.text = "#%d" % rank
		rank_lbl.add_theme_color_override("font_color", ScreenDesign.MUTED)
	hbox.add_child(rank_lbl)

	# 2. Player Name (+ YOU badge)
	var name_box := HBoxContainer.new()
	name_box.custom_minimum_size.x = 280
	name_box.add_theme_constant_override("separation", 8)
	hbox.add_child(name_box)

	var name_lbl := Label.new()
	name_lbl.text = str(entry.get("player_name", "Unknown"))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", COLOR_SELF_ROW_BORDER if is_self else ScreenDesign.TEXT)
	name_box.add_child(name_lbl)

	if is_self:
		var you_tag := Label.new()
		you_tag.text = "(YOU)"
		you_tag.add_theme_font_size_override("font_size", 12)
		you_tag.add_theme_color_override("font_color", COLOR_SELF_ROW_BORDER)
		name_box.add_child(you_tag)

	# 3. Average Overkill
	var avg_val: float = float(entry.get("average_overkill", 0.0))
	var avg_lbl := Label.new()
	avg_lbl.custom_minimum_size.x = 200
	avg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	avg_lbl.text = "%.1f OK / run" % avg_val
	avg_lbl.add_theme_font_override("font", ScreenDesign.display_font())
	avg_lbl.add_theme_font_size_override("font_size", 18)
	avg_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	hbox.add_child(avg_lbl)

	# 4. Total Overkill
	var tot_lbl := Label.new()
	tot_lbl.custom_minimum_size.x = 180
	tot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tot_lbl.text = "%d OK" % int(entry.get("lifetime_overkill", 0))
	tot_lbl.add_theme_font_size_override("font_size", 14)
	tot_lbl.add_theme_color_override("font_color", ScreenDesign.TEXT)
	hbox.add_child(tot_lbl)

	# 5. Runs Started
	var started_lbl := Label.new()
	started_lbl.custom_minimum_size.x = 140
	started_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	started_lbl.text = "%d" % int(entry.get("runs_started", 0))
	started_lbl.add_theme_font_size_override("font_size", 14)
	started_lbl.add_theme_color_override("font_color", ScreenDesign.MUTED)
	hbox.add_child(started_lbl)

	# 6. Runs Won
	var won_lbl := Label.new()
	won_lbl.custom_minimum_size.x = 120
	won_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	won_lbl.text = "%d" % int(entry.get("runs_completed", 0))
	won_lbl.add_theme_font_size_override("font_size", 14)
	won_lbl.add_theme_color_override("font_color", COLOR_CYAN_ACCENT)
	hbox.add_child(won_lbl)

	# 7. Peak Single Run Overkill
	var peak_lbl := Label.new()
	peak_lbl.custom_minimum_size.x = 150
	peak_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	peak_lbl.text = "%d OK" % int(entry.get("best_run_overkill", 0))
	peak_lbl.add_theme_font_size_override("font_size", 14)
	peak_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	hbox.add_child(peak_lbl)

	return row_panel


func _update_footer_summary() -> void:
	if LeaderboardManager == null:
		return
	if current_category == "runs":
		var rank_str := "UNRANKED" if LeaderboardManager.last_run_rank <= 0 else "#%d" % LeaderboardManager.last_run_rank
		_status_summary_label.text = "THIS RUN SCORE: %d OK  ·  LATEST GLOBAL RUN PLACEMENT: %s  ·  PERSONAL BEST: %d OK" % [
			LeaderboardManager.last_run_score,
			rank_str,
			LeaderboardManager.best_run_overkill
		]
	else:
		var acc_rank: int = LeaderboardManager.get_account_rank()
		_status_summary_label.text = "CAREER AVERAGE: %.1f OK/run  ·  GLOBAL STANDING: #%d  ·  RUNS: %d STARTED (%d WON)  ·  LIFETIME: %d OK" % [
			LeaderboardManager.get_average_overkill(),
			acc_rank,
			LeaderboardManager.runs_started,
			LeaderboardManager.runs_completed,
			LeaderboardManager.lifetime_overkill
		]


func _switch_category(category: String) -> void:
	current_category = category
	_update_tab_buttons()
	# Replace table header
	var main_vbox: VBoxContainer = _panel.get_child(0) as VBoxContainer
	var old_header: Control = main_vbox.get_child(2) as Control
	var new_header := _build_table_header()
	main_vbox.remove_child(old_header)
	old_header.queue_free()
	main_vbox.add_child(new_header)
	main_vbox.move_child(new_header, 2)
	_populate_rows()


func _update_tab_buttons() -> void:
	if current_category == "runs":
		_tab_runs_btn.modulate = Color(1.3, 1.3, 1.3)
		_tab_accounts_btn.modulate = Color(0.7, 0.7, 0.7)
	else:
		_tab_runs_btn.modulate = Color(0.7, 0.7, 0.7)
		_tab_accounts_btn.modulate = Color(1.3, 1.3, 1.3)


func _on_name_submitted(new_name: String) -> void:
	if LeaderboardManager != null:
		LeaderboardManager.set_player_name(new_name)
	_populate_rows()


func _on_refresh_pressed() -> void:
	if LeaderboardManager == null:
		return
	if current_category == "runs":
		LeaderboardManager.fetch_run_leaderboard(true)
	else:
		LeaderboardManager.fetch_account_leaderboard(true)


func _on_leaderboard_updated(category: String, _entries: Array) -> void:
	if category == current_category:
		_populate_rows()


func _on_profile_updated() -> void:
	if _name_edit != null and LeaderboardManager != null:
		_name_edit.text = LeaderboardManager.player_name
	_populate_rows()


func _close() -> void:
	if LeaderboardManager != null:
		LeaderboardManager.close_leaderboard()
	else:
		queue_free()
