extends Control
## Canonical 2D front-end stage. Navigation screens share the same cinematic
## cyan/amber shard language as combat instead of instancing a separate 3D
## knight arena.

var character_view: bool = false
var _background: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background = TextureRect.new()
	_background.texture = load("res://assets/screens/class_select_bg.jpg" if character_view else "res://assets/screens/loading_screen_bg_2.jpg")
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tint := ColorRect.new()
	tint.color = Color("03081138")
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not AudioManager.reduced_motion:
		_background.scale = Vector2(1.025, 1.025)
		_background.position = -size * 0.0125
