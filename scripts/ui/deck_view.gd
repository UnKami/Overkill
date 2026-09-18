extends Control
## DeckView - one reusable "browse your deck" component with a mode flag that
## changes only the action verb on tap (deck-view screen doc's core design
## decision), not four separate screens. GameFlow owns the single instance
## lifecycle via open_deck_view(mode)/close_deck_view() as an overlay - this
## never pauses the tree itself (only the pause menu does).

const CardViewScene := preload("res://scenes/card_view.tscn")

@onready var _grid: GridContainer = %CardGrid
@onready var _count_label: Label = %CountLabel
@onready var _close_button: Button = %CloseButton
@onready var _mode_label: Label = %ModeLabel
@onready var _upgrade_only_check: CheckBox = %UpgradeOnlyCheck

var _mode: int = GameFlow.DeckViewMode.REFERENCE
var _pile_filter: Array[CardData] = []
var _card_to_instance_id: Dictionary = {}  # CardData (object identity) -> int


func _ready() -> void:
	_close_button.pressed.connect(func() -> void: GameFlow.close_deck_view())
	_upgrade_only_check.toggled.connect(func(_pressed: bool) -> void: _refresh())
	RunManager.deck_changed.connect(func(_deck: Array) -> void: _refresh())


func set_mode(mode: int, pile_filter: Array = []) -> void:
	_mode = mode
	_pile_filter.assign(pile_filter)
	_upgrade_only_check.visible = mode == GameFlow.DeckViewMode.UPGRADE
	match mode:
		GameFlow.DeckViewMode.UPGRADE:
			_mode_label.text = "Upgrade a Card"
		GameFlow.DeckViewMode.REMOVAL:
			_mode_label.text = "Remove a Card"
		GameFlow.DeckViewMode.PILE_VIEW:
			_mode_label.text = "Viewing Pile"
		_:
			_mode_label.text = "Your Deck"
	_refresh()


func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_card_to_instance_id.clear()

	var cards_to_show: Array[CardData] = []
	if _mode == GameFlow.DeckViewMode.PILE_VIEW:
		cards_to_show = _pile_filter
	else:
		for entry in RunManager.deck:
			var source := RunManager.resolve_card(entry)
			if source == null:
				continue
			var copy: CardData = source.duplicate(false)
			copy.upgrade_level = entry.upgrade_level
			cards_to_show.append(copy)
			_card_to_instance_id[copy] = entry.instance_id

	_count_label.text = "%d cards" % cards_to_show.size()

	for card in cards_to_show:
		var view := CardViewScene.instantiate()
		_grid.add_child(view)
		view.set_card(card)
		var eligible := _is_eligible(card)
		view.modulate = Color(1, 1, 1, 1.0) if eligible else Color(1, 1, 1, 0.45)
		if _mode == GameFlow.DeckViewMode.UPGRADE and _upgrade_only_check.button_pressed and not eligible:
			view.hide()
		if _mode in [GameFlow.DeckViewMode.UPGRADE, GameFlow.DeckViewMode.REMOVAL] and eligible:
			view.pressed.connect(_on_actionable_card_pressed)


func _is_eligible(card: CardData) -> bool:
	if _mode == GameFlow.DeckViewMode.UPGRADE:
		return card.upgrade_level <= 0
	if _mode == GameFlow.DeckViewMode.REMOVAL:
		return true
	return true


func _on_actionable_card_pressed(card: CardData) -> void:
	var instance_id: int = _card_to_instance_id.get(card, -1)
	if instance_id == -1:
		return
	if _mode == GameFlow.DeckViewMode.UPGRADE:
		# Free and one-per-visit (rest-site doc): the cost is that resting was
		# the alternative you gave up, not an additional OK price on top.
		UpgradePreviewDialog.show_dialog(self, card, func() -> void: _do_upgrade(instance_id, card))
	elif _mode == GameFlow.DeckViewMode.REMOVAL:
		var price := RunManager.price_for("removal", 75)
		ModalConfirmDialog.show_dialog(
			self,
			"Remove [b]%s[/b] from your deck for %d OK? This cannot be undone." % [card.display_name, price],
			"Remove",
			func() -> void: _do_removal(instance_id, price),
			true
		)


## Free (rest-site doc: the cost is giving up Rest, not an OK price on top)
## and exactly one card per visit - closes the whole deck-view overlay right
## after, rather than leaving it open to upgrade a second card. Rest-site
## screen's own one-shot listener on RunManager.deck_changed (set up when it
## opened this) marks itself resolved from the same signal this fires.
func _do_upgrade(instance_id: int, card: CardData) -> void:
	RunManager.apply_card_upgrade(instance_id)
	TutorialCallout.trigger("first_rest_upgrade")
	if _mode == GameFlow.DeckViewMode.UPGRADE:
		GameFlow.close_deck_view()


func _do_removal(instance_id: int, price: int) -> void:
	if not OKRunState.spend_ok(price, "card_removal"):
		return
	RunManager.remove_card_from_deck(instance_id)
	RunManager.record_purchase("removal")
