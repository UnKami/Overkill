extends Node
## Disposable-profile checks of production forge and battle code.
var battle: CombatController
var _active: bool = false
var _errors: int = 0
var _checks: int = 0
var _resolved: int = 0
var _capture: bool = false
var _captured: Dictionary = {}
var _output: String = "res://.test-artifacts/046/feedback"

func _ready() -> void:
	if not QAProfileGuard.require_isolated(self): return
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280,720)
	AudioManager.set_master_volume(0.0)
	AudioManager.fast_mode = false
	_capture = OS.get_cmdline_user_args().has("--capture-feedback") and DisplayServer.get_name() != "headless"
	RunManager.start_new_run([],[],60,46046)
	await _test_forge()
	battle = load("res://scenes/combat_scene.tscn").instantiate()
	add_child(battle)
	var enemy: EnemyData = ContentDatabase.get_enemy("boneghoul").duplicate(true)
	enemy.max_hp = 100
	battle.start_combat([enemy])
	await get_tree().create_timer(1.5).timeout
	await _test_statuses()
	await _test_twin()
	AudioManager.fast_mode = true
	for fixture: Array in [[3,100,40,0,0,0,3],[100,100,40,0,0,0,0],[0,2,40,0,0,0,2],[0,100,59,0,0,0,1],[3,100,40,3,0,0,6],[0,100,40,0,1,1,6],[0,100,40,0,0,0,6]]:
		await _test_siphon(fixture)
	AudioManager.reduced_motion = true
	await _test_siphon([3,100,40,0,0,0,3])
	AudioManager.reduced_motion = false
	await _test_thorns_order()
	battle.queue_free()
	await get_tree().process_frame
	print("RELIC_FEEDBACK_OK checks=%d errors=%d forge, independent melee contacts, persistent reactive statuses, capped lifesteal, transfer timing and thorns ordering" % [_checks,_errors])
	get_tree().quit(0 if _errors == 0 else 1)

