# OVERKILL — Art Requirements & AI Generation Prompt Kit

This document has two parts: **(1)** a complete inventory of every art asset the game needs, organized by category with counts and specs, and **(2)** a reusable prompt kit — a master style-lock block plus per-category templates — designed to be handed to an AI image-generation agent so every asset comes back visually consistent.

---

## PART 1 — Master Style Bible

Every prompt in this document should be built by combining the **Style Lock** below with the **category template** for that asset. This is what keeps hundreds of separately-generated assets feeling like one game.

### Style Lock (paste into every prompt)

```
Hand-drawn digital illustration, ink-lined character/object work with flat cel
shading, no painterly blending, no airbrush gradients. Bold clean linework,
slightly exaggerated proportions (readable silhouettes over realism). Moderate
color saturation — punchy but not neon. Dark fantasy tone with a playful,
slightly irreverent edge — think grim dungeon crawl that doesn't take itself
too seriously. Full-body or full-object framing, isolated on a transparent or
flat neutral background, no drop shadows baked into the art, no background
scenery unless the asset is a background/environment piece. Consistent light
source from upper-left at 45 degrees. Game-asset composition, not concept art
— clean edges suitable for sprite extraction. Resolution: 2048x2048 source,
downscaled to spec per asset type.
```

### Palette anchors (reference across all prompts)

