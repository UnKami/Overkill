# CLAUDE.md — Claude Code Context & Instructions

This repository is **Overkill**, a tactical roguelite deckbuilder built in Godot 4.

## Primary Documentation & Instructions
Please read [AGENTS.md](AGENTS.md) for full project architecture, engine conventions, and mandatory multi-AI collaboration rules.

## Core Rules for Claude Code
1. **Never edit files without checking [ACTIVE_WORK.md](ACTIVE_WORK.md)**. If your partner's AI is working on files, do not touch them.
2. **Never push directly to `main`**. Use feature branches (`feat/partner-<feature>`).
3. **Always update [CHANGELOG_AI.md](CHANGELOG_AI.md)** at the end of every work session with handoff notes.
4. **Godot 4 Typed GDScript**: All scripts in `scripts/` must use strict type annotations (`var x: int = 0`, `func foo() -> void:`).
5. **Componentization**: Never create monolithic scenes. Break UI and combat elements into small, reusable sub-scenes.
