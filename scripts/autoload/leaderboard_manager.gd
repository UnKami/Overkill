extends Node
## LeaderboardManager — Global Run & Career Account Leaderboards backed by Firestore.
## Provides seamless REST synchronization with Cloud Firestore (`overkill-86f3e`),
## real-time rank computation, offline fallback caching, and persistent lifetime stats.

signal leaderboard_updated(category: String, entries: Array)
signal run_submitted(success: bool, rank: int)
signal profile_updated()

const FIREBASE_PROJECT_ID: String = "overkill-86f3e"
const FIREBASE_API_KEY: String = "AIzaSyB5tQ_t_2_w-9BAQjeAl454K5oZqLWCjrQ"
const FIRESTORE_REST_BASE: String = "https://firestore.googleapis.com/v1/projects/overkill-86f3e/databases/(default)/documents"
const PROFILE_SAVE_PATH: String = "user://saves/player_profile.json"
const LEADERBOARD_CACHE_PATH: String = "user://saves/leaderboard_cache.json"

const RUN_COLLECTION: String = "run_leaderboard"
const ACCOUNT_COLLECTION: String = "account_leaderboard"
const MAX_LEADERBOARD_ENTRIES: int = 50

# Player profile state
var player_id: String = ""
var player_name: String = "Executioner"
var runs_started: int = 0
var runs_completed: int = 0
var lifetime_overkill: int = 0
var best_run_overkill: int = 0

# Last completed run state
var last_run_score: int = 0
var last_run_rank: int = -1
var last_run_act: int = 1
var last_run_won: bool = false
var last_run_relics: int = 0
var last_run_archetype: String = "Unknown"
var last_run_timestamp: int = 0

# In-memory caches
var cached_runs: Array = []
var cached_accounts: Array = []
var is_fetching_runs: bool = false
var is_fetching_accounts: bool = false

# Active view overlay
var _active_view_overlay: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_profile()
	_load_leaderboard_cache()
	if cached_runs.is_empty():
		cached_runs = _build_default_run_pool()
	if cached_accounts.is_empty():
		cached_accounts = _build_default_account_pool()
	_sort_and_rank_caches()
	if RunManager != null and RunManager.has_signal("run_started"):
		RunManager.run_started.connect(record_run_started)
	# Proactively fetch live leaderboards in background
	fetch_run_leaderboard()
	fetch_account_leaderboard()


func _dispatch_http(url: String, method: HTTPClient.Method, headers: PackedStringArray, body_str: String, callback: Callable) -> void:
	var req := HTTPRequest.new()
	req.timeout = 8.0
	add_child(req)
	req.request_completed.connect(func(res: int, code: int, hdrs: PackedStringArray, body: PackedByteArray) -> void:
		if is_instance_valid(self) and callback.is_valid():
			callback.call(res, code, hdrs, body)
		req.queue_free()
	)
	var err := req.request(url, headers, method, body_str)
	if err != OK:
		req.queue_free()


# -----------------------------------------------------------------------------
# LIFECYCLE & STAT RECORDING
# -----------------------------------------------------------------------------

## Called when player starts a new run
func record_run_started() -> void:
	runs_started += 1
	_save_profile()
	_submit_account_stats()
	profile_updated.emit()


## Called when a run ends (victory or defeat)
func record_run_completed(run_overkill: int, act_reached: int, won: bool, relics_count: int, archetype: String = "") -> int:
	last_run_score = maxi(0, run_overkill)
	last_run_act = act_reached
	last_run_won = won
	last_run_relics = relics_count
	last_run_archetype = archetype if not archetype.is_empty() else _detect_primary_archetype()
	last_run_timestamp = int(Time.get_unix_time_from_system())

	runs_completed += 1
	lifetime_overkill += last_run_score
	if last_run_score > best_run_overkill:
		best_run_overkill = last_run_score

	# Generate new run record entry
	var run_entry: Dictionary = {
		"run_id": "run_%s_%d" % [player_id.substr(0, 8), last_run_timestamp],
		"player_id": player_id,
		"player_name": player_name,
		"overkill_score": last_run_score,
		"act_reached": last_run_act,
		"won": last_run_won,
		"relics_count": last_run_relics,
		"archetype": last_run_archetype,
		"timestamp": last_run_timestamp,
		"is_self": true
	}

	# Insert into local runs cache and determine placement
	_insert_into_run_cache(run_entry)
	last_run_rank = _find_run_rank(run_entry["run_id"])

	# Update accounts cache for self
	_update_self_in_account_cache()

	_save_profile()
	_save_leaderboard_cache()

	# Push run and account update to Firestore
	_submit_run_record(run_entry)
	_submit_account_stats()

	run_submitted.emit(true, last_run_rank)
	profile_updated.emit()
	return last_run_rank


