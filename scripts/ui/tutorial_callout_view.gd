class_name TutorialCalloutView extends Control
## The one display layer for TutorialCallout. Renders whatever the autoload
## requests, then fully disappears - never leaves a permanent element behind.
## overkill-tutorial-callout-system.md, Part 1 guardrails 2-4.
##
## KNOWN SIMPLIFICATION: the spec calls for a different anchor per callout
## (e.g. below the OK counter for first_ok, above the intent badge for
## first_intent). This pass uses one fixed on-screen position for all
## callouts to keep the vertical slice small - per-callout anchoring is a
## polish pass, not a functional gap; the one-time/no-permanent-element
## contract below is implemented in full.

@onready var _panel: PanelContainer = %Panel
@onready var _label: Label = %MessageLabel
@onready var _icon: TextureRect = %Icon

var _dismiss_timer: SceneTreeTimer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	TutorialCallout.callout_requested.connect(_on_requested)


func _on_requested(_callout_id: String, definition: Dictionary) -> void:
	_label.text = definition.get("text", "")

	var icon_path: String = "res://assets/icons/ui/%s.png" % definition.get("icon_id", "")
	_icon.texture = ResourceLoader.load(icon_path) if ResourceLoader.exists(icon_path) else null

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1c1c1e")
	style.border_color = Color(definition.get("accent_color", "#ffffff"))
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", style)

	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	var dismiss_seconds: float = definition.get("dismiss_seconds", -1.0)
	if dismiss_seconds > 0.0:
		_dismiss_timer = get_tree().create_timer(dismiss_seconds)
		_dismiss_timer.timeout.connect(_dismiss)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed:
		_dismiss()


func dismiss_now() -> void:
	_dismiss()


func _dismiss() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: visible = false)
