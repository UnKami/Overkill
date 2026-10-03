class_name CogNavigationGenerator
extends RefCounted
## Deterministic cog lattice. Each physical wheel offers three distinct seats;
## the player chooses a connected destination wheel, then times the arrival.

const LAYER_GEAR_COUNTS: Array[int] = [1, 2, 3, 4, 3, 2, 2, 1]
const SEAT_ANGLES: Array[float] = [-PI * 0.5, PI / 6.0, PI * 5.0 / 6.0]


class Gear:
	var id: String = ""
	var layer: int = 0
	var index: int = 0
	var connections: Array[String] = []
	var seats: Array[MapGenerator.MapNode] = []


static func generate(seed_value: int, act_number: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("overkill_cog_lattice_%d_%d" % [seed_value, act_number])
	var gears: Dictionary = {}
	var layers: Array[Array] = []
	var nodes: Dictionary = {}
	for layer_index: int in LAYER_GEAR_COUNTS.size():
		var layer_ids: Array[String] = []
		for gear_index: int in LAYER_GEAR_COUNTS[layer_index]:
			var gear := Gear.new()
			gear.layer = layer_index
			gear.index = gear_index
			gear.id = _gear_id(act_number, layer_index, gear_index)
			layer_ids.append(gear.id)
			for seat_index: int in 3:
				var node := MapGenerator.MapNode.new()
				node.id = _seat_id(act_number, layer_index, gear_index, seat_index)
				node.row = layer_index
				node.col = gear_index * 3 + seat_index
				node.type = _seat_type(layer_index, seat_index, rng)
				_assign_encounter(node, act_number, layer_index, rng)
				gear.seats.append(node)
				nodes[node.id] = node
			gears[gear.id] = gear
		layers.append(layer_ids)

	for layer_index: int in range(LAYER_GEAR_COUNTS.size() - 1):
		var current_ids: Array = layers[layer_index]
		var next_ids: Array = layers[layer_index + 1]
		for gear_index: int in current_ids.size():
			var gear: Gear = gears[current_ids[gear_index]]
			gear.connections = _two_forward_gears(gear_index, current_ids.size(), next_ids)
	return {"gears": gears, "layers": layers, "nodes": nodes}


static func _seat_type(layer_index: int, seat_index: int, rng: RandomNumberGenerator) -> int:
	if layer_index <= 1:
		return MapGenerator.NodeType.COMBAT
	if layer_index <= 4:
		# The hard fifth approach keeps combat guaranteed, with one elite seat
		# offering a deliberate higher-risk route on selected wheels.
		return MapGenerator.NodeType.ELITE if layer_index == 3 and seat_index == 2 and rng.randf() < 0.42 else MapGenerator.NodeType.COMBAT
	if layer_index == 5:
		return [MapGenerator.NodeType.COMBAT, MapGenerator.NodeType.ELITE, MapGenerator.NodeType.TREASURE][seat_index]
	if layer_index == 6:
		return [MapGenerator.NodeType.REST, MapGenerator.NodeType.SHOP, MapGenerator.NodeType.EVENT][seat_index]
	return MapGenerator.NodeType.BOSS


static func _assign_encounter(node: MapGenerator.MapNode, act_number: int, layer_index: int, rng: RandomNumberGenerator) -> void:
	if node.type == MapGenerator.NodeType.BOSS:
		node.enemy_id = MapGenerator.BOSS_ENEMY_ID_BY_ACT.get(act_number, "act1_boss")
		return
	if node.type == MapGenerator.NodeType.ELITE:
		var elite_pool: Array = MapGenerator.ELITE_ENEMY_IDS_BY_ACT.get(act_number, ["act1_elite"])
		node.enemy_id = elite_pool[rng.randi_range(0, elite_pool.size() - 1)]
		return
	if node.type != MapGenerator.NodeType.COMBAT:
		return
	var pool: Array = MapGenerator.TRASH_ENEMY_IDS_BY_ACT.get(act_number, ["boneghoul"])
	node.enemy_id = pool[rng.randi_range(0, pool.size() - 1)]
	if layer_index > 0 and rng.randf() < MapGenerator.TRASH_PACK_CHANCE:
		var second_id: String = pool[rng.randi_range(0, pool.size() - 1)]
		node.enemy_ids = [node.enemy_id, second_id]


static func _two_forward_gears(index: int, current_count: int, next_ids: Array) -> Array[String]:
	var result: Array[String] = []
	if next_ids.size() <= 1:
		result.append(next_ids[0])
		return result
	var projected: float = 0.0 if current_count <= 1 else float(index) * float(next_ids.size() - 1) / float(current_count - 1)
	var left_index: int = clampi(floori(projected), 0, next_ids.size() - 1)
	var right_index: int = clampi(ceili(projected), 0, next_ids.size() - 1)
	if left_index == right_index:
		if right_index == next_ids.size() - 1:
			left_index = maxi(0, right_index - 1)
		else:
			right_index = mini(next_ids.size() - 1, left_index + 1)
	result.append(next_ids[left_index])
	if next_ids[right_index] != result[0]:
		result.append(next_ids[right_index])
	return result


static func gear_id_from_node(node_id: String) -> String:
	var parts: PackedStringArray = node_id.split("-")
	if parts.size() != 5 or parts[0] != "cogmap":
		return ""
	return "-".join(parts.slice(0, 4))


static func seat_index_from_node(node_id: String) -> int:
	var parts: PackedStringArray = node_id.split("-")
	if parts.size() != 5 or parts[0] != "cogmap":
		return -1
	return int(parts[4].substr(1))


static func layer_from_node(node_id: String) -> int:
	var parts: PackedStringArray = node_id.split("-")
	if parts.size() != 5 or parts[0] != "cogmap":
		return -1
	return int(parts[2].substr(1))


static func node_id_from_seat(gear_id: String, seat_index: int) -> String:
	return "%s-s%d" % [gear_id, seat_index]


static func _gear_id(act_number: int, layer_index: int, gear_index: int) -> String:
	return "cogmap-a%d-r%d-g%d" % [act_number, layer_index, gear_index]


static func _seat_id(act_number: int, layer_index: int, gear_index: int, seat_index: int) -> String:
	return "%s-s%d" % [_gear_id(act_number, layer_index, gear_index), seat_index]
