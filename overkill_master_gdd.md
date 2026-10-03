> **0.14 playtest rules (2026-09-19) supersede the historical 12-hour baseline below:** nine sockets, three sectors of three hours, twelve starter relics (5 × 6-damage attacks, 5 × 5-Block guards, one 3-damage lifesteal, one 4-damage next-attack ×2 relic). Enemy actions reveal before placement and stay visible. See [current rules and edge cases](docs/presentation-014.md). Historical design sections remain for reference, not current runtime behavior.

# TECHNICAL DESIGN & ARCHITECTURAL SPECIFICATION: OVERKILL
**Document Version:** 1.0.0-PROD  
**System Architecture:** Dual-Chronometer Relic Engine & Overkill Run Economy  
**Target Environments:** Modular Web / HTML5 Canvas / WebGL (Three.js / PixiJS) / Godot / Unity C# Engine Architecture  
**Replaces:** Slay the Spire-style card hands, mana/energy action systems, and discard deck combat loops.

---

## 1. EXECUTIVE SUMMARY & DESIGN PHILOSOPHY

*Overkill* is a deterministic, fast-paced tactical roguelite engine. It eliminates traditional card-game tropes—such as random hand draws, turn energy quotas, and manual "End Turn" button clicks—in favor of a programmatic, circular combat arena known as the **Dual-Chronometer Battle Engine**.

### 1.1 Core Tenets
1. **Relics are Active Instructions:** The player’s entire deck consists of physical relics (Gears, Springs, Batteries, Striking Pistons) slotted into a 12-hour circular array.
2. **Zero-Latency Turn Commits:** Every player decision (slotting a relic in Phase 1 or hot-swapping a relic in Phase 2) immediately locks the mechanism, advances the chronometer hand, and executes the clash.
3. **The Overkill Conversion Principle:** Excess damage dealt beyond a target's lethal threshold is converted directly into **Overkill Points** (1:1 conversion ratio), serving as the universal currency for elite meta-progression, relic ascensions, and run-defining Zenith components.

---

## 2. STATE MACHINE & COMBAT LOOP ARCHITECTURE

Combat is governed by an asymmetric two-phase state machine that shifts from an **Assembly Cycle** (Turns 1–12) into a **Quadrant Engine** (Turns 13+).

```
                      ┌────────────────────────────────────────┐
                      │             BATTLE_START               │
                      │ Initialize Player & Enemy Chronometers │
                      └───────────────────┬────────────────────┘
                                          │
                                          ▼
                      ┌────────────────────────────────────────┐
                      │         PHASE 1: ASSEMBLY CYCLE        │
                      │             (Turns 1 to 12)            │
                      └───────────────────┬────────────────────┘
                                          │
            ┌─────────────────────────────┴─────────────────────────────┐
            ▼                                                           ▼
┌───────────────────────────────┐                           ┌───────────────────────────────┐
│     PLAYER TURN (Hour N)      │                           │      EXECUTION (Hour N)       │
│ - Offer 3 Relics from Draw    │ ─── [Slot Relic N] ─────> │ - Hand snaps to Hour N        │
│ - Unchosen shuffle to Draw    │                           │ - Player N vs Enemy N Clash   │
│ - Sockets lock immediately    │                           │ - Overkill Banking check      │
└───────────────────────────────┘                           └───────────────┬───────────────┘
                                                                            │
                                    ┌─── [Hour N < 12: Advance Turn] ───────┘
                                    │
                                    └─── [Hour N == 12: Transition] ────────┐
                                                                            │
                                                                            ▼
                                                            ┌───────────────────────────────┐
                                                            │   PHASE 2: QUADRANT ENGINE    │
                                                            │          (Turns 13+)          │
                                                            └───────────────┬───────────────┘
                                                                            │
            ┌───────────────────────────────────────────────────────────────┴───────────────────────────┐
            ▼                                                                                           ▼
┌──────────────────────────────────────────┐                                            ┌───────────────────────────────┐
│         PLAYER TURN (Quadrant Q)         │                                            │     EXECUTION (Quadrant Q)    │
│ - Identify Active 3-Hour Wedge           │                                            │ - Hand sweeps all 3 hours     │
│ - Draw 1 Relic from remaining Deck       │ ─── [Drop on Socket OR Skip/Discard] ────> │ - Tick A -> Tick B -> Tick C  │
│ - Option A: Hot-Swap into Quadrant Slot  │                                            │ - Overkill Banking check      │
│ - Option B: Skip (Convert to Surge Bank) │                                            │ - Increment Quadrant (Q1->Q4) │
└──────────────────────────────────────────┘                                            └───────────────┬───────────────┘
                                                                                                        │
                                            └──────────────── [Loop Quadrants until Victory/Defeat] ────┘
```

