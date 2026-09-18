# SYSTEM IMPLEMENTATION SPECIFICATION: OVERKILL BATTLE ENGINE
**Module:** `OverkillCombatEngine`  
**Focus:** Concrete Class Interfaces, State Machine Transitions, Tick Resolution Pipeline, and Edge-Case Algorithms  
**Target:** AI Code Assistant / Lead Game Developer

---

## 1. COMPONENT ARCHITECTURE OVERVIEW

The engine decouples mathematical clash resolution from rendering pipelines and UI inputs.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             OverkillGameManager                             │
│  - Tracks active scene, global run inventory, and banked Overkill Points.   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             CombatStateManager                              │
│  - Executes Phase 1 (Turns 1-12) & Phase 2 (Turns 13+) loops.               │
│  - Manages DrawPile, DiscardPile, and ClockSocket arrays.                   │
└──────────────────┬───────────────────────────────────────┬──────────────────┘
                   │                                       │
                   ▼                                       ▼
┌────────────────────────────────────┐   ┌────────────────────────────────────┐
│         PlayerChronometer          │   │          EnemyChronometer          │
│  - 12 ClockSockets                 │   │  - 12 ClockSockets                 │
│  - Active Hand Position            │   │  - Intent / Hazard modifiers       │
│  - Hot-Swap / Selection validator  │   │  - Multi-Hand Boss Controller      │
└──────────────────┬─────────────────┘   └─────────────────┬──────────────────┘
                   │                                       │
                   └───────────────────┬───────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ClashResolutionPipeline                          │
│  - Resolves Step 1 (Defense/Buffs) -> Step 2 (Damage) -> Step 3 (Overkill)  │
│  - Computes exact damage floats, status decay, and Overkill triggers.       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. FULL DATA MODELS & TYPE CONTRACTS

```typescript
export type RelicTier = 'Starter' | 'Common' | 'Rare' | 'Zenith';
export type RelicRole = 'Impact' | 'Bulwark' | 'Tempo' | 'Breaker';
export type BattlePhase = 'ASSEMBLY' | 'QUADRANT' | 'VICTORY' | 'DEFEAT';
export type EnemyArchetype = 'STANDARD' | 'ELITE' | 'BOSS_TWIN_HAND' | 'BOSS_REVERSE';

export interface StatusEffectMap {
  strength: number;     // Flat additive damage to outgoing attacks
  dexterity: number;    // Flat additive block to incoming shields
  vulnerable: number;   // Multiplies incoming damage by 1.5 (duration in ticks)
  weak: number;         // Multiplies outgoing damage by 0.75 (duration in ticks)
  bleed: number;        // Direct unblockable damage executed at tick start
  thorns: number;       // Reflective true damage dealt when struck by an attack
}

export interface Relic {
  id: string;
  name: string;
  tier: RelicTier;
  role: RelicRole;
  description: string;
  baseDamage?: number;
  hits?: number;
  baseBlock?: number;
  applyStrength?: number;
  applyVulnerable?: number;
  applyWeak?: number;
  applyBleed?: number;
  applyThorns?: number;
  onClash?: (source: CombatEntity, target: CombatEntity, context: ClashContext) => void;
  onOverkill?: (overkillAmount: number, source: CombatEntity, target: CombatEntity) => void;
}

export interface ClockSocket {
  hourIndex: number; // 1 to 12
  slottedRelic: Relic | null;
  isLocked: boolean; // Elite modifier: cannot slot or hot-swap
  isHazard: boolean; // Elite modifier: attacker takes 50% recoil
  isSiphon: boolean; // Elite modifier: unblocked dmg drains Overkill Points
  multiplier: number; // Default 1.0 (Zenith socket infusions can be 2.0, 3.0)
}

export interface CombatEntity {
  id: string;
  name: string;
  currentHP: number;
  maxHP: number;
  currentBlock: number;
  statuses: StatusEffectMap;
  chronometer: ClockSocket[];
}

export interface ClashContext {
  turnNumber: number;
  hour: number;
  activeQuadrant: number;
  player: CombatEntity;
  enemy: CombatEntity;
  bankedOverkill: number;
}
```

---

## 3. STATE MACHINE ENGINE (PSEUDOCODE & ALGORITHM)

