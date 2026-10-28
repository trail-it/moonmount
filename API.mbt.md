# MoonMount API 示例

安装 `moon add trail-it/moonmount@0.2.0`，在调用方 `moon.pkg` 导入 `"trail-it/moonmount" @mount`。下方库内文档测试使用 `@moonmount` 别名。

```mbt check
///|
test "documented public API" {
  let text = "10 99 8:1 / / rw shared:2 - ext4 /dev/demo rw\n11 10 8:1 /projects /work ro master:2 - ext4 /dev/demo rw\n"
  let snapshot = @moonmount.parse(text, namespace_id="synthetic-doc")
  let restored = @moonmount.decode_snapshot(snapshot.encode())
  assert_eq(restored.mounts(), snapshot.mounts())
  let resolved = restored.resolve("/work/main.mbt")
  assert_eq(resolved.mount.id, 11)
  assert_eq(resolved.filesystem_path, Some("/projects/main.mbt"))
  assert_true(resolved.mount.read_only())
  assert_false(resolved.mount.super_read_only())
  assert_eq(snapshot.peers(2).length(), 1)
  assert_eq(snapshot.slaves(2).length(), 1)
  assert_eq(snapshot.diff(snapshot).length(), 0)
}
```