---

## 3. CHRONOMETER GEOMETRY & QUADRANT TAXONOMY

The battlefield consists of two interactive circular dials: the **Player Chronometer** (Left) and the **Enemy Chronometer** (Right).

```
                      PLAYER CLOCK                              ENEMY CLOCK
                         [ 12 ]                                    [ 12 ]
                     [11]      [1]                             [11]  ⚡   [1]
                   [10]    ▲     [2]                         [10] 🔒     🔒  [2]
                  [9]    ◄─┼─►   [3]       CLASH NEXUS      [9]     ▲     [3]
                   [8]     ▼     [4]    ◄───────────────►    [8] 🔒  │ 🔒  [4]
                     [7]       [5]                             [7]   ▼   [5]
                         [ 6 ]                                     [ 6 ]
```

### 3.1 Quadrant Breakdown (Phase 2)
The 12 hours are partitioned into 4 tactical quadrants:

* **Quadrant 1 (Hours 1:00, 2:00, 3:00) — Priming & Foundations:**
  * Ideal for vulnerability primers, base shielding, and recurring strength multipliers.
* **Quadrant 2 (Hours 4:00, 5:00, 6:00) — Escalation & Sustain:**
  * Focuses on sustain engines, armor conversion, and multi-hit scaling.
* **Quadrant 3 (Hours 7:00, 8:00, 9:00) — High Pressure & Mitigation:**
  * Counters elite spike turns and prepares finishing damage multipliers.
* **Quadrant 4 (Hours 10:00, 11:00, 12:00) — Finisher & Overkill Climax:**
  * Houses massive single-hit impact relics to harvest huge Overkill point pools.

---

## 4. MATHEMATICAL RESOLUTION & CLASH LOGIC

Resolution occurs on a per-tick basis. When the chronometer hand enters a target hour, actions resolve using deterministic priority logic.

### 4.1 Step-by-Step Tick Resolution Pipeline
```
[TICK FIRES]
    │
    ▼
1. RESOLVE DEFENSES & STATUS EFFECTS
   - Apply incoming Block/Shield to target entity.
   - Increment/Decrement Buffs (Strength, Dexterity, Fortify).
   - Apply Debuffs (Vulnerable: +50% incoming dmg; Weak: -25% outgoing dmg; Bleed).
    │
    ▼
2. RESOLVE ATTACK CLASHES
   - Calculate Effective Outgoing Damage:
     D_out = (D_base + Strength) * Mult_Vulnerable * Mult_Weak
   - Apply Damage to Opposing Block first:
     Remaining_Block = Max(0, Current_Block - D_out)
     Unblocked_Damage = Max(0, D_out - Current_Block)
   - Apply Unblocked Damage to Target HP:
     New_HP = Target_HP - Unblocked_Damage
    │
    ▼
3. CHECK OVERKILL THRESHOLD
   - If New_HP <= 0:
     Overkill_Points = Absolute(New_HP)
     Run_Bank_Overkill += Overkill_Points
     Trigger Target Death State
    │
    ▼
4. UPDATE ENTITY TELEMETRY & PERSISTENCE
   - Decrement transient status timers.
   - Retain residual Block (unless Decay rule is active).
```