func get_average_overkill() -> float:
	if runs_started <= 0:
		return 0.0
	return float(lifetime_overkill) / float(runs_started)


func get_account_rank() -> int:
	for i in range(cached_accounts.size()):
		var acc: Dictionary = cached_accounts[i]
		if acc.get("player_id", "") == player_id or acc.get("is_self", false):
			return i + 1
	return max(1, cached_accounts.size() + 1)


func set_player_name(new_name: String) -> void:
	var trimmed: String = new_name.strip_edges()
	if trimmed.is_empty():
		return
	if trimmed.length() > 20:
		trimmed = trimmed.substr(0, 20)
	player_name = trimmed
	_save_profile()
	_update_self_in_account_cache()
	_submit_account_stats()
	profile_updated.emit()


# -----------------------------------------------------------------------------
# REST FIRESTORE API
# -----------------------------------------------------------------------------

func fetch_run_leaderboard(force_refresh: bool = false) -> void:
	if is_fetching_runs and not force_refresh:
		return
	is_fetching_runs = true
	var url: String = "%s:runQuery?key=%s" % [FIRESTORE_REST_BASE, FIREBASE_API_KEY]
	var query: Dictionary = {
		"structuredQuery": {
			"from": [{"collectionId": RUN_COLLECTION}],
			"orderBy": [{"field": {"fieldPath": "overkill_score"}, "direction": "DESCENDING"}],
			"limit": MAX_LEADERBOARD_ENTRIES
		}
	}
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var json_body: String = JSON.stringify(query)
	_dispatch_http(url, HTTPClient.METHOD_POST, headers, json_body, _on_query_runs_completed)


func fetch_account_leaderboard(force_refresh: bool = false) -> void:
	if is_fetching_accounts and not force_refresh:
		return
	is_fetching_accounts = true
	var url: String = "%s:runQuery?key=%s" % [FIRESTORE_REST_BASE, FIREBASE_API_KEY]
	var query: Dictionary = {
		"structuredQuery": {
			"from": [{"collectionId": ACCOUNT_COLLECTION}],
			"orderBy": [{"field": {"fieldPath": "average_overkill"}, "direction": "DESCENDING"}],
			"limit": MAX_LEADERBOARD_ENTRIES
		}
	}
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var json_body: String = JSON.stringify(query)
	_dispatch_http(url, HTTPClient.METHOD_POST, headers, json_body, _on_query_accounts_completed)


func _submit_run_record(run_entry: Dictionary) -> void:
	var doc_id: String = str(run_entry.get("run_id", ""))
	var url: String = "%s/%s?documentId=%s&key=%s" % [FIRESTORE_REST_BASE, RUN_COLLECTION, doc_id, FIREBASE_API_KEY]
	var firestore_doc: Dictionary = {
		"fields": _dict_to_firestore_fields({
			"run_id": doc_id,
			"player_id": player_id,
			"player_name": player_name,
			"overkill_score": int(run_entry.get("overkill_score", 0)),
			"act_reached": int(run_entry.get("act_reached", 1)),
			"won": bool(run_entry.get("won", false)),
			"relics_count": int(run_entry.get("relics_count", 0)),
			"archetype": str(run_entry.get("archetype", "Chrono-Overdrive")),
			"timestamp": int(run_entry.get("timestamp", Time.get_unix_time_from_system()))
		})
	}
	var headers: PackedStringArray = ["Content-Type: application/json"]
	_dispatch_http(url, HTTPClient.METHOD_POST, headers, JSON.stringify(firestore_doc), _on_submit_run_completed)


