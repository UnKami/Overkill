class_name BattleReferenceOverlay extends Control
## In-battle reading layer used by both the combat chronicle and field
## manual. It deliberately stays inside the game's glass-and-metal visual
## language instead of opening an operating-system-looking AcceptDialog.

const SCENE_PATH := "res://scenes/battle_reference_overlay.tscn"

@onready var _panel: PanelContainer = %Panel
@onready var _kicker_label: Label = %KickerLabel
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: RichTextLabel = %BodyLabel
@onready var _close_button: Button = %CloseButton
@onready var _background_button: Button = %BackgroundButton

var _title_text: String = ""
var _kicker_text: String = ""
var _body_text: String = ""
var _accent: Color = Color("80c8d1")


static func show_overlay(parent: Node, title_text: String, kicker_text: String, body_text: String, accent: Color = Color("80c8d1")) -> BattleReferenceOverlay:
	var scene: PackedScene = load(SCENE_PATH)
	var instance: BattleReferenceOverlay = scene.instantiate()
	instance.configure(title_text, kicker_text, body_text, accent)
	parent.add_child(instance)
	return instance


func configure(title_text: String, kicker_text: String, body_text: String, accent: Color = Color("80c8d1")) -> void:
	_title_text = title_text
	_kicker_text = kicker_text
	_body_text = body_text
	_accent = accent
	if is_node_ready():
		_apply_content()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100
	theme = ScreenDesign.build_theme()
	ScreenDesign.polish(self)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("08141ff8")
	style.border_color = Color(_accent, 0.76)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = Color("000000e5")
	style.shadow_size = 36
	style.shadow_offset = Vector2(0, 14)
	_panel.add_theme_stylebox_override("panel", style)
	_title_label.add_theme_font_override("font", ScreenDesign.display_font())
	_title_label.add_theme_font_size_override("font_size", 38)
	_title_label.add_theme_color_override("font_color", ScreenDesign.GOLD)
	_kicker_label.add_theme_color_override("font_color", _accent)
	_kicker_label.add_theme_font_size_override("font_size", 14)
	_body_label.add_theme_font_size_override("normal_font_size", 19)
	_body_label.add_theme_font_size_override("bold_font_size", 21)
	_body_label.add_theme_color_override("default_color", ScreenDesign.TEXT)
	_body_label.add_theme_constant_override("line_separation", 8)
	_close_button.custom_minimum_size.y = 56
	_close_button.text = "RETURN TO BATTLE"
	_close_button.pressed.connect(queue_free)
	_background_button.pressed.connect(queue_free)
	_apply_content()
	_close_button.grab_focus()
	ScreenDesign.reveal(_panel)


func _apply_content() -> void:
	_kicker_label.text = _kicker_text
	_title_label.text = _title_text
	_body_label.text = _body_text
