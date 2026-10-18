///|
fn base() -> String {
  "1 99 8:1 / / rw shared:7 - ext4 /dev/test rw\n"
}

///|
fn stacked() -> String {
  base() +
  "2 1 8:1 /old /work rw - ext4 /dev/test rw\n" +
  "3 2 0:4 / /work/hidden rw - tmpfs tmpfs rw\n" +
  "4 2 8:2 /project /work ro master:7 - ext4 /dev/other rw\n" +
  "5 4 0:5 / /work/cache rw shared:8 master:7 propagate_from:7 future:abc - tmpfs tmpfs rw\n"
}

///|
test "all fields, independent mount/super options, propagation groups" {
  let s = @moonmount.parse(stacked(), namespace_id="synthetic")
  assert_eq(s.mounts().length(), 5)
  assert_eq(s.namespace_id(), "synthetic")
  let bind = s.get(4).unwrap()
  assert_eq(bind.root, "/project")
  assert_true(bind.read_only())
  assert_false(bind.super_read_only())
  assert_eq(s.peers(7).map(m => m.id), [1])
  assert_eq(s.slaves(7).map(m => m.id), [4, 5])
  assert_eq(
    s.get(5).unwrap().optional_fields,
    "shared:8 master:7 propagate_from:7 future:abc",
  )
  assert_eq(s.get(5).unwrap().propagate_from, Some(7))
  assert_eq(s.children(2).map(m => m.id), [3, 4])
  assert_eq(s.ancestors(5).map(m => m.id), [5, 4, 2, 1])
}

///|
test "overmount hides old nested mount, while new children remain visible" {
  let s = @moonmount.parse(stacked(), namespace_id="synthetic")
  let hidden = s.resolve("/work/hidden/file")
  assert_eq(hidden.mount.id, 4)
  assert_eq(hidden.filesystem_path, Some("/project/hidden/file"))
  assert_eq(hidden.chain, [1, 2, 4])
  assert_eq(s.resolve("/work/cache/key").mount.id, 5)
  assert_eq(s.resolve("/work/cache/key").filesystem_path, Some("/key"))
}

///|
test "component prefix, exact bind root and root join" {
  let s = @moonmount.parse(stacked(), namespace_id="synthetic")
  assert_eq(s.resolve("/work").filesystem_path, Some("/project"))
  assert_eq(s.resolve("/workspace/a").mount.id, 1)
  assert_eq(s.resolve("/").filesystem_path, Some("/"))
  assert_eq(s.resolve("/other").filesystem_path, Some("/other"))
}

///|
test "root stacked mount hides old root children" {
  let text = base() +
    "2 1 0:4 / /old rw - tmpfs tmpfs rw\n3 1 8:2 /sub / rw - ext4 /dev/new rw\n"
  let s = @moonmount.parse(text, namespace_id="synthetic")
  let r = s.resolve("/old/a")
  assert_eq(r.mount.id, 3)
  assert_eq(r.chain, [1, 3])
  assert_eq(r.filesystem_path, Some("/sub/old/a"))
}

///|
test "out of order records and missing outer parents" {
  let s = @moonmount.parse(
    "2 1 0:4 / /a rw - tmpfs tmpfs rw\n" + base(),
    namespace_id="synthetic",
  )
  assert_eq(s.resolve("/a/file").mount.id, 2)
  assert_eq(s.ancestors(1).length(), 1)
  assert_eq(s.get(99), None)
  assert_eq(s.children(99).map(m => m.id), [1])
  assert_eq(s.ancestors(99), [])
}

///|
test "all four kernel escapes and Unicode paths" {
  let text = base() +
    "2 1 8:1 /文档 /目录\\040A\\011B\\012C\\134D rw - ext4 /dev/a\\040b rw\n"
  let s = @moonmount.parse(text, namespace_id="synthetic")
  let m = s.get(2).unwrap()
  assert_eq(m.point, "/目录 A\tB\nC\\D")
  assert_eq(m.source, "/dev/a b")
  assert_eq(
    s.resolve(m.point + "/题目").filesystem_path,
    Some("/文档/题目"),
  )
}