### 4.2 Formal Damage Formulas
* **Base Attack Calculation:**
  $$D_{	ext{effective}} = \max\left(0, (D_{	ext{base}} + 	ext{Strength}) 	imes (1 + 0.5 \cdot \mathbb{I}_{	ext{Vulnerable}}) 	imes (1 - 0.25 \cdot \mathbb{I}_{	ext{Weak}})ight)$$
* **Overkill Point Calculation:**
  $$	ext{Overkill} = egin{cases} D_{	ext{unblocked}} - 	ext{HP}_{	ext{current}}, & 	ext{if } D_{	ext{unblocked}} > 	ext{HP}_{	ext{current}} \ 0, & 	ext{otherwise} \end{cases}$$

---

## 5. STARTER DECK AND EXPANSION POOL

New runs begin with 16 physical relic copies: 6 Iron Strikes (6 damage), 6 Guard Plates (6 Block), 2 Twin Blades (4 damage twice), and 2 Reinforced Walls (8 Block). Unused Block persists across ticks and quadrants until absorbed; it resets when a new battle starts. Each copy can be upgraded independently. The remaining catalog introduces more varied effects through rewards and shops. Existing saved inventories are retained.

Catalog (only the four types above are in the starting inventory):

| ID | Relic Name | Role | Base Effect | Synergistic Optimal Slot |
| :--- | :--- | :--- | :--- | :--- |
| `REL-01` | **Iron Strike** | Impact | Deal 6 Physical Damage. | Sockets 1, 4, 7 |
| `REL-02` | **Twin Blades** | Impact | Deal 4 Physical Damage twice (8 total). | Sockets 2, 5, 8 (Post-Strength) |
| `REL-03` | **Heavy Hammer** | Impact | Deal 14 Physical Damage. | Sockets 3, 6, 9, 12 (Finishers) |
| `REL-04` | **Guard Plate** | Bulwark | Gain 6 Block. | Sockets 1, 2, 4 |
| `REL-05` | **Spiked Buckler** | Bulwark | Gain 4 Block. Deal 4 Thorns on enemy attack. | Sockets facing enemy multi-attacks |
| `REL-06` | **Reinforced Wall** | Bulwark | Gain 8 Block. | Sockets facing boss heavy cleaves |
| `REL-07` | **Rusting Spike** | Tempo | Deal 3 Damage; apply 2 Vulnerable. | Sockets 1, 4, 7, 10 (Quadrant Leads) |
| `REL-08` | **Momentum Spring** | Tempo | Gain +2 Strength for the remainder of this sweep. | Sockets 1, 4, 7, 10 |
| `REL-09` | **Corrosive Oil** | Tempo | Apply 3 Bleed (Deals true damage per action). | Sockets 1, 2, 3 |
| `REL-10` | **Kinetic Battery** | Breaker | Gain 4 Block. Next attack deals +4 Damage. | Sockets 2, 5, 8, 11 |
| `REL-11` | **Execution Wedge** | Breaker | Deal 8 Damage. If Target HP <= 50%, deal 14. | Sockets 3, 6, 9, 12 |
| `REL-12` | **Recoil Piston** | Breaker | Deal 5 Damage. Gain Block equal to Overkill dealt. | Sockets 3, 6, 9, 12 |

---

## 6. ENEMY BEHAVIOR, ELITE MODIFIERS & BOSS DIALS

### 6.1 Standard Enemy Telegraphing
* Hallway enemies display their entire 12-hour action layout from Turn 1.
* Actions are fixed or cyclical (e.g., Slime: `[Block 4] -> [Attack 5] -> [Attack 12]`, repeating across all 4 quadrants).

### 6.2 Elite Modifiers (Board Manipulation)
Elites modify the mechanical integrity of the player's Chronometer:

