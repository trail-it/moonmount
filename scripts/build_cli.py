"""Build and verify a standalone Node CLI zip. No registry publication."""
from pathlib import Path
from datetime import datetime, timezone
import json
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(args):
    p = subprocess.run(args, cwd=ROOT, capture_output=True)
    if p.returncode:
        raise RuntimeError((p.stdout + p.stderr).decode("utf-8", "replace"))
    return p.stdout.decode("utf-8")


def main():
    version = re.search(r'version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text()).group(1)
    run(["moon", "build", "--target", "js", "--release", "--deny-warn"])
    out = ROOT / "output/cli"
    out.mkdir(parents=True, exist_ok=True)
    entry = out / "moonmount.cjs"
    shutil.copyfile(ROOT / "_build/js/release/build/cmd/main/main.js", entry)
    archive = out / f"moonmount-{version}-node.zip"
    readme = f"""MoonMount {version} / MIT
Requires Node.js 22 or newer. MoonBit and Python are not required to run this CLI.
Extract the complete zip to a folder, then run:

node moonmount.cjs --help
node moonmount.cjs import fixtures/stacked.mountinfo synthetic before.json
node moonmount.cjs show before.json
node moonmount.cjs query before.json /work/hidden/file
node moonmount.cjs compare before.json before.json

On Linux, collect real snapshots (same mount namespace):
node moonmount.cjs capture before.json
node moonmount.cjs capture after.json
node moonmount.cjs compare before.json after.json

Use new filenames: existing files are never overwritten.
Captured namespace IDs travel with snapshots and are checked during comparison.
Offline show/query/compare work on Windows and Linux. Capture/live require Linux.
Queries are lexical and do not resolve symlinks or check access permissions.
"""
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(entry, "moonmount.cjs")
        z.writestr("README.txt", readme)
        for name in ["LICENSE", "THIRD_PARTY.md", "THIRD_PARTY_LICENSES/MoonBit-core-LICENSE", "THIRD_PARTY_LICENSES/MoonBit-core-NOTICE", "fixtures/README.md", "fixtures/stacked.mountinfo"]:
            z.write(ROOT / name, name)
    (ROOT / "release-local").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="standalone-cli-", dir=ROOT / "release-local") as tmp:
        tmp = Path(tmp)
        with zipfile.ZipFile(archive) as z:
            z.extractall(tmp)
        # Calls only node on the extracted build, never moon or the source CLI.
        run([sys.executable, "scripts/verify_cli_workflow.py", "--cli", str(tmp / "moonmount.cjs"), "--fixture", str(tmp / "fixtures/stacked.mountinfo"), "--evidence", str(tmp / "evidence.json")])
    result = {"checked_at_utc": datetime.now(timezone.utc).isoformat(), "version": version, "archive": archive.name, "runtime": "Node.js >=22; no MoonBit/Python needed by users", "extracted_cli_workflow": "passed", "result": "passed"}
    (ROOT / "docs/test-evidence").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs/test-evidence/standalone-cli.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
