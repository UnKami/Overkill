extends Node


func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	RunManager.start_new_run([], [], 500, 934)
	OKRunState.current_ok = 90
	var altar: BossOverkillAltar = load("res://scenes/boss_overkill_altar.tscn").instantiate()
	altar.set_boss_context(ContentDatabase.get_enemy("act1_boss"))
	add_child(altar)
	await get_tree().create_timer(0.8).timeout
	for id: String in BossOverkillAltar.OFFER_IDS:
		assert(ContentDatabase.get_clock_relic(id) != null, "Zenith relic must resolve by ID")
		assert(not ContentDatabase.all_clock_relics().has(ContentDatabase.get_clock_relic(id)), "Zenith relic must not enter generic rewards or shop")
		assert(ContentDatabase.all_clock_relics(true).has(ContentDatabase.get_clock_relic(id)), "Full catalog must include Zenith relic")
	await _capture("altar-before")
	assert(altar._offer_buttons.size() == 3, "All three Zenith offers must load")
	assert(RunManager.clock_inventory.size() == 12, "The starter inventory fills the clock")
	altar._open_purchase("REL-28")
	assert(altar._replacement_select.visible, "A full clock must require replacement")
	altar._replacement_select.select(1)
	altar._confirm_purchase()
	assert(OKRunState.current_ok == 55, "A 35-OK purchase must debit the run bank")
	assert(RunManager.clock_inventory.size() == 12, "A Zenith purchase must preserve the 12-copy cap")
	var found: bool = false
	for entry: Dictionary in RunManager.clock_inventory:
		if String(entry.id) == "REL-28":
			found = true
	assert(found, "The bought Zenith relic must enter the chronometer")
	altar._open_purchase("REL-29")
	assert(OKRunState.current_ok == 55, "Only one purchase is allowed at this altar")
	await get_tree().create_timer(0.25).timeout
	await _capture("altar-after")
	print("BOSS_ALTAR_OK: three offers, 12-copy replacement, exact currency debit, one purchase")
	get_tree().quit()


func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("user://boss-altar-test")
	get_viewport().get_texture().get_image().save_png("user://boss-altar-test/%s.png" % label)
