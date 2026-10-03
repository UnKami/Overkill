extends Node
## Focused regression for the Zenith full-clock purchase/replacement flow.

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	AudioManager.set_master_volume(0.0)
	RunManager.start_new_run([], [], 500, 41041)
	while RunManager.clock_inventory.size() < ClockInventory.MAX_SIZE:
		assert(RunManager.add_clock_relic("REL-01"))
	OKRunState.current_ok = 100
	var altar: BossOverkillAltar = load("res://scenes/boss_overkill_altar.tscn").instantiate()
	add_child(altar)
	await get_tree().process_frame
	assert(altar._main_panel.visible and not altar._modal.visible)
	altar._open_purchase("REL-29")
	await get_tree().process_frame
	assert(not altar._main_panel.visible and altar._modal.visible, "Purchase flow must replace the altar instead of stacking over it")
	assert(altar._replacement_scroll.visible, "A full chronometer must show the dedicated replacement chooser")
	assert(altar._replacement_grid.get_child_count() == ClockInventory.MAX_SIZE, "Each owned relic copy needs its own replacement choice")
	assert(altar.find_children("*", "OptionButton", true, false).is_empty(), "Zenith replacement must not use a native dropdown")
	var identities: Dictionary = {}
	for choice: Button in altar._replacement_grid.get_children():
		var identity: String = choice.text.get_slice("\n", 1)
		assert(not identities.has(identity), "Replacement choices must identify unique physical copies")
		identities[identity] = true
	assert(identities.size() == ClockInventory.MAX_SIZE)
	var first_choice: Button = altar._replacement_grid.get_child(0) as Button
	var selected_uid: int = int(first_choice.get_meta("replacement_uid"))
	first_choice.pressed.emit()
	assert(altar._selected_replacement_uid == selected_uid and not altar._confirm_button.disabled)
	assert(altar._selection_label.text.contains("COPY #"), "The selected loss must be visible before spending")
	var rect: Rect2 = altar._modal.get_global_rect()
	assert(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= 1920.0 and rect.end.y <= 1080.0, "Wide replacement screen must remain inside the viewport")
	altar._cancel_purchase()
	assert(altar._main_panel.visible and not altar._modal.visible, "Returning to the altar must restore one screen only")
	RunManager.clock_inventory.remove_at(RunManager.clock_inventory.size() - 1)
	altar._open_purchase("REL-29")
	assert(not altar._main_panel.visible and altar._modal.visible and not altar._replacement_scroll.visible, "An open clock gets a focused bind-confirmation screen without an overlapping altar")
	altar._cancel_purchase()
	print("ZENITH_REPLACEMENT_OK: exclusive purchase/replacement screens, twelve individual targets, explicit selected loss, centered bounds")
	get_tree().quit()
