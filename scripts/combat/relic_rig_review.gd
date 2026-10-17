extends Control
## Close-up native review, plus anatomy/export checks. No player-facing autoplay.
const Actor := preload("res://scripts/combat/relic_rig_actor.gd")
var hero: RelicRigActor
var diagnostic: RelicRigActor
var _title: Label
var _clock: float = 0.0
var _current: String = "idle"
var _checks: int = 0
var _failures: int = 0
var _captures: Dictionary = {}
const OUTPUT := "res://.test-artifacts/046/rig-review"

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	AudioManager.fast_mode = false
	AudioManager.reduced_motion = false
	AudioManager.set_master_volume(0.0)
	var background := ColorRect.new()
	background.color = Color("101922")
	background.size = Vector2(1920,1080)
	add_child(background)
	_title = Label.new()
	_title.position = Vector2(60,35)
	_title.add_theme_font_size_override("font_size",32)
	add_child(_title)
	for side: int in 2:
		var actor: RelicRigActor = Actor.new()
		actor.target_height = 650
		actor.target_width = 500
		actor.position = Vector2(80+side*920,70)
		actor.size = Vector2(600,850)
		actor.facing = 1.0
		add_child(actor)
		if side == 0: hero = actor
		else: diagnostic = actor
		var caption := Label.new()
		caption.position = Vector2(80+side*920,985)
		caption.add_theme_font_size_override("font_size",24)
		caption.text = "PAINTED SKIN / RIG IN MOTION" if side == 0 else "SKELETON / PURPLE COLLARBONES"
		add_child(caption)
	var overlay := RigOverlay.new()
	overlay.actor = diagnostic
	overlay.z_index = 100
	add_child(overlay)
	await get_tree().process_frame
	_check_pipeline()
	var actions: Array[String] = ["throw","channel","siphon","iron_strike","twin_left","heavy","bell","block","chalice","crown"]
	for action: String in actions:
		_current = action
		_clock = 0.0
		hero.play_action(action)
		diagnostic.play_action(action)
		while hero._busy:
			await get_tree().process_frame
			if _clock > .48 and _clock < .62: await _capture(action+"-anticipation")
			var contact: float = float(hero.RIG_DATA.actions[action].contact)
			if _clock >= contact and _clock < contact+.12: await _capture(action+"-contact")
			if action == "siphon" and _clock > 2.3 and _clock < 2.45: await _capture("siphon-held-grip")
		await get_tree().create_timer(.25).timeout
	hero.queue_free()
	diagnostic.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("CHARACTER_RIG_REVIEW_OK checks=%d failures=%d clavicles, rigid pauldrons, precise release sampling, sustained casting and ten full actions" % [_checks,_failures])
	get_tree().quit(0 if _failures == 0 else 1)

func _process(delta: float) -> void:
	_clock += delta
	if _title != null: _title.text = "CHARACTER RIG REVIEW   /   %s   /   %.2f s" % [_current.to_upper(),_clock]
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(diagnostic) or diagnostic._bones.is_empty(): return
	for bone: Bone2D in diagnostic._bones:
		var at: Vector2 = get_global_transform().affine_inverse()*bone.global_position
		var parent: Bone2D = bone.get_parent() as Bone2D
		var color: Color = Color("c879ff") if str(bone.name).begins_with("clavicle") else Color("6cd8e0")
		if parent != null: draw_line(get_global_transform().affine_inverse()*parent.global_position,at,color,3.0,true)
		draw_circle(at,5,color)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(message)

func _check_pipeline() -> void:
	_check(hero.skeleton.get_bone_count() == 20,"Twenty-bone character skeleton is active")
	for side: String in ["near","far"]:
		_check(hero._bone_names["arm_"+side].get_parent() == hero._bone_names["clavicle_"+side],"Upper arm follows its collarbone")
		var cap: Dictionary
		for mesh: Dictionary in hero.RIG_DATA.meshes:
			if str(mesh.name) == "pauldron_"+side: cap = mesh
		_check(not cap.is_empty() and cap.weights.keys() == ["clavicle_"+side],"Shoulder cap is rigidly attached to its collarbone")
	for action: String in hero.RIG_DATA.actions:
		for frame: Array in hero.RIG_DATA.actions[action].frames:
			for bone: Dictionary in hero.RIG_DATA.bones:
				if str(bone.name).begins_with("clavicle"):
					var index: int = hero.RIG_DATA.bones.find(bone)
					_check(absf(float(frame[index][2])) <= deg_to_rad(8.01),"Collarbone rotation stays within an anatomical range")
	for action: String in ["throw","siphon","piston","iron_strike","twin_left","heavy"]:
		for time: float in [.52,.76,1.0]:
			hero.sample_action_for_review(action,time)
			var sampled: Transform2D = hero.sample_grip_transform(action,time)
			_check(sampled.origin.distance_to(hero.get_hand_global_position()) < .01,"Pure Blender grip sampler matches the live skeleton")
	hero.sample_action_for_review("siphon",1.6)
	var held: Vector2 = hero.get_hand_global_position()
	hero.sample_action_for_review("siphon",3.2)
	_check(held.distance_to(hero.get_hand_global_position()) < 4.0,"Siphon grip holds steady throughout transfer")
	hero.set_process(true)
	hero._rest()

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless" or _captures.has(label) or OS.get_cmdline_user_args().has("--movie-review"): return
	_captures[label] = true
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+label+".png")

class RigOverlay extends Node2D:
	var actor: RelicRigActor
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		if not is_instance_valid(actor): return
		for bone: Bone2D in actor._bones:
			var at: Vector2 = to_local(bone.global_position)
			var parent: Bone2D = bone.get_parent() as Bone2D
			var color: Color = Color("c879ff") if str(bone.name).begins_with("clavicle") else Color("6cd8e0")
			if parent != null: draw_line(to_local(parent.global_position),at,color,3.0,true)
			draw_circle(at,5,color)