func _submit_account_stats() -> void:
	# PATCH document with player_id
	var doc_id: String = player_id
	var url: String = "%s/%s/%s?key=%s" % [FIRESTORE_REST_BASE, ACCOUNT_COLLECTION, doc_id, FIREBASE_API_KEY]
	var firestore_doc: Dictionary = {
		"fields": _dict_to_firestore_fields({
			"player_id": player_id,
			"player_name": player_name,
			"runs_started": runs_started,
			"runs_completed": runs_completed,
			"lifetime_overkill": lifetime_overkill,
			"average_overkill": get_average_overkill(),
			"best_run_overkill": best_run_overkill,
			"last_updated": int(Time.get_unix_time_from_system())
		})
	}
	var headers: PackedStringArray = ["Content-Type: application/json"]
	_dispatch_http(url, HTTPClient.METHOD_PATCH, headers, JSON.stringify(firestore_doc), _on_submit_account_completed)


# -----------------------------------------------------------------------------
# HTTP CALLBACKS
# -----------------------------------------------------------------------------

func _on_query_runs_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_fetching_runs = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	var text: String = body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if parsed is Array:
		var remote_runs: Array = []
		for item in parsed:
			if item is Dictionary and item.has("document"):
				var doc: Dictionary = item["document"]
				var fields: Dictionary = doc.get("fields", {})
				var data: Dictionary = _firestore_fields_to_dict(fields)
				data["is_self"] = (data.get("player_id", "") == player_id)
				remote_runs.append(data)
		if not remote_runs.is_empty():
			_merge_remote_runs(remote_runs)
			_sort_and_rank_caches()
			_save_leaderboard_cache()
			leaderboard_updated.emit("runs", cached_runs)


func _on_query_accounts_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_fetching_accounts = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	var text: String = body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if parsed is Array:
		var remote_accounts: Array = []
		for item in parsed:
			if item is Dictionary and item.has("document"):
				var doc: Dictionary = item["document"]
				var fields: Dictionary = doc.get("fields", {})
				var data: Dictionary = _firestore_fields_to_dict(fields)
				data["is_self"] = (data.get("player_id", "") == player_id)
				remote_accounts.append(data)
		if not remote_accounts.is_empty():
			_merge_remote_accounts(remote_accounts)
			_sort_and_rank_caches()
			_save_leaderboard_cache()
			leaderboard_updated.emit("accounts", cached_accounts)


func _on_submit_run_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var success: bool = (result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201))
	run_submitted.emit(success, last_run_rank)


func _on_submit_account_completed(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	pass


# -----------------------------------------------------------------------------
# FIRESTORE DATA CONVERSIONS
# -----------------------------------------------------------------------------

func _dict_to_firestore_fields(data: Dictionary) -> Dictionary:
	var fields: Dictionary = {}
	for k in data.keys():
		var val = data[k]
		if val is bool:
			fields[k] = {"booleanValue": val}
		elif val is int:
			fields[k] = {"integerValue": str(val)}
		elif val is float:
			fields[k] = {"doubleValue": val}
		elif val is String:
			fields[k] = {"stringValue": val}
		elif val is Array:
			var arr_vals: Array = []
			for item in val:
				if item is String:
					arr_vals.append({"stringValue": item})
				elif item is int:
					arr_vals.append({"integerValue": str(item)})
			fields[k] = {"arrayValue": {"values": arr_vals}}
	return fields


func _firestore_fields_to_dict(fields: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in fields.keys():
		var typed_obj: Dictionary = fields[k]
		if typed_obj.has("stringValue"):
			out[k] = typed_obj["stringValue"]
		elif typed_obj.has("integerValue"):
			out[k] = int(typed_obj["integerValue"])
		elif typed_obj.has("doubleValue"):
			out[k] = float(typed_obj["doubleValue"])
		elif typed_obj.has("booleanValue"):
			out[k] = bool(typed_obj["booleanValue"])
		elif typed_obj.has("timestampValue"):
			out[k] = typed_obj["timestampValue"]
	return out


# -----------------------------------------------------------------------------
# LOCAL CACHE & MOCK SEEDING
# -----------------------------------------------------------------------------

func _insert_into_run_cache(new_entry: Dictionary) -> void:
	cached_runs.append(new_entry)
	cached_runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("overkill_score", 0)) > int(b.get("overkill_score", 0))
	)
	if cached_runs.size() > MAX_LEADERBOARD_ENTRIES:
		cached_runs.resize(MAX_LEADERBOARD_ENTRIES)


