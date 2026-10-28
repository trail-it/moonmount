"""Install the exact published version and exercise its public API independently."""
from datetime import datetime, timezone
from pathlib import Path
import json
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(args, cwd):
    result = subprocess.run(args, cwd=cwd, capture_output=True)
    output = (result.stdout + result.stderr).decode("utf-8", "replace").strip()
    if result.returncode:
        raise RuntimeError(output)
    return output


def main():
    manifest = (ROOT / "moon.mod").read_text(encoding="utf-8")
    module = re.search(r'name\s*=\s*"([^"]+)"', manifest).group(1)
    version = re.search(r'version\s*=\s*"([^"]+)"', manifest).group(1)
    (ROOT / "release-local").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="registry-consumer-", dir=ROOT / "release-local") as directory:
        consumer = Path(directory)
        (consumer / "moon.mod").write_text('name = "local/moonmount_registry_consumer"\nversion = "0.0.1"\n', encoding="utf-8")
        run(["moon", "add", f"{module}@{version}"], consumer)
        (consumer / "moon.pkg").write_text('import { "' + module + '" @mount } for "test"\n', encoding="utf-8")
        (consumer / "consumer_test.mbt").write_text('''///|
test "registry snapshot, overmount and namespace contract" {
  let text = "1 99 8:1 / / rw - ext4 x rw\\n2 1 0:2 / /work rw - tmpfs x rw\\n3 2 0:3 / /work/hidden rw - tmpfs x rw\\n4 2 8:4 /sub /work ro - ext4 x rw\\n5 1 0:5 mnt:[42] /ns rw - nsfs nsfs rw\\n"
  let snapshot = @mount.parse(text, namespace_id="registry-consumer")
  let restored = @mount.decode_snapshot(snapshot.encode())
  assert_eq(restored.mounts(), snapshot.mounts())
  assert_eq(restored.resolve("/work/hidden/file").mount.id, 4)
  assert_eq(restored.resolve("/work/hidden/file").filesystem_path, Some("/sub/hidden/file"))
  assert_eq(restored.resolve("/ns").filesystem_path, None)
  assert_eq(restored.diff(snapshot).length(), 0)
  restored.mounts().clear()
  assert_eq(restored.mounts().length(), 5)
}
''', encoding="utf-8", newline="\n")
        checks = {target: run(["moon", "test", "--target", target, "--deny-warn"], consumer) for target in ["wasm-gc", "js"]}
        installed = consumer / ".mooncakes" / module
        if (installed / "moon.mod").exists():
            installed_manifest = (installed / "moon.mod").read_text(encoding="utf-8")
            actual_version = re.search(r'version\s*=\s*"([^"]+)"', installed_manifest).group(1)
            actual_module = re.search(r'name\s*=\s*"([^"]+)"', installed_manifest).group(1)
        else:
            installed_manifest = json.loads((installed / "moon.mod.json").read_text(encoding="utf-8"))
            actual_version, actual_module = installed_manifest["version"], installed_manifest["name"]
        assert (actual_module, actual_version) == (module, version)
        assert not (consumer / "moon.work").exists()
    evidence = {"checked_at_utc": datetime.now(timezone.utc).isoformat(), "module": module, "version": actual_version, "source": "public Mooncakes registry; no local workspace override", "checks": checks, "result": "passed"}
    (ROOT / "docs/test-evidence").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs/test-evidence/registry-consumption.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
