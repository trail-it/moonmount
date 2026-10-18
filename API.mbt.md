# MoonMount API 示例

导入根包 `local/moonmount`，本地临时 namespace，尚未注册表发布。

```mbt check
///|
test "documented public API" {
  let text = "10 99 8:1 / / rw shared:2 - ext4 /dev/demo rw\n11 10 8:1 /projects /work ro master:2 - ext4 /dev/demo rw\n"
  let snapshot = @moonmount.parse(text, namespace_id="synthetic-doc")
  let resolved = snapshot.resolve("/work/main.mbt")
  assert_eq(resolved.mount.id, 11)
  assert_eq(resolved.filesystem_path, Some("/projects/main.mbt"))
  assert_true(resolved.mount.read_only())
  assert_false(resolved.mount.super_read_only())
  assert_eq(snapshot.peers(2).length(), 1)
  assert_eq(snapshot.slaves(2).length(), 1)
  assert_eq(snapshot.diff(snapshot).length(), 0)
}
```
