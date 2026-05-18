'use strict';

const fs = require('fs');
const path = require('path');

// Legacy loader for Vault Agent Injector pattern (writes /vault/secrets/config.env).
// We migrated to Vault Secrets Operator (VSO) — secrets now arrive as env vars
// via `envFrom: secretRef` from the K8s Secret synced by VaultStaticSecret.
//
// This function stays as a no-op fallback for two scenarios:
//   • running outside K8s (local dev, docker-compose) — file doesn't exist
//   • switching back to Agent Injector pattern in the future
// In both cases it returns { loaded: false } and the app continues.
function loadVaultSecrets(filePath = '/vault/secrets/config.env') {
  if (!fs.existsSync(filePath)) {
    return { loaded: false, count: 0 };
  }

  const content = fs.readFileSync(filePath, 'utf8');
  let count = 0;

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    // Accept both `KEY=value` and `export KEY=value`.
    const m = line.match(/^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!m) continue;

    let value = m[2];
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    process.env[m[1]] = value;
    count += 1;
  }

  return { loaded: true, count, path: path.resolve(filePath) };
}

module.exports = { loadVaultSecrets };
