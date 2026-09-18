---
name: overkill-dev
description: >-
  Expert guidance for developing the Overkill game in Godot 4. Use when creating or modifying
  combat systems, dual-chronometer presentation, card resources, relics, enemies, UI screens,
  or coordinating collaborative features with partner AI assistants.
---

# Overkill Game Development Skill

This skill guides development on **Overkill**, a deterministic tactical roguelite deckbuilder in Godot 4.

## Core Rules & Design Principles

1. **Dual-Chronometer Mechanics**:
   - The combat arena is circular with 12 distinct hour slots.
   - Relics placed on sockets act as deterministic program instructions.
   - Turns execute in sequence without traditional mana or manual "End Turn" buttons.

2. **The Overkill Currency & Spillage**:
   - Excess damage dealt beyond a target's lethal threshold is converted 1:1 into Overkill Points.
   - When cards have the `Spillage` keyword, excess damage rolls forward into the next alive enemy in line instead of banking as Overkill.

3. **Autoload Access**:
   - Access singletons directly by name: `RunManager`, `GameFlow`, `ContentDatabase`, `SaveManager`, `AudioManager`.
   - Never re-instantiate or duplicate autoload classes.

4. **Resource Management**:
   - Cards are stored as `.tres` resources in `data/cards/`.
   - Relics are stored in `data/relics/`.
   - Enemies and bosses are in `data/enemies/`.
   - Always verify that all card/relic resources match the typed properties defined in `scripts/data/`.

5. **Collaboration Protocols**:
   - Inspect `ACTIVE_WORK.md` before claiming or modifying files.
   - Document changes upon session conclusion in `CHANGELOG_AI.md`.
