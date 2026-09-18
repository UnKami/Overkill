class_name ChronometerView extends Control
## ChronometerView - Renders the 9-hour circular battle mechanism.
## Manages circular layout, quadrant lighting, socket dispatch, and sweeping hands.

signal socket_pressed(hour_index: int, socket_view: ClockSocketView)

const RADIUS := 177.5

@export var socket_scene: PackedScene

@onready var _outer_rim: Panel = %OuterRim
@onready var _dial_texture: TextureRect = %DialTexture
@onready var _socket_container: Control = %SocketContainer
@onready var _center_hand_pivot: Control = %CenterHandPivot
@onready var _hand_line: Line2D = %HandLine
@onready var _center_hub: Panel = %CenterHub
@onready var _title_label: Label = %TitleLabel

var _socket_views: Dictionary = {} # hour_index (1..9) -> ClockSocketView
var _is_enemy: bool = false
var _hand_tween: Tween = null
var _engraving: Control
var rotation_direction: int = 1


func _ready() -> void:
	_engraving = preload("res://scripts/ui/clock_engraving.gd").new()
	add_child(_engraving)
	move_child(_engraving, _socket_container.get_index())
	_engraving.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mask := ShaderMaterial.new()
	mask.shader = preload("res://assets/ui/combat/circular_art.gdshader")
	_dial_texture.material = mask
	_style_chassis()


func initialize(is_enemy: bool = false, title: String = "") -> void:
	_is_enemy = is_enemy
	_center_hand_pivot.rotation = -PI * 0.5
	_title_label.text = title if not title.is_empty() else ("ENEMY CHRONOMETER" if is_enemy else "PLAYER CHRONOMETER")
	_style_chassis()
	_create_clock_sockets()


func _style_chassis() -> void:
	if _outer_rim == null:
		return

	# Outer rim: heavy dark gunmetal with faction accent border
	var rim_style := StyleBoxFlat.new()
	rim_style.set_corner_radius_all(300)
	rim_style.bg_color = Color(0.025, 0.03, 0.04, 0.94)
	rim_style.border_color = Color("8e6650") if _is_enemy else Color("6f8c90")
	rim_style.set_border_width_all(2)
	rim_style.shadow_color = Color(0, 0, 0, 0.8)
	rim_style.shadow_size = 28
	_outer_rim.add_theme_stylebox_override("panel", rim_style)

	# Center hub: brass / gunmetal core
	var hub_style := StyleBoxFlat.new()
	hub_style.set_corner_radius_all(20)
	hub_style.bg_color = Color("#181a1f")
	hub_style.border_color = Color("#E74C3C") if _is_enemy else Color("#F39C12")
	hub_style.set_border_width_all(3)
	_center_hub.add_theme_stylebox_override("panel", hub_style)

	# Hand color
	_hand_line.default_color = Color("#E74C3C") if _is_enemy else Color("#F39C12")
	_hand_line.width = 6.0
	_hand_line.points = PackedVector2Array([Vector2(-22, 0), Vector2(145, 0)])
	_hand_line.width = 2.0
	if not _center_hand_pivot.has_node("ForgedHand"):
		var hand := Polygon2D.new()
		hand.name = "ForgedHand"
		hand.polygon = PackedVector2Array([Vector2(-30, 0), Vector2(-12, -7), Vector2(100, -3), Vector2(156, 0), Vector2(100, 3), Vector2(-12, 7)])
		_center_hand_pivot.add_child(hand)
	_center_hand_pivot.get_node("ForgedHand").color = Color("ecad7d") if _is_enemy else Color("e8ce91")
	if _engraving:
		_engraving.accent = Color("e99778") if _is_enemy else Color("7bd6de")
	if _dial_texture.material:
		_dial_texture.material.set_shader_parameter("tint", Color(0.95, 0.65, 0.48) if _is_enemy else Color(0.7, 0.9, 0.95))