func _update_self_in_account_cache() -> void:
	var found: bool = false
	var self_entry: Dictionary = {
		"player_id": player_id,
		"player_name": player_name,
		"runs_started": runs_started,
		"runs_completed": runs_completed,
		"lifetime_overkill": lifetime_overkill,
		"average_overkill": get_average_overkill(),
		"best_run_overkill": best_run_overkill,
		"is_self": true
	}
	for i in range(cached_accounts.size()):
		if cached_accounts[i].get("player_id", "") == player_id or cached_accounts[i].get("is_self", false):
			cached_accounts[i] = self_entry
			found = true
			break
	if not found:
		cached_accounts.append(self_entry)
	cached_accounts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("average_overkill", 0.0)) > float(b.get("average_overkill", 0.0))
	)
	if cached_accounts.size() > MAX_LEADERBOARD_ENTRIES:
		cached_accounts.resize(MAX_LEADERBOARD_ENTRIES)


func _merge_remote_runs(remote: Array) -> void:
	var map: Dictionary = {}
	for r in cached_runs:
		if r.get("is_self", false):
			map[r.get("run_id", "")] = r
	for r in remote:
		map[r.get("run_id", "")] = r
	cached_runs = map.values()
	cached_runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("overkill_score", 0)) > int(b.get("overkill_score", 0))
	)
	if cached_runs.size() > MAX_LEADERBOARD_ENTRIES:
		cached_runs.resize(MAX_LEADERBOARD_ENTRIES)


func _merge_remote_accounts(remote: Array) -> void:
	var map: Dictionary = {}
	for a in cached_accounts:
		if a.get("is_self", false):
			map[a.get("player_id", "")] = a
	for a in remote:
		map[a.get("player_id", "")] = a
	cached_accounts = map.values()
	cached_accounts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("average_overkill", 0.0)) > float(b.get("average_overkill", 0.0))
	)
	if cached_accounts.size() > MAX_LEADERBOARD_ENTRIES:
		cached_accounts.resize(MAX_LEADERBOARD_ENTRIES)


func _sort_and_rank_caches() -> void:
	cached_runs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("overkill_score", 0)) > int(b.get("overkill_score", 0))
	)
	cached_accounts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("average_overkill", 0.0)) > float(b.get("average_overkill", 0.0))
	)


func _find_run_rank(run_id: String) -> int:
	for i in range(cached_runs.size()):
		if cached_runs[i].get("run_id", "") == run_id:
			return i + 1
	return max(1, cached_runs.size() + 1)


