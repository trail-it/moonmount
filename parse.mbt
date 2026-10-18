///|
fn number(
  text : String,
  line : Int32,
  positive~ : Bool = false,
) -> Int32 raise MountError {
  if text.is_empty() {
    raise Invalid(line~, reason="empty integer")
  }
  let mut n = 0
  for c in text {
    if c < '0' || c > '9' {
      raise Invalid(line~, reason="non-decimal integer")
    }
    let digit = c.to_int() - 48
    if n > (2147483647 - digit) / 10 {
      raise Invalid(line~, reason="integer overflow")
    }
    n = n * 10 + digit
  }
  if positive && n == 0 {
    raise Invalid(line~, reason="ID must be positive")
  }
  n
}

///|
fn unescape(text : String, line : Int32) -> String raise MountError {
  let chars = text.to_array()
  let out = StringBuilder()
  for i = 0; i < chars.length(); {
    let c = chars[i]
    if c == '\\' {
      if i + 3 >= chars.length() {
        raise Invalid(line~, reason="truncated escape")
      }
      let a = chars[i + 1]
      let b = chars[i + 2]
      let c = chars[i + 3]
      let decoded : Char = match (a, b, c) {
        ('0', '4', '0') => ' '
        ('0', '1', '1') => '\t'
        ('0', '1', '2') => '\n'
        ('1', '3', '4') => '\\'
        _ => raise Invalid(line~, reason="unsupported escape")
      }
      out.write_char(decoded)
      continue i + 4
    } else {
      if c == '\u0000' || c == '\t' || c == '\r' {
        raise Invalid(line~, reason="unescaped control character")
      }
      out.write_char(c)
      continue i + 1
    }
  }
  out.to_string()
}

///|
/// Check canonical absolute namespace_id paths without following symlinks.
fn valid_path(path : String) -> Bool {
  if !path.has_prefix("/") || path.contains_char('\u0000') {
    return false
  }
  if path == "/" {
    return true
  }
  if path.has_suffix("/") {
    return false
  }
  for part in path.strip_prefix("/").unwrap().split("/") {
    if part == "" || part == "." || part == ".." {
      return false
    }
  }
  true
}

///|
fn parse_line(text : String, line : Int32) -> Mount raise MountError {
  if text.iter().any(fn(c) { c.to_int() < 32 || c.to_int() == 127 }) {
    raise Invalid(line~, reason="raw control character")
  }
  let fields = text.split(" ").map(fn(s) { s.to_owned() }).collect()
  if fields.any(fn(s) { s == "" }) || fields.length() < 10 {
    raise Invalid(line~, reason="invalid field layout")
  }
  // Only the delimiter position after the six fixed fields is significant.
  let mut sep = -1
  for i in 6..<fields.length() {
    if fields[i] == "-" {
      sep = i
      break
    }
  }
  if sep < 6 || fields.length() != sep + 4 {
    raise Invalid(line~, reason="missing separator or trailing fields")
  }
  let dev = fields[2].split(":").map(fn(s) { s.to_owned() }).collect()
  if dev.length() != 2 {
    raise Invalid(line~, reason="invalid device")
  }
  let id = number(fields[0], line, positive=true)
  let parent_id = number(fields[1], line, positive=true)
  let major = number(dev[0], line)
  let minor = number(dev[1], line)
  let root = unescape(fields[3], line)
  let point = unescape(fields[4], line)
  if root.is_empty() || !valid_path(point) {
    raise Invalid(line~, reason="empty root or noncanonical mountpoint")
  }
  let tags : Map[String, Bool] = Map([])
  let optional : Array[String] = []
  let mut shared = None
  let mut master = None
  let mut propagate_from = None
  let mut unbindable = false
  for i in 6..<sep {
    let field = fields[i]
    optional.push(field)
    let tag = field.split(":").next().unwrap().to_owned()
    if tag == "shared" ||
      tag == "master" ||
      tag == "propagate_from" ||
      tag == "unbindable" {
      if tags.contains(tag) {
        raise Invalid(line~, reason="duplicate propagation tag")
      }
      tags[tag] = true
      if tag == "unbindable" {
        if field != "unbindable" {
          raise Invalid(line~, reason="invalid unbindable tag")
        }
        unbindable = true
      } else {
        let parts = field.split(":").map(fn(s) { s.to_owned() }).collect()
        if parts.length() != 2 {
          raise Invalid(line~, reason="invalid propagation field")
        }
        let group = number(parts[1], line, positive=true)
        match tag {
          "shared" => shared = Some(group)
          "master" => master = Some(group)
          _ => propagate_from = Some(group)
        }
      }
    }
  }
  if (unbindable && (shared != None || master != None)) ||
    (propagate_from != None && master == None) {
    raise Invalid(line~, reason="inconsistent propagation tags")
  }
  {
    id,
    parent_id,
    major,
    minor,
    root,
    point,
    options: fields[5],
    optional_fields: optional.join(" "),
    shared,
    master,
    propagate_from,
    unbindable,
    fs_type: unescape(fields[sep + 1], line),
    source: unescape(fields[sep + 2], line),
    super_options: fields[sep + 3],
  }
}

///|
/// Parse a complete mountinfo text (maximum 8 Mi UTF-16 units / 16384 mounts).
/// Missing parents are legal for process roots that hide outer mounts.
pub fn parse(
  text : String,
  namespace_id~ : String,
) -> Snapshot raise MountError {
  if namespace_id.is_empty() || namespace_id.length() > 256 {
    raise Limit(reason="namespace_id token must contain 1..256 code units")
  }
  if text.length() > 8 * 1024 * 1024 {
    raise Limit(reason="mountinfo exceeds text budget")
  }
  let entries : Array[Mount] = []
  let index : Map[Int32, Mount] = Map([])
  let child_index : Map[Int32, Array[Mount]] = Map([])
  let lines = text.split("\n").collect()
  for i, raw in lines {
    if i == lines.length() - 1 && raw == "" {
      continue
    }
    if entries.length() >= 16384 {
      raise Limit(reason="too many mounts")
    }
    if raw.length() > 65536 {
      raise Limit(reason="mountinfo line exceeds budget")
    }
    let mount = parse_line(raw.to_owned(), i + 1)
    if index.contains(mount.id) {
      raise Invalid(line=i + 1, reason="duplicate mount ID")
    }
    entries.push(mount)
    index[mount.id] = mount
    if mount.id != mount.parent_id {
      match child_index.get(mount.parent_id) {
        Some(children) => children.push(mount)
        None => child_index[mount.parent_id] = [mount]
      }
    } else if mount.point != "/" {
      raise Topology(reason="self-parent is only allowed at namespace_id root")
    }
  }
  if entries.is_empty() {
    raise Topology(reason="empty mount table")
  }
  // Each node is visited at most once in this graph validation.
  let done : Map[Int32, Bool] = Map([])
  for entry in entries {
    let path : Array[Int32] = []
    let active : Map[Int32, Bool] = Map([])
    let mut current = Some(entry)
    while current is Some(m) {
      if done.contains(m.id) {
        break
      }
      if active.contains(m.id) {
        raise Topology(reason="parent cycle")
      }
      active[m.id] = true
      path.push(m.id)
      if m.id == m.parent_id {
        break
      }
      current = index.get(m.parent_id)
      if current is Some(parent) && !path_prefix(parent.point, m.point) {
        raise Topology(reason="child mountpoint outside parent mountpoint")
      }
    }
    for id in path {
      done[id] = true
    }
  }
  { token: namespace_id, entries, index, child_index, }
}
