///|
fn path_prefix(prefix : String, path : String) -> Bool {
  prefix == "/" || prefix == path || path.has_prefix(prefix + "/")
}

///|
pub fn Snapshot::namespace_id(self : Snapshot) -> String {
  self.token
}

///|
/// Returns a copy: modifying the returned array cannot change the snapshot.
pub fn Snapshot::mounts(self : Snapshot) -> Array[Mount] {
  self.entries.copy()
}

///|
pub fn Snapshot::get(self : Snapshot, id : Int) -> Mount? {
  self.index.get(id)
}

///|
pub fn Snapshot::children(self : Snapshot, id : Int) -> Array[Mount] {
  match self.child_index.get(id) {
    Some(v) => v.copy()
    None => []
  }
}

///|
/// Self followed by visible recorded parents. A missing outer parent stops traversal.
pub fn Snapshot::ancestors(self : Snapshot, id : Int) -> Array[Mount] {
  let out : Array[Mount] = []
  let mut next = self.get(id)
  while next is Some(m) {
    out.push(m)
    if m.id == m.parent_id {
      break
    }
    next = self.get(m.parent_id)
  }
  out
}

///|
pub fn Snapshot::peers(self : Snapshot, group : Int) -> Array[Mount] {
  self.entries.filter(fn(m) { m.shared == Some(group) })
}

///|
/// Direct slave mounts whose master peer group is `group`.
pub fn Snapshot::slaves(self : Snapshot, group : Int) -> Array[Mount] {
  self.entries.filter(fn(m) { m.master == Some(group) })
}

///|
/// Resolve lexically through the *visible parent tree*, not global longest prefix.
/// Rejects ambiguous siblings and snapshots lacking a unique recorded root.
pub fn Snapshot::resolve(
  self : Snapshot,
  path : String,
) -> Resolution raise MountError {
  if !valid_path(path) {
    raise InvalidPath(path)
  }
  let roots = self.entries.filter(fn(m) {
    m.point == "/" && (m.id == m.parent_id || !self.index.contains(m.parent_id))
  })
  if roots.length() != 1 {
    raise Topology(reason="no unique namespace_id root")
  }
  let mut current = roots[0]
  let chain = [current.id]
  for ;; {
    let mut next : Mount? = None
    let mut ambiguous = false
    for m in self.children(current.id) {
      if !path_prefix(m.point, path) {
        continue
      }
      match next {
        None => {
          next = Some(m)
          ambiguous = false
        }
        Some(previous) =>
          if m.point.length() < previous.point.length() {
            next = Some(m)
            ambiguous = false
          } else if m.point.length() == previous.point.length() {
            ambiguous = true
          }
      }
    }
    if ambiguous {
      raise Topology(reason="ambiguous sibling mounts")
    }
    match next {
      None => break
      Some(m) => {
        current = m
        chain.push(m.id)
      }
    }
  }
  let suffix = if current.point == "/" {
    path.strip_prefix("/").unwrap().to_owned()
  } else if path == current.point {
    ""
  } else {
    path.strip_prefix(current.point + "/").unwrap().to_owned()
  }
  let filesystem_path = if suffix == "" {
    current.root
  } else if current.root == "/" {
    "/" + suffix
  } else {
    current.root + "/" + suffix
  }
  { mount: current, filesystem_path, chain, }
}

///|
/// Compare observations of the same namespace_id lifetime. IDs may be reused by Linux:
/// Replaced only means the observed (device, filesystem root/type/source) changed.
pub fn Snapshot::diff(
  self : Snapshot,
  newer : Snapshot,
) -> Array[Change] raise MountError {
  if self.token != newer.token {
    raise NamespaceMismatch
  }
  let changes : Array[Change] = []
  for before in self.entries {
    match newer.get(before.id) {
      None =>
        changes.push({ kind: Removed, before: Some(before), after: None, })
      Some(after) => {
        if before == after {
          continue
        }
        let replaced = before.major != after.major ||
          before.minor != after.minor ||
          before.root != after.root ||
          before.fs_type != after.fs_type ||
          before.source != after.source
        changes.push({
          kind: if replaced {
            Replaced
          } else {
            Changed
          },
          before: Some(before),
          after: Some(after),
        })
      }
    }
  }
  for after in newer.entries {
    if !self.index.contains(after.id) {
      changes.push({ kind: Added, before: None, after: Some(after), })
    }
  }
  changes
}