func _expect(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_errors += 1
		push_error(message)

func _test_forge() -> void:
	var forge: ClockCollectionScreen = ClockCollectionScreen.new()
	forge.mode = "upgrade"
	forge.pre_battle = true
	forge.resolved.connect(func() -> void: _resolved += 1)
	add_child(forge)
	await get_tree().process_frame
	await get_tree().process_frame
	forge._inventory_scroll.scroll_vertical = 100
	var scroll: int = forge._inventory_scroll.scroll_vertical
	var uid: int = int(RunManager.clock_inventory[0].uid)
	forge._choose(uid)
	_expect(forge._upgrade_preview != null,"Upgrade comparison is available")
	await _shot("forge-comparison")
	forge._upgrade_preview._on_confirm_pressed()
	await get_tree().create_timer(2.8).timeout
	_expect(is_instance_valid(forge) and forge.is_inside_tree() and _resolved == 0,"Upgrading stays in the forge")
	_expect(forge._upgrade_preview == null,"Animation automatically returns to browsing")
	_expect(int(RunManager.clock_inventory[0].level) == 1,"Selected saved copy upgraded")
	_expect(forge._inventory_scroll.scroll_vertical == scroll,"Scroll position preserved")
	_expect((forge._grid.get_child(0) as RelicPedestalView).relic.name.ends_with("+"),"Upgraded form immediately visible")
	await _shot("forge-after-upgrade")
	var before: Array = RunManager.clock_inventory.duplicate(true)
	forge._choose(int(RunManager.clock_inventory[1].uid))
	_expect(is_instance_valid(forge._upgrade_preview),"Other copies remain inspectable")
	_expect(forge._upgrade_preview._confirm_button.disabled,"Spent visit allowance cannot grant another free upgrade")
	forge._commit_upgrade(int(RunManager.clock_inventory[1].uid))
	_expect(RunManager.clock_inventory == before,"Duplicate confirmation cannot spend another upgrade")
	forge._upgrade_preview.cancelled.emit()
	await get_tree().process_frame
	forge._close()
	_expect(_resolved == 1,"Separate journey action resolves exactly once")
	forge.queue_free()
	await get_tree().process_frame

func _test_statuses() -> void:
	_reset()
	battle.player_strength = 3
	battle.player_block = 10
	battle._update_stats_display()
	var strength: Control = battle._player_status_strip.get_node("Strength")
	var block: Control = battle._player_core_strip.get_node("Block")
	var strength_id: int = strength.get_instance_id()
	var block_id: int = block.get_instance_id()
	_expect(strength.get_meta("gain_count",0) == 1,"Strength gain reacts")
	_expect(block.get_meta("gain_count",0) >= 1,"Block gain reacts")
	var icon: TextureRect = strength.get_child(0)
	_expect(icon.custom_minimum_size.x >= 30,"Status symbol is readable")
	_expect((icon.material as ShaderMaterial).get_shader_parameter("status_color") == Color("b76cff"),"Strength symbol uses purple")
	for redraw: int in 20: battle._update_stats_display()
	_expect(strength.get_instance_id() == strength_id and block.get_instance_id() == block_id,"Redraw preserves status nodes and active animation")
	_expect(strength.get_meta("gain_count",0) == 1,"Unchanged status never retriggers gain")
	battle.player_strength = 4
	battle._update_stats_display()
	_expect(strength.get_meta("gain_count",0) == 2,"Increasing stacks reacts again")
	await get_tree().create_timer(.15).timeout
	await _shot("strength-block-purple")
	battle.player_strength = 0
	battle._update_stats_display()
	await get_tree().process_frame
	battle.player_strength = 1
	battle._update_stats_display()
	_expect(battle._player_status_strip.get_node("Strength").get_meta("gain_count",0) == 1,"Reacquiring a removed status reacts")

func _test_twin() -> void:
	_reset()
	battle.enemy_block = 2
	var relic: ClockRelicData = ContentDatabase.get_clock_relic("REL-02")
	battle.player_sockets[0].slotted_relic = relic
	_expect(AttackPresentation.for_relic_hit(relic,0).rig_action == "twin_right","First strike uses right-handed melee")
	_expect(AttackPresentation.for_relic_hit(relic,1).rig_action == "twin_left","Second strike uses left-handed melee")
	_active = true
	_run_tick()
	var cue: RelicChoreography
	var first_hp: int = 100
	var hits: int = 0
	while _active:
		await get_tree().process_frame
		var cues: Array[Node] = battle.find_children("RelicChoreography_REL_02","",true,false)
		if not cues.is_empty():
			var current: RelicChoreography = cues[0]
			if cue == null:
				cue = current
				_expect(cue._relic_skeleton.get_bone_count() == 6,"Relic has the actual six-bone runtime skeleton")
				_expect(cue._native_view != null and cue._native_view.skeleton.get_bone_count() == 6,"Twin Blades has an imported 3D prop skeleton")
			_expect(current == cue,"Both hits retain the same dual-wield prop")
			if current._clock > 1.6 and current._clock < 2.05:
				_expect(current._prop.position.distance_to(current.to_local(battle._stage.player.anchor_position("hand_near"))) < 1.0,"Right weapon is bound to its hand")
				_expect(current._extra.position.distance_to(current.to_local(battle._stage.player.anchor_position("hand_far"))) < 1.0,"Left weapon is bound to its hand")
				_expect(current._extra.get_child_count() == 1,"Left hand holds one Iron Strike sword")
				var native: Relic3DView = current._native_view
				var actor: Executioner3DActor = battle._stage.player as Executioner3DActor
				for side: String in ["R","L"]:
					var bone: int = native.skeleton.find_bone("prop" if side=="R" else "secondary")
					var at: Vector3 = native.skeleton.get_bone_global_pose(bone).origin
					_expect(at.distance_to(actor.grip_world(side).origin)<.0001,"3D sword hilt stays inside the articulated palm")
				await _shot("twin-"+str(current._clip.actor_action)+"-windup")
		if battle.enemy_hp != first_hp:
			hits += 1
			_expect(is_instance_valid(cue) and cue._clock >= float(cue._clip.contact),"Damage occurs at sword contact")
			_expect(battle.enemy_hp == (98 if hits == 1 else 94),"Each sword independently resolves Block and HP damage")
			first_hp = battle.enemy_hp
			await _shot("twin-hit-"+str(hits))
	_expect(hits == 2 and battle.enemy_hp == 94,"Twin Blades resolves exactly two unchanged 4-damage hits")
	await get_tree().create_timer(.85).timeout
	_expect(battle._twin_relic_motion == null,"Combo releases retained prop")

func _test_siphon(fixture: Array) -> void:
	_reset()
	battle.enemy_block = int(fixture[0])
	battle.enemy_hp = int(fixture[1])
	battle.player_hp = int(fixture[2])
	battle.player_strength = int(fixture[3])
	battle.player_weak = int(fixture[4])
	battle.enemy_vulnerable = int(fixture[5])
	battle._update_stats_display()
	var relic: ClockRelicData = ClockInventory.resolve({"id":"REL-13","uid":99,"level":1})
	battle.player_sockets[0].slotted_relic = relic
	_expect(relic.base_damage == 6,"Upgraded Siphon damage stays six")
	_active = true
	_run_tick()
	var saw_transit: bool = false
	var delivered: bool = false
	while _active:
		await get_tree().process_frame
		var cues: Array[Node] = battle.find_children("RelicChoreography_REL_13","",true,false)
		if not cues.is_empty():
			var cue: RelicChoreography = cues[0]
			if cue._resolved and cue._clock < float(cue._clip.transfer_end) and int(fixture[6]) > 0:
				saw_transit = true
				_expect(battle._pending_lifesteal_visual == int(fixture[6]),"Healing presentation waits for energy arrival")
				_expect(not _has_heal(),"No premature heal number")
				if cue._clock > 2.2:
					_expect(cue._native_view != null and cue._native_view._tube.visible,"Live Siphon uses the 3D purple hose")
					_expect(cue._native_view._tube.mesh.get_surface_count() == 1,"Life conduit has actual tube geometry")
					_expect(cue._native_view._life_orb.visible,"Life mass is a visible 3D object")
					var tube: PackedVector2Array = cue._siphon_tube.polygon
					var width: float = 0.0
					for index: int in 25: width = maxf(width,tube[index].distance_to(tube[49-index]))
					_expect(width > 40.0,"Purple conduit bulges around life mass")
					await _shot("siphon-single-green-orb")
			if cue._transfer_delivered:
				delivered = true
				if _has_heal(): await _shot("siphon-heal-at-arrival")
	_expect(battle.player_hp == int(fixture[2])+int(fixture[6]),"Healing equals actual enemy HP damage capped at missing HP: "+str(fixture))
	_expect(battle._pending_lifesteal_visual == 0,"Healing presentation finishes without pending state")
	if int(fixture[6]) > 0:
		_expect(saw_transit and delivered,"Transfer visibly precedes healing")
		_expect(_has_heal(),"Applied healing has combat number and history")
	else:
		_expect(not _has_heal(),"Full Block creates no invented heal")
	await _shot("siphon-arrived")
	await get_tree().create_timer(.5).timeout

func _test_thorns_order() -> void:
	_reset()
	battle.player_hp = 2
	battle.enemy_thorns = 4
	battle.player_sockets[0].slotted_relic = ClockInventory.resolve({"id":"REL-13","uid":99,"level":1})
	await battle._resolve_tick(1)
	_expect(battle.player_hp == 4,"Healing still resolves before thorns in authoritative combat state")

func _has_heal() -> bool:
	for entry: String in battle._combat_history:
		if "HEAL" in entry: return true
	return false

func _run_tick() -> void:
	await battle._resolve_tick(1)
	_active = false

func _reset() -> void:
	battle.player_hp = 40
	battle.player_max_hp = 60
	battle.enemy_hp = 100
	battle.enemy_max_hp = 100
	battle._combat_history.clear()
	for key: String in ["player_block","player_strength","player_weak","player_vulnerable","player_bleed","player_thorns","player_next_hit_bonus","enemy_block","enemy_strength","enemy_weak","enemy_vulnerable","enemy_bleed","enemy_thorns"]: battle.set(key,0)
	battle.player_next_attack_multiplier = 1
	battle._combat_over = false
	for socket: ClockSocketData in battle.enemy_sockets:
		socket.intent_damage = 0
		socket.intent_block = 0
		socket.intent_strength = 0
		socket.intent_bleed = 0
		socket.intent_weak = 0
		socket.intent_vulnerable = 0
	battle._update_stats_display()

func _shot(label: String) -> void:
	if not _capture or _captured.has(label): return
	_captured[label] = true
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_output)
	get_viewport().get_texture().get_image().save_png(_output+"/"+label+".png")
