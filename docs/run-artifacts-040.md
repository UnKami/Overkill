# Run-wide Artifacts — v0.40

Artifacts are unique passive objects carried for the entire run. They are deliberately separate from the twelve-copy Chronometer roster: buying one never occupies an hour, replaces a bound relic, or changes the nine active sockets. The Clockwright offers three unowned Artifacts per visit; one may be purchased for 30 Overkill, with the existing per-run `run_artifact` price escalation applied to later shop visits. Each Artifact is unique by ID.

| Artifact | Essence | Trigger | Effect |
|---|---|---|---|
| Aegis Seed | Blue / Block | Battle start | Gain 8 persistent Block once per battle. |
| Ashen Ledger | Blood red / Overkill | Overkill of 8+ | Gain 5 Overkill on the first qualifying hit per battle. |
| Deepwell Suture | Purple / Buff | Kill, with at least 12 missing Vitality | Restore 12 Vitality on the first eligible kill per battle. |
| Verdigris Thorn | Green / Debuff | Battle start | Apply 1 Weak to the opening enemy once per battle. |

These four are shop-only. They are excluded from ordinary treasure relic pools and remain persisted through `RunManager.relics_held` in the existing save schema. The three legacy passive relics remain compatible. The new HEAL effect uses a capped Vitality restore; numeric enum values already serialized by existing content remain unchanged because HEAL is appended to the enum.

## Art and motion

Four original transparent object illustrations use a varied material/silhouette language under the current painterly-real crystalline-magitech canon. Each is a distinct physical object rather than a recolored crystal: the Aegis Seed is an ivory-and-obsidian shell around a cobalt core; the Ashen Ledger is a split dark seal around a suspended blood-red shard; the Deepwell Suture is a silver-and-ivory vessel containing a violet spring; the Verdigris Thorn is a bone-and-obsidian hooked growth around a green core. No lettering, scenery, or card frame is baked into the art.

Assets: `assets/relics/run_wide/aegis_seed.png`, `ashen_ledger.png`, `deepwell_suture.png`, and `verdigris_thorn.png`. Each is shown in the Clockwright with its matching essence sunburst, slow object bob, and restrained aura pulse (disabled when reduced motion is enabled). The shop labels the Artifact shelf separately from active Chronometer relics and spells out its run-wide/socket-free role. Carried Artifacts also appear as icon-first clickable objects in the battle HUD with hover/click rules and a short trigger flash.

## Image generation direction

Generated with the built-in ImageGen tool and the active Overkill visual canon. Shared constraints: one centered, premium, high-detail 3D-rendered relic object; transparent square canvas; silhouette occupying about 60–80% of the frame; no text, card border, hand, character, or environment. Object-specific prompt direction: (1) protective seed/pod with fractured ivory ceramic armor, dark meteorite segments, and a bright cobalt core; (2) suspended red shard held in a broken obsidian seal, hot blood-red fissures, restrained silver details; (3) elegant narrow vitality ampoule with ivory ribs, polished silver fittings, and a contained violet luminous spring; (4) hooked thorn/crescent grown from pale bone and dark stone around a vivid emerald core. The mechanic color remains dominant in each object.

## Balance and verification intent

The starter Guard Plate rises from 5 to 7 Block and Reinforced Wall from 8 to 10. This is a deliberately small increase: Block persists across ticks, and the goal is to make blue choices relevant earlier without turning the five-copy defensive starter into a one-pick wall. Encounter outcomes still require human playtesting. The automated Artifact test covers data registration, art alpha, uniqueness, save/load, shop purchase and one-per-visit behavior, twelve-slot separation, and the four combat triggers.
