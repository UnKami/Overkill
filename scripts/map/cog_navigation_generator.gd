class_name CogNavigationGenerator
extends RefCounted
## Deterministic cog lattice. Each physical wheel offers three distinct seats;
## the player chooses a connected destination wheel, then times the arrival.

const LAYER_GEAR_COUNTS: Array[int] = [1, 2, 3, 4, 3, 2, 1]
const LEGACY_LAYER_GEAR_COUNTS: Array[int] = [1, 2, 3, 4, 3, 2, 2, 1]
const LAYOUT_VERSION: int = 2
const MESH_DISTANCE: float = 260.0
const CONTACT_ANGLE: float = PI * 7.0 / 24.0
const COLUMN_PITCH: float = 2.0 * MESH_DISTANCE * cos(CONTACT_ANGLE)
const ROW_PITCH: float = MESH_DISTANCE * sin(CONTACT_ANGLE)
const SEAT_ANGLES: Array[float] = [-PI * 0.5, atan2(0.235, 0.255), PI - atan2(0.235, 0.255)]


class Gear:
	var id: String = ""
	var layer: int = 0
	var index: int = 0
	var connections: Array[String] = []
	var seats: Array[MapGenerator.MapNode] = []
	var machine_position: Vector2 = Vector2.ZERO


static func generate(seed_value: int, act_number: int, layout_version: int = LAYOUT_VERSION) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("overkill_cog_lattice_%d_%d" % [seed_value, act_number])
	var gears: Dictionary = {}
	var layers: Array[Array] = []
	var nodes: Dictionary = {}
	var counts: Array[int] = LEGACY_LAYER_GEAR_COUNTS if layout_version < LAYOUT_VERSION else LAYER_GEAR_COUNTS
	for layer_index: int in counts.size():
		var layer_ids: Array[String] = []
		for gear_index: int in counts[layer_index]:
			var gear := Gear.new()
			gear.layer = layer_index
			gear.index = gear_index
			gear.id = _gear_id(act_number, layer_index, gear_index)
			var column: float = gear_index - (counts[layer_index] - 1) * 0.5
			# Keep old seat IDs/encounters while staggering the repeated two-wheel
			# row. The top bearing shifts half a column; every edge remains meshed.
			if layout_version < LAYOUT_VERSION and layer_index >= 6:
				column += 0.5
			gear.machine_position = Vector2(column * COLUMN_PITCH, -layer_index * ROW_PITCH)
			layer_ids.append(gear.id)
			for seat_index: int in 3:
				var node := MapGenerator.MapNode.new()
				node.id = _seat_id(act_number, layer_index, gear_index, seat_index)
				node.row = layer_index
				node.col = gear_index * 3 + seat_index
				node.type = _seat_type(layer_index, seat_index, rng, counts.size())
				_assign_encounter(node, act_number, layer_index, rng)
				gear.seats.append(node)
				nodes[node.id] = node
			gears[gear.id] = gear
		layers.append(layer_ids)

	for layer_index: int in range(counts.size() - 1):
		var current_ids: Array = layers[layer_index]
		var next_ids: Array = layers[layer_index + 1]
		for gear_index: int in current_ids.size():
			var gear: Gear = gears[current_ids[gear_index]]
			for next_id: String in next_ids:
				var next: Gear = gears[next_id]
				if absf(gear.machine_position.distance_to(next.machine_position) - MESH_DISTANCE) < 0.01:
					gear.connections.append(next_id)
	return {"gears": gears, "layers": layers, "nodes": nodes, "layout_version": layout_version}


static func _seat_type(layer_index: int, seat_index: int, rng: RandomNumberGenerator, layer_count: int) -> int:
	if layer_index <= 1:
		return MapGenerator.NodeType.COMBAT
	if layer_index < layer_count - 3:
		# Early approaches guarantee combat, with an optional elite seat
		# on selected fourth-stage wheels.
		return MapGenerator.NodeType.ELITE if layer_index == 3 and seat_index == 2 and rng.randf() < 0.42 else MapGenerator.NodeType.COMBAT
	if layer_index == layer_count - 3:
		return [MapGenerator.NodeType.COMBAT, MapGenerator.NodeType.ELITE, MapGenerator.NodeType.TREASURE][seat_index]
	if layer_index == layer_count - 2:
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


static func rotation_sign(layer_index: int) -> float:
	return 1.0 if layer_index % 2 == 0 else -1.0


static func rotation_for_layer(layer_index: int, machine_angle: float) -> float:
	return rotation_sign(layer_index) * machine_angle + (PI / 24.0 if layer_index % 2 != 0 else 0.0)


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
