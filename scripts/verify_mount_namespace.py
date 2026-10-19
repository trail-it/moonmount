"""Exercise actual bind mounts in an explicitly disposable mount namespace.

Run only in a disposable container with CAP_SYS_ADMIN, or invoke this script via
unshare --user --map-root-user --mount. The CLI/library remain read-only.
"""
from pathlib import Path
from datetime import datetime, timezone
import json
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "_build/js/debug/build/cmd/main/main.js"


def run(*args):
    p = subprocess.run(list(map(str, args)), cwd=ROOT, capture_output=True)
    if p.returncode:
        raise RuntimeError(p.stderr.decode("utf-8", "replace"))
    return p.stdout.decode("utf-8")


def main():
    # Do not let a normal direct invocation alter a host mount namespace.
    assert os.environ.get("MOONMOUNT_DISPOSABLE_NAMESPACE") == "1", "explicit disposable-namespace acknowledgement required"
    run("mount", "--make-rprivate", "/")
    mounted = []
    scenarios = []
    with tempfile.TemporaryDirectory(prefix="moonmount-kernel-") as tmp:
        tmp = Path(tmp)
        old, new, target = (tmp / p for p in ("old", "new", "target"))
        for p in (old, new, target):
            (p / "hidden").mkdir(parents=True)
        (old / "marker").write_text("old")
        (new / "marker").write_text("new")

        def bind(source, destination):
            run("mount", "--bind", source, destination)
            mounted.append(destination)

        def inspect():
            return json.loads(run("node", CLI, "live"))["mounts"]

        def check(path, expected_id=None):
            actual = json.loads(run("node", CLI, "live", path))["resolution"]
            expected = json.loads(run("findmnt", "--json", "--target", path, "--output", "ID,TARGET,FSROOT"))["filesystems"][0]
            assert actual["mount"]["id"] == int(expected["id"])
            assert actual["mount"]["point"] == expected["target"]
            if expected_id is not None:
                assert actual["mount"]["id"] == expected_id
            return actual

        try:
            bind(old, target)
            bind(old / "hidden", target / "hidden")
            old_records = inspect()
            hidden_id = check(target / "hidden")["mount"]["id"]
            bind(new, target)
            assert (target / "marker").read_text() == "new"
            records = inspect()
            assert any(m["id"] == hidden_id for m in records), "covered child must remain in mountinfo"
            top_id = check(target)["mount"]["id"]
            result = check(target / "hidden", top_id)
            assert result["mount"]["id"] != hidden_id
            scenarios.append("overmount hides recorded old child; kernel lookup agrees")
            assert result["filesystem_path"] == str(new / "hidden")
            scenarios.append("bind filesystem root path agrees with source subdirectory")
            # Kernel pathname quoting differs between mountpoint and source/type.
            odd = tmp / "space tab\tline\nslash\\hash#cr\rctrl\x01del\x7f目录"
            odd.mkdir()
            bind(new, odd)
            odd_result = check(odd)
            assert odd_result["mount"]["point"] == str(odd)
            assert odd_result["filesystem_path"] == str(new)
            scenarios.append("real escaped and unescaped control-character mountpoint")
            # A real remount changes per-mount flags; it must not change identity.
            before_file, after_file = tmp / "before.mountinfo", tmp / "after.mountinfo"
            before_file.write_bytes(Path("/proc/self/mountinfo").read_bytes())
            run("mount", "-o", "remount,bind,ro", odd)
            after_file.write_bytes(Path("/proc/self/mountinfo").read_bytes())
            changes = json.loads(run("node", CLI, "diff", before_file, after_file, os.readlink("/proc/self/ns/mnt")))
            matching = [change for change in changes if change.get("after", {}).get("id") == odd_result["mount"]["id"]]
            assert len(matching) == 1 and matching[0]["kind"] == "Changed"
            assert "ro" in matching[0]["after"]["options"].split(",")
            scenarios.append("real bind remount produces Changed without false Replaced")
        finally:
            for destination in reversed(mounted):
                run("umount", destination)
    result = {"checked_at_utc": datetime.now(timezone.utc).isoformat(), "platform": "Linux", "scenarios": scenarios, "scenario_count": len(scenarios), "isolation": "disposable mount namespace; propagation private; all temporary mounts unmounted", "result": "passed"}
    dest = ROOT / "docs/test-evidence/mount-namespace.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
