// Gunakan akun Firebase CLI lokal; tidak menyalin kredensial ke repository.
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

async function main() {
  let directory = path.dirname(fs.realpathSync(execFileSync('which', ['firebase'], { encoding: 'utf8' }).trim()));
  while (directory !== path.dirname(directory)) {
    const manifest = path.join(directory, 'package.json');
    if (fs.existsSync(manifest) && JSON.parse(fs.readFileSync(manifest)).name === 'firebase-tools') break;
    directory = path.dirname(directory);
  }
  const auth = require(path.join(directory, 'lib/auth.js'));
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Jalankan firebase login terlebih dahulu.');
  const credential = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
  const project = process.argv[2];
  if (!project || !/^[a-z][a-z0-9-]+$/.test(project)) throw new Error('Penggunaan: node docs/send_notification.cjs PROJECT_ID');
  const payload = JSON.parse(fs.readFileSync(path.join(__dirname, 'fcm_payload.json')));
  if (process.argv.includes('--data-only')) {
    delete payload.message.notification;
    delete payload.message.android.notification;
  }
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${project}/messages:send`, {
    method: 'POST', headers: { Authorization: `Bearer ${credential.access_token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const body = await response.json();
  if (!response.ok) {
    console.error(JSON.stringify({ status: response.status, error: body.error?.status, message: body.error?.message }));
    process.exitCode = 1;
    return;
  }
  console.log(JSON.stringify({ time: new Date().toISOString(), status: response.status, name: body.name, kind: process.argv.includes('--data-only') ? 'data-only' : 'notification+data' }));
}
main().catch(() => { console.error('Pengiriman gagal. Periksa login Firebase CLI dan akses project.'); process.exitCode = 1; });
