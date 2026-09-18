extends Control
## Shop screen (screen composition doc 4.2, balance doc pricing table): zoned
## by category, prices via RunManager.price_for(), unaffordable items dimmed
## (same treatment as everywhere else unplayable/ineligible state is shown).
## Locked Excess-tier cards sit in their normal position with a lock +
## requirement-text treatment, per the icon-system doc, rather than being
## segregated out of the list.

const CARD_BUY_BASE_PRICE := {
	CardData.Rarity.COMMON: 20,
	CardData.Rarity.UNCOMMON: 35,
	CardData.Rarity.RARE: 55,
	CardData.Rarity.EXCESS: 80,
}
const RELIC_BASE_PRICE := 200
const REMOVAL_BASE_PRICE := 75
const CARDS_OFFERED := 4
const RELICS_OFFERED := 2

const CardViewScene := preload("res://scenes/card_view.tscn")

@onready var _hud: CombatHUD = %HUD
@onready var _card_row: HBoxContainer = %CardRow
@onready var _relic_row: HBoxContainer = %RelicRow
@onready var _remove_button: Button = %RemoveButton
@onready var _back_button: Button = %BackButton
@onready var _background: TextureRect = %Background

var _offered_cards: Array[CardData] = []
var _offered_relics: Array[RelicData] = []


func _ready() -> void:
	_hud.bind_run_state()
	_back_button.pressed.connect(func() -> void: GameFlow.goto_map())
	_remove_button.pressed.connect(func() -> void: GameFlow.open_deck_view(GameFlow.DeckViewMode.REMOVAL))
	_roll_inventory()
	_rebuild()
	_load_background()
	AmbientMotion.spawn_embers(self, Color(0.85, 0.85, 0.92, 0.4), 10, true)


func _load_background() -> void:
	var path := "res://assets/screens/shop_bg.jpg"
	if ResourceLoader.exists(path):
		_background.texture = ResourceLoader.load(path)
		AmbientMotion.apply_ken_burns(_background, 40.0, 0.025)


func _roll_inventory() -> void:
	var pool: Array = ContentDatabase.all_cards().duplicate()
	pool.shuffle()
	_offered_cards.assign(pool.slice(0, min(CARDS_OFFERED, pool.size())))

	var relic_pool: Array = []
	for relic in ContentDatabase.all_relics():
		if not RunManager.has_relic(relic.id):
			relic_pool.append(relic)
	relic_pool.shuffle()
	_offered_relics.assign(relic_pool.slice(0, min(RELICS_OFFERED, relic_pool.size())))


func _rebuild() -> void:
	for child in _card_row.get_children():
		child.queue_free()
	for child in _relic_row.get_children():
		child.queue_free()

	for card in _offered_cards:
		_build_card_offer(card, _card_row)
	for relic in _offered_relics:
		_relic_row.add_child(_build_relic_offer(relic))


## `condition_data`-style auto-rendered lock text (data schema doc 2.4's
## rule applied to gates, not just relic tooltips) - never hand-write a
## requirement string that could drift from what excess_gate_type actually
## checks.
func _gate_requirement_text(card: CardData) -> String:
	if card.excess_gate_type == CardData.ExcessGateType.TURN_TOTAL_OK:
		return "requires %d+ total OK in one turn" % card.excess_gate_threshold
	return "requires %d+ OK in one hit" % card.excess_gate_threshold


## Cards render through the same CardView every other screen uses (hand,
## reward, deck view) - a shop offer must look like the actual card the
## player would get, never a plain name+button placeholder.
##
## Takes the target row directly and adds itself immediately, BEFORE
## building the CardView's contents - set_card() relies on the view's
## @onready vars, which only resolve once the node is actually inside the
## SceneTree. Calling set_card() while box was still a disconnected,
## not-yet-parented VBoxContainer crashed with every field null (confirmed
## via headless testing) - same failure class reward_screen.gd hit earlier.
func _build_card_offer(card: CardData, target_row: HBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	target_row.add_child(box)

	var view := CardViewScene.instantiate()
	box.add_child(view)
	view.set_card(card)
	# Deliberately left clickable/hoverable (default mouse_filter) so the
	# hover grow+glow still works here for a closer look - nothing is
	# connected to its `pressed` signal in a shop, so a click is a safe no-op.

	var locked: bool = not OKRunState.is_card_unlocked(card)
	if locked:
		TutorialCallout.trigger("first_excess_gate")
		view.modulate = Color(0.45, 0.45, 0.45)
		var lock_label := Label.new()
		lock_label.text = "LOCKED\n%s" % _gate_requirement_text(card)
		lock_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		lock_label.custom_minimum_size = Vector2(240, 0)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_color_override("font_color", Color("#9C4FDD"))
		box.add_child(lock_label)
		return

	var price := RunManager.price_for("buy_%s" % CardData.Rarity.keys()[card.rarity].to_lower(), CARD_BUY_BASE_PRICE.get(card.rarity, 20))
	var buy_button := Button.new()
	buy_button.text = "Buy - %d OK" % price
	buy_button.disabled = price > OKRunState.current_ok
	buy_button.tooltip_text = "Add this card to your deck for %d OK." % price
	buy_button.pressed.connect(func() -> void: _buy_card(card, price))
	box.add_child(buy_button)


func _build_relic_offer(relic: RelicData) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := RelicIcon.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	icon.relic = relic

	var name_label := Label.new()
	name_label.text = relic.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	var price := RunManager.price_for("relic", RELIC_BASE_PRICE)
	var buy_button := Button.new()
	buy_button.text = "Buy - %d OK" % price
	buy_button.disabled = price > OKRunState.current_ok
	buy_button.tooltip_text = "Add this relic for %d OK." % price
	buy_button.pressed.connect(func() -> void: _buy_relic(relic, price))
	box.add_child(buy_button)
	return box


func _buy_card(card: CardData, price: int) -> void:
	if not OKRunState.spend_ok(price, "shop_card"):
		return
	RunManager.add_card_to_deck(card)
	RunManager.record_purchase("buy_%s" % CardData.Rarity.keys()[card.rarity].to_lower())
	_offered_cards.erase(card)
	_rebuild()
	SaveManager.save_run()


func _buy_relic(relic: RelicData, price: int) -> void:
	if not OKRunState.spend_ok(price, "shop_relic"):
		return
	RunManager.add_relic(relic)
	RunManager.record_purchase("relic")
	_offered_relics.erase(relic)
	_rebuild()
	SaveManager.save_run()
