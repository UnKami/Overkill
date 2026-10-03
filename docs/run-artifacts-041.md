# Run-wide Artifacts — v0.41 expansion

The Clockwright now has eight unique Run-wide Artifacts, still separate from
the fixed twelve-copy Chronometer roster. The shop offers three unowned items
from this pool, and one may be bought per visit. The effects are once per
battle; purchasing one neither consumes a clock socket nor changes battle
damage, clock order, or the ordinary relic reward pool.

| Artifact | Hue | Trigger | Effect |
|---|---|---|---|
| Aegis Seed | Blue | Battle start | Gain 8 persistent Block. |
| Ashen Ledger | Blood red | Overkill of 8+ | Gain 5 Overkill on the first qualifying hit. |
| Deepwell Suture | Purple | First kill with at least 12 missing Vitality | Restore 12 Vitality. |
| Verdigris Thorn | Green | Battle start | Apply 1 Weak to the opening foe. |
| Cinder Dial | Orange | First player attack | Add 4 damage to the first strike. |
| Tideward Clapper | Blue | A bound Block relic activates | Restore up to 6 missing Vitality. |
| Violet Weaver's Shuttle | Purple | First kill | Gain 2 Strength. |
| Gloam Moth | Green | First time the player loses Vitality to a hit | The foe's next strike is weakened. |

## Signature activation language

Each carried Artifact remains represented by its own HUD icon. On activation,
its illustrated object leaves that icon, follows three fine essence-colored
light strokes into the affected combatant, and resolves with an effect-family
impact: shield flare for Block, slash plus sparks for attack/status effects,
vitality glimmer for healing, and a stronger body pulse for Strength. Impact
size scales with effect magnitude within readability limits. All motion is
non-blocking presentation; effect resolution stays synchronous with the
deterministic clock step. Reduced-motion settings keep the direct effect
feedback and omit the traveling object.

## Data compatibility

New serialized `RelicData.Trigger` and `EffectData.EffectType` values are
appended to their enums; no existing ordinal changes. The attack bonus joins
the regular next-hit calculation and is retained for conditional strike
damage. The Gloam Moth adds one decay cushion because its reactive trigger is
after a hit; the resulting one Weak step then reduces the following foe
strike. The Clapper listens only to block gained from a bound clock relic, so
its own Artifact ward cannot recursively trigger it.

Art direction continues the painterly-real magitech canon while varying the
material and silhouette: a brass astrolabe, an ivory warding bell, a silver
thread shuttle, and a bone-and-bronze moth charm. New illustrations are
transparent, with orange, blue, purple, and green hues respectively.

## Verification

`run_artifact_test.tscn` verifies all eight content records and transparent
art, excludes them from ordinary rewards, exercises persistence and purchase,
checks the 12-slot separation, and tests all activation conditions and
once-per-battle limits. This source test is automated evidence, not a human
full-run balance sign-off.
