class_name UpgradePreviewDialog extends Control
## Rest-site upgrade confirmation (replaces the plain-text ModalConfirmDialog
## for this one flow): shows the card as it is now next to the card as it
## would become, with whatever line actually changes highlighted blue via
## CardView's compare_against parameter - "read the difference," never
## "trust the number changed somewhere." Free and one-card-per-visit is
## enforced by the caller (deck_view.gd), not here.

const SCENE_PATH := "res://scenes/upgrade_preview_dialog.tscn"
const CardViewScene := preload("res://scenes/card_view.tscn")

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


func _ready() -> void:
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
