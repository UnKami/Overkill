extends Control
## Direct entry into the playable first 3D encounter; launcher isolates its save profile.
var _battle: CombatController
var _result: Control
@export var enemy_id: String = "act1_boss"
@export var victory_title: String = "THE SENTINEL FALLS"

func _ready() -> void:
	_start()

func _start() -> void:
	if is_instance_valid(_result): _result.queue_free()
	if is_instance_valid(_battle):
		remove_child(_battle)
		_battle.queue_free()
	RunManager.start_new_run([],[],80,1729)
	_battle = preload("res://scenes/combat_scene.tscn").instantiate()
	add_child(_battle)
	_battle.combat_won.connect(func(_enemies: Array[EnemyData]) -> void: _finished(true))
	_battle.combat_lost.connect(func() -> void: _finished(false))
	_battle.start_combat([ContentDatabase.get_enemy(enemy_id)])

func _finished(won: bool) -> void:
	_result = Control.new()
	add_child(_result)
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.z_index = 100
	var layout := VBoxContainer.new()
	_result.add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layout.position -= Vector2(320,140)
	layout.custom_minimum_size = Vector2(640,280)
	layout.add_theme_constant_override("separation",24)
	var title := Label.new()
	title.text = victory_title if won else "THE CLOCK FALLS SILENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("dfbc80"))
	layout.add_child(title)
	var again := Button.new()
	again.text = "Fight again"
	again.custom_minimum_size.y = 56
	layout.add_child(again)
	again.pressed.connect(_start)
	again.grab_focus()
	var menu := Button.new()
	menu.text = "Main menu"
	menu.custom_minimum_size.y = 56
	layout.add_child(menu)
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
