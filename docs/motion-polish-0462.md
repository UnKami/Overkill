# Local motion study 0.46.2 — not visually accepted

The user found 0.46.1 improved but still amateurish. The previous rig/export
checks are technical evidence, not evidence that the performance is polished.
Publication remains held.

## Authored changes

- Replaced the throw's raised, abrupt preparation with a lower curved wind-up,
  inward folded elbow, accelerated release and trailing settle. Preserved the
  0.76-second release, 0.95-second contact, existing durations and combat values.
- Added small planted lateral pelvis shifts during casts. Full extension is
  reserved for leg support; arms retain 6 pixels of extension reserve so the
  solver cannot hit the near-straight elbow singularity.
- Phase-staggered pelvis/chest, hands, head and cloth in the Blender bake.
  Offsets vanish at action boundaries and contact; delayed root/chest motion
  produces cloak inertia that decays while standing still.
- Channel, Chalice and Bell use lower asymmetric arm poses. Long effects retain
  their gesture with subtle breathing. Siphon keeps its attached transfer grip.
- Rebuilt both saved Blender sources and the runtime character/relic tracks.

## Current evidence

Saved Blender/Godot skin comparison: 45,504 checks, maximum error 0.000738 pixel.
Source and exported motion: 85,676 checks, max per-frame displacement 22.181
pixels across the whole roster. This aggregate is not a smoothness score.
Native close-up: 5,096 checks, 10 complete actions. Source feedback: 4,412
checks, no errors. Actual Windows payload, native renderer: 1,509 checks, no
errors, no shutdown warning. Variable per-frame checks explain count changes.

Rendered native frame sequences were visually inspected for the casting arc,
shoulder/elbow silhouette, planted support, and correct video proportions.
The comparison crops actual character captures, previous version on the left
and revised on the right. The previous capture is 30 FPS, repeated into the
60-FPS comparison; the new footage is sampled at 60 FPS. The movies are muted
fixed-simulation captures, not real-time performance benchmarks or evidence
of human acceptance. Source movie runs retain the prior shutdown ObjectDB
warning; the clean native payload does not.

## Review files

- `.test-artifacts/046/casting-comparison-0462.mp4`: before/after, 34 seconds.
- `.test-artifacts/046/polish-rig-review-0462.mp4`: full skeleton close-up.
- `.test-artifacts/046/relic-performance-0462.mp4`: in-battle reel, 43.9 seconds.
- `.test-artifacts/046/polish-throw-sheet.png`: dense casting pose sequence.

## Remaining visual limits

The character still uses flat painted pieces. The torso has no drawn turning
poses, the hand is a fixed fist silhouette, and the rig cannot invent finger
opening or convincing depth rotation from those textures. This is a motion
revision within that art, not a new fully dimensional character asset. It
should not be represented as finished cinematic-quality animation. A broader
art pass would require new turning/hand pose artwork or a fully modelled,
textured 3D character. Human visual acceptance, interactive installation and
full campaign play remain unverified. No branch, PR or release was published.

Exported catalog: all 29 relics passed, including fast/reduced motion, outcome rules and recovery.
Local installer SHA-256: 99cc1c27794842cfdeec8c6f0bc9d620c1385db6b8cc70f681a1a4bc9f68507f.


Tested PCK SHA-256: 44dd654fd3f69e505544796c355b6c1b4328155c0d380ab5fc38596a18e78b87.
