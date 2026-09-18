extends Node
## ContentDatabase - resolves content ids (card_id, relic_id) to their Resource.
## Needed because save data stores plain ids (JSON mandate, technical
## architecture doc Part 2.3), not typed Resource references. Scans once at
## startup; nothing else should ResourceLoader.load() a card/relic by
## hand-built path - go through here so there is one place that knows where
## content data lives.

var _cards_by_id: Dictionary = {}   # String -> CardData
var _relics_by_id: Dictionary = {}  # String -> RelicData
var _enemies_by_id: Dictionary = {} # String -> EnemyData
var _clock_relics_by_id: Dictionary = {}


func _ready() -> void:
	_scan_into("res://data/cards/", _cards_by_id)
	_scan_into("res://data/relics/", _relics_by_id)
	_scan_into("res://data/enemies/", _enemies_by_id)
	_scan_into("res://data/clock_relics/", _clock_relics_by_id)


func get_clock_relic(relic_id: String) -> ClockRelicData:
	return _clock_relics_by_id.get(relic_id, null)


func all_clock_relics() -> Array:
	return _clock_relics_by_id.values()


func get_card(card_id: String) -> CardData:
	return _cards_by_id.get(card_id, null)


func get_relic(relic_id: String) -> RelicData:
	return _relics_by_id.get(relic_id, null)


func get_enemy(enemy_id: String) -> EnemyData:
	return _enemies_by_id.get(enemy_id, null)


func all_cards() -> Array:
	return _cards_by_id.values()


func all_relics() -> Array:
	return _relics_by_id.values()


func _scan_into(root_path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return
	_scan_dir_recursive(dir, root_path, target)


func _scan_dir_recursive(dir: DirAccess, path: String, target: Dictionary) -> void:
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			var sub_dir := DirAccess.open(full_path)
			if sub_dir != null:
				_scan_dir_recursive(sub_dir, full_path, target)
		elif entry.ends_with(".tres") or entry.ends_with(".tres.remap"):
			# Exported/packed builds list resources with a ".remap" suffix
			# (e.g. "strike.tres.remap") instead of their plain filename -
			# ResourceLoader still wants the original path with that suffix
			# stripped, Godot resolves the remap internally. Editor/dev runs
			# never hit this branch since unpacked source files list under
			# their plain name.
			var resource_path: String = full_path.trim_suffix(".remap")
			var resource: Resource = ResourceLoader.load(resource_path)
			if resource != null and "id" in resource and not String(resource.id).is_empty():
				target[resource.id] = resource
		entry = dir.get_next()
	dir.list_dir_end()