///|
test "literal backslash escape is decoded only once" {
  let s = @moonmount.parse(
    base() + "2 1 8:1 / /a\\134040 rw - ext4 x rw\n",
    namespace_id="synthetic",
  )
  assert_eq(s.get(2).unwrap().point, "/a\\040")
}

///|
test "self-parent namespace root" {
  let s = @moonmount.parse(
    "1 1 0:1 /sub / ro - tmpfs tmpfs ro",
    namespace_id="synthetic",
  )
  assert_eq(s.ancestors(1).length(), 1)
  assert_eq(s.resolve("/a").filesystem_path, Some("/sub/a"))
  assert_true(s.get(1).unwrap().super_read_only())
}

///|
test "snapshot arrays do not expose internal mutation" {
  let s = @moonmount.parse(stacked(), namespace_id="synthetic")
  s.mounts().clear()
  s.children(2).clear()
  assert_eq(s.mounts().length(), 5)
  assert_eq(s.resolve("/work/hidden").mount.id, 4)
}

///|
test "ambiguous siblings refuse to guess and irrelevant siblings do not interfere" {
  let s = @moonmount.parse(
    base() + "2 1 0:2 / /a rw - tmpfs x rw\n3 1 0:3 / /a rw - tmpfs x rw\n",
    namespace_id="synthetic",
  )
  assert_true(
    try {
      ignore(s.resolve("/a"))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(s.resolve("/b").mount.id, 1)
}

///|
test "partial table remains inspectable but cannot resolve without a root" {
  let s = @moonmount.parse(
    "2 77 0:2 / /a rw - tmpfs x rw",
    namespace_id="synthetic",
  )
  assert_eq(s.mounts().length(), 1)
  assert_true(
    try {
      ignore(s.resolve("/a"))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "invalid graph cycles, duplicate IDs and impossible child paths" {
  let bad = [
    base() + "1 99 8:1 / / rw - ext4 x rw\n",
    "1 2 0:1 / / rw - tmpfs x rw\n2 1 0:1 / / rw - tmpfs x rw\n",
    "1 1 0:1 / /a rw - tmpfs x rw\n",
    base() + "2 1 0:2 / /a rw - tmpfs x rw\n3 2 0:3 / /b rw - tmpfs x rw\n",
  ]
  for text in bad {
    assert_true(
      try {
        ignore(@moonmount.parse(text, namespace_id="s"))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "path contract rejects normalization guesses" {
  let s = @moonmount.parse(base(), namespace_id="s")
  for path in ["", "a", "/a/", "//a", "/a//b", "/a/./b", "/a/../b", "/a\u0000b"] {
    assert_true(
      try {
        ignore(s.resolve(path))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "strict integer syntax and overflow" {
  for
    prefix in [
      "0 1 0:1", "-1 1 0:1", "+1 1 0:1", "2147483648 1 0:1", "1 0 0:1", "1 1 -1:0",
      "1 1 0:2147483648", "1 1 0", "1 1 0:1:2",
    ] {
    assert_true(
      try {
        ignore(
          @moonmount.parse(prefix + " / / rw - tmpfs x rw", namespace_id="s"),
        )
        false
      } catch {
        _ => true
      },
    )
  }
  let s = @moonmount.parse(
    "2147483647 2147483647 2147483647:0 / / rw - tmpfs x rw",
    namespace_id="s",
  )
  assert_eq(s.mounts()[0].major, 2147483647)
}

///|
test "invalid layout, raw control bytes and escape errors" {
  for
    text in [
      "",
      "\n",
      base() + "\n",
      "1 1 0:1 / / rw tmpfs x rw",
      "1 1 0:1 / / rw - tmpfs x rw extra",
      "1  1 0:1 / / rw - tmpfs x rw",
      "1 1 0:1 / /a\\04 rw - tmpfs x rw",
      "1 1 0:1 / /a\\041 rw - tmpfs x rw",
      "1 1 0:1 / / rw\t - tmpfs x rw",
      "1 1 0:1 / / rw - tmpfs x rw\r\n",
    ] {
    assert_true(
      try {
        ignore(@moonmount.parse(text, namespace_id="s"))
        false
      } catch {
        _ => true
      },
    )
  }
}

///|
test "invalid propagation fields versus forward compatible unknown tags" {
  for
    tags in [
      "shared:0", "shared:1 shared:2", "master:x", "master:1:2", "unbindable:1",
      "shared:1 unbindable", "master:1 unbindable", "propagate_from:1",
    ] {
    assert_true(
      try {
        ignore(
          @moonmount.parse(
            "1 1 0:1 / / rw " + tags + " - tmpfs x rw",
            namespace_id="s",
          ),
        )
        false
      } catch {
        _ => true
      },
    )
  }
  let s = @moonmount.parse(
    "1 1 0:1 / / rw experimental:value unbindable - tmpfs x rw",
    namespace_id="s",
  )
  assert_true(s.get(1).unwrap().unbindable)
  assert_eq(s.get(1).unwrap().optional_fields, "experimental:value unbindable")
}

///|
test "line and namespace budgets" {
  assert_true(
    try {
      ignore(@moonmount.parse(base(), namespace_id=""))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonmount.parse(base(), namespace_id="x".repeat(257)))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@moonmount.parse("x".repeat(65537), namespace_id="s"))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(
        @moonmount.parse("x".repeat(8 * 1024 * 1024 + 1), namespace_id="s"),
      )
      false
    } catch {
      _ => true
    },
  )
}

///|
test "diff has four distinct changes in stable input order" {
  let before = @moonmount.parse(
    base() +
    "2 1 0:2 / /a rw - tmpfs x rw\n3 1 0:3 / /b rw - tmpfs y rw\n4 1 0:4 / /c rw - tmpfs z rw\n",
    namespace_id="s",
  )
  let after = @moonmount.parse(
    base() +
    "2 1 0:2 / /a ro - tmpfs x rw\n3 1 0:30 / /b rw - tmpfs y rw\n5 1 0:5 / /d rw - tmpfs k rw\n",
    namespace_id="s",
  )
  assert_eq(before.diff(after).map(c => c.kind), [
    Changed,
    Replaced,
    Removed,
    Added,
  ])
  assert_eq(before.diff(after)[0].before.unwrap().options, "rw")
  assert_eq(before.diff(after)[0].after.unwrap().options, "ro")
  assert_eq(before.diff(before).length(), 0)
}

///|
test "namespace changes reject object comparison" {
  let a = @moonmount.parse(base(), namespace_id="a")
  let b = @moonmount.parse(base(), namespace_id="b")
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
test "namespace pseudo-filesystem root is preserved as an opaque identifier" {
  let s = @moonmount.parse(
    base() + "2 1 0:4 mnt:[12345] /ns rw - nsfs nsfs rw\n",
    namespace_id="synthetic",
  )
  let r = s.resolve("/ns")
  assert_eq(r.mount.root, "mnt:[12345]")
  assert_eq(r.mount.id, 2)
  assert_eq(r.filesystem_path, None)
}

///|
test "record count accepts its documented bound and rejects the next record" {
  let text = StringBuilder()
  text.write_string("1 1 0:1 / / rw - tmpfs x rw\n")
  for id in 2..<=16384 {
    text.write_string("\{id} 1 0:1 / /m\{id} rw - tmpfs x rw\n")
  }
  assert_eq(
    @moonmount.parse(text.to_string(), namespace_id="s").mounts().length(),
    16384,
  )
  text.write_string("16385 1 0:1 / /last rw - tmpfs x rw\n")
  assert_true(
    try {
      ignore(@moonmount.parse(text.to_string(), namespace_id="s"))
      false
    } catch {
      _ => true
    },
  )
}
