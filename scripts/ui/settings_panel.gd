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
	get_node("CenterContainer/Panel").custom_minimum_size.x = 640
	_close_button.grab_focus()
	var motion := CheckBox.new()
	motion.text = "Reduce camera motion"
	motion.button_pressed = AudioManager.reduced_motion
	_fast_mode_check.get_parent().add_child(motion)
	_fast_mode_check.get_parent().move_child(motion, _fast_mode_check.get_index() + 1)
	motion.toggled.connect(func(enabled: bool) -> void:
		AudioManager.reduced_motion = enabled
		AudioManager.save_settings())
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