func _create_clock_sockets() -> void:
	for child in _socket_container.get_children():
		child.queue_free()
	_socket_views.clear()

	var center := size * 0.5
	for hour in range(1, 10):
		# Nine equally spaced sockets; hour 9 is at the top.
		var deg := (hour * 40.0) - 90.0
		var rad := deg_to_rad(deg)
		var pos := center + Vector2(cos(rad), sin(rad)) * size.x * 0.355

		var socket_view: ClockSocketView = socket_scene.instantiate()
		_socket_container.add_child(socket_view)
		socket_view.set_anchors_preset(Control.PRESET_TOP_LEFT)
		socket_view.position = pos - socket_view.custom_minimum_size * 0.5
		socket_view.pressed.connect(_on_socket_pressed)
		_socket_views[hour] = socket_view


func bind_sockets(sockets_data: Array) -> void:
	for s_data in sockets_data:
		var socket: ClockSocketData = s_data as ClockSocketData
		if socket != null and _socket_views.has(socket.hour_index):
			_socket_views[socket.hour_index].bind_socket(socket, _is_enemy)


func get_socket_view(hour: int) -> ClockSocketView:
	return _socket_views.get(hour, null)


## Smoothly rotates the pointer hand to aim directly at an hour.
func snap_hand_to_hour(hour: int, duration: float = 0.32) -> Signal:
	var target_deg := (hour * 40.0) - 90.0
	var target_rad := deg_to_rad(target_deg)
	if rotation_direction > 0:
		while target_rad < _center_hand_pivot.rotation - 0.001: target_rad += TAU
	else:
		while target_rad > _center_hand_pivot.rotation + 0.001: target_rad -= TAU
	_engraving.active_hour = hour

	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()

	_hand_tween = create_tween()
	_hand_tween.tween_property(_center_hand_pivot, "rotation", target_rad, duration / AudioManager.animation_speed_scale()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return _hand_tween.finished


func set_twin_hand(enabled: bool) -> void:
	if not _center_hand_pivot.has_node("TwinHand"):
		var echo := Polygon2D.new()
		echo.name = "TwinHand"
		echo.polygon = PackedVector2Array([Vector2(-146, 0), Vector2(-95, -4), Vector2(0, -2), Vector2(0, 2), Vector2(-95, 4)])
		echo.rotation = deg_to_rad(-20.0)
		echo.color = Color("c98ad8")
		_center_hand_pivot.add_child(echo)
	_center_hand_pivot.get_node("TwinHand").visible = enabled


## Highlights the 3 sockets in quadrant q (1: 1-3, 2: 4-6, 3: 7-9)
func highlight_quadrant(quadrant_index: int, highlight_color: Color = Color("#EF9F27")) -> void:
	clear_quadrant_highlights()
	_engraving.quadrant = quadrant_index
	var hours := get_quadrant_hours(quadrant_index)
	for h in hours:
		if _socket_views.has(h):
			_socket_views[h].set_quadrant_highlight(true, highlight_color)


func clear_quadrant_highlights() -> void:
	_engraving.quadrant = 0
	for h in _socket_views:
		_socket_views[h].set_quadrant_highlight(false)


func mark_hour(hour: int) -> void:
	_engraving.active_hour = hour


func set_interactive_quadrant(quadrant_index: int, interactive: bool) -> void:
	for h in _socket_views:
		_socket_views[h].is_interactive = false

	if interactive:
		var hours := get_quadrant_hours(quadrant_index)
		for h in hours:
			if _socket_views.has(h):
				var s_view: ClockSocketView = _socket_views[h]
				if s_view.data != null and not s_view.data.is_locked:
					s_view.is_interactive = true


static func get_quadrant_hours(q: int) -> Array[int]:
	match q:
		1: return [1, 2, 3]
		2: return [4, 5, 6]
		3: return [7, 8, 9]
		_: return [1, 2, 3]


func _on_socket_pressed(socket_view: ClockSocketView) -> void:
	if socket_view.data != null:
		socket_pressed.emit(socket_view.data.hour_index, socket_view)
