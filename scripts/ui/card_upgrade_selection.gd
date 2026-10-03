class_name CardUpgradeSelection extends "res://scripts/ui/clock_collection_screen.gd"
## Compatibility scene for old links; all upgrade presentation uses real relics.

func _ready() -> void:
	mode = "upgrade"
	pre_battle = true
	super._ready()
