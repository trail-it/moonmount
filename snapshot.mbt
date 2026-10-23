///|
/// Portable versioned snapshot containing the original text and namespace ID.
/// This preserves unknown fields and distinguishes it from a display-only report.
pub fn Snapshot::encode(self : Snapshot) -> String {
  let document : Json = {
    "format": "moonmount.snapshot",
    "schema": 1,
    "namespace_id": Json(self.token),
    "mountinfo": Json(self.source_text),
  }
  document.stringify()
}

///|
/// Decode a saved snapshot and rebuild the validated immutable topology.
/// Namespace identity is retained; comparing different IDs raises NamespaceMismatch.
pub fn decode_snapshot(text : String) -> Snapshot raise MountError {
  // JSON may expand a source character to six ASCII escape characters.
  if text.length() > 64 * 1024 * 1024 {
    raise InvalidSnapshot(reason="snapshot exceeds 64 Mi code-unit budget")
  }
  let document = @json.parse(text) catch {
    _ => raise InvalidSnapshot(reason="invalid snapshot JSON")
  }
  match document {
    {
      "format": String("moonmount.snapshot"),
      "schema": Number(1.0, ..),
      "namespace_id": String(token),
      "mountinfo": String(source),
      ..
    } => parse(source, namespace_id=token)
    _ =>
      raise InvalidSnapshot(
        reason="expected moonmount.snapshot schema 1 with namespace_id and mountinfo strings",
      )
  }
}
