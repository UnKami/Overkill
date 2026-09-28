extends Node

const PEDESTAL := preload("res://scenes/relic_pedestal_view.tscn")
const OUTPUT_DIR := "res://.test-artifacts/relic-color-language"

var _title: Label
var _row: HBoxContainer


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	_build_stage()
	await _show_page("THE FIVE ESSENCES", ["REL-01", "REL-04", "REL-16", "REL-17", "REL-18"], "five-essences")
	await _show_page("DUAL-BOUND RELICS", ["REL-19", "REL-20", "REL-21", "REL-24", "REL-26"], "dual-bindings")
	print("RELIC_COLOR_VISUAL_OK: five-essence and dual-binding card sheets captured")
	get_tree().quit()


func _build_stage() -> void:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("071019")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)
	var column := VBoxContainer.new()
	column.position = Vector2(90, 54)
	column.size = Vector2(1740, 972)
	column.add_theme_constant_override("separation", 30)
	canvas.add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", ScreenDesign.display_font())
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color("e8c994"))
	column.add_child(_title)
	_row = HBoxContainer.new()
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 24)
	column.add_child(_row)


func _show_page(title: String, ids: Array[String], file_name: String) -> void:
	_title.text = title
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	await get_tree().process_frame
	for id: String in ids:
		var view: RelicPedestalView = PEDESTAL.instantiate()
		view.custom_minimum_size = Vector2(320, 650)
		_row.add_child(view)
		view.bind_relic(ContentDatabase.get_clock_relic(id), "")
		view._slot_button.hide()
	await get_tree().create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var output_path := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, file_name])
	assert(get_viewport().get_texture().get_image().save_png(output_path) == OK)
