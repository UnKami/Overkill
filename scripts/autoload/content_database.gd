extends Node
## ContentDatabase - resolves content ids (card_id, relic_id) to their Resource.
## Needed because save data stores plain ids (JSON mandate, technical
## architecture doc Part 2.3), not typed Resource references. Scans once at
## startup; nothing else should ResourceLoader.load() a card/relic by
## hand-built path - go through here so there is one place that knows where
## content data lives.

const BASIC_STARTER_RELIC_IDS: Array[String] = ["REL-01", "REL-04"]

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


func all_clock_relics(include_zenith: bool = false) -> Array:
	# Generic catalog query; Zenith relics are reserved for the act-boss Overkill altar.
	var result: Array = []
	for relic: ClockRelicData in _clock_relics_by_id.values():
		if include_zenith or relic.tier != ClockRelicData.Tier.ZENITH:
			result.append(relic)
	return result


func reward_clock_relics(elite_reward: bool = false) -> Array[ClockRelicData]:
	## Returns non-basic clock relics ordered so the first 3 choices follow
	## Slay-the-Spire rarity weighting (Normal: 75% Common / 25% Rare;
	## Elite: 50% Common / 50% Rare with at least 1 Rare guaranteed in the top 3).
	var commons: Array[ClockRelicData] = []
	var rares: Array[ClockRelicData] = []
	for relic: ClockRelicData in _clock_relics_by_id.values():
		if relic.tier == ClockRelicData.Tier.ZENITH or relic.tier == ClockRelicData.Tier.STARTER:
			continue
		if relic.id in BASIC_STARTER_RELIC_IDS:
			continue
		if relic.tier == ClockRelicData.Tier.RARE:
			rares.append(relic)
		else:
			commons.append(relic)
	commons.shuffle()
	rares.shuffle()

	var drafted: Array[ClockRelicData] = []
	var rare_chance: float = 0.50 if elite_reward else 0.25
	var picked_rare: bool = false
	for slot_idx: int in range(3):
		var force_rare: bool = elite_reward and slot_idx == 2 and not picked_rare
		var choose_rare: bool = force_rare or (randf() < rare_chance)
		if choose_rare and not rares.is_empty():
			drafted.append(rares.pop_back())
			picked_rare = true
		elif not commons.is_empty():
			drafted.append(commons.pop_back())
		elif not rares.is_empty():
			drafted.append(rares.pop_back())
			picked_rare = true
	drafted.shuffle()

	var remainder: Array[ClockRelicData] = []
	remainder.append_array(commons)
	remainder.append_array(rares)
	remainder.shuffle()

	var result: Array[ClockRelicData] = []
	result.append_array(drafted)
	result.append_array(remainder)
	return result


func shop_clock_relics() -> Array[ClockRelicData]:
	## Excludes basic starter filler (REL-01, REL-04) and Zenith boss relics.
	var result: Array[ClockRelicData] = []
	for relic: ClockRelicData in _clock_relics_by_id.values():
		if relic.tier == ClockRelicData.Tier.ZENITH or relic.tier == ClockRelicData.Tier.STARTER:
			continue
		if relic.id in BASIC_STARTER_RELIC_IDS:
			continue
		result.append(relic)
	result.shuffle()
	return result


func get_card(card_id: String) -> CardData:
	return _cards_by_id.get(card_id, null)


func get_relic(relic_id: String) -> RelicData:
	return _relics_by_id.get(relic_id, null)


func get_enemy(enemy_id: String) -> EnemyData:
	return _enemies_by_id.get(enemy_id, null)


func all_cards() -> Array:
	return _cards_by_id.values()


func all_relics(include_run_artifacts: bool = false) -> Array:
	var result: Array = []
	for relic: RelicData in _relics_by_id.values():
		if include_run_artifacts or not relic.id.begins_with("artifact_"):
			result.append(relic)
	return result


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
