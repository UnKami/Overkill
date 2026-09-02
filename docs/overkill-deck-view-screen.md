# OVERKILL — Deck View Screen

Resolves fix-plan gap #6. The key design decision here: this isn't one screen — it's **one reusable "browse your deck" component that changes its action verb depending on where it's opened from.** Rest site, shop removal service, and pause-menu reference should all look identical except for what tapping a card does, per the same consistency-of-pattern principle established throughout (one visual form per concept, reused everywhere it appears).

---

## 1. Access points and their action mode

| Entry point | Action mode | What tapping a card does |
|---|---|---|
| Rest site "Upgrade" option | Upgrade mode | Shows that card's upgrade cost in OK (balance doc, Section 5), confirms the spend |
| Shop "Remove a card" service | Removal mode | Shows the removal cost (OK, per balance doc Section 5), confirms the sacrifice |
| Pause menu / map screen "View Deck" | Reference mode | No action — pure browse, tapping only opens the normal card tooltip/zoom, nothing is spent or changed |
| Combat draw/discard/exhaust pile icons (Zone F, screen composition doc) | Reference mode, pre-filtered | Same component, filtered to show only that specific pile's current contents |

**The component itself never needs to know which entry point launched it beyond a single "mode" flag** — same grid, same card rendering, same sort/filter controls in every mode. Only the confirm-on-tap behavior changes.

---

## 2. Layout

- **Grid of full card faces**, not a condensed list — cards must render with the exact same frame treatment used everywhere else (rarity border, Excess-tier ribbon, upgrade indicator) established in the card frame mockup and icon system doc. A stripped-down list view would break the "one consistent visual form per card" rule the whole icon system is built on.
- **Sort/filter controls** pinned above the grid: sort by type (Attack/Skill/Power), cost, rarity, or acquisition order; filter to show only upgradeable cards (useful specifically in Upgrade mode, where the player is scanning for good upgrade targets rather than browsing everything).
- **Total card count displayed** at the top of the screen, small and unobtrusive — useful context since deck size affects draw consistency (balance doc, Section 1's soft cap note), without needing the player to count manually.
- **Scrolls/paginates once the deck exceeds a single screen's grid** (early run: 10 cards fit easily; late run: ~25-30 cards will need scrolling) — no separate "compact mode," just more grid rows.

---

## 3. Card state rendering (reuses the targeting-preview system's visual language)

- **Upgraded cards** show their upgrade indicator (a "+" marker or similar) consistently here and everywhere else a card appears — this is the first spec to actually need that indicator rendered, so it's worth confirming now: same treatment in hand, in this deck view, and in any future rewards/shop screens showing an already-upgraded card.
- **In Upgrade mode**, a card that's already at max upgrade level (or otherwise ineligible) should dim using the exact same "unplayable" visual treatment established in the targeting-preview spec (Section 5 of that doc) — one consistent "not available right now" pattern reused a third time (locked Excess cards, unaffordable hand cards, now ineligible-for-upgrade cards in this screen).
- **In Removal mode**, similarly, any card the design wants to protect from removal (e.g., a starter Strike if the design ever restricts that) uses the same dimmed treatment.

---

## 4. Confirmation behavior

Both Upgrade and Removal modes trigger an irreversible spend — this is exactly the case the fix plan's still-open confirmation-dialog convention (Tier 3, gap #13) needs to cover. Recommend: tapping a card in an actionable mode doesn't spend immediately — it opens a small inline confirm state (the selected card enlarges slightly, shows the exact cost and resulting effect, with a confirm/cancel pair) rather than a full modal popup, keeping the player in the deck-view context rather than yanking them to a separate screen for a one-tap confirmation.

---

## 5. Reference-mode specifics (pile viewers)

When opened from the draw/discard/exhaust pile icons during combat, the component opens read-only, pre-filtered to that pile, and should close immediately on tap-away or a back gesture — this is a quick-reference glance mid-combat, not a screen the player is meant to linger on, so it shouldn't pause or otherwise interrupt combat state beyond the glance itself.

---

## 6. Empty and small-deck states

Early in a run (10-card starting deck), the grid should not look sparse or broken with excess empty space — center the smaller grid rather than left-aligning it against a mostly-empty screen, so the screen composition feels intentional at every deck size rather than only "finished" once the deck is large.
