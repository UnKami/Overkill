class_name ScreenDesign extends RefCounted
## Shared presentation tokens and controls for the complete run flow.
const GOLD := Color("c9aa76")
const INK := Color("0a1119")
const TEXT := Color("e5e4df")
const MUTED := Color("99a9b5")
const CYAN := Color("80c8d1")
static var _theme: Theme
static var _display_font: SystemFont

static func display_font() -> Font:
	if _display_font == null:
		_display_font = SystemFont.new()
		_display_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	return _display_font

static func box(fill: Color, line: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(width)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func build_theme() -> Theme:
	if _theme != null: return _theme
	_theme = load("res://assets/ui/theme/overkill_theme.tres").duplicate(true)
	_theme.default_font_size = 22
	_theme.set_color("font_color", "Label", TEXT)
	for type in ["Button", "SecondaryButton", "DangerButton", "OptionButton"]:
		var accent := Color("b66d64") if type == "DangerButton" else GOLD
		_theme.set_stylebox("normal",type,box(Color("101b26e8"),Color("655a4380")))
		_theme.set_stylebox("hover",type,box(Color("213440f5"),accent))
		_theme.set_stylebox("pressed",type,box(Color("30404d"),CYAN))
		_theme.set_stylebox("disabled",type,box(Color("0c141aa0"),Color("35414a")))
		_theme.set_stylebox("focus",type,box(Color(0,0,0,0),CYAN,2))
		_theme.set_color("font_color",type,TEXT)
		_theme.set_color("font_hover_color",type,Color("fff1d3"))
		_theme.set_color("font_disabled_color",type,Color("75818a"))
		_theme.set_font_size("font_size",type,22)
	for type in ["Panel", "PanelContainer", "PopupPanel", "PopupMenu"]:
		_theme.set_stylebox("panel",type,box(Color("0e1925f5"),Color("716449")))
	_theme.set_stylebox("panel","TooltipPanel",box(Color("111e2aff"),GOLD))
	_theme.set_font_size("font_size","TooltipLabel",20)
	_theme.set_stylebox("slider","HSlider",box(Color("263640"),Color("263640"),0))
	_theme.set_stylebox("grabber_area","HSlider",box(CYAN,CYAN,0))
	for state in ["grabber","grabber_highlight","grabber_disabled"]:
		_theme.set_icon(state,"HSlider",load("res://assets/ui/controls/clock_slider.svg"))
	_theme.set_icon("checked","CheckBox",load("res://assets/ui/controls/clock_check_on.svg"))
	_theme.set_icon("unchecked","CheckBox",load("res://assets/ui/controls/clock_check_off.svg"))
	_theme.set_icon("checked_disabled","CheckBox",load("res://assets/ui/controls/clock_check_on.svg"))
	_theme.set_icon("unchecked_disabled","CheckBox",load("res://assets/ui/controls/clock_check_off.svg"))
	for state in ["slider","grabber_area"]:
		var track := _theme.get_stylebox(state,"HSlider") as StyleBoxFlat
		track.content_margin_top = 3
		track.content_margin_bottom = 3
	return _theme

static func label(parent: Node, text: String, font_size: int = 22, color: Color = TEXT, display: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",color)
	if display: result.add_theme_font_override("font",display_font())
	parent.add_child(result)
	return result

static func button(parent: Node, text: String, action: Callable, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 62
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if primary:
		result.add_theme_stylebox_override("normal",box(Color("493e2bd9"),GOLD))
	parent.add_child(result)
	result.pressed.connect(action)
	result.mouse_entered.connect(func() -> void: AudioManager.play_clock_sound("tick"))
	result.focus_entered.connect(func() -> void: AudioManager.play_clock_sound("tick"))
	return result

static func rule(parent: Node, color: Color = GOLD) -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(color,0.45)
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line

static func spacer(parent: Node, height: float) -> void:
	var item := Control.new()
	item.custom_minimum_size.y = height
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)

static func shade(parent: Control) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.30,0.58,1])
	gradient.colors = PackedColorArray([Color("071019f5"),Color("071019dc"),Color("07101945"),Color("07101910")])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 1024
	texture.height = 16
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	var veil := TextureRect.new()
	veil.texture = texture
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func column(parent: Control, top: float = 0.19, right: float = 0.38) -> VBoxContainer:
	var result := VBoxContainer.new()
	parent.add_child(result)
	result.anchor_left = 0.075
	result.anchor_right = right
	result.anchor_top = top
	result.add_theme_constant_override("separation",14)
	return result

static func frame(parent: Control, breadcrumb: String) -> void:
	var top := label(parent,"O V E R K I L L     /     " + breadcrumb,18,GOLD)
	top.position = Vector2(64,38)
	var footer := label(parent,"BIND THE HOURS. BREAK THE CYCLE.",15,MUTED)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position += Vector2(64,-96)

static func reveal(control: Control) -> void:
	control.modulate.a = 0
	control.create_tween().tween_property(control,"modulate:a",1.0,0.18 if AudioManager.reduced_motion else 0.55)

static func polish(root: Control) -> void:
	root.theme = build_theme()
	for node in root.find_children("*","Label",true,false):
		if "Title" in node.name or "Header" in node.name:
			node.add_theme_font_override("font",display_font())
			node.add_theme_color_override("font_color",GOLD)
	for node in root.find_children("*","Button",true,false):
		if not root is CombatController: node.custom_minimum_size.y = maxf(node.custom_minimum_size.y,48)
		if not node.mouse_entered.is_connected(_hover): node.mouse_entered.connect(_hover)
	apply_text_size(root)

static func apply_text_size(root: Node) -> void:
	var multiplier := 1.15 if AudioManager.text_size == "large" else 1.0
	var shared := build_theme()
	shared.default_font_size = roundi(22*multiplier)
	for type in ["Button","SecondaryButton","DangerButton","OptionButton"]:
		shared.set_font_size("font_size",type,roundi(22*multiplier))
	_scale_labels(root,multiplier)

static func _scale_labels(root: Node, multiplier: float) -> void:
	if root is RichTextLabel and root.has_theme_font_size_override("normal_font_size"):
		if not root.has_meta("base_body_size"):
			root.set_meta("base_body_size", root.get_theme_font_size("normal_font_size"))
		root.add_theme_font_size_override("normal_font_size", roundi(int(root.get_meta("base_body_size")) * multiplier))
	if root is Control and root.has_theme_font_size_override("font_size"):
		if not root.has_meta("base_text_size"):
			root.set_meta("base_text_size",root.get_theme_font_size("font_size"))
		var base: int = root.get_meta("base_text_size")
		if base <= 32: root.add_theme_font_size_override("font_size",roundi(base*multiplier))
	for child in root.get_children(): _scale_labels(child,multiplier)

static func _hover() -> void:
	AudioManager.play_clock_sound("tick")
