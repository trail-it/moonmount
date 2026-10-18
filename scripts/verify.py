"""Verify all declared offline backends and CLI failure behavior."""
from pathlib import Path
import json
import platform
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(args):
    p = subprocess.run(args, cwd=ROOT, capture_output=True)
    output = (p.stdout + p.stderr).decode("utf-8", "replace")
    if p.returncode:
        raise RuntimeError(" ".join(args) + "\n" + output)
    return output.strip()


def main():
    versions = run(["moon", "version", "--all"])
    versions = "\n".join(re.sub(r"\)\s+.*$", ")", line) for line in versions.splitlines())
    evidence = {"date": "2026-10-18", "platform": platform.system(), "toolchain": versions, "checks": {}}
    evidence["checks"]["format"] = run(["moon", "fmt", "--check"])
    demos = []
    for target in ["wasm-gc", "js"]:
        evidence["checks"][target] = {kind: run(["moon", kind, "--target", target, "--deny-warn", *(["--warn-list", "+73"] if kind == "check" else [])]) for kind in ["check", "test", "build"]}
        demos.append(json.loads(run(["moon", "run", "examples/replay", "--target", target])))
    assert demos[0] == demos[1]
    cli = ROOT / "_build/js/debug/build/cmd/main/main.js"
    with tempfile.TemporaryDirectory(dir=ROOT / "release-local", prefix="cli-") as tmp:
        tmp = Path(tmp)
        bad = tmp / "invalid.mountinfo"
        bad.write_text("not mountinfo", encoding="utf-8")
        invalid_utf8 = tmp / "invalid-utf8.mountinfo"
        invalid_utf8.write_bytes(b"\xff")
        huge = tmp / "huge.mountinfo"
        with huge.open("wb") as f:
            f.truncate(8 * 1024 * 1024 + 1)
        cases = [[], ["unknown"], ["inspect", str(bad), "s"], ["inspect", str(tmp / "missing"), "s"], ["inspect", str(invalid_utf8), "s"], ["inspect", str(huge), "s"], ["resolve", "fixtures/stacked.mountinfo", "s", "relative"]]
        for args in cases:
            p = subprocess.run(["node", str(cli), *args], cwd=ROOT, capture_output=True)
            assert p.returncode == 1 and p.stderr and not p.stdout, args
        message = subprocess.run(["node", str(cli), "inspect", str(bad), "s"], cwd=ROOT, capture_output=True)
        assert b"mountinfo line 1:" in message.stderr
        if platform.system() != "Linux":
            p = subprocess.run(["node", str(cli), "live"], cwd=ROOT, capture_output=True)
            assert p.returncode == 1
    evidence["cli_error_cases"] = len(cases)
    evidence["cross_backend_demo"] = "identical JSON"
    evidence["result"] = "passed"
    out = ROOT / "docs/test-evidence"
    out.mkdir(parents=True, exist_ok=True)
    (out / "offline.json").write_text(json.dumps(evidence, indent=2) + "\n")
    print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
