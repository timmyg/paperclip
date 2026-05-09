// One-time bootstrap invite generator. Runs at container startup.
// Skipped if /paperclip/bootstrap-invite.txt already exists.
// Output: writes invite URL to /paperclip/bootstrap-invite.txt and stdout.
'use strict';
const {createHash, randomBytes} = require('crypto');
const fs = require('fs');

const DONE_FILE = '/paperclip/bootstrap-invite.txt';

if (fs.existsSync(DONE_FILE)) {
  console.log('[bootstrap] invite already created, skipping. URL:', fs.readFileSync(DONE_FILE, 'utf8').trim());
  process.exit(0);
}

const dbUrl = process.env.DATABASE_URL;
if (!dbUrl) {
  console.error('[bootstrap] DATABASE_URL not set, skipping bootstrap');
  process.exit(0);
}

const baseUrl = (process.env.PAPERCLIP_PUBLIC_URL || 'http://localhost:3100').replace(/\/$/, '');

async function main() {
  const postgres = require('./packages/db/node_modules/postgres');
  const token = 'pcp_bootstrap_' + randomBytes(24).toString('hex');
  const tokenHash = createHash('sha256').update(token).digest('hex');
  const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000);

  const sql = postgres(dbUrl, {max: 1});
  try {
    // Revoke any stale bootstrap invites
    await sql`
      UPDATE invites
      SET revoked_at = NOW(), updated_at = NOW()
      WHERE invite_type = 'bootstrap_ceo'
        AND revoked_at IS NULL
        AND accepted_at IS NULL
        AND expires_at > NOW()
    `;
    // Insert new invite
    await sql`
      INSERT INTO invites (invite_type, token_hash, allowed_join_types, expires_at, invited_by_user_id)
      VALUES ('bootstrap_ceo', ${tokenHash}, 'human', ${expiresAt}, 'system')
    `;
    const inviteUrl = baseUrl + '/invite/' + token;
    console.log('[bootstrap] INVITE_URL=' + inviteUrl);
    fs.writeFileSync(DONE_FILE, inviteUrl + '\n');
  } finally {
    await sql.end();
  }
}

main().catch(function(e) {
  console.error('[bootstrap] error:', e.message);
  process.exit(0); // Don't block server startup on bootstrap failure
});
