///|
/// Parsing and topology failures are explicit; malformed input is never skipped.
pub suberror MountError {
  Invalid(line~ : Int32, reason~ : String)
  Limit(reason~ : String)
  Topology(reason~ : String)
  InvalidPath(String)
  NamespaceMismatch
} derive(Debug, Eq)

///|
/// Immutable mount record. Options retain their comma separated spelling.
pub struct Mount {
  id : Int32
  parent_id : Int32
  major : Int32
  minor : Int32
  root : String
  point : String
  options : String
  optional_fields : String
  shared : Int32?
  master : Int32?
  propagate_from : Int32?
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
  priv index : Map[Int32, Mount]
  priv child_index : Map[Int32, Array[Mount]]
} derive(Debug)

///|
pub struct Resolution {
  mount : Mount
  filesystem_path : String?
  chain : Array[Int32]
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

///|
pub extend MountError with @debug.Debug::{to_repr}

///|
pub extend MountError with Eq::{equal, not_equal}

///|
pub extend Mount with @debug.Debug::{to_repr}

///|
pub extend Mount with Eq::{equal, not_equal}

///|
pub extend Mount with ToJson::{to_json}

///|
pub extend Snapshot with @debug.Debug::{to_repr}

///|
pub extend Resolution with @debug.Debug::{to_repr}

///|
pub extend Resolution with ToJson::{to_json}

///|
pub extend ChangeKind with @debug.Debug::{to_repr}

///|
pub extend ChangeKind with Eq::{equal, not_equal}

///|
pub extend ChangeKind with ToJson::{to_json}

///|
pub extend Change with @debug.Debug::{to_repr}

///|
pub extend Change with ToJson::{to_json}
