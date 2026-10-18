"""Independent component-by-component mount traversal, synthetic input only."""
from pathlib import Path
import json
import random
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "_build/js/debug/build/cmd/main/main.js"


def call(*args):
    p = subprocess.run(["node", str(CLI), *map(str, args)], cwd=ROOT, capture_output=True)
    if p.returncode:
        raise RuntimeError(p.stderr.decode("utf-8", "replace"))
    return json.loads(p.stdout)


def walk(records, path):
    """Visit every pathname component, following same-location mount stacks."""
    table = {r[0]: r for r in records}
    roots = [r for r in records if r[3] == "/" and (r[1] not in table or r[1] == r[0])]
    assert len(roots) == 1
    current = roots[0]
    chain = [current[0]]
    prefixes = ["/"] + ["/" + "/".join(path.strip("/").split("/")[:n])
                         for n in range(1, len(path.strip("/").split("/")) + 1)] if path != "/" else ["/"]
    for prefix in prefixes:
        while True:
            children = [r for r in records if r[1] == current[0] and r[0] != current[0] and r[3] == prefix]
            assert len(children) <= 1
            if not children:
                break
            current = children[0]
            chain.append(current[0])
    suffix = path[len(current[3]):].lstrip("/")
    internal = current[2].rstrip("/") + ("/" + suffix if suffix else "")
    return current[0], internal or "/", chain


def main():
    rng = random.Random(42618)
    records = [(1, 99, "/", "/")]
    points = ["/", "/a", "/a/b", "/a/b/c", "/a/c", "/x", "/x/y", "/z"]
    for identity in range(2, 38):
        point = rng.choice(points)
        parent, _, _ = walk(records, point)
        records.append((identity, parent, f"/sub{identity}", point))
    text = "".join(f"{i} {p} 0:{i} {root} {point} rw - tmpfs synthetic rw\n" for i, p, root, point in records)
    work = ROOT / "release-local"
    work.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="oracle-", dir=work) as tmp:
        fixture = Path(tmp) / "generated.mountinfo"
        fixture.write_text(text, encoding="utf-8")
        paths = sorted(set(points + [p.rstrip("/") + "/file" for p in points] + ["/aa", "/unknown", "/a/bb"]))
        for path in paths:
            actual = call("resolve", fixture, "synthetic-oracle", path)["resolution"]
            expected_id, expected_path, expected_chain = walk(records, path)
            assert (actual["mount"]["id"], actual["filesystem_path"], actual["chain"]) == (expected_id, expected_path, expected_chain), path
        # Fixed, independently hand-derived overmount fixture is the negative control
        # against a global longest-prefix resolver.
        actual = call("resolve", "fixtures/stacked.mountinfo", "synthetic", "/work/hidden/file")["resolution"]
        assert actual["mount"]["id"] == 4 and actual["filesystem_path"] == "/project/hidden/file"
        assert actual["mount"]["id"] != 3
    result = {"date": "2026-10-18", "oracle": "independent Python pathname-component traversal", "synthetic_mounts": len(records), "paths_compared": len(paths), "hidden_subtree_negative_control": "passed", "result": "passed"}
    (ROOT / "docs/test-evidence").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs/test-evidence/oracle.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
