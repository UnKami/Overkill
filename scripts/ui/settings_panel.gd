extends Control
## Settings submenu (pause/settings doc Part 3) - opened identically from the
## title screen and the pause menu, per the doc's explicit "reuses the exact
## pause-menu settings submenu" rule. Persists via AudioManager, which owns
## these values and writes them through SaveManager.save_meta().

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _fast_mode_check: CheckBox = %FastModeCheck
@onready var _text_size_option: OptionButton = %TextSizeOption
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	ScreenDesign.polish(self)
	var panel: PanelContainer = get_node("CenterContainer/Panel")
	panel.custom_minimum_size.x = 720
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("091520f2")
	panel_style.border_color = Color("80c8d17a")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000cc")
	panel_style.shadow_size = 28
	panel_style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", panel_style)
	var stack: VBoxContainer = _close_button.get_parent()
	var title: Label = stack.get_node("TitleLabel")
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 36)
	var kicker := ScreenDesign.label(stack, "CHRONOMETER CALIBRATION", 14, ScreenDesign.CYAN)
	stack.move_child(kicker, 0)
	var top_rule := ScreenDesign.rule(stack, ScreenDesign.GOLD)
	stack.move_child(top_rule, title.get_index() + 1)
	var audio_section := ScreenDesign.label(stack, "AUDIO", 14, ScreenDesign.GOLD)
	stack.move_child(audio_section, stack.get_node("MasterLabel").get_index())
	_close_button.grab_focus()
	var motion := CheckBox.new()
	motion.text = "Reduce ambient camera movement"
	motion.button_pressed = AudioManager.reduced_motion
	_fast_mode_check.get_parent().add_child(motion)
	_fast_mode_check.get_parent().move_child(motion, _fast_mode_check.get_index() + 1)
	_fast_mode_check.text = "Accelerated combat choreography"
	var access_section := ScreenDesign.label(stack, "ACCESSIBILITY", 14, ScreenDesign.GOLD)
	stack.move_child(access_section, _fast_mode_check.get_index())
	stack.get_node("TextSizeLabel").text = "Interface text size"
	motion.toggled.connect(func(enabled: bool) -> void:
		AudioManager.reduced_motion = enabled
		AudioManager.save_settings())
	var quality_box: VBoxContainer = VBoxContainer.new()
	quality_box.name = "GraphicsQuality"
	var quality_label: Label = Label.new()
	quality_label.text = "Scene effects quality"
	quality_label.add_theme_color_override("font_color", ScreenDesign.TEXT)
	quality_box.add_child(quality_label)
	var quality: OptionButton = OptionButton.new()
	quality.name = "QualityOption"
	for choice: String in ["High","Balanced","Performance"]: quality.add_item(choice)
	var modes: Array[String] = ["high","balanced","performance"]
	quality.selected = maxi(0,modes.find(AudioManager.render_quality))
	quality.custom_minimum_size.y = 44
	quality_box.add_child(quality)
	var explanation: Label = Label.new()
	explanation.text = "Lower settings reduce animated scenery and showcase rendering load.\nText, relics and clocks remain sharp. Changes apply immediately."
	explanation.add_theme_font_size_override("font_size",18)
	explanation.add_theme_color_override("font_color", ScreenDesign.MUTED)
	quality_box.add_child(explanation)
	var settings_box: Node = _close_button.get_parent()
	settings_box.add_child(quality_box)
	settings_box.move_child(quality_box,_close_button.get_index())
	var visual_section := ScreenDesign.label(stack, "PRESENTATION", 14, ScreenDesign.GOLD)
	stack.move_child(visual_section, quality_box.get_index())
	quality.item_selected.connect(func(index: int) -> void: AudioManager.set_render_quality(modes[index]))
	_master_slider.value = AudioManager.master_volume
	_music_slider.value = AudioManager.music_volume
	_sfx_slider.value = AudioManager.sfx_volume
	_fast_mode_check.button_pressed = AudioManager.fast_mode
	_text_size_option.clear()
	_text_size_option.add_item("Normal")
	_text_size_option.add_item("Large")
	_text_size_option.selected = 1 if AudioManager.text_size == "large" else 0

	_master_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_master_volume(v))
	_music_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_music_volume(v))
	_sfx_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_sfx_volume(v))
	_fast_mode_check.toggled.connect(func(pressed: bool) -> void: AudioManager.set_fast_mode(pressed))
	_text_size_option.item_selected.connect(func(idx: int) -> void: AudioManager.set_text_size("large" if idx == 1 else "normal"))
	_close_button.pressed.connect(func() -> void: GameFlow.close_settings())
	_close_button.text = "RETURN"
	_close_button.custom_minimum_size.y = 58
	ScreenDesign.apply_text_size(self)
