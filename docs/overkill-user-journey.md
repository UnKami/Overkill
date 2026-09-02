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
Player sees a card-pick screen and picks freely — no OK cost, per the game design doc's Section 3. This is a deliberate contrast with the shop screen coming later: one is a gift, the other is a spend.

### 7. Map screen — first view
Player sees the branching path with node icons (combat/elite/rest/shop/event/treasure/boss), their current position highlighted, and available next-nodes at full contrast while unreachable/visited nodes recede.
**[governed by: screen composition doc Part 4.1.]**

### 8. Rest site
Player chooses to heal or upgrade a card. If they choose upgrade, the card selection screen shows their current deck with upgrade costs priced in OK (per the balance doc's Section 5 pricing) — this is the first moment OK is spent, not just earned, closing the resource loop the player has been building toward since their first kill.
**[governed by: balance doc Section 5, data schema doc Section 1.5 OKRunState.]**

### 9. Shop screen
Player sees cards, relics, and potions all priced in the same currency, zoned by item category rather than by currency (per screen composition Part 4.2 — since OK is the only currency, category is what separates one section from another now). If the player hasn't yet crossed an Excess-tier threshold, one or more cards in the shop appear visibly locked with the exact requirement shown ("requires a 25+ OK hit") rather than being absent — establishing early that this is a concrete, visible goal, not a hidden system.
**[governed by: screen composition Part 4.2, icon system Part 4, balance doc Section 5.]**

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

## PART 2.5 — Extended scenarios (added after the gap analysis pass)

The first-time journey (Part 1) covers a clean, idealized run. Real play hits messier situations constantly — these scenarios exercise the rules fixed in the gap analysis and surface a few more.

### A. Targeting and the damage preview (the most important addition here)

When a player picks up a single-target card and it's ready to play, before they commit to a target they should see, on the hovered/highlighted enemy: the enemy's current HP, its current Block if any, and — critically — a live preview of the outcome if this exact card is played on this exact enemy (predicted remaining HP, or predicted OK if the hit would be lethal). This preview updates live as the player drags/hovers between different enemies in a multi-enemy fight, letting them compare "overkill this one for 12 OK" versus "just barely kill that one for 2 OK" before committing energy. Without this, precise overkill play is guesswork rather than the skill the whole design is built around.
**[status: this is the Tier 1 gap from the fix plan — flagged here as the concrete UX moment that spec needs to cover, not yet a finished spec itself.]**

### B. Multi-enemy AOE fight

Player plays an AOE attack into a 3-enemy fight where one enemy has low HP, one has Block up, and one has high HP. Per the newly-fixed formula (data schema doc, Part 1.6): the low-HP enemy dies with a visible OK pop; the Blocked enemy's damage depletes Block first before any HP/OK math applies to it; the high-HP enemy just takes a clean hit with no OK. All three outcomes should be visually legible in the same instant — this is a good stress-test scenario for the screen composition doc's attention-priority rules (Part 1.2), since three different feedback types are firing simultaneously.

### B.5 A Spillage chain kill

Player has a Spillage-flagged attack card in hand facing a row of three weak enemies. Playing it kills the first, and rather than an OK pop, the player sees the excess damage visually travel to the second enemy (a quick motion/trail effect distinct from a normal hit), which also dies, chaining into the third. No OK is generated from any of these three kills — the preview system (targeting-preview spec) should make this trade-off visible *before* the player commits, showing "this kill will Spillage, 0 OK" rather than letting the player discover the forgone currency only after the fact. This is the moment that should make a Spillage-leaning deck feel distinct in hand from a banking deck, even though both are "just" playing attack cards.

### C. A poison/DOT kill on the enemy's turn

Player has stacked Poison on an enemy and ends their turn without playing a finishing blow. On the enemy's turn, the poison tick resolves and kills it, generating OK per the same formula as a card-source kill (data schema doc, Part 1.6). This should trigger the identical OK-feedback treatment as a card-triggered kill — same amber pop, same priority in the animation queue — even though the player didn't just take an action. If this moment looks or feels different from a card-kill, that inconsistency would quietly teach players that DOT builds don't "really" count, which actively undermines a whole archetype's legitimacy.

### D. Deck runs out mid-combat (reshuffle)

Player has played and discarded most of their deck in a long fight. On their next draw, the game reshuffles the discard pile into the draw pile — this should be visibly communicated (a brief shuffle animation or icon state on the draw pile), not a silent instant swap, so the player understands why cards they discarded are coming back.

### E. A card exhausts

Player plays a card with `exhaust: true` (data schema doc, Part 1.1). Instead of going to the discard pile, it should visibly move to a distinct "exhausted" zone or fade out entirely, communicating it's gone for the rest of combat — different enough from the normal discard motion that a player glancing at their discard pile doesn't miscount what's still available to redraw.

### F. Low-resource tense turn

Player is at low HP with a hand of cards they can't fully afford this turn (not enough energy) — the unplayable cards should visibly dim/gray per the fix-plan's flagged gap (#8), making the "what are my real options right now" question answerable at a glance rather than requiring the player to click every card to find out it won't play.

### G. Deck review between fights

At a rest site or shop, player opens a persistent deck-view screen (fix-plan gap #6) to check exactly which cards they're holding before deciding whether to spend OK on an upgrade or a new card — this screen should show the same card-face treatment used everywhere else (Excess-tier framing, upgrade indicator, etc.) rather than a stripped-down list view, so information stays consistent across every place a card can appear.

### H. Second class, same journey — divergence check

Running the exact same journey with a different class (say, a Burst-archetype class instead of the first class's Volume leaning) should feel different in *pacing* (fewer, bigger OK spikes vs. frequent small ones) without any UI screen itself changing shape — this is a direct test of the "consistency of pattern across classes" principle established in the icon system doc. If a class needs a differently-laid-out combat screen to make sense, that's a sign the archetype was implemented as a UI exception rather than a deck-building pattern, which the original design explicitly wanted to avoid.

### I. Abandoning a run

Player opens a pause/settings menu (fix-plan gap #12) mid-run and selects an option to abandon. This is an irreversible action and should follow whatever confirmation-dialog convention gets established for fix-plan gap #13 — flagged here as a concrete case that convention needs to cover, alongside card removal and relic-choice confirmations.

---

## PART 3 — Gaps surfaced by this exercise (for the still-open spec list)

The full list, after both the original journey and the extended-scenario pass, lives in the dedicated gap analysis document (`overkill-gap-analysis-fix-plan.md`), which also fixed several of these directly (Block/OK formula, AOE summation, DOT kills, exhaust/retain fields) rather than just flagging them. Remaining open items, in the priority order that document recommends:

1. **Card targeting & damage preview system** (Scenario A) — highest priority, since without it the core mechanic is unplayable at the intended skill level, not just less polished.
2. **Deck-view screen, card-play interaction model, unplayable-card visual state** (Scenarios F, G) — cluster together as one "how the player handles their hand and deck" spec.
3. **Enemy-turn presentation, tutorial callouts, unlock celebration content** — smaller confirmations of behavior already implied elsewhere.
4. **Settings/pause menu, confirmation-dialog convention, meta-progression scope, map generation, audio design, technical architecture** — lower risk, sequenced whenever convenient.
