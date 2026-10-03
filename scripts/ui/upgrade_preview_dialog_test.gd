extends Node
## Regression checks for modal dimming, relic preview sizing and action focus.

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)
	AudioManager.set_master_volume(0.0)
	var dialog: UpgradePreviewDialog = load("res://scenes/upgrade_preview_dialog.tscn").instantiate()
	add_child(dialog)
	var relic: ClockRelicData = ContentDatabase.get_clock_relic("REL-04")
	assert(relic != null, "The preview test relic must be registered")
	dialog._setup_relic(relic, relic)
	await get_tree().process_frame
	await get_tree().process_frame
	var background: Button = dialog.get_node("BackgroundButton")
	var dimmer: ColorRect = dialog.get_node("Dimmer")
	assert(is_zero_approx(background.self_modulate.a), "The click-catcher must not add a second visible veil")
	assert(dimmer.color.a <= 0.66, "The single veil should preserve the Forge backdrop")
	assert(dialog._current_slot.size.y == 370.0 and dialog._upgraded_slot.size.y == 370.0, "Relic comparison should use its intended collection height without excess blank space")
	for button: Button in [dialog._cancel_button, dialog._confirm_button]:
		assert(button.get_node_or_null("ActionableButtonFX") == null, "Modal actions must not stack custom contours over Godot focus outlines")
	var panel: Control = dialog.get_node("CenterContainer/Panel")
	var bounds: Rect2 = panel.get_global_rect()
	var viewport: Rect2 = get_viewport().get_visible_rect()
	assert(bounds.position.x >= viewport.position.x and bounds.position.y >= viewport.position.y and bounds.end.x <= viewport.end.x and bounds.end.y <= viewport.end.y, "Relic upgrade modal must stay inside the active canvas viewport: %s / %s" % [str(bounds), str(viewport)])
	dialog.queue_free()
	await get_tree().process_frame
	var confirmation: ModalConfirmDialog = ModalConfirmDialog.show_dialog(self, "Abandon this course? Your bound relics and saved route will be lost.", "ABANDON RUN", func() -> void: pass, true)
	await get_tree().process_frame
	assert(confirmation._cancel_button.get_node_or_null("ActionableButtonFX") == null and confirmation._confirm_button.get_node_or_null("ActionableButtonFX") == null, "Confirmation actions should use one focus outline")
	var confirmation_bounds: Rect2 = confirmation.get_node("CenterContainer/Panel").get_global_rect()
	assert(viewport.encloses(confirmation_bounds), "Confirmation content must remain inside the viewport")
	confirmation.queue_free()
	await get_tree().process_frame
	var reference: BattleReferenceOverlay = BattleReferenceOverlay.show_overlay(self, "THE CLOCK", "FIELD MANUAL", "A focused guide that keeps the battle visible.")
	await get_tree().process_frame
	assert((reference.get_node("Dim") as ColorRect).color.a <= 0.74, "The battle reference should dim without erasing the arena")
	assert(reference._close_button.get_node_or_null("ActionableButtonFX") == null, "Reference-overlay controls should use one focus outline")
	reference.queue_free()
	await get_tree().process_frame
	var treasure: TreasureScreen = load("res://scenes/treasure_screen.tscn").instantiate()
	treasure.set_reward_context({"ok_gain": 20})
	add_child(treasure)
	await get_tree().process_frame
	assert(treasure.get_node_or_null("TreasureDim") == null, "The cache reveal should not stack a full-screen veil over its own directional text shade")
	treasure.queue_free()
	await get_tree().process_frame
	print("UI_OVERLAYS_OK: readable single veils, no doubled focus contours, compact relic preview, centered bounds, protected artwork")
	get_tree().quit()
