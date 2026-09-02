You're picking up a fully-specced pre-implementation design for a roguelike deckbuilder called OVERKILL (a Slay the Spire-style game with one core twist: dealing damage beyond what's needed to kill an enemy generates "Overkill," the game's single persistent currency). No gameplay code exists yet — this is a documentation-first handoff. Your job right now is NOT to start building. It's to get a complete, accurate top-down understanding of the current design, verify it's internally consistent, and clean up the project folder before implementation begins.

## Step 1 — Read everything, in this order

The docs build on each other, so read them in this sequence rather than alphabetically:

1. `overkill-game-design.md` — core concept, the Overkill/Spillage mechanic, archetypes, economy. This is the source of truth for the game's identity.
2. `overkill-balance-baseline.md` — actual starting numbers, pricing, HP curves.
3. `overkill-data-schema.md` — the data model everything else binds to, including the combat resolution rules (Block/AOE/DOT/Spillage interactions).
4. `overkill-icon-system-intent-ui.md` — icon-vs-text rules and the intent icon component.
5. `overkill-screen-composition.md` — how screens are laid out and how competing feedback resolves.
6. `overkill-targeting-preview-system.md` — the card targeting/damage preview system (this is flagged in-doc as the single most important UX system in the game, since the whole design depends on players calculating overkill before committing a card).
7. `overkill-deck-view-screen.md` — the reusable deck-browsing component.
8. `overkill-turn-presentation-tutorial-unlock.md` — enemy turn sequencing, first-time tutorial callouts, Excess-tier unlock celebration.
9. `overkill-pause-settings-confirmation.md` — pause menu, settings, confirmation-dialog convention.
10. `overkill-technical-architecture-save.md` — folder structure, autoloads, save format, meta-progression scope.
11. `overkill-map-generation-audio.md` — map generation rules and the audio design language.
12. `overkill-user-journey.md` — a full walkthrough tying everything above together into what a player actually sees, step by step, plus extended edge-case scenarios.
13. `overkill-art-requirements.md` — the full art asset list and AI-generation prompt kit (separate track, but reference it for naming conventions used elsewhere).
14. `overkill-gap-analysis-fix-plan.md` — a log of every design gap found during this process and how each was resolved. Read this last — it's useful as a map of *why* certain decisions were made, and it should currently show every item as resolved.

Note: some art has already been generated as standalone images (not full pose/animation sheets) using an external AI agent — that's expected and correct for most asset categories per the art doc; only playable characters and enemies need multiple poses, and even those are meant to be animated in-engine from a single static pose rather than hand-drawn frame sheets (see the art doc's animation notes).

## Step 2 — Verify consistency yourself, don't just trust the summary

Recently, the economy was restructured: Gold was removed as a separate currency (Overkill is now the only currency, with a small passive trickle as a safety net), and a new optional "Spillage" mechanic was added (certain cards let excess damage carry to the next enemy instead of banking as Overkill). This change was propagated across the game design, balance, data schema, screen composition, icon, audio, art, and user journey docs, and a follow-up sweep already caught and fixed several stale references (a leftover "gold" field in the save schema, a stale currency mention in the deck-view removal flow, and a stale event-reward example). Do your own pass anyway — search across all files for "gold" (case-insensitive) and for "spillover" (the old, discarded name for the mechanic — the correct current term is "Spillage") to catch anything that slipped through. Also check that every cross-reference between docs (e.g., "see balance doc Section 5") actually points to a section that exists with that number in the current version of that file — section numbers may have shifted during edits.

## Step 3 — Evaluate the design itself, not just the documents

Beyond internal consistency, form your own view: does the Overkill/Spillage/Excess-tier system hang together as a coherent, implementable game? Specifically check:
- Does the combat resolution order (data schema doc, Part 1.6) fully and unambiguously cover every case a real combat implementation will hit — Block, AOE, DOT, and Spillage interacting with each other?
- Is there anything the targeting/preview spec doesn't account for that the Spillage mechanic now requires (it needs to communicate two possible outcomes per card — bank vs. spill — not just one)?
- Are there any remaining design decisions marked as open, deferred, or "needs playtesting" that would actually block a first playable vertical slice, versus ones that can genuinely wait?

Flag anything you find before writing any code.

## Step 4 — Organize the folder

Once you're confident in your understanding: reorganize these files sensibly (a logical folder/naming structure, not necessarily the flat list they currently exist as), and remove or merge anything genuinely redundant or superseded — but only if you can point to specifically what makes it redundant. Do not delete anything just because it looks similar to another file; several of these docs intentionally cross-reference each other without duplicating content. If you're unsure whether something is safe to remove, keep it and flag it for a human decision instead of deleting it.

## Step 5 — Report back

Before starting any implementation, give a summary of: what you found and fixed in Step 2, your honest evaluation from Step 3, and what the folder looks like after Step 4. Wait for confirmation before beginning actual game implementation.
