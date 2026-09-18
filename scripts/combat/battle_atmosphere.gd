extends Control
## Procedural atmosphere: bounded particles, vignette and perspective floor light.
var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	for i in range(18):
		var inset := float(i) * 9.0
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(0.008, 0.012, 0.02, 0.024), false, 18.0)
	for i in range(38):
		var seed_value := float(i)
		var x := fmod(seed_value * 137.7 + sin(elapsed * 0.22 + seed_value) * 25.0, size.x)
		var y := size.y - fmod(seed_value * 81.3 + elapsed * (7.0 + fmod(seed_value, 5.0)), size.y)
		var col := Color("77cbd6") if i % 3 == 0 else Color("dcb375")
		col.a = (0.2 + sin(elapsed + seed_value) * 0.12)
		draw_circle(Vector2(x, y), 1.0 + fmod(seed_value, 2.0), col)
