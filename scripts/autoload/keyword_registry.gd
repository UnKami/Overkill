extends Node
## KeywordRegistry - single shared lookup mapping status_id / effect patterns to
## (icon, short_label). Any EffectData or StatusEffectData renders through this
## by default. New status effects get added here first, before being wired into
## any card. Data schema doc, Part 3.
##
## rules_text_override on CardData should stay nearly empty - if more than ~10%
## of cards need it, this registry is under-built, not the cards over-designed.
##
## Entries are KeywordEntry (scripts/data/keyword_entry.gd) - a top-level
## class rather than nested here, so callers can type-hint it without going
## through this autoload singleton reference.

var _entries: Dictionary = {}


func _ready() -> void:
	_register("vulnerable", "status_vulnerable", "status", "Vulnerable")
	_register("weak", "status_weak", "status", "Weak")
	_register("strength", "status_strength", "status", "Strength")
	_register("block", "icon_block", "ui", "Block")
	_register("overkill", "icon_overkill", "ui", "Overkill")


func _register(id: String, icon_id: String, icon_subdir: String, label: String) -> void:
	_entries[id] = KeywordEntry.new(icon_id, icon_subdir, label)


func get_entry(id: String) -> KeywordEntry:
	return _entries.get(id, null)


func has_entry(id: String) -> bool:
	return _entries.has(id)
