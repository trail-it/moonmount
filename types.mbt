///|
/// Parsing and topology failures are explicit; malformed input is never skipped.
pub suberror MountError {
  Invalid(line~ : Int, reason~ : String)
  Limit(reason~ : String)
  Topology(reason~ : String)
  InvalidPath(String)
  NamespaceMismatch
} derive(Debug, Eq)

///|
/// Immutable mount record. Options retain their comma separated spelling.
pub struct Mount {
  id : Int
  parent_id : Int
  major : Int
  minor : Int
  root : String
  point : String
  options : String
  optional_fields : String
  shared : Int?
  master : Int?
  propagate_from : Int?
  unbindable : Bool
  fs_type : String
  source : String
  super_options : String
} derive(Debug, Eq, ToJson)

///|
/// Namespace identity must describe a single namespace lifetime.
pub struct Snapshot {
  priv token : String
  priv entries : Array[Mount]
  priv index : Map[Int, Mount]
  priv child_index : Map[Int, Array[Mount]]
} derive(Debug)

///|
pub struct Resolution {
  mount : Mount
  filesystem_path : String
  chain : Array[Int]
} derive(Debug, ToJson)

///|
pub(all) enum ChangeKind {
  Added
  Removed
  Changed
  Replaced
} derive(Debug, Eq, ToJson)

///|
pub struct Change {
  kind : ChangeKind
  before : Mount?
  after : Mount?
} derive(Debug, ToJson)

///|
/// Per-mount read-only state, distinct from superblock read-only state.
pub fn Mount::read_only(self : Mount) -> Bool {
  self.options.split(",").any(fn(v) { v == "ro" })
}

///|
pub fn Mount::super_read_only(self : Mount) -> Bool {
  self.super_options.split(",").any(fn(v) { v == "ro" })
}
