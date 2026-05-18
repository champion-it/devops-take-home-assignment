'use strict';

// OpenTelemetry bootstrap. Must be require()'d FIRST in server.js, before
// express/pino — otherwise auto-instrumentation can't patch their internals.
//
// Spans flow to Tempo via OTLP HTTP. Endpoint is taken from
// OTEL_EXPORTER_OTLP_ENDPOINT (set in the Deployment env), default localhost
// for dev / docker-compose.

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} = require('@opentelemetry/semantic-conventions');

if (process.env.OTEL_DISABLED === 'true') {
  // Tests / local dev can opt out without breaking imports.
  module.exports = { shutdown: async () => {} };
  return;
}

const endpoint =
  process.env.OTEL_EXPORTER_OTLP_ENDPOINT ||
  'http://tempo.monitoring.svc.cluster.local:4318';

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'devops-backend',
    [ATTR_SERVICE_VERSION]: process.env.APP_VERSION || 'unknown',
    'service.color': process.env.APP_COLOR || 'blue',
    'deployment.environment': process.env.DEPLOY_ENV || 'production',
  }),
  traceExporter: new OTLPTraceExporter({
    url: `${endpoint.replace(/\/$/, '')}/v1/traces`,
  }),
  // auto-instrument http, express, pino → spans + trace_id injection into logs.
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false }, // too noisy
    }),
  ],
});

sdk.start();

const shutdown = async () => {
  try {
    await sdk.shutdown();
  } catch (err) {
    // Don't crash on shutdown errors.
    // eslint-disable-next-line no-console
    console.error('OTel shutdown error', err);
  }
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

module.exports = { shutdown };
