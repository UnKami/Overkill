class_name EffectData extends Resource

enum EffectType {
	DAMAGE,
	BLOCK,
	DRAW,
	ENERGY_GAIN,
	APPLY_STATUS,
	GAIN_OK,
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0
@export var status_id: String = ""              ## only used if effect_type == APPLY_STATUS, refs StatusEffectData
@export var keyword_icon_override: String = ""  ## almost never needed - see KeywordRegistry first
