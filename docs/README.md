# OVERKILL — Design Doc Index

Read in this order — each doc builds on the ones before it. This mirrors `claude-code-handoff-prompt.md`'s Step 1 list.

1. `overkill-game-design.md` — core concept: Overkill, Spillage, archetypes, economy. Source of truth for the game's identity.
2. `overkill-balance-baseline.md` — starting numbers, pricing, HP curves.
3. `overkill-data-schema.md` — the data model, including the combat resolution rules (Block/AOE/DOT/Spillage/Tempered interactions — Part 1.6).
4. `overkill-icon-system-intent-ui.md` — icon-vs-text rules, the intent icon component, buff/debuff color language.
5. `overkill-screen-composition.md` — screen layout and the attention-priority rule for competing feedback.
6. `overkill-targeting-preview-system.md` — the card targeting/damage preview system. The single most important UX system in the game: the whole design depends on players calculating overkill (and now Spillage chains) before committing a card.
7. `overkill-deck-view-screen.md` — the reusable deck-browsing component.
8. `overkill-turn-presentation-tutorial-unlock.md` — enemy turn sequencing, first-time tutorial callouts, Excess-tier unlock celebration.
9. `overkill-pause-settings-confirmation.md` — pause menu, settings, confirmation-dialog convention.
10. `overkill-technical-architecture-save.md` — folder structure, autoloads, save format, meta-progression scope.
11. `overkill-map-generation-audio.md` — map generation rules and the audio design language.
12. `overkill-user-journey.md` — a full walkthrough tying everything above together, plus extended edge-case scenarios.
13. `overkill-art-requirements.md` — the full art asset list and AI-generation prompt kit.
14. `overkill-gap-analysis-fix-plan.md` — log of every design gap found and how each was resolved. Read last — it's a map of *why* certain decisions were made. Two items remain open (act-gating semantics for Excess thresholds, input-locking during animations) and need a decision before they're load-bearing for implementation.

`claude-code-handoff-prompt.md` is the process doc that kicked off the verification pass this index reflects — background, not a design source itself.

`archive/overkill-tutorial-callout-system.md` is superseded by doc 8 above; kept only for its more implementation-specific GDScript/timing detail.
