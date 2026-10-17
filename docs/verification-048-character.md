# Executioner reference fidelity pass — 2026-10-08

Local art candidate on `feat/yonatan-046-relic-feedback`, continuing the existing
uncommitted 0.47 work. This is not a versioned release or final visual acceptance.
The published installer remains v0.45.0-test. All previous character inputs are
preserved under `.test-artifacts/048-character/baseline/`.

## Changes

- Hood: deeper forward brow, recessed faceless mask, asymmetrical soft folds.
- Cloth: charcoal-teal dye variation and fine woven normal relief rather than
  uniformly blue material. Woven surfaces have their own nonmetallic material
  so metallic texture mipmaps cannot create bright trim on cloth seams.
- Coat: longer curved embroidered panels, finished hems and turned chest lapels.
- Armor: aged metal color and embossed surface detail; the canonical atlas is
  used around actual geometry rather than projecting painted highlights onto it.
- Undersuit: warmer leather tint. Greaves meet the boots more continuously.
- Materials: four 4096px PBR maps plus a dedicated 4096px cloth color atlas,
  wider bake margins and anisotropic texture filtering. A temporary joined
  bake mesh avoids processing the full atlas separately for each component;
  the saved source retains all 28 editable meshes, exact coordinates and weights.
- Idle: planted weight transfer, opposing chest motion, watchful head movement,
  relaxed hand motion. The causal capture filter is bypassed only for analytic
  idle curves, fixing the mismatch at the animation loop boundary.

## Confirmed source checks

`source-seams.log` checks the saved Blender source against runtime motion data,
normalized skinning, editable controls and 2240 garment-bound samples. All 15
active clips remain sample-for-sample identical to the takeover baseline. All
16 durations/contact markers and every bind bone are unchanged. Idle's first
and last frames match exactly. These checks do not establish final art quality.

`bake-seams-check.log` passes 160268 saved-source checks and exact original-to-
baked coordinate/skin-weight parity, and verifies all five packed 4K maps.
The temporary bake mesh is absent from the saved editable source.

## Visual review status

The earlier version-8 source review produced 96 native angle/pose views in
`turns/`. Inspection identified dark armor and cloth-edge material highlights;
version 9 addresses them and requires fresh native captures. Do not treat the
version-8 captures as version-9 evidence.

Final evidence is under `.test-artifacts/048-character/`:

- `final-portraits/`: four native 1000x1400 turn views, inspected from front and
  rear. These precede only the final runtime suppression of cloth specular and
  emission. `idle-frames/` and `final-quality/` include that final material setting.
- `final-quality.log`: 1944 checks, zero failures across High, Balanced and
  Performance. Includes matte-cloth material and 4K texture checks.
- `payload-motion.log`: 280042 native motion checks, zero failures against the
  exported pack. The source motion suite passed the same check count.
- `payload-battle.log`: ten real combat sequences completed, including both
  Twin Blades contacts. The recording fixture exits successfully; this is not
  a full-catalog, full-campaign or balance acceptance run.
- `Executioner-Reference-Idle.mp4`: original illustration beside the live native
  character, 193 frames at 30 FPS, two full idle loops. The corrected scene-based
  capture exits without script errors (`idle-final.log`).
- `Executioner-Combat.mp4`: 1591 frames at 30 FPS, exported combat footage.
  Frame sampling is deterministic; this is not measured real-time FPS evidence.
- `payload/Preview Character Build.cmd`: current local runtime/pack with a
  separate disposable save profile. No installer was produced for this pass.
- `artifact-hashes.json`: SHA-256 of the actual character GLB and exported pack.

Both videos were decoded with FFmpeg to check for corruption. Sampled native
frames were visually inspected. The original illustration still has finer
sculpted ornament, more organic garment construction, stronger asymmetry and
more intricate glowing details. This pass improves the existing model; it does
not establish that the requested illustration-level fidelity has been reached.
Active choreography was preserved, not redesigned. Relic refinement, final art
acceptance, stable-FPS verification and installer/release delivery remain open.
No publication, push or merge was performed; the existing publication hold
remains in place. The GitHub download is still the earlier v0.45.0-test build.