func _build_default_run_pool() -> Array:
	var pool: Array = [
		{"run_id": "mock_01", "player_name": "Valerius_Prime", "overkill_score": 218, "act_reached": 3, "won": true, "relics_count": 12, "archetype": "Chrono-Overdrive"},
		{"run_id": "mock_02", "player_name": "Iron_Bastion_09", "overkill_score": 194, "act_reached": 3, "won": true, "relics_count": 11, "archetype": "Iron Bastion"},
		{"run_id": "mock_03", "player_name": "Siphon_Wraith", "overkill_score": 178, "act_reached": 3, "won": true, "relics_count": 12, "archetype": "Crimson Hemorrhage"},
		{"run_id": "mock_04", "player_name": "Harvest_King", "overkill_score": 165, "act_reached": 3, "won": true, "relics_count": 10, "archetype": "Overkill Harvest"},
		{"run_id": "mock_05", "player_name": "Chrono_Vanguard", "overkill_score": 152, "act_reached": 3, "won": false, "relics_count": 12, "archetype": "Chrono-Overdrive"},
		{"run_id": "mock_06", "player_name": "Rupture_Echo", "overkill_score": 141, "act_reached": 2, "won": false, "relics_count": 9, "archetype": "Crimson Hemorrhage"},
		{"run_id": "mock_07", "player_name": "Aegis_Smith", "overkill_score": 134, "act_reached": 3, "won": false, "relics_count": 11, "archetype": "Iron Bastion"},
		{"run_id": "mock_08", "player_name": "Void_Pendulum", "overkill_score": 126, "act_reached": 2, "won": false, "relics_count": 8, "archetype": "Chrono-Overdrive"},
		{"run_id": "mock_09", "player_name": "Abacus_Reaper", "overkill_score": 118, "act_reached": 2, "won": false, "relics_count": 9, "archetype": "Overkill Harvest"},
		{"run_id": "mock_10", "player_name": "Gilded_Gear", "overkill_score": 105, "act_reached": 2, "won": false, "relics_count": 8, "archetype": "Chrono-Overdrive"},
		{"run_id": "mock_11", "player_name": "Spike_Maiden", "overkill_score": 96, "act_reached": 1, "won": false, "relics_count": 7, "archetype": "Iron Bastion"},
		{"run_id": "mock_12", "player_name": "Blood_Tithe_99", "overkill_score": 88, "act_reached": 1, "won": false, "relics_count": 6, "archetype": "Crimson Hemorrhage"},
		{"run_id": "mock_13", "player_name": "Clockwright_Apprentice", "overkill_score": 74, "act_reached": 1, "won": false, "relics_count": 6, "archetype": "Overkill Harvest"},
		{"run_id": "mock_14", "player_name": "Rusting_Blade", "overkill_score": 62, "act_reached": 1, "won": false, "relics_count": 5, "archetype": "Chrono-Overdrive"},
		{"run_id": "mock_15", "player_name": "Cinder_Novice", "overkill_score": 45, "act_reached": 1, "won": false, "relics_count": 4, "archetype": "Iron Bastion"}
	]
	return pool


func _build_default_account_pool() -> Array:
	var pool: Array = [
		{"player_id": "acc_01", "player_name": "Valerius_Prime", "runs_started": 24, "runs_completed": 19, "lifetime_overkill": 3480, "average_overkill": 145.0, "best_run_overkill": 218},
		{"player_id": "acc_02", "player_name": "Iron_Bastion_09", "runs_started": 18, "runs_completed": 14, "lifetime_overkill": 2430, "average_overkill": 135.0, "best_run_overkill": 194},
		{"player_id": "acc_03", "player_name": "Siphon_Wraith", "runs_started": 16, "runs_completed": 12, "lifetime_overkill": 1952, "average_overkill": 122.0, "best_run_overkill": 178},
		{"player_id": "acc_04", "player_name": "Harvest_King", "runs_started": 20, "runs_completed": 13, "lifetime_overkill": 2240, "average_overkill": 112.0, "best_run_overkill": 165},
		{"player_id": "acc_05", "player_name": "Chrono_Vanguard", "runs_started": 15, "runs_completed": 9, "lifetime_overkill": 1530, "average_overkill": 102.0, "best_run_overkill": 152},
		{"player_id": "acc_06", "player_name": "Aegis_Smith", "runs_started": 14, "runs_completed": 8, "lifetime_overkill": 1316, "average_overkill": 94.0, "best_run_overkill": 134},
		{"player_id": "acc_07", "player_name": "Rupture_Echo", "runs_started": 12, "runs_completed": 7, "lifetime_overkill": 1068, "average_overkill": 89.0, "best_run_overkill": 141},
		{"player_id": "acc_08", "player_name": "Void_Pendulum", "runs_started": 10, "runs_completed": 5, "lifetime_overkill": 810, "average_overkill": 81.0, "best_run_overkill": 126},
		{"player_id": "acc_09", "player_name": "Abacus_Reaper", "runs_started": 11, "runs_completed": 5, "lifetime_overkill": 825, "average_overkill": 75.0, "best_run_overkill": 118},
		{"player_id": "acc_10", "player_name": "Gilded_Gear", "runs_started": 8, "runs_completed": 3, "lifetime_overkill": 544, "average_overkill": 68.0, "best_run_overkill": 105}
	]
	return pool


