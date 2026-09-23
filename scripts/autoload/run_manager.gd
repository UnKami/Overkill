extends Node
## RunManager - single owner of everything that survives across a fight
## boundary: the deck (as per-copy RunCardEntry records), run-persistent HP,
## relics, potions, and map position. PlayerState owns everything that resets
## every combat (block/energy/hand/piles) - see the technical architecture
## doc's PlayerState-vs-RunManager split. No other script should cache its
## own copy of any field here (same anti-drift rule as OKRunState).

signal hp_changed(current: int, max_hp: int)
signal deck_changed(deck: Array)
signal relics_changed(relics: Array)
signal run_started()
signal run_ended()
signal clock_inventory_changed

var run_active: bool = false

## Map state
var seed_value: int = 0
var act_number: int = 1
var current_node_id: String = ""
var visited_nodes: Array[String] = []
var pre_battle_offer_acts: Array[int] = []

## Run-persistent HP (distinct from PlayerState.hp, which resets every fight)
var current_hp: int = 0
var max_hp: int = 0

## Run-persistent deck and inventory
var deck: Array[RunCardEntry] = []
var clock_inventory: Array[Dictionary] = []
var relics_held: Array[RelicData] = []
var potions_held: Array[String] = []  # potion ids - stub, no PotionData yet

## Per-category purchase counters this run, for the shop pricing formula
## (base * 1.15 ^ purchases_already_made_this_run_in_that_category)
var purchase_counts: Dictionary = {}  # category String -> int

var _next_card_instance_id: int = 0


func start_new_run(starting_deck: Array[CardData], starting_relics: Array[RelicData] = [], starting_max_hp: int = 75, map_seed: int = -1) -> void:
	OKRunState.reset_for_new_run()
	deck.clear()
	clock_inventory = ClockInventory.starter()
	_next_card_instance_id = 0
	for card in starting_deck:
		deck.append(RunCardEntry.new(card.id, _next_card_instance_id, 0))
		_next_card_instance_id += 1
	relics_held = starting_relics.duplicate()
	potions_held.clear()
	purchase_counts.clear()
	current_hp = starting_max_hp
	max_hp = starting_max_hp
	act_number = 1
	current_node_id = ""
	visited_nodes.clear()
	pre_battle_offer_acts.clear()
	seed_value = map_seed if map_seed != -1 else randi()
	run_active = true
	run_started.emit()


func load_from_save(data: Dictionary) -> void:
	clock_inventory.clear()
	var seen: Dictionary = {}
	for raw in data.get("clock_inventory", []):
		if raw is Dictionary and ContentDatabase.get_clock_relic(str(raw.get("id", ""))) != null:
			var uid := int(raw.get("uid", clock_inventory.size()))
			if seen.has(uid): uid = clock_inventory.size() + 10000
			seen[uid] = true
			clock_inventory.append({"uid": uid, "id": str(raw.id), "level": clampi(int(raw.get("level", 0)), 0, 1)})
	# Older card-only saves migrate once; keep their old records intact.
	if clock_inventory.is_empty():
		clock_inventory = ClockInventory.starter()
	deck.clear()
	var highest_instance_id := -1
	for entry_data in data.get("deck", []):
		var entry := RunCardEntry.from_save_dict(entry_data)
		deck.append(entry)
		highest_instance_id = max(highest_instance_id, entry.instance_id)
	_next_card_instance_id = highest_instance_id + 1

	relics_held.clear()
	for relic_id in data.get("relics_held", []):
		var relic := ContentDatabase.get_relic(relic_id)
		if relic != null:
			relics_held.append(relic)

	potions_held.assign(data.get("potions_held", []))
	purchase_counts = data.get("purchase_counts", {}).duplicate()
	current_hp = data.get("current_hp", 75)
	max_hp = data.get("max_hp", 75)

	var map_data: Dictionary = data.get("map", {})
	seed_value = map_data.get("seed", randi())
	act_number = map_data.get("act_number", 1)
	current_node_id = map_data.get("current_node_id", "")
	visited_nodes.assign(map_data.get("visited_nodes", []))
	pre_battle_offer_acts.assign(map_data.get("pre_battle_offer_acts", []))

	OKRunState.load_from_save(data.get("ok_run_state", {}))
	run_active = true
	run_started.emit()


