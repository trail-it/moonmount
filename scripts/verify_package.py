"""Consume the actual packaged archive; source checkout is not a workspace member."""
from pathlib import Path
from datetime import datetime, timezone
import json
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, cwd):
    p = subprocess.run(args, cwd=cwd, capture_output=True)
    if p.returncode:
        raise RuntimeError((p.stdout + p.stderr).decode("utf-8", "replace"))
    return (p.stdout + p.stderr).decode("utf-8", "replace").strip()


def main():
    (ROOT / "release-local").mkdir(exist_ok=True)
    (ROOT / "docs/test-evidence").mkdir(parents=True, exist_ok=True)
    packaging = run(["moon", "package"], ROOT)
    import re
    manifest = (ROOT / "moon.mod").read_text(encoding="utf-8")
    version = re.search(r'version\s*=\s*"([^"]+)"', manifest).group(1)
    module = re.search(r'name\s*=\s*"([^"]+)"', manifest).group(1)
    archive = ROOT / f"_build/publish/{module.replace('/', '-')}-{version}.zip"
    with zipfile.ZipFile(archive) as z:
        entries = z.namelist()
        forbidden = {".git", ".github", "research", "release-local", "_build", "target", "demo-output", "tmp", "output", "__pycache__", ".local-ledger.md"}
        for name in entries:
            path = Path(name)
            assert not (set(path.parts) & forbidden), name
            assert ".." not in path.parts and not path.is_absolute() and not path.drive
            assert not name.lower().endswith((".exe", ".dll", ".pem", ".key"))
        for required in ["moon.mod", "moon.pkg", "LICENSE", "THIRD_PARTY.md", "pkg.generated.mbti", "cmd/main/main.mbt", "fixtures/stacked.mountinfo", "API.mbt.md"]:
            assert required in entries, required
        with tempfile.TemporaryDirectory(prefix="consume-", dir=ROOT / "release-local") as temp:
            temp = Path(temp)
            library = temp / "library"
            z.extractall(library)
            # Run the README verification commands before creating a workspace:
            # no ignored source-tree directories or build cache may be required.
            fresh = json.loads(run([sys.executable, "scripts/verify.py"], library))
            oracle = json.loads(run([sys.executable, "scripts/verify_oracle.py"], library))
            workflow = json.loads(run([sys.executable, "scripts/verify_cli_workflow.py"], library))
            assert fresh["result"] == oracle["result"] == "passed"
            assert workflow["result"] == "passed"
            consumer = temp / "consumer"
            consumer.mkdir()
            (temp / "moon.work").write_text('members = ["library", "consumer"]\n', encoding="utf-8")
            (consumer / "moon.mod").write_text('name = "local/mount_consumer"\nversion = "0.0.1"\nimport { "' + module + '@' + version + '" }\n', encoding="utf-8")
            (consumer / "moon.pkg").write_text('import { "' + module + '" @mount } for "test"\n', encoding="utf-8")
            source = '''///|
test "archive public API, hidden subtree and opaque root" {
  let text = "1 99 8:1 / / rw - ext4 x rw\\n2 1 0:2 / /work rw - tmpfs x rw\\n3 2 0:3 / /work/hidden rw - tmpfs x rw\\n4 2 8:4 /sub /work ro - ext4 x rw\\n5 1 0:5 mnt:[42] /ns rw - nsfs nsfs rw\\n"
  let s = @mount.parse(text, namespace_id="synthetic-consumer")
  let restored = @mount.decode_snapshot(s.encode())
  assert_eq(restored.mounts(), s.mounts())
  assert_eq(s.resolve("/work/hidden/a").mount.id, 4)
  assert_eq(s.resolve("/work/hidden/a").filesystem_path, Some("/sub/hidden/a"))
  assert_eq(s.resolve("/ns").filesystem_path, None)
  assert_eq(s.diff(s).length(), 0)
  s.mounts().clear()
  assert_eq(s.mounts().length(), 5)
}
'''
            (consumer / "consumer_test.mbt").write_text(source, encoding="utf-8", newline="\n")
            consumers = {target: run(["moon", "test", "--package", "local/mount_consumer", "--target", target, "--deny-warn"], consumer) for target in ["wasm-gc", "js"]}
            run(["moon", "build", "--target", "js", "--deny-warn"], library)
            cli = json.loads(run(["moon", "run", "cmd/main", "--target", "js", "--", "resolve", str(library / "fixtures/stacked.mountinfo"), "synthetic", "/work/hidden/file"], library))
            assert cli["resolution"]["mount"]["id"] == 4
    result = {"checked_at_utc": datetime.now(timezone.utc).isoformat(), "archive": archive.name, "file_count": len(entries), "archive_bytes": archive.stat().st_size, "fresh_archive_readme_checks": fresh["result"], "fresh_archive_oracle": oracle["result"], "fresh_archive_saved_snapshot_workflow": workflow["result"], "consumers": consumers, "extracted_cli": "passed", "distribution_exclusions": "passed", "packaging_output": packaging.replace(str(ROOT), "<project>"), "result": "passed"}
    (ROOT / "docs/test-evidence/package-consumption.json").write_text(json.dumps(result, indent=2) + "\n")
    (ROOT / "release-local/package-files.txt").write_text("\n".join(entries) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