func _detect_primary_archetype() -> String:
	if not RunManager or not (RunManager.clock_inventory is Array):
		return "Chrono-Overdrive"
	var counts: Dictionary = {
		"Chrono-Overdrive": 0,
		"Iron Bastion": 0,
		"Crimson Hemorrhage": 0,
		"Overkill Harvest": 0
	}
	for relic_entry in RunManager.clock_inventory:
		if not (relic_entry is Dictionary):
			continue
		var id: String = str(relic_entry.get("id", ""))
		if id in ["REL-02", "REL-08", "REL-10", "REL-14", "REL-16", "REL-21", "REL-29"]:
			counts["Chrono-Overdrive"] += 1
		elif id in ["REL-04", "REL-05", "REL-06", "REL-12", "REL-15", "REL-22", "REL-24", "REL-27"]:
			counts["Iron Bastion"] += 1
		elif id in ["REL-07", "REL-09", "REL-13", "REL-17", "REL-23", "REL-28"]:
			counts["Crimson Hemorrhage"] += 1
		elif id in ["REL-01", "REL-03", "REL-11", "REL-18", "REL-19", "REL-20", "REL-25", "REL-26"]:
			counts["Overkill Harvest"] += 1
	var best_arch: String = "Chrono-Overdrive"
	var best_count: int = -1
	for arch in counts.keys():
		if counts[arch] > best_count:
			best_count = counts[arch]
			best_arch = arch
	return best_arch


# -----------------------------------------------------------------------------
# PERSISTENCE
# -----------------------------------------------------------------------------

func _save_profile() -> void:
	var data: Dictionary = {
		"player_id": player_id,
		"player_name": player_name,
		"runs_started": runs_started,
		"runs_completed": runs_completed,
		"lifetime_overkill": lifetime_overkill,
		"best_run_overkill": best_run_overkill,
		"last_run_score": last_run_score,
		"last_run_rank": last_run_rank
	}
	DirAccess.make_dir_recursive_absolute(PROFILE_SAVE_PATH.get_base_dir())
	var file := FileAccess.open(PROFILE_SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_SAVE_PATH):
		player_id = "ply_%s_%d" % [str(randi()).sha1_text().substr(0, 10), int(Time.get_unix_time_from_system())]
		player_name = "Executioner #%04d" % randi_range(1000, 9999)
		_save_profile()
		return
	var file := FileAccess.open(PROFILE_SAVE_PATH, FileAccess.READ)
	if file != null:
		var text := file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			player_id = str(parsed.get("player_id", ""))
			if player_id.is_empty():
				player_id = "ply_%s_%d" % [str(randi()).sha1_text().substr(0, 10), int(Time.get_unix_time_from_system())]
			player_name = str(parsed.get("player_name", "Executioner"))
			runs_started = int(parsed.get("runs_started", 0))
			runs_completed = int(parsed.get("runs_completed", 0))
			lifetime_overkill = int(parsed.get("lifetime_overkill", 0))
			best_run_overkill = int(parsed.get("best_run_overkill", 0))
			last_run_score = int(parsed.get("last_run_score", 0))
			last_run_rank = int(parsed.get("last_run_rank", -1))


func _save_leaderboard_cache() -> void:
	var data: Dictionary = {
		"runs": cached_runs,
		"accounts": cached_accounts
	}
	DirAccess.make_dir_recursive_absolute(LEADERBOARD_CACHE_PATH.get_base_dir())
	var file := FileAccess.open(LEADERBOARD_CACHE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _load_leaderboard_cache() -> void:
	if not FileAccess.file_exists(LEADERBOARD_CACHE_PATH):
		return
	var file := FileAccess.open(LEADERBOARD_CACHE_PATH, FileAccess.READ)
	if file != null:
		var text := file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			if parsed.has("runs") and parsed["runs"] is Array:
				cached_runs = parsed["runs"]
			if parsed.has("accounts") and parsed["accounts"] is Array:
				cached_accounts = parsed["accounts"]


# -----------------------------------------------------------------------------
# MODAL PRESENTATION
# -----------------------------------------------------------------------------

func show_leaderboard(category: String = "runs") -> void:
	close_leaderboard()
	var view_script = preload("res://scripts/ui/leaderboard_view.gd")
	var instance = view_script.new()
	instance.initial_category = category
	_active_view_overlay = instance
	var root: Window = get_tree().root
	root.add_child(_active_view_overlay)


func close_leaderboard() -> void:
	if _active_view_overlay != null and is_instance_valid(_active_view_overlay):
		_active_view_overlay.queue_free()
		_active_view_overlay = null
