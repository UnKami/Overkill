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
	_register("vulnerable", "status_vulnerable", "status", "Vulnerable", "Takes 50% more damage from attacks while this many stacks remain. Loses 1 stack at the end of the affected turn.")
	_register("weak", "status_weak", "status", "Weak", "Deals 25% less damage with attacks while this many stacks remain. Loses 1 stack at the end of the affected turn.")
	_register("strength", "status_strength", "status", "Strength", "Adds flat bonus damage to every attack. Does not decay - it lasts for the rest of combat.")
	_register("block", "icon_block", "ui", "Block", "Absorbs incoming damage this turn point-for-point, then resets to 0 at the start of your next turn.")
	_register("overkill", "icon_overkill", "ui", "Overkill", "Damage dealt beyond what was needed to kill - banked as OK, the currency spent on cards, relics, and upgrades between fights.")
	_register("spillage", "icon_spillage", "ui", "Spillage", "Any Overkill from this hit carries over as damage to the next enemy in line, instead of being banked as OK.")
	_register("lose_hp", "icon_hp_loss", "ui", "Lose HP", "Costs you HP directly, bypassing Block entirely - this damage cannot be reduced or prevented.")


func _register(id: String, icon_id: String, icon_subdir: String, label: String, definition: String = "") -> void:
	_entries[id] = KeywordEntry.new(icon_id, icon_subdir, label, definition)


func get_entry(id: String) -> KeywordEntry:
	return _entries.get(id, null)


func has_entry(id: String) -> bool:
	return _entries.has(id)
