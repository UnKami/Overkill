class_name RunCardEntry extends RefCounted
## One player-owned copy of a card, for the current run. CardData itself stays
## shared/immutable content data (loaded once via ContentDatabase) - this is
## the per-copy mutable record: which card, which specific copy, how upgraded.
## Serializes 1:1 into RunSave.deck with zero translation.

var card_id: String = ""
var instance_id: int = 0
var upgrade_level: int = 0


func _init(p_card_id: String = "", p_instance_id: int = 0, p_upgrade_level: int = 0) -> void:
	card_id = p_card_id
	instance_id = p_instance_id
	upgrade_level = p_upgrade_level


func to_save_dict() -> Dictionary:
	return {"card_id": card_id, "instance_id": instance_id, "upgrade_level": upgrade_level}


static func from_save_dict(data: Dictionary) -> RunCardEntry:
	return RunCardEntry.new(data.get("card_id", ""), data.get("instance_id", 0), data.get("upgrade_level", 0))
