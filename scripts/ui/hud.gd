class_name CombatHUD extends Control
## Zone D persistent stat bar (screen composition doc, Part 1.1/5): HP, Block,
## Energy, OK - always visible, fixed position. Binds directly to PlayerState
## signals and OKRunState signals; never caches its own copy of these values,
## per the data schema doc's anti-drift warning.

@onready var _hp_label: Label = %HPLabel
@onready var _block_label: Label = %BlockLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _ok_label: Label = %OKLabel
@onready var _hp_icon: TextureRect = $Row/HPIcon
@onready var _block_icon: TextureRect = $Row/BlockIcon
@onready var _energy_icon: TextureRect = $Row/EnergyIcon
@onready var _ok_icon: TextureRect = $Row/OKIcon

var _was_low_hp: bool = false


func _ready() -> void:
	OKRunState.ok_gained.connect(_on_ok_gained)
	_ok_label.text = str(OKRunState.current_ok)
	_load_icon_if_present(_hp_icon, "icon_hp")
	_load_icon_if_present(_block_icon, "icon_block")
	_load_icon_if_present(_energy_icon, "icon_energy")
	_load_icon_if_present(_ok_icon, "icon_overkill")


func _load_icon_if_present(rect: TextureRect, icon_id: String) -> void:
	var path := "res://assets/icons/ui/%s.png" % icon_id
	if ResourceLoader.exists(path):
		rect.texture = ResourceLoader.load(path)


func bind_player(player: PlayerState) -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.block_changed.connect(_on_block_changed)
	player.energy_changed.connect(_on_energy_changed)
	_on_hp_changed(player.hp, player.max_hp)
	_on_block_changed(player.block)
	_on_energy_changed(player.energy, player.max_energy)


func _on_ok_gained(_amount: int, _source: String) -> void:
	_ok_label.text = str(OKRunState.current_ok)


func _on_hp_changed(current: int, max_hp: int) -> void:
	_hp_label.text = "%d/%d" % [current, max_hp]
	# Danger-state escalation (screen composition 1.3): only pulse on crossing
	# the 25% threshold, never on every subsequent point of damage below it.
	var is_low: bool = float(current) / float(max_hp) < 0.25
	if is_low and not _was_low_hp:
		_pulse_hp_danger()
	_was_low_hp = is_low


func _pulse_hp_danger() -> void:
	_hp_label.add_theme_color_override("font_color", Color("#E24B4A"))
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(_hp_label, "modulate:a", 0.4, 0.3)
	tween.tween_property(_hp_label, "modulate:a", 1.0, 0.3)


func _on_block_changed(current: int) -> void:
	_block_label.text = str(current)


func _on_energy_changed(current: int, max_energy: int) -> void:
	_energy_label.text = "%d/%d" % [current, max_energy]
