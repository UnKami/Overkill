extends Node
## Regression for route reconstruction after save/load or unrelated random
## activity. Compare the whole graph, not only node counts or the seed field.
var _failures: Array[String] = []
const RUN_SEEDS: Array[int] = [0, 1, 2, 17, 99, 731, 2026, 19030, 42042, 100003, 1234567, 2147483646]

func _ready() -> void:
	var act_one_signatures: Dictionary = {}
	for run_seed: int in RUN_SEEDS:
		for act: int in range(1, 4):
			seed(1001)
			var baseline: Dictionary = MapGenerator.generate(run_seed, act)
			var expected: String = _signature(baseline)
			_check_structure(baseline, run_seed, act)
			if act == 1:
				act_one_signatures[expected] = true
			# Encounter/VFX randomness must not affect a regenerated map.
			for salt: int in [7, 401, 9127]:
				seed(salt)
				for _draw: int in range(13 + act * 7):
					randi()
				MapGenerator.generate(run_seed + 113, (act % 3) + 1)
				var rebuilt: Dictionary = MapGenerator.generate(run_seed, act)
				_expect(_signature(rebuilt) == expected, "Whole route graph changed for seed %d act %d after unrelated RNG %d" % [run_seed, act, salt])
			# Generating a map must also leave gameplay's global RNG untouched.
			seed(7123 + act)
			var expected_next: int = randi()
			seed(7123 + act)
			MapGenerator.generate(run_seed, act)
			_expect(randi() == expected_next, "Map generation consumed the global RNG for seed %d act %d" % [run_seed, act])
	_expect(act_one_signatures.size() > 1, "Different seeds must still produce different routes")
	if _failures.is_empty():
		print("MAP_DETERMINISM_OK: 36 seeded maps, full graph reconstruction across unrelated RNG and interleaved acts, global RNG isolation and route reachability")
		get_tree().quit()
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)

func _signature(map: Dictionary) -> String:
	var encoded_nodes: Array = []
	var rows: Array = map.rows
	var nodes: Dictionary = map.nodes
	for row: Array in rows:
		for node_id: String in row:
			var node: MapGenerator.MapNode = nodes[node_id]
			var connections: Array[String] = node.connections.duplicate()
			connections.sort()
			encoded_nodes.append([node.id, node.row, node.col, node.type, node.enemy_id, node.enemy_ids, connections])
	return JSON.stringify([map.start_ids, rows, encoded_nodes])

func _check_structure(map: Dictionary, run_seed: int, act: int) -> void:
	var nodes: Dictionary = map.nodes
	var rows: Array = map.rows
	var context: String = "seed %d act %d" % [run_seed, act]
	_expect(rows.size() == MapGenerator.ROWS_PER_ACT, "Row count changed: " + context)
	_expect(map.start_ids == rows[0], "Start nodes do not match the entrance row: " + context)
	var seen: Dictionary = {}
	var pending: Array[String] = []
	pending.assign(map.start_ids)
	while not pending.is_empty():
		var node_id: String = pending.pop_front()
		if seen.has(node_id):
			continue
		seen[node_id] = true
		var node: MapGenerator.MapNode = nodes[node_id]
		if node.row < MapGenerator.ROWS_PER_ACT - 1:
			_expect(not node.connections.is_empty(), "A route is a dead end: %s %s" % [context, node_id])
		var unique_edges: Dictionary = {}
		for next_id: String in node.connections:
			_expect(not unique_edges.has(next_id), "Duplicate route edge: %s %s" % [context, node_id])
			unique_edges[next_id] = true
			_expect(nodes.has(next_id), "Route points to a missing node: %s %s" % [context, next_id])
			if not nodes.has(next_id):
				continue
			var next: MapGenerator.MapNode = nodes[next_id]
			_expect(next.row == node.row + 1, "Route does not advance exactly one row: %s %s" % [context, node_id])
			pending.append(next_id)
	_expect(seen.size() == nodes.size(), "An unreachable node remains in the generated map: " + context)
	var boss_row: Array = rows[rows.size() - 1]
	_expect(boss_row.size() == 1, "Routes must converge on one boss: " + context)
	var boss: MapGenerator.MapNode = nodes[boss_row[0]]
	_expect(boss.type == MapGenerator.NodeType.BOSS and boss.connections.is_empty(), "Boss endpoint is invalid: " + context)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
