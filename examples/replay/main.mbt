///|
fn main raise {
  let text =
    #|1 99 8:1 / / rw shared:7 - ext4 /dev/demo rw
    #|2 1 8:1 /old /work rw - ext4 /dev/demo rw
    #|3 2 0:4 / /work/hidden rw - tmpfs tmpfs rw
    #|4 2 8:2 /project /work ro master:7 - ext4 /dev/new rw
    #|
  let before = @mount.parse(text, namespace_id="synthetic-demo")
  let after = @mount.parse(
    text.replace(old="/work ro", new="/work rw"),
    namespace_id="synthetic-demo",
  )
  let report : Json = {
    "input": "synthetic-demo",
    "resolution": Json(before.resolve("/work/hidden/file")),
    "changes": Json(before.diff(after)),
  }
  println(report.stringify())
}
