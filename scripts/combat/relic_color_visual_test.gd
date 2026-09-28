extends Node

const PEDESTAL := preload("res://scenes/relic_pedestal_view.tscn")
const OUTPUT_DIR := "res://.test-artifacts/relic-color-language"

var _title: Label
var _subtitle: Label
var _row: HBoxContainer
var _canvas: Control


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	AudioManager.reduced_motion = false
	RunManager.start_new_run([], [], 80, 527)
	_build_stage()
	await _show_page("THE FIVE ESSENCES", "One visual law for every combat promise.", ["REL-01", "REL-04", "REL-16", "REL-17", "REL-18"], "five-essences")
	await _show_page("DUAL-BOUND RELICS", "Two colors. Two effects. No false promises.", ["REL-19", "REL-20", "REL-21", "REL-24", "REL-26"], "dual-bindings")
	await _capture_reliquary()
	print("RELIC_COLOR_VISUAL_OK: cinematic five-essence, dual-binding and production Reliquary views captured")
	get_tree().quit()


func _build_stage() -> void:
	_canvas = Control.new()
	_canvas.theme = ScreenDesign.build_theme()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)
	var background := TextureRect.new()
	background.texture = load(CinematicArt.COLLECTION)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.62, 0.67, 0.72)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(background)
	ScreenDesign.shade(_canvas)
	var top_veil := ColorRect.new()
	top_veil.color = Color("061019d9")
	top_veil.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_veil.offset_bottom = 214
	top_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(top_veil)
	ScreenDesign.frame(_canvas, "RELIQUARY  /  CHROMATIC CODEX")
	var column := VBoxContainer.new()
	column.position = Vector2(70, 96)
	column.size = Vector2(1780, 918)
	column.add_theme_constant_override("separation", 8)
	_canvas.add_child(column)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", ScreenDesign.display_font())
	_title.add_theme_font_size_override("font_size", 48)
	_title.add_theme_color_override("font_color", Color("e8c994"))
	column.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 19)
	_subtitle.add_theme_color_override("font_color", Color("b9c8cf"))
	column.add_child(_subtitle)
	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 18)
	column.add_child(legend)
	for essence: int in ClockRelicData.Essence.values():
		var marker := Label.new()
		marker.text = "◆  " + ClockRelicData.essence_to_short_name(essence).to_upper()
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_color", ClockRelicData.essence_to_color(essence))
		legend.add_child(marker)
	_row = HBoxContainer.new()
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_row.add_theme_constant_override("separation", 22)
	column.add_child(_row)


func _show_page(title: String, subtitle: String, ids: Array[String], file_name: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	await get_tree().process_frame
	for id: String in ids:
		var view: RelicPedestalView = PEDESTAL.instantiate()
		_row.add_child(view)
		view.use_gallery_layout()
		view.bind_relic(ContentDatabase.get_clock_relic(id), "")
	await get_tree().create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var output_path := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, file_name])
	assert(get_viewport().get_texture().get_image().save_png(output_path) == OK)


func _capture_reliquary() -> void:
	_canvas.hide()
	var collection := preload("res://scripts/ui/clock_collection_screen.gd").new()
	collection.mode = "collection"
	add_child(collection)
	await get_tree().create_timer(0.8).timeout
	assert(collection._grid.get_child_count() == 4, "Collection should group the 12-copy starter inventory into four readable designs")
	for card: RelicPedestalView in collection._grid.get_children():
		assert(card.size.y <= 370.0 and card._art_rect.size.y >= 170.0, "Reliquary cards must stay compact while preserving artifact presence")
	await RenderingServer.frame_post_draw
	var output_path := ProjectSettings.globalize_path("%s/reliquary-production.png" % OUTPUT_DIR)
	assert(get_viewport().get_texture().get_image().save_png(output_path) == OK)
	collection.queue_free()
	_canvas.show()