* **Locked Sockets (`🔒`):** Seals specific hours (e.g., Hours 4 & 9). Players cannot place relics there during Phase 1, and cannot hot-swap them during Phase 2.
* **Hazard Sockets (`💀`):** If an offensive relic triggers in this slot, the player suffers 50% recoil damage.
* **Overdrive Siphons (`⚡`):** Any unblocked damage dealt by the elite drains 25% of the player's banked Overkill Points directly from their run inventory.

### 6.3 Boss Encounter Architecture
Bosses break symmetrical 1:1 rotation rules via multi-hand mechanisms:

```
                    BOSS: THE CHRONO-LEVIATHAN
                              [ 12 ]
                          [11]      [1]  ───► Hand A (Minute Hand: Fast 1h/tick)
                        [10]    ▲     [2]
                       [9]    ◄─┼─►   [3] ───► Hand B (Hour Hand: Heavy 3h/sweep)
                        [8]     ▼     [4]
                          [7]       [5]
                              [ 6 ]
```

* **Type A: Twin-Hand Tyrant:**
  * *Minute Hand:* Advances 1 hour per turn, dealing light tactical strikes (4–8 damage).
  * *Hour Hand:* Advances 1 quadrant (3 hours) every 3 turns, releasing a 40+ damage mega-cleave at 3:00, 6:00, 9:00, and 12:00.
* **Type B: Reverse Gear (Inverted Clocks):**
  * Player sweeps clockwise ($1 ightarrow 2 ightarrow 3$), Boss sweeps counter-clockwise ($12 ightarrow 11 ightarrow 10$).
  * Forces players to weather the Boss’s ultimate finisher at Turn 1, then out-scale its decaying strength.
* **Type C: Multi-Dial Chimera:**
  * Three separate 4-hour dials (Attack Dial, Shield Dial, Debuff Dial) rotating independently at different speeds.

---

## 7. OVERKILL RUN ECONOMY & ZENITH-GRADE RELICS

Overkill Points replace standard currency (Gold) across all world map nodes.

```
                    ┌───────────────────────────────┐
                    │      OVERKILL POINT BANK      │
                    │       (Excess Damage)         │
                    └───────────────┬───────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          ▼                         ▼                         ▼
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│ CLOCKWORK FORGE   │     │  BLACK SHRINES    │     │ SOCKET INFUSIONS  │
│ - Upgrade: Base+  │     │ - Zenith Relics   │     │ - Hour 12: x3 PWR │
│ - Strip Base Cogs │     │ - Cursed Relics   │     │ - Hour 1: Free Stk│
└───────────────────┘     └───────────────────┘     └───────────────────┘
```

### 7.1 Zenith-Tier Relic Catalog
Zenith relics possess game-warping abilities purchasable only with high Overkill reserves:

* **The Ouroboros Cog (Zenith):** When Hour 12 resolves in Phase 2, instantly re-trigger the entire Quadrant 1 (Hours 1–3) in the same turn.
* **Chrono-Shatter Core (Zenith):** Landing an Overkill kill causes all remaining hours in the active quadrant to execute twice.
* **Temporal Singularity (Zenith):** Copies the effects of all 3 previous hours and combines them into an amplified burst on the current hour.
* **Paradox Battery (Zenith):** Converts all excess Block at the end of a quadrant sweep into true damage distributed across all enemies.

---

## 8. COMBAT UI, HUD & MOTION SPECIFICATION

