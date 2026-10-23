///|
test "saved snapshot round trips raw text, opaque roots and propagation" {
  let text = "1 99 8:1 / / rw shared:7 future:opaque - ext4 /dev/test rw\n2 1 0:2 mnt:[42] /ns rw - nsfs nsfs rw\n3 1 8:1 /root\r /目录\\040A rw - ext4 /dev/a\\043b rw\n"
  let original = @moonmount.parse(text, namespace_id="synthetic-roundtrip")
  let restored = @moonmount.decode_snapshot(original.encode())
  assert_eq(restored.namespace_id(), original.namespace_id())
  assert_eq(restored.mounts(), original.mounts())
  assert_eq(
    restored.resolve("/目录 A/file").filesystem_path,
    Some("/root\r/file"),
  )
  assert_eq(restored.resolve("/ns").filesystem_path, None)
  assert_eq(restored.diff(original).length(), 0)
  assert_eq(restored.encode(), original.encode())
}

///|
test "saved snapshots retain different namespaces and refuse comparison" {
  let text = "1 1 0:1 / / rw - tmpfs x rw"
  let a = @moonmount.decode_snapshot(
    @moonmount.parse(text, namespace_id="a").encode(),
  )
  let b = @moonmount.decode_snapshot(
    @moonmount.parse(text, namespace_id="b").encode(),
  )
  assert_true(
    try {
      ignore(a.diff(b))
      false
    } catch {
      NamespaceMismatch => true
      _ => false
    },
  )
}

///|
test "snapshot input rejects malformed, unsupported or report-only documents" {
  let invalid = [
    "not JSON",
    "[]",
    "{}",
    "{\"format\":\"other\",\"schema\":1,\"namespace_id\":\"s\",\"mountinfo\":\"x\"}",
    "{\"format\":\"moonmount.snapshot\",\"schema\":2,\"namespace_id\":\"s\",\"mountinfo\":\"x\"}",
    "{\"format\":\"moonmount.snapshot\",\"schema\":1,\"namespace_id\":42,\"mountinfo\":\"x\"}",
    "{\"schema\":1,\"namespace_id\":\"s\",\"mounts\":[]}",
    "[".repeat(12) + "0" + "]".repeat(12),
  ]
  for text in invalid {
    assert_true(
      try {
        ignore(@moonmount.decode_snapshot(text))
        false
      } catch {
        InvalidSnapshot(_) => true
        _ => false
      },
    )
  }
}

///|
test "snapshot metadata cannot bypass mountinfo validation" {
  let document : Json = {
    "format": "moonmount.snapshot",
    "schema": 1,
    "namespace_id": "s",
    "mountinfo": "invalid mountinfo",
  }
  assert_true(
    try {
      ignore(@moonmount.decode_snapshot(document.stringify()))
      false
    } catch {
      Invalid(..) => true
      _ => false
    },
  )
}
