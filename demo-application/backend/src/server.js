'use strict';

// OpenTelemetry MUST initialize before any other instrumented module so
// auto-instrumentation can hook into them.
require('./tracing');

// Load secrets injected by Vault Agent (no-op outside K8s) BEFORE we read any
// env-var-driven config below. The file path is the Vault Injector default.
const { loadVaultSecrets } = require('./vault-env');
const vaultResult = loadVaultSecrets();

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const pinoHttp = require('pino-http');
const logger = require('./logger');
const metrics = require('./metrics');
const routes = require('./routes');

if (vaultResult.loaded) {
  logger.info({ keys: vaultResult.count, file: vaultResult.path }, 'vault secrets loaded');
}

const PORT = parseInt(process.env.PORT || '8080', 10);
const APP_VERSION = process.env.APP_VERSION || 'unknown';
const APP_COLOR = process.env.APP_COLOR || 'blue';

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '100kb' }));
app.use(pinoHttp({ logger }));
app.use(metrics.middleware);

app.use('/api', routes);
app.get('/metrics', metrics.handler);
app.get('/healthz', (_req, res) => res.status(200).json({ status: 'ok' }));
app.get('/readyz', (_req, res) => res.status(200).json({ status: 'ready' }));
app.get('/', (_req, res) =>
  res.status(200).json({
    service: 'devops-backend',
    version: APP_VERSION,
    color: APP_COLOR,
  }),
);

app.use((err, _req, res, _next) => {
  logger.error({ err }, 'unhandled error');
  res.status(500).json({ error: 'internal_server_error' });
});

const server = app.listen(PORT, () => {
  logger.info({ port: PORT, version: APP_VERSION, color: APP_COLOR }, 'backend started');
});

const shutdown = (signal) => {
  logger.info({ signal }, 'shutdown initiated');
  server.close(() => {
    logger.info('server closed cleanly');
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10_000).unref();
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = app;
