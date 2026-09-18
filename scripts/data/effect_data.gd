class_name EffectData extends Resource

enum EffectType {
	DAMAGE,
	BLOCK,
	DRAW,
	ENERGY_GAIN,
	APPLY_STATUS,
	GAIN_OK,
	APPLY_SPILLAGE,  ## marker only - flags the DAMAGE effect(s) on this same card as
	                 ## Spillage-carrying (data schema doc 1.1/1.6). Carries no value.
	LOSE_HP,         ## self-inflicted HP loss, bypasses Block - drawback cost for
	                 ## Burst-archetype cards (schema's effect_type enum is explicitly
	                 ## open-ended, this is an intentional documented extension)
}

## Closed set of non-FIXED value sources an effect's value can resolve from at
## preview/resolve time (data schema doc 1.1). ENERGY_SPENT_ON_PLAY is an
## addition to the doc's original three, added here first per its own rule,
## to support X-cost cards (Zero Sum) that both design docs call for.
enum ValueSource { FIXED, LAST_KILL_OK, PLAYER_BLOCK, PLAYER_HP_MISSING, ENERGY_SPENT_ON_PLAY }

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value: int = 0                      ## used as-is when value_source == FIXED
@export var status_id: String = ""              ## only used if effect_type == APPLY_STATUS, refs StatusEffectData
@export var keyword_icon_override: String = ""  ## almost never needed - see KeywordRegistry first

@export var value_source: ValueSource = ValueSource.FIXED
@export var value_multiplier: float = 1.0       ## applied to the resolved source value when
                                                 ## value_source != FIXED. Ignored when FIXED.
