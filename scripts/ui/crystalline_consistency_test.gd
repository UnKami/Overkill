extends Node
## Runtime resource contracts; visual acceptance is a separate rendered review.
var _failures: PackedStringArray = []

func _ready() -> void:
	var relics: Array = ContentDatabase.all_clock_relics()
	_expect(relics.size() == 26, "26 live relics")
	for relic: ClockRelicData in relics:
		_expect(not relic.art_id.ends_with("_v2"), "Retired art cannot return: " + relic.id)
		var texture: Texture2D = RelicArt.load_texture(relic.art_id)
		_expect(texture != null, "Relic object exists: " + relic.id)
		if texture != null:
			_expect(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Relic is backgroundless: " + relic.id)
	_expect(RelicArt.load_texture(ContentDatabase.get_clock_relic("REL-03").art_id).resource_path == IllustratedActor.HEAVY_HAMMER_PATH, "Hammer identity matches its attack animation")
	var stage := IllustratedStage.new()
	var distinct: Dictionary = {}
	for enemy_id: String in ["boneghoul", "act1_elite", "act1_boss", "act2_trash", "act2_elite", "act2_boss", "act3_trash", "act3_elite", "act3_boss", "final_boss"]:
		var enemy: EnemyData = ContentDatabase.get_enemy(enemy_id)
		_expect(enemy != null, "Enemy registered: " + enemy_id)
		var path: String = stage._enemy_art_path(enemy.art_id)
		_expect(path.contains("crystalline") or path.ends_with("final_boss_crystal_warden.png"), "Enemy uses crystalline canon: " + enemy_id)
		distinct[path] = true
		var texture: Texture2D = load(path)
		_expect(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Enemy cutout has transparency: " + enemy_id)
	_expect(distinct.size() == 10, "Ten separate enemy silhouettes")
	_expect(stage._enemy_art_path("unknown").ends_with("boneghoul_crystalline.png"), "Fallback cannot reintroduce old humanoid")
	stage.free()
	for path: String in CinematicArt.all_paths():
		_expect(ResourceLoader.exists(path), "Cinematic route resolves: " + path)
		_expect(not path.contains("_painterly"), "No discarded cinematic routes")
	_expect(ProjectSettings.get_setting("application/boot_splash/image") == CinematicArt.LOADING, "Startup and transition loading art agree")
	RunManager.start_new_run([], [], 75, 731)
	var upgrade: Control = load("res://scenes/card_upgrade_selection.tscn").instantiate()
	add_child(upgrade)
	await get_tree().process_frame
	_expect(upgrade.mode == "upgrade" and upgrade.pre_battle, "Compatibility route presents a real relic upgrade")
	_expect(upgrade.find_children("*", "CardView", true, false).is_empty(), "No scenery-card upgrade interface")
	upgrade.queue_free()
	await get_tree().process_frame
	if _failures.is_empty():
		print("CRYSTALLINE_CONSISTENCY_OK: 26 relics, 10 enemies, cinematic routes, matching hammer and relic upgrade")
	else:
		for failure: String in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

