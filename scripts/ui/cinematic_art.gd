class_name CinematicArt extends RefCounted
## Canonical routing for the painterly-real Overkill environment library.
## Keeping every choice here prevents screens from drifting back to unrelated
## placeholder art and makes the role of each generated plate auditable.

const ENVIRONMENT_ROOT := "res://assets/environments/cinematic/"
const SCREEN_ROOT := "res://assets/screens/cinematic/"
const FINAL_BOSS_ARENA := ENVIRONMENT_ROOT + "act3_final_convergence.jpg"

const TITLE := SCREEN_ROOT + "title_last_bell.jpg"
const CLASS_SELECT := SCREEN_ROOT + "class_executioner_altar.jpg"
const PRE_BATTLE := SCREEN_ROOT + "prebattle_forgemaster_offer.jpg"
const REWARD := SCREEN_ROOT + "reward_victory_cache.jpg"
const RELIC_REWARD := SCREEN_ROOT + "reward_relic_vault.jpg"
const COLLECTION := SCREEN_ROOT + "collection_archive_hall.jpg"
const UPGRADE := SCREEN_ROOT + "upgrade_memory_forge.jpg"
const LOADING := SCREEN_ROOT + "loading_crystalline_passage.png"
const VICTORY := SCREEN_ROOT + "victory_balanced_clock.jpg"
const DEFEAT := SCREEN_ROOT + "defeat_extinguished_clock.jpg"

const MAP_BY_ACT := {
	1: SCREEN_ROOT + "map_act1_pilgrim_ruins.jpg",
	2: SCREEN_ROOT + "map_act2_luminous_refinery.jpg",
	3: SCREEN_ROOT + "map_act3_fractured_horizon.jpg",
}

const EVENT_BY_ID := {
	"greedy_shrine": SCREEN_ROOT + "event_humming_shrine.jpg",
	"cursed_offering": SCREEN_ROOT + "event_overflowing_cache.jpg",
}

const TRANSITION_BY_ACT := {
	1: SCREEN_ROOT + "transition_act1_act2.jpg",
	2: SCREEN_ROOT + "transition_act2_act3.jpg",
	3: SCREEN_ROOT + "transition_act3_final.jpg",
}

static var BATTLE_BY_ACT: Dictionary = {
	1: {
		"regular": PackedStringArray([
			ENVIRONMENT_ROOT + "act1_fallen_nave.jpg",
			ENVIRONMENT_ROOT + "act1_crystal_cloister.jpg",
		]),
		"elite": ENVIRONMENT_ROOT + "act1_execution_court.jpg",
		"boss": ENVIRONMENT_ROOT + "act1_bell_sanctum.jpg",
	},
	2: {
		"regular": PackedStringArray([
			ENVIRONMENT_ROOT + "act2_refinery_floor.jpg",
			ENVIRONMENT_ROOT + "act2_furnace_bridge.jpg",
		]),
		"elite": ENVIRONMENT_ROOT + "act2_pressure_chamber.jpg",
		"boss": ENVIRONMENT_ROOT + "act2_chronoforge_core.jpg",
	},
	3: {
		"regular": PackedStringArray([
			ENVIRONMENT_ROOT + "act3_shattered_causeway.jpg",
			ENVIRONMENT_ROOT + "act3_void_cathedral.jpg",
		]),
		"elite": ENVIRONMENT_ROOT + "act3_zenith_vault.jpg",
		"boss": ENVIRONMENT_ROOT + "act3_final_convergence.jpg",
	},
}


static func map_background(act_number: int) -> String:
	return String(MAP_BY_ACT.get(act_number, MAP_BY_ACT[1]))


static func event_background(event_id: String) -> String:
	return String(EVENT_BY_ID.get(event_id, SCREEN_ROOT + "event_humming_shrine.jpg"))


static func transition_background(completed_act: int) -> String:
	return String(TRANSITION_BY_ACT.get(completed_act, TRANSITION_BY_ACT[1]))


static func combat_background(enemy: EnemyData, act_number: int) -> String:
	if enemy == null:
		return ENVIRONMENT_ROOT + "act1_fallen_nave.jpg"
	if enemy.id == "final_boss":
		return FINAL_BOSS_ARENA
	var act_catalog: Dictionary = BATTLE_BY_ACT.get(act_number, BATTLE_BY_ACT[1])
	match enemy.tier:
		EnemyData.Tier.BOSS:
			return String(act_catalog.boss)
		EnemyData.Tier.ELITE:
			return String(act_catalog.elite)
		_:
			var regular: PackedStringArray = act_catalog.regular
			var stable_index: int = absi(hash(enemy.id)) % regular.size()
			return regular[stable_index]


static func all_paths() -> PackedStringArray:
	var result := PackedStringArray([
		TITLE, CLASS_SELECT, PRE_BATTLE, REWARD, RELIC_REWARD, COLLECTION,
		UPGRADE, LOADING, VICTORY, DEFEAT,
	])
	for path: String in MAP_BY_ACT.values():
		result.append(path)
	for path: String in EVENT_BY_ID.values():
		result.append(path)
	for path: String in TRANSITION_BY_ACT.values():
		result.append(path)
	for act_catalog: Dictionary in BATTLE_BY_ACT.values():
		for regular_path: String in act_catalog.regular:
			result.append(regular_path)
		result.append(String(act_catalog.elite))
		result.append(String(act_catalog.boss))
	return result
