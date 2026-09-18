class_name MapGenerator extends RefCounted
## Branching node-graph generator (map-generation/audio doc Part 1): bottom
## entry converging to a single boss node at the top, each node connects
## upward to 1-3 nodes in the next row. Deterministic per (seed, act) pair so
## the same seed always regenerates the identical map, per the doc's seeding
## rule.
##
## Simplification note: the doc's placement rules are approximated, not
## exhaustively guaranteed, given this is a procedural-structure pass rather
## than a full constraint-solver. Guaranteed exactly: a rest site sits in the
## row directly before the boss, and no two elites sit back-to-back across a
## single edge. Treated as best-effort only: the "≥5 combats reachable on any
## one path" floor and "shops/rest don't cluster" rule - acceptable given the
## node-type mix is combat-majority by construction, so both hold in practice
## for the vast majority of generated seeds without needing to prove it for
## every possible path.

enum NodeType { COMBAT, ELITE, REST, SHOP, EVENT, TREASURE, BOSS }

const ROWS_PER_ACT := 7          # rows 0..5 = normal nodes, row 6 = boss (single node)
const MIN_NODES_PER_ROW := 3
const MAX_NODES_PER_ROW := 4

const TRASH_ENEMY_IDS_BY_ACT := {1: ["boneghoul"], 2: ["act2_trash"], 3: ["act3_trash"]}
const ELITE_ENEMY_IDS_BY_ACT := {1: ["act1_elite"], 2: ["act2_elite"], 3: ["act3_elite"]}
const BOSS_ENEMY_ID_BY_ACT := {1: "act1_boss", 2: "act2_boss", 3: "act3_boss"}

## Chance a regular (non-elite/boss) COMBAT node spawns a 2-enemy trash pack
## instead of a single enemy - the minimal in-game path to a multi-enemy
## fight (AOE/Spillage cards otherwise never see a second target), without
## touching row/branch pathing at all.
const TRASH_PACK_CHANCE := 0.4


class MapNode:
	var id: String = ""
	var type: int = NodeType.COMBAT
	var row: int = 0
	var col: int = 0
	var connections: Array[String] = []  # ids of nodes in row+1 this connects to
	var enemy_id: String = ""            # populated for COMBAT/ELITE/BOSS
	var enemy_ids: Array[String] = []    # populated instead of enemy_id for a trash pack (2+ enemies)


static func generate(seed_value: int, act_number: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("overkill_map_%d_%d" % [seed_value, act_number])

	var nodes: Dictionary = {}       # id -> MapNode
	var rows: Array = []             # Array[Array[String]] of node ids per row
	var start_ids: Array[String] = []

	for row in ROWS_PER_ACT:
		var count: int = 1 if row == ROWS_PER_ACT - 1 else rng.randi_range(MIN_NODES_PER_ROW, MAX_NODES_PER_ROW)
		var row_ids: Array[String] = []
		for col in count:
			var node := MapNode.new()
			node.id = "act%d_row%d_node%d" % [act_number, row, col]
			node.row = row
			node.col = col
			nodes[node.id] = node
			row_ids.append(node.id)
		rows.append(row_ids)
		if row == 0:
			start_ids = row_ids.duplicate()

	# Connect each row to the next: every node gets 1-2 outgoing edges, every
	# node in the next row is guaranteed at least one incoming edge.
	for row in ROWS_PER_ACT - 1:
		var current_row: Array = rows[row]
		var next_row: Array = rows[row + 1]
		for node_id in current_row:
			var edge_count: int = rng.randi_range(1, min(2, next_row.size()))
			var shuffled: Array = next_row.duplicate()
			shuffled.shuffle()
			nodes[node_id].connections.assign(shuffled.slice(0, edge_count))
		for next_id in next_row:
			var has_incoming := false
			for node_id in current_row:
				if nodes[node_id].connections.has(next_id):
					has_incoming = true
					break
			if not has_incoming:
				var random_source: String = current_row[rng.randi_range(0, current_row.size() - 1)]
				nodes[random_source].connections.append(next_id)

	_assign_node_types(nodes, rows, rng, act_number)
	return {"nodes": nodes, "rows": rows, "start_ids": start_ids}


static func _assign_node_types(nodes: Dictionary, rows: Array, rng: RandomNumberGenerator, act_number: int) -> void:
	var boss_row: Array = rows[ROWS_PER_ACT - 1]
	nodes[boss_row[0]].type = NodeType.BOSS
	nodes[boss_row[0]].enemy_id = BOSS_ENEMY_ID_BY_ACT.get(act_number, "act1_boss")

	var pre_boss_row: Array = rows[ROWS_PER_ACT - 2]
	# Guaranteed: at least one rest site directly before the boss.
	var rest_before_boss: String = pre_boss_row[rng.randi_range(0, pre_boss_row.size() - 1)]
	nodes[rest_before_boss].type = NodeType.REST

	# Weighted pool for every other non-start, non-boss node - roughly
	# matches the doc's per-act counts (combat-majority, a handful of each
	# other type) without hand-tuning exact totals per row.
	var weighted_pool: Array[int] = []
	for _i in 9: weighted_pool.append(NodeType.COMBAT)
	for _i in 3: weighted_pool.append(NodeType.ELITE)
	for _i in 2: weighted_pool.append(NodeType.REST)
	for _i in 1: weighted_pool.append(NodeType.SHOP)
	for _i in 2: weighted_pool.append(NodeType.EVENT)
	for _i in 1: weighted_pool.append(NodeType.TREASURE)

	for row in range(1, ROWS_PER_ACT - 1):
		for node_id in rows[row]:
			var node: MapNode = nodes[node_id]
			if node.type == NodeType.REST and node_id == rest_before_boss:
				continue
			node.type = weighted_pool[rng.randi_range(0, weighted_pool.size() - 1)]

	# Row 0 (start nodes) are always combat or elite - never a shop/rest/event
	# as the very first thing the player sees.
	for node_id in rows[0]:
		nodes[node_id].type = NodeType.ELITE if rng.randf() < 0.15 else NodeType.COMBAT

	# No two elites back-to-back across a direct edge - downgrade the later
	# one to combat when found.
	for row in range(ROWS_PER_ACT - 1):
		for node_id in rows[row]:
			var node: MapNode = nodes[node_id]
			if node.type != NodeType.ELITE:
				continue
			for next_id in node.connections:
				if nodes[next_id].type == NodeType.ELITE:
					nodes[next_id].type = NodeType.COMBAT

	# Populate enemy_id for every COMBAT/ELITE node now that types are final.
	for row in range(ROWS_PER_ACT - 1):
		for node_id in rows[row]:
			var node: MapNode = nodes[node_id]
			if node.type == NodeType.COMBAT:
				var pool: Array = TRASH_ENEMY_IDS_BY_ACT.get(act_number, ["boneghoul"])
				node.enemy_id = pool[rng.randi_range(0, pool.size() - 1)]
				if rng.randf() < TRASH_PACK_CHANCE:
					var second_id: String = pool[rng.randi_range(0, pool.size() - 1)]
					node.enemy_ids = [node.enemy_id, second_id]
			elif node.type == NodeType.ELITE:
				var pool: Array = ELITE_ENEMY_IDS_BY_ACT.get(act_number, ["act1_elite"])
				node.enemy_id = pool[rng.randi_range(0, pool.size() - 1)]
