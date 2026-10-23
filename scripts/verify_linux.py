"""Run locally on Linux. Raw host data stays under ignored release-local/."""
from pathlib import Path
from datetime import datetime, timezone
import json
import os
import platform
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "_build/js/debug/build/cmd/main/main.js"


def run(args):
    return subprocess.run(args, cwd=ROOT, capture_output=True, check=True).stdout.decode("utf-8")


def main():
    assert sys.platform == "linux", "Linux required"
    raw = ROOT / "release-local/linux"
    raw.mkdir(parents=True, exist_ok=True)
    text = Path("/proc/self/mountinfo").read_bytes().decode("utf-8")
    token = os.readlink("/proc/self/ns/mnt")
    source = raw / "mountinfo.txt"
    source.write_text(text, encoding="utf-8", newline="\n")
    parsed = json.loads(run(["node", str(CLI), "inspect", str(source), token]))["mounts"]
    columns = "ID,PARENT,MAJ:MIN,FSROOT,TARGET,FSTYPE,VFS-OPTIONS"
    expected = json.loads(run(["findmnt", "--tab-file", str(source), "--kernel", "--json", "--list", "--output", columns]))["filesystems"]
    (raw / "findmnt.json").write_text(json.dumps(expected))
    expected_by_id = {int(m["id"]): m for m in expected}
    assert len(parsed) == len(expected_by_id)
    for m in parsed:
        e = expected_by_id[m["id"]]
        assert m["parent_id"] == int(e["parent"])
        assert f'{m["major"]}:{m["minor"]}' == e["maj:min"]
        assert m["root"] == e["fsroot"] and m["point"] == e["target"]
        assert m["fs_type"] == e["fstype"]
        assert set(m["options"].split(",")) == set(e["vfs-options"].split(","))
    paths = ["/", "/proc", "/proc/self/mountinfo", "/dev/null", "/sys", "/tmp"]
    for path in paths:
        actual = json.loads(run(["node", str(CLI), "live", path]))["resolution"]
        # Existing real paths only; findmnt uses kernel path lookup here.
        e = json.loads(run(["findmnt", "--json", "--target", path, "--output", "ID,TARGET,FSTYPE"]))["filesystems"][0]
        assert actual["mount"]["id"] == int(e["id"]), path
        assert actual["mount"]["point"] == e["target"]
    live = json.loads(run(["node", str(CLI), "live"]))
    assert live["namespace_id"].endswith(":" + token)
    with tempfile.TemporaryDirectory(prefix="saved-snapshots-", dir=raw) as temporary:
        temporary = Path(temporary)
        before, after = temporary / "before.json", temporary / "after.json"
        run(["node", str(CLI), "capture", str(before)])
        run(["node", str(CLI), "capture", str(after)])
        saved = json.loads(before.read_bytes())
        assert saved["namespace_id"] == live["namespace_id"]
        assert len(json.loads(run(["node", str(CLI), "show", str(before)]))["mounts"]) > 0
        query = json.loads(run(["node", str(CLI), "query", str(before), "/proc/self/mountinfo"]))
        assert query["namespace_id"] == live["namespace_id"]
        compared = json.loads(run(["node", str(CLI), "compare", str(before), str(after)]))
        assert compared["namespace_id"] == live["namespace_id"]
        assert set(compared["summary"]) == {"added", "removed", "changed", "replaced"}
        original = before.read_bytes()
        refusal = subprocess.run(["node", str(CLI), "capture", str(before)], capture_output=True)
        assert refusal.returncode == 1 and before.read_bytes() == original
    # A real unreadable input, not a synthetic replacement for live success.
    error = subprocess.run(["node", str(CLI), "inspect", "/proc/no-such-mount-record", token], capture_output=True)
    assert error.returncode == 1 and not error.stdout
    versions = "\n".join(re.sub(r"\)\s+.*$", ")", line) for line in run(["moon", "version", "--all"]).strip().splitlines())
    result = {"checked_at_utc": datetime.now(timezone.utc).isoformat(), "platform": platform.system(), "backend": "js / Node", "toolchain": versions, "node": run(["node", "--version"]).strip(), "findmnt": run(["findmnt", "--version"]).strip(), "records_compared": len(parsed), "fields_per_record": 7, "real_paths_compared": len(paths), "read_failure": "passed", "live_namespace_identity": "passed", "capture_show_query_compare": "passed", "capture_existing_file": "preserved", "host_mount_changes": "none", "result": "passed"}
    dest = ROOT / "docs/test-evidence/linux.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
