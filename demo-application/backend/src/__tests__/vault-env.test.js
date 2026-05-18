'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { loadVaultSecrets } = require('../vault-env');

describe('loadVaultSecrets', () => {
  let tmpFile;

  afterEach(() => {
    if (tmpFile && fs.existsSync(tmpFile)) fs.unlinkSync(tmpFile);
    delete process.env.TEST_API_KEY;
    delete process.env.TEST_DB_PASSWORD;
  });

  test('is a no-op when the file does not exist', () => {
    const result = loadVaultSecrets('/nonexistent/path/config.env');
    expect(result.loaded).toBe(false);
    expect(result.count).toBe(0);
  });

  test('parses KEY=value, quoted values, and `export` prefix', () => {
    tmpFile = path.join(os.tmpdir(), `vault-test-${Date.now()}.env`);
    fs.writeFileSync(
      tmpFile,
      [
        '# comment line',
        '',
        'TEST_API_KEY=plain-value',
        'export TEST_DB_PASSWORD="quoted value"',
      ].join('\n'),
    );

    const result = loadVaultSecrets(tmpFile);
    expect(result.loaded).toBe(true);
    expect(result.count).toBe(2);
    expect(process.env.TEST_API_KEY).toBe('plain-value');
    expect(process.env.TEST_DB_PASSWORD).toBe('quoted value');
  });
});
