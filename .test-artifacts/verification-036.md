# 0.36.0 local verification report — 2026-10-01

- Source branch: `fix/yonatan-full-ui-polish`; exact release commit is supplied by the publication workflow.
- Godot 4.5.1 editor import/parse completed. `crystalline_visual_test.tscn` passed in source and from the portable archive with `CRYSTALLINE_VISUAL_OK`; the fixture checks every catalog relic's mapped halo, transparency, all 15 unique signatures, and production screens. The reward-screen render was visually reviewed.
- Exported `Overkill.pck`: 270,976,544 bytes, SHA-256 `36620b9792f60c7967af6671f1a77e048e4d67678a5993ea74fd77b48f179c30`.
- Portable ZIP contains exactly `Overkill.exe`, `Overkill.pck`, `GODOT-LICENSE.txt`, `DELIVERY.md`, and `Play Overkill.cmd`. ZIP: 346,173,706 bytes, SHA-256 `637d972a3cd837ef027f0e48c4c537a7dbd23715c89a1967ea09002c652c7cee`. The extracted portable executable ran the crystalline visual fixture successfully.
- Installer compilation succeeded. `OverkillSetup-0.36.0.exe`: 319,084,700 bytes, SHA-256 `c4c94278b335201077ae183d203906b064d8f29c8f1d0f99016d4df3fe70f5ae`. Silent current-user installation completed; installed `Overkill.exe` ran the same fixture; silent uninstall removed the test payload.
- Known restricted-runner messages: Godot cannot read the Windows root certificate store; the installed fixture may emit a non-fatal ObjectDB shutdown notice. They did not prevent the explicit fixture success sentinel or package checks.
- Full human campaign playthrough and interactive installer wizard are not claimed. Installer is unsigned. No mechanics, balance, or save format changed.
- GitHub publication and remote download/hash verification remain pending.
