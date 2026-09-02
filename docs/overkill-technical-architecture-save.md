# OVERKILL — Technical Architecture & Save Format

This is the most load-bearing of the remaining Tier 3 items — tutorial-callout flags, settings, and meta-progression scope all sit on top of whatever gets decided here. It also requires settling the meta-progression scope question (gap #15) first, since that determines what actually needs to persist.

---

## PART 1 — Meta-progression scope decision (resolves gap #15)

**Recommendation for v1: keep it minimal.** Settings and tutorial-seen flags persist across runs (required regardless, per the pause-menu and tutorial-callout specs). Beyond that, no cross-run unlocks (no locked classes, no permanent stat boosts, no meta-currency) ship in v1 — every run starts from the same baseline, and progression is purely within a single run via the OK/deck-building loop already designed.

**Why minimal is the right default here, not just the easy one**: the whole design's identity is about in-run mastery of the Overkill mechanic. Adding cross-run unlocks (new classes, permanent upgrades) is a reasonable thing to want eventually, but it's an entirely separate design surface — it doesn't need to be solved before Claude Code can build the core game, and deciding it now would just be guessing ahead of any playtesting data about what the loop actually needs. Treat this as explicitly deferred, not rejected — worth a real design pass once the core loop is proven, not before.

---

## PART 2 — Two-tier save structure

### 2.1 RunSave — the current in-progress run
Everything needed to resume an interrupted run exactly where it left off:
```
- deck (list of CardData references + per-card upgrade level)
- current_hp, max_hp
- relics_held (list of RelicData references)
- potions_held
- ok_run_state: { current_ok, best_single_hit_ok_this_run, unlocked_excess_thresholds }
- map: { seed, current_node_id, visited_nodes, act_number }
- schema_version
```

### 2.2 MetaSave — persists across runs, survives a run ending
```
- settings: { master_volume, music_volume, sfx_volume, fast_mode, text_size }
- tutorial_seen: { moment_id: bool, ... }  (per the tutorial callout doc's persistence rule)
- schema_version
```

**Keeping these as two separate files/objects, not one blob, matters**: a run ending (win or loss) should cleanly delete or archive the RunSave without touching MetaSave at all — settings and tutorial flags must never be affected by how a run concluded. If meta-progression is added later (per Part 1's deferred note), it slots into MetaSave without disturbing RunSave's shape.

### 2.3 Format
**JSON, not Godot's typed Resource serialization, for both save files.** Reasoning: content-authoring data (cards, enemies, relics) should stay as `.tres` Resources, since designers benefit from editing them in the Godot editor directly — but save *data* is different: it changes shape as development continues, and typed Resource saves break silently when a class's fields change between versions. JSON is schema-flexible, human-readable for debugging, and trivial to migrate with a version field (2.4) rather than crashing on load.

### 2.4 Schema versioning
Both save files carry a `schema_version` integer from day one, even though there's only one version right now. This is cheap insurance — the first time a card field gets renamed or restructured after players have existing saves, having a version field already in place is the difference between a clean migration path and broken saves with no way to detect why.

### 2.5 When saves write
**Autosave on every meaningful state change** — after combat resolution, after any map node choice, after any shop/rest-site transaction — not a manual save-slot system. This is standard for the genre (StS itself autosaves constantly) and means a crash or forced quit never loses more than the single action in progress. MetaSave writes whenever settings change or a new tutorial flag is set, independent of RunSave's save cadence.

### 2.6 File location
Save files live in Godot's `user://` directory (writable at runtime), never `res://` (read-only once exported) — `user://saves/run_save.json` and `user://saves/meta_save.json` as a starting convention.

---

## PART 3 — Project folder structure

Extending the naming convention already established in the art requirements doc so asset drops require no renaming:

```
res://
├── data/
│   ├── cards/[class-id]/[card-id].tres
│   ├── cards/excess/[card-id].tres
│   ├── enemies/act[N]/[enemy-id].tres
│   ├── relics/[relic-id].tres
│   └── statuses/[status-id].tres
├── art/                          # mirrors the art doc's folder convention exactly
├── scenes/
│   ├── ui/                       # combat, map, shop, rest, deck_view, pause, settings screens
│   └── components/               # intent_icon, card_display, relic_icon, tooltip, targeting_preview
├── autoloads/
│   ├── ok_run_state.gd
│   ├── keyword_registry.gd
│   ├── save_manager.gd
│   └── audio_manager.gd          # placeholder pending the still-open audio design doc
└── data_schemas/                 # base Resource class definitions (CardData, EnemyData, etc.)
```

---

## PART 4 — Autoload responsibilities

| Autoload | Owns |
|---|---|
| `OKRunState` | Current OK total, threshold-crossing signals — already defined in the data schema doc, listed here for completeness of the architecture picture |
| `KeywordRegistry` | Status/keyword icon+label lookup — already defined in the data schema doc |
| `SaveManager` | Reading/writing both RunSave and MetaSave, autosave triggers, schema migration |
| `AudioManager` | Placeholder responsibility until the audio design doc exists — should at minimum own volume settings application from MetaSave |

**No autoload should duplicate state another autoload owns** — e.g., `SaveManager` reads *from* `OKRunState` when writing a RunSave, it doesn't maintain its own separate copy of the OK total. This is the same anti-drift principle already established for OK threshold checks and the targeting-preview's resolution function — one owner per piece of state, everywhere in the architecture, not just in the two places it's been called out explicitly so far.
