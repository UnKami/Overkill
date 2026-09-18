extends Node

func _ready() -> void:
	AudioManager.set_master_volume(0)
	var encounter := preload("res://scenes/sentinel_encounter.tscn").instantiate()
	add_child(encounter)
	await get_tree().create_timer(0.1).timeout
	assert(encounter._battle._stage is DirectedArena)
	encounter._battle.enemy_hp = 0
	assert(encounter._battle._check_combat_end())
	await get_tree().create_timer(1.7).timeout
	assert(encounter._result != null)
	assert(encounter._result.z_index > 90,"Result must remain above the battle fade")
	var retry: Button = encounter._result.get_child(0).get_child(1)
	retry.pressed.emit()
	await get_tree().process_frame
	assert(encounter._battle.enemy_hp == 175)
	assert(not encounter._battle._combat_over)
	encounter._battle.player_hp = 0
	assert(encounter._battle._check_combat_end())
	await get_tree().create_timer(1.7).timeout
	assert(encounter._result.get_child(0).get_child(0).text == "THE CLOCK FALLS SILENT")
	print("SENTINEL_ENTRY_OK: 3D entry, victory, retry and defeat")
	get_tree().quit()
