///|
extern "js" fn arguments() -> FixedArray[String] =
  #|() => process.argv.slice(2)

///|
/// Host I/O only: mount parsing, snapshot format and comparison remain MoonBit.
extern "js" fn read_text(path : String, maximum : Int32) -> FixedArray[String] =
  #|(path, maximum) => { try { const fs = require('node:fs'); const fd = fs.openSync(path, 'r'); try { const parts=[]; let size=0; for (;;) { const b=Buffer.alloc(65536); const n=fs.readSync(fd,b,0,b.length,null); if(!n) break; size+=n; if(size>maximum) throw Error('input exceeds '+maximum+' bytes'); parts.push(b.subarray(0,n)); } return ['ok',new TextDecoder('utf-8',{fatal:true}).decode(Buffer.concat(parts))]; } finally {fs.closeSync(fd)} } catch(e) {return ['error',String(e.message)]} }

///|
extern "js" fn live_input() -> FixedArray[String] =
  #|() => { try { if(process.platform!=='linux') throw Error('capture/live requires Linux; use import/show/query/compare for offline snapshots'); const fs=require('node:fs'); return ['ok',fs.readFileSync('/proc/sys/kernel/random/boot_id','utf8').trim()+':'+fs.readlinkSync('/proc/self/ns/mnt')]; } catch(e) {return ['error',String(e.message)]} }

///|
/// Exclusive creation protects existing files; restrictive mode applies on POSIX.
extern "js" fn write_new(path : String, text : String) -> FixedArray[String] =
  #|(path, text) => { const fs=require('node:fs'); let fd; try { fd=fs.openSync(path,'wx',0o600); fs.writeFileSync(fd,text,{encoding:'utf8'}); fs.closeSync(fd); return ['ok','']; } catch(e) { if(fd!==undefined) {try{fs.closeSync(fd)}catch(_){} try{fs.unlinkSync(path)}catch(_){} } return ['error',String(e.message)]; } }

///|
extern "js" fn failure(message : String) -> Unit =
  #|(message) => {console.error(message);process.exitCode=1}
