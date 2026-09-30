class_name TreasureScreen extends Control
## Dedicated, cinematic reveal for the map's sealed-cache destination.
## Rewards are granted by the map when the node is committed; this screen is
## presentation/acknowledgement only and never grants them a second time.

var _ok_gain: int = 0
var _found_relic: RelicData


func set_reward_context(context: Dictionary) -> void:
	_ok_gain = int(context.get("ok_gain", 0))
	_found_relic = context.get("relic", null) as RelicData


func _ready() -> void:
	theme = ScreenDesign.build_theme()
	_build_backdrop()
	_build_reveal()
	ScreenDesign.polish(self)
	if not AudioManager.reduced_motion:
		var reveal := create_tween().set_parallel(true)
		for node: CanvasItem in find_children("TreasureReveal*", "Control", true, false):
			node.modulate.a = 0.0
			reveal.tween_property(node, "modulate:a", 1.0, 0.46).set_delay(0.08)
	else:
		for node: CanvasItem in find_children("TreasureReveal*", "Control", true, false):
			node.modulate.a = 1.0


func _build_backdrop() -> void:
	var art := TextureRect.new()
	art.name = "TreasureBackgroundArt"
	art.texture = load(CinematicArt.RELIC_REWARD)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(0.9, 0.92, 0.92)
	add_child(art)
	move_child(art, 1)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AmbientMotion.apply_cinematic_backdrop(self, art, 20.0, 0.52)

	var dim := ColorRect.new()
	dim.name = "TreasureDim"
	dim.color = Color("03080eb0")
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ScreenDesign.shade(self)


func _build_reveal() -> void:
	var kicker := _label("TreasureRevealKicker", "THE ASCENT  ·  ACT %02d" % RunManager.act_number, 16, ScreenDesign.CYAN)
	kicker.position = Vector2(72.0, 94.0)
	kicker.size = Vector2(620.0, 28.0)

	var title := _label("TreasureRevealTitle", "THE SEALED\nCACHE OPENS", 54, Color("f0dfbf"), true)
	title.position = Vector2(68.0, 132.0)
	title.size = Vector2(640.0, 160.0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_outline_color", Color("071019e8"))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_shadow_color", Color("000000d0"))
	title.add_theme_constant_override("shadow_offset_y", 4)

	var rule := ColorRect.new()
	rule.color = Color(ScreenDesign.GOLD, 0.72)
	rule.position = Vector2(74.0, 306.0)
	rule.size = Vector2(460.0, 1.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)

	var reward_title := _label("TreasureRevealCurrencyLabel", "RECOVERED OVERKILL", 14, ScreenDesign.MUTED)
	reward_title.position = Vector2(74.0, 330.0)
	reward_title.size = Vector2(420.0, 24.0)
	var reward_amount := _label("TreasureRevealCurrencyAmount", "+%d" % _ok_gain, 46, Color("cf5e5b"), true)
	reward_amount.position = Vector2(70.0, 354.0)
	reward_amount.size = Vector2(205.0, 62.0)
	var reward_unit := _label("TreasureRevealCurrencyUnit", "OVERKILL", 15, Color("e8ccc2"))
	reward_unit.position = Vector2(222.0, 378.0)
	reward_unit.size = Vector2(180.0, 32.0)

	if _found_relic != null:
		_add_relic_reveal()
	else:
		var empty_note := _label("TreasureRevealNoRelic", "No relic remained in the sealed compartment.", 16, ScreenDesign.MUTED)
		empty_note.position = Vector2(74.0, 430.0)
		empty_note.size = Vector2(520.0, 52.0)
		empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var button := Button.new()
	button.name = "TreasureRevealContinue"
	button.text = "RETURN TO THE ASCENT"
	button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	button.position = Vector2(70.0, -122.0)
	button.custom_minimum_size = Vector2(390.0, 56.0)
	button.add_theme_stylebox_override("normal", ScreenDesign.box(Color("3d3428e8"), ScreenDesign.GOLD))
	button.add_theme_stylebox_override("hover", ScreenDesign.box(Color("554732f2"), Color("f2d8a4")))
	button.pressed.connect(GameFlow.goto_map)
	add_child(button)
	button.grab_focus()

	var note := _label("TreasureRevealFooter", "THE CACHE HAS BEEN ADDED TO YOUR RUN", 12, Color("c6c6c0"))
	note.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	note.position = Vector2(74.0, -54.0)
	note.size = Vector2(430.0, 20.0)


func _add_relic_reveal() -> void:
	var object_art := TextureRect.new()
	object_art.name = "TreasureRevealRelicArt"
	object_art.texture = RelicArt.load_texture(_found_relic.art_id)
	object_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	object_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	object_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	object_art.position = Vector2(70.0, 426.0)
	object_art.size = Vector2(236.0, 236.0)
	object_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(object_art)
	var item_label := _label("TreasureRevealRelicLabel", "RELIC RECOVERED", 13, ScreenDesign.CYAN)
	item_label.position = Vector2(320.0, 444.0)
	item_label.size = Vector2(340.0, 20.0)
	var item_name := _label("TreasureRevealRelicName", _found_relic.display_name, 25, ScreenDesign.GOLD, true)
	item_name.position = Vector2(318.0, 468.0)
	item_name.size = Vector2(390.0, 62.0)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var item_description := _label("TreasureRevealRelicDescription", _describe_relic(_found_relic), 15, ScreenDesign.TEXT)
	item_description.position = Vector2(320.0, 526.0)
	item_description.size = Vector2(430.0, 86.0)
	item_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _describe_relic(relic: RelicData) -> String:
	var sentences: PackedStringArray = []
	match relic.trigger:
		RelicData.Trigger.ON_OVERKILL:
			var threshold: int = int(relic.condition_data.get("min_ok", 0))
			sentences.append("Triggers when you Overkill by %d or more." % threshold if threshold > 0 else "Triggers whenever you Overkill.")
		RelicData.Trigger.ON_KILL:
			sentences.append("Triggers when you defeat an enemy.")
		RelicData.Trigger.ON_TURN_START:
			sentences.append("Triggers at the start of your turn.")
		RelicData.Trigger.ON_TURN_END:
			sentences.append("Triggers at the end of your turn.")
		RelicData.Trigger.ON_COMBAT_START:
			sentences.append("Triggers at the start of battle.")
		RelicData.Trigger.ON_CARD_PLAYED:
			sentences.append("Triggers when a card is played.")
		_:
			sentences.append("Always active.")
	for effect: EffectData in relic.effects:
		match effect.effect_type:
			EffectData.EffectType.DAMAGE:
				sentences.append("Deal %d damage." % effect.value)
			EffectData.EffectType.BLOCK:
				sentences.append("Gain %d Block." % effect.value)
			EffectData.EffectType.GAIN_OK:
				sentences.append("Gain %d Overkill." % effect.value)
			EffectData.EffectType.DRAW:
				sentences.append("Draw %d card(s)." % effect.value)
			EffectData.EffectType.ENERGY_GAIN:
				sentences.append("Gain %d energy." % effect.value)
	if not relic.flavor_text.is_empty():
		sentences.append(relic.flavor_text)
	return " ".join(sentences)


func _label(node_name: String, value: String, font_size: int, color: Color, display: bool = false) -> Label:
	var label := ScreenDesign.label(self, value, font_size, color, display)
	label.name = node_name
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
