// Wait until MongoDB accepts TCP connections, so the first deploy doesn't crash
// while the database service is still starting. Gives up after WAIT_FOR_MONGO_SECONDS.
import net from 'node:net';
const uri = process.env.MONGODB_URI || '';
const m = uri.match(/^mongodb(?:\+srv)?:\/\/(?:[^@/]*@)?([^/?,]+)/);
if (!m) { console.log('[railway] MONGODB_URI not set or not parseable; not waiting'); process.exit(0); }
let host = m[1], port = 27017;
const hp = host.match(/^\[?([^\]]+?)\]?(?::(\d+))?$/);
if (hp) { host = hp[1]; if (hp[2]) port = Number(hp[2]); }
const deadline = Date.now() + Number(process.env.WAIT_FOR_MONGO_SECONDS || 180) * 1000;
const tryOnce = () => new Promise(res => {
  const s = net.connect({ host, port, family: 0, autoSelectFamily: true, timeout: 3000 });
  s.once('connect', () => { s.destroy(); res(true); });
  s.once('timeout', () => { s.destroy(); res(false); });
  s.once('error', () => res(false));
});
while (Date.now() < deadline) {
  if (await tryOnce()) { console.log(`[railway] MongoDB at ${host}:${port} is reachable`); process.exit(0); }
  console.log(`[railway] waiting for MongoDB at ${host}:${port} ...`);
  await new Promise(r => setTimeout(r, 2000));
}
console.log('[railway] MongoDB still unreachable; starting anyway');
