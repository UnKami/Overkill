class_name UpgradePreviewDialog extends Control
## Rest-site upgrade confirmation (replaces the plain-text ModalConfirmDialog
## for this one flow): shows the card as it is now next to the card as it
## would become, with whatever line actually changes highlighted blue via
## CardView's compare_against parameter - "read the difference," never
## "trust the number changed somewhere." Free and one-card-per-visit is
## enforced by the caller (deck_view.gd), not here.

const SCENE_PATH := "res://scenes/upgrade_preview_dialog.tscn"
const CardViewScene := preload("res://scenes/card_view.tscn")
const RelicViewScene := preload("res://scenes/relic_pedestal_view.tscn")

signal confirmed()
signal cancelled()

@onready var _current_slot: Control = %CurrentSlot
@onready var _upgraded_slot: Control = %UpgradedSlot
@onready var _cancel_button: Button = %CancelButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _background_button: Button = %BackgroundButton
@onready var _no_change_label: Label = %NoChangeLabel


static func show_dialog(parent: Node, card: CardData, on_confirm: Callable) -> void:
	var scene: PackedScene = load(SCENE_PATH)
	var instance: UpgradePreviewDialog = scene.instantiate()
	parent.add_child(instance)
	instance.confirmed.connect(on_confirm)
	instance.confirmed.connect(instance.queue_free)
	instance.cancelled.connect(instance.queue_free)
	instance._setup(card)


static func show_relic_dialog(parent: Node, current: ClockRelicData, upgraded: ClockRelicData, on_confirm: Callable) -> void:
	var scene: PackedScene = load(SCENE_PATH)
	var instance: UpgradePreviewDialog = scene.instantiate()
	parent.add_child(instance)
	instance.confirmed.connect(on_confirm)
	instance.confirmed.connect(instance.queue_free)
	instance.cancelled.connect(instance.queue_free)
	instance._setup_relic(current, upgraded)


func _ready() -> void:
	ScreenDesign.polish(self)
	var panel: PanelContainer = get_node("CenterContainer/Panel")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("091520f8")
	panel_style.border_color = Color("80c8d18c")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.shadow_color = Color("000000dc")
	panel_style.shadow_size = 32
	panel_style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", panel_style)
	var stack: VBoxContainer = _cancel_button.get_parent().get_parent()
	var title: Label = stack.get_node("TitleLabel")
	title.text = "TEMPER THIS MEMORY?"
	title.add_theme_font_size_override("font_size", 32)
	var kicker := ScreenDesign.label(stack, "BEFORE  /  AFTER", 14, ScreenDesign.CYAN)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.move_child(kicker, 0)
	var rule := ScreenDesign.rule(stack, ScreenDesign.GOLD)
	stack.move_child(rule, title.get_index() + 1)
	_cancel_button.text = "CANCEL"
	_confirm_button.text = "TEMPER MEMORY"
	_cancel_button.custom_minimum_size = Vector2(220, 56)
	_confirm_button.custom_minimum_size = Vector2(220, 56)
	_cancel_button.pressed.connect(func() -> void: cancelled.emit())
	_confirm_button.pressed.connect(func() -> void: confirmed.emit())
	_background_button.pressed.connect(func() -> void: cancelled.emit())


func _setup(card: CardData) -> void:
	var current_view := CardViewScene.instantiate()
	_current_slot.add_child(current_view)
	current_view.set_card(card)
	current_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var upgraded: CardData = card.duplicate(false)
	upgraded.upgrade_level = 1
	var has_upgrade_data: bool = not upgraded.upgraded_effects.is_empty()

	var upgraded_view := CardViewScene.instantiate()
	_upgraded_slot.add_child(upgraded_view)
	upgraded_view.set_card(upgraded, card)
	upgraded_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Defensive: if a card somehow has no upgraded_effects authored yet,
	# say so plainly and block the confirm instead of upgrading it into a
	# silent no-op (the exact bug this whole dialog exists to prevent).
	_no_change_label.visible = not has_upgrade_data
	_confirm_button.disabled = not has_upgrade_data


func _setup_relic(current: ClockRelicData, upgraded: ClockRelicData) -> void:
	var title: Label = get_node("CenterContainer/Panel/Margin/VBox/TitleLabel")
	title.text = "TEMPER THIS RELIC?"
	get_node("CenterContainer/Panel/Margin/VBox/CardsRow/CurrentColumn/CurrentLabel").text = "BOUND FORM"
	get_node("CenterContainer/Panel/Margin/VBox/CardsRow/UpgradedColumn/UpgradedLabel").text = "TEMPERED FORM"
	_confirm_button.text = "TEMPER RELIC"
	# Relic cards retain a taller natural rect than card memories. Give the
	# comparison row that full height so the action buttons never cover stats.
	_current_slot.custom_minimum_size = Vector2(272, 440)
	_upgraded_slot.custom_minimum_size = Vector2(272, 440)
	var current_view: RelicPedestalView = RelicViewScene.instantiate()
	_current_slot.add_child(current_view)
	current_view.use_collection_layout()
	current_view.bind_relic(current, "")
	current_view.size = Vector2(272, 440)
	current_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var upgraded_view: RelicPedestalView = RelicViewScene.instantiate()
	_upgraded_slot.add_child(upgraded_view)
	upgraded_view.use_collection_layout()
	upgraded_view.bind_relic(upgraded, "")
	upgraded_view.size = Vector2(272, 440)
	upgraded_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_no_change_label.hide()
