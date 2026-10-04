class_name CogGearView
extends Node2D
## Regular involute teeth provide a repeatable contact profile. The canonical
## wheel painting remains inside the root circle as the machine's faceplate.

const TEETH: int = 24
const PITCH_RADIUS: float = 130.0
const TIP_RADIUS: float = 141.0
const ROOT_RADIUS: float = 117.0
const PRESSURE_ANGLE: float = PI / 9.0
const TOOTH_STEP: float = TAU / TEETH
static var _face_texture: Texture2D
static var _outline_cache: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	if _face_texture == null:
		_face_texture = load("res://assets/map/cog_navigation/wheel.png") as Texture2D
	var face := Polygon2D.new()
	face.name = "CanonicalFaceplate"
	face.texture = _face_texture
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	var texture_size := Vector2(_face_texture.get_width(), _face_texture.get_height())
	for index: int in 96:
		var point: Vector2 = Vector2.from_angle(TAU * index / 96.0) * (ROOT_RADIUS - 2.0)
		polygon.append(point)
		uv.append((point / 286.0 + Vector2.ONE * 0.5) * texture_size)
	face.polygon = polygon
	face.uv = uv
	add_child(face)
	queue_redraw()


func _draw() -> void:
	var outline: PackedVector2Array = tooth_outline()
	draw_colored_polygon(outline, Color("27363d"))
	# Individual forged bevels retain the painted face's steel/gold palette.
	for tooth: int in TEETH:
		var sector := PackedVector2Array()
		sector.append(Vector2.ZERO)
		for index: int in range(tooth * 18, tooth * 18 + 18):
			sector.append(outline[index])
		var angle: float = tooth * TOOTH_STEP
		var light: float = 0.5 + 0.5 * cos(angle + PI * 0.65)
		draw_colored_polygon(sector, Color("27383f").lerp(Color("71858b"), light * 0.65))
	var closed: PackedVector2Array = outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color("c5ba8c"), 1.4, true)
	draw_arc(Vector2.ZERO, ROOT_RADIUS - 2.0, 0.0, TAU, 96, Color("bea66e"), 3.0, true)
	draw_arc(Vector2.ZERO, ROOT_RADIUS - 7.0, 0.0, TAU, 96, Color("203138"), 2.0, true)


static func tooth_outline() -> PackedVector2Array:
	if not _outline_cache.is_empty():
		return _outline_cache
	var base_radius: float = PITCH_RADIUS * cos(PRESSURE_ANGLE)
	var pitch_involute: float = tan(PRESSURE_ANGLE) - PRESSURE_ANGLE
	var half_width: float = PI / (2.0 * TEETH)
	var base_width: float = half_width + pitch_involute
	for tooth: int in TEETH:
		var center: float = tooth * TOOTH_STEP
		_outline_cache.append(Vector2.from_angle(center - TOOTH_STEP * 0.5) * ROOT_RADIUS)
		_outline_cache.append(Vector2.from_angle(center - base_width) * ROOT_RADIUS)
		for sample: int in 7:
			var radius: float = lerpf(base_radius, TIP_RADIUS, sample / 6.0)
			var alpha: float = acos(base_radius / radius)
			var width: float = half_width + pitch_involute - (tan(alpha) - alpha)
			_outline_cache.append(Vector2.from_angle(center - width) * radius)
		for sample: int in range(6, -1, -1):
			var radius: float = lerpf(base_radius, TIP_RADIUS, sample / 6.0)
			var alpha: float = acos(base_radius / radius)
			var width: float = half_width + pitch_involute - (tan(alpha) - alpha)
			_outline_cache.append(Vector2.from_angle(center + width) * radius)
		_outline_cache.append(Vector2.from_angle(center + base_width) * ROOT_RADIUS)
		_outline_cache.append(Vector2.from_angle(center + TOOTH_STEP * 0.5) * ROOT_RADIUS)
	return _outline_cache
