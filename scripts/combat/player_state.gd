class_name PlayerState extends Node
## Per-combat player state. Deliberately NOT an autoload - HP/Block/Energy
## reset every combat (user journey doc, Step 5), unlike OKRunState which is
## the one piece of state that survives the whole run. HUD binds to this
## directly rather than caching its own copy.

signal hp_changed(current: int, max: int)
signal block_changed(current: int)
signal energy_changed(current: int, max: int)
signal hand_changed(hand: Array)

const MAX_HP := 75          ## balance doc Section 1
const MAX_ENERGY := 3
const HAND_SIZE := 5

var max_hp: int = MAX_HP
var hp: int = MAX_HP
var block: int = 0
var max_energy: int = MAX_ENERGY
var energy: int = MAX_ENERGY

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []


func setup_deck(deck: Array[CardData]) -> void:
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()


func start_turn() -> void:
	energy = max_energy
	energy_changed.emit(energy, max_energy)
	block = 0
	block_changed.emit(block)
	_draw_to_hand_size()


func end_turn() -> void:
	discard_pile.append_array(hand)
	hand.clear()
	hand_changed.emit(hand)


func can_afford(card: CardData) -> bool:
	return card.energy_cost <= energy


func spend_energy(amount: int) -> void:
	energy -= amount
	energy_changed.emit(energy, max_energy)


func play_card(card: CardData) -> void:
	hand.erase(card)
	discard_pile.append(card)
	hand_changed.emit(hand)


func gain_block(amount: int) -> void:
	block += amount
	block_changed.emit(block)


## Returns unabsorbed damage after Block, per the standard soak rule.
func take_damage(amount: int) -> int:
	var absorbed: int = min(block, amount)
	block -= absorbed
	var remaining: int = amount - absorbed
	hp = max(0, hp - remaining)
	block_changed.emit(block)
	hp_changed.emit(hp, max_hp)
	return remaining


func is_dead() -> bool:
	return hp <= 0


func _draw_to_hand_size() -> void:
	draw_extra(HAND_SIZE - hand.size())


## Draws `count` cards regardless of current hand size, reshuffling discard
## into draw pile when the draw pile runs out. Used for the turn-start draw
## and for any card effect that grants extra draw.
func draw_extra(count: int) -> void:
	for _i in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break  # deck fully exhausted, nothing left to draw
			draw_pile = discard_pile.duplicate()
			draw_pile.shuffle()
			discard_pile.clear()
		hand.append(draw_pile.pop_back())
	hand_changed.emit(hand)
