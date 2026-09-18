class_name KeywordEntry extends RefCounted
## One entry in KeywordRegistry: an icon_id (matching the exact asset
## basename on disk) plus the short label it renders next to. Kept as its
## own top-level class rather than nested inside the KeywordRegistry
## autoload, so it can be used as a type hint anywhere without going through
## the autoload singleton reference.

var icon_id: String
var icon_subdir: String  # "status" or "ui"
var label: String
var definition: String  ## plain-language explanation, shown as a hover tooltip
                         ## wherever this keyword appears on a card - nothing
                         ## that isn't self-evident from its name+icon alone
                         ## should ship without one.


func _init(p_icon_id: String, p_icon_subdir: String, p_label: String, p_definition: String = "") -> void:
	icon_id = p_icon_id
	icon_subdir = p_icon_subdir
	label = p_label
	definition = p_definition


func icon_path() -> String:
	return "res://assets/icons/%s/%s.png" % [icon_subdir, icon_id]