func to_save_dict() -> Dictionary:
	var deck_data: Array = []
	for entry in deck:
		deck_data.append(entry.to_save_dict())
	var relic_ids: Array = []
	for relic in relics_held:
		relic_ids.append(relic.id)
	return {
		"clock_inventory": clock_inventory.duplicate(true),
		"deck": deck_data,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"relics_held": relic_ids,
		"potions_held": potions_held.duplicate(),
		"purchase_counts": purchase_counts.duplicate(),
		"map": {
			"seed": seed_value,
			"current_node_id": current_node_id,
			"visited_nodes": visited_nodes.duplicate(),
			"act_number": act_number,
			"pre_battle_offer_acts": pre_battle_offer_acts.duplicate(),
		},
	}


func ensure_clock_inventory() -> void:
	if clock_inventory.is_empty(): clock_inventory = ClockInventory.starter()


func add_clock_relic(relic_id: String) -> bool:
	if ContentDatabase.get_clock_relic(relic_id) == null: return false
	var uid := 0
	for entry in clock_inventory: uid = maxi(uid, int(entry.uid) + 1)
	clock_inventory.append({"uid": uid, "id": relic_id, "level": 0})
	clock_inventory_changed.emit()
	return true


func upgrade_clock_relic(uid: int) -> bool:
	for entry in clock_inventory:
		if int(entry.uid) == uid and int(entry.level) == 0:
			entry.level = 1
			clock_inventory_changed.emit()
			return true
	return false


func remove_clock_relic(uid: int) -> bool:
	if clock_inventory.size() <= ClockInventory.MINIMUM_SIZE: return false
	for i in clock_inventory.size():
		if int(clock_inventory[i].uid) == uid:
			clock_inventory.remove_at(i)
			clock_inventory_changed.emit()
			return true
	return false


func end_run() -> void:
	run_active = false
	run_ended.emit()


func resolve_card(entry: RunCardEntry) -> CardData:
	return ContentDatabase.get_card(entry.card_id)


func apply_card_upgrade(instance_id: int) -> bool:
	for entry in deck:
		if entry.instance_id == instance_id:
			if entry.upgrade_level > 0:
				return false
			entry.upgrade_level = 1
			deck_changed.emit(deck)
			return true
	return false


func add_card_to_deck(card: CardData, upgrade_level: int = 0) -> int:
	var entry := RunCardEntry.new(card.id, _next_card_instance_id, upgrade_level)
	_next_card_instance_id += 1
	deck.append(entry)
	deck_changed.emit(deck)
	return entry.instance_id


func remove_card_from_deck(instance_id: int) -> bool:
	for i in deck.size():
		if deck[i].instance_id == instance_id:
			deck.remove_at(i)
			deck_changed.emit(deck)
			return true
	return false


func add_relic(relic: RelicData) -> void:
	relics_held.append(relic)
	relics_changed.emit(relics_held)


func has_relic(relic_id: String) -> bool:
	for relic in relics_held:
		if relic.id == relic_id:
			return true
	return false


func add_potion(potion_id: String) -> void:
	potions_held.append(potion_id)


func use_potion(potion_id: String) -> bool:
	var idx := potions_held.find(potion_id)
	if idx == -1:
		return false
	potions_held.remove_at(idx)
	return true


func apply_run_hp_change(delta: int) -> void:
	current_hp = clampi(current_hp + delta, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func apply_max_hp_change(delta: int) -> void:
	max_hp = max(1, max_hp + delta)
	if delta > 0:
		current_hp = clampi(current_hp + delta, 0, max_hp)
	else:
		current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func sync_hp_from_combat(ending_hp: int) -> void:
	current_hp = clampi(ending_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func commit_map_node(node_id: String) -> void:
	current_node_id = node_id
	if not visited_nodes.has(node_id):
		visited_nodes.append(node_id)


func should_offer_pre_battle() -> bool:
	# One authored offer at the first battle of each act. Keeping the trigger in
	# run state (rather than the map UI) lets future elite/boss events opt into
	# the same presentation without making every encounter show an offer.
	return not pre_battle_offer_acts.has(act_number)


func mark_pre_battle_offer_seen() -> void:
	if not pre_battle_offer_acts.has(act_number):
		pre_battle_offer_acts.append(act_number)


func advance_act(new_seed: int = -1) -> void:
	act_number += 1
	current_node_id = ""
	visited_nodes.clear()
	seed_value = new_seed if new_seed != -1 else randi()


## Shop pricing formula (balance doc): base * 1.15 ^ purchases already made
## this run in that category. Category is caller-defined (e.g. "upgrade_common",
## "buy_card_common", "relic", "removal") so different tracks scale independently.
func price_for(category: String, base_price: int) -> int:
	var count: int = purchase_counts.get(category, 0)
	return int(round(base_price * pow(1.15, count)))


func record_purchase(category: String) -> void:
	purchase_counts[category] = purchase_counts.get(category, 0) + 1