- **Overkill / Excess theme color**: amber-orange (#EF9F27 range) — reserved exclusively for anything tied to the Overkill mechanic (icon, excess-tier card frames, VFX). Never use this color family decoratively elsewhere.
- **HP / danger**: deep red (#E24B4A range)
- **Block / defense**: cool blue (#378ADD range)
- **Neutral / structural UI**: warm gray, near-black linework
- **Environment palette shifts per Act** (see Part 1, Section E) to signal descent through the world.

### Game description (paste into every prompt for context)

```
OVERKILL is a roguelike deckbuilding game in the vein of Slay the Spire. The
player builds a deck of attack/skill/power cards and fights through a
procedurally-arranged map of monster encounters, elites, and bosses. The
game's signature mechanic: dealing damage beyond what's needed to kill an
enemy generates "Overkill" (OK), a persistent currency spent between fights
to upgrade cards, buy new cards, and unlock a rare tier of "Excess" cards.
Tone: dark fantasy dungeon crawl with a playful, self-aware edge — dramatic
and a little absurd, not grimdark or horror. Think a grindhouse monster-hunter
aesthetic crossed with tarot-card illustration sensibilities.
```

---

## PART 2 — Full Asset Inventory

### A. Playable Characters (per class)

Estimate: 4 classes at launch (mirroring StS's 4-character roster).

| Asset | Spec | Notes |
|---|---|---|
| Character portrait | 512x512, transparent bg | Used on character-select screen, shop dialogue |
| Combat idle sprite | 512x768, transparent bg, front 3/4 view | Base pose for animation rigging |
| Attack animation set | 6-8 frames per attack type (light/heavy) | See Part 3 animation notes |
| Hurt/damaged frame | 1-2 frames | Flinch reaction |
| Death animation | 4-6 frames | Run-over screen only |
| Card-back design | 1 per class | Unique deck skin |
| Class icon (map/menu) | 64x64 | Simple emblem, not full character |

**Prompt template — Character:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Full-body character portrait of [CLASS NAME], a [class concept, e.g. "brutal
executioner obsessed with excessive force"]. [Physical description: build,
signature weapon, silhouette-defining costume element]. Pose: confident
combat-ready stance, weapon visible, facing 3/4 toward camera. Color identity:
[class's signature accent color] worked into costume/weapon accents. No
background.
```

---

### B. Enemies

Estimate per act: ~8 trash monsters, ~3 elites, 1 act boss. Across 4 acts + 1 final boss: **~44 enemy sprites** minimum (scale to your actual encounter design).

| Asset | Spec | Notes |
|---|---|---|
| Idle/combat sprite | 512x512 to 768x768 depending on enemy scale | Bosses may need larger canvas |
| Attack telegraph pose | 1 frame | Shown during intent-preview phase (StS-style intent icons above head) |
| Hurt frame | 1 frame | |
| Death/defeat frame | 1 frame — should read as "overkilled" for enemies killed with high OK | Consider a distinct "shattered/burst" variant used specifically for high-overkill kills |
| Intent icons | Reuse shared icon set (Part 2E), not per-enemy | |

**Prompt template — Enemy:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Full-body monster illustration: [enemy name/concept]. [Size/threat class:
trash / elite / boss]. [Physical description and signature attack weapon or
ability]. Menacing but slightly exaggerated/comic proportions to match the
game's playful-dark tone — avoid pure horror-realism. Combat-ready pose,
facing left (toward the player side of the battlefield). No background.
Act [N] palette: [warm dungeon tones / cold crypt blues / molten reds / etc.
per act].
```

---

### C. Cards

This is the largest single bucket. Estimate 25-30 cards per class × 4 classes + ~15 colorless + ~20 Excess-tier = **~150-170 unique card illustrations**, each needing 4 rarity/tier frame treatments.

| Asset | Spec | Notes |
|---|---|---|
| Card illustration (per card) | 512x384, centered composition, top 2/3 of card | One AI-generated image per unique card |
| Card frame — Common | Template, not per-card | Flat gray/bronze border |
| Card frame — Uncommon | Template | Silver border |
| Card frame — Rare | Template | Gold border |
| Card frame — Excess-tier | Template | Amber border + tinted background + "excess" ribbon tag (see mockup already built) |
| Card back (per class) | 1 per class | Already counted in Section A |
| Energy cost gem | 1 shared asset | Small icon, top-left of card |

**Prompt template — Card illustration:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Card illustration for "[CARD NAME]," a [attack/skill/power] card with the
effect: "[card text]." Composition: single dramatic focal action or object
that reads clearly at small size (cards are viewed at ~1/6 screen width).
[Visual concept translating the card's mechanical effect into an image —
e.g. for a high-overkill finisher: a weapon strike with visible excess force/
energy bursting past the target]. Framed tightly, no border (border is added
programmatically).
```

**Prompt template — Excess-tier card illustration (distinct treatment):**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Card illustration for the rare "Excess" tier, reserved for cards that require
proving a high-Overkill kill to unlock. Visual language should feel like a
step above normal cards: brighter amber energy, more dramatic composition,
a sense of raw excess/overflow (energy bursting past its container, damage
visibly "spilling over"). Card: "[CARD NAME]" — [card text].
```

---

### D. Relics

Estimate: ~40-50 relics across the run (StS launched with ~90; a smaller first pass of 40-50 is reasonable for v1).

| Asset | Spec | Notes |
|---|---|---|
| Relic icon | 256x256, transparent bg | Must be silhouette-distinct at 32px display size — this is the legibility requirement flagged as critical |
| Relic "get" animation frame | Optional — 2-3 frame pop/glow | Shown once when picked up |

**Prompt template — Relic:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Object icon: "[RELIC NAME]," a magical/mechanical item with the effect
"[relic text]." Single object, centered, dramatic lighting, strong readable
silhouette — must be identifiable at very small icon size (32px). No
background. Avoid generic shapes (plain orbs, plain gems, plain boxes) —
give the object a distinct outline shape unique among other relics.
```

---

### E. Shared UI / Icon Set

One-off assets used everywhere — highest priority for legibility since these carry gameplay information every single turn.

| Asset | Count | Notes |
|---|---|---|
| Overkill (OK) icon | 1 | Amber, used in HUD, damage numbers, card gate tags — must be instantly recognizable |
| HP icon | 1 | |
| Block icon | 1 | |
| Energy icon | 1 | |
| Status effect icons (Vulnerable, Weak, Strength, etc.) | ~15-20 | Small, must each be visually distinct as a set |
| Enemy intent icons (attack, defend, buff, debuff, unknown) | ~6-8 | |
| Card type badges (Attack/Skill/Power) | 3 | |
| Rarity gems (Common/Uncommon/Rare/Excess) | 4 | |
| Potion icons | ~15-20 | |
| Currency icons (Gold, OK) | 2 | |
| Map node icons (combat, elite, rest, shop, event, boss, treasure) | ~7 | |

**Prompt template — Icon:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Small UI icon representing [concept], for use at 32-48px display size.
Extremely simple, high-contrast silhouette, 1-2 colors maximum, flat design,
no fine detail that would disappear at small size. Centered, transparent
background. Style should match [reference: "the same ink-lined flat style as
the card illustrations, simplified"].
```

---

### F. Environments / Backgrounds

| Asset | Spec | Notes |
|---|---|---|
| Combat background (per act) | 1920x1080, full-screen art | 4 acts = 4 base backgrounds minimum |
| Map background (per act) | 1920x1080 | Can share palette with combat bg |
| Elite/boss unique combat background | 1 per boss | Bosses deserve unique staging per the "epic, full-screen" direction |
| Rest site / shop / event background variants | 3-4 shared across acts, palette-shifted | |

**Prompt template — Environment:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Full-screen background illustration for Act [N]: [environment concept, e.g.
"a crumbling ossuary lit by hanging braziers"]. Wide establishing composition
with clear negative space in the lower-middle third where character sprites
will be placed in front of it. Painterly background rendering is acceptable
here (unlike character/card assets) since it sits behind gameplay elements —
slightly more atmospheric depth and softer edges than foreground assets.
Palette: [act-specific palette].
```

---

### G. VFX / Combat Feedback

These are the assets most directly tied to your core mechanic and deserve special attention.

| Asset | Notes |
|---|---|
| Normal damage number style | Neutral gray/white, standard size |
| Overkill damage number style | Amber, larger scale, brief "punch" animation on appear |
| Overkill burst effect (particle/flash) | Triggers on any kill that generates OK — intensity/scale should visibly increase with OK amount generated |
| High-overkill "shatter" kill effect | For big OK kills — distinct enemy-death treatment (see Section B) |
| Block gain effect | Small blue flash/shield icon pop |
| Status apply effect (generic) | Small icon-pop above target |
| Excess-tier card unlock celebration | One-time full-screen moment when a threshold is first crossed |

**Prompt template — VFX sprite sheet:**
```
[STYLE LOCK] + [GAME DESCRIPTION]
Particle/VFX sprite sheet for "[effect name]," a [burst/flash/shatter] effect
used when [trigger condition]. Provide as a sequence of 4-6 frames showing
the effect's progression from trigger to fade, flat colors with no
soft-glow blur (must read clearly as pixel/vector layers, not photographic
light). Primary color: [amber for overkill / blue for block / etc].
Transparent background, each frame same canvas size for direct sprite-sheet
use.
```

---

### H. Meta / Frontend

| Asset | Notes |
|---|---|
| Game logo/title art | Full-screen key art incorporating the title |
| Main menu background | Full-screen |
| Loading screen art (1-3 variants) | |
| Victory/defeat run-summary screen art | |
| Class-select screen backdrop | |

---

## PART 3 — Animation Notes (for the "STS2 liveliness" pass)

Since the plan is AI-generate static sprites first, then animate — a few notes to keep the two phases compatible:

- **Generate characters/enemies in a neutral, rig-friendly pose** (limbs slightly separated, weapon held clear of body) so the static sprite can be cut into layers (torso/limbs/weapon) for skeletal animation (e.g. Spine, DragonBones, or After Effects puppet pins) rather than needing full frame-by-frame redraws.
- **Keep a consistent canvas anchor point** (e.g. character's feet always at the same relative Y position) across all character/enemy generations so animation rigs can be reused as a template between assets of similar size class (trash vs elite vs boss).
- **Idle animation**: subtle breathing/weapon-sway loop, 2-4 second cycle, is the single highest-value animation for STS2-style liveliness since it's visible constantly.
- **Attack animation** matters more for readability than fluidity — the wind-up frame should be exaggerated enough that players read "this is about to happen" even at a glance, tying back to the intent-telegraph system.
- **Overkill-specific animation beat**: consider a unique "overkill impact" animation layer (screen-shake + enemy sprite briefly overscaled/distorted before the death frame) reserved for kills above a threshold — this is the single highest-leverage animation for making your core mechanic feel distinct from a normal kill.

---

## PART 4 — Technical & Pipeline Requirements

Style and content prompts alone aren't enough to get usable production assets back from an AI agent at this volume. These requirements should be treated as hard constraints, not preferences.

### File delivery specs

```
- Format: PNG-32 with real alpha transparency (no white or checkerboard
  background baked into the file)
- Color profile: sRGB
- No baked-in text, logos, or watermarks anywhere in the image
- No drop shadows, vignettes, or background blur baked into character/card/
  icon assets — lighting and shading only on the subject itself
- No signature, no border/frame unless the asset IS a frame template
- Exact canvas size as specified per asset type in Part 2 — no auto-cropping
  or off-canvas bleed the agent has to guess at
```

### Standing negative prompt (attach to every generation)

```
No text, no watermark, no signature, no logo, photorealistic rendering,
3D render, blurry, low detail, extra limbs, malformed hands, cropped
composition, background scenery (unless generating an environment asset),
drop shadow, glow/bloom effect baked into image, copyrighted characters,
existing franchise likenesses, trademarked designs, real public figures.
```

### Consistency mechanism — the biggest real risk

A shared text prompt alone will visibly drift over 150+ separate generations — line weight, proportions, and palette all wander asset-to-asset even with identical prompt text. Do not rely on prompt text alone for consistency at this volume. Instead:

1. **Generate one "anchor" asset per category first** (one character, one enemy, one card, one icon, one background) and get explicit sign-off on style before batch-generating anything else — this is already Part 4's step 1 in the generation order below, but it's worth stating as a hard gate, not a suggestion.
2. **Reuse the anchor as an image reference** (image-to-image / reference-conditioning, not just a repeated text prompt) for every subsequent asset in that category, so line weight and rendering approach stay locked.
3. **For the 4 playable classes specifically**, generate a model sheet / turnaround first (front + 3/4 + side view of the same character, same prompt) before generating any of that class's ~25 card illustrations or animation frames — the player's own character is the asset most likely to be noticed if it drifts.
4. **Log the prompt, negative prompt, and seed/reference used for every accepted asset.** If an asset needs a revision pass later, regenerating from scratch without the original seed will not match the rest of the batch.

### Naming & folder convention

Output filenames should map directly to engine import folders so there's no manual sorting pass. Suggested pattern:

```
/characters/[class-id]/[class-id]_portrait.png
/characters/[class-id]/[class-id]_idle.png
/characters/[class-id]/anim/[class-id]_attack_[01-08].png
/enemies/act[N]/[enemy-id]_idle.png
/enemies/act[N]/[enemy-id]_death.png
/cards/[class-id]/[card-id]_art.png
/cards/excess/[card-id]_art.png
/cards/frames/frame_[common|uncommon|rare|excess].png
/icons/status/[status-id].png
/icons/ui/[icon-id].png
/relics/[relic-id].png
/environments/act[N]/[bg-id].png
/vfx/[effect-id]_[frame-01-06].png
```

Every asset ID here should match the ID already used in your game's design/data files (card IDs, enemy IDs, relic IDs) so art drops in without a renaming step.

### Legal / IP guardrail

Include this instruction explicitly in the agent's system context, not just the negative prompt — generic "dark fantasy dungeon crawler" prompts can drift toward recognizable existing IP (armor silhouettes, weapon designs, creature designs) without a direct instruction against it:

```
Do not reference, reproduce, or closely imitate any existing copyrighted
character, franchise design, trademarked logo, or real public figure. All
designs must be original creations distinct from existing games, films, or
media franchises, even when drawing on shared fantasy/dungeon-crawler tropes.
```

---

## PART 5 — Suggested Generation Order

For an AI agent working through this list, this priority order front-loads the assets that define whether the visual language reads correctly before spending budget on volume:

1. Style Lock validation — generate 1 character, 1 enemy, 1 card, 1 icon first and review for consistency before batch-generating anything else.
2. Shared UI/icon set (Section E) — small in count, used everywhere, must be legible immediately.
3. One full class (Section A + that class's ~25 cards) — proves the character-to-card visual pipeline end to end.
4. Remaining classes.
5. Act 1 enemies + environment (Sections B, F) — enables a playable vertical slice.
6. Remaining acts' enemies/environments.
7. Relics (Section D).
8. VFX (Section G) — best done once real gameplay footage exists to time against.
9. Meta/frontend art (Section H) — lowest priority, doesn't block core-loop testing.
