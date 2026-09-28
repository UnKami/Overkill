extends Node
## Structural smoke test for the cinematic art catalog and deterministic
## screen/encounter routing. Visual composition is covered separately by the
## rendered battle-arrival fixture.

var _failures := PackedStringArray()


func _ready() -> void:
	var paths: PackedStringArray = CinematicArt.all_paths()
	_expect(paths.size() == 30, "catalog exposes exactly 30 authored scenes")
	var unique_paths: Dictionary = {}
	for path: String in paths:
		_expect(ResourceLoader.exists(path), "resource exists: %s" % path)
		unique_paths[path] = true
	_expect(unique_paths.size() == paths.size(), "catalog contains no duplicate scene routes")

	_expect(CinematicArt.map_background(2).ends_with("map_act2_luminous_refinery.jpg"), "act 2 map route")
	_expect(CinematicArt.event_background("cursed_offering").ends_with("event_overflowing_cache.jpg"), "event route")
	_expect(CinematicArt.transition_background(3).ends_with("transition_act3_final.jpg"), "final transition route")

	var regular := EnemyData.new()
	regular.id = "boneghoul"
	regular.tier = EnemyData.Tier.TRASH
	_expect(CinematicArt.combat_background(regular, 1).contains("act1_"), "regular battle stays in its act")
	var elite := EnemyData.new()
	elite.id = "custodian"
	elite.tier = EnemyData.Tier.ELITE
	_expect(CinematicArt.combat_background(elite, 2).ends_with("act2_pressure_chamber.jpg"), "elite route")
	var boss := EnemyData.new()
	boss.id = "final_boss"
	boss.tier = EnemyData.Tier.BOSS
	_expect(CinematicArt.combat_background(boss, 3).ends_with("act3_final_convergence.jpg"), "final boss route")

	if _failures.is_empty():
		print("CINEMATIC_ART_TEST_OK paths=30 unique=30")
		get_tree().quit()
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append("CINEMATIC_ART_TEST_FAIL: %s" % description)
