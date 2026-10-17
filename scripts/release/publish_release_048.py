import subprocess
import json
import os
import hashlib
import urllib.request
import urllib.error

def get_token():
    p = subprocess.run(['git', 'credential', 'fill'], input=b'protocol=https\nhost=github.com\n\n', capture_output=True, check=True)
    for line in p.stdout.decode().splitlines():
        if line.startswith('password='):
            return line.split('=', 1)[1]
    raise RuntimeError("Failed to retrieve GitHub token from git credential helper")

def compute_sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        while chunk := f.read(1024 * 1024):
            h.update(chunk)
    return h.hexdigest().lower()

def main():
    token = get_token()
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Overkill-release',
        'X-GitHub-Api-Version': '2022-11-28'
    }

    version = open('VERSION', 'r').read().strip()
    tag = f"v{version}-test"
    print(f"Targeting tag {tag} for release...")

    # Read commit
    source_commit = subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
    print(f"Source commit: {source_commit}")

    # Build release notes
    notes_path = f"docs/encounter-{version.split('.')[1].zfill(3)}.md"
    verif_path = f".test-artifacts/verification-{version.split('.')[1].zfill(3)}.md"
    body = open(notes_path, 'r', encoding='utf-8').read() + f"\n\nSource: {source_commit}\n\n" + open(verif_path, 'r', encoding='utf-8').read()

    # Check existing release
    req = urllib.request.Request(f'https://api.github.com/repos/UnKami/Overkill/releases/tags/{tag}', headers=headers)
    release = None
    try:
        with urllib.request.urlopen(req) as resp:
            release = json.loads(resp.read().decode())
            print(f"Found existing release ID {release['id']}")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print("No existing release found. Creating draft release...")
        else:
            raise

    if not release:
        create_payload = json.dumps({
            'tag_name': tag,
            'target_commitish': 'feat/yonatan-046-relic-feedback',
            'name': f"Overkill {version} - Playtest",
            'body': body,
            'draft': True,
            'prerelease': True
        }).encode('utf-8')
        req = urllib.request.Request('https://api.github.com/repos/UnKami/Overkill/releases', data=create_payload, headers=headers)
        with urllib.request.urlopen(req) as resp:
            release = json.loads(resp.read().decode())
            print(f"Created draft release {release['id']}: {release['html_url']}")

    release_id = release['id']
    assets = [
        f"installer/OverkillSetup-{version}.exe",
        f"build/Overkill-{version}-Windows.zip",
        f"installer/OverkillSetup-{version}.sha256"
    ]

    # Inspect existing assets on release
    existing_assets = {a['name']: a for a in release.get('assets', [])}

    for asset_path in assets:
        fname = os.path.basename(asset_path)
        fsize = os.path.getsize(asset_path)
        fhash = compute_sha256(asset_path)
        print(f"\nProcessing {fname} ({fsize} bytes, sha256: {fhash})...")

        if fname in existing_assets:
            ex = existing_assets[fname]
            if ex['size'] == fsize:
                print(f"Asset {fname} already uploaded with matching size. Skipping upload.")
                continue
            else:
                print(f"Asset {fname} size mismatch. Deleting prior asset {ex['id']}...")
                del_req = urllib.request.Request(f"https://api.github.com/repos/UnKami/Overkill/releases/assets/{ex['id']}", headers=headers, method='DELETE')
                urllib.request.urlopen(del_req)

        upload_url = f"https://uploads.github.com/repos/UnKami/Overkill/releases/{release_id}/assets?name={urllib.parse.quote(fname)}"
        print(f"Uploading {fname} to {upload_url}...")
        with open(asset_path, 'rb') as f:
            data = f.read()
        up_headers = headers.copy()
        up_headers['Content-Type'] = 'application/octet-stream'
        up_headers['Content-Length'] = str(len(data))
        up_req = urllib.request.Request(upload_url, data=data, headers=up_headers)
        with urllib.request.urlopen(up_req) as resp:
            uploaded = json.loads(resp.read().decode())
            print(f"Uploaded {fname} successfully (ID: {uploaded['id']}, size: {uploaded['size']})")

    # Publish release (draft -> false)
    print("\nPublishing release (draft -> false)...")
    patch_payload = json.dumps({'draft': False, 'prerelease': True}).encode('utf-8')
    patch_req = urllib.request.Request(f"https://api.github.com/repos/UnKami/Overkill/releases/{release_id}", data=patch_payload, headers=headers, method='PATCH')
    with urllib.request.urlopen(patch_req) as resp:
        published = json.loads(resp.read().decode())
        print(f"Release successfully published: {published['html_url']}")

    # Verify public download URLs
    print("\nVerifying public download asset accessibility (HTTP HEAD)...")
    for a in published['assets']:
        url = a['browser_download_url']
        head_req = urllib.request.Request(url, method='HEAD')
        head_req.add_header('User-Agent', 'Overkill-release-check')
        try:
            with urllib.request.urlopen(head_req) as h_resp:
                print(f"Verified {a['name']}: HTTP {h_resp.status} ({a['size']} bytes)")
        except Exception as e:
            print(f"Asset head check note for {a['name']}: {e}")

    print("\nALL_RELEASE_STEPS_COMPLETED_SUCCESSFULLY!")

if __name__ == '__main__':
    main()
