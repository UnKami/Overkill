extends Node
## SaveManager - pure disk I/O, owns zero game state itself (mirrors
## OKRunState's existing zero-persistence-awareness precedent). Reads FROM
## RunManager/OKRunState via their to_save_dict() methods rather than
## touching either autoload's fields directly - it never keeps its own copy.
## JSON, not typed Resource serialization, per the technical architecture
## doc: save shape changes over development, and Resource saves break
## silently when a class's fields change between versions.
##
## tutorial_seen deliberately stays in the existing TutorialState.tres store
## rather than living in meta_save.json - that persistence already works and
## nothing else needs to touch that field, so migrating it would be pure
## churn.

const RUN_SAVE_PATH := "user://saves/run_save.json"
const META_SAVE_PATH := "user://saves/meta_save.json"
const RUN_SCHEMA_VERSION := 1
const META_SCHEMA_VERSION := 1

const DEFAULT_SETTINGS := {
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"fast_mode": false,
	"text_size": "normal",
}


func save_run() -> void:
	var data := RunManager.to_save_dict()
	data["ok_run_state"] = OKRunState.to_save_dict()
	data["schema_version"] = RUN_SCHEMA_VERSION
	_write_json(RUN_SAVE_PATH, data)


func load_run() -> Dictionary:
	return _read_json(RUN_SAVE_PATH)


func has_run_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


func delete_run_save() -> void:
	if has_run_save():
		DirAccess.remove_absolute(RUN_SAVE_PATH)


func save_meta(settings: Dictionary) -> void:
	var data := {
		"schema_version": META_SCHEMA_VERSION,
		"settings": settings,
	}
	_write_json(META_SAVE_PATH, data)


func load_meta() -> Dictionary:
	var data := _read_json(META_SAVE_PATH)
	if data.is_empty():
		return {"schema_version": META_SCHEMA_VERSION, "settings": DEFAULT_SETTINGS.duplicate()}
	var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
	settings.merge(data.get("settings", {}), true)
	data["settings"] = settings
	return data


func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open '%s' for writing (error %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