```
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ [TOP]  HP: [████████░░] 68/80  |  BLOCK: [🛡️ 12]  |  OVERKILL: [⚡ 340 PTS]  |  ACT: 1-4     │
├────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                            │
│       PLAYER CHRONOMETER (Left)                       ENEMY CHRONOMETER (Right)            │
│                 [ 12 ]                                          [ 12 ]                     │
│            [11]   │    [ 1 ]                               [11]   │    [ 1 ]               │
│         [10]      │       [ 2 ]                         [10]      │       [ 2 ]            │
│        [ 9 ] ─────┼─────> [ 3 ] ── CLASH NEXUS ── <─────  [ 9 ] <───┼─────  [ 3 ]            │
│         [ 8 ]     │       [ 4 ]    (Impact FX)          [ 8 ]     │       [ 4 ]            │
│            [ 7 ]  │    [ 5 ]                               [ 7 ]  │    [ 5 ]               │
│                 [ 6 ]                                           [ 6 ]                      │
│                                                                                            │
│         [ Active Quadrant Glow ]                        [ Enemy Hazard / Intent Badges ]   │
│                                                                                            │
├────────────────────────────────────────────────────────────────────────────────────────────┤
│ [DOCK] Phase 1: [ RELIC A ] [ RELIC B ] [ RELIC C ]                                        │
│        Phase 2: [ DRAWN RELIC ]  ──►  [ SKIP & CONVERT ]      DECK: [24]   DISCARD: [6]    │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

The current battle UI replaces the dock above with a floating choice overlay. Assembly shows three relics and the numbered destination; quadrant turns show the drawn relic and three replacement destinations plus Keep & Sweep. The relevant clock slots pulse before selection. The overlay disappears during binding and resolution, and the arena retains its full height.

### 8.1 Animation & Cadence Blueprint
* **Input Lock-In:** Dragging or clicking a relic to a socket triggers an iron latch sound effect and cog-locking animation ($< 0.05	ext{s}$).
* **Phase 1 Cadence:** Clock hand snaps to Hour $N$ ($0.12	ext{s}$), clash resolves ($0.20	ext{s}$), total turn duration $\sim 0.35	ext{s}$.
* **Phase 2 Cadence:** Active quadrant illuminates; hand executes a rapid **"Tick-Tick-SLAM"** sequence across all 3 hours ($0.50	ext{s}$ total execution).
* **Overkill Payout Effect:** A lethal blow triggering Overkill introduces a 4-frame hit-stop, generates floating gold numbers (`+18 OVERKILL!`), and streams golden particle trails into the top HUD counter accompanied by a metallic coin chime.

---

## 9. CODE DATA STRUCTURES & SCHEMAS (JSON / TYPESCRIPT)

Below are the foundational data schemas required to instantiate and execute the *Overkill* combat engine:

```typescript
// Core Relic Interface
export interface Relic {
  id: string;
  name: string;
  tier: 'Starter' | 'Common' | 'Rare' | 'Zenith';
  role: 'Impact' | 'Bulwark' | 'Tempo' | 'Breaker';
  description: string;
  baseStats: {
    damage?: number;
    hits?: number;
    block?: number;
    strength?: number;
    vulnerable?: number;
    weak?: number;
    bleed?: number;
    thorns?: number;
  };
  onClash?: (context: ClashContext) => void;
  onOverkill?: (overkillAmount: number, context: ClashContext) => void;
}

// Chronometer Socket Model
export interface ClockSocket {
  hour: number; // 1 to 12
  isLocked: boolean; // Elite Rust modifier
  isHazard: boolean; // Elite Recoil modifier
  isSiphon: boolean; // Elite Overkill drain modifier
  enchantmentMultiplier: number; // Socket Infusion buff (e.g. 1.0, 2.0, 3.0)
  slottedRelic: Relic | null;
}

// Combat State Manager Interface
export interface CombatState {
  currentTurn: number;
  phase: 'ASSEMBLY' | 'QUADRANT';
  activeHour: number; // 1 to 12
  activeQuadrant: 1 | 2 | 3 | 4;
  playerHP: number;
  playerMaxHP: number;
  playerBlock: number;
  enemyHP: number;
  enemyMaxHP: number;
  enemyBlock: number;
  bankedOverkillPoints: number;
  playerDeck: Relic[];
  playerDiscard: Relic[];
  playerChronometer: ClockSocket[];
  enemyChronometer: ClockSocket[];
}
```
