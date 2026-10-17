import subprocess
import json
import base64
import urllib.request
import urllib.error

def get_token():
    p = subprocess.run(['git', 'credential', 'fill'], input=b'protocol=https\nhost=github.com\n\n', capture_output=True, check=True)
    for line in p.stdout.decode().splitlines():
        if line.startswith('password='):
            return line.split('=', 1)[1]
    raise RuntimeError("Failed to retrieve GitHub token from git credential helper")

def api_call(path, method='GET', data=None, token=None):
    base = 'https://api.github.com/repos/UnKami/Overkill'
    url = f"{base}{path}"
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Overkill-release',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    encoded_data = None
    if data is not None:
        encoded_data = json.dumps(data).encode('utf-8')
        headers['Content-Type'] = 'application/json; charset=utf-8'

    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            content = resp.read().decode('utf-8')
            return json.loads(content) if content else {}
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode('utf-8')
        print(f"HTTPError {e.code} on {method} {url}: {err_msg}")
        raise

def main():
    token = get_token()
    print("Retrieved GitHub token.")

    # 1. Fetch current main commit & tree
    main_ref = api_call('/git/ref/heads/main', token=token)
    main_sha = main_ref['object']['sha']
    main_commit = api_call(f'/git/commits/{main_sha}', token=token)
    base_tree_sha = main_commit['tree']['sha']
    print(f"Current main commit: {main_sha}, base tree: {base_tree_sha}")

    # Read current main files
    def get_main_content(filepath):
        res = api_call(f'/contents/{filepath}?ref=main', token=token)
        return base64.b64decode(res['content']).decode('utf-8')

    main_readme = get_main_content('README.md')
    main_installer_readme = get_main_content('installer/README.md')
    main_update_log = get_main_content('UPDATE_LOG.md')

    # Read local encounter-048.md
    with open('docs/encounter-048.md', 'r', encoding='utf-8') as f:
        doc_encounter = f.read()

    # Construct updated README.md for main
    # Place 0.48.0 playtest section at top of downloads
    updated_readme = """# Overkill

## Latest full-game playtest — 0.48.0 Archetype Synergy & Chronometer Depth

**[Download the Windows installer — 0.48.0 playtest](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/OverkillSetup-0.48.0.exe)**

[Portable Windows ZIP](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/Overkill-0.48.0-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.48.0-test) · **[Update log](UPDATE_LOG.md)**

Play the **0.48.0 playtest**: assemble your clock sector in any order, trigger immediate progressive combo sweeps (`1`, `1 → 2`, `1 → 2 → 3`), inspect live damage and block calculations on hover, and explore four build archetypes (Chrono-Overdrive, Iron Bastion, Crimson Hemorrhage, and Overkill Harvest). [Detailed changes and notes](docs/encounter-048.md).

The downloadable prerelease is built from [exact source 421bec7](https://github.com/UnKami/Overkill/commit/421bec75c13e418209e953bbe2ba18af272a0c2e) on `feat/yonatan-046-relic-feedback`, tagged `v0.48.0-test`. **Main has download documentation only; this experimental gameplay has not been merged.**
""" + main_readme[main_readme.find("\n## Latest character playtest"):]

    # Construct updated installer/README.md for main
    updated_installer_readme = """# Windows installers

## Latest full-game playtest — 0.48.0 Archetype Synergy & Chronometer Depth

**[Download OverkillSetup-0.48.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/OverkillSetup-0.48.0.exe)**

[Portable game folder ZIP](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/Overkill-0.48.0-Windows.zip) · [Release notes and checksums](https://github.com/UnKami/Overkill/releases/tag/v0.48.0-test) · [Update log](../UPDATE_LOG.md)

Launch **Overkill** for the 0.48.0 playtest: assemble your clock sector in any order, trigger immediate progressive combo sweeps (`1`, `1 → 2`, `1 → 2 → 3`), inspect live damage and block calculations on hover, and explore four build archetypes (Chrono-Overdrive, Iron Bastion, Crimson Hemorrhage, and Overkill Harvest). See [detailed changes and notes](../docs/encounter-048.md). Exact source: `421bec75c13e418209e953bbe2ba18af272a0c2e`, immutable `v0.48.0-test` tag. The installer is unsigned; prior releases remain available for rollback.
""" + main_installer_readme[main_installer_readme.find("\n## Latest character playtest"):]

    # Construct updated UPDATE_LOG.md for main
    update_log_048_entry = """## 0.48.0 playtest — 2026-10-17

- **4 Synergistic Relic Archetypes (29 Clock Relics)**: Re-authored all 29 clock relics into four deep, viable archetypes: Chrono-Overdrive (multi-hit / tempo / socket multiplier / positional), Iron Bastion (Block retention / Thorns / kinetic slam), Crimson Hemorrhage (Bleed / rupture / lifesteal), and Overkill Harvest (sector finisher / banked-OK scaling / extraction). Added positional triggers (`charge_next_socket_multiplier`, `echo_previous_hour`, `sector_finisher_bonus_damage`, `sector_finisher_hits_bonus`, `resonance_essence_bonus`) and archetype payoffs. All Bleed ticks and Rupture excess damage now convert 1:1 into Overkill points.
- **Sector-First Chronometer Combat Loop**: All 9 enemy hours revealed upfront. Players assemble their 3-hour sector in any order by clicking active sector sockets. Filled hours sweep in progressive combo chains (`1`, `1 -> 2`, `1 -> 2 -> 3`). Added "Overcharge & Sweep" to skip assembly, boost the middle socket (+0.25x multiplier), and bank +3 Overkill.
- **Slay-the-Spire-Caliber Smart Hover & HUD UX**: Instant `SmartHoverInspector` anchored to sockets/pedestals without obscuring the hovered item. Displays live math formulas (e.g. `Base 6 + Str 2 * Socket 1.5x = 12 DMG`), contextual keyword sub-cards (spawning only active keywords), and per-hour clash forecast timeline strips. Sockets show live green `#67E68D` / coral `#FF7A7A` numbers, Sector Finisher gold crown markers on Hours 3/6/9, and compound enemy intent badges (`8⚔ 3🛡`). Reserve Draw/Discard counters show remaining relics on hover.
- **80 Max HP Progression & Economy**: Player Vitality rebalanced to 80 Max HP (StS standard). Starter loadout set to 10 relics (`3x REL-01, 3x REL-04, 1x REL-02, 1x REL-08, 1x REL-13, 1x REL-14`), leaving 2 open slots (10/12). Shop 12/12 inventory bug resolved with an in-place relic replacement picker, plus a new "Dismantle Relic (15 OK)" option. Expanded `EventCatalog` to 6 rich risk/reward events with full-inventory replacement. Boss Zenith relics made 100% free (0 OK), with an optional 20-OK pre-upgrade bonus. Strategic Cog Navigation map routes differentiate Left (aggressive/elites), Center (balanced), and Right (economy/utility) paths.
- **3D Relic Assets & Choreography**: Validated in Blender 5.2 & Godot 4.7.2. Tightened post-contact choreography in `build_relic_choreography.py` / `relic_tracks.gd`. 280,042 motion checks pass with 0 failures. Includes dedicated handoff notes for future visual AI models (Gemini 4 Argon / ChatGPT 6).
- **Installer:** [OverkillSetup-0.48.0.exe](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/OverkillSetup-0.48.0.exe). **Portable ZIP:** [Overkill-0.48.0-Windows.zip](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/Overkill-0.48.0-Windows.zip). [Release and verification](https://github.com/UnKami/Overkill/releases/tag/v0.48.0-test) · [SHA-256 manifest](https://github.com/UnKami/Overkill/releases/download/v0.48.0-test/OverkillSetup-0.48.0.sha256).
- **Source:** `421bec75c13e418209e953bbe2ba18af272a0c2e`, immutable tag `v0.48.0-test`, branch `feat/yonatan-046-relic-feedback`. Main has download documentation only; experimental gameplay has not been merged into main.
- **Compatibility:** Saves adopt new 80 Max HP economy and starter relic counts on new runs. Existing saves retain completed act progress.
- **Verification:** 10 automated test suites passed with 0 failures: `overhaul_verification_test` (archetypes, combo sweeps, SmartHoverInspector, shop replacement/dismantle, 6 events, free boss altar, map routing), `starter_relic_test`, `run_artifact_test`, `ux_017_test` (59 live comparisons), `motion_quality_test` (280,042 checks), `relic_animation_test`, `map_determinism_test`, `cog_navigation_test` (8,646 checks), `boss_overkill_altar_test`, `enemy_intent_readout_test`. All three public download URLs verified HTTP 200.
- **Verified assets:** installer 656,140,756 bytes, SHA-256 `198212bd311f3a8723c7155a66f16d6222067f24831b69586821d24465f8aec1`; ZIP 684,843,169 bytes, SHA-256 `008fb6039fa79b22291ff5faa65883472e469dfbc2b8cfea0983fb4c30e377e2`; manifest 187 bytes.
- **Limits:** Unsigned playtest. Gameplay remains on feature branch awaiting human playthrough feedback and future 3D visual polish by visual models.
"""

    pos = main_update_log.find("\n## 0.45.0 playtest")
    if pos != -1:
        updated_update_log = main_update_log[:pos] + "\n" + update_log_048_entry + main_update_log[pos:]
    else:
        updated_update_log = update_log_048_entry + "\n" + main_update_log

    doc_files = {
        'README.md': updated_readme,
        'installer/README.md': updated_installer_readme,
        'UPDATE_LOG.md': updated_update_log,
        'docs/encounter-048.md': doc_encounter
    }

    # Create blobs and tree
    tree_items = []
    for path, content in doc_files.items():
        blob = api_call('/git/blobs', method='POST', data={
            'content': base64.b64encode(content.encode('utf-8')).decode('ascii'),
            'encoding': 'base64'
        }, token=token)
        tree_items.append({
            'path': path,
            'mode': '100644',
            'type': 'blob',
            'sha': blob['sha']
        })
        print(f"Created blob for {path}: {blob['sha']}")

    new_tree = api_call('/git/trees', method='POST', data={
        'base_tree': base_tree_sha,
        'tree': tree_items
    }, token=token)
    print(f"Created new tree: {new_tree['sha']}")

    # Create commit
    commit = api_call('/git/commits', method='POST', data={
        'message': 'docs: publish verified 0.48.0 playtest downloads',
        'tree': new_tree['sha'],
        'parents': [main_sha]
    }, token=token)
    commit_sha = commit['sha']
    print(f"Created commit on top of main: {commit_sha}")

    # Create branch
    branch_name = 'fix/yonatan-048-downloads'
    ref = api_call('/git/refs', method='POST', data={
        'ref': f'refs/heads/{branch_name}',
        'sha': commit_sha
    }, token=token)
    print(f"Created branch {branch_name} -> {ref['object']['sha']}")

    # Create Pull Request
    pr = api_call('/pulls', method='POST', data={
        'title': 'Publish verified 0.48.0 playtest downloads',
        'head': branch_name,
        'base': 'main',
        'body': 'Documentation only: installer/portable links, exact source commit, verification and known limits for 0.48.0 Archetype Synergy & Chronometer Depth Overhaul. Gameplay remains on `feat/yonatan-046-relic-feedback`. No gameplay merge is included.'
    }, token=token)
    print(f"\nSuccessfully created Documentation PR #{pr['number']}: {pr['html_url']}")

if __name__ == '__main__':
    main()
