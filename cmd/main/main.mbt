///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
/// The host only reads bytes/namespace identity. All mount semantics are MoonBit.
extern "js" fn read_text(path : String) -> FixedArray[String] =
  #|(path) => { try { const fs = require('node:fs'); const fd = fs.openSync(path, 'r'); try { const parts=[]; let size=0; for (;;) { const b=Buffer.alloc(65536); const n=fs.readSync(fd,b,0,b.length,null); if(!n) break; size+=n; if(size>8388608) throw Error('input exceeds 8 MiB'); parts.push(b.subarray(0,n)); } return ['ok',new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(parts))]; } finally {fs.closeSync(fd)} } catch(e) {return ['error', String(e.message)]} }

///|
extern "js" fn live_input() -> FixedArray[String] =
  #|() => { try { if(process.platform!=='linux') throw Error('live requires Linux'); const fs=require('node:fs'); const boot=fs.readFileSync('/proc/sys/kernel/random/boot_id','utf8').trim(); const token=()=>boot+':'+fs.readlinkSync('/proc/self/ns/mnt'); const a=token(); return ['ok',a]; } catch(e) {return ['error',String(e.message)]} }

///|
extern "js" fn failure(message : String) -> Unit =
  #|(message) => {console.error(message);process.exitCode=1}

///|
fn read(path : String) -> String raise {
  let result = read_text(path)
  if result[0] != "ok" {
    fail(result[1])
  }
  result[1]
}

///|
fn live() -> @mount.Snapshot raise {
  let start = live_input()
  if start[0] != "ok" {
    fail(start[1])
  }
  let text = read("/proc/self/mountinfo")
  let finish = live_input()
  if finish[0] != "ok" || start[1] != finish[1] {
    fail("mount namespace changed during capture")
  }
  @mount.parse(text, namespace_id=start[1])
}

///|
fn report(s : @mount.Snapshot, path : String?) -> Unit raise {
  let result : Json = match path {
    None =>
      {
        "schema": 1,
        "namespace_id": s.namespace_id().to_json(),
        "mounts": s.mounts().to_json(),
      }
    Some(path) =>
      {
        "schema": 1,
        "namespace_id": s.namespace_id().to_json(),
        "resolution": s.resolve(path).to_json(),
      }
  }
  println(result.stringify())
}

///|
fn run(args : Array[String]) -> Unit raise {
  match args {
    ["inspect", input, token] =>
      report(@mount.parse(read(input), namespace_id=token), None)
    ["resolve", input, token, path] =>
      report(@mount.parse(read(input), namespace_id=token), Some(path))
    ["diff", old, newer, token] => {
      let a = @mount.parse(read(old), namespace_id=token)
      let b = @mount.parse(read(newer), namespace_id=token)
      println(a.diff(b).to_json().stringify())
    }
    ["live"] => report(live(), None)
    ["live", path] => report(live(), Some(path))
    _ =>
      fail(
        "usage: inspect FILE NAMESPACE | resolve FILE NAMESPACE ABS_PATH | diff OLD NEW SAME_NAMESPACE | live [ABS_PATH]",
      )
  }
}

///|
fn main {
  run(Array::from_iter(arguments().iter())) catch {
    error => failure(error.to_string())
  }
}
