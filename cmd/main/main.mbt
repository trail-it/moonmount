///|
fn read(path : String, max_bytes~ : Int32 = 8388608) -> String raise {
  let result = read_text(path, max_bytes)
  if result[0] != "ok" {
    fail(result[1])
  }
  result[1]
}

///|
fn load_snapshot(path : String) -> @mount.Snapshot raise {
  @mount.decode_snapshot(read(path, max_bytes=67108864))
}

///|
fn save_snapshot(snapshot : @mount.Snapshot, path : String) -> Unit raise {
  let result = write_new(path, snapshot.encode() + "\n")
  if result[0] != "ok" {
    fail(result[1])
  }
  let output : Json = {
    "schema": 1,
    "saved": Json(path),
    "namespace_id": Json(snapshot.namespace_id()),
    "mount_count": Json(snapshot.mounts().length()),
  }
  println(output.stringify())
}

///|
fn compare_snapshots(
  before : @mount.Snapshot,
  after : @mount.Snapshot,
) -> Unit raise {
  let changes = before.diff(after)
  let mut added = 0
  let mut removed = 0
  let mut changed = 0
  let mut replaced = 0
  for change in changes {
    match change.kind {
      Added => added += 1
      Removed => removed += 1
      Changed => changed += 1
      Replaced => replaced += 1
    }
  }
  let result : Json = {
    "schema": 1,
    "namespace_id": Json(before.namespace_id()),
    "summary": {
      "added": Json(added),
      "removed": Json(removed),
      "changed": Json(changed),
      "replaced": Json(replaced),
    },
    "changes": Json(changes),
  }
  println(result.stringify())
}

///|
fn help() -> Unit {
  let usage =
    #|MoonMount 0.2.0 - Linux mount topology and portable snapshots
    #|Usage: node moonmount.cjs COMMAND [ARGS]
    #|
    #|  capture NEW_SNAPSHOT             Capture this Linux namespace to a new file
    #|  import RAW_FILE NAMESPACE NEW_SNAPSHOT
    #|                                   Save externally collected mountinfo
    #|  show SNAPSHOT                    Inspect a saved snapshot (any platform)
    #|  query SNAPSHOT /absolute/path    Resolve a path from a saved snapshot
    #|  compare BEFORE AFTER             Compare saved snapshots; namespace checked
    #|  live [/absolute/path]            Inspect current Linux mounts without saving
    #|
    #|Raw-text compatibility commands:
    #|  inspect RAW_FILE NAMESPACE
    #|  resolve RAW_FILE NAMESPACE /absolute/path
    #|  diff OLD_RAW NEW_RAW SAME_NAMESPACE
    #|
    #|  --help | help                    Show this help
    #|  --version                        Show version
    #|Output files must be new paths; parent directories must exist.
    #|Path queries are lexical: symlinks and file permissions are not resolved.
    #|Success: exit 0, errors: stderr and exit 1. JSON commands emit one JSON value.
  println(usage)
}

///|
fn live() -> @mount.Snapshot raise {
  let start = live_input()
  if start[0] != "ok" {
    fail(start[1])
  }
  let text = read("/proc/self/mountinfo")
  let finish = live_input()
  if finish[0] != "ok" || start[1] != finish[1] {
    fail("mount namespace changed during capture")
  }
  @mount.parse(text, namespace_id=start[1])
}

///|
fn report(s : @mount.Snapshot, path : String?) -> Unit raise {
  let result : Json = match path {
    None =>
      {
        "schema": 1,
        "namespace_id": Json(s.namespace_id()),
        "mounts": Json(s.mounts()),
      }
    Some(path) =>
      {
        "schema": 1,
        "namespace_id": Json(s.namespace_id()),
        "resolution": Json(s.resolve(path)),
      }
  }
  println(result.stringify())
}

///|
fn run(args : Array[String]) -> Unit raise {
  match args {
    [] | ["--help"] | ["-h"] | ["help"] => help()
    ["--version"] => println("0.2.0")
    ["capture", output] => save_snapshot(live(), output)
    ["import", input, token, output] =>
      save_snapshot(@mount.parse(read(input), namespace_id=token), output)
    ["show", input] => report(load_snapshot(input), None)
    ["query", input, path] => report(load_snapshot(input), Some(path))
    ["compare", before, after] =>
      compare_snapshots(load_snapshot(before), load_snapshot(after))
    ["inspect", input, token] =>
      report(@mount.parse(read(input), namespace_id=token), None)
    ["resolve", input, token, path] =>
      report(@mount.parse(read(input), namespace_id=token), Some(path))
    ["diff", old, newer, token] => {
      let a = @mount.parse(read(old), namespace_id=token)
      let b = @mount.parse(read(newer), namespace_id=token)
      println(Json(a.diff(b)).stringify())
    }
    ["live"] => report(live(), None)
    ["live", path] => report(live(), Some(path))
    _ => fail("invalid command or arguments; use --help for usage")
  }
}

///|
fn main {
  run(Array::from_iter(arguments().iter())) catch {
    @mount.MountError::Invalid(line~, reason~) =>
      failure("mountinfo line \{line}: \{reason}")
    @mount.MountError::Limit(reason~) => failure("input limit: \{reason}")
    @mount.MountError::Topology(reason~) => failure("topology: \{reason}")
    @mount.MountError::InvalidPath(path) =>
      failure("noncanonical absolute path: \{path}")
    @mount.MountError::NamespaceMismatch => failure("mount namespace mismatch")
    @mount.MountError::InvalidSnapshot(reason~) =>
      failure(
        "saved snapshot: \{reason}; create snapshots with capture or import",
      )
    error => failure(error.to_string())
  }
}
