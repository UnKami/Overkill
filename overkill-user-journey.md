# OVERKILL — Complete User Journey

This document walks through everything a player does and sees, screen by screen, from first launch through a full run. Its job is different from the other spec docs: those each nail down one system in isolation (data, icons, screens, numbers); this one proves those systems actually connect into one coherent experience — and surfaces any gap where a moment in the journey doesn't yet have a spec behind it.

Each beat below ends with **[governed by: doc name]** so Claude Code can trace every UI moment back to its authoritative spec. Where a beat has no clean reference, that's flagged explicitly as an open gap.

---

## PART 1 — First-time player journey

### 1. Title screen
Player sees the game logo, a "New Run" option, and (after a first run) "Continue" if a run is in progress. No settings clutter competing for attention on first load.
**[governed by: art requirements doc, Section H — not yet UX-specced beyond art asset list. Minor gap: exact title-screen button layout.]**

### 2. Class select
Player sees the available classes (starting with however many ship at launch) as large character portraits with a one-line identity tag each (e.g., "Burst" or "Volume" flavor described in-fiction, not literally labeled with archetype jargon). Tapping a class shows its starting deck preview and a short flavor blurb before confirming.
**[governed by: art requirements doc Section A for assets; icon system doc Part 2 for the "once per pickup, text is fine" rule applies here — full text is correct on this screen since it's a one-time-per-run decision.]**

### 3. First combat — the mechanic is taught by playing, not by a popup wall
This is the most important sequence in the whole journey, since it's where "Overkill" as a concept has to click without a lecture.

- **Turn 1**: Player sees their hand (5 cards), energy (3/3), and the enemy row. The first enemy has visibly low HP (per the balance doc's wide Act 1 HP band, deliberately weighted toward a low-roll first encounter) and its **intent icon** is already showing above its head — a sword icon with an exact damage number — before the player acts at all.
- Player plays a basic attack card. Damage resolves. **If this specific first hit exceeds the enemy's HP**, the split damage-number system fires for the first time: a gray number for the "needed" damage, then distinctly, an amber number and icon pop for the Overkill generated — timed and sized per the screen composition doc's priority rules (Overkill feedback wins visual priority over everything else happening that instant).
- **A short, dismissible one-line callout appears the very first time OK is generated** — not a blocking tutorial modal, a small anchored text line near the HUD's OK counter (e.g., "Excess damage becomes Overkill — spend it between fights") that fades after a few seconds or on next input. This is the one deliberate exception to "no text popups" — a single first-time moment, never repeated.
- **[gap flagged: this specific "first OK generated" tutorial callout isn't formally specced anywhere yet — it belongs in the onboarding/tutorial doc still on the open list. Everything else in this step is governed by existing docs: screen composition (Part 1.2, 3), icon system (Part 3 intent icons), data schema (Part 2.3 OK feedback).]**

### 4. Combat continues — intents, blocking, status effects introduced organically
As the fight progresses, the player sees a second enemy with a **Defend intent** (shield icon), teaching by contrast that not everything is a damage race. If a card applies a status (e.g., Vulnerable), the status icon appears on the enemy with a stack number, and hovering/tapping it shows the tooltip rendered from the shared template.
**[governed by: icon system doc Part 3 (intents), data schema doc Part 2.5 (status tooltip templates), screen composition Part 3 (tooltip trigger/timing).]**

### 5. Combat ends — victory screen
HP/Block reset for next combat, but the OK counter persists visibly — the number doesn't reset to zero, reinforcing (without text) that this currency is different from anything else in the fight.
**[governed by: screen composition Part 5 — persistent elements never reset/relocate across screen transitions.]**

### 6. Reward screen
Player sees a card-pick screen (per the screen composition doc's note that this is the one screen where full text is correct, not a violation of icon-first design) and, if the class's shop-style economy is active even here, an option to skip for a small consolation of OK or gold — exact reward-screen mechanics beyond "full text is fine here" are a game-design decision, not a UI one, and are covered by the original game design doc's Section 4 (card acquisition sink) rather than this journey doc.

### 7. Map screen — first view
Player sees the branching path with node icons (combat/elite/rest/shop/event/treasure/boss), their current position highlighted, and available next-nodes at full contrast while unreachable/visited nodes recede.
**[governed by: screen composition doc Part 4.1.]**

### 8. Rest site
Player chooses to heal or upgrade a card. If they choose upgrade, the card selection screen shows their current deck with upgrade costs now priced in OK (per the balance doc's Section 5 pricing) rather than the free/gold-based rest-site upgrade some deckbuilders use — this distinction matters because it's the first moment OK is spent, not just earned, closing the resource loop the player has been building toward since their first kill.
**[governed by: balance doc Section 5, data schema doc Section 1.5 OKRunState.]**

### 9. Shop screen
Player sees cards priced in OK and relics/potions priced in Gold, visually zoned separately (per screen composition Part 4.2) rather than just differing by a small icon. If the player hasn't yet crossed an Excess-tier threshold, one or more cards in the shop appear visibly locked with the exact requirement shown ("requires a 25+ OK hit") rather than being absent — establishing early that this is a concrete, visible goal, not a hidden system.
**[governed by: screen composition Part 4.2, icon system Part 4, balance doc Section 4-5.]**

### 10. Event node
A narrative/choice encounter — full text expected here per the icon-vs-text framework's "narrative" exception. Not otherwise UI-specced in this document set; flagged as future work if events become mechanically complex (e.g., an event that grants OK directly) rather than pure flavor choices.

### 11. Elite encounter
Player sees a visibly tougher enemy with a distinct sprite/HP band (per balance doc Section 3) and possibly a multi-hit intent (per icon doc Section 3.3's "×N" multiplier tag) — this is a natural moment for the player to feel real risk in chasing overkill versus playing safe, which is the core tension the original game design doc set out to protect.

### 12. First Excess-tier threshold crossed
If the player lands a qualifying single hit, the **`excess_threshold_crossed` signal** fires its distinct one-time full-screen beat (per data schema doc Part 2.3 and screen composition Part 1.2's priority order) — this should feel like unlocking a new tier of the game, not a minor stat update. Immediately after, the previously-locked Excess cards in future shops/rewards become purchasable, and — ideally — the game surfaces this connection explicitly (e.g., the full-screen beat text references "Excess cards now available" rather than just celebrating a number).
**[gap flagged: whether the threshold-crossed celebration screen explicitly names the unlocked reward, or leaves the player to notice it later in a shop, is an open UX decision worth locking down — recommend explicit, since implicit discovery risks the moment feeling disconnected from its payoff.]**

### 13. Act boss
Player faces the Act's boss with its larger HP pool and (per the game design doc's boss-design section) phase-gates or damage caps preventing trivial overkill. The intent system still applies at full rigor — no exception to the fairness contract just because the enemy is a boss.

### 14. Act transition
Brief transition beat (art doc Section F backgrounds shift per-act palette) — mechanically nothing new here, but visually this is where the "epic, full-screen" art direction (from the STS2 research) should carry the most weight, since it's a pacing breath between acts rather than a moment requiring player input.

### 15. Run end — victory or defeat
Run-summary screen shows OK earned/spent as its own highlighted stat line (per screen composition Part 4.4), not buried in a generic list — closing the loop on a mechanic that's been visually reinforced at every step since the first kill.

### 16. Return to title / meta-progression
If the game includes cross-run meta-progression (unlocks, achievements), it surfaces here — not yet specced in any prior document; flagged as an open item if meta-progression beyond "OK resets each run" is planned.

---

## PART 2 — Steady-state loop (an experienced player's second, third, fiftieth run)

Once the mechanics are known, the journey compresses — this is worth stating explicitly so Claude Code doesn't over-build repeated tutorial moments into the core loop:

1. Class select → immediately reading the starting deck for synergies rather than needing the flavor text
2. Combat: intents read instantly as shapes, no conscious "what does this icon mean" step
3. OK ticking up is now background awareness, checked deliberately when planning a kill, not something the player is surprised by
4. Shop/rest visits become fast resource-allocation decisions (upgrade vs. new card vs. save toward an Excess unlock) rather than moments of discovery
5. Excess-tier threshold crossings still deserve their full-screen beat every single time (per the data schema doc's explicit note: "once per new threshold, ever, this run" — not muted for experienced players, since it's still a meaningful in-run event even if the player understands the system)

**The design test this section exists to protect**: nothing in the first-time journey (Part 1) should require permanent UI real estate or a mandatory pause once a player already knows the game. Every gap-flagged tutorial moment above should be the *only* thing that behaves differently between a new and experienced player — the underlying screens themselves never change.

---

## PART 3 — Gaps surfaced by this exercise (for the still-open spec list)

Writing the full journey end-to-end surfaced these as genuinely unspecced, not just deprioritized:

1. **First-time tutorial callouts** (Step 3) — needs its own short spec: which moments get a one-time callout, exact trigger conditions, dismissal behavior.
2. **Excess-tier unlock celebration content** (Step 12) — whether the unlock explicitly names the reward or leaves discovery implicit.
3. **Title screen and event-node UI** — lightly touched, not fully specced, though lower risk since they're simpler screens.
4. **Meta-progression across runs** (Step 16) — not yet decided as in-scope or out-of-scope for v1.

These are good candidates for the next spec pass if you want the full picture airtight before implementation starts.
