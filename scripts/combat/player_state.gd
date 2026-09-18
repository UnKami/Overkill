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

## Damage-modifier state (data schema doc 1.6) - Strength never decays this
## combat, Weak/Vulnerable are duration stacks ticked down at end of the
## turn in which their owner acted. See CombatMath.resolve_damage().
var strength: int = 0
var weak_stacks: int = 0
var vulnerable_stacks: int = 0

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []


## Called once from combat_controller._ready(), right after construction, to
## seed this fight's HP from RunManager's run-persistent value. hp/max_hp then
## live independently for the fight's duration - RunManager.sync_hp_from_combat()
## is the only thing that writes the ending value back, at combat end.
func setup_hp(current: int, p_max_hp: int) -> void:
	max_hp = p_max_hp
	hp = current
	hp_changed.emit(hp, max_hp)


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
	var kept: Array[CardData] = []
	for card in hand:
		if card.retain:
			kept.append(card)
		else:
			discard_pile.append(card)
	hand = kept
	weak_stacks = max(0, weak_stacks - 1)
	vulnerable_stacks = max(0, vulnerable_stacks - 1)
	hand_changed.emit(hand)


func can_afford(card: CardData) -> bool:
	return card.energy_cost <= energy


func spend_energy(amount: int) -> void:
	energy -= amount
	energy_changed.emit(energy, max_energy)


## Spends this card's cost and returns the amount actually spent - for a
## normal card that's card.energy_cost; for an X-cost card (energy_cost < 0)
## it's however much energy the player had, spent in full (may be 0).
func spend_energy_for(card: CardData) -> int:
	var cost: int = energy if card.energy_cost < 0 else card.energy_cost
	spend_energy(cost)
	return cost


## Direct energy grant (e.g. Overcharge) - goes through the same signal path
## as spend_energy so the HUD never silently drifts from the real value.
func gain_energy(amount: int) -> void:
	energy += amount
	energy_changed.emit(energy, max_energy)


func play_card(card: CardData) -> void:
	hand.erase(card)
	if not card.exhaust:
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


## Self-inflicted HP loss from a card's own cost (LOSE_HP effect), not an
## enemy attack - bypasses Block entirely, unlike take_damage().
func lose_hp(amount: int) -> void:
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)


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
