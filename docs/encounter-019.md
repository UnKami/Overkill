# Overkill 0.19.0 — Sentinel Production Playtest

On GitHub: **UnKami/Overkill → Releases → 0.19.0 → Assets → OverkillSetup-0.19.0.exe**. The repository's **installer** folder and homepage also point to this release. Install and choose **Play Sentinel encounter** from the Start menu, or extract the whole portable ZIP and run **Play Sentinel.cmd**. This direct encounter uses a separate save profile. **Overkill.exe** opens the regular game.

## What changed

- Original skinned Sentinel body with layered pauldrons, fluted limb armor, articulated boots, crest/grille helmet, folded tabard and a nine-mark chest clock. Authored edge wear and cavity masks distinguish its metal surfaces.
- Dedicated protective guard, unguarded recoil and stagger-to-kneel death performance. Heavy attack timing stays synchronized with actual weapon contact.
- More coherent cathedral staging: stone piers, pointed arches, stepped dais, matte floor and nine-hour floor markings. Quieter forged metal, a ridged execution blade and improved cloak drape.
- Closer action/inspection framing; wider composition returns for top relic choices, including large text. Reduced-motion mode keeps the wider camera steady.
- Defeat clears stale placement/action prompts, extinguishes only the defeated actor's lights and suppresses late impacts while handing off one result.
- Saved High, Balanced and Performance 3D resolution settings. High remains the default; text and clocks retain full resolution.
- Rigid weapon batching and cached clock graphics reduce redundant rendering work. This is not a claim of stable frame rate.

## Compatibility and scope

The nine-hour clock, twelve-relic starter, persistent Block, gradual enemy reveals and combat balance are unchanged. Existing 0.14–0.18 saves remain compatible; the new graphics setting defaults to High. Source tag: **v0.19.0-test**, branch **feat/yonatan-sentinel-production**. Gameplay remains on the feature branch pending review; main's download documentation points to the released playtest.

**This is not AAA completion.** The Sentinel is a developing 3D vertical slice. Other enemies still need bespoke model production, materials and animation. Cloth is a drape approximation, not full collision simulation. Weapon release, animation variety, broader environment art, listening review and human balance testing remain unfinished.

**Performance is not accepted yet.** Local Intel Graphics Vulkan idle diagnostics showed median 33–36 ms, p95 61–82 ms and p99 spikes up to 235 ms. Results vary by workload and renderer; lower resolution can reduce rendering cost but does not establish smooth full fights. Try Balanced or Performance if needed. The installer is unsigned and its interactive wizard has not been manually tested. Known Windows certificate-store and headless exit warnings remain.

## Verification

Source and packaged checks cover starter rules, clock combat, preview-versus-live resolution, contact timing, guard/recoil, original mesh/skin/material structure, saved graphics settings and terminal victory/defeat behavior. Rendered review covers the default Vulkan renderer and GL compatibility, 1080p/720p, large text, normal/fast speed and reduced motion. Pose fixtures and one-hit finish setups do not substitute for full-run or broad hardware acceptance.

The release includes SHA-256 checksums for the installer and portable ZIP. Published assets are checked against local hashes and download availability before delivery. Detailed development evidence is in `docs/sentinel-production.md` and `CHANGELOG_AI.md`.
