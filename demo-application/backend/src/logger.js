'use strict';

const pino = require('pino');
const { trace, context } = require('@opentelemetry/api');

// Inject the active span's trace_id / span_id into every log line so Grafana
// can link a Loki log to its Tempo trace (and vice-versa). The values are
// empty strings when there is no active span — fine for startup logs.
const mixin = () => {
  const span = trace.getSpan(context.active());
  if (!span) return {};
  const ctx = span.spanContext();
  return { trace_id: ctx.traceId, span_id: ctx.spanId };
};

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: {
    service: 'devops-backend',
    version: process.env.APP_VERSION || 'unknown',
    color: process.env.APP_COLOR || 'blue',
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  mixin,
});

module.exports = logger;
