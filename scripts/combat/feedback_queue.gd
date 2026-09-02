class_name FeedbackQueue extends Node
## Implements the attention-hierarchy rule from the screen composition doc,
## Part 1.2: when multiple things fire in the same instant, stagger their
## animations by 100-150ms in a fixed priority order instead of firing them
## all at once. This is the ONLY place that ordering is allowed to live -
## individual effects should enqueue here rather than hand-rolling their own
## delays.

enum Priority {
	OVERKILL = 1,       # always wins - the core mechanic's moment
	INTENT = 2,          # affects the player's very next decision
	PLAYER_STAT = 3,     # HP loss / Block gain, low-drama ticks
	RELIC_STATUS = 4,    # corner-of-eye confirmations, lowest priority
}

const STAGGER_SECONDS := 0.125  # within the spec's 100-150ms window


## entries: Array of {priority: Priority, action: Callable}. Fires callables
## in priority order, staggered - never all in the same frame.
func fire_batch(entries: Array) -> void:
	if entries.is_empty():
		return
	var sorted: Array = entries.duplicate()
	sorted.sort_custom(func(a, b): return a.priority < b.priority)
	for i in sorted.size():
		sorted[i].action.call()
		if i < sorted.size() - 1:
			await get_tree().create_timer(STAGGER_SECONDS).timeout
