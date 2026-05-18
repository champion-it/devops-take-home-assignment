'use strict';

const request = require('supertest');
const app = require('../server');

afterAll(() => {
  const server = app.listen();
  server.close();
});

describe('health endpoints', () => {
  test('GET /healthz returns 200', async () => {
    const res = await request(app).get('/healthz');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET /readyz returns 200', async () => {
    const res = await request(app).get('/readyz');
    expect(res.status).toBe(200);
  });

  test('GET /api/info returns service metadata', async () => {
    const res = await request(app).get('/api/info');
    expect(res.status).toBe(200);
    expect(res.body.service).toBe('devops-backend');
  });

  test('GET /metrics returns prometheus metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.status).toBe(200);
    expect(res.text).toMatch(/http_requests_total/);
  });
});
