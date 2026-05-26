const request = require('supertest');
const app = require('../app');

describe('GET /', () => {
    it('should return 200 and hello message', async () => {
        const res = await request(app).get('/');
        expect(res.statusCode).toBe(200);
        expect(res.text).toContain('Hello from Node App');
    });
});

describe('GET /health', () => {
    it('should return 200 and status ok', async () => {
        const res = await request(app).get('/health');
        expect(res.statusCode).toBe(200);
        expect(res.body.status).toBe('ok');
    });
});
