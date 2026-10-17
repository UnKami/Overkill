extends Node
func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	var hero := Executioner3DActor.new()
	hero.size = Vector2(552,624)
	add_child(hero)
	hero.sample_action_for_review("iron_strike",2.2)
	await get_tree().create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	var before: Image = hero.viewport.get_texture().get_image()
	var occupied: Rect2i = before.get_used_rect()
	hero.model.position += hero.camera.global_basis.x*2.8
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var after: Image = hero.viewport.get_texture().get_image()
	var remnants: int = 0
	for y: int in range(occupied.position.y,occupied.end.y):
		for x: int in range(occupied.position.x,occupied.end.x):
			if before.get_pixel(x,y).a>.1 and after.get_pixel(x,y).a>.01: remnants+=1
	before.save_png("res://.test-artifacts/047/history-before.png")
	after.save_png("res://.test-artifacts/047/history-after.png")
	print("CHARACTER_RENDER_HISTORY remnants=%d old_bounds=%s" % [remnants,str(occupied)])
	get_tree().quit(0 if remnants==0 else 1)
