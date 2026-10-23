"""Exercise persisted snapshots through the real CLI from an unrelated directory."""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import json
import platform
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cli", type=Path, default=ROOT / "_build/js/debug/build/cmd/main/main.js")
    parser.add_argument("--fixture", type=Path, default=ROOT / "fixtures/stacked.mountinfo")
    parser.add_argument("--evidence", type=Path, default=ROOT / "docs/test-evidence/cli-workflow.json")
    options = parser.parse_args()
    cli, fixture = options.cli.resolve(), options.fixture.resolve()
    (ROOT / "release-local").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="user-workflow-", dir=ROOT / "release-local") as tmp:
        tmp = Path(tmp)

        def call(*args, failure=False):
            p = subprocess.run(["node", str(cli), *map(str, args)], cwd=tmp, capture_output=True)
            if failure:
                assert p.returncode == 1 and p.stderr and not p.stdout, args
                return p.stderr.decode("utf-8", "replace")
            assert p.returncode == 0, p.stderr.decode("utf-8", "replace")
            return p.stdout.decode("utf-8")

        help_text = call("--help")
        assert all(command in help_text for command in ["capture", "import", "show", "query", "compare"])
        assert "Usage:" in call()
        version = re.search(r'version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text()).group(1)
        assert call("--version").strip() == version
        before, after, other = tmp / "before.json", tmp / "after.json", tmp / "other.json"
        json.loads(call("import", fixture, "synthetic-workflow", before))
        original = before.read_bytes()
        saved = json.loads(original)
        assert saved["format"] == "moonmount.snapshot" and saved["schema"] == 1
        assert saved["mountinfo"] == fixture.read_bytes().decode("utf-8")
        assert len(json.loads(call("show", before))["mounts"]) == 5
        resolved = json.loads(call("query", before, "/work/hidden/file"))["resolution"]
        assert resolved["mount"]["id"] == 4
        assert resolved["filesystem_path"] == "/project/hidden/file"
        raw_after = tmp / "after.mountinfo"
        raw_after.write_text(saved["mountinfo"].replace("/work ro", "/work rw"), encoding="utf-8", newline="\n")
        call("import", raw_after, "synthetic-workflow", after)
        diff = json.loads(call("compare", before, after))
        assert diff["summary"] == {"added": 0, "removed": 0, "changed": 1, "replaced": 0}
        assert diff["changes"][0]["kind"] == "Changed"
        assert json.loads(call("compare", before, before))["changes"] == []
        call("import", fixture, "another-namespace", other)
        assert "namespace mismatch" in call("compare", before, other, failure=True)
        call("import", fixture, "synthetic-workflow", before, failure=True)
        assert before.read_bytes() == original, "existing output must survive refused writes"
        broken = tmp / "broken.json"
        broken.write_text('{"format":"moonmount.snapshot","schema":999}', encoding="utf-8")
        assert "schema 1" in call("show", broken, failure=True)
        call("show", tmp / "missing.json", failure=True)
        call("query", before, "relative/path", failure=True)
        call("import", fixture, "s", tmp / "missing-parent" / "out.json", failure=True)
        if platform.system() != "Linux":
            assert "Linux" in call("capture", tmp / "linux-only.json", failure=True)
        else:
            live_before, live_after = tmp / "live-before.json", tmp / "live-after.json"
            call("capture", live_before)
            call("capture", live_after)
            assert len(json.loads(call("show", live_before))["mounts"]) > 0
            assert json.loads(call("query", live_before, "/proc/self/mountinfo"))["resolution"]["mount"]["id"] > 0
            live_diff = json.loads(call("compare", live_before, live_after))
            assert live_diff["namespace_id"] == json.loads(live_before.read_bytes())["namespace_id"]
    result = {"checked_at_utc": datetime.now(timezone.utc).isoformat(), "platform": platform.system(), "version": version, "workflow": "import -> saved snapshot -> show/query -> compare", "live_capture_workflow": "passed" if platform.system() == "Linux" else "Linux only", "namespace_mismatch": "rejected", "existing_file": "preserved", "unrelated_working_directory": "passed", "result": "passed"}
    options.evidence.parent.mkdir(parents=True, exist_ok=True)
    options.evidence.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