```typescript
export class CombatEngine {
  public phase: BattlePhase = 'ASSEMBLY';
  public turnNumber: number = 1;
  public activeQuadrant: number = 1;
  public currentDraftSelection: Relic[] = [];
  public currentDrawnRelic: Relic | null = null;
  public playerDeck: Relic[] = [];
  public playerDiscard: Relic[] = [];

  constructor(
    public player: CombatEntity,
    public enemy: CombatEntity,
    public enemyType: EnemyArchetype
  ) {
    this.initializeChronometers();
    this.startPhaseOne();
  }

  private initializeChronometers(): void {
    this.player.chronometer = Array.from({ length: 12 }, (_, i) => ({
      hourIndex: i + 1,
      slottedRelic: null,
      isLocked: false,
      isHazard: false,
      isSiphon: false,
      multiplier: 1.0,
    }));
    // Enemy chronometer initialized by EnemyFactory based on archetype
  }

  // -------------------------------------------------------------
  // PHASE 1: ASSEMBLY CYCLE (Turns 1 - 12)
  // -------------------------------------------------------------
  public startPhaseOne(): void {
    this.phase = 'ASSEMBLY';
    this.turnNumber = 1;
    this.promptPhaseOneDraft();
  }

  private promptPhaseOneDraft(): void {
    // Draw 3 distinct relics from playerDeck
    this.currentDraftSelection = this.drawRelics(3);
    // UI Event: Present 3 Relic Pedestals to player
  }

  public commitPhaseOneRelic(selectedRelicIndex: number): void {
    const selectedRelic = this.currentDraftSelection[selectedRelicIndex];
    const targetHour = this.turnNumber; // 1:00 to 12:00

    // 1. Socket Relic
    this.player.chronometer[targetHour - 1].slottedRelic = selectedRelic;

    // 2. Return unchosen relics to draw pile
    this.currentDraftSelection.forEach((relic, idx) => {
      if (idx !== selectedRelicIndex) this.playerDeck.push(relic);
    });
    this.currentDraftSelection = [];
    this.shuffleDeck();

    // 3. Instant Sweep Resolution for Hour N
    this.resolveTick(targetHour);

    // 4. Check End of Turn / Transition
    if (this.checkCombatEnd()) return;

    if (this.turnNumber < 12) {
      this.turnNumber++;
      this.promptPhaseOneDraft();
    } else {
      this.transitionToPhaseTwo();
    }
  }

  // -------------------------------------------------------------
  // PHASE 2: QUADRANT ENGINE (Turns 13+)
  // -------------------------------------------------------------
  public transitionToPhaseTwo(): void {
    this.phase = 'QUADRANT';
    this.turnNumber = 13;
    this.activeQuadrant = 1;
    this.promptPhaseTwoTurn();
  }

  private promptPhaseTwoTurn(): void {
    this.currentDrawnRelic = this.drawRelics(1)[0] || null;
    // UI Event: Light up 3 active quadrant sockets & show Draw/Skip options
  }

  public commitPhaseTwoHotSwap(targetHourIndex: number): void {
    const quadrantHours = this.getQuadrantHours(this.activeQuadrant);
    if (!quadrantHours.includes(targetHourIndex)) {
      throw new Error("Invalid Socket: Not in active quadrant.");
    }

    const socket = this.player.chronometer[targetHourIndex - 1];
    if (socket.isLocked) {
      throw new Error("Socket is Locked by Elite modifier.");
    }

    // Move old relic to discard, slot new relic
    if (socket.slottedRelic) {
      this.playerDiscard.push(socket.slottedRelic);
    }
    socket.slottedRelic = this.currentDrawnRelic;
    this.currentDrawnRelic = null;

    this.executeQuadrantSweep(this.activeQuadrant);
  }

  public commitPhaseTwoSkip(): void {
    // Discard drawn relic
    if (this.currentDrawnRelic) {
      this.playerDiscard.push(this.currentDrawnRelic);
      this.currentDrawnRelic = null;
    }
    this.executeQuadrantSweep(this.activeQuadrant);
  }

  private executeQuadrantSweep(quadrant: number): void {
    const hours = this.getQuadrantHours(quadrant);
    
    // Sequential 3-Tick Cascade: Hour A -> Hour B -> Hour C
    for (const hour of hours) {
      this.resolveTick(hour);
      if (this.checkCombatEnd()) return;
    }

    // Advance Quadrant (1 -> 2 -> 3 -> 4 -> 1)
    this.activeQuadrant = (this.activeQuadrant % 4) + 1;
    this.turnNumber++;
    this.promptPhaseTwoTurn();
  }

  private getQuadrantHours(q: number): number[] {
    switch (q) {
      case 1: return [1, 2, 3];
      case 2: return [4, 5, 6];
      case 3: return [7, 8, 9];
      case 4: return [10, 11, 12];
      default: return [1, 2, 3];
    }
  }

  // -------------------------------------------------------------
  // CLASH RESOLUTION PIPELINE (Per-Tick Execution)
  // -------------------------------------------------------------
  private resolveTick(hour: number): void {
    const playerSocket = this.player.chronometer[hour - 1];
    const enemySocket = this.enemy.chronometer[hour - 1];

    // 1. Resolve Bleed (Start of tick true damage)
    this.resolveBleed(this.player);
    this.resolveBleed(this.enemy);
    if (this.checkCombatEnd()) return;

    // 2. Resolve Shields & Buffs
    this.applyDefenses(this.player, playerSocket);
    this.applyDefenses(this.enemy, enemySocket);

    // 3. Resolve Attacks
    this.applyAttacks(this.player, this.enemy, playerSocket);
    this.applyAttacks(this.enemy, this.player, enemySocket);

    // 4. Status Decay (Decrement transient multipliers at end of tick)
    this.decrementStatuses(this.player);
    this.decrementStatuses(this.enemy);
  }

  private applyAttacks(source: CombatEntity, target: CombatEntity, socket: ClockSocket): void {
    const relic = socket.slottedRelic;
    if (!relic || !relic.baseDamage) return;

    const hits = relic.hits || 1;
    for (let i = 0; i < hits; i++) {
      let dmg = relic.baseDamage + source.statuses.strength;
      if (target.statuses.vulnerable > 0) dmg *= 1.5;
      if (source.statuses.weak > 0) dmg *= 0.75;
      dmg = Math.floor(dmg * socket.multiplier);

      // Hazard Check
      if (socket.isHazard) {
        source.currentHP -= Math.floor(dmg * 0.5);
      }

      // Shield vs HP subtraction
      if (target.currentBlock >= dmg) {
        target.currentBlock -= dmg;
      } else {
        const remainingDmg = dmg - target.currentBlock;
        target.currentBlock = 0;
        
        if (target.currentHP <= remainingDmg) {
          // OVERKILL TRIGGERED
          const overkillAmount = remainingDmg - target.currentHP;
          target.currentHP = 0;
          this.handleOverkill(overkillAmount, source, relic);
          break;
        } else {
          target.currentHP -= remainingDmg;
        }
      }

      // Thorns counter
      if (target.statuses.thorns > 0) {
        source.currentHP -= target.statuses.thorns;
      }
    }
  }

  private handleOverkill(amount: number, source: CombatEntity, relic: Relic): void {
    if (source === this.player) {
      GlobalRunManager.addOverkillPoints(amount);
    }
    if (relic.onOverkill) {
      relic.onOverkill(amount, source, this.enemy);
    }
  }
}
```

---

## 4. EDGE CASE RESOLUTION MATRIX

| Scenario / Edge Case | Engine Behavior & Truth Table |
| :--- | :--- |
| **Draw pile is empty during Phase 2 draw** | Automatically shuffle `playerDiscard` into `playerDeck` and complete the draw. If both are empty, player plays with current board as-is. |
| **Target dies mid-quadrant sweep** | If minion/boss dies on Hour 1 of 3, remaining hours (2 and 3) immediately convert 100% of their offensive output into bonus Overkill Points. |
| **Simultaneous lethal damage** | Player shields and attacks execute simultaneously with enemy. If both HP reach 0 on the exact same tick, Player Priority takes precedence (Victory if lethal overkill occurred). |
| **Elite Siphon vs Zero Overkill Bank** | Siphon calculates 25% of current banked Overkill Points. If Bank = 0, no negative points are assigned. |
| **Quadrant wrap-around on Hour 12** | At Hour 12 in Phase 2, the sweep finishes Quadrant 4, loops `activeQuadrant = 1`, and prompts Turn 17 on Hour 1. |
