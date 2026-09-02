# OVERKILL — Starting Numbers & Balance Baseline (v1)

Every number in this document is a **first-pass baseline, not a final balance pass** — it exists so Claude Code has concrete values to build the systems against instead of placeholder zeros. Expect all of it to move during playtesting. What should *not* move without a deliberate decision is the underlying design intent behind each number (noted inline), since that's what the number is protecting.

---

## 1. Player baseline

| Stat | Value | Notes |
|---|---|---|
| Starting HP | 75 | In line with StS's Ironclad (80) — slightly lower since Overkill's aggression-rewarding loop should feel a touch riskier by default |
| Energy per turn | 3 | Standard deckbuilder baseline; do not deviate without a specific class identity reason |
| Hand size drawn per turn | 5 | |
| Starting deck size | 10 cards | 5 basic attacks, 4 basic defends, 1 class-specific starter card |
| Max deck size (soft target by run's end) | ~25-30 cards | Beyond this, card draw consistency degrades sharply — a natural upper bound, not a hard cap |

**Starting deck damage/block baseline** (per class's basic Strike/Defend equivalents):
- Basic attack: 1 cost, 6-8 damage
- Basic defend: 1 cost, 5-6 block

---

## 2. Card cost/effect baselines by rarity

These are anchor points for content generation — new cards should be checked against these ranges, not designed in a vacuum.

| Rarity | Cost range | Attack damage range (per cost point) | Design note |
|---|---|---|---|
| Common | 0-2 | ~6-9 dmg per cost point | Efficient, low-variance, the "volume" archetype's bread and butter |
| Uncommon | 1-3 | ~7-10 dmg per cost point, plus one conditional/utility effect | Slight power increase justified by an added condition or secondary effect |
| Rare | 1-3, or X-cost | Higher variance — burst finishers can spike to 15-20+ dmg per cost point in exchange for a drawback or setup requirement | This is where "burst" archetype cards should cluster |
| Excess | 2-3, or X-cost | Highest ceiling in the game, explicitly OK-scaling per the gated-card design | Locked until threshold met (Section 4) — should feel clearly stronger than Rare when unlocked, since the unlock itself is a cost |

**X-cost finishers** (Zero Sum-style cards from the original design doc): baseline 4 damage per X, since these are meant to be built around rather than efficient by default.

---

## 3. Enemy HP curves

HP bands are deliberately **wide within a tier**, not tight — a wide range is what creates natural overkill opportunities (a low-roll trash enemy dies to a normal hit with excess; a high-roll one takes the full hit cleanly). A narrow band collapses the "should I overkill this one" decision into a non-decision.

| Act | Trash HP range | Elite HP range | Boss HP range |
|---|---|---|---|
| Act 1 | 8-24 | 45-60 | 150-200 |
| Act 2 | 20-40 | 65-85 | 220-280 |
| Act 3 | 35-55 | 90-115 | 300-380 |

Final boss (post-Act 3, per the original design doc's "capstone" note): 400-550 HP, with the phase-gate/damage-cap mechanics flagged in the game design doc to prevent trivial one-shot overkill on a boss this large.

**Design intent to protect**: the low end of each trash band should be comfortably killable in one hit by a baseline attack card *with room to overshoot* — if a player's basic Strike-equivalent (6-8 dmg) can't ever overkill the lowest-HP trash in Act 1, the Volume archetype has no floor to stand on. Playtest this specifically, not just average-case balance.

**Encounter composition per act** (baseline, matches the art doc's asset-count estimate): ~8-10 regular combats, 2-3 elites, 1 boss.

---

## 4. Excess-tier unlock thresholds

Carried over from the original game design doc, now as concrete numbers:

| Act | Single-hit OK threshold to unlock Excess-tier cards |
|---|---|
| Act 1 | 20 |
| Act 2 | 35 |
| Act 3 | 60 |
| Final boss / Act 4 equivalent | 90 |

These should scale per-class if playtesting shows some classes naturally generate higher single-hit OK than others (a Burst-archetype class will clear these faster than a Volume-archetype class by default) — if that gap is large, consider per-class threshold variants rather than nerfing a class's natural identity to fit a universal number.

---

## 5. Overkill (OK) — the single currency

Gold has been dropped as a separate currency; OK now covers everything Gold previously did (relics, potions) in addition to cards and upgrades. One economy, one number to track and optimize around.

### 5.1 Passive trickle (safety net)

To keep a rough combat stretch from leaving a player with nothing to spend, a small flat amount of OK is granted independent of overkill performance:

| Source | Flat OK amount |
|---|---|
| Per-combat baseline (awarded regardless of overkill quality) | Act 1: +2 / Act 2: +4 / Act 3: +6 |
| Treasure node | 20-40 flat |

This is a floor, not a real income source — it should never come close to the totals a well-played fight generates through actual overkill. If playtesting shows players leaning on the trickle more than genuine overkill income, the trickle is too generous and should shrink, not the other way around.

### 5.2 Pricing formula

**Formula**: `price = base_price × (1.15 ^ purchases_already_made_this_run_in_that_category)`, as established in the original design doc's anti-inflation guardrail. Track the exponent separately per category (card upgrades, card purchases, relics, potions) so buying a lot in one category doesn't also inflate the others.

| Action | Base price (OK) |
|---|---|
| Upgrade a Common card | 15 |
| Upgrade an Uncommon card | 25 |
| Upgrade a Rare card | 40 |
| Buy a new Common card (shop) | 20 |
| Buy a new Uncommon card (shop) | 35 |
| Buy a new Rare card (shop) | 55 |
| Buy a new Excess-tier card (post-unlock) | 80 |
| Relic (shop) | 150-300 |
| Potion (shop) | 20-50 |
| Card removal service | 75-150, scaling up per removal this run |
| Smelt (sacrifice) a card for partial OK refund | Common: 10 / Uncommon: 15 / Rare: 25 flat refund, no scaling |

**Note**: the post-combat card reward screen is never priced — pick freely, per the updated game design doc's Section 3. Everything in the table above is a deliberate shop/rest-site spend, not something charged automatically when a reward is handed to the player.

**Playtesting target**: a reasonably-played run should have enough OK to make roughly 2-4 real purchases per act (upgrade, new card, relic, or potion combined), not enough to buy everything offered. Since a much wider range of things now compete for the same pool of OK than before, this ratio needs closer attention than it did under the two-currency split — if players are consistently capped out with unspent OK by Act 2, either enemy HP bands need tightening or prices need to rise faster; if players can never afford anything, loosen HP bands or lower base prices. This is the single most important ratio to tune first, since it governs whether OK feels like a real economy or free currency.

---

## 6. Act pacing

| Act | Node count (approx.) |
|---|---|
| Act 1 | 16-17 |
| Act 2 | 16-17 |
| Act 3 | 16-17 |

Matches the StS-standard node density. Node type distribution within an act (combat/elite/rest/shop/event/treasure ratios) is a map-generation question, not covered here — flagged as one of the still-open items from the last planning pass if you want it specced next.

---

## 7. Difficulty scaling (Ascension-equivalent, if included at launch)

Per the original design doc's guidance to scale difficulty *on-theme* rather than just raising enemy stats:

| Lever | Baseline effect per difficulty tier |
|---|---|
| OK generation multiplier | -10% per tier (e.g., a hit that would generate 20 OK generates 18 at tier 1, 16 at tier 2) |
| Excess-tier thresholds | +10-15% per tier |
| Enemy HP | Standard StS-style modest increase (+5-10% per tier), kept secondary to the two levers above so difficulty scaling reinforces the game's actual theme instead of just being "enemies have more HP" |

---

## 8. What still needs a real playtest pass before trusting these numbers

- Whether the Act 1 trash HP floor (8) is too low and makes some kills feel trivial rather than satisfying
- Whether the OK pricing curve's exponent (1.15) creates a "cliff" where prices spike too fast by late Act 2
- Whether Burst-archetype classes clear Excess thresholds so much faster than Volume-archetype classes that per-class threshold tuning becomes mandatory rather than optional
- Boss HP bands against actual player damage output at the point a boss is reached — this can only be verified once real combat exists, not from these numbers alone
