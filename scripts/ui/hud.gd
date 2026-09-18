class_name CombatHUD extends Control
## Zone D persistent stat bar (screen composition doc, Part 1.1/5): HP, Block,
## Energy, OK - always visible, fixed position. Binds directly to PlayerState
## signals and OKRunState signals; never caches its own copy of these values,
## per the data schema doc's anti-drift warning.

@onready var _hp_label: Label = %HPLabel
@onready var _block_label: Label = %BlockLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _ok_label: Label = %OKLabel
@onready var _hp_bar: TextureProgressBar = %HPBar
@onready var _hp_icon: TextureRect = $Row/HPIcon
@onready var _block_icon: TextureRect = $Row/BlockIcon
@onready var _energy_icon: TextureRect = $Row/EnergyIcon
@onready var _ok_icon: TextureRect = $Row/OKIcon

var _was_low_hp: bool = false
var _hp_bar_tween: Tween = null
var _prev_block: int = 0
var _prev_energy: int = -1


func _ready() -> void:
	OKRunState.ok_gained.connect(_on_ok_gained)
	_ok_label.text = str(OKRunState.current_ok)
	_load_icon_if_present(_hp_icon, "icon_hp")
	_load_icon_if_present(_block_icon, "icon_block")
	_load_icon_if_present(_energy_icon, "icon_energy")
	_load_icon_if_present(_ok_icon, "icon_overkill")
	_hp_icon.tooltip_text = "HP - lose it all and the run ends."
	_block_icon.tooltip_text = "Block - absorbs incoming damage this turn, then resets to 0."
	_energy_icon.tooltip_text = "Energy - spend it to play cards. Refills at the start of your turn."
	_ok_icon.tooltip_text = "Overkill (OK) - excess damage beyond a kill, banked as currency between fights."
	for icon in [_hp_icon, _block_icon, _energy_icon, _ok_icon]:
		icon.mouse_filter = Control.MOUSE_FILTER_STOP


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


## For non-combat screens (map, shop, rest, ...): HP/OK still apply and stay
## in their fixed position (screen composition doc Part 5's cross-screen
## consistency rule), but Block/Energy don't exist outside a fight - hidden
## rather than relocated or left showing stale numbers.
func bind_run_state() -> void:
	_block_icon.hide()
	_block_label.hide()
	_energy_icon.hide()
	_energy_label.hide()
	if not RunManager.hp_changed.is_connected(_on_hp_changed):
		RunManager.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(RunManager.current_hp, RunManager.max_hp)


func bind_clock_state(current: int, maximum: int) -> void:
	_ok_label.text = str(OKRunState.current_ok)
	_block_icon.hide()
	_block_label.hide()
	_energy_icon.hide()
	_energy_label.hide()
	if _hp_label.text != "%d/%d" % [maxi(current, 0), maximum]:
		_on_hp_changed(maxi(current, 0), maximum)


func _on_ok_gained(_amount: int, _source: String) -> void:
	_ok_label.text = str(OKRunState.current_ok)


func _on_hp_changed(current: int, max_hp: int) -> void:
	_hp_label.text = "%d/%d" % [current, max_hp]
	_hp_bar.max_value = max_hp
	# Bar fill always eases toward the new value instead of snapping - an
	# instant jump reads as a HUD glitch, not a hit landing or a heal.
	if _hp_bar_tween != null and _hp_bar_tween.is_valid():
		_hp_bar_tween.kill()
	_hp_bar_tween = create_tween()
	_hp_bar_tween.tween_property(_hp_bar, "value", current, 0.35).set_trans(Tween.TRANS_CUBIC)
	AmbientMotion.punch_scale(_hp_label, 1.25, 0.2)
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
	if current != _prev_block:
		AmbientMotion.punch_scale(_block_label, 1.3, 0.2)
		AmbientMotion.punch_scale(_block_icon, 1.25, 0.2)
	_prev_block = current


func _on_energy_changed(current: int, max_energy: int) -> void:
	_energy_label.text = "%d/%d" % [current, max_energy]
	if _prev_energy != -1 and current != _prev_energy:
		AmbientMotion.punch_scale(_energy_label, 1.3, 0.2)
	_prev_energy = current
