class_name RelicData extends Resource

enum Trigger {
	ON_KILL,
	ON_OVERKILL,
	ON_TURN_START,
	ON_TURN_END,
	ON_COMBAT_START,
	ON_CARD_PLAYED,
	PASSIVE_MODIFIER,
}

@export var id: String = ""
@export var display_name: String = ""
@export var trigger: Trigger = Trigger.PASSIVE_MODIFIER
@export var effects: Array[EffectData] = []
@export var condition_data: Dictionary = {}     ## trigger-specific params, e.g. {"min_ok": 15}. Flat dict only -
                                                 ## tooltip text renders FROM this, never hand-written separately.
@export_multiline var flavor_text: String = ""
@export var art_id: String = ""
