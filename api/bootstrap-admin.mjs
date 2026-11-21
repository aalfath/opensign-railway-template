// Creates OpenSign's first administrator (and its organisation) from the deploy variables,
// through upstream's own `addadmin` cloud function, called with the master key.
// Runs next to the server on every start and does nothing once an administrator exists.
const base = 'http://127.0.0.1:8080/app';
const headers = {
  'Content-Type': 'application/json',
  'X-Parse-Application-Id': process.env.APP_ID || 'opensign',
  'X-Parse-Master-Key': process.env.MASTER_KEY,
};
const email = (process.env.OPENSIGN_ADMIN_EMAIL || '').trim().toLowerCase();
const password = process.env.OPENSIGN_ADMIN_PASSWORD || '';
const log = (m) => console.log(`[railway] admin bootstrap: ${m}`);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function call(fn, params = {}) {
  const r = await fetch(`${base}/functions/${fn}`, { method: 'POST', headers, body: JSON.stringify(params) });
  const body = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(`${fn}: HTTP ${r.status} ${body.error || ''}`);
  return body.result;
}

async function main() {
  for (let i = 0; ; i++) {
    try {
      const r = await fetch(`${base}/health`);
      if (r.ok && (await r.json()).status === 'ok') break;
    } catch {}
    if (i > 300) return log('API did not become healthy; skipped');
    await sleep(1000);
  }
  if ((await call('checkadminexist')) === 'exist') return log('an administrator already exists; nothing to do');
  if (!email || !email.includes('@')) return log('OPENSIGN_ADMIN_EMAIL is not set to an e-mail address; no administrator created');
  if (password.length < 8) return log('OPENSIGN_ADMIN_PASSWORD is shorter than 8 characters; no administrator created');
  await call('addadmin', {
    userDetails: {
      name: process.env.OPENSIGN_ADMIN_NAME || 'Administrator',
      email,
      password,
      phone: '',
      company: process.env.OPENSIGN_ADMIN_COMPANY || 'OpenSign',
      jobTitle: 'Administrator',
      role: 'contracts_Admin',
      timezone: process.env.TZ || 'UTC',
    },
  });
  const state = await call('checkadminexist');
  log(state === 'exist' ? `administrator ${email} created` : `addadmin ran but checkadminexist says "${state}"; see the logs above`);
}
main().catch((e) => log(`failed: ${e.message}`));
