'use strict';

const express = require('express');
const router = express.Router();

const startedAt = Date.now();

router.get('/info', (_req, res) => {
  res.json({
    service: 'devops-backend',
    version: process.env.APP_VERSION || 'unknown',
    color: process.env.APP_COLOR || 'blue',
    uptime_seconds: Math.floor((Date.now() - startedAt) / 1000),
    hostname: require('os').hostname(),
  });
});

router.get('/items', (_req, res) => {
  res.json({
    items: [
      { id: 1, name: 'Terraform' },
      { id: 2, name: 'Docker' },
      { id: 3, name: 'Kubernetes' },
      { id: 4, name: 'Prometheus' },
      { id: 5, name: 'Grafana' },
    ],
  });
});

router.get('/error', (_req, _res, next) => {
  next(new Error('synthetic error for testing'));
});

module.exports = router;
